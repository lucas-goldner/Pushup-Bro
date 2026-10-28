/// Metric or imperial, for showing height and weight. Answers are always
/// stored in metric.
enum UnitSystem {
  metric,
  imperial;

  static UnitSystem fromName(String? name) =>
      name == imperial.name ? imperial : metric;
}

abstract final class BodyUnits {
  static const double cmPerInch = 2.54;
  static const double kgPerPound = 0.45359237;

  static double poundsFromKg(double kg) => kg / kgPerPound;
  static double kgFromPounds(double pounds) => pounds * kgPerPound;

  /// Whole feet and the inches left over, e.g. 180 cm is (5, 11).
  static (int feet, int inches) feetAndInches(double cm) {
    final totalInches = (cm / cmPerInch).round();
    return (totalInches ~/ 12, totalInches % 12);
  }

  static double cmFromFeetAndInches(int feet, int inches) =>
      (feet * 12 + inches) * cmPerInch;

  /// The height to show, like "180" (cm) or "5′11″".
  static String height(double cm, UnitSystem units) {
    if (units == UnitSystem.metric) return cm.round().toString();
    final (feet, inches) = feetAndInches(cm);
    return '$feet′$inches″';
  }

  /// The weight to show as a whole number in kg or lb.
  static int weight(double kg, UnitSystem units) =>
      (units == UnitSystem.metric ? kg : poundsFromKg(kg)).round();
}
