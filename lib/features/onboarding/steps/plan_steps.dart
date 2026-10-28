import 'dart:async';
import 'dart:math' as math;

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_plan.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/onboarding/steps/body_steps.dart';
import 'package:pushup_bro/features/onboarding/widgets/onboarding_kit.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// A day like "Dec 9" in the app's language.
String shortDate(BuildContext context, DateTime date) =>
    DateFormat.MMMd(Localizations.localeOf(context).toString()).format(date);

/// CalAI-style projection from their own max, with a date.
class ChartStep extends StatelessWidget {
  const ChartStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = OnboardingPlan(args.answers, today: DateTime.now());

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbChartTitle(args.answers.maxInARow, plan.targetInARow)),
        OnbSub(l.onbChartSub(shortDate(context, plan.targetDate))),
        const SizedBox(height: PBSpace.xl),
        Expanded(
          child: Reveal(
            at: 0.6,
            child: OnbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ProjectionChart(plan: plan)),
                  const SizedBox(height: PBSpace.sm),
                  Row(
                    children: [
                      Text(
                        l.onbChartToday,
                        style: context.textTheme.labelSmall,
                      ),
                      const Spacer(),
                      Text(
                        shortDate(context, plan.targetDate),
                        style: context.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: PBSpace.md),
                  Wrap(
                    spacing: PBSpace.lg,
                    runSpacing: PBSpace.xs,
                    children: [
                      _Legend(context.colorScheme.secondary, l.onbChartWithBro),
                      _Legend(context.colorScheme.outline, l.onbChartAlone),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: PBSpace.xl),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: PBSpace.xs + 2),
          Text(label, style: context.textTheme.labelMedium),
        ],
      );
}

/// The player's line rising to the target, drawn in, against a flat line
/// for going it alone.
class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.plan});

  final OnboardingPlan plan;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);
    final style = context.textTheme.titleMedium;

    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = Curves.easeInOutCubic
            .transform(((clock.value - 1) / 1.6).clamp(0.0, 1.0));

        return CustomPaint(
          painter: _ChartPainter(
            progress: t,
            from: plan.answers.maxInARow,
            to: plan.targetInARow,
            bro: context.colorScheme.secondary,
            alone: context.colorScheme.outline,
            grid: context.colorScheme.onSurface.withValues(alpha: 0.06),
            label: style?.copyWith(color: context.colorScheme.secondary),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.progress,
    required this.from,
    required this.to,
    required this.bro,
    required this.alone,
    required this.grid,
    required this.label,
  });

  final double progress;
  final int from;
  final int to;
  final Color bro;
  final Color alone;
  final Color grid;
  final TextStyle? label;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 28.0;
    final height = size.height - top - 8;
    double y(double reps) => top + height * (1 - reps / (to * 1.08));

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final gy = top + height * i / 4;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    Path curve(double end) {
      final path = Path()..moveTo(0, y(from.toDouble()));
      const steps = 40;
      for (var i = 1; i <= steps; i++) {
        final x = i / steps;
        // Fast gains first, then steady: an ease-out curve.
        final eased = 1 - math.pow(1 - x, 2.2).toDouble();
        path.lineTo(size.width * x, y(from + (end - from) * eased));
      }
      return path;
    }

    void drawPartial(Path path, Paint paint) {
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
      }
    }

    drawPartial(
      curve(from + (to - from) * 0.25),
      Paint()
        ..color = alone
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    drawPartial(
      curve(to.toDouble()),
      Paint()
        ..color = bro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = bro;
    canvas.drawCircle(Offset(0, y(from.toDouble())), 6, dotPaint);
    if (progress > 0.98) {
      final end = Offset(size.width, y(to.toDouble()));
      canvas.drawCircle(end, 7, dotPaint);
      final text = TextPainter(
        text: TextSpan(text: '$to', style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, end - Offset(text.width + 10, text.height + 6));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}

/// What the first four weeks bring.
class MonthStep extends StatelessWidget {
  const MonthStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final weeks = [
      (game.banana, CarbonIcons.calendar, l.onbMonthWeek1),
      (game.leaf, CarbonIcons.tree, l.onbMonthWeek2),
      (game.red, CarbonIcons.lightning, l.onbMonthWeek3),
      (game.purple, CarbonIcons.trophy, l.onbMonthWeek4),
    ];

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbMonthTitle),
        OnbSub(l.onbMonthSub),
        const SizedBox(height: PBSpace.xl),
        for (final (i, (color, icon, text)) in weeks.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: PBSpace.sm + 2),
            child: Reveal(
              at: 0.7 + i * 0.3,
              child: OnbCard(
                padding: const EdgeInsets.all(PBSpace.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: game.onGame, size: 20),
                    ),
                    const SizedBox(width: PBSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.onbMonthWeek(i + 1),
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(text, style: context.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The daily goal with a rolling number.
class DailyStep extends StatelessWidget {
  const DailyStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = OnboardingPlan(args.answers, today: DateTime.now());

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbDailyTitle),
        OnbSub(l.onbDailySub),
        const Spacer(),
        Center(
          child: Reveal(
            at: 0.6,
            child: BigNumber(
              value: args.answers.dailyGoal,
              unit: l.onbPushupsUnit,
              size: 120,
            ),
          ),
        ),
        const SizedBox(height: PBSpace.sm),
        Center(
          child: Reveal(
            at: 0.8,
            child: Text(
              l.onbDailyMinutes(plan.dailyMinutes),
              style: context.textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: PBSpace.xl),
        Reveal(
          at: 0.7,
          child: RulerPicker(
            min: 5,
            max: 150,
            value: args.answers.dailyGoal,
            introFrom: 5,
            color: context.gameColors.banana,
            onChanged: (value) =>
                args.answer(args.answers.copyWith(dailyGoal: value)),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

/// Primes the notification permission with a preview of the reminder.
class ReminderStep extends StatefulWidget {
  const ReminderStep(this.args, {super.key});

  final StepArgs args;

  @override
  State<ReminderStep> createState() => _ReminderStepState();
}

class _ReminderStepState extends State<ReminderStep> {
  bool _asking = false;

  Future<void> _allow() async {
    if (_asking) return;
    setState(() => _asking = true);
    await context.read<RemindersCubit>().setEnabled(enabled: true);
    if (mounted) widget.args.next();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<RemindersCubit>().state.settings;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: settings.hour, minute: settings.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return StepLayout(
      cta: PBButton(l.onbReminderAllow, callback: _allow, expanded: true),
      secondary: OnbTextButton(l.onbNotNow, onTap: widget.args.next),
      children: [
        OnbTitle(l.onbReminderTitle, accent: context.gameColors.banana),
        OnbSub(l.onbReminderSub(time)),
        const Spacer(),
        Pop(
          at: 1,
          duration: 0.6,
          child: OnbCard(
            padding: const EdgeInsets.all(PBSpace.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Assets.images.appIcons.classic.image(
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pushup Bro',
                            style: context.textTheme.labelLarge,
                          ),
                          const Spacer(),
                          Text(time, style: context.textTheme.labelSmall),
                        ],
                      ),
                      Text(
                        l.onbReminderPreview,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

/// A short loading moment that makes the plan feel computed.
class BuildingStep extends StatefulWidget {
  const BuildingStep(this.args, {super.key});

  final StepArgs args;

  @override
  State<BuildingStep> createState() => _BuildingStepState();
}

class _BuildingStepState extends State<BuildingStep> {
  Timer? _done;

  @override
  void initState() {
    super.initState();
    _done = Timer(const Duration(milliseconds: 4400), () {
      GameAudio.instance.play(Sfx.star);
      widget.args.next();
    });
  }

  @override
  void dispose() {
    _done?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final answers = args.answers;
    final weight = answers.weightKg;
    final items = [
      l.onbBuildMax(answers.maxInARow),
      if (weight != null)
        l.onbBuildCalories(formatWeight(l, weight, answers.units)),
      l.onbBuildDaily(answers.dailyGoal),
      l.onbBuildQuest,
    ];
    final clock = MotionClock.of(context);

    return StepLayout(
      center: true,
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: clock,
          builder: (context, _) {
            final t = Curves.easeInOutCubic
                .transform(((clock.value - 0.2) / 3.4).clamp(0.0, 1.0));

            return SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: t,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    color: context.colorScheme.secondary,
                    backgroundColor: context.colorScheme.surfaceContainer,
                  ),
                  Center(
                    child: AnimatedFlipCounter(
                      value: (t * 100).round(),
                      suffix: '%',
                      textStyle: context.textTheme.displayMedium,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: PBSpace.xxl),
        OnbTitle(l.onbBuildingTitle, center: true, at: 0.3),
        const SizedBox(height: PBSpace.xl),
        for (final (i, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: PBSpace.md),
            child: Reveal(
              at: 0.8 + i * 0.8,
              offset: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pop(
                    at: 0.9 + i * 0.8,
                    child: CheckDot(color: context.gameColors.leaf, size: 22),
                  ),
                  const SizedBox(width: PBSpace.sm + 2),
                  Flexible(
                    child: Text(item, style: context.textTheme.titleSmall),
                  ),
                ],
              ),
            ),
          ),
        const Spacer(flex: 2),
      ],
    );
  }

  StepArgs get args => widget.args;
}
