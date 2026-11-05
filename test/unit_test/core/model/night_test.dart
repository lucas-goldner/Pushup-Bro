import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/night.dart';

void main() {
  test('it is night from 8 pm until 6 am', () {
    expect(isNight(DateTime(2026, 11, 4, 21)), isTrue);
    expect(isNight(DateTime(2026, 11, 4, 3)), isTrue);
    expect(isNight(DateTime(2026, 11, 4, 12)), isFalse);
  });

  test('night starts at 8 pm and ends at 6 am sharp', () {
    expect(isNight(DateTime(2026, 11, 4, 19, 59, 59)), isFalse);
    expect(isNight(DateTime(2026, 11, 4, 20)), isTrue);
    expect(isNight(DateTime(2026, 11, 4, 23, 59)), isTrue);
    expect(isNight(DateTime(2026, 11, 5)), isTrue);
    expect(isNight(DateTime(2026, 11, 5, 5, 59, 59)), isTrue);
    expect(isNight(DateTime(2026, 11, 5, 6)), isFalse);
  });
}
