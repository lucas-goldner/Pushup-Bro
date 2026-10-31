import 'dart:async';
import 'dart:ui';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/phone_canvas.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_step.dart';
import 'package:pushup_bro/features/onboarding/steps/body_steps.dart';
import 'package:pushup_bro/features/onboarding/steps/finish_steps.dart';
import 'package:pushup_bro/features/onboarding/steps/intro_steps.dart';
import 'package:pushup_bro/features/onboarding/steps/plan_steps.dart';
import 'package:pushup_bro/features/onboarding/steps/story_steps.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';

/// What a step gets from the onboarding: the answers so far, a way to
/// change them and a way to move on.
class StepArgs {
  const StepArgs({
    required this.answers,
    required this.answer,
    required this.next,
    required this.skipTo,
    required this.finish,
  });

  final OnboardingAnswers answers;
  final ValueChanged<OnboardingAnswers> answer;
  final VoidCallback next;

  /// Moves on to the given step, or to the one after it if this player
  /// skips it.
  final ValueChanged<OnboardingStep> skipTo;

  /// Ends the onboarding and opens the app.
  final Future<void> Function() finish;
}

/// The first-launch onboarding: 21 short steps that build the player's
/// plan, a first real set with Carlos and the Pro free days.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({this.initialStep, super.key});

  /// Starts at this step, for tests and screenshots.
  final OnboardingStep? initialStep;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final List<OnboardingStep> _flow = OnboardingStep.flow(
    hasPushups: context.read<DBCubit>().state.pushupSets.isNotEmpty,
    isPro: context.read<ProCubit>().state.isPro,
  );
  late int _index = widget.initialStep == null
      ? 0
      : _flow.indexOf(widget.initialStep!).clamp(0, _flow.length - 1);

  OnboardingStep get _step => _flow[_index];

  void _next() {
    if (_index >= _flow.length - 1) {
      unawaited(_finish());
      return;
    }
    GameAudio.instance.play(Sfx.tap);
    setState(() => _index++);
  }

  void _skipTo(OnboardingStep step) {
    final target = _flow.indexWhere((s) => s.index >= step.index);
    if (target <= _index) {
      _next();
      return;
    }
    setState(() => _index = target);
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  Future<void> _finish() => context.read<OnboardingCubit>().complete();

  @override
  Widget build(BuildContext context) {
    final night = _isNight(_step);
    final theme = night ? darkTheme : Theme.of(context);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Material(
          color: _background(context, _step),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                final blur = (1 - animation.value) * 12;
                return Opacity(
                  opacity: animation.value,
                  child: ImageFiltered(
                    enabled: blur > 0.1,
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Transform.scale(
                      scale: 1.03 - animation.value * 0.03,
                      child: child,
                    ),
                  ),
                );
              },
            ),
            child: KeyedSubtree(
              key: ValueKey(_step),
              // Phone sized on any window: centred on a wide one, scaled
              // down on a short one.
              child: PhoneCanvas(
                child: _StepFrame(
                  step: _step,
                  progress: (_index + 1) / _flow.length,
                  onBack: _index == 0 ? null : _back,
                  child: BlocBuilder<OnboardingCubit, OnboardingState>(
                    buildWhen: (a, b) => a.answers != b.answers,
                    builder: (context, state) => MotionClock(
                      child: _stepWidget(
                        _step,
                        StepArgs(
                          answers: state.answers,
                          answer: context.read<OnboardingCubit>().answer,
                          next: _next,
                          skipTo: _skipTo,
                          finish: _finish,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _stepWidget(OnboardingStep step, StepArgs args) =>
      switch (step) {
        OnboardingStep.hook => HookStep(args),
        OnboardingStep.goal => GoalStep(args),
        OnboardingStep.max => MaxStep(args),
        OnboardingStep.often => OftenStep(args),
        OnboardingStep.height => HeightStep(args),
        OnboardingStep.weight => WeightStep(args),
        OnboardingStep.goalWeight => GoalWeightStep(args),
        OnboardingStep.pains => PainsStep(args),
        OnboardingStep.notYou => NotYouStep(args),
        OnboardingStep.carlos => CarlosStep(args),
        OnboardingStep.track => TrackStep(args),
        OnboardingStep.moves => MovesStep(args),
        OnboardingStep.chart => ChartStep(args),
        OnboardingStep.month => MonthStep(args),
        OnboardingStep.daily => DailyStep(args),
        OnboardingStep.reminder => ReminderStep(args),
        OnboardingStep.building => BuildingStep(args),
        OnboardingStep.firstSet => FirstSetStep(args),
        OnboardingStep.reward => RewardStep(args),
        OnboardingStep.plan => PlanStep(args),
        OnboardingStep.paywall => PaywallStep(args),
      };

  /// Story moments happen at night.
  static bool _isNight(OnboardingStep step) => switch (step) {
        OnboardingStep.hook ||
        OnboardingStep.notYou ||
        OnboardingStep.reminder =>
          true,
        _ => false,
      };

  /// Each step paints its own tint over the surface.
  static Color _background(BuildContext context, OnboardingStep step) {
    final game = context.gameColors;
    final surface = context.colorScheme.surface;
    final tint = switch (step) {
      OnboardingStep.hook ||
      OnboardingStep.notYou ||
      OnboardingStep.reminder =>
        null,
      OnboardingStep.max ||
      OnboardingStep.height ||
      OnboardingStep.firstSet ||
      OnboardingStep.carlos =>
        game.ice,
      OnboardingStep.goalWeight || OnboardingStep.moves => game.leaf,
      OnboardingStep.pains => game.orange,
      OnboardingStep.month => game.purple,
      OnboardingStep.daily || OnboardingStep.reward => game.banana,
      _ => context.colorScheme.secondary,
    };
    if (tint == null) return context.colorScheme.surfaceContainerLowest;
    final strength = switch (step) {
      OnboardingStep.carlos => context.isDark ? 0.45 : 0.32,
      _ => context.isDark ? 0.14 : 0.1,
    };
    return Color.alphaBlend(tint.withValues(alpha: strength), surface);
  }
}

/// The back button and progress bar above a step, and the safe area.
class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.step,
    required this.progress,
    required this.onBack,
    required this.child,
  });

  final OnboardingStep step;
  final double progress;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: step.fullBleed
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PBSpace.xl - 4,
                      ),
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            child: GestureDetector(
                              onTap: onBack,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: context.cardShadow,
                                ),
                                child: Icon(
                                  CarbonIcons.chevron_left,
                                  size: 18,
                                  color: onBack == null
                                      ? context.colorScheme.outline
                                      : context.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: PBSpace.md),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: progress),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  color: context.colorScheme.secondary,
                                  backgroundColor: context.colorScheme.onSurface
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Expanded(child: child),
          ],
        ),
      );
}

/// A step's layout: content at the top, the main button at the bottom.
class StepLayout extends StatelessWidget {
  const StepLayout({
    required this.children,
    this.cta,
    this.secondary,
    this.center = false,
    this.scroll = false,
    super.key,
  });

  final List<Widget> children;
  final Widget? cta;
  final Widget? secondary;
  final bool center;

  /// Lets tall content scroll on small phones.
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      children: children,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PBSpace.xl,
        PBSpace.lg,
        PBSpace.xl,
        PBSpace.lg,
      ),
      child: Column(
        children: [
          Expanded(
            child: scroll ? SingleChildScrollView(child: column) : column,
          ),
          if (cta != null) Reveal(at: 0.9, offset: 16, child: cta!),
          if (secondary != null) secondary!,
        ],
      ),
    );
  }
}
