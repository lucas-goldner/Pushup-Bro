import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/pushup.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/home/finished_set_bottom_sheet.dart';

/// WCAG relative contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;

  return (lighter + 0.05) / (darker + 0.05);
}

Widget wrapInApp(Widget child) => CupertinoApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      // Mirrors the real app shell in lib/main.dart. The dark brightness here
      // is what makes `Theme.of` hand the sheet a dark Material theme.
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        textTheme: CupertinoTextThemeData(
          textStyle: PBTextStyles.defaultTextStyle,
        ),
      ),
      home: child,
    );

void main() {
  final pushupSet = PushupSet(
    [
      Pushup(completedAt: DateTime(2026, 10, 4, 12)),
      Pushup(completedAt: DateTime(2026, 10, 4, 12, 3)),
    ],
    0,
  );

  group('FinishedSetBottomSheet', () {
    testWidgets('paints its own surface instead of the derived dark canvas',
        (tester) async {
      await tester.pumpWidget(wrapInApp(FinishedSetBottomSheet(pushupSet)));

      final sheet = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FinishedSetBottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(sheet.color, PBColors.background);
      expect(
        sheet.color,
        isNot(Theme.of(tester.element(find.byType(Slider))).canvasColor),
      );
    });

    testWidgets('text inherits a foreground that contrasts with the surface',
        (tester) async {
      await tester.pumpWidget(wrapInApp(FinishedSetBottomSheet(pushupSet)));

      final sheet = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FinishedSetBottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );

      // Every label in the sheet resolves against the Material's textStyle,
      // including the ones whose PBTextStyles constant has no colour.
      final textStyle = DefaultTextStyle.of(
        tester.element(find.text('Congrats!')),
      ).style;

      expect(textStyle.color, PBTextStyles.defaultTextStyle.color);
      expect(contrastRatio(textStyle.color!, sheet.color!), greaterThan(4.5));
    });
  });
}
