import 'package:pushup_bro/core/model/shared_preferences_key.dart';

abstract class SharedPreferencesInterface {
  bool get initialized;
  Future<void> loadSharedPrefs();
  Future<void> writeStringToSharedPrefs(SharedPreferencesKey key, String value);
  Future<void> writeBoolToSharedPrefs(
    SharedPreferencesKey key, {
    required bool value,
  });
  Future<void> writeIntToSharedPrefs(
    SharedPreferencesKey key, {
    required int value,
  });
  Future<int?> getSharedPrefInt(SharedPreferencesKey key);
  Future<String?> getSharedPrefString(SharedPreferencesKey key);
  Future<bool?> getSharedPrefBool(SharedPreferencesKey key);
}
