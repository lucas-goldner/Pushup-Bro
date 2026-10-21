import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class PBCalendarToday extends StatelessWidget {
  const PBCalendarToday(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.onSecondary,
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        child: Center(
          // The day number is intentionally not locale-formatted: CLDR appends
          // a suffix for some locales (e.g. `30日` for `ja`) which wraps the
          // cell onto two lines.
          child: Text(
            '${day.day}',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: context.textTheme.titleSmall?.copyWith(
              color: context.colorScheme.surfaceBright,
            ),
          ),
        ),
      );
}
