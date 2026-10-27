import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

/// The Jungle Trek's colours for the three kinds of pushup.
const _normal = Color(0xFF4FB35A);
const _held = Color(0xFF4A90E2);
const _quick = Color(0xFFF5C343);
const _badForm = Color(0xFFFF8A3D);

/// How long at the bottom makes a held pushup, and how soon after the last
/// one makes a quick one (as the Trek counts them).
const _holdSeconds = 2.0;
const _quickSeconds = 1.6;

/// Colours the skeleton by what the body is doing: whiter at the top,
/// filling with blue the longer it holds at the bottom, then flashing the
/// colour of the pushup just done (green, blue held, yellow quick).
class RepFeedback {
  Duration? _downSince;
  Duration? _lastRep;
  Duration? _flashAt;
  Color _flash = _normal;
  PushupReading reading = PushupReading.none;

  void update(PushupReading next, Duration time) {
    reading = next;
    if (next.wentDown) _downSince = time;
    if (next.cameUp) {
      final held = _downSince != null &&
          (time - _downSince!).inMilliseconds / 1000 >= _holdSeconds;
      final quick = _lastRep != null &&
          (time - _lastRep!).inMilliseconds / 1000 <= _quickSeconds;
      _flash = held
          ? _held
          : quick
              ? _quick
              : _normal;
      _flashAt = time;
      _lastRep = time;
      _downSince = null;
    }
  }

  Color color(Duration time) {
    final flashAt = _flashAt;
    if (flashAt != null && (time - flashAt).inMilliseconds < 500) return _flash;
    final since = _downSince;
    if (reading.down && since != null) {
      final held =
          ((time - since).inMilliseconds / 1000 / _holdSeconds).clamp(0.0, 1.0);
      return Color.lerp(Colors.white, _held, 0.3 + 0.7 * held)!;
    }

    return Colors.white;
  }
}

/// Draws the tracked skeleton over the camera image. [pose] is in upright
/// image pixels, [imageSize] big; it's scaled to fill the canvas the way the
/// image is.
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.color,
    required this.form,
    this.lineScale = 1,
  });

  final Map<Joint, PosePoint> pose;

  /// Line widths are multiplied by this, to stay the same on screen however
  /// much the image is scaled down to fit its window.
  final double lineScale;
  final Size imageSize;
  final Color color;
  final PushupForm form;

  static const Set<(Joint, Joint)> _hipBones = {
    (Joint.leftShoulder, Joint.leftHip),
    (Joint.rightShoulder, Joint.rightHip),
    (Joint.leftHip, Joint.leftKnee),
    (Joint.rightHip, Joint.rightKnee),
    (Joint.leftKnee, Joint.leftAnkle),
    (Joint.rightKnee, Joint.rightAnkle),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty) return;
    final scale = size.width / imageSize.width;
    Offset at(PosePoint p) => Offset(p.x * scale, p.y * scale);
    final badForm = form == PushupForm.sagging || form == PushupForm.piking;
    final glow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 9 * lineScale
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in skeletonBones) {
      final pa = pose[a];
      final pb = pose[b];
      if (pa == null ||
          pb == null ||
          pa.likelihood < PushupPoseTracker.minLikelihood ||
          pb.likelihood < PushupPoseTracker.minLikelihood) {
        continue;
      }
      final bone = Paint()
        ..color = badForm && _hipBones.contains((a, b)) ? _badForm : color
        ..strokeWidth = 5 * lineScale
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(at(pa), at(pb), glow)
        ..drawLine(at(pa), at(pb), bone);
    }
    for (final point in pose.values) {
      if (point.likelihood < PushupPoseTracker.minLikelihood) continue;
      canvas
        ..drawCircle(at(point), 6 * lineScale, Paint()..color = Colors.black26)
        ..drawCircle(at(point), 4.5 * lineScale, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) => true;
}

/// The rounded camera window: [child] (the cut-out camera image and its
/// skeleton) in a frame the colour of the feedback, with a hint underneath
/// when the body isn't in view or the form slips.
class CameraBubble extends StatelessWidget {
  const CameraBubble({
    required this.child,
    required this.color,
    required this.reading,
    this.message,
    super.key,
  });

  final Widget child;
  final Color color;
  final PushupReading reading;

  /// Shown instead of a hint, e.g. while the camera starts.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hint = message ??
        (!reading.visible
            ? l.cameraStepBack
            : switch (reading.form) {
                PushupForm.sagging => l.cameraHipsUp,
                PushupForm.piking => l.cameraHipsDown,
                _ => null,
              });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The cut-out sits on the jungle's colours.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E7D4F), Color(0xFF123524)],
                ),
              ),
            ),
            child,
            if (hint != null)
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: buttonTextStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// How much to thicken lines drawn on an image of [image] size that's
/// scaled to cover a window of [window] size.
double coverLineScale(Size image, Size window) {
  if (image.isEmpty || window.isEmpty) return 1;
  final scale = math.max(
    window.width / image.width,
    window.height / image.height,
  );

  return 1 / scale;
}
