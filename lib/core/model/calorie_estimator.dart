/// Rough calories burned by pushups, from the player's weight.
///
/// About 0.0045 kcal per pushup per kilogram of body weight: 0.37 kcal a
/// pushup at 82 kg. Without a weight it assumes [defaultWeightKg].
abstract final class CalorieEstimator {
  static const double kcalPerRepPerKg = 0.0045;
  static const double defaultWeightKg = 75;

  /// The calories [reps] pushups burn at [weightKg].
  static double kcal(int reps, {double? weightKg}) =>
      reps * kcalPerRepPerKg * (weightKg ?? defaultWeightKg);

  /// [kcal] rounded to whole calories, never below 1 for at least one
  /// pushup so a small set still shows something.
  static int roundedKcal(int reps, {double? weightKg}) {
    if (reps <= 0) return 0;
    final value = kcal(reps, weightKg: weightKg).round();
    return value < 1 ? 1 : value;
  }
}
