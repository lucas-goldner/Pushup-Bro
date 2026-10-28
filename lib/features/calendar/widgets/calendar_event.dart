import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/features/calendar/widgets/calendar_stat_item.dart';

/// A workout on the chosen day: its size, effort and stats on a card.
class CalendarEvent extends StatelessWidget {
  const CalendarEvent(this.pushupSet, {super.key});
  final PushupSet pushupSet;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.lg,
          vertical: PBSpace.sm,
        ),
        child: Container(
          padding: const EdgeInsets.all(PBSpace.lg),
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(PBRadius.lg),
            boxShadow: context.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.setOfXOPushups(
                        pushupSet.pushups.length.toString(),
                      ),
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: PBSpace.md),
                  SheetTag(
                    pushupSet.translateEffort(context),
                    icon: CarbonIcons.fire,
                    color: context.gameColors.orange,
                  ),
                ],
              ),
              const SizedBox(height: PBSpace.md),
              Text(
                context.l10n.stats.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: PBSpace.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CalendarStatItem(
                    pushupSet.timeSpent.toString(),
                    CarbonIcons.time,
                  ),
                  CalendarStatItem(
                    pushupSet.pushups.length.toString(),
                    CarbonIcons.add_alt,
                  ),
                  CalendarStatItem(
                    '${pushupSet.pushups.length}/${pushupSet.timeSpent}',
                    CarbonIcons.chart_average,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
