import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_overlay.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

const Map<Joint, PoseLandmarkType> _landmarks = {
  Joint.nose: PoseLandmarkType.nose,
  Joint.leftShoulder: PoseLandmarkType.leftShoulder,
  Joint.rightShoulder: PoseLandmarkType.rightShoulder,
  Joint.leftElbow: PoseLandmarkType.leftElbow,
  Joint.rightElbow: PoseLandmarkType.rightElbow,
  Joint.leftWrist: PoseLandmarkType.leftWrist,
  Joint.rightWrist: PoseLandmarkType.rightWrist,
  Joint.leftHip: PoseLandmarkType.leftHip,
  Joint.rightHip: PoseLandmarkType.rightHip,
  Joint.leftKnee: PoseLandmarkType.leftKnee,
  Joint.rightKnee: PoseLandmarkType.rightKnee,
  Joint.leftAnkle: PoseLandmarkType.leftAnkle,
  Joint.rightAnkle: PoseLandmarkType.rightAnkle,
};

/// The front camera, watching the player do pushups: ML Kit's pose
/// detection (BlazePose, the model MediaPipe uses) finds the body every
/// frame, [PushupPoseTracker] turns it into pushups, and selfie
/// segmentation cuts the player out of the room onto the jungle's colours,
/// with the skeleton drawn on top.
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
  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  final _segmenter = SelfieSegmenter();
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
  Size _maskSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

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
    unawaited(_poseDetector.close());
    unawaited(_segmenter.close());
    _mask?.dispose();
    super.dispose();
  }

  Future<void> _onImage(CameraImage image) async {
    if (_busy) return;
    _busy = true;
    try {
      final input = _inputImage(image);
      if (input == null) return;
      final rawSize = Size(image.width.toDouble(), image.height.toDouble());
      // Pose in upright pixels, so up is up and angles keep their shape.
      final upright = switch (_rotation) {
        InputImageRotation.rotation90deg ||
        InputImageRotation.rotation270deg =>
          Size(rawSize.height, rawSize.width),
        _ => rawSize,
      };
      final poses = await _poseDetector.processImage(input);
      // Cut-out every other frame is plenty and halves the work.
      final mask =
          (_frame++).isEven ? await _segmenter.processImage(input) : null;

      final pose = <Joint, PosePoint>{};
      if (poses.isNotEmpty) {
        final landmarks = poses.first.landmarks;
        for (final MapEntry(key: joint, value: type) in _landmarks.entries) {
          final landmark = landmarks[type];
          if (landmark == null) continue;
          final at = _toCanvas(landmark.x, landmark.y, upright, rawSize);
          pose[joint] = PosePoint(at.dx, at.dy, landmark.likelihood);
        }
      }
      final reading = _tracker.update(pose, _clock.elapsed);
      if (widget.active) {
        if (reading.wentDown) widget.onDown();
        if (reading.cameUp) widget.onUp();
      }
      _feedback.update(reading, _clock.elapsed);

      if (mask != null) {
        final next = await _maskImage(mask);
        _mask?.dispose();
        _mask = next;
        _maskSize = Size(mask.width.toDouble(), mask.height.toDouble());
      }
      if (mounted) {
        setState(() {
          _pose = pose;
          _upright = upright;
        });
      }
    } on Object catch (e) {
      debugPrint('Camera tracking frame failed: $e');
    } finally {
      _busy = false;
    }
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// The camera frame as ML Kit wants it (following ML Kit's own example).
  InputImage? _inputImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;
    final sensor = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensor);
    } else {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      compensation = camera.lensDirection == CameraLensDirection.front
          ? (sensor + compensation) % 360
          : (sensor - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;
    _rotation = rotation;
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null ||
        (Platform.isIOS && format != InputImageFormat.bgra8888) ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Where an ML Kit point lands on a [canvas] showing the (mirrored, for
  /// the front camera) preview; [imageSize] is the analysed image's size
  /// (following ML Kit's example).
  Offset _toCanvas(double x, double y, Size canvas, Size imageSize) {
    final front = _camera?.lensDirection == CameraLensDirection.front;
    final ios = Platform.isIOS;
    final px = switch (_rotation) {
      InputImageRotation.rotation90deg =>
        x * canvas.width / (ios ? imageSize.width : imageSize.height),
      InputImageRotation.rotation270deg => canvas.width -
          x * canvas.width / (ios ? imageSize.width : imageSize.height),
      _ => front
          ? canvas.width - x * canvas.width / imageSize.width
          : x * canvas.width / imageSize.width,
    };
    final py = switch (_rotation) {
      InputImageRotation.rotation90deg ||
      InputImageRotation.rotation270deg =>
        y * canvas.height / (ios ? imageSize.height : imageSize.width),
      _ => y * canvas.height / imageSize.height,
    };

    return Offset(px, py);
  }

  /// The segmentation mask as an image whose alpha is how sure it is that
  /// a pixel is the player.
  Future<ui.Image> _maskImage(SegmentationMask mask) {
    final pixels = Uint8List(mask.width * mask.height * 4);
    for (var i = 0; i < mask.confidences.length; i++) {
      final alpha = (mask.confidences[i] * 255).round().clamp(0, 255);
      pixels
        ..[i * 4] = 255
        ..[i * 4 + 1] = 255
        ..[i * 4 + 2] = 255
        ..[i * 4 + 3] = alpha;
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      mask.width,
      mask.height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );

    return done.future;
  }

  /// Maps the mask over the preview the same way as the landmarks.
  Shader _maskShader(Rect bounds) {
    final mask = _mask!;
    final origin = _toCanvas(0, 0, bounds.size, _maskSize);
    final end =
        _toCanvas(_maskSize.width, _maskSize.height, bounds.size, _maskSize);
    final scaleX = (end.dx - origin.dx) / mask.width;
    final scaleY = (end.dy - origin.dy) / mask.height;
    final matrix = Matrix4.identity()
      ..translateByDouble(origin.dx, origin.dy, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1, 1);

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
    if (_error != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return CameraBubble(
        color: Colors.white,
        reading: PushupReading.none,
        message: _error != null
            ? context.l10n.cameraUnavailable
            : context.l10n.cameraStarting,
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white54, size: 40),
        ),
      );
    }
    final preview = CameraPreview(controller);

    return CameraBubble(
      color: _feedback.color(time),
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
                    color: _feedback.color(time),
                    form: _feedback.reading.form,
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
