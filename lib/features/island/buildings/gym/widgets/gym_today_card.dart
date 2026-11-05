import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// "5 h 12 min" or "12 min" until [left] is up.
String gymTimeLeft(S l, Duration left) {
  final minutes = (left.inSeconds / 60).ceil().clamp(1, 24 * 60);

  return minutes >= 60
      ? l.statsHours(minutes ~/ 60, minutes % 60)
      : l.statsMinutes(minutes);
}

/// Today's gym workout: what it is, Gus's brief, what it takes and pays,
/// when the next one comes, and Start.
class GymTodayCard extends StatelessWidget {
  const GymTodayCard({
    required this.challenge,
    required this.done,
    required this.nextIn,
    required this.onStart,
    super.key,
  });

  final GymChallenge challenge;

  /// Already won today.
  final bool done;

  /// Until the next workout (midnight).
  final Duration nextIn;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;
    final color = scheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, game.purple, 0.6)!],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: PBSpace.sm,
                  runSpacing: PBSpace.xs,
                  children: [
                    _Pill(
                      done ? '✓ ${l.gymDoneToday}' : '✨ ${l.gymTodayTag}',
                    ),
                    _Pill('🏋️ ${l.gymOnlyHere}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      challenge.kind.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(width: PBSpace.sm),
                    Expanded(
                      child: Text(
                        challenge.kind.title(l),
                        style: text.headlineMedium?.copyWith(
                          color: game.onGame,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  challenge.goal(l),
                  style: text.labelMedium?.copyWith(
                    color: game.onGame.withValues(alpha: 0.92),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, PBSpace.lg, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SheetBadge(Character.gus.emoji, color: Character.gus.color),
                    const SizedBox(width: PBSpace.md),
                    Expanded(
                      child: Text(
                        challenge.kind.description(l),
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: PBSpace.sm,
                  runSpacing: PBSpace.sm,
                  children: [
                    SheetTag(
                      done
                          ? l.questReplay
                          : '🍌 ${l.questDoubleBonus(
                              GymChallenge.bananaMultiplier,
                              GymChallenge.bonus,
                            )}',
                      color: game.orange,
                    ),
                    SheetTag(
                      l.gymNextIn(gymTimeLeft(l, nextIn)),
                      icon: CarbonIcons.time,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: PillButton(
                    label: done ? l.gymTrainAgain : l.gymStart,
                    icon: CarbonIcons.play_filled_alt,
                    color: done ? null : color,
                    onPressed: onStart,
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

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: context.gameColors.onGame.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(PBRadius.sm),
        ),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.gameColors.onGame,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
      );
}
