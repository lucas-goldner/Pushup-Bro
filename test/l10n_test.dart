import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/generated/l10n.dart';

void main() {
  group('language selection label', () {
    test('reads 言語選択 in Japanese', () async {
      final s = await S.load(const Locale('ja'));

      expect(s.switchLanguage, '言語選択');
    });

    test('reads "Switch language" in English', () async {
      final s = await S.load(const Locale('en'));

      expect(s.switchLanguage, 'Switch language');
    });
  });

  group('close-without-saving explanation', () {
    test('refers to the pushup set in Japanese, not the settings', () async {
      final s = await S.load(const Locale('ja'));

      expect(s.closeExplanation, '今終了すると、セットは保存されません');
      expect(s.closeExplanation, isNot(contains('設定')));
    });
  });
}
