import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
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

  /// Only the skeleton is drawn, no picture of the player (the setting).
  bool _skeletonOnly = false;

  /// The share of the picture the player fills, from the latest mask.
  double? _coverage;

  /// The pushup outline shows until the player has matched it once, held
  /// for [_guideHold]; then it says so and never shows again.
  bool _guidePending = false;
  Duration? _fitSince;
  Duration? _guideDoneAt;
  static const _guideHold = Duration(milliseconds: 800);
  static const _guideCheer = Duration(milliseconds: 1500);

  /// When a pushup was done before counting started, to say so.
  Duration? _idleRepAt;

  /// The shoulders fill most of the picture: too close to the phone.
  bool _tooClose = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
    unawaited(
      SharedPreferencesProvider()
          .getSharedPrefBool(SharedPreferencesKey.cameraGuideDone)
          .then((done) {
        if (mounted && done != true) setState(() => _guidePending = true);
      }),
    );
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
      // The cut-out every other frame is plenty and halves the work. It's
      // fetched even when only the skeleton shows: how much of the picture
      // the player fills tells the bottom of a pushup when the head hides
      // the rest of the body.
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
      final mask = reply['mask'];
      if (mask is Uint8List) _coverage = maskCoverage(mask);
      final reading =
          _tracker.update(pose, _clock.elapsed, coverage: _coverage);
      if (widget.active) {
        if (reading.wentDown) widget.onDown();
        if (reading.cameUp) widget.onUp();
      }
      _feedback.update(reading, _clock.elapsed);
      _check(reading, pose, upright);

      ui.Image? next;
      if (mask is Uint8List && mounted && !_skeletonOnly) {
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

  /// The first-time outline, a pushup done before counting started, and
  /// whether the player is too close.
  void _check(
    PushupReading reading,
    Map<Joint, PosePoint> pose,
    Size upright,
  ) {
    final now = _clock.elapsed;
    _tooClose = reading.visible && tooClose(pose, upright);
    if (!widget.active && reading.cameUp) _idleRepAt = now;
    if (!_guidePending) return;
    if (!PoseGuide.fits(pose, upright)) {
      _fitSince = null;
      return;
    }
    final since = _fitSince ??= now;
    if (now - since < _guideHold) return;
    _guidePending = false;
    _guideDoneAt = now;
    GameAudio.instance.play(Sfx.unlock);
    unawaited(
      SharedPreferencesProvider().writeBoolToSharedPrefs(
        SharedPreferencesKey.cameraGuideDone,
        value: true,
      ),
    );
  }

  /// What to tell the player under the picture, if anything beyond the
  /// usual (step back, hips): the outline, counting not started yet, or
  /// too close to the phone.
  String? _message(BuildContext context, Duration time) {
    final l = context.l10n;
    final doneAt = _guideDoneAt;
    if (doneAt != null && time - doneAt < _guideCheer) return l.cameraGuideDone;
    if (_guidePending) return l.cameraGuideHint;
    final idle = _idleRepAt;
    if (!widget.active &&
        idle != null &&
        time - idle < const Duration(seconds: 4)) {
      return l.cameraNotCounting;
    }
    if (_tooClose) return l.cameraTooClose;

    return null;
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
    _skeletonOnly = context.select<SharedPreferencesCubit, bool>(
      (cubit) => cubit.state.cameraView == CameraView.skeleton,
    );

    final doneAt = _guideDoneAt;
    final cheering = doneAt != null && time - doneAt < _guideCheer;
    final guide = _guidePending || cheering;
    final fit = cheering
        ? 1.0
        : _fitSince == null
            ? 0.0
            : ((time - _fitSince!).inMilliseconds / _guideHold.inMilliseconds)
                .clamp(0.0, 1.0);

    return CameraBubble(
      color: cheering ? colors.normal : _feedback.color(time, colors),
      reading: _feedback.reading,
      message: _message(context, time),
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
                if (_skeletonOnly)
                  const SizedBox.shrink()
                else if (_mask == null)
                  preview
                else
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: _maskShader,
                    child: preview,
                  ),
                if (guide)
                  AnimatedOpacity(
                    // It fades away once matched.
                    opacity: cheering
                        ? 1 -
                            (time - doneAt).inMilliseconds /
                                _guideCheer.inMilliseconds
                        : 1,
                    duration: Duration.zero,
                    child: CustomPaint(
                      painter: PoseGuidePainter(
                        fit: fit,
                        colors: colors,
                        pulse: (math.sin(time.inMilliseconds / 260) + 1) / 2,
                      ),
                    ),
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
