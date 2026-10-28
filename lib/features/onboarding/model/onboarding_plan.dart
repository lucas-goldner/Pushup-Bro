import 'package:pushup_bro/core/model/calorie_estimator.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';

/// Where the goal weight is heading, always told as something doable.
enum WeightDirection { lose, keep, gain }

/// The plan the onboarding promises, worked out from the answers.
class OnboardingPlan {
  OnboardingPlan(this.answers, {required DateTime today}) : _today = today;

  final OnboardingAnswers answers;
  final DateTime _today;

  /// How many in a row the plan aims for: 30, or 10 more than now for
  /// players who already do 30.
  int get targetInARow {
    final max = answers.maxInARow;
    if (max < 30) return 30;
    return ((max + 10) / 5).ceil() * 5;
  }

  /// Weeks of daily sets to get from the current max to [targetInARow],
  /// about 2.5 more in a row each week, never less than two.
  int get weeksToTarget {
    final gap = targetInARow - answers.maxInARow;
    final weeks = (gap / 2.5).ceil();
    return weeks < 2 ? 2 : weeks;
  }

  DateTime get targetDate =>
      DateTime(_today.year, _today.month, _today.day + weeksToTarget * 7);

  /// About how long the daily goal takes, rests included.
  int get dailyMinutes {
    final minutes = (answers.dailyGoal / 4).ceil();
    return minutes < 3 ? 3 : minutes;
  }

  /// Calories the daily goal burns at the player's weight.
  int get dailyKcal => CalorieEstimator.roundedKcal(
        answers.dailyGoal,
        weightKg: answers.weightKg,
      );

  /// The goal weight minus the current weight, in kg.
  double get weightChangeKg {
    final weight = answers.weightKg;
    final goal = answers.goalWeightKg;
    if (weight == null || goal == null) return 0;
    return goal - weight;
  }

  WeightDirection get weightDirection {
    final change = weightChangeKg;
    if (change.abs() < 0.5) return WeightDirection.keep;
    return change < 0 ? WeightDirection.lose : WeightDirection.gain;
  }

  /// Months to the goal weight at a healthy pace: half a kilo a week to
  /// lose, a quarter to gain muscle. At least one.
  int get monthsToGoalWeight {
    final perWeek = switch (weightDirection) {
      WeightDirection.lose => 0.5,
      WeightDirection.gain => 0.25,
      WeightDirection.keep => 1.0,
    };
    final weeks = weightChangeKg.abs() / perWeek;
    final months = (weeks / 4.345).round();
    return months < 1 ? 1 : months;
  }
}
