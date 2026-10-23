import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/string_ext.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/platform/system_locale.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';

class SharedPreferencesCubit extends Cubit<SharedPreferencesState> {
  SharedPreferencesCubit(this._sharedPreferencesProvider)
      : super(const SharedPreferencesInitial());
  final SharedPreferencesInterface _sharedPreferencesProvider;

  Future<String> getLanguage() async {
    final selectedLanguage =
        await _sharedPreferencesProvider.getSharedPrefString(
      SharedPreferencesKey.language,
    );

    final systemLanguage = await findSystemLocale();

    _update(
      language: Locale(selectedLanguage ?? systemLanguage.getLanguageCode()),
    );

    return selectedLanguage ?? systemLanguage.getLanguageCode();
  }

  Future<void> finishFirstPushupCompleted() =>
      _sharedPreferencesProvider.writeBoolToSharedPrefs(
        SharedPreferencesKey.firstPushupDone,
        value: true,
      );

  Future<bool> getFirstPushupCompleted() async {
    final firstPushupCompleted =
        await _sharedPreferencesProvider.getSharedPrefBool(
      SharedPreferencesKey.firstPushupDone,
    );

    return firstPushupCompleted ?? false;
  }

  Future<int> getVolume() async {
    final volume = await _sharedPreferencesProvider.getSharedPrefInt(
          SharedPreferencesKey.volume,
        ) ??
        10;

    return volume;
  }

  Future<void> setLanguage(Locale locale) async {
    await _sharedPreferencesProvider.writeStringToSharedPrefs(
      SharedPreferencesKey.language,
      locale.toLanguageTag(),
    );

    _update(language: locale);
  }

  Future<void> setVolume(int volume) async {
    await _sharedPreferencesProvider.writeIntToSharedPrefs(
      SharedPreferencesKey.volume,
      value: volume,
    );

    _update(volumeLevel: volume);
  }

  Future<void> setFirstPushupCompleted({required bool completed}) async {
    await _sharedPreferencesProvider.writeBoolToSharedPrefs(
      SharedPreferencesKey.firstPushupDone,
      value: completed,
    );

    _update(firstPushupCompleted: completed);
  }

  Future<void> setFirstJoined() async {
    if (await getFirstJoined() == null) {
      await _sharedPreferencesProvider.writeStringToSharedPrefs(
        SharedPreferencesKey.joined,
        DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now()),
      );
    }
  }

  Future<DateTime?> getFirstJoined() async {
    final dateString = await _sharedPreferencesProvider.getSharedPrefString(
          SharedPreferencesKey.joined,
        ) ??
        '';
    if (dateString != '') {
      return DateFormat('yyyy-MM-dd hh:mm:ss').parse(
        dateString,
      );
    }
    return null;
  }

  Future<void> setFirstTimeIslandVisited({required bool isFirstVisit}) async {
    await _sharedPreferencesProvider.writeBoolToSharedPrefs(
      SharedPreferencesKey.firstTimeIslandVisited,
      value: isFirstVisit,
    );
    _update(firstTimeIslandVisited: isFirstVisit);
  }

  Future<bool> getFirstTimeIslandVisited() async {
    final isFirstVisit = await _sharedPreferencesProvider.getSharedPrefBool(
          SharedPreferencesKey.firstTimeIslandVisited,
        ) ??
        true;

    _update(firstTimeIslandVisited: isFirstVisit);

    return isFirstVisit;
  }

  /// Emits the loaded state with the given fields changed, keeping the rest.
  void _update({
    Locale? language,
    int? volumeLevel,
    bool? firstPushupCompleted,
    bool? firstTimeIslandVisited,
  }) =>
      emit(
        SharedPreferencesLoaded(
          language: language ?? state.language,
          volumeLevel: volumeLevel ?? state.volumeLevel,
          firstPushupCompleted:
              firstPushupCompleted ?? state.firstPushupCompleted,
          firstTimeIslandVisited:
              firstTimeIslandVisited ?? state.firstTimeIslandVisited,
        ),
      );
}
