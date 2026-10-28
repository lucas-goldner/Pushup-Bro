import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/platform/store_review.dart';
import 'package:pushup_bro/core/provider/audio_player_provider.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_plan.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_step.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/onboarding/steps/body_steps.dart';
import 'package:pushup_bro/features/onboarding/steps/plan_steps.dart';
import 'package:pushup_bro/features/onboarding/widgets/onboarding_kit.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_tracker.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// Five real pushups with Carlos before any paywall, counted by the
/// AirPods or the camera, or by a tap when neither is around.
class FirstSetStep extends StatefulWidget {
  const FirstSetStep(this.args, {super.key});

  static const goal = 5;

  final StepArgs args;

  @override
  State<FirstSetStep> createState() => _FirstSetStepState();
}

class _FirstSetStepState extends State<FirstSetStep> {
  final _counter = PushupCubit(AudioPlayerProvider(AudioPlayer()));
  late final TrackingMode _mode =
      context.read<SharedPreferencesCubit>().state.trackingMode;
  late final AirPodsTrackerCubit _airpods = context.read<AirPodsTrackerCubit>();
  bool _saving = false;

  int get _volume =>
      context.read<SharedPreferencesCubit>().state.volumeLevel ?? 10;

  @override
  void initState() {
    super.initState();
    if (_mode == TrackingMode.airpods) _airpods.getAirPodsMotionData();
  }

  @override
  void dispose() {
    if (_mode == TrackingMode.airpods) _airpods.stopListening();
    unawaited(_counter.close());
    super.dispose();
  }

  void _tap() {
    _counter
      ..down()
      ..up(_volume);
  }

  Future<void> _done() async {
    if (_saving) return;
    _saving = true;
    final pushups = _counter.state.pushups;
    final prefs = context.read<SharedPreferencesCubit>();
    final db = context.read<DBCubit>();
    final inventory = context.read<GameInventoryCubit>();
    if (!await prefs.getFirstPushupCompleted()) {
      await db.createUser();
      await prefs.finishFirstPushupCompleted();
    }
    await inventory.fetchInventory();
    final current = inventory.state.inventory;
    await inventory.updateInventory(
      current.copyWith(bananas: current.bananas + pushups.length),
    );
    await db.writeNewPushupsetToDB(PushupSet(pushups, 5));
    GameAudio.instance.play(Sfx.banana);
    widget.args.next();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocProvider.value(
      value: _counter,
      child: BlocListener<AirPodsTrackerCubit, AirPodsTrackerState>(
        listener: (context, state) {
          if (state.isListening) {
            _counter.listenForPushupEvents(state.currentMotionData, _volume);
          }
        },
        child: BlocConsumer<PushupCubit, PushupState>(
          listenWhen: (a, b) => a.pushups.length != b.pushups.length,
          listener: (context, state) {
            unawaited(HapticFeedback.mediumImpact());
            if (state.pushups.length == FirstSetStep.goal) {
              GameAudio.instance.play(Sfx.star);
            }
          },
          builder: (context, state) {
            final count = state.pushups.length;
            final done = count >= FirstSetStep.goal;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: done ? null : _tap,
              child: Stack(
                children: [
                  StepLayout(
                    center: true,
                    cta: PBButton(
                      l.onbFirstSetDone,
                      callback: done ? _done : null,
                      expanded: true,
                    ),
                    secondary: OnbTextButton(
                      l.onbFirstSetSkip,
                      onTap: () => widget.args.skipTo(OnboardingStep.plan),
                    ),
                    children: [
                      OnbTitle(l.onbFirstSetTitle, center: true),
                      OnbSub(l.onbFirstSetSub, center: true),
                      const SizedBox(height: PBSpace.xl),
                      Reveal(
                        at: 0.7,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: context.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: context.cardShadow,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BigNumber(
                                value: count.clamp(0, FirstSetStep.goal),
                                size: 76,
                                color: context.colorScheme.onSurface,
                              ),
                              Text(
                                l.onbPushupsUnit.toUpperCase(),
                                style: context.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(count),
                          tween: Tween(begin: 1, end: 0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, t, child) => Transform.translate(
                            offset: Offset(0, 16 * t),
                            child: child,
                          ),
                          child: Reveal(
                            at: 0.9,
                            offset: 40,
                            child: Assets.images.proHeroPushup.image(
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < FirstSetStep.goal; i++)
                            Padding(
                              padding: const EdgeInsets.all(3),
                              child: AnimatedScale(
                                scale: i < count ? 1 : 0.6,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                child: CheckDot(
                                  color: i < count
                                      ? context.gameColors.leaf
                                      : context.colorScheme.surfaceContainer,
                                  size: 26,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: PBSpace.sm),
                      Reveal(
                        at: 1.4,
                        child: Text(
                          l.onbFirstSetTap,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (_mode == TrackingMode.camera && !done)
                    Positioned(
                      top: PBSpace.lg,
                      right: PBSpace.lg,
                      width: 96,
                      height: 128,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(PBRadius.md),
                        child: CameraTrackerView(
                          onDown: _counter.down,
                          onUp: () => _counter.up(_volume),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Day 1 done: bananas, a streak to protect, and the rating prompt at
/// the peak of the moment.
class RewardStep extends StatefulWidget {
  const RewardStep(this.args, {super.key});

  final StepArgs args;

  @override
  State<RewardStep> createState() => _RewardStepState();
}

class _RewardStepState extends State<RewardStep> {
  Timer? _review;

  @override
  void initState() {
    super.initState();
    _review = Timer(
      const Duration(milliseconds: 1800),
      () => const StoreReview().request(),
    );
  }

  @override
  void dispose() {
    _review?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sets = context.watch<DBCubit>().state.pushupSets;
    final bananas = sets.isEmpty ? 0 : sets.last.pushups.length;

    return StepLayout(
      center: true,
      cta: PBButton(l.onbSeeMyPlan, callback: widget.args.next, expanded: true),
      children: [
        const SizedBox(height: PBSpace.xl),
        OnbTitle(l.onbRewardTitle, center: true, size: 40),
        OnbSub(l.onbRewardSub(bananas), center: true),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Pop(
                at: 0.6,
                duration: 0.7,
                child: Assets.images.island.banana.image(height: 200),
              ),
              Positioned(
                bottom: 24,
                child: Pop(
                  at: 1.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PBSpace.lg,
                      vertical: PBSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary,
                      borderRadius: BorderRadius.circular(PBRadius.pill),
                    ),
                    child: Text(
                      '+$bananas',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: context.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Reveal(
          at: 1.7,
          child: OnbCard(
            child: Row(
              children: [
                Icon(CarbonIcons.fire, color: context.gameColors.orange),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.onbRewardStreak,
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        l.onbRewardStreakBody,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PBSpace.xl),
      ],
    );
  }
}

/// Their plan in four cards.
class PlanStep extends StatelessWidget {
  const PlanStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final answers = args.answers;
    final plan = OnboardingPlan(answers, today: DateTime.now());
    final goal = answers.goalWeightKg;
    final cards = [
      (
        game.red,
        CarbonIcons.fire,
        l.onbPlanDaily(answers.dailyGoal),
        l.onbPlanDailyHint(plan.dailyMinutes),
      ),
      (
        game.ice,
        CarbonIcons.chart_line,
        l.onbPlanTarget(plan.targetInARow),
        l.onbPlanTargetHint(shortDate(context, plan.targetDate)),
      ),
      if (goal != null)
        (
          game.leaf,
          CarbonIcons.trophy,
          l.onbPlanWeight(formatWeight(l, goal, answers.units)),
          l.onbPlanWeightHint(plan.dailyKcal),
        ),
      (game.purple, CarbonIcons.flag, l.onbPlanQuests, l.onbPlanQuestsHint),
    ];

    return StepLayout(
      cta: PBButton(l.onbLetsGo, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbPlanTitle),
        OnbSub(l.onbPlanSub),
        const SizedBox(height: PBSpace.xl),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PBSpace.md,
          crossAxisSpacing: PBSpace.md,
          childAspectRatio: 1.25,
          children: [
            for (final (i, (color, icon, title, hint)) in cards.indexed)
              Reveal(
                at: 0.7 + i * 0.15,
                child: OnbCard(
                  padding: const EdgeInsets.all(PBSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        hint,
                        maxLines: 2,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Reveal(
            at: 1.4,
            offset: 40,
            child: Assets.images.proHeroWave.image(fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

/// The free days as a timeline, or the plans once they're over.
class PaywallStep extends StatelessWidget {
  const PaywallStep(this.args, {super.key});

  final StepArgs args;

  Future<void> _plans(BuildContext context) async {
    await showPaywall(context);
    await args.finish();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pro = context.watch<ProCubit>();
    final free = pro.state.inFreeDays(pro.now);

    if (!free) {
      return StepLayout(
        cta: PBButton(
          l.onbPaywallSeePlans,
          callback: () => _plans(context),
          expanded: true,
        ),
        secondary: OnbTextButton(l.onbMaybeLater, onTap: args.finish),
        children: [
          OnbTitle(l.onbPaywallOverTitle),
          OnbSub(l.onbPaywallOverSub),
          const SizedBox(height: PBSpace.xl),
          Wrap(
            spacing: PBSpace.sm,
            runSpacing: PBSpace.sm,
            children: [
              for (final (i, feature) in ProFeature.values.indexed)
                Pop(
                  at: 0.8 + i * 0.1,
                  child: Chip(
                    avatar: Icon(feature.icon, color: feature.color(context)),
                    label: Text(feature.label(context)),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Reveal(
              at: 1.4,
              offset: 40,
              child: Assets.images.proHeroDance.image(fit: BoxFit.contain),
            ),
          ),
        ],
      );
    }

    final game = context.gameColors;
    final timeline = [
      (
        game.leaf,
        CarbonIcons.unlocked,
        l.onbPaywallToday,
        l.onbPaywallTodayBody
      ),
      (
        game.banana,
        CarbonIcons.notification,
        l.onbPaywallDay2,
        l.onbPaywallDay2Body
      ),
      (game.purple, CarbonIcons.star, l.onbPaywallDay3, l.onbPaywallDay3Body),
    ];

    return StepLayout(
      cta: PBButton(l.onbPaywallStart, callback: args.finish, expanded: true),
      secondary: OnbTextButton(
        l.onbPaywallSeePlans,
        onTap: () => _plans(context),
      ),
      children: [
        OnbTitle(l.onbPaywallTitle),
        OnbSub(l.onbPaywallSub),
        const SizedBox(height: PBSpace.xl),
        for (final (i, (color, icon, title, body)) in timeline.indexed)
          Reveal(
            at: 0.8 + i * 0.4,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: game.onGame),
                      ),
                      if (i < timeline.length - 1)
                        Expanded(
                          child: Container(
                            width: 3,
                            color: color.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: PBSpace.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: PBSpace.sm,
                        bottom: PBSpace.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.textTheme.titleMedium),
                          Text(body, style: context.textTheme.bodySmall),
                        ],
                      ),
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
