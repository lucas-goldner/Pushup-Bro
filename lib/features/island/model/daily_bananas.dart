import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';

/// The daily banana gift on the island: once a day, by the phone's
/// calendar day. The day of the last claim is saved, so reopening the
/// island the same day offers nothing.
class DailyBananas {
  DailyBananas({
    SharedPreferencesInterface? prefs,
    DateTime Function()? clock,
  })  : _prefs = prefs ?? SharedPreferencesProvider(),
        _clock = clock ?? DateTime.now;

  static const amount = 10;

  final SharedPreferencesInterface _prefs;
  final DateTime Function() _clock;

  /// A local calendar day, like 2026-10-29.
  static String dayKey(DateTime time) {
    final day = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${day.year}-${two(day.month)}-${two(day.day)}';
  }

  /// Whether today's bananas are still to claim.
  Future<bool> available() async =>
      await _prefs.getSharedPrefString(
        SharedPreferencesKey.dailyBananasClaimedOn,
      ) !=
      dayKey(_clock());

  /// Marks today's bananas as claimed. Returns false when they already
  /// were, so a second tap or a second visit gives nothing.
  Future<bool> claim() async {
    if (!await available()) return false;
    await _prefs.writeStringToSharedPrefs(
      SharedPreferencesKey.dailyBananasClaimedOn,
      dayKey(_clock()),
    );
    return true;
  }
}
