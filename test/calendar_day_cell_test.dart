import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/ui/widgets/calendar/markers/pb_calendar_selected_marker.dart';
import 'package:pushup_bro/ui/widgets/calendar/markers/pb_calendar_today_marker.dart';

/// Regression tests for #22: the custom day-cell builders used
/// `DateFormat.d()`, which resolves against the ambient locale. Under `ja`
/// CLDR expands that to the pattern `d日`, so a selected day rendered as
/// `30日` and wrapped the cell onto two lines.
/// Width of the selected-day circle in [PBCalendarSelectedMarker]; the
/// tightest horizontal budget a day label has to live within.
const _dayCellWidth = 40.0;

void main() {
  setUpAll(initializeDateFormatting);

  tearDown(() => Intl.defaultLocale = null);

  Widget host(Widget child) => CupertinoApp(
        home: Center(
          child: SizedBox(width: 48, height: 48, child: child),
        ),
      );

  void expectBareDayOnOneLine(WidgetTester tester, int day) {
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, '$day', reason: 'day label must be the bare integer');
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);

    // Re-measure the *resolved* label with wrapping deliberately enabled, at
    // the width of the day cell. This asserts the content itself is narrow
    // enough to fit on one line, rather than relying on `softWrap: false` to
    // hide an overflow. `30日` needs two lines here; `30` does not.
    final paragraph = tester.renderObject<RenderParagraph>(find.byType(Text));
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: _dayCellWidth);
    expect(
      painter.computeLineMetrics().length,
      1,
      reason: 'day label must not wrap inside the cell',
    );
    painter.dispose();
  }

  for (final locale in ['en', 'ja', 'de']) {
    for (final day in [1, 9, 10, 30]) {
      testWidgets('selected day $day is numeric-only in $locale',
          (tester) async {
        Intl.defaultLocale = locale;
        await tester.pumpWidget(
          host(PBCalendarSelectedMarker(DateTime(2024, 1, day))),
        );
        expectBareDayOnOneLine(tester, day);
      });

      testWidgets('today marker day $day is numeric-only in $locale',
          (tester) async {
        Intl.defaultLocale = locale;
        await tester.pumpWidget(
          host(PBCalendarTodayMarker(DateTime(2024, 1, day))),
        );
        expectBareDayOnOneLine(tester, day);
      });
    }
  }

  test('DateFormat.d() under ja is why the cell wrapped', () {
    // Guards the root cause: if this ever stops being locale-dependent the
    // comments above can be revisited. `DateFormat('d')` is *not* a safe
    // alternative -- 'd' is a skeleton name and expands the same way.
    Intl.defaultLocale = 'ja';
    expect(DateFormat.d().format(DateTime(2024, 1, 30)), '30日');
    expect(DateFormat('d').format(DateTime(2024, 1, 30)), '30日');
    Intl.defaultLocale = 'en';
    expect(DateFormat.d().format(DateTime(2024, 1, 30)), '30');
  });
}
