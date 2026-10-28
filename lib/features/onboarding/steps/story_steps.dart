import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/onboarding/widgets/onboarding_kit.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// Three pain cards; each ✓ or ✕ flies the top one away.
class PainsStep extends StatefulWidget {
  const PainsStep(this.args, {super.key});

  final StepArgs args;

  @override
  State<PainsStep> createState() => _PainsStepState();
}

class _PainsStepState extends State<PainsStep> {
  int _answered = 0;
  bool _lastYes = true;

  void _answer({required bool yes}) {
    if (_answered >= 3) return;
    unawaited(HapticFeedback.lightImpact());
    GameAudio.instance.play(yes ? Sfx.pop : Sfx.whoosh);
    setState(() {
      _lastYes = yes;
      _answered++;
    });
    if (_answered == 3) {
      Future<void>.delayed(const Duration(milliseconds: 550), () {
        if (mounted) widget.args.next();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cards = [l.onbPain1, l.onbPain2, l.onbPain3];

    return StepLayout(
      children: [
        OnbTitle(l.onbPainsTitle),
        OnbSub(l.onbPainsSub),
        const SizedBox(height: PBSpace.xl),
        Expanded(
          child: Stack(
            children: [
              for (var i = cards.length - 1; i >= 0; i--)
                _PainCard(
                  text: cards[i],
                  depth: i - _answered,
                  gone: i < _answered,
                  flyRight: _lastYes,
                ),
            ],
          ),
        ),
        const SizedBox(height: PBSpace.xl),
        Reveal(
          at: 0.9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: CarbonIcons.close,
                color: context.colorScheme.surface,
                iconColor: context.gameColors.red,
                label: MaterialLocalizations.of(context).cancelButtonLabel,
                onTap: () => _answer(yes: false),
              ),
              const SizedBox(width: PBSpace.xxl),
              _RoundButton(
                icon: CarbonIcons.checkmark,
                color: context.gameColors.leaf,
                iconColor: context.gameColors.onGame,
                label: MaterialLocalizations.of(context).okButtonLabel,
                onTap: () => _answer(yes: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: PBSpace.lg),
      ],
    );
  }
}

class _PainCard extends StatelessWidget {
  const _PainCard({
    required this.text,
    required this.depth,
    required this.gone,
    required this.flyRight,
  });

  final String text;
  final int depth;
  final bool gone;
  final bool flyRight;

  @override
  Widget build(BuildContext context) {
    final inset = depth.clamp(0, 2) * 10.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      left: gone ? (flyRight ? 420 : -420) : inset,
      right: gone ? (flyRight ? -420 : 420) : inset,
      top: inset,
      bottom: 20 - inset,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 420),
        turns: gone
            ? (flyRight ? 0.05 : -0.05)
            : [0.0, 0.006, -0.008][depth.clamp(0, 2)],
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: gone ? 0 : 1,
          child: OnbCard(
            padding: const EdgeInsets.all(PBSpace.xl + 4),
            child: Center(
              child: Text(
                text,
                style: context.textTheme.headlineMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: context.cardShadow,
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
        ),
      );
}

/// "It's not you." Three lines out of the dark.
class NotYouStep extends StatelessWidget {
  const NotYouStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final banana = context.gameColors.banana;

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        const Spacer(),
        OnbTitle(l.onbNotYou1, at: 0.2, accent: banana, size: 40),
        const SizedBox(height: PBSpace.xl),
        OnbTitle(l.onbNotYou2, at: 1.2, accent: banana),
        const SizedBox(height: PBSpace.xl),
        OnbTitle(l.onbNotYou3, at: 2.4, accent: banana),
        const Spacer(flex: 2),
      ],
    );
  }
}

/// The emotional core: Carlos, his island and his message.
class CarlosStep extends StatelessWidget {
  const CarlosStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return StepLayout(
      center: true,
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbCarlosTitle, center: true, size: 40),
        OnbSub(l.onbCarlosBody, center: true, at: 0.8),
        const SizedBox(height: PBSpace.lg),
        Pop(
          at: 2.2,
          child: OnbCard(
            padding: const EdgeInsets.symmetric(
              horizontal: PBSpace.lg,
              vertical: PBSpace.md,
            ),
            child: Text(
              l.onbCarlosMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: Reveal(
            at: 1.4,
            duration: 0.8,
            offset: 80,
            child: Assets.images.proHeroWave.image(fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

/// AirPods or camera: picking one sets how pushups are counted.
class TrackStep extends StatelessWidget {
  const TrackStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = context.watch<SharedPreferencesCubit>();
    final mode = prefs.state.trackingMode;

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbTrackTitle),
        OnbSub(l.onbTrackSub),
        const SizedBox(height: PBSpace.xl),
        Reveal(
          at: 0.7,
          child: OnbOption(
            label: l.trackingAirpods,
            hint: l.onbTrackAirpodsHint,
            icon: CarbonIcons.headphones,
            selected: mode == TrackingMode.airpods,
            onTap: () => prefs.setTrackingMode(TrackingMode.airpods),
          ),
        ),
        const SizedBox(height: PBSpace.sm + 2),
        Reveal(
          at: 0.8,
          child: OnbOption(
            label: l.trackingCamera,
            hint: l.onbTrackCameraHint,
            icon: CarbonIcons.camera,
            selected: mode == TrackingMode.camera,
            onTap: () => prefs.setTrackingMode(TrackingMode.camera),
          ),
        ),
        Expanded(
          child: Reveal(
            at: 1.1,
            offset: 40,
            child: Assets.images.proHeroPushup.image(fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

/// The Jungle Trek's three moves and the enemies they beat.
class MovesStep extends StatelessWidget {
  const MovesStep(this.args, {super.key});

  final StepArgs args;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final moves = [
      (game.leaf, CarbonIcons.arrows_vertical, l.repNormal, l.weakGreen),
      (game.ice, CarbonIcons.pause, l.repHeld, l.weakBlue),
      (game.banana, CarbonIcons.flash, l.repQuick, l.weakYellow),
    ];

    return StepLayout(
      cta: PBButton(l.onbContinue, callback: args.next, expanded: true),
      children: [
        OnbTitle(l.onbMovesTitle),
        OnbSub(l.onbMovesSub),
        const SizedBox(height: PBSpace.xl),
        for (final (i, (color, icon, move, weak)) in moves.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: PBSpace.sm + 2),
            child: Reveal(
              at: 0.9 + i * 0.35,
              child: OnbCard(
                padding: const EdgeInsets.all(PBSpace.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(PBRadius.sm),
                      ),
                      child: Icon(icon, color: game.onGame),
                    ),
                    const SizedBox(width: PBSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(move, style: context.textTheme.titleMedium),
                          Text(weak, style: context.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Reveal(
            at: 2,
            offset: 40,
            child: Assets.images.proHeroKomo.image(fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
