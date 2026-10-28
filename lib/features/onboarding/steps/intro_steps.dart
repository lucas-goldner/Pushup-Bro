import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/onboarding/widgets/onboarding_kit.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// "You've started working out a hundred times." Carlos waves in.
class HookStep extends StatelessWidget {
  const HookStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return StepLayout(
      cta: PBButton(l.onbGetStarted, callback: args.next, expanded: true),
      secondary: Reveal(
        at: 1.2,
        child: Padding(
          padding: const EdgeInsets.only(top: PBSpace.md),
          child: Text(l.onbTakesTwoMinutes, style: context.textTheme.bodySmall),
        ),
      ),
      children: [
        Expanded(
          child: Center(
            child: Reveal(
              at: 0.1,
              duration: 0.9,
              offset: 80,
              child: Assets.images.proHeroWave.image(height: 260),
            ),
          ),
        ),
        OnbTitle(l.onbHookLine1, at: 0.8, accent: context.gameColors.banana),
        const SizedBox(height: PBSpace.sm),
        OnbTitle(l.onbHookLine2, at: 1.8, accent: context.gameColors.banana),
        const SizedBox(height: PBSpace.xxl),
      ],
    );
  }
}

/// What they want from their pushups; more than one.
class GoalStep extends StatelessWidget {
  const GoalStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final goals = args.answers.goals;
    final options = [
      (OnboardingGoal.strength, CarbonIcons.fire, l.onbGoalStrength),
      (OnboardingGoal.look, CarbonIcons.user, l.onbGoalLook),
      (OnboardingGoal.energy, CarbonIcons.flash, l.onbGoalEnergy),
      (OnboardingGoal.habit, CarbonIcons.calendar, l.onbGoalHabit),
      (OnboardingGoal.record, CarbonIcons.trophy, l.onbGoalRecord),
    ];

    return StepLayout(
      scroll: true,
      cta: PBButton(
        l.onbContinue,
        callback: goals.isEmpty ? null : args.next,
        expanded: true,
      ),
      children: [
        OnbTitle(l.onbGoalTitle),
        OnbSub(l.onbGoalSub),
        const SizedBox(height: PBSpace.xl),
        for (final (i, (goal, icon, label)) in options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: PBSpace.sm + 2),
            child: Reveal(
              at: 0.7 + i * 0.08,
              child: OnbOption(
                label: label,
                icon: icon,
                selected: goals.contains(goal),
                onTap: () => args.answer(
                  args.answers.copyWith(
                    goals: goals.contains(goal)
                        ? ({...goals}..remove(goal))
                        : {...goals, goal},
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// How many in a row, on a ruler that rolls in.
class MaxStep extends StatelessWidget {
  const MaxStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final max = args.answers.maxInARow;

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbMaxTitle),
        OnbSub(l.onbMaxSub),
        const Spacer(),
        Center(
          child: Reveal(
            at: 0.6,
            child: BigNumber(value: max, unit: l.onbPushupsUnit, size: 120),
          ),
        ),
        const SizedBox(height: PBSpace.xl),
        Reveal(
          at: 0.7,
          child: RulerPicker(
            min: 0,
            max: 100,
            value: max,
            introFrom: 0,
            onChanged: (value) =>
                args.answer(args.answers.copyWith(maxInARow: value)),
          ),
        ),
        const Spacer(),
        Reveal(
          at: 1.2,
          offset: 40,
          child: Center(
            child: Assets.images.proHeroPushup.image(height: 150),
          ),
        ),
      ],
    );
  }
}

/// How often they trained last month.
class OftenStep extends StatelessWidget {
  const OftenStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = [
      (WorkoutFrequency.never, l.onbOftenNever, l.onbOftenNeverHint),
      (
        WorkoutFrequency.sometimes,
        l.onbOftenSometimes,
        l.onbOftenSometimesHint
      ),
      (WorkoutFrequency.often, l.onbOftenOften, l.onbOftenOftenHint),
      (WorkoutFrequency.daily, l.onbOftenDaily, l.onbOftenDailyHint),
    ];

    return StepLayout(
      scroll: true,
      cta: PBButton(
        l.onbContinue,
        callback: args.answers.frequency == null ? null : args.next,
        expanded: true,
      ),
      children: [
        OnbTitle(l.onbOftenTitle),
        const SizedBox(height: PBSpace.xl),
        for (final (i, (frequency, label, hint)) in options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: PBSpace.sm + 2),
            child: Reveal(
              at: 0.6 + i * 0.08,
              child: OnbOption(
                label: label,
                hint: hint,
                selected: args.answers.frequency == frequency,
                onTap: () =>
                    args.answer(args.answers.copyWith(frequency: frequency)),
              ),
            ),
          ),
      ],
    );
  }
}
