import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';
import 'package:pushup_bro/features/social/social_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeSocialBackend backend;
  late AccountCubit account;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeSocialBackend();
    account = AccountCubit(
      backend,
      SharedPreferencesProvider(),
      random: math.Random(7),
    );
  });

  tearDown(() => account.close());

  test('signs in anonymously and gets a bro name and a code', () async {
    await account.start(look: const MonkeyLook(hat: 'hat.crown'));

    final profile = account.state.profile!;
    expect(account.state.status, AccountStatus.ready);
    expect(profile.uid, 'me');
    expect(FriendCode.isValid(profile.code), isTrue);
    expect(backend.codes[profile.code], 'me');
    expect(backend.profiles['me'], profile);
    expect(profile.look.hat, 'hat.crown');
    expect(account.state.isLinked, isFalse);
  });

  test('keeps the same name and code on the next launch', () async {
    await account.start();
    final first = account.state.profile!;
    await account.start();
    expect(account.state.profile!.code, first.code);
    expect(account.state.profile!.broName, first.broName);
  });

  test('tries another code when one is taken', () async {
    final taken = FriendCode.generate(math.Random(7));
    backend.codes[taken] = 'someone';
    await account.start();
    expect(account.state.profile!.code, isNot(taken));
  });

  test('is offline without Firebase', () async {
    final offline = AccountCubit(
      UnavailableSocialBackend(),
      SharedPreferencesProvider(),
    );
    await offline.start();
    expect(offline.state.status, AccountStatus.offline);
    await offline.close();
  });

  group('the save prompt', () {
    setUp(() => account.start());

    test('waits until Pro starts from a purchase or restore', () async {
      expect(await account.shouldPromptUpgrade(), isFalse);
      await account.markUpgradePrompt();
      expect(await account.shouldPromptUpgrade(), isTrue);
    });

    test('shows once', () async {
      await account.markUpgradePrompt();
      await account.upgradePromptShown();
      expect(await account.shouldPromptUpgrade(), isFalse);
      await account.markUpgradePrompt();
      expect(await account.shouldPromptUpgrade(), isFalse);
    });

    test('never shows once Apple or Google is connected', () async {
      await account.markUpgradePrompt();
      await account.link(SignInProvider.apple);
      expect(account.state.linked, {SignInProvider.apple});
      expect(await account.shouldPromptUpgrade(), isFalse);
    });
  });

  test('connecting keeps the uid and calls back for Pro', () async {
    String? signedIn;
    account.onSignedIn = (uid) => signedIn = uid;
    await account.start();
    final outcome = await account.link(SignInProvider.google);
    expect(outcome, isA<Linked>());
    expect(account.state.uid, 'me');
    expect(signedIn, 'me');
  });

  test('a cancelled sheet changes nothing', () async {
    await account.start();
    backend.nextSheet = const LinkCancelled();
    expect(await account.link(SignInProvider.apple), isA<LinkCancelled>());
    expect(account.state.isLinked, isFalse);
  });

  test(
      'an Apple ID with an island elsewhere signs in to it and offers '
      'the restore, keeping the friends made here', () async {
    // The island saved from the old iPhone.
    backend
      ..accountsByProvider[SignInProvider.apple] = 'old'
      ..profiles['old'] = const BroProfile(
        uid: 'old',
        broName: BroName(1, 1, 1),
        code: 'ZZZZZZ',
        streak: 12,
      )
      ..codes['ZZZZZZ'] = 'old'
      ..backups['old'] = CloudBackup(
        savedAt: DateTime(2026, 10, 28, 21, 14),
        device: 'iPhone',
        prefs: const {},
        inventory: const {},
        sets: const [],
      )
      ..profiles['mia'] = const BroProfile(
        uid: 'mia',
        broName: BroName(2, 2, 2),
        code: 'MAZ9QK',
      )
      ..codes['MAZ9QK'] = 'mia';
    await account.start();
    final leftover = account.state.profile!.code;
    await backend.addFriend(me: 'me', friend: 'mia', code: 'MAZ9QK');

    final outcome = await account.link(SignInProvider.apple);

    expect(outcome, isA<SwitchedAccount>());
    expect(account.state.uid, 'old');
    expect(account.state.profile!.streak, 12);
    expect(account.state.restore, isNotNull);
    // The anonymous account is gone, its friend moved over.
    expect(backend.profiles.containsKey('me'), isFalse);
    expect(backend.codes.containsKey(leftover), isFalse);
    expect(backend.friendEdges['old'], contains('mia'));
    expect(backend.friendEdges['mia'], contains('old'));
  });

  test('deleting removes everything on the server and starts over', () async {
    await account.start();
    final code = account.state.profile!.code;
    await account.deleteAccount();
    expect(backend.codes.containsKey(code), isFalse);
    expect(account.state.status, AccountStatus.ready);
    expect(account.state.profile!.code, isNot(code));
  });
}
