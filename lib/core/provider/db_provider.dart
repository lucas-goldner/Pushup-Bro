import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/platform/key_value_store.dart';
import 'package:pushup_bro/core/provider/db_provder_interface.dart';

class DBProvider implements DBProviderInterface {
  static const _pushupSetsKey = 'pushup_sets';
  static const _userKey = 'user';
  static const _gameInventoryKey = 'game_inventory';

  @visibleForTesting
  KeyValueStore? store;

  @override
  bool get initialized => store != null;

  @override
  Future<void> loadDB() async {
    if (initialized) return;
    final keyValueStore = KeyValueStore();
    await keyValueStore.initialize();
    store = keyValueStore;
  }

  Map<String, dynamic>? _decodeObject(String key) {
    final raw = store?.decodeString(key);
    if (raw == null || raw.isEmpty) return null;

    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<User> getUser() async {
    final json = _decodeObject(_userKey);

    return json == null ? User.empty() : User.fromJson(json);
  }

  @override
  Future<User> createUser({int xp = 0, int level = 1}) async {
    final user = User(
      xp: xp,
      level: level,
      name: '',
      image: '',
      friends: [],
      streak: 1,
      longestStreak: 1,
    );
    await updateUser(user);

    return user;
  }

  @override
  Future<void> updateUser(User user) async {
    store?.encodeString(_userKey, jsonEncode(user));
  }

  @override
  Future<GameInventory> getInventory() async {
    final json = _decodeObject(_gameInventoryKey);

    return json == null ? GameInventory.empty() : GameInventory.fromJson(json);
  }

  /// Seeds an empty inventory unless one is stored already, so bananas
  /// earned before the first island visit are kept.
  @override
  Future<GameInventory> createInventory() async {
    final stored = _decodeObject(_gameInventoryKey);
    if (stored != null) return GameInventory.fromJson(stored);

    final inventory = GameInventory.empty();
    await updateInventory(inventory);

    return inventory;
  }

  @override
  Future<void> updateInventory(GameInventory inventory) async {
    store?.encodeString(_gameInventoryKey, jsonEncode(inventory));
  }

  @override
  Future<void> addNewPushupSet(PushupSet pushupSet) async {
    final current = await getAllPushupSets();
    final updated = [...current, pushupSet];
    store?.encodeString(_pushupSetsKey, jsonEncode(updated));
  }

  @override
  Future<void> deletePushupSet(int id) async {
    final current = await getAllPushupSets();
    final filtered = current.where((set) => set.id != id).toList();
    store?.encodeString(_pushupSetsKey, jsonEncode(filtered));
  }

  @override
  Future<List<PushupSet>> getAllPushupSets() async {
    final raw = store?.decodeString(_pushupSetsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((e) => PushupSet.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
