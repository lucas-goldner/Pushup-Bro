import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/core/widgets/phone_page.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/demo_social_backend.dart';
import 'package:pushup_bro/features/stats/stats_page.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wednesday, 28 October 2026, in the evening.
final statsNow = DateTime(2026, 10, 28, 19);

/// A believable log: most days over the last four months, more lately.
List<PushupSet> sampleSets() {
  final random = math.Random(7);
  final sets = <PushupSet>[];
  for (var back = 120; back >= 0; back--) {
    if (random.nextDouble() < (back < 30 ? 0.2 : 0.45)) continue;
    final day = DateTime(statsNow.year, statsNow.month, statsNow.day - back);
    for (var s = 0; s < 1 + random.nextInt(3); s++) {
      final start = day.add(
        Duration(hours: [7, 12, 18, 21][random.nextInt(4)], minutes: s * 9),
      );
      if (start.isAfter(statsNow)) continue;
      final count = 8 + random.nextInt(18) + (120 - back) ~/ 12;
      sets.add(
        PushupSet(
          [
            for (var i = 0; i < count; i++)
              Pushup(
                completedAt: start.add(
                  Duration(milliseconds: i * (1500 + random.nextInt(900))),
                ),
              ),
          ],
          1 + random.nextInt(5),
          id: start.microsecondsSinceEpoch,
        ),
      );
    }
  }
  return sets;
}

/// A played-for-a-while inventory.
GameInventory sampleInventory() => GameInventory.empty().copyWith(
      bananas: 1240,
      boughtItems: [ShopBuyables.accessories, ShopBuyables.airport],
      ownedCosmetics: ['hat.party', 'eyes.stars'],
      quests: const QuestLog(
        completed: {'volcano-hiccups': 6, 'wishing-moon': 3},
      ),
      trek: TrekProgress(
        level: 6,
        power: 3,
        vitality: 2,
        grip: 1,
        agility: 2,
        stars: {
          for (final stage in TrekStage.all.take(4)) stage.id: 3,
          TrekStage.all[4].id: 2,
        },
      ),
    );

class StatsDBProvider extends DBProvider {
  StatsDBProvider({
    this.sets = const [],
    GameInventory? inventory,
    User? user,
  })  : inventory = inventory ?? GameInventory.empty(),
        user = user ?? User.empty();

  final List<PushupSet> sets;
  final GameInventory inventory;
  final User user;

  @override
  bool get initialized => true;

  @override
  Future<void> loadDB() async {}

  @override
  Future<User> getUser() async => user;

  @override
  Future<GameInventory> getInventory() async => inventory;

  @override
  Future<List<PushupSet>> getAllPushupSets() async => [...sets];
}

/// The stats page as the menu shows it, filled from [db].
Future<void> pumpStats(
  WidgetTester tester,
  StatsDBProvider db, {
  Locale locale = const Locale('en'),
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final dbCubit = DBCubit(db);
  final inventory = GameInventoryCubit(db);
  final onboarding = OnboardingCubit(SharedPreferencesProvider());
  final account = AccountCubit(
    demoSocialBackend(now: statsNow),
    SharedPreferencesProvider(),
  );
  addTearDown(account.close);
  await tester.runAsync(() async {
    await dbCubit.getUser();
    await dbCubit.getAllPushupSets();
    await inventory.fetchInventory();
    await onboarding.load();
  });

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: dbCubit),
        BlocProvider.value(value: inventory),
        BlocProvider.value(value: onboarding),
        BlocProvider.value(value: account),
      ],
      child: Theme(
        data: dark ? darkTheme : lightTheme,
        child: CupertinoApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: locale,
          home: Material(
            child: PhonePage(child: StatsPage(now: statsNow)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the totals, records and the game', (tester) async {
    await pumpStats(
      tester,
      StatsDBProvider(
        sets: [
          PushupSet(
            [
              for (var i = 0; i < 12; i++)
                Pushup(
                  completedAt: DateTime(2026, 10, 28, 8).add(
                    Duration(seconds: 2 * i),
                  ),
                ),
            ],
            2,
          ),
          PushupSet(
            [
              for (var i = 0; i < 30; i++)
                Pushup(
                  completedAt: DateTime(2026, 10, 27, 8).add(
                    Duration(seconds: 2 * i),
                  ),
                ),
            ],
            2,
          ),
        ],
        inventory: sampleInventory(),
        user: User.empty().copyWith(level: 3, xp: 40),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('2 days'), findsNWidgets(2));
    expect(find.text('42 pushups'), findsOneWidget);
    expect(find.text('Bro Level 3'), findsNothing);

    await tester.scrollUntilVisible(find.text('Bro Level 3'), 300);
    expect(find.text('1,240'), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Jungle Trek'), 300);
    expect(find.text('5 / ${TrekStage.all.length}'), findsOneWidget);
  });

  testWidgets('switches the activity chart between week, month and year',
      (tester) async {
    await pumpStats(
      tester,
      StatsDBProvider(sets: sampleSets(), inventory: sampleInventory()),
    );

    expect(find.text('Last 7 days'), findsOneWidget);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Last 30 days'), findsOneWidget);
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('Last 12 months'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('says how to fill it before the first set', (tester) async {
    await pumpStats(tester, StatsDBProvider());

    expect(tester.takeException(), isNull);
    expect(
      find.text('Finish your first set and your stats fill up here.'),
      findsOneWidget,
    );
    expect(find.text('No pushups here yet'), findsOneWidget);
  });

  for (final locale in S.delegate.supportedLocales) {
    for (final dark in [false, true]) {
      testWidgets(
          'fits a small phone in ${locale.languageCode}'
          '${dark ? ', dark' : ''}', (tester) async {
        tester.view
          ..physicalSize = const Size(320, 568)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpStats(
          tester,
          StatsDBProvider(sets: sampleSets(), inventory: sampleInventory()),
          locale: locale,
          dark: dark,
        );
        for (var i = 0; i < 8; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
