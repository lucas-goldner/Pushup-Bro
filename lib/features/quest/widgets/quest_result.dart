import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// The end of a quest: won or not, the pushups done and bananas earned.
class QuestResult extends StatelessWidget {
  const QuestResult({
    required this.quest,
    required this.won,
    required this.pushups,
    required this.bananas,
    required this.onDone,
    super.key,
  });

  final JungleQuest quest;
  final bool won;
  final int pushups;
  final int bananas;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: background2.withValues(alpha: 0.35),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetBadge(
                    won ? '🏆' : '💫',
                    size: 76,
                    color: won ? const Color(0xFFF5A623) : accentColor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    won
                        ? context.l10n.questComplete
                        : context.l10n.questSoClose,
                    style: pageTitleTextStyle.copyWith(color: background2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    won
                        ? quest.title(context.l10n)
                        : context.l10n.questTomorrow,
                    textAlign: TextAlign.center,
                    style: defaultTextStyle.copyWith(
                      color: background2.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '$pushups',
                          label: context.l10n.questPushups,
                          icon: const Icon(
                            CarbonIcons.chart_line,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Stat(
                          value: '+$bananas',
                          label: won && quest.bananaMultiplier > 1
                              ? context.l10n.questBananasDoubled
                              : context.l10n.questBananas,
                          icon: Assets.images.island.banana.image(width: 30),
                          color: const Color(0xFFFFF4D6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PillButton(
                    label: context.l10n.questBackToJungle,
                    icon: CarbonIcons.tree,
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    this.color = background,
  });

  final String value;
  final String label;
  final Widget icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SizedBox(height: 30, child: Center(child: icon)),
            const SizedBox(height: 6),
            Text(
              value,
              style: pushupTextStyle.copyWith(
                fontSize: 28,
                color: background2,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: defaultTextStyle.copyWith(
                fontSize: 13,
                color: background2.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
}
