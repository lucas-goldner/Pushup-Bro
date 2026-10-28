import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/reminders/model/reminder_settings.dart';

class RemindersState extends Equatable {
  const RemindersState({
    this.settings = const ReminderSettings(),
    this.loaded = false,
    this.permissionDenied = false,
  });

  final ReminderSettings settings;
  final bool loaded;

  /// The player asked for reminders but notifications aren't allowed, so
  /// the page explains how to turn them on in the Settings app.
  final bool permissionDenied;

  RemindersState copyWith({
    ReminderSettings? settings,
    bool? loaded,
    bool? permissionDenied,
  }) =>
      RemindersState(
        settings: settings ?? this.settings,
        loaded: loaded ?? this.loaded,
        permissionDenied: permissionDenied ?? this.permissionDenied,
      );

  @override
  List<Object?> get props => [settings, loaded, permissionDenied];
}
