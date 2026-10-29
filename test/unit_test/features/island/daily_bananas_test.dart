import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/island/model/daily_bananas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  DailyBananas at(DateTime time) =>
      DailyBananas(prefs: SharedPreferencesProvider(), clock: () => time);

  test('offers the bananas on the first visit of the day', () async {
    expect(await at(DateTime(2026, 10, 29, 8)).available(), isTrue);
  });

  test('gives them only once a day', () async {
    final morning = at(DateTime(2026, 10, 29, 8));
    expect(await morning.claim(), isTrue);
    expect(await morning.claim(), isFalse);

    final evening = at(DateTime(2026, 10, 29, 23, 59));
    expect(await evening.available(), isFalse);
    expect(await evening.claim(), isFalse);
  });

  test('offers them again the next day', () async {
    expect(await at(DateTime(2026, 10, 29, 23, 59)).claim(), isTrue);

    final tomorrow = at(DateTime(2026, 10, 30, 0, 1));
    expect(await tomorrow.available(), isTrue);
    expect(await tomorrow.claim(), isTrue);
  });

  test('pads the day key', () {
    expect(DailyBananas.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
