import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_loader.dart';
import 'package:pushup_bro/generated/l10n.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool reduceMotion = false,
    double? height,
  }) async {
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
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Material(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(height: height, child: const JungleLoader()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Carlos hops while the jungle loads', (tester) async {
    await pump(tester);
    expect(find.text('Heading into the jungle…'), findsOneWidget);

    final carlos = find.byType(Image).first;
    final before = tester.getTopLeft(carlos);
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getTopLeft(carlos).dy, lessThan(before.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stands still with Reduce Motion', (tester) async {
    await pump(tester, reduceMotion: true);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('Heading into the jungle…'), findsOneWidget);
  });

  testWidgets('fits a screen laid out short for a moment', (tester) async {
    // The height the jungle got on an iPhone before it filled the screen.
    await pump(tester, height: 154);
    expect(find.text('Heading into the jungle…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
