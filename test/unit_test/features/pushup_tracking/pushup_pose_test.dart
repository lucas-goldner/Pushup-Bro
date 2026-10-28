import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/pushup_pose.dart';

/// A side view of a pushup, seen from the left: hands on the floor at x 100,
/// feet at x 500, the shoulders [lift] pixels above the hands. Upper arm and
/// forearm are 80 px, so a lift of 160 is straight arms.
Map<Joint, PosePoint> sidePose(
  double lift, {
  double hipDrop = 0,
  bool arms = true,
  double likelihood = 0.9,
}) {
  const floor = 400.0;
  const wristX = 100.0;
  final shoulder = Offset2(wristX, floor - lift);
  const ankle = Offset2(500, floor);
  final hip = Offset2(
    (shoulder.x + ankle.x) / 2,
    (shoulder.y + ankle.y) / 2 + hipDrop,
  );
  // The elbow bends out towards the head, perpendicular to the arm.
  final half = lift / 2;
  final out = math.sqrt(math.max(0, 80 * 80 - half * half));
  final elbow = Offset2(wristX - out, floor - half);
  PosePoint p(Offset2 o) => PosePoint(o.x, o.y, likelihood);

  return {
    Joint.leftShoulder: p(shoulder),
    if (arms) Joint.leftElbow: p(elbow),
    Joint.leftWrist: p(const Offset2(wristX, floor)),
    Joint.leftHip: p(hip),
    Joint.leftKnee: p(Offset2((hip.x + ankle.x) / 2, (hip.y + ankle.y) / 2)),
    Joint.leftAnkle: p(ankle),
  };
}

class Offset2 {
  const Offset2(this.x, this.y);
  final double x;
  final double y;
}

/// Feeds [lifts], one frame every 33 ms, and counts finished pushups.
int countReps(
  PushupPoseTracker tracker,
  Iterable<double> lifts, {
  bool arms = true,
}) {
  var reps = 0;
  var frame = 0;
  for (final lift in lifts) {
    final reading = tracker.update(
      sidePose(lift, arms: arms),
      Duration(milliseconds: 33 * frame++),
    );
    if (reading.cameUp) reps++;
  }

  return reps;
}

/// [count] smooth pushups, each [frames] long, from straight arms down to
/// [bottom] and back.
Iterable<double> pushups(
  int count, {
  int frames = 40,
  double bottom = 60,
}) sync* {
  for (var r = 0; r < count; r++) {
    for (var f = 0; f < frames; f++) {
      final t = (1 - math.cos(2 * math.pi * f / frames)) / 2;
      yield 158 - (158 - bottom) * t;
    }
  }
}

/// A front view of a pushup, the phone on the floor in front of the hands:
/// at depth [t] (0 top, 1 bottom) the shoulders come down towards the hands
/// and closer to the camera, so they also look wider. [scale] stands for
/// how far away the player is.
Map<Joint, PosePoint> frontPose(double t, {double scale = 1}) {
  const floor = 600.0;
  const centre = 200.0;
  final width = (100 + 30 * t) * scale;
  final shoulderY = floor - (1.25 - 0.92 * t) * width;
  final handX = width * 0.75;
  PosePoint p(double x, double y) => PosePoint(x, y, 0.9);

  return {
    Joint.nose: p(centre, shoulderY - 0.3 * width),
    Joint.leftShoulder: p(centre - width / 2, shoulderY),
    Joint.rightShoulder: p(centre + width / 2, shoulderY),
    // Elbows flare out as the arms bend.
    Joint.leftElbow:
        p(centre - handX - 30 * t * scale, (shoulderY + floor) / 2),
    Joint.rightElbow:
        p(centre + handX + 30 * t * scale, (shoulderY + floor) / 2),
    Joint.leftWrist: p(centre - handX, floor),
    Joint.rightWrist: p(centre + handX, floor),
  };
}

/// [count] smooth front-view pushups, each [frames] long, down to depth
/// [bottom].
int countFrontReps(
  PushupPoseTracker tracker,
  int count, {
  int frames = 40,
  double bottom = 1,
  double scale = 1,
}) {
  var reps = 0;
  var frame = 0;
  for (var r = 0; r < count; r++) {
    for (var f = 0; f < frames; f++) {
      final t = (1 - math.cos(2 * math.pi * f / frames)) / 2 * bottom;
      final reading = tracker.update(
        frontPose(t, scale: scale),
        Duration(milliseconds: 33 * frame++),
      );
      if (reading.cameUp) reps++;
    }
  }

  return reps;
}

void main() {
  test('angleAt measures the angle at the middle point', () {
    expect(
      angleAt(
        const PosePoint(0, 1, 1),
        const PosePoint(0, 0, 1),
        const PosePoint(1, 0, 1),
      ),
      closeTo(90, 1e-9),
    );
  });

  group('PushupPoseTracker from the front', () {
    test('counts pushups facing the phone, the first one too', () {
      expect(countFrontReps(PushupPoseTracker(), 1), 1);
      expect(countFrontReps(PushupPoseTracker(), 5), 5);
    });

    test('ignores shallow dips', () {
      expect(countFrontReps(PushupPoseTracker(), 4, bottom: 0.25), 0);
    });

    test('works near and far from the phone', () {
      expect(countFrontReps(PushupPoseTracker(), 3, scale: 0.5), 3);
      expect(countFrontReps(PushupPoseTracker(), 3, scale: 2), 3);
    });

    test("doesn't judge the body line from the front", () {
      final reading = PushupPoseTracker().update(frontPose(0), Duration.zero);
      expect(reading.visible, isTrue);
      expect(reading.form, PushupForm.unknown);
    });
  });

  group('PushupPoseTracker', () {
    test('counts full pushups from the elbow angle', () {
      expect(countReps(PushupPoseTracker(), pushups(5)), 5);
    });

    test('ignores shallow dips that never reach the bottom', () {
      expect(countReps(PushupPoseTracker(), pushups(4, bottom: 140)), 0);
    });

    test('ignores jitter at the top', () {
      final jitter = [for (var i = 0; i < 120; i++) 158 + (i.isEven ? 4 : -4)];
      expect(
        countReps(PushupPoseTracker(), jitter.map((e) => e.toDouble())),
        0,
      );
    });

    test('a twitch through the bottom is too short to count', () {
      final twitch = [
        for (var i = 0; i < 10; i++) 158.0,
        40.0,
        for (var i = 0; i < 10; i++) 158.0,
      ];
      expect(countReps(PushupPoseTracker(), twitch), 0);
    });

    test('falls back on shoulder height when the elbows are hidden', () {
      expect(countReps(PushupPoseTracker(), pushups(5), arms: false), 5);
    });

    test('reports going down and the depth at the bottom', () {
      final tracker = PushupPoseTracker();
      var wentDown = false;
      var deepest = 0.0;
      var frame = 0;
      for (final lift in pushups(1)) {
        final reading = tracker.update(
          sidePose(lift),
          Duration(milliseconds: 33 * frame++),
        );
        wentDown |= reading.wentDown;
        deepest = math.max(deepest, reading.depth);
      }
      expect(wentDown, isTrue);
      expect(deepest, greaterThan(0.8));
    });

    test('needs the body in view', () {
      final reading = PushupPoseTracker().update(
        sidePose(158, likelihood: 0.1),
        Duration.zero,
      );
      expect(reading.visible, isFalse);
    });

    test('judges the body line', () {
      PushupForm form(double hipDrop) => PushupPoseTracker()
          .update(sidePose(158, hipDrop: hipDrop), Duration.zero)
          .form;

      expect(form(0), PushupForm.good);
      expect(form(60), PushupForm.sagging);
      expect(form(-60), PushupForm.piking);
    });
  });
}
