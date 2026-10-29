import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:pushup_bro/core/app_config.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';

/// What the store offers and what the player owns.
typedef ProCatalog = ({List<ProPlan> plans, bool isPro});

/// Sells Pushup Bro Pro.
abstract interface class PurchasesService {
  /// Whether purchases can be offered at all on this build and platform.
  bool get isAvailable;

  Future<ProCatalog> load();

  /// Buys [plan]. Returns whether the player has Pro afterwards, or null
  /// when they cancelled.
  Future<bool?> purchase(ProPlan plan);

  /// Returns whether the player has Pro after restoring.
  Future<bool> restore();

  /// Ties purchases to the player's account [uid], so Pro follows them to a
  /// new iPhone. Returns whether they have Pro.
  Future<bool> logIn(String uid);
}

class RevenueCatPurchasesService implements PurchasesService {
  Future<void>? _configuration;

  String get _apiKey => switch (defaultTargetPlatform) {
        TargetPlatform.iOS ||
        TargetPlatform.macOS =>
          AppConfig.revenueCatAppleApiKey,
        TargetPlatform.android => AppConfig.revenueCatGoogleApiKey,
        _ => '',
      };

  @override
  bool get isAvailable => !kIsWeb && _apiKey.isNotEmpty;

  Future<void> _ensureConfigured() =>
      _configuration ??= Purchases.configure(PurchasesConfiguration(_apiKey));

  bool _isPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(AppConfig.proEntitlement);

  ProPlan _plan(Package package, ProPlanKind kind) {
    final product = package.storeProduct;
    return ProPlan(
      kind: kind,
      price: product.priceString,
      amount: product.price,
      pricePerWeek:
          kind == ProPlanKind.yearly ? product.pricePerWeekString : null,
      handle: package,
    );
  }

  @override
  Future<ProCatalog> load() async {
    await _ensureConfigured();
    final offering =
        (await Purchases.getOfferings()).getOffering(AppConfig.proOffering);

    return (
      plans: [
        if (offering?.weekly case final weekly?)
          _plan(weekly, ProPlanKind.weekly),
        if (offering?.annual case final annual?)
          _plan(annual, ProPlanKind.yearly),
        if (offering?.lifetime case final lifetime?)
          _plan(lifetime, ProPlanKind.lifetime),
      ],
      isPro: _isPro(await Purchases.getCustomerInfo()),
    );
  }

  @override
  Future<bool?> purchase(ProPlan plan) async {
    await _ensureConfigured();
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(plan.handle! as Package),
      );
      return _isPro(result.customerInfo);
    } on PlatformException catch (error) {
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<bool> restore() async {
    await _ensureConfigured();
    return _isPro(await Purchases.restorePurchases());
  }

  @override
  Future<bool> logIn(String uid) async {
    await _ensureConfigured();
    final result = await Purchases.logIn(uid);
    return _isPro(result.customerInfo);
  }
}

/// A store that sells nothing (web, tests, builds without a key). Shows the
/// prices the plans are meant to have, so the paywall can still be seen.
class PreviewPurchasesService implements PurchasesService {
  const PreviewPurchasesService();

  static const plans = [
    ProPlan(kind: ProPlanKind.weekly, price: r'$4.99', amount: 4.99),
    ProPlan(
      kind: ProPlanKind.yearly,
      price: r'$29.99',
      amount: 29.99,
      pricePerWeek: r'$0.58',
    ),
    ProPlan(kind: ProPlanKind.lifetime, price: r'$69.99', amount: 69.99),
  ];

  @override
  bool get isAvailable => false;

  @override
  Future<ProCatalog> load() async => (plans: plans, isPro: false);

  @override
  Future<bool?> purchase(ProPlan plan) async => false;

  @override
  Future<bool> restore() async => false;

  @override
  Future<bool> logIn(String uid) async => false;
}
