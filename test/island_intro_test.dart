import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/island/intro/intro_world.dart';
import 'package:pushup_bro/features/island/intro/island_intro.dart';
import 'package:pushup_bro/features/quest/widgets/dialog_box.dart';
import 'package:pushup_bro/generated/l10n.dart';

Future<void> _pumpIntro(
  WidgetTester tester,
  VoidCallback onDone, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => GameInventoryCubit(DBProvider()),
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
          locale: locale,
          home: IslandIntro(onDone: onDone, scene: false),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

/// Waits for the line to type out (and the storm's wind), then taps on.
Future<void> _nextLine(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.tap(find.byType(DialogBox));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  test('tells the story in order: village, storm, beach', () {
    final sets = introBeats.map((beat) => beat.set).toList();

    expect(sets.first, IntroSet.village);
    expect(sets.last, IntroSet.beach);
    // Each place comes once, in order, opened by a story card.
    final order = <IntroSet>[];
    for (final (i, beat) in introBeats.indexed) {
      if (order.isEmpty || order.last != beat.set) {
        order.add(beat.set);
        expect(beat.card, isNotNull, reason: 'beat $i opens ${beat.set}');
      }
    }
    expect(order, IntroSet.values);
    // Carlos gets up on the beach and never lies back down.
    final poses = [
      for (final beat in introBeats)
        if (beat.set == IntroSet.beach) beat.step,
    ];
    for (var i = 1; i < poses.length; i++) {
      expect(poses[i], greaterThanOrEqualTo(poses[i - 1]));
    }
    // The storm goes through every stage, in order: the strike, the run
    // for the huts, the tornado coming, grabbing him, spinning him up and
    // flinging him away.
    expect(
      [
        for (final beat in introBeats)
          if (beat.set == IntroSet.storm) beat.step,
      ],
      [0, 1, 2, 3, 4, 5],
    );
  });

  testWidgets('plays through every line and ends in white', (tester) async {
    var done = 0;
    await _pumpIntro(tester, () => done++);

    for (final beat in introBeats) {
      if (beat.card != null) {
        expect(find.text(beat.card!(S.current)), findsOneWidget);
        // Cards go on by themselves.
        await tester.pump(const Duration(seconds: 3));
        // Through black to the beach.
        await tester.pump(const Duration(milliseconds: 600));
        continue;
      }
      // The storm's first line waits for the wind.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(beat.line!.$2(S.current)), findsOneWidget);
      await _nextLine(tester);
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  testWidgets('skip leaves at once', (tester) async {
    var done = 0;
    await _pumpIntro(tester, () => done++);

    await tester.tap(find.text('Skip'));
    await tester.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('every line fits a small phone in ${locale.languageCode}',
        (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pumpIntro(tester, () {}, locale: locale);
      for (final beat in introBeats) {
        if (beat.card != null) {
          await tester.pump(const Duration(seconds: 3));
          await tester.pump(const Duration(milliseconds: 600));
        } else {
          await _nextLine(tester);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
