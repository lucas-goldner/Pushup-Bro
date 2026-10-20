import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/user.dart';

abstract class DBProviderInterface {
  bool get initialized;
  Future<void> loadDB();
  Future<List<PushupSet>> getAllPushupSets();
  Future<void> addNewPushupSet(PushupSet pushupSet);
  Future<void> deletePushupSet(int id);
  Future<User> createUser({int xp = 0, int level = 1});
  Future<void> updateUser(User user);
  Future<User> getUser();
  Future<GameInventory> getInventory();
  Future<GameInventory> createInventory();
  Future<void> updateInventory(GameInventory inventory);
}
