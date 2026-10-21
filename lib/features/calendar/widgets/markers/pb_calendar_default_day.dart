import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class PBCalendarDefaultDay extends StatelessWidget {
  const PBCalendarDefaultDay(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => Center(
        // The day number is intentionally not locale-formatted: CLDR appends
        // a suffix for some locales (e.g. `30日` for `ja`) which wraps the
        // cell onto two lines.
        child: Text(
          '${day.day}',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: context.textTheme.bodyMedium,
        ),
      );
}
