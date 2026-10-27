import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/app_config.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';

/// Whether the player has Pushup Bro Pro, is in their free days, and what
/// the store sells.
class ProState extends Equatable {
  const ProState({
    this.isPro = false,
    this.freeSince,
    this.plans = const [],
    this.storeAvailable = false,
    this.loaded = false,
    this.simulateLocked = false,
  });

  final bool isPro;

  /// When the three free days started (the first launch).
  final DateTime? freeSince;
  final List<ProPlan> plans;

  /// Whether the store can sell anything on this build. Without it nobody
  /// is locked out.
  final bool storeAvailable;
  final bool loaded;

  /// Debug only: act as if the free days were over and nothing was bought,
  /// even without a store, to try the paywall and the locks.
  final bool simulateLocked;

  DateTime? get freeUntil => freeSince?.add(AppConfig.freeDays);

  /// Whether the free days are still running at [now].
  bool inFreeDays(DateTime now) {
    final until = freeUntil;
    return until != null && now.isBefore(until);
  }

  /// What's left of the free days at [now] (zero once they're over).
  Duration freeLeft(DateTime now) {
    final until = freeUntil;
    if (until == null || !now.isBefore(until)) return Duration.zero;
    return until.difference(now);
  }

  /// Whether everything is open at [now]: Pro, the free days, or a store
  /// that can't sell anything.
  bool hasAccess(DateTime now) =>
      !simulateLocked &&
      (isPro || inFreeDays(now) || !storeAvailable || plans.isEmpty);

  ProPlan? plan(ProPlanKind kind) {
    for (final plan in plans) {
      if (plan.kind == kind) return plan;
    }
    return null;
  }

  ProState copyWith({
    bool? isPro,
    DateTime? freeSince,
    List<ProPlan>? plans,
    bool? storeAvailable,
    bool? loaded,
    bool? simulateLocked,
  }) =>
      ProState(
        isPro: isPro ?? this.isPro,
        freeSince: freeSince ?? this.freeSince,
        plans: plans ?? this.plans,
        storeAvailable: storeAvailable ?? this.storeAvailable,
        loaded: loaded ?? this.loaded,
        simulateLocked: simulateLocked ?? this.simulateLocked,
      );

  @override
  List<Object?> get props =>
      [isPro, freeSince, plans, storeAvailable, loaded, simulateLocked];
}
