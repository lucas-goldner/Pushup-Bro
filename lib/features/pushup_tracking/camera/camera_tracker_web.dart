import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_overlay.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

/// The web build's stand-in for the camera (Vision is iOS only): a
/// skeleton doing a pushup every three seconds facing the camera, run
/// through the same tracker and overlay as the real thing.
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
    with SingleTickerProviderStateMixin {
  static const _size = Size(300, 400);
  final _tracker = PushupPoseTracker();
  final _feedback = RepFeedback();
  late final Ticker _ticker;
  Duration _time = Duration.zero;
  Map<Joint, PosePoint> _pose = const {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(CameraTrackerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start counting from the top, not halfway through a pushup.
    if (widget.active && !oldWidget.active) _tracker.reset();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration time) {
    _time = time;
    // Down for a moment, then up, every 3 s, held long
    // enough at each end to count even at a low frame rate.
    final t = (time.inMilliseconds % 3000) / 3000;
    final dip = t < 0.15
        ? t / 0.15
        : t < 0.5
            ? 1.0
            : t < 0.65
                ? 1 - (t - 0.5) / 0.15
                : 0.0;
    // Facing the camera: the shoulders come down towards the hands and
    // closer, so they also look wider.
    const floor = 330.0;
    const centre = 150.0;
    final width = 110 + 30 * dip;
    final shoulderY = floor - (1.25 - 0.92 * dip) * width;
    final handX = width * 0.75;
    PosePoint p(double x, double y) => PosePoint(x, y, 0.95);
    final pose = {
      Joint.nose: p(centre, shoulderY - 0.35 * width),
      Joint.leftShoulder: p(centre - width / 2, shoulderY),
      Joint.rightShoulder: p(centre + width / 2, shoulderY),
      Joint.leftElbow: p(centre - handX - 30 * dip, (shoulderY + floor) / 2),
      Joint.rightElbow: p(centre + handX + 30 * dip, (shoulderY + floor) / 2),
      Joint.leftWrist: p(centre - handX, floor),
      Joint.rightWrist: p(centre + handX, floor),
    };
    final reading = _tracker.update(pose, time);
    if (widget.active) {
      if (reading.wentDown) widget.onDown();
      if (reading.cameUp) widget.onUp();
    }
    _feedback.update(reading, time);
    setState(() => _pose = pose);
  }

  @override
  Widget build(BuildContext context) {
    final colors = RepPalette.of(context);

    return CameraBubble(
      color: _feedback.color(_time, colors),
      reading: _feedback.reading,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox.fromSize(
            size: _size,
            child: CustomPaint(
              painter: SkeletonPainter(
                pose: _pose,
                imageSize: _size,
                color: _feedback.color(_time, colors),
                form: _feedback.reading.form,
                colors: colors,
                lineScale: coverLineScale(_size, constraints.biggest),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
