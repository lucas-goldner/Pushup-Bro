import 'dart:math' as math;
import 'dart:ui' show Offset;

/// The body points the pushup tracker looks at (a subset of the 33 that
/// BlazePose, the model behind ML Kit's and MediaPipe's pose detection,
/// finds).
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
/// The main signal is the elbow angle (straight arms at the top, bent past
/// about 90° at the bottom), which works from the side and at an angle.
/// When the elbows can't be seen, it falls back on how high the shoulders
/// are above the wrists, relative to the torso, which also works from the
/// front; that one is normalised by the range seen so far, so it adapts to
/// wherever the phone is. Both are smoothed, and a pushup only counts with
/// hysteresis (deep enough to go down, high enough to come back up) and a
/// minimum time at the bottom, so jitter never counts twice.
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

  /// Starts over, forgetting the range seen so far.
  void reset() {
    _depth = null;
    _down = false;
    _downSince = null;
    _low = null;
    _high = null;
  }

  PushupReading update(Map<Joint, PosePoint> pose, Duration time) {
    PosePoint? seen(Joint joint) {
      final point = pose[joint];
      return point != null && point.likelihood >= minLikelihood ? point : null;
    }

    final raw = _elbowDepth(seen) ?? _shoulderDepth(seen);
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
      form: _form(seen),
      wentDown: wentDown,
      cameUp: cameUp,
    );
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
