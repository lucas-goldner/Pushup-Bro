import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/notices/free_days_notices.dart';
import 'package:pushup_bro/features/pro/paywall/widgets/paywall_plans.dart';
import 'package:pushup_bro/features/pro/widgets/free_days_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store implements PurchasesService {
  bool pro = false;

  @override
  bool get isAvailable => true;

  @override
  Future<ProCatalog> load() async =>
      (plans: PreviewPurchasesService.plans, isPro: pro);

  @override
  Future<bool?> purchase(ProPlan plan) async => pro = true;

  @override
  Future<bool> restore() async => pro;

  @override
  Future<bool> logIn(String uid) async => pro;
}

void main() {
  final start = DateTime(2026, 10, 1, 9);
  final selling = ProState(
    freeSince: start,
    plans: PreviewPurchasesService.plans,
    storeAvailable: true,
    loaded: true,
  );

  group('ProState free days', () {
    test('run for three days from the first launch', () {
      expect(selling.freeUntil, DateTime(2026, 10, 4, 9));
      expect(selling.inFreeDays(start), isTrue);
      expect(selling.inFreeDays(DateTime(2026, 10, 4, 8, 59)), isTrue);
      expect(selling.inFreeDays(DateTime(2026, 10, 4, 9)), isFalse);
    });

    test('count down what is left, then stay at zero', () {
      expect(
        selling.freeLeft(DateTime(2026, 10, 3, 9)),
        const Duration(days: 1),
      );
      expect(selling.freeLeft(DateTime(2026, 10, 9)), Duration.zero);
      expect(const ProState().freeLeft(start), Duration.zero);
    });
  });

  group('ProState access', () {
    final over = DateTime(2026, 10, 5);

    test('is open during the free days and closed after', () {
      expect(selling.hasAccess(start), isTrue);
      expect(selling.hasAccess(over), isFalse);
    });

    test('stays open with Pro', () {
      expect(selling.copyWith(isPro: true).hasAccess(over), isTrue);
    });

    test('never locks anyone out without a store or plans', () {
      expect(selling.copyWith(storeAvailable: false).hasAccess(over), isTrue);
      expect(selling.copyWith(plans: []).hasAccess(over), isTrue);
    });

    test('simulateLocked closes everything, even with Pro or no store', () {
      final locked = selling.copyWith(simulateLocked: true);
      expect(locked.hasAccess(start), isFalse);
      expect(locked.copyWith(isPro: true).hasAccess(start), isFalse);
      expect(locked.copyWith(storeAvailable: false).hasAccess(over), isFalse);
    });

    test('free days only show while they matter', () {
      expect(selling.showsFreeDays(start), isTrue);
      expect(selling.showsFreeDays(over), isFalse);
      expect(selling.copyWith(isPro: true).showsFreeDays(start), isFalse);
      expect(
        selling.copyWith(storeAvailable: false).showsFreeDays(start),
        isFalse,
      );
    });
  });

  group('ProCubit', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts the free days on the first launch and keeps them', () async {
      var now = start;
      final prefs = SharedPreferencesProvider();
      final cubit = ProCubit(prefs, purchases: _Store(), clock: () => now);
      await cubit.load();
      expect(cubit.state.freeSince, start);
      expect(cubit.hasAccess, isTrue);

      now = DateTime(2026, 10, 8);
      final later = ProCubit(prefs, purchases: _Store(), clock: () => now);
      await later.load();
      expect(later.state.freeSince, start);
      expect(later.hasAccess, isFalse);
      expect(
        await prefs.getSharedPrefString(SharedPreferencesKey.proFreeSince),
        start.toIso8601String(),
      );
    });

    test('simulateLocked locks and unlocks', () async {
      final cubit = ProCubit(
        SharedPreferencesProvider(),
        purchases: _Store(),
        clock: () => start,
      );
      await cubit.load();
      cubit.simulateLocked(locked: true);
      expect(cubit.hasAccess, isFalse);
      cubit.simulateLocked(locked: false);
      expect(cubit.hasAccess, isTrue);
    });

    test('a purchase opens everything', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesKey.proFreeSince.name: start.toIso8601String(),
      });
      final cubit = ProCubit(
        SharedPreferencesProvider(),
        purchases: _Store(),
        clock: () => DateTime(2026, 11),
      );
      await cubit.load();
      expect(cubit.hasAccess, isFalse);
      expect(await cubit.purchase(PreviewPurchasesService.plans[1]), isTrue);
      expect(cubit.hasAccess, isTrue);
    });
  });

  group('free days notices', () {
    test('welcome first, once', () {
      expect(
        dueFreeDaysNotice(
          left: const Duration(days: 3),
          welcomeSeen: false,
          lastDaySeen: false,
        ),
        FreeDaysNotice.welcome,
      );
      expect(
        dueFreeDaysNotice(
          left: const Duration(days: 2),
          welcomeSeen: true,
          lastDaySeen: false,
        ),
        isNull,
      );
    });

    test('the last day once, under 24 hours', () {
      expect(
        dueFreeDaysNotice(
          left: const Duration(hours: 9),
          welcomeSeen: true,
          lastDaySeen: false,
        ),
        FreeDaysNotice.lastDay,
      );
      expect(
        dueFreeDaysNotice(
          left: const Duration(hours: 9),
          welcomeSeen: true,
          lastDaySeen: true,
        ),
        isNull,
      );
      expect(
        dueFreeDaysNotice(
          left: Duration.zero,
          welcomeSeen: false,
          lastDaySeen: false,
        ),
        isNull,
      );
    });
  });

  test('yearly saves against 52 weeks', () {
    expect(yearlySavings(PreviewPurchasesService.plans), 88);
    expect(yearlySavings(PreviewPurchasesService.plans.sublist(1)), isNull);
  });
}
