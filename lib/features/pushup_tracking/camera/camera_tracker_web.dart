import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_overlay.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

/// The web build's stand-in for the camera (ML Kit has no web build): a
/// skeleton doing a pushup every two seconds from the side, run through the
/// same tracker and overlay as the real thing.
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
    // Seen from the side: down for a moment, then up, every 3 s, held long
    // enough at each end to count even at a low frame rate.
    final t = (time.inMilliseconds % 3000) / 3000;
    final dip = t < 0.15
        ? t / 0.15
        : t < 0.5
            ? 1.0
            : t < 0.65
                ? 1 - (t - 0.5) / 0.15
                : 0.0;
    final lift = 118 - 74 * dip;
    const floor = 300.0;
    const wristX = 95.0;
    final shoulder = Offset(wristX, floor - lift);
    const ankle = Offset(265, floor);
    final hip = Offset.lerp(shoulder, ankle, 0.5)!;
    final half = lift / 2;
    final out = math.sqrt(math.max(0, 60 * 60 - half * half));
    final elbow = Offset(wristX + out, floor - half);
    PosePoint p(Offset o) => PosePoint(o.dx, o.dy, 0.95);
    final pose = {
      Joint.nose: p(shoulder + const Offset(-26, -6)),
      Joint.leftShoulder: p(shoulder),
      Joint.leftElbow: p(elbow),
      Joint.leftWrist: p(const Offset(wristX, floor)),
      Joint.leftHip: p(hip),
      Joint.leftKnee: p(Offset.lerp(hip, ankle, 0.5)!),
      Joint.leftAnkle: p(ankle),
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
