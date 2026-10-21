import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class CalendarHeaderDayOfWeek extends StatelessWidget {
  const CalendarHeaderDayOfWeek(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          DateFormat.E().format(day),
          style: context.textTheme.titleSmall,
        ),
      );
}
