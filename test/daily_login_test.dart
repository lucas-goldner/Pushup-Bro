import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/island/widgets/quests/daily_login.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the inventory in memory; MMKV needs its native library.
class _InventoryOnly extends DBProvider {
  GameInventory inventory = GameInventory.empty();

  @override
  bool get initialized => true;

  @override
  Future<void> loadDB() async {}

  @override
  Future<GameInventory> getInventory() async => inventory;

  @override
  Future<void> updateInventory(GameInventory inventory) async =>
      this.inventory = inventory;
}

void main() {
  late _InventoryOnly db;
  late int closed;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = _InventoryOnly();
    closed = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GameInventoryCubit(db),
        child: Theme(
          data: lightTheme,
          child: CupertinoApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: const Locale('en'),
            home: Material(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: DailyLogin(onClose: () => closed++)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('counts the bananas up to +10 as they land', (tester) async {
    await pump(tester);
    expect(find.text('+0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('+10'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('Claim 10 bananas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('claiming gives 10 bananas once and closes', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('Claim 10 bananas'));
    await tester.pump();
    await tester.tap(find.text('Claim 10 bananas'), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(db.inventory.bananas, 10);
    expect(closed, 1);
  });
}
