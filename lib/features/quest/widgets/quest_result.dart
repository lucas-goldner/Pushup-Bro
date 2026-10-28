import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/share/model/recap.dart';
import 'package:pushup_bro/features/share/widgets/share_recap_button.dart';
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
        color: context.colorScheme.scrim
            .withValues(alpha: context.isDark ? 0.5 : 0.35),
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
              margin: const EdgeInsets.all(PBSpace.xl),
              padding: const EdgeInsets.all(PBSpace.xl),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetBadge(
                    won ? '🏆' : '💫',
                    size: 76,
                    color: won
                        ? context.gameColors.orange
                        : context.colorScheme.secondary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    won
                        ? context.l10n.questComplete
                        : context.l10n.questSoClose,
                    style: context.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    won
                        ? quest.title(context.l10n)
                        : context.l10n.questTomorrow,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '$pushups',
                          label: context.l10n.questPushups,
                          icon: Icon(
                            CarbonIcons.chart_line,
                            color: context.colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: PBSpace.md),
                      Expanded(
                        child: _Stat(
                          value: '+$bananas',
                          label: won && quest.bananaMultiplier > 1
                              ? context.l10n.questBananasDoubled
                              : context.l10n.questBananas,
                          icon: Assets.images.island.banana.image(width: 30),
                          color: context.gameColors.cream,
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
                  if (won)
                    ShareRecapButton(
                      recap: () => Recap.quest(
                        title: quest.title(context.l10n),
                        pushups: pushups,
                        bananas: bananas,
                        history: context.read<DBCubit>().state.pushupSets,
                        now: DateTime.now(),
                        weightKg: playerWeightKg(context),
                      ),
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
    this.color,
  });

  final String value;
  final String label;
  final Widget icon;

  /// The tile's fill; the page background colour when null.
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
