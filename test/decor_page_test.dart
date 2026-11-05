import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/buildings/decor_page.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// The shop on a 320 pt phone, holding [inventory].
Future<GameInventoryCubit> _pump(
  WidgetTester tester,
  GameInventory inventory, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = const Size(320, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = GameInventoryCubit(DBProvider());
  // A fresh page for every pump.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: theme ?? lightTheme,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: locale,
        home: const DecorPage(preview: false),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The page loads the saved inventory first; then this one is "saved".
  await cubit.updateInventory(inventory);
  await tester.pumpAndSettle();

  return cubit;
}

GameInventory _inventory({int bananas = 400, List<DecorPiece>? decor}) =>
    GameInventory(
      bananas: bananas,
      boughtItems: const [ShopBuyables.accessories],
      monkeys: [AdoptableMonkey.carlos()],
      decor: decor ??
          const [
            DecorPiece(item: DecorItem.flamingo, z: 3.5, placed: true),
            DecorPiece(item: DecorItem.bonfire),
          ],
    );

void main() {
  for (final locale in S.delegate.supportedLocales) {
    testWidgets('fits a small phone in ${locale.languageCode}', (tester) async {
      for (final theme in [lightTheme, darkTheme]) {
        await _pump(tester, _inventory(), locale: locale, theme: theme);
        expect(tester.takeException(), isNull);
        // Just bought, with the place and buy-again buttons.
        await tester.tap(
          find.text(DecorItem.rubberDucky.label(S.current)).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(S.current.decorBuy(20)));
        await tester.pumpAndSettle();
        expect(find.text(S.current.decorPlace), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Too dear.
        final gorilla = find.text(DecorItem.goldGorilla.label(S.current));
        await tester.drag(find.byType(GridView), const Offset(0, -800));
        await tester.pumpAndSettle();
        await tester.tap(gorilla, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('buying stands the decoration on the island', (tester) async {
    final cubit = await _pump(tester, _inventory(bananas: 100, decor: []));
    expect(find.text(S.current.decorEditIsland), findsNothing);
    await tester.tap(find.text(S.current.decorBuy(20)));
    await tester.pumpAndSettle();
    final inventory = cubit.state.inventory;
    expect(inventory.bananas, 80);
    expect(inventory.decor.single.item, DecorItem.rubberDucky);
    expect(inventory.decor.single.placed, true);
    expect(find.text(S.current.decorBought), findsOneWidget);
    expect(find.text(S.current.decorOwned(1)), findsOneWidget);
    expect(find.text(S.current.decorEditIsland), findsOneWidget);
  });

  testWidgets('says how many bananas are missing', (tester) async {
    await _pump(tester, _inventory(bananas: 10));
    expect(find.text(S.current.shopNeedMore(10)), findsOneWidget);
  });
}
