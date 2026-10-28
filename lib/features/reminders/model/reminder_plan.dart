import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/app_config.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/reminders/model/reminder_settings.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// How many days ahead the daily reminders and quests are scheduled; every
/// launch, workout and settings change schedules them again.
const kReminderDaysAhead = 7;

/// The hour of the streak warning: one hour before midnight.
const kStreakWarningHour = 23;

/// The hour a new jungle quest is announced.
const kQuestHour = 9;

/// The hour of both free days warnings.
const kFreeDaysWarningHour = 18;

/// Quiet days after the last workout before the comeback nudge.
const kComebackAfterDays = 3;

/// The smallest streak worth a warning.
const kMinStreakToWarn = 2;

/// Stable notification ids, one block per kind, so a reschedule replaces
/// what was scheduled before.
abstract final class ReminderIds {
  /// Plus the day offset (0 is today).
  static const daily = 100;
  static const streak = 200;

  /// Plus the day offset (0 is today).
  static const quest = 300;
  static const freeLastDay = 400;
  static const freeHoursLeft = 401;
  static const comeback = 500;

  /// Every id Pushup Bro may have scheduled.
  static final all = <int>[
    for (var i = 0; i < kReminderDaysAhead; i++) daily + i,
    streak,
    for (var i = 0; i < kReminderDaysAhead; i++) quest + i,
    freeLastDay,
    freeHoursLeft,
    comeback,
  ];
}

/// One notification to schedule.
class PlannedReminder extends Equatable {
  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, when, title, body];

  @override
  String toString() => 'PlannedReminder($id, $when, $title)';
}

/// Works out every notification to schedule from plain data, so it can be
/// tested without the plugin.
abstract final class ReminderPlan {
  /// The notifications to schedule at [now], sorted by time. Empty while
  /// reminders are off.
  ///
  /// - Daily reminder at the player's time for the next days, rotating
  ///   copy; skips today once [workedOutToday], and stops when the
  ///   comeback nudge takes over.
  /// - Streak at risk at 23:00 on a day without a workout, from a
  ///   [streak] of 2: today, or tomorrow when today's workout is done.
  /// - New jungle quest at 9:00 while the player [hasAccess]; during the
  ///   free days only until they end.
  /// - Free days ending at 18:00 on day 2 and day 3 of the free days that
  ///   started at [freeSince], unless [isPro].
  /// - Comeback at the player's time [kComebackAfterDays] after the
  ///   [lastWorkout], once.
  static List<PlannedReminder> build({
    required DateTime now,
    required ReminderSettings settings,
    required DateTime? lastWorkout,
    required bool workedOutToday,
    required int streak,
    required bool hasAccess,
    required bool isPro,
    required DateTime? freeSince,
    required S strings,
  }) {
    if (!settings.enabled) return const [];

    final reminders = <PlannedReminder>[];
    DateTime at(DateTime day, int days, int hour, [int minute = 0]) =>
        DateTime(day.year, day.month, day.day + days, hour, minute);

    // Comeback: once, a few quiet days after the last workout.
    DateTime? comebackAt;
    if (lastWorkout != null) {
      final when = at(
        lastWorkout,
        kComebackAfterDays,
        settings.hour,
        settings.minute,
      );
      if (when.isAfter(now)) {
        comebackAt = when;
        reminders.add(
          PlannedReminder(
            id: ReminderIds.comeback,
            when: when,
            title: strings.reminderComebackTitle,
            body: strings.reminderComebackBody,
          ),
        );
      }
    }

    // Daily reminder, until the comeback nudge takes over.
    for (var i = 0; i < kReminderDaysAhead; i++) {
      if (i == 0 && workedOutToday) continue;
      final when = at(now, i, settings.hour, settings.minute);
      if (!when.isAfter(now)) continue;
      if (comebackAt != null && !_dayBefore(when, comebackAt)) break;
      final (title, body) = _dailyCopy(when, strings);
      reminders.add(
        PlannedReminder(
          id: ReminderIds.daily + i,
          when: when,
          title: title,
          body: body,
        ),
      );
    }

    // Streak at risk.
    if (streak >= kMinStreakToWarn) {
      final when = at(now, workedOutToday ? 1 : 0, kStreakWarningHour);
      if (when.isAfter(now)) {
        reminders.add(
          PlannedReminder(
            id: ReminderIds.streak,
            when: when,
            title: strings.reminderStreakTitle,
            body: strings.reminderStreakBody(streak),
          ),
        );
      }
    }

    final freeUntil = freeSince?.add(AppConfig.freeDays);
    final inFreeDays = freeUntil != null && now.isBefore(freeUntil);

    // New jungle quest; during the free days only while they last.
    if (hasAccess) {
      for (var i = 0; i < kReminderDaysAhead; i++) {
        final when = at(now, i, kQuestHour);
        if (!when.isAfter(now)) continue;
        if (!isPro && inFreeDays && !when.isBefore(freeUntil)) break;
        reminders.add(
          PlannedReminder(
            id: ReminderIds.quest + i,
            when: when,
            title: strings.reminderQuestTitle,
            body: strings.reminderQuestBody(
              JungleQuest.forDay(when).title(strings),
            ),
          ),
        );
      }
    }

    // Free days ending.
    if (!isPro && freeSince != null && freeUntil != null) {
      final lastDay = at(freeSince, 1, kFreeDaysWarningHour);
      if (lastDay.isAfter(now) && lastDay.isBefore(freeUntil)) {
        reminders.add(
          PlannedReminder(
            id: ReminderIds.freeLastDay,
            when: lastDay,
            title: strings.reminderFreeLastDayTitle,
            body: strings.reminderFreeLastDayBody,
          ),
        );
      }
      final finalDay = at(freeSince, 2, kFreeDaysWarningHour);
      final hoursLeft = (freeUntil.difference(finalDay).inMinutes / 60).ceil();
      if (finalDay.isAfter(now) && hoursLeft > 0) {
        reminders.add(
          PlannedReminder(
            id: ReminderIds.freeHoursLeft,
            when: finalDay,
            title: strings.reminderFreeHoursLeftTitle(hoursLeft),
            body: strings.reminderFreeHoursLeftBody,
          ),
        );
      }
    }

    return reminders..sort((a, b) => a.when.compareTo(b.when));
  }

  /// The daily reminder's copy for [day]; a different line every day.
  static (String, String) _dailyCopy(DateTime day, S strings) =>
      switch (dayNumber(day) % 4) {
        0 => (strings.reminderDailyTitle1, strings.reminderDailyBody1),
        1 => (strings.reminderDailyTitle2, strings.reminderDailyBody2),
        2 => (strings.reminderDailyTitle3, strings.reminderDailyBody3),
        _ => (strings.reminderDailyTitle4, strings.reminderDailyBody4),
      };

  /// Whether [a] falls on a day before [b]'s day.
  static bool _dayBefore(DateTime a, DateTime b) =>
      DateTime(a.year, a.month, a.day)
          .isBefore(DateTime(b.year, b.month, b.day));
}

/// Days in a row with a workout among [workouts], up to today, or up to
/// yesterday while today's workout is still open.
int workoutStreak(Iterable<DateTime> workouts, DateTime now) {
  final days = {
    for (final workout in workouts)
      DateTime(workout.year, workout.month, workout.day),
  };
  var day = DateTime(now.year, now.month, now.day);
  if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }

  return streak;
}
