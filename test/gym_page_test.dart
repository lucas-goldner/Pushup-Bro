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
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_log.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_session.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_hud.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_result.dart';
import 'package:pushup_bro/features/island/buildings/gym_page.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GymDB extends DBProvider {
  _GymDB(this.inventory, this.sets);

  final GameInventory inventory;
  final List<PushupSet> sets;

  @override
  bool get initialized => true;

  @override
  Future<void> loadDB() async {}

  @override
  Future<GameInventory> getInventory() async => inventory;

  @override
  Future<List<PushupSet>> getAllPushupSets() async => [...sets];
}

final DateTime _yesterday = DateTime.now().subtract(const Duration(days: 1));

final List<PushupSet> _sets = [
  PushupSet(
    [for (var i = 0; i < 24; i++) Pushup(completedAt: _yesterday)],
    3,
    id: 4242,
  ),
];

/// [child] on a 320 pt phone, the smallest the app supports.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  GameInventory? inventory,
  Locale locale = const Locale('en'),
  bool dark = false,
}) async {
  tester.view
    ..physicalSize = const Size(320, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final db = _GymDB(inventory ?? GameInventory.empty(), _sets);
  final dbCubit = DBCubit(db);
  final inventoryCubit = GameInventoryCubit(db);
  final prefsProvider = SharedPreferencesProvider();
  await tester.runAsync(() async {
    await prefsProvider.loadSharedPrefs();
    await dbCubit.getAllPushupSets();
    await inventoryCubit.fetchInventory();
  });
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: dbCubit),
        BlocProvider.value(value: inventoryCubit),
        BlocProvider(create: (_) => SharedPreferencesCubit(prefsProvider)),
        BlocProvider(
          create: (_) => AirPodsTrackerCubit(AirPodsMotionProvider()),
        ),
      ],
      child: MaterialApp(
        theme: dark ? darkTheme : lightTheme,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: locale,
        home: child,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  final streaky = GameInventory.empty().copyWith(
    gym: GymLog(
      completed: const {'pyramid': 3, 'emom': 1},
      lastCompletedDay: dayNumber(_yesterday),
      streak: 4,
      bestStreak: 9,
    ).complete('tempo', DateTime.now()),
  );

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('the gym fits a small phone in ${locale.languageCode}',
        (tester) async {
      for (final inventory in [GameInventory.empty(), streaky]) {
        for (final dark in [false, true]) {
          await _pump(
            tester,
            const GymPage(showScene: false),
            inventory: inventory,
            locale: locale,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          // Scroll to the end: the list of workouts lays out too.
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -4000),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('every workout HUD fits in ${locale.languageCode}',
        (tester) async {
      for (final kind in GymChallengeKind.values) {
        final session = GymSession(
          GymChallenge.build(
            kind,
            const GymStrength(typical: 40, best: 60),
          ),
        )
          ..rep(1, downSeconds: 3)
          ..rep(2, downSeconds: 3);
        for (final started in [false, true]) {
          await _pump(
            tester,
            Scaffold(
              body: GymHud(
                session: session,
                now: 3,
                started: started,
                downFor: 1.5,
                coachLine: S.current.gymCoach3,
                onStart: () {},
                onFinish: () {},
              ),
            ),
            locale: locale,
          );
          expect(tester.takeException(), isNull, reason: kind.name);
        }
      }
    });

    testWidgets('the finish card fits in ${locale.languageCode}',
        (tester) async {
      final challenge = GymChallenge.build(
        GymChallengeKind.gusDrill,
        GymStrength.beginner,
      );
      for (final won in [true, false]) {
        await _pump(
          tester,
          Scaffold(
            body: GymResult(
              challenge: challenge,
              won: won,
              pushups: 123,
              bananas: 326,
              streak: 14,
              gift: won ? 'outfit.wristbands' : null,
              onDone: () {},
            ),
          ),
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('shows today’s workout and the gym streak', (tester) async {
    await _pump(tester, const GymPage(showScene: false), inventory: streaky);
    final today = todaysGymChallenge(_sets, DateTime.now());
    expect(find.text(today.kind.title(S.current)), findsWidgets);
    expect(find.textContaining(S.current.gymDoneToday), findsOneWidget);
    expect(find.text(S.current.statsDays(5)), findsOneWidget);
    expect(
      find.text('${S.current.statsBestStreak}: ${S.current.statsDays(9)}'),
      findsOneWidget,
    );
    expect(find.text(S.current.gymTrainAgain), findsOneWidget);
  });
}
