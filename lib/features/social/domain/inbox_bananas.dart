import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';

/// At most this many bananas a day from all friends together.
const kInboxBananasPerDay = 5;

/// Counts bananas claimed from friends today; returns whether one more may
/// be added (and counts it).
Future<bool> takeInboxBanana(
  SharedPreferencesInterface prefs, {
  required DateTime now,
}) async {
  final today = localDayKey(now);
  final saved = await prefs.getSharedPrefString(
    SharedPreferencesKey.inboxBananasDay,
  );
  final parts = (saved ?? '').split(':');
  final count = parts.length == 2 && parts.first == today
      ? int.tryParse(parts.last) ?? 0
      : 0;
  if (count >= kInboxBananasPerDay) return false;
  await prefs.writeStringToSharedPrefs(
    SharedPreferencesKey.inboxBananasDay,
    '$today:${count + 1}',
  );
  return true;
}
