import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/cubit/db/db_cubit.dart';
import 'package:pushup_bro/cubit/db/db_state.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_cubit.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/ui/widgets/calendar/calendar_event.dart';
import 'package:pushup_bro/ui/widgets/calendar/pb_calendar.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});
  static const routeName = '/calendar';

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDay = DateTime.now();

  Future<String> _getLanguage(BuildContext context) =>
      BlocProvider.of<SharedPreferencesCubit>(context).getLanguage();

  List<PushupSet> _getEventsForDay(
    List<PushupSet> pushupSets,
    DateTime day,
  ) =>
      pushupSets.where((pset) => isSameDay(pset.completedDate, day)).toList();

  void _updateSelectedDate(DateTime day) => setState(() => _selectedDay = day);

  @override
  void initState() {
    unawaited(BlocProvider.of<DBCubit>(context).getAllPushupSets());
    super.initState();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: BlocBuilder<DBCubit, DBState>(
          builder: (context, state) {
            final eventsPerDay =
                _getEventsForDay(state.pushupSets, _selectedDay);
            return Column(
              children: [
                const SizedBox(height: 64),
                FutureBuilder(
                  future: _getLanguage(context),
                  builder: (context, language) => PBCalendar(
                    getEventsPerDay: (day) =>
                        _getEventsForDay(state.pushupSets, day),
                    selectedDate: _selectedDay,
                    updateSelectedDate: _updateSelectedDate,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (int i = 0; i <= eventsPerDay.length - 1; i++) ...{
                          CalendarEvent(eventsPerDay[i]),
                        },
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
