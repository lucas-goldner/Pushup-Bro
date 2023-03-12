import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/utils/extensions/string_extensions.dart';

void main() {
  group('test getLanguageCode', () {
    test('test getLanguageCode for de', () async {
      expect('de_DE'.getLanguageCode(), 'de');
    });
  });
}
