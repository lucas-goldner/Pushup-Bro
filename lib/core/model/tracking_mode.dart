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
