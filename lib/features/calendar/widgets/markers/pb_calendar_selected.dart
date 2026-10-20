import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class PBCalendarSelected extends StatelessWidget {
  const PBCalendarSelected(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(40),
            ),
            border: Border.all(
              width: 2,
              color: context.colorScheme.inversePrimary,
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
              style: context.textTheme.bodyMedium,
            ),
          ),
        ),
      );
}
