import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_loader.dart';
import 'package:pushup_bro/generated/l10n.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) async {
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
            child: const Material(child: JungleLoader()),
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
}
