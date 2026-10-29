import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/cloud_save.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store implements PurchasesService {
  bool pro = false;

  @override
  bool get isAvailable => true;

  @override
  Future<ProCatalog> load() async => (plans: const <ProPlan>[], isPro: pro);

  @override
  Future<bool?> purchase(ProPlan plan) async => pro = true;

  @override
  Future<bool> restore() async => pro;

  @override
  Future<bool> logIn(String uid) async => pro;
}

class _Source implements BackupSource {
  final _changes = StreamController<void>.broadcast();
  CloudBackup? applied;
  List<Map<String, dynamic>> sets = [
    {'id': 1, 'pushups': const <Object>[], 'effort': 3},
  ];

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<CloudBackup> collect({required DateTime now}) async => CloudBackup(
        savedAt: now,
        device: 'iPhone',
        prefs: const {'onboardingCompleted': true},
        inventory: const {'bananas': 40},
        sets: sets,
      );

  @override
  Future<void> apply(CloudBackup backup) async => applied = backup;

  @override
  Future<int> pushupsToday(DateTime now) async => 0;
}

void main() {
  late FakeSocialBackend backend;
  late AccountCubit account;
  late _Store store;
  late ProCubit pro;
  late CloudSave save;
  final now = DateTime(2026, 10, 29, 18);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = FakeSocialBackend();
    account = AccountCubit(backend, SharedPreferencesProvider());
    store = _Store();
    pro = ProCubit(SharedPreferencesProvider(), purchases: store);
    save = CloudSave(
      account: account,
      pro: pro,
      source: _Source(),
      clock: () => now,
    );
    await account.start();
    await pro.load();
  });

  tearDown(() async {
    await save.dispose();
    await account.close();
    await pro.close();
  });

  test('saves nothing for a free anonymous player', () async {
    expect(await save.saveNow(), isFalse);
    expect(backend.backups, isEmpty);
  });

  test('saves nothing for Pro until Apple or Google is connected', () async {
    store.pro = true;
    await pro.load();
    expect(await save.saveNow(), isFalse);
  });

  test('saves a linked Pro member and remembers when', () async {
    store.pro = true;
    await pro.load();
    await account.link(SignInProvider.apple);

    expect(await save.saveNow(), isTrue);
    expect(backend.backups['me']!.inventory['bananas'], 40);
    expect(account.state.savedAt, now);
  });

  test('pauses when Pro lapses, keeping what was saved', () async {
    store.pro = true;
    await pro.load();
    await account.link(SignInProvider.apple);
    await save.saveNow();
    store.pro = false;
    await pro.load();

    expect(save.paused, isTrue);
    expect(await save.saveNow(), isFalse);
    expect(backend.backups['me'], isNotNull);
  });

  test('restoring keeps the sets done on this iPhone (by id)', () {
    final merged = mergeSets(
      [
        {'id': 1, 'pushups': const <Object>[]},
        {'id': 2, 'pushups': const <Object>[]},
      ],
      [
        {'id': 2, 'pushups': const <Object>[]},
        {'id': 3, 'pushups': const <Object>[]},
      ],
    );
    expect(merged.map((set) => set['id']), [1, 2, 3]);
  });

  test('groups sets by the year of their first pushup', () {
    expect(
      setYear({
        'pushups': [
          {'completedAt': '2025-12-31T23:00:00.000'},
        ],
      }),
      2025,
    );
    expect(setYear({'pushups': const <Object>[]}), 0);
  });
}
