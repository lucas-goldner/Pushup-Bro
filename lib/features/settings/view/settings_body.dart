import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/onboarding/model/body_units.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/steps/body_steps.dart';
import 'package:pushup_bro/features/onboarding/widgets/onboarding_kit.dart';

/// Height, weight and goal weight from the onboarding, to change later.
/// Used for the calories burned; stays on the phone.
class BodySetting extends StatelessWidget {
  const BodySetting({super.key});
  static const routeName = '/body';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.watch<OnboardingCubit>();
    final answers = cubit.state.answers;
    final units = answers.units;
    final metric = units == UnitSystem.metric;
    final height = answers.heightCm ?? OnboardingAnswers.defaultHeightCm;
    final weight = answers.weightKg ?? OnboardingAnswers.defaultWeightKg;
    final goal = answers.goalWeightKg ?? weight;

    Widget section(String title, String value, Widget ruler) => Padding(
          padding: const EdgeInsets.only(bottom: PBSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(title, style: context.textTheme.titleMedium),
                  const Spacer(),
                  Text(value, style: context.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: PBSpace.sm),
              ruler,
            ],
          ),
        );

    return CupertinoPageScaffold(
      backgroundColor: context.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.xl,
                PBSpace.lg,
                PBSpace.xl,
                PBSpace.lg,
              ),
              child: Text(
                l.bodySettingsTitle,
                style: context.textTheme.headlineLarge,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: PBSpace.xl),
                children: [
                  Row(
                    children: [
                      Text(l.bodyUnits, style: context.textTheme.titleMedium),
                      const Spacer(),
                      UnitToggle(
                        values: UnitSystem.values,
                        labels: [l.bodyMetric, l.bodyImperial],
                        value: units,
                        onChanged: (value) =>
                            cubit.answer(answers.copyWith(units: value)),
                      ),
                    ],
                  ),
                  const SizedBox(height: PBSpace.xl),
                  section(
                    l.bodyHeight,
                    metric
                        ? '${height.round()} ${l.onbUnitCm}'
                        : BodyUnits.height(height, units),
                    RulerPicker(
                      key: ValueKey(('height', units)),
                      min: metric ? 120 : 48,
                      max: metric ? 220 : 90,
                      labelEvery: metric ? 10 : 12,
                      label: metric ? null : (value) => '${value ~/ 12}′',
                      value: metric
                          ? height.round()
                          : (height / BodyUnits.cmPerInch).round(),
                      onChanged: (value) => cubit.answer(
                        answers.copyWith(
                          heightCm: metric
                              ? value.toDouble()
                              : value * BodyUnits.cmPerInch,
                        ),
                      ),
                    ),
                  ),
                  section(
                    l.bodyWeight,
                    formatWeight(l, weight, units),
                    _weightRuler(
                      key: ValueKey(('weight', units)),
                      kg: weight,
                      units: units,
                      onChanged: (kg) =>
                          cubit.answer(answers.copyWith(weightKg: kg)),
                    ),
                  ),
                  section(
                    l.bodyGoalWeight,
                    formatWeight(l, goal, units),
                    _weightRuler(
                      key: ValueKey(('goal', units)),
                      kg: goal,
                      units: units,
                      color: context.gameColors.leaf,
                      onChanged: (kg) =>
                          cubit.answer(answers.copyWith(goalWeightKg: kg)),
                    ),
                  ),
                  Text(l.bodyFooter, style: context.textTheme.bodySmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.sm,
                PBSpace.sm,
                PBSpace.sm,
                PBSpace.lg,
              ),
              child: PBButton(
                l.bodyDone,
                callback: () => Navigator.of(context).pop(),
                expanded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _weightRuler({
    required Key key,
    required double kg,
    required UnitSystem units,
    required ValueChanged<double> onChanged,
    Color? color,
  }) {
    final metric = units == UnitSystem.metric;

    return RulerPicker(
      key: key,
      min: metric ? 30 : 66,
      max: metric ? 200 : 440,
      value: BodyUnits.weight(kg, units),
      color: color,
      onChanged: (value) => onChanged(
        metric ? value.toDouble() : BodyUnits.kgFromPounds(value.toDouble()),
      ),
    );
  }
}
