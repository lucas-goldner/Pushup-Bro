import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/bro_push.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/data/push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePush implements PushService {
  int asked = 0;
  String? token = 'tok1';
  final refresh = StreamController<String>.broadcast();

  @override
  Future<String?> enable() async {
    asked++;
    return token;
  }

  @override
  Stream<String> get tokenRefresh => refresh.stream;

  @override
  Stream<String> get opened => const Stream.empty();
}

void main() {
  late FakeSocialBackend backend;
  late AccountCubit account;
  late _FakePush push;
  late BroPush broPush;
  var language = 'de';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = FakeSocialBackend();
    account = AccountCubit(
      backend,
      SharedPreferencesProvider(),
      random: math.Random(7),
    );
    push = _FakePush();
    language = 'de';
    broPush = BroPush(account: account, push: push, language: () => language)
      ..start();
    account.beforeSignOut = broPush.forget;
    await account.start();
  });

  tearDown(() async {
    await broPush.dispose();
    await account.close();
  });

  Future<void> addBro() async {
    await account.updateProfile(friendCount: 1);
    await broPush.update();
  }

  test("doesn't ask for notifications before the first bro", () async {
    await broPush.update();

    expect(push.asked, 0);
    expect(backend.devices, isEmpty);
  });

  test('registers the token in the app language once there is a bro', () async {
    await addBro();

    expect(backend.devices['me'], {'tok1': 'de'});
  });

  test('asks once and writes again only when something changed', () async {
    await addBro();
    await broPush.update();
    await broPush.update();

    expect(push.asked, 1);

    language = 'ja';
    await broPush.update();
    expect(backend.devices['me'], {'tok1': 'ja'});
  });

  test('sends other languages in English', () async {
    language = 'fr';
    await addBro();

    expect(backend.devices['me'], {'tok1': 'en'});
  });

  test('stays quiet when notifications are off', () async {
    push.token = null;
    await addBro();

    expect(backend.devices, isEmpty);
  });

  test('saves a new token', () async {
    await addBro();
    push.refresh.add('tok2');
    await Future<void>.delayed(Duration.zero);
    await broPush.update();

    expect(backend.devices['me']!['tok2'], 'de');
  });

  test('removes the token from the old account on sign out', () async {
    await addBro();
    await account.signOut();
    await broPush.update();

    expect(backend.devices['me'], isEmpty);
    // The new account has no bros yet.
    expect(backend.devices['me-2'], isNull);
  });
}
