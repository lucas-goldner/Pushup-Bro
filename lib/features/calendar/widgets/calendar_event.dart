import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/features/calendar/widgets/calendar_stat_item.dart';

class CalendarEvent extends StatelessWidget {
  const CalendarEvent(this.pushupSet, {super.key});
  final PushupSet pushupSet;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          height: 100,
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            color: context.colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.setOfXOPushups(
                      pushupSet.pushups.length.toString(),
                    ),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colorScheme.surfaceBright,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Icon(
                    CarbonIcons.fire,
                    color: context.colorScheme.inversePrimary,
                  ),
                  Text(
                    pushupSet.translateEffort(context),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colorScheme.surfaceBright,
                    ),
                  ),
                ],
              ),
              Text(
                context.l10n.stats,
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.surfaceBright,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
