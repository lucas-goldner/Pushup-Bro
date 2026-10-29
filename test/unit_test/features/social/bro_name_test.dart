import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';

void main() {
  test('is stored as its parts and read back', () {
    final name = BroName.random(math.Random(3));
    expect(BroName.parse(name.key), name);
  });

  test('reads in every language', () {
    const name = BroName(0, 0, 4821);
    expect(name.display('en'), 'Banana Bro 4821');
    expect(name.display('de'), 'Bananen Bro 4821');
    expect(name.display('es'), 'Bro Bananero 4821');
    expect(name.display('pt'), 'Bro Banana 4821');
    expect(name.display('ja'), 'バナナブロ 4821');
    expect(name.display('fr'), 'Banana Bro 4821');
  });

  test('pads the number', () {
    expect(const BroName(1, 2, 7).display('en'), 'Jungle Gorilla 0007');
  });

  test('turns a broken name into a friendly one', () {
    expect(BroName.parse(null), const BroName(0, 0, 0));
    expect(BroName.parse('nonsense'), const BroName(0, 0, 0));
    expect(BroName.parse('99.99.123456'), const BroName(15, 15, 9999));
  });
}
