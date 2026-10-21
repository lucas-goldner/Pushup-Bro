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

    emit(
      SharedPreferencesLoaded(
        language: Locale(selectedLanguage ?? systemLanguage.getLanguageCode()),
        volumeLevel: state.volumeLevel,
        firstPushupCompleted: state.firstPushupCompleted,
      ),
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

    emit(
      SharedPreferencesLoaded(
        language: locale,
        volumeLevel: state.volumeLevel,
        firstPushupCompleted: state.firstPushupCompleted,
      ),
    );
  }

  Future<void> setVolume(int volume) async {
    await _sharedPreferencesProvider.writeIntToSharedPrefs(
      SharedPreferencesKey.volume,
      value: volume,
    );

    emit(
      SharedPreferencesLoaded(
        language: state.language,
        volumeLevel: volume,
        firstPushupCompleted: state.firstPushupCompleted,
      ),
    );
  }

  Future<void> setFirstPushupCompleted({required bool completed}) async {
    await _sharedPreferencesProvider.writeBoolToSharedPrefs(
      SharedPreferencesKey.firstPushupDone,
      value: completed,
    );

    emit(
      SharedPreferencesLoaded(
        language: state.language,
        volumeLevel: state.volumeLevel,
        firstPushupCompleted: completed,
      ),
    );
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
    emit(
      SharedPreferencesLoaded(firstTimeIslandVisited: isFirstVisit),
    );
  }

  Future<bool> getFirstTimeIslandVisited() async {
    final isFirstVisit = await _sharedPreferencesProvider.getSharedPrefBool(
          SharedPreferencesKey.firstTimeIslandVisited,
        ) ??
        true;

    emit(
      SharedPreferencesLoaded(firstTimeIslandVisited: isFirstVisit),
    );

    return isFirstVisit;
  }
}
