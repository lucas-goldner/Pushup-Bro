import 'dart:ui' show DisplayFeatureType;

import 'package:duo_kit/testing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/core/widgets/fold_safe.dart';
import 'package:pushup_bro/core/widgets/phone_page.dart';
import 'package:pushup_bro/features/island/widgets/bros_bubble.dart';
import 'package:pushup_bro/features/island/widgets/bros_hub.dart';
import 'package:pushup_bro/features/island/widgets/island_dock.dart';
import 'package:pushup_bro/features/island/widgets/island_top_bar.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_answers.dart';
import 'package:pushup_bro/features/onboarding/model/onboarding_step.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/paywall/paywall_page.dart';
import 'package:pushup_bro/features/pro/success/pro_success_page.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/features/reminders/reminders_page.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/demo_social_backend.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'unit_test/features/reminders/fake_reminder_service.dart';

/// The iPhone Duo poses every screen must fit: the cover display and the
/// inner display, lying flat and half open.
const List<FoldTestPose> _poses = [
  FoldTestPose.duoCover,
  FoldTestPose.duoInnerLandscape,
  FoldTestPose.duoInnerPortrait,
  FoldTestPose.duoHalfOpenedLandscape,
];

void main() {
  late OnboardingCubit onboarding;
  late ProCubit pro;
  late AccountCubit account;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    onboarding = OnboardingCubit(SharedPreferencesProvider());
    await onboarding.load();
    await onboarding.answer(
      const OnboardingAnswers(
        goals: {OnboardingGoal.strength},
        frequency: WorkoutFrequency.sometimes,
        heightCm: 180,
        weightKg: 82,
        goalWeightKg: 76,
      ),
    );
    pro = ProCubit(
      SharedPreferencesProvider(),
      purchases: const PreviewPurchasesService(),
      clock: () => DateTime(2026, 10, 28, 12),
    );
    await pro.load();
    account = AccountCubit(
      demoSocialBackend(now: DateTime.now()),
      SharedPreferencesProvider(),
    );
  });

  tearDown(() => account.close());

  Future<void> pump(
    WidgetTester tester,
    FoldTestPose pose,
    Widget child, {
    Locale locale = const Locale('de'),
  }) async {
    final data = pose.data;
    tester.view
      ..physicalSize = data.size
      ..devicePixelRatio = 1
      ..padding = FakeViewPadding(
        left: data.padding.left,
        top: data.padding.top,
        right: data.padding.right,
        bottom: data.padding.bottom,
      )
      ..viewPadding = FakeViewPadding(
        left: data.viewPadding.left,
        top: data.viewPadding.top,
        right: data.viewPadding.right,
        bottom: data.viewPadding.bottom,
      )
      ..displayFeatures = data.displayFeatures;
    addTearDown(tester.view.reset);
    await tester.runAsync(account.start);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: onboarding),
          BlocProvider.value(value: pro),
          BlocProvider.value(value: account),
          BlocProvider(create: (_) => DBCubit(DBProvider())),
          BlocProvider(create: (_) => GameInventoryCubit(DBProvider())),
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
            home: Material(child: child),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 3));
  }

  final screens = <String, Widget Function()>{
    for (final step in OnboardingStep.values)
      if (step != OnboardingStep.firstSet)
        'onboarding ${step.name}': () => OnboardingPage(initialStep: step),
    'paywall': () => const PaywallPage(),
    'welcome to pro': () => const ProSuccessPage(plan: ProPlanKind.yearly),
    'reminders': () => const PhonePage(child: RemindersPage()),
    'bros hub': () => const BrosHub(),
    'bros hub, bros tab': () => const BrosHub(initialTab: 1),
    'island controls': () => const _IslandControls(),
  };

  for (final pose in _poses) {
    group('fits ${pose.name}', () {
      for (final MapEntry(key: name, value: screen) in screens.entries) {
        testWidgets(name, (tester) async {
          await pump(tester, pose, screen());
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  group('nothing to tap on the fold of an iPhone Duo open like a book', () {
    const pose = FoldTestPose.duoHalfOpenedLandscape;
    final fold = pose.data.displayFeatures
        .firstWhere((feature) => feature.type == DisplayFeatureType.fold)
        .bounds;
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets(name, (tester) async {
        await pump(tester, pose, screen());
        final taps = [
          ...find.byType(InkWell).evaluate(),
          ...find.byType(ButtonStyleButton).evaluate(),
          ...find.byType(CupertinoButton).evaluate(),
          ...find
              .byWidgetPredicate(
                (widget) => widget is GestureDetector && widget.onTap != null,
              )
              .evaluate(),
        ];
        for (final element in taps) {
          final box = element.renderObject;
          if (box is! RenderBox || !box.hasSize || !box.attached) continue;
          final rect = box.localToGlobal(Offset.zero) & box.size;
          if (rect.isEmpty) continue;
          expect(
            rect.overlaps(fold),
            isFalse,
            reason: '${element.widget.runtimeType} at $rect is on the fold',
          );
        }
      });
    }
  });

  testWidgets('the island bar stays off the fold of a half-open iPhone Duo',
      (tester) async {
    const pose = FoldTestPose.duoHalfOpenedLandscape;
    await pump(tester, pose, const _IslandControls());

    final fold = pose.data.displayFeatures
        .firstWhere((feature) => feature.type == DisplayFeatureType.fold)
        .bounds;
    final dock = tester.getRect(find.byType(IslandDock));
    expect(dock.overlaps(fold), isFalse);
    expect(dock.left, greaterThanOrEqualTo(fold.right));
  });
}

/// The island's controls as the island lays them out, without its scene.
class _IslandControls extends StatelessWidget {
  const _IslandControls();

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          FoldSafe(
            anchor: const Offset(double.maxFinite, 0),
            alignment: Alignment.topCenter,
            child: IslandTopBar(openQuest: (_) {}),
          ),
          FoldSafe(
            maxWidth: 560,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BrosBubble(onTap: () {}),
                      const SizedBox(height: 12),
                      IslandDock(
                        onShop: () {},
                        onCarlos: () {},
                        onJungle: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
