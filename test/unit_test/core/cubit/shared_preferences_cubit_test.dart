import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('checking the island visit keeps the chosen language', () async {
    final provider = SharedPreferencesProvider();
    await provider.loadSharedPrefs();
    final cubit = SharedPreferencesCubit(provider);

    await cubit.setLanguage(const Locale('de'));
    await cubit.setVolume(3);
    await cubit.getFirstTimeIslandVisited();
    await cubit.setFirstTimeIslandVisited(isFirstVisit: false);

    expect(cubit.state.language, const Locale('de'));
    expect(cubit.state.volumeLevel, 3);
    expect(cubit.state.firstTimeIslandVisited, isFalse);
  });

  test('changing the language keeps the island visit', () async {
    final provider = SharedPreferencesProvider();
    await provider.loadSharedPrefs();
    final cubit = SharedPreferencesCubit(provider);

    await cubit.setFirstTimeIslandVisited(isFirstVisit: false);
    await cubit.setLanguage(const Locale('ja'));

    expect(cubit.state.firstTimeIslandVisited, isFalse);
  });
}
