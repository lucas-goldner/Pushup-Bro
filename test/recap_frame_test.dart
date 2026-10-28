import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/share/model/flex_stat.dart';
import 'package:pushup_bro/features/share/model/recap.dart';
import 'package:pushup_bro/features/share/recap_share_page.dart';
import 'package:pushup_bro/features/share/widgets/recap_frame.dart';
import 'package:pushup_bro/generated/l10n.dart';

const _workout = Recap(
  kind: RecapKind.workout,
  pushups: 125,
  vsLast: 10,
  minutes: 9,
  kcal: 46,
  flex: [
    FlexStat(FlexKind.moreThanLast, 10),
    FlexStat(FlexKind.kcal, 46),
    FlexStat(FlexKind.inARow, 32, best: true),
    FlexStat(FlexKind.streak, 12),
  ],
);

const _trek = Recap(
  kind: RecapKind.trek,
  title: 'Fern Trail',
  pushups: 30,
  stars: 3,
  flex: [
    FlexStat(FlexKind.damage, 412),
    FlexStat(FlexKind.combo, 7, best: true),
    FlexStat(FlexKind.pushups, 30),
    FlexStat(FlexKind.kcal, 11),
  ],
);

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Theme(
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
          home: child,
        ),
      ),
    );
  }

  for (final recap in [_workout, _trek]) {
    for (final seconds in [0.0, 1.5, 2.6, 5.5, 8.5, kRecapSeconds]) {
      testWidgets('${recap.kind.name} frame at ${seconds}s', (tester) async {
        await pump(
          tester,
          Center(child: RecapFrame(recap: recap, seconds: seconds)),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the workout frame shows the gain and the flex wall',
      (tester) async {
    await pump(
      tester,
      const Center(child: RecapFrame(recap: _workout, seconds: 2.6)),
    );
    expect(find.text('+10 vs last time'), findsOneWidget);

    await pump(
      tester,
      const Center(child: RecapFrame(recap: _workout, seconds: 6)),
    );
    expect(find.text('You crushed it'), findsOneWidget);
    expect(find.text('more than last time'), findsOneWidget);
    expect(find.text('in a row · new best'), findsOneWidget);
  });

  testWidgets('the share page previews the video with a Share button',
      (tester) async {
    await pump(tester, const RecapSharePage(recap: _workout));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RecapFrame), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
