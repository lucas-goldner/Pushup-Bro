import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_step.dart';
import 'package:pushup_bro/features/onboarding/onboarding_gate.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'unit_test/features/reminders/fake_reminder_service.dart';

void main() {
  late OnboardingCubit onboarding;
  late ProCubit pro;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    onboarding = OnboardingCubit(SharedPreferencesProvider());
    await onboarding.load();
    pro = ProCubit(
      SharedPreferencesProvider(),
      purchases: const PreviewPurchasesService(),
      clock: () => DateTime(2026, 10, 28, 12),
    );
    await pro.load();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: onboarding),
          BlocProvider.value(value: pro),
          BlocProvider(create: (_) => DBCubit(DBProvider())),
          BlocProvider(
            create: (_) => SharedPreferencesCubit(SharedPreferencesProvider()),
          ),
          BlocProvider(
            create: (_) => RemindersCubit(
              SharedPreferencesProvider(),
              FakeReminderService(),
            ),
          ),
          BlocProvider(
            create: (_) => AirPodsTrackerCubit(AirPodsMotionProvider()),
          ),
        ],
        child: Theme(
          data: dark ? darkTheme : lightTheme,
          child: CupertinoApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: locale,
            home: child,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets('a new player starts on the hook and moves on to the goal',
      (tester) async {
    await pump(tester, const OnboardingGate(child: Text('home')));

    expect(find.text('home'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Get properly strong'), findsOneWidget);
  });

  testWidgets('picking goals saves them right away', (tester) async {
    await pump(tester, const OnboardingPage(initialStep: OnboardingStep.goal));

    await tester.tap(find.text('Beat my pushup record'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(onboarding.state.answers.goals, {OnboardingGoal.record});
  });

  testWidgets('the goal weight is always framed as doable', (tester) async {
    await onboarding.answer(
      const OnboardingAnswers(weightKg: 82, goalWeightKg: 76),
    );
    await pump(
      tester,
      const OnboardingPage(initialStep: OnboardingStep.goalWeight),
    );

    expect(find.text('−6 kg. Totally doable.'), findsOneWidget);
    expect(find.text('About 3 months at a healthy pace.'), findsOneWidget);
  });

  testWidgets('the plan shows the goal weight and its calories',
      (tester) async {
    await onboarding.answer(
      const OnboardingAnswers(weightKg: 82, goalWeightKg: 76),
    );
    await pump(tester, const OnboardingPage(initialStep: OnboardingStep.plan));

    expect(find.text('76 kg goal'), findsOneWidget);
    expect(find.text('11 kcal a day from pushups'), findsOneWidget);
  });

  testWidgets('completing the onboarding opens the app', (tester) async {
    await pump(tester, const OnboardingGate(child: Text('home')));
    expect(find.text('home'), findsNothing);

    await onboarding.complete();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('home'), findsOneWidget);
  });

  group('every step fits on a phone', () {
    for (final locale in const [Locale('en'), Locale('de'), Locale('ja')]) {
      for (final step in OnboardingStep.values) {
        if (step == OnboardingStep.firstSet) continue;
        testWidgets('${step.name} in ${locale.languageCode}', (tester) async {
          await onboarding.answer(
            const OnboardingAnswers(
              goals: {OnboardingGoal.strength},
              frequency: WorkoutFrequency.sometimes,
              heightCm: 180,
              weightKg: 82,
              goalWeightKg: 76,
            ),
          );
          await pump(
            tester,
            OnboardingPage(initialStep: step),
            locale: locale,
            dark: locale.languageCode == 'ja',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
