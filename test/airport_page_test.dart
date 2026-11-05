import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/island/buildings/airport/departures_board.dart';
import 'package:pushup_bro/features/island/buildings/airport/drop_gift_sheet.dart';
import 'package:pushup_bro/features/island/buildings/airport/gift_opened_overlay.dart';
import 'package:pushup_bro/features/island/buildings/airport_page.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/demo_social_backend.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    SocialBackend? backend,
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    // A 320 pt phone.
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final account = AccountCubit(
      backend ?? demoSocialBackend(now: DateTime.now()),
      SharedPreferencesProvider(),
    );
    addTearDown(account.close);
    await tester.runAsync(account.start);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: account),
          BlocProvider(create: (_) => GameInventoryCubit(DBProvider())),
        ],
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
          home: screen,
        ),
      ),
    );
    // Let the friends, names and scores arrive, and the flaps settle.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(seconds: 2));
  }

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('the board fits a small phone in ${locale.languageCode}',
        (tester) async {
      for (final theme in [lightTheme, darkTheme]) {
        await pump(tester, const AirportPage(), locale: locale, theme: theme);
        expect(find.byType(FlightRow), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('no flights fit a small phone in ${locale.languageCode}',
        (tester) async {
      await pump(
        tester,
        const AirportPage(),
        backend: FakeSocialBackend(),
        locale: locale,
      );
      expect(find.text(S.current.airportEmptyTitle), findsOneWidget);
      expect(find.text(S.current.airportAddBro), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the gift sheet fits a small phone in ${locale.languageCode}',
        (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: DropGiftSheet(friend: 'mia', name: 'Mia'),
        ),
        locale: locale,
      );
      for (final gift in GiftKind.values) {
        expect(find.text(gift.emoji), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('an opened gift fits a small phone in ${locale.languageCode}',
        (tester) async {
      await pump(
        tester,
        GiftOpenedOverlay(
          drop: GiftDrop.create(
            gift: GiftKind.flowers,
            fromUid: 'mia',
            fromName: 'Mia',
            now: DateTime.now(),
          ),
        ),
        locale: locale,
      );
      expect(find.text(S.current.dropOpenBananas(5)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every bro is a flight, five in the demo', (tester) async {
    await pump(tester, const AirportPage());
    expect(find.byType(FlightRow), findsNWidgets(5));
    expect(find.text('Mia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('flight numbers stay the same for a bro', () {
    expect(flightNumber('mia'), flightNumber('mia'));
    expect(flightNumber('mia'), matches(RegExp(r'^PB[1-9][0-9]{2}$')));
    expect(gateFor(0), 'A1');
    expect(gateFor(4), 'B2');
  });
}
