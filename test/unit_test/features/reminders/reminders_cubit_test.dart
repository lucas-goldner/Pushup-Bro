import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/features/reminders/model/reminder_plan.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_reminder_service.dart';

void main() {
  late S en;
  late FakeReminderService service;
  late SharedPreferencesProvider prefs;
  final now = DateTime(2026, 10, 27, 12);

  setUpAll(() async => en = await S.load(const Locale('en')));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = FakeReminderService();
    prefs = SharedPreferencesProvider();
    await prefs.loadSharedPrefs();
  });

  RemindersCubit cubit() => RemindersCubit(prefs, service, clock: () => now);

  ReminderInputs inputs({List<DateTime> workouts = const []}) => ReminderInputs(
        workouts: workouts,
        hasAccess: false,
        isPro: false,
        freeSince: null,
        strings: en,
      );

  test('starts off at 20:30 and schedules nothing', () async {
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());

    expect(reminders.state.loaded, isTrue);
    expect(reminders.state.settings.enabled, isFalse);
    expect(reminders.state.settings.minutesOfDay, 20 * 60 + 30);
    expect(service.last, isEmpty);
    expect(service.permissionRequests, 0);
  });

  test('turning on asks for permission, saves and schedules', () async {
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());

    final on = await reminders.setEnabled(enabled: true);

    expect(on, isTrue);
    expect(service.permissionRequests, 1);
    expect(
      await prefs.getSharedPrefBool(SharedPreferencesKey.reminderEnabled),
      isTrue,
    );
    expect(service.last, isNotEmpty);
    expect(service.last!.first.id, ReminderIds.daily);
  });

  test('stays off and shows the hint when permission is denied', () async {
    service.grant = false;
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());

    final on = await reminders.setEnabled(enabled: true);

    expect(on, isFalse);
    expect(reminders.state.settings.enabled, isFalse);
    expect(reminders.state.permissionDenied, isTrue);
    expect(service.last, isEmpty);
  });

  test('a new time is saved and rescheduled', () async {
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());
    await reminders.setEnabled(enabled: true);

    await reminders.setTime(hour: 7, minute: 5);

    expect(
      await prefs.getSharedPrefInt(SharedPreferencesKey.reminderMinutes),
      7 * 60 + 5,
    );
    expect(service.last!.first.when, DateTime(2026, 10, 28, 7, 5));
  });

  test('restores the saved settings', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKey.reminderEnabled.name: true,
      SharedPreferencesKey.reminderMinutes.name: 19 * 60,
    });
    prefs = SharedPreferencesProvider();
    service.permitted = true;
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());

    expect(reminders.state.settings.enabled, isTrue);
    expect(reminders.state.settings.hour, 19);
    expect(service.last!.first.when, DateTime(2026, 10, 27, 19));
  });

  test('flags notifications blocked in the Settings app', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKey.reminderEnabled.name: true,
    });
    prefs = SharedPreferencesProvider();
    final reminders = cubit();
    await reminders.load();

    expect(reminders.state.permissionDenied, isTrue);
    expect(reminders.plan(), isEmpty);
  });

  test('a workout today moves the daily reminder to tomorrow', () async {
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());
    await reminders.setEnabled(enabled: true);
    expect(service.last!.first.when, DateTime(2026, 10, 27, 20, 30));

    await reminders.updateInputs(
      inputs(workouts: [DateTime(2026, 10, 26, 9), DateTime(2026, 10, 27, 9)]),
    );

    final daily =
        service.last!.where((r) => r.id < ReminderIds.streak).toList();
    expect(daily.first.when, DateTime(2026, 10, 28, 20, 30));
    // Two days in a row: the streak warning is set for tomorrow night.
    expect(
      service.last!.where((r) => r.id == ReminderIds.streak).single.when,
      DateTime(2026, 10, 28, 23),
    );
  });

  test('does not schedule the same plan twice', () async {
    final reminders = cubit();
    await reminders.load();
    await reminders.updateInputs(inputs());
    await reminders.setEnabled(enabled: true);
    final count = service.schedules.length;

    await reminders.updateInputs(inputs());
    await reminders.refresh();

    expect(service.schedules, hasLength(count));
  });

  test('waits for the inputs before the first schedule', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKey.reminderEnabled.name: true,
    });
    prefs = SharedPreferencesProvider();
    service.permitted = true;
    final reminders = cubit();
    await reminders.load();

    expect(service.schedules, isEmpty);
  });
}
