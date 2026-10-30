import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_overlay.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

/// Apple's Vision framework, run natively (PoseVision in
/// ios/Runner/AppDelegate.swift): body pose and the person mask per frame.
const _vision = MethodChannel('pushup_bro/pose');

/// The front camera, watching the player do pushups facing the phone:
/// Apple's Vision finds the body every frame, [PushupPoseTracker] turns it
/// into pushups, and Vision's person segmentation cuts the player out of
/// the room onto the jungle's colours, with the skeleton drawn on top.
///
/// [onDown] and [onUp] fire as each pushup starts and finishes, while
/// [active]; otherwise it only shows the preview, so the player can find a
/// good spot for the phone.
class CameraTrackerView extends StatefulWidget {
  const CameraTrackerView({
    required this.onDown,
    required this.onUp,
    this.active = true,
    super.key,
  });

  final VoidCallback onDown;
  final VoidCallback onUp;
  final bool active;

  @override
  State<CameraTrackerView> createState() => _CameraTrackerViewState();
}

class _CameraTrackerViewState extends State<CameraTrackerView>
    with WidgetsBindingObserver {
  final _tracker = PushupPoseTracker();
  final _feedback = RepFeedback();
  final _clock = Stopwatch()..start();

  CameraController? _controller;
  CameraDescription? _camera;
  String? _error;
  bool _busy = false;
  int _frame = 0;

  Map<Joint, PosePoint> _pose = const {};
  Size _upright = Size.zero;

  ui.Image? _mask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      unawaited(_stop());
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'none');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = camera;
      _controller = controller;
      _tracker.reset();
      await controller.startImageStream(_onImage);
      // Closed while the stream started: dispose stopped it already.
      if (!mounted) return;
      setState(() => _error = null);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _stop() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
  }

  @override
  void didUpdateWidget(CameraTrackerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start counting from the top, not halfway through a pushup.
    if (widget.active && !oldWidget.active) _tracker.reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    _mask?.dispose();
    _mask = null;
    super.dispose();
  }

  Future<void> _onImage(CameraImage image) async {
    final camera = _camera;
    if (_busy || camera == null || image.planes.length != 1) return;
    _busy = true;
    try {
      // The plugin usually hands over upright (and, for the front camera,
      // mirrored like the preview) frames; a landscape one still needs the
      // sensor's turn.
      final rotation =
          image.height >= image.width ? 0 : camera.sensorOrientation % 360;
      final turned = rotation == 90 || rotation == 270;
      final upright = Size(
        (turned ? image.height : image.width).toDouble(),
        (turned ? image.width : image.height).toDouble(),
      );
      final plane = image.planes.first;
      // The cut-out every other frame is plenty and halves the work.
      final wantsMask = (_frame++).isEven;
      final reply = await _vision.invokeMapMethod<String, Object?>(
        'process',
        {
          'bytes': plane.bytes,
          'width': image.width,
          'height': image.height,
          'bytesPerRow': plane.bytesPerRow,
          'rotation': rotation,
          'mask': wantsMask,
        },
      );
      if (reply == null) return;

      final pose = <Joint, PosePoint>{};
      final joints = reply['joints'] as Map<Object?, Object?>? ?? const {};
      for (final joint in Joint.values) {
        final point = joints[joint.name] as List<Object?>?;
        if (point == null || point.length < 3) continue;
        pose[joint] = PosePoint(
          (point[0]! as num) * upright.width,
          (point[1]! as num) * upright.height,
          (point[2]! as num).toDouble(),
        );
      }
      final reading = _tracker.update(pose, _clock.elapsed);
      if (widget.active) {
        if (reading.wentDown) widget.onDown();
        if (reading.cameUp) widget.onUp();
      }
      _feedback.update(reading, _clock.elapsed);

      final mask = reply['mask'];
      ui.Image? next;
      if (mask is Uint8List && mounted) {
        next = await _maskImage(
          mask,
          reply['maskWidth']! as int,
          reply['maskHeight']! as int,
        );
      }
      // A frame still on its way when the camera closed: dispose already
      // freed the mask, so it must not be touched again.
      if (!mounted) {
        next?.dispose();
        return;
      }
      final old = next == null ? null : _mask;
      setState(() {
        if (next != null) _mask = next;
        _pose = pose;
        _upright = upright;
      });
      // The old mask goes once the new one is painted, never while the
      // preview might still draw it.
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    } on Object catch (e) {
      debugPrint('Camera tracking frame failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Vision's person mask (one byte per pixel, upright) as an image whose
  /// alpha is how sure it is that a pixel is the player.
  Future<ui.Image> _maskImage(Uint8List mask, int width, int height) {
    final pixels = Uint8List(width * height * 4);
    for (var i = 0; i < width * height && i < mask.length; i++) {
      pixels
        ..[i * 4] = 255
        ..[i * 4 + 1] = 255
        ..[i * 4 + 2] = 255
        ..[i * 4 + 3] = mask[i];
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );

    return done.future;
  }

  /// Stretches the upright mask over the preview.
  Shader _maskShader(Rect bounds) {
    final mask = _mask!;
    final matrix = Matrix4.identity()
      ..scaleByDouble(
        bounds.width / mask.width,
        bounds.height / mask.height,
        1,
        1,
      );

    return ImageShader(
      mask,
      TileMode.clamp,
      TileMode.clamp,
      matrix.storage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final time = _clock.elapsed;
    final colors = RepPalette.of(context);
    if (_error != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return CameraBubble(
        color: colors.rest,
        reading: PushupReading.none,
        message: _error != null
            ? context.l10n.cameraUnavailable
            : context.l10n.cameraStarting,
        child: Center(
          child: Icon(
            Icons.videocam_rounded,
            color: colors.rest.withValues(alpha: 0.54),
            size: 40,
          ),
        ),
      );
    }
    final preview = CameraPreview(controller);

    return CameraBubble(
      color: _feedback.color(time, colors),
      reading: _feedback.reading,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _upright.isEmpty ? 300 : _upright.width,
            height: _upright.isEmpty ? 400 : _upright.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_mask == null)
                  preview
                else
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: _maskShader,
                    child: preview,
                  ),
                CustomPaint(
                  painter: SkeletonPainter(
                    pose: _pose,
                    imageSize: _upright,
                    color: _feedback.color(time, colors),
                    form: _feedback.reading.form,
                    colors: colors,
                    lineScale: coverLineScale(
                      _upright.isEmpty ? const Size(300, 400) : _upright,
                      constraints.biggest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
