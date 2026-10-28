import 'package:equatable/equatable.dart';

/// The player's reminder choices: off until they turn them on (and allow
/// notifications), at 20:30 unless they pick another time.
class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.enabled = false,
    this.hour = defaultHour,
    this.minute = defaultMinute,
  });

  /// Reads the minutes since midnight saved in the preferences.
  factory ReminderSettings.fromStored({bool? enabled, int? minutes}) {
    final valid = minutes != null && minutes >= 0 && minutes < 24 * 60;

    return ReminderSettings(
      enabled: enabled ?? false,
      hour: valid ? minutes ~/ 60 : defaultHour,
      minute: valid ? minutes % 60 : defaultMinute,
    );
  }

  static const defaultHour = 20;
  static const defaultMinute = 30;

  final bool enabled;
  final int hour;
  final int minute;

  /// The reminder time as minutes since midnight, as it is saved.
  int get minutesOfDay => hour * 60 + minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  List<Object?> get props => [enabled, hour, minute];
}
