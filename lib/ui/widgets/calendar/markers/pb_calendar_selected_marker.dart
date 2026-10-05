import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';

class PBCalendarSelectedMarker extends StatelessWidget {
  const PBCalendarSelectedMarker(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(40),
          ),
          border: Border.all(
            width: 2,
            color: PBColors.accentColor,
          ),
        ),
        child: Center(
          // The day number is intentionally not locale-formatted: CLDR appends
          // a suffix for some locales (e.g. `30日` for `ja`) which wraps the
          // cell onto two lines.
          child: Text(
            '${day.day}',
            style: PBTextStyles.defaultTextStyle,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
