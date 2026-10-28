import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';

/// Pushup Bro Pro: three free days from the first launch, then the gym
/// stays free and everything else needs a plan.
class ProCubit extends Cubit<ProState> {
  ProCubit(
    this._prefs, {
    PurchasesService? purchases,
    DateTime Function()? clock,
  })  : _purchases = purchases ?? RevenueCatPurchasesService(),
        _clock = clock ?? DateTime.now,
        super(const ProState());

  final SharedPreferencesProvider _prefs;
  final PurchasesService _purchases;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  /// The plan bought last in this session, for the welcome screen; null
  /// after a restore.
  ProPlanKind? lastPurchase;

  /// Whether everything is open right now.
  bool get hasAccess => state.hasAccess(now);

  /// Starts the free days on the first launch and asks the store what the
  /// player owns.
  Future<void> load() async {
    final saved = await _prefs.getSharedPrefString(
      SharedPreferencesKey.proFreeSince,
    );
    var freeSince = DateTime.tryParse(saved ?? '');
    if (freeSince == null) {
      freeSince = now;
      await _prefs.writeStringToSharedPrefs(
        SharedPreferencesKey.proFreeSince,
        freeSince.toIso8601String(),
      );
    }
    emit(state.copyWith(freeSince: freeSince));

    final store =
        _purchases.isAvailable ? _purchases : const PreviewPurchasesService();
    try {
      final catalog = await store.load();
      emit(
        state.copyWith(
          plans: catalog.plans,
          isPro: catalog.isPro,
          storeAvailable: _purchases.isAvailable,
          loaded: true,
        ),
      );
    } on Object catch (error) {
      // An unreachable store never locks anyone out.
      debugPrint('Store unavailable: $error');
      emit(state.copyWith(storeAvailable: false, loaded: true));
    }
  }

  /// Buys [plan]; returns whether the player has Pro now, or null when
  /// they cancelled.
  Future<bool?> purchase(ProPlan plan) async {
    final pro = await _purchases.purchase(plan);
    if (pro ?? false) {
      lastPurchase = plan.kind;
      emit(state.copyWith(isPro: true));
    }
    return pro;
  }

  /// Debug only: lock everything as if the free days were over.
  void simulateLocked({required bool locked}) =>
      emit(state.copyWith(simulateLocked: locked));

  Future<bool> restore() async {
    final pro = await _purchases.restore();
    if (pro) {
      lastPurchase = null;
      emit(state.copyWith(isPro: true));
    }
    return pro;
  }
}
