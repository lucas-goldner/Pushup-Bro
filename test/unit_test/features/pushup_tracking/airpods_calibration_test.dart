import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/features/pushup_tracking/model/airpods_calibration.dart';

/// One pushup as the AirPods feel it: a drop of [depth] g, a rise of the
/// same, then calm.
List<double> _rep(double depth) => [
      0,
      -depth * 0.5,
      -depth,
      -depth * 0.4,
      0.02,
      depth * 0.6,
      depth,
      depth * 0.3,
      0.01,
      0,
    ];

void main() {
  test('the standard level is the original 0.3 g, and levels get softer', () {
    expect(
      AirPodsSensitivity.threshold(AirPodsSensitivity.standard),
      0.3,
    );
    for (var level = AirPodsSensitivity.min;
        level < AirPodsSensitivity.max;
        level++) {
      expect(
        AirPodsSensitivity.threshold(level + 1),
        lessThan(AirPodsSensitivity.threshold(level)),
      );
    }
    expect(AirPodsSensitivity.threshold(99), AirPodsSensitivity.threshold(10));
    expect(AirPodsSensitivity.threshold(-3), AirPodsSensitivity.threshold(1));
  });

  test('counts at its level like a set, and finds every rep', () {
    final calibration = AirPodsCalibration();
    for (final depth in [0.5, 0.2, 0.45]) {
      _rep(depth).forEach(calibration.add);
    }

    // The 0.2 g pushup is too soft for 0.3 g, but it was a rep.
    expect(calibration.counted, 2);
    expect(calibration.reps, hasLength(3));
  });

  test('suggests the least sensitive level that counts every rep', () {
    final calibration = AirPodsCalibration();
    expect(calibration.suggestion, isNull);
    for (final depth in [0.5, 0.35, 0.42]) {
      _rep(depth).forEach(calibration.add);
    }

    final suggestion = calibration.suggestion!;
    // The softest rep was 0.35 g: with room to spare, at most 0.245 g.
    expect(AirPodsSensitivity.threshold(suggestion), lessThanOrEqualTo(0.245));
    expect(AirPodsSensitivity.threshold(suggestion - 1), greaterThan(0.245));
  });

  test('ignores small wobbles and starts over', () {
    final calibration = AirPodsCalibration();
    [0.02, -0.03, 0.04, -0.05, 0.01].forEach(calibration.add);
    expect(calibration.reps, isEmpty);
    expect(calibration.counted, 0);

    _rep(0.6).forEach(calibration.add);
    calibration.reset(level: 8);
    expect(calibration.counted, 0);
    expect(calibration.reps, isEmpty);
    expect(calibration.level, 8);
  });
}
