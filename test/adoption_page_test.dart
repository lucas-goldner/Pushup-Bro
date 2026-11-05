import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/buildings/adoption_page.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// Holds an inventory without a database behind it.
class _Inventory extends GameInventoryCubit {
  _Inventory(GameInventory inventory) : super(DBProvider()) {
    emit(GameInventoryLoaded(inventory));
  }

  @override
  Future<void> updateInventory(GameInventory inventory) async =>
      emit(GameInventoryLoaded(inventory));
}

GameInventory _withAdopted(int count, {int bananas = 2000}) {
  var inventory = GameInventory.empty().copyWith(bananas: 100000);
  for (var i = 0; i < count; i++) {
    inventory = inventory.adopt(Adoption.candidates(i + 40).first)!;
  }
  return inventory.copyWith(bananas: bananas);
}

Future<_Inventory> _pump(
  WidgetTester tester,
  GameInventory inventory, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = const Size(320, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = _Inventory(inventory);
  await tester.pumpWidget(
    BlocProvider<GameInventoryCubit>.value(
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
        home: const AdoptionPage(effects: false),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

Future<void> _scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}

void main() {
  for (final locale in S.delegate.supportedLocales) {
    testWidgets('fits a small phone in ${locale.languageCode}', (tester) async {
      for (final inventory in [
        _withAdopted(0, bananas: 10),
        _withAdopted(2),
        _withAdopted(4),
      ]) {
        for (final theme in [lightTheme, darkTheme]) {
          await _pump(tester, inventory, locale: locale, theme: theme);
          expect(tester.takeException(), isNull);
          await _scrollThrough(tester);
        }
      }
    });
  }

  testWidgets('shows the next price and how many bananas are missing',
      (tester) async {
    await _pump(tester, _withAdopted(0, bananas: 500));
    // 1500 for the first, 500 already saved up.
    expect(find.textContaining('1000'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('1500'), 200);
    expect(find.text(S.current.adoptionFreeSpot), findsWidgets);
  });

  testWidgets('lists adopted monkeys and toggles the home gym', (tester) async {
    final cubit = await _pump(tester, _withAdopted(2));
    final second = cubit.state.inventory.monkeys[2];
    await tester.scrollUntilVisible(find.text(second.name), 200);
    expect(find.text(S.current.adoptionTrainWith('Carlos')), findsNWidgets(2));
    await tester.ensureVisible(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(cubit.state.inventory.monkeys[2].trainsInGym, isFalse);
    expect(cubit.state.inventory.gymMates, hasLength(1));
  });

  testWidgets('a full island has no adopt button', (tester) async {
    await _pump(tester, _withAdopted(4));
    expect(find.textContaining(S.current.adoptionFull), findsOneWidget);
    expect(find.text(S.current.adoptionFreeSpot), findsNothing);
  });

  testWidgets('reminds to keep a spot for King Komo', (tester) async {
    await _pump(tester, _withAdopted(3));
    await tester.scrollUntilVisible(
      find.textContaining(S.current.adoptionKomoSpot),
      200,
    );
    final withKomo = _withAdopted(2).copyWith(
      monkeys: [
        ..._withAdopted(2).monkeys,
        AdoptableMonkey(name: 'King Komo', look: MonkeyLook.kingKomo),
      ],
    );
    await _pump(tester, withKomo);
    expect(find.textContaining(S.current.adoptionKomoSpot), findsNothing);
  });

  testWidgets('adopting pays, moves the monkey in and celebrates',
      (tester) async {
    final cubit = await _pump(tester, _withAdopted(0));
    await tester.tap(find.byType(PillButton));
    await tester.pumpAndSettle();
    final inventory = cubit.state.inventory;
    expect(inventory.monkeys, hasLength(2));
    expect(inventory.bananas, 2000 - Adoption.prices.first);
    final name = inventory.monkeys[1].name;
    expect(find.text(S.current.adoptionWelcome(name)), findsOneWidget);
    expect(
      find.text(S.current.adoptionAdopt(name, Adoption.prices.first)),
      findsNothing,
    );
    await tester.tap(find.text(S.current.adoptionYay));
    await tester.pumpAndSettle();
    expect(find.text(S.current.adoptionWelcome(name)), findsNothing);
    // Its card is on the list, the next one costs more.
    await tester.scrollUntilVisible(find.text(name), 200);
    await tester.scrollUntilVisible(find.text('${Adoption.prices[1]}'), 200);
  });
}
