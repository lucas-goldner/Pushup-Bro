import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/features/settings/view/settings_tracking.dart';
import 'package:pushup_bro/features/settings/view/settings_volume.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesCubit> _pump(
  WidgetTester tester,
  Widget page, {
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  final provider = SharedPreferencesProvider();
  await tester.runAsync(provider.loadSharedPrefs);
  final prefs = SharedPreferencesCubit(provider);
  await tester.runAsync(prefs.loadWorkoutSettings);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: prefs),
        BlocProvider(
          create: (_) => AirPodsTrackerCubit(AirPodsMotionProvider()),
        ),
      ],
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
          home: Material(child: page),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets('music and sound effects each have a switch and a slider',
      (tester) async {
    final prefs = await _pump(tester, const VolumeSetting());

    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.byType(Slider), findsNWidgets(2));
    expect(prefs.state.musicOn, isTrue);

    await tester.runAsync(() async {
      await tester.tap(find.byType(Switch).first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(prefs.state.musicOn, isFalse);
    // A switched off volume reads "Off" and can't be dragged.
    expect(find.text('Off'), findsOneWidget);
    expect(
      tester.widget<Slider>(find.byType(Slider).first).onChanged,
      isNull,
    );
  });

  testWidgets(
      'the camera view and the AirPods sensitivity can be changed '
      'and reset', (tester) async {
    final prefs = await _pump(tester, const TrackingSettingsPage());

    expect(prefs.state.cameraView, CameraView.person);
    await tester.runAsync(() async {
      await tester.tap(find.text('Skeleton only'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(prefs.state.cameraView, CameraView.skeleton);

    await tester.runAsync(() async {
      await prefs.setAirpodsSensitivity(9);
    });
    await tester.pumpAndSettle();
    expect(find.text('Level 9'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Reset to default'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(prefs.state.airpodsSensitivity, AirPodsSensitivity.standard);
    expect(find.text('Level 5 · standard'), findsOneWidget);
  });

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('both pages fit a small phone in ${locale.languageCode}',
        (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final page in const [VolumeSetting(), TrackingSettingsPage()]) {
        await _pump(tester, page, locale: locale);
        for (var i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
