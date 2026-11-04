/// How pushups are counted: from the AirPods' motion sensors, or by
/// watching the body through the front camera.
enum TrackingMode {
  airpods,
  camera;

  static TrackingMode byName(String? name) => TrackingMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => TrackingMode.airpods,
      );
}

/// What the camera window shows while the camera counts.
enum CameraView {
  /// The player, cut out of the room, with the skeleton on top.
  person,

  /// Only the skeleton, on the jungle's colours: no picture of the player.
  skeleton;

  static CameraView byName(String? name) => CameraView.values.firstWhere(
        (view) => view.name == name,
        orElse: () => CameraView.person,
      );
}

/// How hard the AirPods have to move before a pushup counts, from 1 (only
/// big, deep pushups) to [max] (the smallest dip counts).
abstract final class AirPodsSensitivity {
  static const min = 1;
  static const max = 10;
  static const standard = 5;

  /// The head acceleration (in g) that starts and finishes a pushup at
  /// [level]; the standard level is the original 0.3 g.
  static double threshold(int level) => const [
        0.55,
        0.48,
        0.42,
        0.36,
        0.30,
        0.26,
        0.22,
        0.18,
        0.15,
        0.12,
      ][level.clamp(min, max) - 1];
}
