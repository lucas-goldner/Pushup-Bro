import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

/// The selected day: ringed in the theme's secondary colour.
class PBCalendarSelected extends StatelessWidget {
  const PBCalendarSelected(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 2,
              color: context.colorScheme.secondary,
            ),
          ),
          child: Center(
            // The day number is intentionally not locale-formatted: CLDR
            // appends a suffix for some locales (e.g. `30日` for `ja`) which
            // wraps the cell onto two lines.
            child: Text(
              '${day.day}',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.secondary,
              ),
            ),
          ),
        ),
      );
}
