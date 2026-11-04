import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';

/// The two fresh starts in Settings.
///
/// - [resetIsland]: the island and the story start over (buildings,
///   bananas, monkeys, wardrobe, daily quests, the Jungle Trek's levels and
///   stages, and the intro film). Pushups, stats and the bro level stay.
/// - [resetAll]: that, plus every pushup set and the bro level, like a
///   fresh install.
///
/// Settings, Pro, the account, the onboarding and reminders always stay.
/// A cloud backup catches up by itself: the next save sends the fresh
/// state.
class ProgressReset {
  ProgressReset({
    required this.dbCubit,
    required this.inventory,
    required this.prefsCubit,
  });

  final DBCubit dbCubit;
  final GameInventoryCubit inventory;
  final SharedPreferencesCubit prefsCubit;

  /// Island and story state kept outside the inventory.
  static const List<SharedPreferencesKey> _islandPrefs = [
    SharedPreferencesKey.trekBestCombo,
    SharedPreferencesKey.dailyBananasClaimedOn,
  ];

  Future<void> resetIsland() async {
    await inventory.updateInventory(GameInventory.empty());
    for (final key in _islandPrefs) {
      await prefsCubit.remove(key);
    }
    // The intro film plays again on the next visit.
    await prefsCubit.setFirstTimeIslandVisited(isFirstVisit: true);
    await inventory.fetchInventory();
  }

  Future<void> resetAll() async {
    await resetIsland();
    await dbCubit.clearPushupSets();
    await dbCubit.wipeUser();
    await prefsCubit.setFirstPushupCompleted(completed: false);
  }
}
