import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/features/calendar/widgets/calendar_header/calendar_header.dart';
import 'package:pushup_bro/features/calendar/widgets/calendar_header/calendar_header_day_of_week.dart';
import 'package:pushup_bro/features/calendar/widgets/markers/pb_calendar_default_day.dart';
import 'package:pushup_bro/features/calendar/widgets/markers/pb_calendar_event.dart';
import 'package:pushup_bro/features/calendar/widgets/markers/pb_calendar_selected.dart';
import 'package:pushup_bro/features/calendar/widgets/markers/pb_calendar_today.dart';
import 'package:table_calendar/table_calendar.dart';

class PBCalendar extends StatelessWidget {
  const PBCalendar({
    required this.selectedDate,
    required this.updateSelectedDate,
    required this.getEventsPerDay,
    this.language,
    super.key,
  });
  final String? language;
  final DateTime selectedDate;
  final List<PushupSet> Function(DateTime day) getEventsPerDay;
  final void Function(DateTime) updateSelectedDate;

  @override
  Widget build(BuildContext context) => TableCalendar<PushupSet>(
        locale: language ?? 'en',
        firstDay: DateTime(2023, 2, 18),
        eventLoader: getEventsPerDay,
        lastDay: DateTime.utc(
          DateTime.now().year,
          DateTime.now().month + 3,
          DateTime.now().day,
        ),
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) =>
            updateSelectedDate(selectedDay),
        focusedDay: DateTime.now(),
        daysOfWeekHeight: 32,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            CarbonIcons.chevron_left,
            color: context.colorScheme.inversePrimary,
          ),
          rightChevronIcon: Icon(
            CarbonIcons.chevron_right,
            color: context.colorScheme.inversePrimary,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) =>
              events.isNotEmpty ? const PBCalendarEvent() : null,
          selectedBuilder: (context, day, focusedDay) =>
              PBCalendarSelected(day),
          todayBuilder: (context, day, focusedDay) => PBCalendarToday(day),
          headerTitleBuilder: (context, day) => CalendarHeader(day),
          dowBuilder: (context, day) => CalendarHeaderDayOfWeek(day),
          defaultBuilder: (context, day, focusedDay) =>
              PBCalendarDefaultDay(day),
        ),
      );
}
