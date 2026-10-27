import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/reminders/model/reminder_plan.dart';
import 'package:pushup_bro/features/reminders/model/reminder_settings.dart';
import 'package:pushup_bro/generated/l10n.dart';

void main() {
  late S en;

  setUpAll(() async => en = await S.load(const Locale('en')));

  // Tuesday noon.
  final noon = DateTime(2026, 10, 27, 12);
  const on = ReminderSettings(enabled: true);

  List<PlannedReminder> plan({
    DateTime? now,
    ReminderSettings settings = on,
    DateTime? lastWorkout,
    bool workedOutToday = false,
    int streak = 0,
    bool hasAccess = false,
    bool isPro = false,
    DateTime? freeSince,
    S? strings,
  }) =>
      ReminderPlan.build(
        now: now ?? noon,
        settings: settings,
        lastWorkout: lastWorkout,
        workedOutToday: workedOutToday,
        streak: streak,
        hasAccess: hasAccess,
        isPro: isPro,
        freeSince: freeSince,
        strings: strings ?? en,
      );

  Iterable<PlannedReminder> ofKind(List<PlannedReminder> plan, int base) =>
      plan.where((r) => r.id >= base && r.id < base + 100);

  group('reminders off', () {
    test('plans nothing at all', () {
      final reminders = plan(
        settings: const ReminderSettings(),
        lastWorkout: noon.subtract(const Duration(days: 1)),
        streak: 5,
        hasAccess: true,
        freeSince: noon,
      );

      expect(reminders, isEmpty);
    });
  });

  group('daily reminder', () {
    test('at 20:30 for the next 7 days by default', () {
      final daily = ofKind(plan(), ReminderIds.daily).toList();

      expect(daily, hasLength(kReminderDaysAhead));
      expect(daily.first.when, DateTime(2026, 10, 27, 20, 30));
      expect(daily.last.when, DateTime(2026, 11, 2, 20, 30));
      expect(daily.map((r) => r.id), [for (var i = 0; i < 7; i++) 100 + i]);
    });

    test("at the player's own time", () {
      final daily = ofKind(
        plan(settings: on.copyWith(hour: 7, minute: 15), now: noon),
        ReminderIds.daily,
      );

      expect(daily.first.when, DateTime(2026, 10, 28, 7, 15));
      expect(
        daily.every((r) => r.when.hour == 7 && r.when.minute == 15),
        isTrue,
      );
    });

    test('skips today once the time has passed', () {
      final daily = ofKind(
        plan(now: DateTime(2026, 10, 27, 21)),
        ReminderIds.daily,
      ).toList();

      expect(daily.first.when, DateTime(2026, 10, 28, 20, 30));
      expect(daily.first.id, ReminderIds.daily + 1);
      expect(daily, hasLength(6));
    });

    test('skips today once a workout is done', () {
      final daily = ofKind(
        plan(lastWorkout: DateTime(2026, 10, 27, 8), workedOutToday: true),
        ReminderIds.daily,
      );

      expect(daily.first.when, DateTime(2026, 10, 28, 20, 30));
    });

    test('rotates its copy every day', () {
      final titles =
          ofKind(plan(), ReminderIds.daily).take(4).map((r) => r.title).toSet();

      expect(titles, hasLength(4));
      expect(
        titles,
        containsAll(<String>[
          'Carlos is on the mat',
          'King Komo thinks you skipped today',
          'Your mat misses you',
        ]),
      );
    });

    test('speaks the given language', () async {
      final de = await S.load(const Locale('de'));
      final daily = ofKind(plan(strings: de), ReminderIds.daily);
      await S.load(const Locale('en'));

      expect(
        daily.map((r) => r.title),
        contains('Carlos liegt schon auf der Matte'),
      );
    });
  });

  group('streak at risk', () {
    test('at 23:00 today without a workout today', () {
      final streak = plan(
        lastWorkout: DateTime(2026, 10, 26, 19),
        streak: 14,
      ).where((r) => r.id == ReminderIds.streak).single;

      expect(streak.when, DateTime(2026, 10, 27, 23));
      expect(streak.body, "14 days in a row. Don't let it end at 14!");
    });

    test('tomorrow at 23:00 once today is done', () {
      final streak = plan(
        lastWorkout: DateTime(2026, 10, 27, 8),
        workedOutToday: true,
        streak: 3,
      ).where((r) => r.id == ReminderIds.streak).single;

      expect(streak.when, DateTime(2026, 10, 28, 23));
    });

    test('not for a streak below 2', () {
      final reminders = plan(lastWorkout: DateTime(2026, 10, 26), streak: 1);

      expect(reminders.where((r) => r.id == ReminderIds.streak), isEmpty);
    });

    test('not once midnight is less than an hour away', () {
      final reminders = plan(
        now: DateTime(2026, 10, 27, 23, 30),
        lastWorkout: DateTime(2026, 10, 26),
        streak: 4,
      );

      expect(reminders.where((r) => r.id == ReminderIds.streak), isEmpty);
    });
  });

  group('new jungle quest', () {
    test('at 9:00 every day with Pro, with the quest of the day', () {
      final quests =
          ofKind(plan(hasAccess: true, isPro: true), ReminderIds.quest)
              .toList();

      // 9:00 today is over at noon.
      expect(quests, hasLength(kReminderDaysAhead - 1));
      expect(quests.first.when, DateTime(2026, 10, 28, 9));
      expect(quests.first.title, 'A new jungle quest is waiting');
      expect(
        quests.first.body,
        contains(JungleQuest.forDay(DateTime(2026, 10, 28)).title(en)),
      );
    });

    test('not without access', () {
      expect(ofKind(plan(), ReminderIds.quest), isEmpty);
    });

    test('during the free days only until they end', () {
      final quests = ofKind(
        plan(hasAccess: true, freeSince: DateTime(2026, 10, 26, 10)),
        ReminderIds.quest,
      );

      // Free until Oct 29, 10:00.
      expect(quests.map((r) => r.when), [
        DateTime(2026, 10, 28, 9),
        DateTime(2026, 10, 29, 9),
      ]);
    });
  });

  group('free days ending', () {
    test('day 2 and day 3 at 18:00, with the hours really left', () {
      final reminders = plan(
        now: DateTime(2026, 10, 27, 0, 5),
        hasAccess: true,
        freeSince: DateTime(2026, 10, 27),
      );
      final lastDay =
          reminders.where((r) => r.id == ReminderIds.freeLastDay).single;
      final hoursLeft =
          reminders.where((r) => r.id == ReminderIds.freeHoursLeft).single;

      expect(lastDay.when, DateTime(2026, 10, 28, 18));
      expect(lastDay.title, 'Tomorrow is your last free day');
      expect(hoursLeft.when, DateTime(2026, 10, 29, 18));
      expect(hoursLeft.title, '6 hours left with everything');
    });

    test('counts the hours from when the free days started', () {
      final hoursLeft = plan(
        hasAccess: true,
        freeSince: DateTime(2026, 10, 26, 10),
      ).where((r) => r.id == ReminderIds.freeHoursLeft).single;

      // Oct 28, 18:00 to Oct 29, 10:00.
      expect(hoursLeft.title, '16 hours left with everything');
    });

    test('drops a warning whose time has passed', () {
      final reminders = plan(
        now: DateTime(2026, 10, 28, 19),
        hasAccess: true,
        freeSince: DateTime(2026, 10, 27),
      );

      expect(reminders.where((r) => r.id == ReminderIds.freeLastDay), isEmpty);
      expect(
        reminders.where((r) => r.id == ReminderIds.freeHoursLeft),
        hasLength(1),
      );
    });

    test('not with Pro', () {
      final reminders = plan(
        hasAccess: true,
        isPro: true,
        freeSince: DateTime(2026, 10, 27),
      );

      expect(
        reminders.where(
          (r) =>
              r.id == ReminderIds.freeLastDay ||
              r.id == ReminderIds.freeHoursLeft,
        ),
        isEmpty,
      );
    });
  });

  group('comeback', () {
    test("3 days after the last workout at the player's time, once", () {
      final comeback = plan(lastWorkout: DateTime(2026, 10, 26, 18))
          .where((r) => r.id == ReminderIds.comeback)
          .single;

      expect(comeback.when, DateTime(2026, 10, 29, 20, 30));
      expect(comeback.title, 'Carlos ate all the bananas');
    });

    test('takes over from the daily reminder, then nothing more', () {
      final reminders = plan(lastWorkout: DateTime(2026, 10, 26, 18));
      final daily = ofKind(reminders, ReminderIds.daily);

      expect(daily.map((r) => r.when), [
        DateTime(2026, 10, 27, 20, 30),
        DateTime(2026, 10, 28, 20, 30),
      ]);
      expect(reminders.last.id, ReminderIds.comeback);
    });

    test('not once its time has passed', () {
      final reminders = plan(lastWorkout: DateTime(2026, 10, 20));

      expect(reminders.where((r) => r.id == ReminderIds.comeback), isEmpty);
      expect(ofKind(reminders, ReminderIds.daily), hasLength(7));
    });

    test('not without any workout yet', () {
      expect(plan().where((r) => r.id == ReminderIds.comeback), isEmpty);
    });
  });

  test('everything at once: sorted, unique and known ids', () {
    final reminders = plan(
      now: DateTime(2026, 10, 27, 0, 5),
      lastWorkout: DateTime(2026, 10, 26, 18),
      streak: 5,
      hasAccess: true,
      freeSince: DateTime(2026, 10, 27),
    );
    final ids = reminders.map((r) => r.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
    expect(ReminderIds.all, containsAll(ids));
    for (var i = 1; i < reminders.length; i++) {
      expect(reminders[i].when.isBefore(reminders[i - 1].when), isFalse);
    }
  });

  group('workout streak', () {
    test('counts days in a row up to today', () {
      final streak = workoutStreak(
        [
          DateTime(2026, 10, 27, 8),
          DateTime(2026, 10, 27, 18),
          DateTime(2026, 10, 26, 7),
          DateTime(2026, 10, 25, 22),
          DateTime(2026, 10, 23),
        ],
        noon,
      );

      expect(streak, 3);
    });

    test("keeps yesterday's streak while today is open", () {
      expect(
        workoutStreak(
          [DateTime(2026, 10, 26), DateTime(2026, 10, 25)],
          noon,
        ),
        2,
      );
    });

    test('is broken after a day without a workout', () {
      expect(workoutStreak([DateTime(2026, 10, 25)], noon), 0);
      expect(workoutStreak(const [], noon), 0);
    });
  });

  group('settings', () {
    test('default to off at 20:30', () {
      const settings = ReminderSettings();

      expect(settings.enabled, isFalse);
      expect((settings.hour, settings.minute), (20, 30));
    });

    test('read back from the saved minutes', () {
      final settings =
          ReminderSettings.fromStored(enabled: true, minutes: 7 * 60 + 45);

      expect(
        settings,
        const ReminderSettings(enabled: true, hour: 7, minute: 45),
      );
      expect(
        ReminderSettings.fromStored(minutes: -3),
        const ReminderSettings(),
      );
    });
  });
}
