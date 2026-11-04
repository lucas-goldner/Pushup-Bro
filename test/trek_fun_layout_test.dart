import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/demo_social_backend.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/boon.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/widgets/battle_hud.dart';
import 'package:pushup_bro/features/trek/widgets/rest_panel.dart';
import 'package:pushup_bro/features/trek/widgets/tower_panel.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AccountCubit account;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    account = AccountCubit(
      demoSocialBackend(now: DateTime.now()),
      SharedPreferencesProvider(),
    );
  });

  tearDown(() => account.close());

  // A 320 pt phone, the smallest the app supports.
  Future<void> pump(WidgetTester tester, Widget child, Locale locale) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: account),
          BlocProvider(create: (_) => GameInventoryCubit(DBProvider())),
        ],
        child: MaterialApp(
          theme: lightTheme,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: locale,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  for (final locale in S.delegate.supportedLocales) {
    final code = locale.languageCode;

    testWidgets('the rest with power-ups fits in $code', (tester) async {
      await pump(
        tester,
        RestPanel(
          secondsLeft: 12,
          hp: 60,
          maxHp: 100,
          nextWave: const [
            EnemySpec.shieldIguana(),
            EnemySpec.medic(),
            EnemySpec.chameleon(vanisher: true),
          ],
          onReady: () {},
          offer: const [Boon.comboKing, Boon.ironPlank, Boon.chain],
          picked: Boon.ironPlank,
          onPick: (_) {},
          onStop: () {},
        ),
        locale,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the tower panel fits in $code', (tester) async {
      await pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TowerPanel(
            trek: TrekProgress(
              towerBest: 128,
              stars: {TrekStage.all.last.id: 3},
            ),
            onClimb: () {},
          ),
        ),
        locale,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the battle warnings fit in $code', (tester) async {
      final foe = Foe(const EnemySpec.shieldIguana(), 0)..charging = 1.5;
      await pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const HeavyAlert(left: 1.5, total: 3.2, bracing: false),
              const HeavyAlert(left: 1.5, total: 3.2, bracing: true),
              FoeBar(foe: foe, targeted: true),
              WeaknessHint(foe: foe),
            ],
          ),
        ),
        locale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
