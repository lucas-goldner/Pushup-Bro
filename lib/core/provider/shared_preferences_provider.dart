import 'package:flutter/widgets.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesProvider implements SharedPreferencesInterface {
  @visibleForTesting
  SharedPreferences? prefs;

  @override
  bool get initialized => prefs != null;

  @override
  Future<void> loadSharedPrefs() async {
    prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> writeStringToSharedPrefs(
    SharedPreferencesKey key,
    String value,
  ) async {
    await loadSharedPrefs();
    await prefs?.setString(key.name, value);
  }

  @override
  Future<void> writeBoolToSharedPrefs(
    SharedPreferencesKey key, {
    required bool value,
  }) async {
    await loadSharedPrefs();
    await prefs?.setBool(key.name, value);
  }

  @override
  Future<void> writeIntToSharedPrefs(
    SharedPreferencesKey key, {
    required int value,
  }) async {
    await loadSharedPrefs();
    await prefs?.setInt(key.name, value);
  }

  @override
  Future<int?> getSharedPrefInt(SharedPreferencesKey key) async {
    await loadSharedPrefs();
    return prefs?.getInt(key.name);
  }

  @override
  Future<String?> getSharedPrefString(SharedPreferencesKey key) async {
    await loadSharedPrefs();
    return prefs?.getString(key.name);
  }

  @override
  Future<bool?> getSharedPrefBool(SharedPreferencesKey key) async {
    await loadSharedPrefs();
    return prefs?.getBool(key.name);
  }
}
