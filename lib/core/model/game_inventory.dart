import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

class GameInventory extends Equatable {
  const GameInventory({
    required this.bananas,
    required this.boughtItems,
    required this.monkeys,
    this.ownedCosmetics = const [],
    this.quests = const QuestLog(),
    this.trek = const TrekProgress(),
  });

  factory GameInventory.empty() => GameInventory(
        bananas: 0,
        boughtItems: const [],
        monkeys: [AdoptableMonkey.carlos()],
      );

  factory GameInventory.fromJson(Map<String, dynamic> json) {
    final buyables = ShopBuyables.values.asNameMap();
    final monkeys = json['monkeys'] as List<dynamic>?;
    final boughtItems = (json['boughtItems'] as List<dynamic>? ?? [])
        .map((e) => buyables[e])
        .whereType<ShopBuyables>()
        .toList();
    final quests = json['quests'];
    final trek = json['trek'];

    return GameInventory(
      bananas: json['bananas'] as int? ?? 0,
      boughtItems: boughtItems,
      monkeys: monkeys == null
          ? [AdoptableMonkey.carlos()]
          : monkeys
              .map((e) => AdoptableMonkey.fromJson(e as Map<String, dynamic>))
              .toList(),
      ownedCosmetics: {
        ...(json['ownedCosmetics'] as List<dynamic>? ?? []).whereType<String>(),
        // Bought before the wardrobe existed.
        if (boughtItems.contains(ShopBuyables.accessoryPartyHat)) 'hat.party',
      }.toList(),
      quests: quests is Map<String, dynamic>
          ? QuestLog.fromJson(quests)
          : const QuestLog(),
      trek: trek is Map<String, dynamic>
          ? TrekProgress.fromJson(trek)
          : const TrekProgress(),
    );
  }

  final int bananas;
  final List<ShopBuyables> boughtItems;
  final List<AdoptableMonkey> monkeys;

  /// Cosmetic ids bought in the wardrobe; the defaults are always owned.
  final List<String> ownedCosmetics;

  /// Progress through the jungle's daily quests.
  final QuestLog quests;

  /// Progress through the Jungle Trek.
  final TrekProgress trek;

  bool owns(String cosmeticId) =>
      MonkeyLook.defaults.contains(cosmeticId) ||
      ownedCosmetics.contains(cosmeticId);

  GameInventory copyWith({
    int? bananas,
    List<ShopBuyables>? boughtItems,
    List<AdoptableMonkey>? monkeys,
    List<String>? ownedCosmetics,
    QuestLog? quests,
    TrekProgress? trek,
  }) =>
      GameInventory(
        bananas: bananas ?? this.bananas,
        boughtItems: boughtItems ?? this.boughtItems,
        monkeys: monkeys ?? this.monkeys,
        ownedCosmetics: ownedCosmetics ?? this.ownedCosmetics,
        quests: quests ?? this.quests,
        trek: trek ?? this.trek,
      );

  Map<String, dynamic> toJson() => {
        'bananas': bananas,
        'boughtItems': boughtItems.map((item) => item.name).toList(),
        'monkeys': monkeys.map((monkey) => monkey.toJson()).toList(),
        'ownedCosmetics': ownedCosmetics,
        'quests': quests.toJson(),
        'trek': trek.toJson(),
      };

  @override
  List<Object?> get props =>
      [bananas, boughtItems, monkeys, ownedCosmetics, quests, trek];
}
