import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/utils/get_localized_language_name.dart';

void main() {
  final languageLocal = LanguageLocal();

  group('test getDisplayLanguage for supported languages', () {
    test('test getDisplayLanguage for de', () async {
      final deLanguage = languageLocal.getDisplayLanguage('de');

      expect(
        deLanguage?.name,
        'German',
      );
      expect(
        deLanguage?.nativeName,
        'Deutsch',
      );
    });

    test('test getDisplayLanguage for en', () async {
      final enLanguage = languageLocal.getDisplayLanguage('en');

      expect(
        enLanguage?.name,
        'English',
      );
      expect(
        enLanguage?.nativeName,
        'English',
      );
    });

    test('test getDisplayLanguage for ja', () async {
      final jaLanguage = languageLocal.getDisplayLanguage('ja');

      expect(
        jaLanguage?.name,
        'Japanese',
      );
      expect(
        jaLanguage?.nativeName,
        '日本語 (にほんご／にっぽんご)',
      );
    });

    test('test getDisplayLanguage for pt', () async {
      final ptLanguage = languageLocal.getDisplayLanguage('pt');

      expect(
        ptLanguage?.name,
        'Portuguese',
      );
      expect(
        ptLanguage?.nativeName,
        'Português',
      );
    });

    test('test getDisplayLanguage for es', () async {
      final esLanguage = languageLocal.getDisplayLanguage('es');

      expect(
        esLanguage?.name,
        'Spanish; Castilian',
      );
      expect(
        esLanguage?.nativeName,
        'español, castellano',
      );
    });
  });

  test('test getDisplayLanguage for false language', () async {
    expect(
      () => languageLocal.getDisplayLanguage('falsyKey'),
      throwsA(isA<Exception>()),
    );
  });
}
