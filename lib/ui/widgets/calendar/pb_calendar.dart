
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/widgets/calendar/calendar_header/calendar_header.dart';
import 'package:pushup_bro/ui/widgets/calendar/calendar_header/calendar_header_day_of_week.dart';
import 'package:pushup_bro/ui/widgets/calendar/markers/pb_calendar_event_marker.dart';
import 'package:pushup_bro/ui/widgets/calendar/markers/pb_calendar_selected_marker.dart';
import 'package:pushup_bro/ui/widgets/calendar/markers/pb_calendar_today_marker.dart';
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
        selectedDayPredicate: (day) {
          return isSameDay(selectedDate, day);
        },
        onDaySelected: (selectedDay, focusedDay) =>
            updateSelectedDate(selectedDay),
        focusedDay: DateTime.now(),
        daysOfWeekHeight: 32,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            CarbonIcons.chevron_left,
            color: PBColors.accentColor,
          ),
          rightChevronIcon: Icon(
            CarbonIcons.chevron_right,
            color: PBColors.accentColor,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) =>
              events.isNotEmpty ? const PBCalendarEventMarker() : null,
          selectedBuilder: (context, day, focusedDay) =>
              PBCalendarSelectedMarker(day),
          todayBuilder: (context, day, focusedDay) =>
              PBCalendarTodayMarker(day),
          headerTitleBuilder: (context, day) => CalendarHeader(day),
          dowBuilder: (context, day) => CalendarHeaderDayOfWeek(day),
        ),
      );
}
