import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class CalendarHeader extends StatelessWidget {
  const CalendarHeader(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          DateFormat.yMMMM().format(day),
          style: context.textTheme.titleSmall,
        ),
      );
}
