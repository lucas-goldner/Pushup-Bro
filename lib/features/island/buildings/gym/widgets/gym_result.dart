import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// The end of a gym workout: won or not, the pushups and bananas, the gym
/// streak and any gear Gus handed over.
class GymResult extends StatelessWidget {
  const GymResult({
    required this.challenge,
    required this.won,
    required this.pushups,
    required this.bananas,
    required this.onDone,
    this.streak = 0,
    this.gift,
    this.crate = 0,
    this.replay = false,
    super.key,
  });

  final GymChallenge challenge;
  final bool won;
  final int pushups;
  final int bananas;

  /// The gym streak after this workout (shown for a first win of the day).
  final int streak;

  /// The cosmetic id of the gear won.
  final String? gift;

  /// Bananas in the streak crate, when all the gear is owned already.
  final int crate;
  final bool replay;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final scheme = context.colorScheme;
    final gear = gift == null ? null : Cosmetic.byId(gift!);

    return ColoredBox(
      color: scheme.scrim.withValues(alpha: context.isDark ? 0.5 : 0.35),
      child: Center(
        child: SingleChildScrollView(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.all(PBSpace.lg),
              padding: const EdgeInsets.all(PBSpace.xl),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetBadge(
                    won ? challenge.kind.emoji : '💫',
                    size: 76,
                    color: won ? game.orange : scheme.secondary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    won ? l.gymWorkoutDone : l.gymNotThisTime,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    won ? challenge.kind.title(l) : l.gymTryTomorrow,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (won && !replay && streak > 0) ...[
                    const SizedBox(height: PBSpace.md),
                    SheetTag(
                      '🔥 ${l.gymStreakUp(streak)}',
                      color: game.orange,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '$pushups',
                          label: l.questPushups,
                          icon: Icon(
                            CarbonIcons.chart_line,
                            color: scheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: PBSpace.md),
                      Expanded(
                        child: _Stat(
                          value: '+$bananas',
                          label: won && !replay
                              ? l.questBananasDoubled
                              : l.questBananas,
                          icon: Assets.images.island.banana.image(width: 30),
                          color: game.cream,
                        ),
                      ),
                    ],
                  ),
                  if (gear != null || crate > 0) ...[
                    const SizedBox(height: PBSpace.md),
                    SheetCard(
                      color: Color.alphaBlend(
                        context.tint(game.purple),
                        scheme.surface,
                      ),
                      child: Row(
                        children: [
                          SheetBadge(
                            gear?.emoji ?? '📦',
                            color: game.purple,
                            size: 44,
                          ),
                          const SizedBox(width: PBSpace.md),
                          Expanded(
                            child: Text(
                              gear != null
                                  ? l.gymGift(gear.label(l))
                                  : l.gymGiftCrate(crate),
                              style: context.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PillButton(
                    label: l.gymBackToGym,
                    icon: CarbonIcons.arrow_left,
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final Widget icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color ?? context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(PBRadius.md),
        ),
        child: Column(
          children: [
            SizedBox(height: 30, child: Center(child: icon)),
            const SizedBox(height: 6),
            Text(
              value,
              style: context.textTheme.displaySmall?.copyWith(fontSize: 30),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      );
}
