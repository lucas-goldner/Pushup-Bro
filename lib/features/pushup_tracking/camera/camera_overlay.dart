import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

/// The Jungle Trek's colours for the three kinds of pushup, from the
/// theme's game colours: green for a normal one, blue held, yellow quick,
/// orange when the form slips, and white at rest.
@immutable
class RepPalette {
  const RepPalette({
    required this.normal,
    required this.held,
    required this.quick,
    required this.badForm,
    required this.rest,
    required this.shade,
  });

  factory RepPalette.of(BuildContext context) {
    final game = context.gameColors;

    return RepPalette(
      normal: game.leaf,
      held: game.held,
      quick: game.banana,
      badForm: game.orange,
      rest: game.onGame,
      shade: context.colorScheme.scrim,
    );
  }

  final Color normal;
  final Color held;
  final Color quick;
  final Color badForm;

  /// The skeleton when nothing is happening.
  final Color rest;

  /// The soft outline under the skeleton's lines and joints.
  final Color shade;
}

enum _RepKind { normal, held, quick }

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
  _RepKind _flash = _RepKind.normal;
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
          ? _RepKind.held
          : quick
              ? _RepKind.quick
              : _RepKind.normal;
      _flashAt = time;
      _lastRep = time;
      _downSince = null;
    }
  }

  Color color(Duration time, RepPalette colors) {
    final flashAt = _flashAt;
    if (flashAt != null && (time - flashAt).inMilliseconds < 500) {
      return switch (_flash) {
        _RepKind.normal => colors.normal,
        _RepKind.held => colors.held,
        _RepKind.quick => colors.quick,
      };
    }
    final since = _downSince;
    if (reading.down && since != null) {
      final held =
          ((time - since).inMilliseconds / 1000 / _holdSeconds).clamp(0.0, 1.0);
      return Color.lerp(colors.rest, colors.held, 0.3 + 0.7 * held)!;
    }

    return colors.rest;
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
    required this.colors,
    this.lineScale = 1,
  });

  final Map<Joint, PosePoint> pose;

  /// Line widths are multiplied by this, to stay the same on screen however
  /// much the image is scaled down to fit its window.
  final double lineScale;
  final Size imageSize;
  final Color color;
  final PushupForm form;

  /// For the bad form bones and the shade under the lines.
  final RepPalette colors;

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
      ..color = colors.shade.withValues(alpha: 0.35)
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
        ..color = badForm && _hipBones.contains((a, b)) ? colors.badForm : color
        ..strokeWidth = 5 * lineScale
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(at(pa), at(pb), glow)
        ..drawLine(at(pa), at(pb), bone);
    }
    for (final point in pose.values) {
      if (point.likelihood < PushupPoseTracker.minLikelihood) continue;
      canvas
        ..drawCircle(
          at(point),
          6 * lineScale,
          Paint()..color = colors.shade.withValues(alpha: 0.26),
        )
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
        borderRadius: BorderRadius.circular(PBRadius.lg + 2),
        border: Border.all(color: color, width: 4),
        boxShadow: context.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PBRadius.lg - 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The cut-out sits on the jungle's colours.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.gameColors.jungle,
                    context.gameColors.jungleDeep,
                  ],
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
                    color: context.colorScheme.scrim.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(PBRadius.sm),
                  ),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.gameColors.onGame,
                      letterSpacing: 0,
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
