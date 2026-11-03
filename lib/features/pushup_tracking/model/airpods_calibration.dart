import 'dart:math' as math;

import 'package:pushup_bro/core/model/tracking_mode.dart';

/// How a few test pushups with AirPods would count, and the sensitivity
/// that fits them.
///
/// Feed it the head's vertical acceleration (in g) sample by sample. It
/// counts pushups at the chosen [level], exactly as a set would, and
/// separately finds every rep with a low threshold, keeping how sharp it
/// was, to suggest a level that counts all of them without counting
/// wobbles.
class AirPodsCalibration {
  AirPodsCalibration({this.level = AirPodsSensitivity.standard});

  /// Any dip sharper than this is a rep for the suggestion.
  static const _findThreshold = 0.08;

  /// The suggestion stays this far under the softest rep, so a slightly
  /// lazier one still counts.
  static const _margin = 0.7;

  /// Reps the suggestion needs before it means anything.
  static const repsForSuggestion = 3;

  /// The sensitivity being tried.
  int level;

  /// Pushups counted at [level].
  int counted = 0;
  bool _down = false;

  /// The reps found, each as its sharpness: the smaller of how hard the
  /// head dropped and how hard it came back up.
  final List<double> reps = [];
  bool _findingDown = false;
  bool _findingUp = false;
  double _drop = 0;
  double _rise = 0;

  /// The latest sample, for a live meter.
  double latest = 0;

  void add(double accelerationY) {
    latest = accelerationY;
    // Counting at the chosen level, like PushupCubit.
    final threshold = AirPodsSensitivity.threshold(level);
    if (_down) {
      if (accelerationY > threshold) {
        counted++;
        _down = false;
      }
    } else if (accelerationY < -threshold) {
      _down = true;
    }

    // Finding reps for the suggestion: a drop, then a rise, then calm.
    if (!_findingDown && !_findingUp && accelerationY < -_findThreshold) {
      _findingDown = true;
      _drop = 0;
      _rise = 0;
    }
    if (_findingDown) {
      _drop = math.max(_drop, -accelerationY);
      if (accelerationY > _findThreshold) {
        _findingDown = false;
        _findingUp = true;
      }
    }
    if (_findingUp) {
      _rise = math.max(_rise, accelerationY);
      if (accelerationY.abs() < _findThreshold / 2) {
        _findingUp = false;
        reps.add(math.min(_drop, _rise));
      }
    }
  }

  /// Starts the test over at [level].
  void reset({int? level}) {
    if (level != null) this.level = level;
    counted = 0;
    _down = false;
    reps.clear();
    _findingDown = false;
    _findingUp = false;
    latest = 0;
  }

  /// The least sensitive level that still counts every rep found (with a
  /// little room to spare), or null until there are enough reps.
  int? get suggestion {
    if (reps.length < repsForSuggestion) return null;
    final softest = reps.reduce(math.min) * _margin;
    for (var level = AirPodsSensitivity.min;
        level <= AirPodsSensitivity.max;
        level++) {
      if (AirPodsSensitivity.threshold(level) <= softest) return level;
    }

    return AirPodsSensitivity.max;
  }
}
