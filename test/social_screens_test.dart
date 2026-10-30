import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/friends/friends.dart';
import 'package:pushup_bro/features/island/widgets/bros_bubble.dart';
import 'package:pushup_bro/features/island/widgets/bros_hub.dart';
import 'package:pushup_bro/features/leaderboard/leaderboard.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/demo_social_backend.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AccountCubit account;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    account = AccountCubit(
      demoSocialBackend(now: DateTime.now()),
      SharedPreferencesProvider(),
    );
  });

  tearDown(() => account.close());

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(account.start);
    await tester.pumpWidget(
      BlocProvider.value(
        value: account,
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
            home: Material(child: screen),
          ),
        ),
      ),
    );
    // Let the friends, names and scores arrive.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets("today's friends: the podium, the rest and the next win",
      (tester) async {
    await pump(tester, const Leaderboard());

    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Jonas'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('👑'), findsWidgets);
    expect(find.text('Not started today'), findsOneWidget);
    expect(find.text('36 more to pass Jonas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("today's everyone: the top and the player's own place",
      (tester) async {
    await pump(tester, const Leaderboard());
    await tester.tap(find.text('Everyone'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('🥇'), findsOneWidget);
    expect(find.textContaining('You · '), findsWidgets);
    expect(find.textContaining('#'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bros: the code card and every friend, done or nudge',
      (tester) async {
    await pump(tester, const Friends());

    expect(find.text('Your friend code'), findsOneWidget);
    expect(find.text('5 bros'), findsOneWidget);
    expect(find.text('✓ Done'), findsNWidgets(4));
    expect(find.text('👋 Nudge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the island's bubble: the place today and the next small win",
      (tester) async {
    var opened = false;
    await pump(
      tester,
      Align(
        alignment: Alignment.bottomRight,
        child: BrosBubble(onTap: () => opened = true),
      ),
    );

    expect(find.text('#3 today'), findsOneWidget);
    expect(find.text('36 to pass Jonas'), findsOneWidget);
    await tester.tap(find.byType(BrosBubble));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bros hub: today first, the bros one tap away',
      (tester) async {
    await pump(tester, const BrosHub());

    expect(find.text('36 more to pass Jonas.'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(SocialTabs),
        matching: find.text('Bros'),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Your friend code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
