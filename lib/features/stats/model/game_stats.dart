import 'package:flutter/foundation.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/level_scalings.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// A count out of everything there is to get.
typedef Collected = ({int have, int of});

/// The game side of the stats: the bro level, the island, the wardrobe,
/// the jungle quests and the Jungle Trek.
@immutable
class GameStats {
  const GameStats({
    required this.level,
    required this.levelProgress,
    required this.bananas,
    required this.buildings,
    required this.cosmetics,
    required this.monkeys,
    required this.quests,
    required this.questsTotal,
    required this.trekLevel,
    required this.trekStages,
    required this.trekStars,
    required this.power,
    required this.vitality,
    required this.grip,
    required this.agility,
  });

  /// [level] and [xp] are the bro level the finished-set sheet fills up.
  factory GameStats.from(
    GameInventory inventory, {
    required int level,
    required int xp,
  }) {
    final needed = LevelScaler().getLevelScaling(level);
    final trek = inventory.trek;
    final stages = TrekStage.all;

    return GameStats(
      level: level,
      levelProgress: needed <= 0 ? 1 : (xp / needed).clamp(0, 1).toDouble(),
      bananas: inventory.bananas,
      buildings: (
        have: ShopBuyables.buildingsShopBuyables
            .where(inventory.boughtItems.contains)
            .length,
        of: ShopBuyables.buildingsShopBuyables.length,
      ),
      cosmetics: (
        have: Cosmetic.all.where((c) => inventory.owns(c.id)).length,
        of: Cosmetic.all.length,
      ),
      monkeys: inventory.monkeys.length,
      quests: (
        have: JungleQuest.all
            .where((quest) => (inventory.quests.completed[quest.id] ?? 0) > 0)
            .length,
        of: JungleQuest.all.length,
      ),
      questsTotal: inventory.quests.total,
      trekLevel: trek.level,
      trekStages: (
        have: stages.where((stage) => trek.cleared(stage.id)).length,
        of: stages.length,
      ),
      trekStars: (
        have: stages.fold(0, (sum, stage) => sum + (trek.stars[stage.id] ?? 0)),
        of: stages.length * 3,
      ),
      power: trek.power,
      vitality: trek.vitality,
      grip: trek.grip,
      agility: trek.agility,
    );
  }

  final int level;

  /// How far into [level], 0 to 1.
  final double levelProgress;

  /// Bananas in the stash.
  final int bananas;

  /// Island buildings built.
  final Collected buildings;

  /// Wardrobe items owned, the defaults included.
  final Collected cosmetics;

  /// Monkeys living on the island.
  final int monkeys;

  /// Different jungle quests finished.
  final Collected quests;

  /// Jungle quests finished, counting repeats.
  final int questsTotal;
  final int trekLevel;
  final Collected trekStages;
  final Collected trekStars;
  final int power;
  final int vitality;
  final int grip;
  final int agility;
}
