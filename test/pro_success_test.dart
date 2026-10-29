import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pro/success/pro_success_page.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store that sells every plan.
class _Store implements PurchasesService {
  @override
  bool get isAvailable => true;

  /// The planned prices, each with a store handle so it can be bought.
  @override
  Future<ProCatalog> load() async => (
        plans: [
          for (final plan in PreviewPurchasesService.plans)
            ProPlan(
              kind: plan.kind,
              price: plan.price,
              amount: plan.amount,
              pricePerWeek: plan.pricePerWeek,
              handle: plan.kind,
            ),
        ],
        isPro: false,
      );

  @override
  Future<bool?> purchase(ProPlan plan) async => true;

  @override
  Future<bool> restore() async => true;

  @override
  Future<bool> logIn(String uid) async => true;
}

void main() {
  late ProCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cubit = ProCubit(
      SharedPreferencesProvider(),
      purchases: _Store(),
      clock: () => DateTime(2026, 10, 28, 12),
    );
    await cubit.load();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<ProCubit>.value(
        value: cubit,
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
            locale: const Locale('en'),
            home: child,
          ),
        ),
      ),
    );
  }

  testWidgets('unlocks every feature and names the plan', (tester) async {
    await pump(tester, const ProSuccessPage(plan: ProPlanKind.yearly));
    await tester.pump(const Duration(seconds: 9));

    expect(find.text('Jungle Trek'), findsOneWidget);
    expect(find.text('Widgets & icons'), findsOneWidget);
    expect(
      find.text('Yearly plan active · Manage it any time in Settings'),
      findsOneWidget,
    );
    expect(find.text('Let’s go, Carlos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('says Pro is back after a restore', (tester) async {
    await pump(tester, const ProSuccessPage());
    await tester.pump(const Duration(seconds: 9));

    expect(find.text('Pro is back on this iPhone'), findsOneWidget);
  });

  testWidgets('a purchase from the paywall is celebrated, then it closes',
      (tester) async {
    bool? result;
    await pump(
      tester,
      Builder(
        builder: (context) => CupertinoButton(
          onPressed: () async => result = await showPaywall(context),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final cta = find.text('Keep everything after day 3');
    await tester.ensureVisible(cta);
    await tester.pump();
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 9));

    expect(find.byType(ProSuccessPage), findsOneWidget);
    expect(
      find.text('Yearly plan active · Manage it any time in Settings'),
      findsOneWidget,
    );

    await tester.tap(find.text('Let’s go, Carlos'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(ProSuccessPage), findsNothing);
    expect(result, isTrue);
  });
}
