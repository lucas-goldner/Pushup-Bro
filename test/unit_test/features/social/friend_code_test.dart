import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';

void main() {
  test('generates six letters and digits that are hard to mix up', () {
    final random = math.Random(1);
    for (var i = 0; i < 200; i++) {
      final code = FriendCode.generate(random);
      expect(FriendCode.isValid(code), isTrue, reason: code);
      expect(code, isNot(matches(RegExp('[01OIL]'))));
    }
  });

  test('shows the code with a dash', () {
    expect(FriendCode.format('4K2B7Q'), '4K2-B7Q');
  });

  test('reads typed, pasted and scanned codes', () {
    expect(FriendCode.normalize('4k2-b7q'), '4K2B7Q');
    expect(FriendCode.normalize(' 4K2 B7Q '), '4K2B7Q');
    expect(
      FriendCode.normalize('https://lucas-goldner.com/pb/4K2B7Q'),
      '4K2B7Q',
    );
    expect(
      FriendCode.normalize(
        'Be my pushup bro: https://lucas-goldner.com/pb/4K2B7Q',
      ),
      '4K2B7Q',
    );
  });

  test('rejects codes with letters outside the alphabet', () {
    expect(FriendCode.isValid('4K2B7'), isFalse);
    expect(FriendCode.isValid('4K2B0Q'), isFalse);
    expect(FriendCode.isValid('OOOOOO'), isFalse);
  });

  test('links to the add screen', () {
    expect(FriendCode.link('4K2B7Q'), 'https://lucas-goldner.com/pb/4K2B7Q');
  });
}
