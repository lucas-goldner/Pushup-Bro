import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/calorie_estimator.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/onboarding/model/body_units.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_plan.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CalorieEstimator', () {
    test('burns about 0.37 kcal a pushup at 82 kg', () {
      expect(CalorieEstimator.kcal(1, weightKg: 82), closeTo(0.369, 0.001));
      expect(CalorieEstimator.roundedKcal(125, weightKg: 82), 46);
    });

    test('assumes 75 kg without a weight', () {
      expect(CalorieEstimator.kcal(100), closeTo(33.75, 0.001));
    });

    test('shows at least 1 kcal for a set and nothing for none', () {
      expect(CalorieEstimator.roundedKcal(1, weightKg: 50), 1);
      expect(CalorieEstimator.roundedKcal(0), 0);
    });
  });

  group('BodyUnits', () {
    test('converts kg and pounds both ways', () {
      expect(BodyUnits.poundsFromKg(82), closeTo(180.78, 0.01));
      expect(BodyUnits.kgFromPounds(180.78), closeTo(82, 0.01));
    });

    test('shows height in cm or feet and inches', () {
      expect(BodyUnits.height(180, UnitSystem.metric), '180');
      expect(BodyUnits.height(180, UnitSystem.imperial), '5′11″');
      expect(BodyUnits.feetAndInches(152.4), (5, 0));
    });

    test('shows whole kilograms or pounds', () {
      expect(BodyUnits.weight(82.4, UnitSystem.metric), 82);
      expect(BodyUnits.weight(82, UnitSystem.imperial), 181);
    });
  });

  group('OnboardingAnswers', () {
    const answers = OnboardingAnswers(
      goals: {OnboardingGoal.energy, OnboardingGoal.strength},
      maxInARow: 12,
      frequency: WorkoutFrequency.sometimes,
      heightCm: 180,
      weightKg: 82,
      goalWeightKg: 76,
      units: UnitSystem.imperial,
      dailyGoal: 40,
    );

    test('survives a JSON round trip', () {
      expect(OnboardingAnswers.decode(answers.encode()), answers);
    });

    test('stores the goals in a fixed order', () {
      expect(answers.toJson()['goals'], ['strength', 'energy']);
    });

    test('starts fresh from nothing or garbage', () {
      expect(OnboardingAnswers.decode(null), const OnboardingAnswers());
      expect(OnboardingAnswers.decode('{nope'), const OnboardingAnswers());
    });

    test('ignores goals and frequencies it no longer knows', () {
      final decoded = OnboardingAnswers.decode(
        '{"goals":["strength","flying"],"frequency":"hourly"}',
      );
      expect(decoded.goals, {OnboardingGoal.strength});
      expect(decoded.frequency, isNull);
    });
  });

  group('OnboardingPlan', () {
    final today = DateTime(2026, 10, 28);

    test('aims for 30 in a row, about 2.5 more each week', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(maxInARow: 12),
        today: today,
      );
      expect(plan.targetInARow, 30);
      expect(plan.weeksToTarget, 8);
      expect(plan.targetDate, DateTime(2026, 12, 23));
    });

    test('aims 10 higher for players who already do 30', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(maxInARow: 42),
        today: today,
      );
      expect(plan.targetInARow, 55);
    });

    test('never promises less than two weeks', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(maxInARow: 29),
        today: today,
      );
      expect(plan.weeksToTarget, 2);
    });

    test('loses half a kilo a week towards the goal weight', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(weightKg: 82, goalWeightKg: 76),
        today: today,
      );
      expect(plan.weightDirection, WeightDirection.lose);
      expect(plan.weightChangeKg, -6);
      expect(plan.monthsToGoalWeight, 3);
    });

    test('keeps the weight when the goal is within half a kilo', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(weightKg: 82, goalWeightKg: 82.3),
        today: today,
      );
      expect(plan.weightDirection, WeightDirection.keep);
    });

    test('gains muscle a quarter kilo a week, at least a month', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(weightKg: 70, goalWeightKg: 71),
        today: today,
      );
      expect(plan.weightDirection, WeightDirection.gain);
      expect(plan.monthsToGoalWeight, 1);
    });

    test('works out the daily calories and minutes', () {
      final plan = OnboardingPlan(
        const OnboardingAnswers(weightKg: 82),
        today: today,
      );
      expect(plan.dailyKcal, 11);
      expect(plan.dailyMinutes, 8);
    });
  });

  group('OnboardingStep.flow', () {
    test('has all 21 steps for a new player', () {
      expect(
        OnboardingStep.flow(hasPushups: false, isPro: false),
        OnboardingStep.values,
      );
      expect(OnboardingStep.values, hasLength(21));
    });

    test('skips the first set for players who already have sets', () {
      final flow = OnboardingStep.flow(hasPushups: true, isPro: false);
      expect(flow, isNot(contains(OnboardingStep.firstSet)));
      expect(flow, isNot(contains(OnboardingStep.reward)));
      expect(flow, contains(OnboardingStep.plan));
    });

    test('skips the paywall for Pro members', () {
      final flow = OnboardingStep.flow(hasPushups: false, isPro: true);
      expect(flow.last, OnboardingStep.plan);
    });
  });

  group('OnboardingCubit', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts not completed with empty answers', () async {
      final cubit = OnboardingCubit(SharedPreferencesProvider());
      await cubit.load();
      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.completed, isFalse);
      expect(cubit.state.answers, const OnboardingAnswers());
    });

    test('keeps answers and completion across launches', () async {
      final first = OnboardingCubit(SharedPreferencesProvider());
      await first.load();
      await first.answer(const OnboardingAnswers(weightKg: 82));
      await first.complete();

      final second = OnboardingCubit(SharedPreferencesProvider());
      await second.load();
      expect(second.state.completed, isTrue);
      expect(second.state.answers.weightKg, 82);
    });
  });
}
