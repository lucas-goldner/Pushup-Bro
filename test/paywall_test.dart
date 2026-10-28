import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/notices/free_days_sheets.dart';
import 'package:pushup_bro/features/pro/paywall/paywall_page.dart';
import 'package:pushup_bro/features/pro/paywall/widgets/paywall_plans.dart';
import 'package:pushup_bro/features/pro/widgets/pro_lock_sheet.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that sells the planned prices.
class _Store implements PurchasesService {
  @override
  bool get isAvailable => true;

  @override
  Future<ProCatalog> load() async =>
      (plans: PreviewPurchasesService.plans, isPro: false);

  @override
  Future<bool?> purchase(ProPlan plan) async => true;

  @override
  Future<bool> restore() async => false;
}

void main() {
  late ProCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cubit = ProCubit(
      SharedPreferencesProvider(),
      purchases: _Store(),
      clock: () => DateTime(2026, 10, 27, 12),
    );
    await cubit.load();
  });

  Widget wrapInApp(Widget child, {bool dark = false}) =>
      BlocProvider<ProCubit>.value(
        value: cubit,
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
            locale: const Locale('en'),
            home: child,
          ),
        ),
      );

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrapInApp(child, dark: dark));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpPaywall(WidgetTester tester, {bool dark = false}) async {
    await pumpScreen(tester, const PaywallPage(), dark: dark);
    // The stage loops forever, so pump a while instead of settling.
  }

  PlanCard card(WidgetTester tester, ProPlanKind kind) =>
      tester.widgetList<PlanCard>(find.byType(PlanCard)).firstWhere(
            (card) => card.plan.kind == kind,
          );

  group('PaywallPage', () {
    testWidgets('shows the three plans with the yearly one picked',
        (tester) async {
      await pumpPaywall(tester);

      expect(find.byType(PlanCard), findsNWidgets(3));
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);
      expect(card(tester, ProPlanKind.yearly).selected, isTrue);
      expect(card(tester, ProPlanKind.weekly).selected, isFalse);
      expect(card(tester, ProPlanKind.lifetime).selected, isFalse);
      expect(find.text('Save 88%'), findsOneWidget);
      expect(find.text(r'$29.99 a year'), findsOneWidget);
      expect(find.text('Keep everything after day 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('picking a plan moves the ring and the terms', (tester) async {
      await pumpPaywall(tester);

      await tester.ensureVisible(find.text('Lifetime'));
      await tester.tap(find.text('Lifetime'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(card(tester, ProPlanKind.lifetime).selected, isTrue);
      expect(card(tester, ProPlanKind.yearly).selected, isFalse);
      expect(
        find.text('A one-time purchase. No subscription, nothing renews.'),
        findsOneWidget,
      );
    });

    testWidgets('says the free days are over once they are', (tester) async {
      cubit.simulateLocked(locked: true);
      await pumpPaywall(tester);

      expect(find.text('Free days are over'), findsOneWidget);
      expect(find.text('Unlock everything'), findsOneWidget);
    });
  });

  testWidgets('plays every scene of the stage in dark mode', (tester) async {
    await pumpPaywall(tester, dark: true);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 2900));
    }

    expect(tester.takeException(), isNull);
  });

  group('sheets', () {
    testWidgets('the lock sheet names the place and the yearly plan',
        (tester) async {
      await pumpScreen(
        tester,
        const ProLockSheet(place: ProLockPlace.jungle),
      );

      expect(find.text('The jungle is a Pro place'), findsOneWidget);
      expect(find.text(r'Yearly · $29.99'), findsOneWidget);
      expect(find.text('See all plans'), findsOneWidget);
    });

    testWidgets('the welcome sheet counts three days', (tester) async {
      await pumpScreen(
        tester,
        FreeDaysWelcomeSheet(
          freeSince: DateTime(2026, 10, 27, 9),
          now: DateTime(2026, 10, 27, 12),
        ),
        dark: true,
      );

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the last-day sheet shows the hours left', (tester) async {
      await pumpScreen(
        tester,
        const LastFreeDaySheet(left: Duration(hours: 8, minutes: 10)),
      );

      expect(find.text('Last free day'), findsOneWidget);
      expect(find.textContaining('In 9 h'), findsOneWidget);
    });
  });
}
