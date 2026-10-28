import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';

import 'package:pushup_bro/core/widgets/island_sheet.dart';

/// Carlos's Trek stats, with buttons to spend his level-up points.
class StatsSheet extends StatelessWidget {
  const StatsSheet({required this.onClose, super.key});

  final VoidCallback onClose;

  Future<void> _spend(BuildContext context, String stat) async {
    final cubit = context.read<GameInventoryCubit>();
    final inventory = cubit.state.inventory;
    await cubit.updateInventory(
      inventory.copyWith(trek: inventory.trek.spend(stat)),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, TrekProgress>(
        selector: (state) => state.inventory.trek,
        builder: (context, trek) {
          final l = context.l10n;
          final red = context.gameColors.red;
          final text = context.textTheme;

          return IslandSheet(
            title: l.trekStats,
            subtitle: trek.points > 0
                ? l.trekPointsToSpend(trek.points)
                : l.trekLevel(trek.level),
            badge: '💪',
            accent: red,
            onClose: onClose,
            child: Column(
              children: [
                _XpBar(trek: trek),
                const SizedBox(height: 14),
                for (final (stat, emoji, name, info, value) in [
                  (
                    'power',
                    '👊',
                    l.statPower,
                    l.statPowerInfo,
                    '${trek.attack.round()}',
                  ),
                  (
                    'vitality',
                    '❤️',
                    l.statVitality,
                    l.statVitalityInfo,
                    '${trek.maxHp.round()}',
                  ),
                  (
                    'grip',
                    '🧊',
                    l.statGrip,
                    l.statGripInfo,
                    '+${(trek.gripBonus * 100).round()}%',
                  ),
                  (
                    'agility',
                    '⚡',
                    l.statAgility,
                    l.statAgilityInfo,
                    '+${(trek.quickBonus * 100).round()}%',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SheetCard(
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: text.titleSmall?.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(info, style: text.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            value,
                            style: text.headlineSmall,
                          ),
                          if (trek.points > 0) ...[
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () => _spend(context, stat),
                              style: IconButton.styleFrom(
                                backgroundColor: red,
                              ),
                              icon: Icon(
                                CarbonIcons.add,
                                color: context.gameColors.onGame,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.trek});

  final TrekProgress trek;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SheetTag(
            context.l10n.trekLevel(trek.level),
            icon: CarbonIcons.star_filled,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: trek.xp / trek.nextLevelXp,
                minHeight: 10,
                backgroundColor: context.colorScheme.surfaceContainerHigh,
                valueColor:
                    AlwaysStoppedAnimation(context.colorScheme.secondary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.trekXp(trek.xp, trek.nextLevelXp),
            style: context.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
}
