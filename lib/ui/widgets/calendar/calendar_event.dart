import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/calendar/calendar_stat_item.dart';

class CalendarEvent extends StatelessWidget {
  const CalendarEvent(this.pushupSet, {super.key});
  final PushupSet pushupSet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        height: 100,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: PBColors.background2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  S.of(context).setOfXOPushups(
                        pushupSet.pushups.length.toString(),
                      ),
                  style: PBTextStyles.headerTextStyle.copyWith(
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Icon(
                  CarbonIcons.fire,
                  color: PBColors.accentColor,
                ),
                Text(
                  pushupSet.translateEffort(context),
                  style: PBTextStyles.defaultTextStyle.copyWith(
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
            Text(
              S.of(context).stats,
              style: PBTextStyles.buttonTextStyle.copyWith(
                color: CupertinoColors.white,
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
}
