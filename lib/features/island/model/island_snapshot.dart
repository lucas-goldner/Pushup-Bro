import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// What another player needs to draw someone's island: the buildings they
/// bought (the island grows with them) and Carlos's look. Saved on their
/// profile, so friends can visit.
class IslandSnapshot extends Equatable {
  const IslandSnapshot({
    this.bought = const [],
    this.look = const MonkeyLook(),
  });

  factory IslandSnapshot.of(GameInventory inventory) => IslandSnapshot(
        bought: inventory.boughtItems,
        look: inventory.monkeys.isEmpty
            ? const MonkeyLook()
            : inventory.monkeys.first.look,
      );

  factory IslandSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const IslandSnapshot();
    final buyables = ShopBuyables.values.asNameMap();
    return IslandSnapshot(
      bought: [
        for (final name in json['bought'] as List? ?? const [])
          if (buyables[name] case final item?) item,
      ],
      look: json['look'] is Map
          ? MonkeyLook.fromJson(Map<String, dynamic>.from(json['look'] as Map))
          : const MonkeyLook(),
    );
  }

  final List<ShopBuyables> bought;
  final MonkeyLook look;

  Map<String, dynamic> toJson() => {
        'bought': [for (final item in bought) item.name],
        'look': look.toJson(),
      };

  @override
  List<Object?> get props => [bought, look];
}
