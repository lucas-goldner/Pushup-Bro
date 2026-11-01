import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pushup_bro/core/model/calorie_estimator.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/features/widgets/widget_snapshot.dart';

/// How many weeks the activity grid shows.
const kStatsHeatmapWeeks = 17;

/// A set needs this many pushups before its pace counts as a record.
const kStatsPaceMinPushups = 5;

/// The span the activity chart covers.
enum StatsRange { week, month, year }

/// One bar of the activity chart: the pushups from its start on, for a
/// day (week and month) or a month (year).
typedef StatsBar = ({DateTime start, int pushups});

/// When in the day a pushup was done.
enum DayTime {
  /// 5:00 to 11:59.
  morning,

  /// 12:00 to 16:59.
  afternoon,

  /// 17:00 to 21:59.
  evening,

  /// 22:00 to 4:59.
  night;

  static DayTime of(DateTime time) => switch (time.hour) {
        >= 5 && < 12 => morning,
        >= 12 && < 17 => afternoon,
        >= 17 && < 22 => evening,
        _ => night,
      };
}

/// Everything the pushup log says about the player, as of [now].
///
/// A pure summary of the saved sets: every number on the stats page comes
/// from here, so it can be tested without widgets.
@immutable
class PushupStats {
  const PushupStats._({
    required this.now,
    required this.total,
    required this.sets,
    required this.activeDays,
    required this.seconds,
    required this.kcal,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.bestSet,
    required this.bestDay,
    required this.bestDayDate,
    required this.bestPace,
    required this.currentStreak,
    required this.longestStreak,
    required this.firstDay,
    required this.perDay,
    required this.weekdays,
    required this.dayTimes,
    required this.efforts,
  });

  factory PushupStats.from(
    Iterable<PushupSet> sets,
    DateTime now, {
    double? weightKg,
  }) {
    final perDay = <DateTime, int>{};
    final weekdays = List.filled(7, 0);
    final dayTimes = List.filled(DayTime.values.length, 0);
    final efforts = List.filled(6, 0);
    var total = 0;
    var setCount = 0;
    var seconds = 0;
    var bestSet = 0;
    double? bestPace;

    for (final set in sets) {
      final times = [
        for (final pushup in set.pushups)
          if (pushup.completedAt != null) pushup.completedAt!.toLocal(),
      ]..sort();
      if (times.isEmpty) continue;
      setCount++;
      total += times.length;
      bestSet = math.max(bestSet, times.length);
      efforts[set.effort.clamp(0, 5)]++;
      final length = times.last.difference(times.first).inSeconds;
      // A set of one pushup still took a moment.
      seconds += math.max(length, 2 * times.length);
      if (times.length >= kStatsPaceMinPushups && length > 0) {
        final pace = times.length * 60 / length;
        if (bestPace == null || pace > bestPace) bestPace = pace;
      }
      for (final time in times) {
        final day = _dayOf(time);
        perDay[day] = (perDay[day] ?? 0) + 1;
        weekdays[time.weekday - 1]++;
        dayTimes[DayTime.of(time).index]++;
      }
    }

    final today = _dayOf(now);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(today.year, today.month);
    var bestDay = 0;
    DateTime? bestDayDate;
    var thisWeek = 0;
    var thisMonth = 0;
    for (final MapEntry(key: day, value: count) in perDay.entries) {
      if (count > bestDay ||
          (count == bestDay &&
              bestDayDate != null &&
              day.isAfter(bestDayDate))) {
        bestDay = count;
        bestDayDate = day;
      }
      if (!day.isBefore(weekStart) && !day.isAfter(today)) thisWeek += count;
      if (!day.isBefore(monthStart) && !day.isAfter(today)) thisMonth += count;
    }
    final streaks = workoutStreaks(sets, now);
    final days = perDay.keys.toList()..sort();

    return PushupStats._(
      now: now,
      total: total,
      sets: setCount,
      activeDays: perDay.length,
      seconds: seconds,
      kcal: CalorieEstimator.roundedKcal(total, weightKg: weightKg),
      today: perDay[today] ?? 0,
      thisWeek: thisWeek,
      thisMonth: thisMonth,
      bestSet: bestSet,
      bestDay: bestDay,
      bestDayDate: bestDayDate,
      bestPace: bestPace,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
      firstDay: days.isEmpty ? null : days.first,
      perDay: perDay,
      weekdays: weekdays,
      dayTimes: dayTimes,
      efforts: efforts,
    );
  }

  final DateTime now;

  /// Pushups ever.
  final int total;
  final int sets;

  /// Days with at least one pushup.
  final int activeDays;

  /// Time spent in sets.
  final int seconds;
  final int kcal;
  final int today;

  /// Since Monday.
  final int thisWeek;

  /// Since the first of the month.
  final int thisMonth;

  /// Most pushups in one set.
  final int bestSet;

  /// Most pushups in one day, and that day.
  final int bestDay;
  final DateTime? bestDayDate;

  /// Fastest pushups per minute in a set of at least
  /// [kStatsPaceMinPushups].
  final double? bestPace;
  final int currentStreak;
  final int longestStreak;

  /// The first day with pushups.
  final DateTime? firstDay;

  /// Pushups per local day.
  final Map<DateTime, int> perDay;

  /// Pushups per weekday, Monday first.
  final List<int> weekdays;

  /// Pushups per [DayTime].
  final List<int> dayTimes;

  /// Sets per effort, 0 (not rated) to 5.
  final List<int> efforts;

  bool get isEmpty => total == 0;

  int get minutes => (seconds / 60).ceil();

  /// Average pushups a set, rounded.
  int get averageSet => sets == 0 ? 0 : (total / sets).round();

  /// The weekday (1 Monday to 7 Sunday) with the most pushups, if any.
  int? get favouriteWeekday {
    final most = weekdays.reduce(math.max);
    return most == 0 ? null : weekdays.indexOf(most) + 1;
  }

  /// The time of day with the most pushups, if any.
  DayTime? get favouriteDayTime {
    final most = dayTimes.reduce(math.max);
    return most == 0 ? null : DayTime.values[dayTimes.indexOf(most)];
  }

  /// The most picked effort among rated sets (1 to 5), if any set was rated.
  int? get usualEffort {
    final rated = efforts.sublist(1);
    final most = rated.reduce(math.max);
    return most == 0 ? null : rated.indexOf(most) + 1;
  }

  /// The activity chart's bars for [range], oldest first: the last 7 or 30
  /// days, or the last 12 months.
  List<StatsBar> bars(StatsRange range) {
    final today = _dayOf(now);
    if (range == StatsRange.year) {
      return [
        for (var back = 11; back >= 0; back--)
          () {
            final start = DateTime(today.year, today.month - back);
            final end = DateTime(start.year, start.month + 1);
            var count = 0;
            for (final MapEntry(key: day, value: pushups) in perDay.entries) {
              if (!day.isBefore(start) && day.isBefore(end)) count += pushups;
            }
            return (start: start, pushups: count);
          }(),
      ];
    }
    final days = range == StatsRange.week ? 7 : 30;
    return [
      for (var back = days - 1; back >= 0; back--)
        () {
          final day = DateTime(today.year, today.month, today.day - back);
          return (start: day, pushups: perDay[day] ?? 0);
        }(),
    ];
  }

  /// The activity grid: [kStatsHeatmapWeeks] columns of Monday to Sunday,
  /// oldest first, ending with this week. Days after today are null.
  List<List<int?>> heatmap() {
    final today = _dayOf(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final first = DateTime(
      monday.year,
      monday.month,
      monday.day - 7 * (kStatsHeatmapWeeks - 1),
    );

    return [
      for (var week = 0; week < kStatsHeatmapWeeks; week++)
        [
          for (var weekday = 0; weekday < 7; weekday++)
            () {
              final day = DateTime(
                first.year,
                first.month,
                first.day + week * 7 + weekday,
              );
              return day.isAfter(today) ? null : perDay[day] ?? 0;
            }(),
        ],
    ];
  }
}

DateTime _dayOf(DateTime time) => DateTime(time.year, time.month, time.day);
