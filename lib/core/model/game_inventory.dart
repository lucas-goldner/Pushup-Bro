import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

class GameInventory extends Equatable {
  const GameInventory({
    required this.bananas,
    required this.boughtItems,
    required this.monkeys,
  });

  factory GameInventory.empty() => GameInventory(
        bananas: 0,
        boughtItems: const [],
        monkeys: [AdoptableMonkey.carlos()],
      );

  factory GameInventory.fromJson(Map<String, dynamic> json) {
    final buyables = ShopBuyables.values.asNameMap();
    final monkeys = json['monkeys'] as List<dynamic>?;

    return GameInventory(
      bananas: json['bananas'] as int? ?? 0,
      boughtItems: (json['boughtItems'] as List<dynamic>? ?? [])
          .map((e) => buyables[e])
          .whereType<ShopBuyables>()
          .toList(),
      monkeys: monkeys == null
          ? [AdoptableMonkey.carlos()]
          : monkeys
              .map((e) => AdoptableMonkey.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  final int bananas;
  final List<ShopBuyables> boughtItems;
  final List<AdoptableMonkey> monkeys;

  GameInventory copyWith({
    int? bananas,
    List<ShopBuyables>? boughtItems,
    List<AdoptableMonkey>? monkeys,
  }) =>
      GameInventory(
        bananas: bananas ?? this.bananas,
        boughtItems: boughtItems ?? this.boughtItems,
        monkeys: monkeys ?? this.monkeys,
      );

  Map<String, dynamic> toJson() => {
        'bananas': bananas,
        'boughtItems': boughtItems.map((item) => item.name).toList(),
        'monkeys': monkeys.map((monkey) => monkey.toJson()).toList(),
      };

  @override
  List<Object?> get props => [bananas, boughtItems, monkeys];
}
