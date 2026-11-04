import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/settings/model/progress_reset.dart';
import 'package:pushup_bro/features/settings/widgets/reset_progress.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _json(GameInventory inventory) => jsonEncode(inventory);

class _MemoryDB extends DBProvider {
  List<PushupSet> sets = [
    PushupSet([Pushup(completedAt: DateTime(2026, 11, 1, 9))], 2, id: 1),
    PushupSet([Pushup(completedAt: DateTime(2026, 11, 2))], 3, id: 2),
  ];
  User user = User.empty().copyWith(level: 4, xp: 30);
  GameInventory inventory = GameInventory.empty().copyWith(
    bananas: 900,
    boughtItems: [ShopBuyables.airport],
    ownedCosmetics: ['hat.party'],
    trek: const TrekProgress(level: 5, stars: {'fern-trail': 3}),
  );

  @override
  bool get initialized => true;
  @override
  Future<void> loadDB() async {}
  @override
  Future<User> getUser() async => user;
  @override
  Future<void> updateUser(User user) async => this.user = user;
  @override
  Future<GameInventory> getInventory() async => inventory;
  @override
  Future<void> updateInventory(GameInventory inventory) async =>
      this.inventory = inventory;
  @override
  Future<List<PushupSet>> getAllPushupSets() async => [...sets];
  @override
  Future<void> deletePushupSet(int id) async =>
      sets = sets.where((set) => set.id != id).toList();
}

void main() {
  late _MemoryDB db;
  late DBCubit dbCubit;
  late GameInventoryCubit inventory;
  late SharedPreferencesCubit prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKey.firstTimeIslandVisited.name: false,
      SharedPreferencesKey.trekBestCombo.name: 12,
      SharedPreferencesKey.dailyBananasClaimedOn.name: '2026-11-04',
      SharedPreferencesKey.firstPushupDone.name: true,
      SharedPreferencesKey.musicVolume.name: 3,
    });
    db = _MemoryDB();
    dbCubit = DBCubit(db);
    inventory = GameInventoryCubit(db);
    prefs = SharedPreferencesCubit(SharedPreferencesProvider());
    await dbCubit.getUser();
    await dbCubit.getAllPushupSets();
    await inventory.fetchInventory();
  });

  ProgressReset reset() => ProgressReset(
        dbCubit: dbCubit,
        inventory: inventory,
        prefsCubit: prefs,
      );

  test('resetting the island keeps the pushups and the bro level', () async {
    await reset().resetIsland();
    final stored = await SharedPreferences.getInstance();

    expect(_json(db.inventory), _json(GameInventory.empty()));
    expect(
      _json(inventory.state.inventory),
      _json(GameInventory.empty()),
    );
    expect(stored.getBool('firstTimeIslandVisited'), isTrue);
    expect(stored.containsKey('trekBestCombo'), isFalse);
    expect(stored.containsKey('dailyBananasClaimedOn'), isFalse);
    // Kept.
    expect(db.sets, hasLength(2));
    expect(db.user.level, 4);
    expect(stored.getInt('musicVolume'), 3);
  });

  test('resetting everything clears the pushups and the bro level too',
      () async {
    await reset().resetAll();
    final stored = await SharedPreferences.getInstance();

    expect(_json(db.inventory), _json(GameInventory.empty()));
    expect(db.sets, isEmpty);
    expect(dbCubit.state.pushupSets, isEmpty);
    expect(db.user.level, 1);
    expect(db.user.xp, 0);
    expect(stored.getBool('firstPushupDone'), isFalse);
    // Settings stay.
    expect(stored.getInt('musicVolume'), 3);
  });

  Future<void> pumpGroup(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: dbCubit),
          BlocProvider.value(value: inventory),
          BlocProvider.value(value: prefs),
        ],
        child: Theme(
          data: lightTheme,
          child: const CupertinoApp(
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Material(child: ResetProgressGroup()),
          ),
        ),
      ),
    );
  }

  testWidgets('asks first, and cancelling changes nothing', (tester) async {
    await pumpGroup(tester);

    await tester.tap(find.text('Reset all progress'));
    await tester.pumpAndSettle();
    expect(find.textContaining("can't be undone"), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(db.sets, hasLength(2));
    expect(db.inventory.bananas, 900);
  });

  testWidgets('resets the island after the confirm', (tester) async {
    await pumpGroup(tester);

    await tester.tap(find.text('Reset island').first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Reset island').last);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('Done: a fresh start!'), findsOneWidget);
    expect(_json(db.inventory), _json(GameInventory.empty()));
    expect(db.sets, hasLength(2));
  });
}
