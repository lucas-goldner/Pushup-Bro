import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/app_icon/app_icon_choice.dart';
import 'package:pushup_bro/features/app_icon/app_icon_service.dart';

void main() {
  group('AppIconChoice', () {
    test('Classic is the primary icon, the rest are alternates', () {
      expect(AppIconChoice.classic.iosName, isNull);
      expect(AppIconChoice.classic.needsPro, isFalse);
      for (final choice in AppIconChoice.values.skip(1)) {
        expect(choice.iosName, startsWith('AppIcon-'));
        expect(choice.needsPro, isTrue);
      }
    });

    test('maps the iOS names both ways', () {
      expect(AppIconChoice.golden.iosName, 'AppIcon-Golden');
      expect(AppIconChoice.kingKomo.iosName, 'AppIcon-KingKomo');
      expect(AppIconChoice.bigBoss.iosName, 'AppIcon-BigBoss');
      for (final choice in AppIconChoice.values) {
        expect(AppIconChoice.fromIosName(choice.iosName), choice);
      }
      expect(AppIconChoice.fromIosName(null), AppIconChoice.classic);
      expect(AppIconChoice.fromIosName('AppIcon-Gone'), AppIconChoice.classic);
    });

    test('every alternate has an icon set and is in the Xcode project', () {
      final project =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      final alternates = RegExp(
        'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "([^"]*)";',
      ).allMatches(project).map((m) => m.group(1)!.split(' ').toSet());

      // Set on every Runner configuration.
      expect(alternates, hasLength(6));
      for (final names in alternates) {
        expect(
          names,
          unorderedEquals(
            AppIconChoice.values.map((c) => c.iosName).whereType<String>(),
          ),
        );
      }
      for (final choice in AppIconChoice.values.skip(1)) {
        final set = 'ios/Runner/Assets.xcassets/${choice.iosName}.appiconset';
        expect(File('$set/Contents.json').existsSync(), isTrue, reason: set);
        expect(File('$set/icon-1024.png').existsSync(), isTrue, reason: set);
      }
    });

    test('every icon has a preview image', () {
      for (final choice in AppIconChoice.values) {
        expect(File(choice.preview.path).existsSync(), isTrue);
      }
    });
  });

  group('AppIconService', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('pushup_bro/app_icon');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('reads and sets the icon by its iOS name', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'isSupported' => true,
          'current' => 'AppIcon-Lava',
          _ => null,
        };
      });
      final service = AppIconService(enabled: true);

      expect(await service.isSupported(), isTrue);
      expect(await service.current(), AppIconChoice.lava);
      await service.set(AppIconChoice.classic);
      await service.set(AppIconChoice.snow);

      expect(
        calls.where((c) => c.method == 'set').map((c) => c.arguments),
        [null, 'AppIcon-Snow'],
      );
    });

    test('is a no-op off iOS', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        fail('No channel calls off iOS');
      });
      final service = AppIconService(enabled: false);

      expect(await service.isSupported(), isFalse);
      expect(await service.current(), AppIconChoice.classic);
      await service.set(AppIconChoice.bigBoss);
    });
  });
}
