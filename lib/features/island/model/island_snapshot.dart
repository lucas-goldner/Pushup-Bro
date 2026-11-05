import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// What another player needs to draw someone's island: the buildings they
/// bought (the island grows with them), Carlos's look and the looks of the
/// monkeys living with him. Saved on their profile, so friends can visit.
class IslandSnapshot extends Equatable {
  const IslandSnapshot({
    this.bought = const [],
    this.look = const MonkeyLook(),
    this.friends = const [],
  });

  factory IslandSnapshot.of(GameInventory inventory) => IslandSnapshot(
        bought: inventory.boughtItems,
        look: inventory.monkeys.isEmpty
            ? const MonkeyLook()
            : inventory.monkeys.first.look,
        friends: inventory.islandFriends,
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
      friends: [
        for (final look in json['friends'] as List? ?? const [])
          if (look is Map) MonkeyLook.fromJson(Map<String, dynamic>.from(look)),
      ].take(Adoption.maxExtras).toList(),
    );
  }

  final List<ShopBuyables> bought;
  final MonkeyLook look;

  /// The other monkeys on the island (see `IslandFriends`).
  final List<MonkeyLook> friends;

  Map<String, dynamic> toJson() => {
        'bought': [for (final item in bought) item.name],
        'look': look.toJson(),
        'friends': [for (final friend in friends) friend.toJson()],
      };

  @override
  List<Object?> get props => [bought, look, friends];
}
