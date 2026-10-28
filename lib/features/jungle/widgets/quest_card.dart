import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';

/// Today's jungle quest, popping up with a bounce: where it happens, who
/// Carlos meets, the challenge and the reward.
class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.quest,
    required this.done,
    required this.completedQuests,
    required this.onPlay,
    super.key,
  });

  final JungleQuest quest;

  /// Already won today.
  final bool done;

  /// Quests won so far, all told.
  final int completedQuests;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final questColor = game.jungle;
    final text = context.textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        alignment: Alignment.bottomCenter,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    questColor,
                    Color.lerp(questColor, scheme.secondary, 0.5)!,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Pill(
                        done
                            ? '✓ ${context.l10n.questDoneToday}'
                            : '✨ ${context.l10n.questDaily}',
                        color: game.onGame.withValues(alpha: 0.22),
                      ),
                      const Spacer(),
                      if (completedQuests > 0)
                        _Pill(
                          '🏆 $completedQuests',
                          color: game.onGame.withValues(alpha: 0.22),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quest.title(context.l10n),
                    style: text.headlineMedium?.copyWith(
                      color: game.onGame,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${quest.location.emoji}  '
                    '${quest.location.name(context.l10n)}',
                    style: text.labelMedium?.copyWith(
                      color: game.onGame.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                PBSpace.lg,
                20,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SheetBadge(quest.guest.emoji, color: quest.guest.color),
                      const SizedBox(width: PBSpace.md),
                      Expanded(
                        child: Text(
                          quest.teaser(context.l10n),
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
                        quest.rule.summary(context.l10n),
                        icon: switch (quest.rule) {
                          TimedRule() => CarbonIcons.timer,
                          HoldRule() => CarbonIcons.pause_filled,
                          TargetRule() => CarbonIcons.flag,
                        },
                      ),
                      SheetTag(
                        done
                            ? context.l10n.questReplay
                            : quest.bananaMultiplier > 1
                                ? '🍌 ${context.l10n.questDoubleBonus(
                                    quest.bananaMultiplier,
                                    quest.bonus,
                                  )}'
                                : '🍌 '
                                    '${context.l10n.questBonus(quest.bonus)}',
                        color: game.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: PillButton(
                      label: done
                          ? context.l10n.questPlayAgain
                          : context.l10n.questLetsGo,
                      icon: CarbonIcons.play_filled_alt,
                      color: done ? null : questColor,
                      onPressed: onPlay,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
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
