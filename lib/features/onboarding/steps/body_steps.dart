import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/onboarding/model/body_units.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_plan.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/onboarding/widgets/onboarding_kit.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// A weight in the player's units with its unit, like "82 kg".
String formatWeight(S l, double kg, UnitSystem units) =>
    '${BodyUnits.weight(kg, units)} '
    '${units == UnitSystem.metric ? l.onbUnitKg : l.onbUnitLb}';

/// cm or ft / in.
class _HeightUnits extends StatelessWidget {
  const _HeightUnits(this.args);

  final StepArgs args;

  @override
  Widget build(BuildContext context) => Reveal(
        at: 0.6,
        child: UnitToggle(
          values: UnitSystem.values,
          labels: [context.l10n.onbUnitCm, context.l10n.onbUnitFtIn],
          value: args.answers.units,
          onChanged: (units) =>
              args.answer(args.answers.copyWith(units: units)),
        ),
      );
}

/// kg or lb.
class _WeightUnits extends StatelessWidget {
  const _WeightUnits(this.args);

  final StepArgs args;

  @override
  Widget build(BuildContext context) => Reveal(
        at: 0.6,
        child: UnitToggle(
          values: UnitSystem.values,
          labels: [context.l10n.onbUnitKg, context.l10n.onbUnitLb],
          value: args.answers.units,
          onChanged: (units) =>
              args.answer(args.answers.copyWith(units: units)),
        ),
      );
}

/// How tall: a vertical ruler next to Carlos.
class HeightStep extends StatelessWidget {
  const HeightStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final answers = args.answers;
    final cm = answers.heightCm ?? OnboardingAnswers.defaultHeightCm;
    final metric = answers.units == UnitSystem.metric;
    final inches = (cm / BodyUnits.cmPerInch).round();

    return StepLayout(
      cta: PBButton(
        l.onbContinue,
        callback: () {
          args
            ..answer(answers.copyWith(heightCm: cm))
            ..next();
        },
        expanded: true,
      ),
      children: [
        OnbTitle(l.onbHeightTitle),
        OnbSub(l.onbHeightSub),
        const SizedBox(height: PBSpace.lg),
        Center(child: _HeightUnits(args)),
        const SizedBox(height: PBSpace.md),
        Center(
          child: Reveal(
            at: 0.7,
            child: BigNumber(
              value: cm.round(),
              text: metric ? null : BodyUnits.height(cm, answers.units),
              unit: metric ? l.onbUnitCm : null,
            ),
          ),
        ),
        const SizedBox(height: PBSpace.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Reveal(
                  at: 1,
                  offset: 60,
                  child: Assets.images.proHeroWave.image(fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: PBSpace.lg),
              Reveal(
                at: 0.8,
                child: SizedBox(
                  height: double.infinity,
                  child: metric
                      ? RulerPicker(
                          key: const ValueKey('cm'),
                          vertical: true,
                          min: 120,
                          max: 220,
                          value: cm.round(),
                          introFrom: 140,
                          onChanged: (value) => args.answer(
                            answers.copyWith(heightCm: value.toDouble()),
                          ),
                        )
                      : RulerPicker(
                          key: const ValueKey('in'),
                          vertical: true,
                          min: 48,
                          max: 90,
                          value: inches,
                          labelEvery: 12,
                          label: (value) => '${value ~/ 12}′',
                          onChanged: (value) => args.answer(
                            answers.copyWith(
                              heightCm: value * BodyUnits.cmPerInch,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The current weight on a sliding ruler, private by design.
class WeightStep extends StatelessWidget {
  const WeightStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final answers = args.answers;
    final kg = answers.weightKg ?? OnboardingAnswers.defaultWeightKg;

    return StepLayout(
      cta: PBButton(
        l.onbContinue,
        callback: () {
          args
            ..answer(answers.copyWith(weightKg: kg))
            ..next();
        },
        expanded: true,
      ),
      children: [
        OnbTitle(l.onbWeightTitle),
        OnbSub(l.onbWeightSub),
        const SizedBox(height: PBSpace.lg),
        Center(child: _WeightUnits(args)),
        const Spacer(),
        Center(
          child: Reveal(
            at: 0.7,
            child: BigNumber(
              value: BodyUnits.weight(kg, answers.units),
              unit: answers.units == UnitSystem.metric
                  ? l.onbUnitKg
                  : l.onbUnitLb,
              size: 112,
            ),
          ),
        ),
        const SizedBox(height: PBSpace.xl),
        Reveal(
          at: 0.8,
          child: _WeightRuler(
            kg: kg,
            units: answers.units,
            introFromKg: 40,
            onChanged: (value) =>
                args.answer(answers.copyWith(weightKg: value)),
          ),
        ),
        const SizedBox(height: PBSpace.lg),
        Reveal(
          at: 1.4,
          child: OnbCard(
            padding: const EdgeInsets.all(PBSpace.md),
            child: Row(
              children: [
                Icon(
                  CarbonIcons.locked,
                  size: 18,
                  color: context.colorScheme.secondary,
                ),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Text(
                    l.onbWeightPrivate,
                    style: context.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

/// The goal weight, always told as something doable.
class GoalWeightStep extends StatelessWidget {
  const GoalWeightStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final answers = args.answers;
    final weight = answers.weightKg ?? OnboardingAnswers.defaultWeightKg;
    final goal = answers.goalWeightKg ?? weight;
    final plan = OnboardingPlan(
      answers.copyWith(weightKg: weight, goalWeightKg: goal),
      today: DateTime.now(),
    );
    final green = context.gameColors.leaf;

    return StepLayout(
      cta: PBButton(
        l.onbContinue,
        callback: () {
          args
            ..answer(answers.copyWith(goalWeightKg: goal))
            ..next();
        },
        expanded: true,
      ),
      children: [
        OnbTitle(l.onbGoalWeightTitle),
        OnbSub(l.onbGoalWeightSub),
        const SizedBox(height: PBSpace.lg),
        Center(
          child: Reveal(
            at: 0.6,
            child: BigNumber(
              value: BodyUnits.weight(goal, answers.units),
              unit: answers.units == UnitSystem.metric
                  ? l.onbUnitKg
                  : l.onbUnitLb,
              color: green,
              size: 112,
            ),
          ),
        ),
        const SizedBox(height: PBSpace.lg),
        Reveal(
          at: 0.7,
          child: _WeightRuler(
            kg: goal,
            units: answers.units,
            introFromKg: weight,
            color: green,
            onChanged: (value) =>
                args.answer(answers.copyWith(goalWeightKg: value)),
          ),
        ),
        const SizedBox(height: PBSpace.lg),
        Pop(
          at: 1.6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
            child: _GoalMessage(
              key: ValueKey(plan.weightDirection),
              plan: plan,
              units: answers.units,
            ),
          ),
        ),
        Expanded(
          child: Reveal(
            at: 2,
            offset: 50,
            child: Assets.images.proHeroDance.image(fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

class _GoalMessage extends StatelessWidget {
  const _GoalMessage({required this.plan, required this.units, super.key});

  final OnboardingPlan plan;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final change = formatWeight(l, plan.weightChangeKg.abs(), units);
    final (title, body) = switch (plan.weightDirection) {
      WeightDirection.lose => (
          l.onbGoalWeightLose('−$change'),
          l.onbGoalWeightPace(plan.monthsToGoalWeight),
        ),
      WeightDirection.gain => (
          l.onbGoalWeightGain('+$change'),
          l.onbGoalWeightPace(plan.monthsToGoalWeight),
        ),
      WeightDirection.keep => (l.onbGoalWeightKeep, l.onbGoalWeightKeepBody),
    };

    return OnbCard(
      color: context.gameColors.leaf,
      child: Row(
        children: [
          Icon(CarbonIcons.trophy, color: context.gameColors.onGame),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium
                      ?.copyWith(color: context.gameColors.onGame),
                ),
                Text(
                  body,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.gameColors.onGame.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal ruler in kg or lb that reports kilograms.
class _WeightRuler extends StatelessWidget {
  const _WeightRuler({
    required this.kg,
    required this.units,
    required this.onChanged,
    this.introFromKg,
    this.color,
  });

  final double kg;
  final UnitSystem units;
  final ValueChanged<double> onChanged;
  final double? introFromKg;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final metric = units == UnitSystem.metric;
    final from = introFromKg;

    return RulerPicker(
      key: ValueKey(units),
      min: metric ? 30 : 66,
      max: metric ? 200 : 440,
      value: BodyUnits.weight(kg, units),
      introFrom: from == null ? null : BodyUnits.weight(from, units),
      color: color,
      onChanged: (value) => onChanged(
        metric ? value.toDouble() : BodyUnits.kgFromPounds(value.toDouble()),
      ),
    );
  }
}
