import 'package:pushup_bro/features/reminders/data/reminder_service.dart';
import 'package:pushup_bro/features/reminders/model/reminder_plan.dart';

/// Records what would be scheduled instead of talking to the plugin.
class FakeReminderService implements ReminderService {
  FakeReminderService({this.grant = true});

  /// What the permission prompt answers.
  bool grant;
  bool permitted = false;
  int permissionRequests = 0;
  final schedules = <List<PlannedReminder>>[];

  List<PlannedReminder>? get last => schedules.isEmpty ? null : schedules.last;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    permitted = grant;
    return grant;
  }

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async =>
      schedules.add(List.of(reminders));
}
