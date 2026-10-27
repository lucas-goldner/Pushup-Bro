import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_state.dart';
import 'package:pushup_bro/features/reminders/data/reminder_service.dart';
import 'package:pushup_bro/features/reminders/model/reminder_plan.dart';
import 'package:pushup_bro/features/reminders/model/reminder_settings.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// What the reminders are planned from, besides the settings: the
/// workouts, Pro and the language.
class ReminderInputs {
  const ReminderInputs({
    required this.workouts,
    required this.hasAccess,
    required this.isPro,
    required this.freeSince,
    required this.strings,
  });

  /// When each saved set was finished.
  final List<DateTime> workouts;
  final bool hasAccess;
  final bool isPro;
  final DateTime? freeSince;
  final S strings;
}

/// Loads the reminder settings and schedules the notifications again
/// whenever the settings or the [ReminderInputs] change.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit(
    this._prefs,
    this._service, {
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const RemindersState());

  final SharedPreferencesProvider _prefs;
  final ReminderService _service;
  final DateTime Function() _clock;

  ReminderInputs? _inputs;
  List<PlannedReminder>? _scheduled;
  Future<void> _queue = Future.value();

  /// What was scheduled last, for tests and debugging.
  List<PlannedReminder>? get scheduled => _scheduled;

  Future<void> load() async {
    final enabled =
        await _prefs.getSharedPrefBool(SharedPreferencesKey.reminderEnabled);
    final minutes =
        await _prefs.getSharedPrefInt(SharedPreferencesKey.reminderMinutes);
    final settings =
        ReminderSettings.fromStored(enabled: enabled, minutes: minutes);
    final denied = settings.enabled && !await _permitted();
    emit(
      state.copyWith(
        settings: settings,
        loaded: true,
        permissionDenied: denied,
      ),
    );
    await _reschedule();
  }

  /// Turns the reminders on or off; turning them on asks for permission
  /// first and stays off when it's denied. Returns whether they're on.
  Future<bool> setEnabled({required bool enabled}) async {
    var granted = true;
    if (enabled) {
      try {
        granted = await _service.requestPermission();
      } on Object catch (error) {
        debugPrint('Notification permission failed: $error');
        granted = false;
      }
    }
    final on = enabled && granted;
    await _prefs.writeBoolToSharedPrefs(
      SharedPreferencesKey.reminderEnabled,
      value: on,
    );
    emit(
      state.copyWith(
        settings: state.settings.copyWith(enabled: on),
        permissionDenied: enabled && !granted,
      ),
    );
    await _reschedule();

    return on;
  }

  Future<void> setTime({required int hour, required int minute}) async {
    final settings = state.settings.copyWith(hour: hour, minute: minute);
    await _prefs.writeIntToSharedPrefs(
      SharedPreferencesKey.reminderMinutes,
      value: settings.minutesOfDay,
    );
    emit(state.copyWith(settings: settings));
    await _reschedule();
  }

  /// New workouts, Pro state or language: plans again.
  Future<void> updateInputs(ReminderInputs inputs) {
    _inputs = inputs;

    return _reschedule();
  }

  /// Back in the app: the day may have changed, and the player may have
  /// allowed or blocked notifications in the Settings app.
  Future<void> refresh() async {
    if (!state.loaded) return;
    if (state.settings.enabled || state.permissionDenied) {
      final permitted = await _permitted();
      final enabled = state.settings.enabled;
      // Allowed in the Settings app after a denial: just turn them on.
      if (!enabled && permitted) {
        await setEnabled(enabled: true);
        return;
      }
      emit(state.copyWith(permissionDenied: !permitted));
    }
    await _reschedule();
  }

  /// The notifications for the current settings and inputs.
  List<PlannedReminder> plan() {
    final inputs = _inputs;
    if (inputs == null || !state.settings.enabled || state.permissionDenied) {
      return const [];
    }
    final now = _clock();
    DateTime? lastWorkout;
    for (final workout in inputs.workouts) {
      if (lastWorkout == null || workout.isAfter(lastWorkout)) {
        lastWorkout = workout;
      }
    }
    final workedOutToday = lastWorkout != null &&
        lastWorkout.year == now.year &&
        lastWorkout.month == now.month &&
        lastWorkout.day == now.day;

    return ReminderPlan.build(
      now: now,
      settings: state.settings,
      lastWorkout: lastWorkout,
      workedOutToday: workedOutToday,
      streak: workoutStreak(inputs.workouts, now),
      hasAccess: inputs.hasAccess,
      isPro: inputs.isPro,
      freeSince: inputs.freeSince,
      strings: inputs.strings,
    );
  }

  Future<bool> _permitted() async {
    try {
      return await _service.isPermitted();
    } on Object catch (error) {
      debugPrint('Notification permission check failed: $error');
      return false;
    }
  }

  /// Schedules one plan at a time, and only when it changed.
  Future<void> _reschedule() => _queue = _queue.then((_) async {
        // Wait for the workouts and Pro state before the first schedule,
        // but always clear when reminders are off.
        if (!state.loaded) return;
        if (_inputs == null && state.settings.enabled) return;
        final plan = this.plan();
        if (listEquals(plan, _scheduled)) {
          return;
        }
        try {
          await _service.schedule(plan);
          _scheduled = plan;
        } on Object catch (error) {
          debugPrint('Scheduling reminders failed: $error');
        }
      });
}
