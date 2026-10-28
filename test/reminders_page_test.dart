import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/features/reminders/reminders_page.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'unit_test/features/reminders/fake_reminder_service.dart';

void main() {
  late FakeReminderService service;
  late RemindersCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = FakeReminderService();
    final prefs = SharedPreferencesProvider();
    await prefs.loadSharedPrefs();
    cubit = RemindersCubit(prefs, service);
    await cubit.load();
  });

  Future<void> pump(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: Theme(
          data: theme,
          child: CupertinoApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: const Locale('en'),
            theme: MaterialBasedCupertinoThemeData(materialTheme: theme),
            builder: (context, child) => Theme(data: theme, child: child!),
            home: const RemindersPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (name, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
    testWidgets('shows the switch, the time and what is sent ($name)',
        (tester) async {
      await pump(tester, theme);

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Daily reminder'), findsOneWidget);
      expect(find.text('8:30 PM'), findsOneWidget);
      expect(find.text('What Pushup Bro sends'.toUpperCase()), findsOneWidget);
      expect(find.text('A comeback nudge after 3 quiet days'), findsOneWidget);
      expect(
        tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        isFalse,
      );
      expect(find.text('Notifications are off'), findsNothing);
    });
  }

  testWidgets('turning on asks for permission', (tester) async {
    await pump(tester, lightTheme);

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isTrue,
    );
  });

  testWidgets('explains how to allow notifications when denied',
      (tester) async {
    service.grant = false;
    await pump(tester, darkTheme);

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();

    expect(find.text('Notifications are off'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isFalse,
    );
  });

  testWidgets('picks a new time in a sheet', (tester) async {
    await pump(tester, lightTheme);

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);

    await tester.drag(
      find.byType(CupertinoDatePicker),
      const Offset(0, -64),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(cubit.state.settings.minutesOfDay, isNot(20 * 60 + 30));
  });
}
