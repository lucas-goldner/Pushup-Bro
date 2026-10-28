import 'dart:math' as math;
import 'dart:ui' show Offset;

/// The body points the pushup tracker looks at (the ones Apple's Vision
/// body pose finds that matter for a pushup).
enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// One detected body point, in image pixels (y grows downwards), with how
/// sure the model is that it's really there.
class PosePoint {
  const PosePoint(this.x, this.y, this.likelihood);

  final double x;
  final double y;
  final double likelihood;

  Offset get offset => Offset(x, y);
}

/// The skeleton's bones, for drawing it.
const skeletonBones = <(Joint, Joint)>[
  (Joint.leftShoulder, Joint.rightShoulder),
  (Joint.leftShoulder, Joint.leftElbow),
  (Joint.leftElbow, Joint.leftWrist),
  (Joint.rightShoulder, Joint.rightElbow),
  (Joint.rightElbow, Joint.rightWrist),
  (Joint.leftShoulder, Joint.leftHip),
  (Joint.rightShoulder, Joint.rightHip),
  (Joint.leftHip, Joint.rightHip),
  (Joint.leftHip, Joint.leftKnee),
  (Joint.leftKnee, Joint.leftAnkle),
  (Joint.rightHip, Joint.rightKnee),
  (Joint.rightKnee, Joint.rightAnkle),
];

/// How the body line looks: straight, hips sagging or hips piked up.
enum PushupForm { unknown, good, sagging, piking }

/// What the tracker made of the latest frame.
class PushupReading {
  const PushupReading({
    required this.visible,
    required this.down,
    required this.depth,
    required this.form,
    this.wentDown = false,
    this.cameUp = false,
  });

  static const none = PushupReading(
    visible: false,
    down: false,
    depth: 0,
    form: PushupForm.unknown,
  );

  /// Whether enough of the body is in view to track.
  final bool visible;

  /// Whether the body is in the bottom half of a pushup.
  final bool down;

  /// 0 at the top of a pushup, 1 at the bottom.
  final double depth;
  final PushupForm form;

  /// Whether this frame started a pushup (went down) or finished one (came
  /// back up).
  final bool wentDown;
  final bool cameUp;
}

/// Counts pushups from pose landmarks, frame by frame.
///
/// Players face the phone, so the main signal is the front view: how far
/// the shoulders are above the hands, in shoulder widths. Going down
/// brings the shoulders down to the hands and closer to the camera (so
/// they also look wider), and both shrink that number. It starts from a
/// typical top and bottom and widens to what the player shows, so the
/// first pushup counts and it adapts to wherever the phone is. From the
/// front the elbows only nudge it, since a bent arm pointing at the camera
/// is hard to read.
///
/// Seen from the side (one shoulder hidden), the elbow angle takes over:
/// straight arms at the top, bent past about 90° at the bottom, with the
/// shoulder height above the wrists as a fallback when the elbows can't be
/// seen. The depth is smoothed, and a pushup only counts with hysteresis
/// (deep enough to go down, high enough to come back up) and a minimum time
/// at the bottom, so jitter never counts twice.
class PushupPoseTracker {
  PushupPoseTracker({
    this.downAt = 0.62,
    this.upAt = 0.32,
    this.minDown = const Duration(milliseconds: 220),
  });

  /// Depth past which the body counts as down, and under which it counts
  /// as back up.
  final double downAt;
  final double upAt;

  /// The shortest time at the bottom that counts as a pushup.
  final Duration minDown;

  /// Likelihood under which a point is ignored.
  static const minLikelihood = 0.5;

  double? _depth;
  bool _down = false;
  Duration? _downSince;
  double? _low;
  double? _high;
  double _frontLow = _frontBottom;
  double _frontHigh = _frontTop;

  /// Shoulders above the hands, in shoulder widths, at the bottom and the
  /// top of a typical pushup seen from the front (from a phone on the
  /// floor in front of the hands).
  static const _frontBottom = 0.35;
  static const _frontTop = 1.25;

  /// Starts over, forgetting the range seen so far.
  void reset() {
    _depth = null;
    _down = false;
    _downSince = null;
    _low = null;
    _high = null;
    _frontLow = _frontBottom;
    _frontHigh = _frontTop;
  }

  PushupReading update(Map<Joint, PosePoint> pose, Duration time) {
    PosePoint? seen(Joint joint) {
      final point = pose[joint];
      return point != null && point.likelihood >= minLikelihood ? point : null;
    }

    final front = _frontDepth(seen);
    final elbows = _elbowDepth(seen);
    final raw = front != null
        ? (elbows == null ? front : front * 0.8 + elbows * 0.2)
        : elbows ?? _shoulderDepth(seen);
    if (raw == null) {
      return PushupReading(
        visible: false,
        down: _down,
        depth: _depth ?? 0,
        form: PushupForm.unknown,
      );
    }
    final depth = _depth = _depth == null ? raw : _depth! * 0.55 + raw * 0.45;

    var wentDown = false;
    var cameUp = false;
    if (!_down && depth >= downAt) {
      _down = true;
      _downSince = time;
      wentDown = true;
    } else if (_down && depth <= upAt) {
      final since = _downSince;
      if (since == null || time - since >= minDown) {
        _down = false;
        cameUp = true;
      }
    }

    return PushupReading(
      visible: true,
      down: _down,
      depth: depth,
      // The body line can only be judged from the side.
      form: front == null ? _form(seen) : PushupForm.unknown,
      wentDown: wentDown,
      cameUp: cameUp,
    );
  }

  /// Depth from the front: the shoulders' height above the hands in
  /// shoulder widths, placed in the range seen so far. Null unless both
  /// shoulders and a hand are in view, i.e. the player faces the camera.
  double? _frontDepth(PosePoint? Function(Joint) seen) {
    final left = seen(Joint.leftShoulder);
    final right = seen(Joint.rightShoulder);
    final hands = _mid(seen(Joint.leftWrist), seen(Joint.rightWrist));
    if (left == null || right == null || hands == null) return null;
    final width = (left.offset - right.offset).distance;
    // Seen edge on, the shoulders overlap: that's a side view.
    if (width < 12) return null;
    final shoulders = (left.offset + right.offset) / 2;
    final height = (hands.dy - shoulders.dy) / width;

    // Widen the range to what this player shows, and let it ease back
    // towards the typical one so an odd frame doesn't stretch it for good.
    _frontLow = math.min(_frontLow, height);
    _frontHigh = math.max(_frontHigh, height);
    _frontLow += (_frontBottom - _frontLow).clamp(0.0, 1.0) * 0.002;
    _frontHigh -= (_frontHigh - _frontTop).clamp(0.0, 10.0) * 0.002;

    return (1 - (height - _frontLow) / (_frontHigh - _frontLow))
        .clamp(0.0, 1.0);
  }

  /// Depth from the elbow angles: 0 with the arms straight (170°), 1 bent
  /// to 85°.
  double? _elbowDepth(PosePoint? Function(Joint) seen) {
    final angles = <double>[];
    for (final (shoulder, elbow, wrist) in const [
      (Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist),
      (Joint.rightShoulder, Joint.rightElbow, Joint.rightWrist),
    ]) {
      final s = seen(shoulder);
      final e = seen(elbow);
      final w = seen(wrist);
      if (s != null && e != null && w != null) angles.add(angleAt(s, e, w));
    }
    if (angles.isEmpty) return null;
    final angle = angles.reduce((a, b) => a + b) / angles.length;

    return ((170 - angle) / (170 - 85)).clamp(0.0, 1.0);
  }

  /// Depth from how far the shoulders are above the wrists, in torso
  /// lengths, scaled to the range seen so far.
  double? _shoulderDepth(PosePoint? Function(Joint) seen) {
    final shoulders = _mid(seen(Joint.leftShoulder), seen(Joint.rightShoulder));
    final wrists = _mid(seen(Joint.leftWrist), seen(Joint.rightWrist));
    if (shoulders == null || wrists == null) return null;
    final hips = _mid(seen(Joint.leftHip), seen(Joint.rightHip));
    final left = seen(Joint.leftShoulder);
    final right = seen(Joint.rightShoulder);
    final scale = hips != null
        ? (hips - shoulders).distance
        : left != null && right != null
            ? (left.offset - right.offset).distance * 1.6
            : null;
    if (scale == null || scale < 1) return null;
    final height = (wrists.dy - shoulders.dy) / scale;

    // Widen the range to what's been seen, and let it relax slowly so an
    // odd frame doesn't stretch it for good.
    var low = _low ?? height;
    var high = _high ?? height;
    low = math.min(low, height);
    high = math.max(high, height);
    final mid = (low + high) / 2;
    _low = low + (mid - low) * 0.002;
    _high = high - (high - mid) * 0.002;
    final range = high - low;
    // Too little movement yet to tell up from down.
    if (range < 0.2) return 0;

    return (1 - (height - low) / range).clamp(0.0, 1.0);
  }

  /// The body line from the side: the angle at the hips between the
  /// shoulders and the ankles (or knees, when the feet are out of view).
  PushupForm _form(PosePoint? Function(Joint) seen) {
    for (final (shoulder, hip, knee, ankle) in const [
      (Joint.leftShoulder, Joint.leftHip, Joint.leftKnee, Joint.leftAnkle),
      (Joint.rightShoulder, Joint.rightHip, Joint.rightKnee, Joint.rightAnkle),
    ]) {
      final s = seen(shoulder);
      final h = seen(hip);
      final end = seen(ankle) ?? seen(knee);
      if (s == null || h == null || end == null) continue;
      if (angleAt(s, h, end) >= 155) return PushupForm.good;
      // Which side of the shoulder-to-feet line are the hips on? Below it
      // (larger y) is a sag, above it a pike.
      final along = (h.x - s.x) / (end.x - s.x == 0 ? 1e-6 : end.x - s.x);
      final lineY = s.y + (end.y - s.y) * along;

      return h.y > lineY ? PushupForm.sagging : PushupForm.piking;
    }

    return PushupForm.unknown;
  }

  static Offset? _mid(PosePoint? a, PosePoint? b) =>
      a != null && b != null ? (a.offset + b.offset) / 2 : (a ?? b)?.offset;
}

/// The angle at [b] between [a] and [c], in degrees.
double angleAt(PosePoint a, PosePoint b, PosePoint c) {
  final ab = a.offset - b.offset;
  final cb = c.offset - b.offset;
  final cos = (ab.dx * cb.dx + ab.dy * cb.dy) / (ab.distance * cb.distance);

  return math.acos(cos.clamp(-1.0, 1.0)) * 180 / math.pi;
}
