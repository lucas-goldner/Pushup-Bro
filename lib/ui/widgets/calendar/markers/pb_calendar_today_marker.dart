import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';

class PBCalendarTodayMarker extends StatelessWidget {
  const PBCalendarTodayMarker(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PBColors.background2,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Center(
        // The day number is intentionally not locale-formatted: CLDR appends
        // a suffix for some locales (e.g. `30日` for `ja`) which wraps the
        // cell onto two lines.
        child: Text(
          '${day.day}',
          style: PBTextStyles.headerTextStyle
              .copyWith(color: CupertinoColors.white),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
