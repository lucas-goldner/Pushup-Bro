import 'package:equatable/equatable.dart';

enum ProPlanKind { weekly, yearly, lifetime }

/// One Pushup Bro Pro plan as the store sells it, with its localized price.
class ProPlan extends Equatable {
  const ProPlan({
    required this.kind,
    required this.price,
    required this.amount,
    this.pricePerWeek,
    this.handle,
  });

  final ProPlanKind kind;

  /// The localized price, e.g. "$29.99".
  final String price;

  /// The price as a number, to work out savings.
  final double amount;

  /// The price per week, for the yearly plan (e.g. "$0.58").
  final String? pricePerWeek;

  /// The store's own object for buying this plan.
  final Object? handle;

  @override
  List<Object?> get props => [kind, price, amount, pricePerWeek];
}
