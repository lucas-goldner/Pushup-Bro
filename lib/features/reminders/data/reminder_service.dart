import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pushup_bro/features/reminders/model/reminder_plan.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _kChannelId = 'reminders';
const _kChannelName = 'Reminders';

const _kDetails = NotificationDetails(
  android: AndroidNotificationDetails(_kChannelId, _kChannelName),
  // Shown as a banner while the app is open too.
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentSound: true,
  ),
);

/// Schedules Pushup Bro's local notifications.
abstract interface class ReminderService {
  /// Loads the time zones and the plugin; asks for nothing.
  Future<void> init();

  /// Asks for notification permission. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Whether notifications are allowed right now (they can be turned off
  /// in the iOS Settings app at any time).
  Future<bool> isPermitted();

  /// Replaces everything scheduled before with [reminders].
  Future<void> schedule(List<PlannedReminder> reminders);
}

/// [ReminderService] on flutter_local_notifications. Tapping a
/// notification just opens the app.
class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  @override
  Future<void> init() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } on Object catch (error) {
      // Falls back to UTC; times then drift by the offset, but still fire.
      debugPrint('Unknown time zone: $error');
    }

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android => await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission(),
      TargetPlatform.iOS => await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true),
      _ => true,
    };

    return granted ?? false;
  }

  @override
  Future<bool> isPermitted() async {
    await init();
    final permitted = switch (defaultTargetPlatform) {
      TargetPlatform.android => await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled(),
      TargetPlatform.iOS => (await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.checkPermissions())
          ?.isEnabled,
      _ => true,
    };

    return permitted ?? false;
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    await init();
    for (final id in ReminderIds.all) {
      await _plugin.cancel(id: id);
    }
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        notificationDetails: _kDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
