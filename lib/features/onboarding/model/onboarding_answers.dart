import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/onboarding/model/body_units.dart';

/// What the player wants from their pushups (more than one).
enum OnboardingGoal { strength, look, energy, habit, record }

/// How often they worked out last month.
enum WorkoutFrequency { never, sometimes, often, daily }

/// Everything the onboarding asks, saved as JSON so the plan, the calorie
/// estimates and Settings can read it later. Height and weight are in
/// metric whatever [units] says.
class OnboardingAnswers extends Equatable {
  const OnboardingAnswers({
    this.goals = const {},
    this.maxInARow = defaultMaxInARow,
    this.frequency,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.units = UnitSystem.metric,
    this.dailyGoal = defaultDailyGoal,
  });

  factory OnboardingAnswers.fromJson(Map<String, dynamic> json) {
    final goals = OnboardingGoal.values.asNameMap();
    final frequencies = WorkoutFrequency.values.asNameMap();

    return OnboardingAnswers(
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((e) => goals[e])
          .whereType<OnboardingGoal>()
          .toSet(),
      maxInARow: (json['maxInARow'] as num?)?.toInt() ?? defaultMaxInARow,
      frequency: frequencies[json['frequency']],
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      goalWeightKg: (json['goalWeightKg'] as num?)?.toDouble(),
      units: UnitSystem.fromName(json['units'] as String?),
      dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? defaultDailyGoal,
    );
  }

  /// Reads what [encode] wrote; anything unreadable starts fresh.
  factory OnboardingAnswers.decode(String? source) {
    if (source == null || source.isEmpty) return const OnboardingAnswers();
    try {
      return OnboardingAnswers.fromJson(
        jsonDecode(source) as Map<String, dynamic>,
      );
    } on Object {
      return const OnboardingAnswers();
    }
  }

  static const defaultMaxInARow = 10;
  static const defaultDailyGoal = 30;
  static const defaultHeightCm = 175.0;
  static const defaultWeightKg = 75.0;

  final Set<OnboardingGoal> goals;
  final int maxInARow;
  final WorkoutFrequency? frequency;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final UnitSystem units;
  final int dailyGoal;

  OnboardingAnswers copyWith({
    Set<OnboardingGoal>? goals,
    int? maxInARow,
    WorkoutFrequency? frequency,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    UnitSystem? units,
    int? dailyGoal,
  }) =>
      OnboardingAnswers(
        goals: goals ?? this.goals,
        maxInARow: maxInARow ?? this.maxInARow,
        frequency: frequency ?? this.frequency,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        goalWeightKg: goalWeightKg ?? this.goalWeightKg,
        units: units ?? this.units,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );

  Map<String, dynamic> toJson() => {
        'goals': [
          for (final goal in OnboardingGoal.values)
            if (goals.contains(goal)) goal.name,
        ],
        'maxInARow': maxInARow,
        if (frequency != null) 'frequency': frequency!.name,
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (goalWeightKg != null) 'goalWeightKg': goalWeightKg,
        'units': units.name,
        'dailyGoal': dailyGoal,
      };

  String encode() => jsonEncode(toJson());

  @override
  List<Object?> get props => [
        goals,
        maxInARow,
        frequency,
        heightCm,
        weightKg,
        goalWeightKg,
        units,
        dailyGoal,
      ];
}
