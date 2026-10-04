import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:mmkv/mmkv.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/provider/interface/db_provder_interface.dart';

class DBProvider implements DBProviderInterface {
  static const _pushupSetsKey = 'pushup_sets';

  @visibleForTesting
  MMKV? mmkv;

  @override
  bool get initialized => mmkv != null;

  @override
  Future<void> loadDB() async {
    await MMKV.initialize();
    mmkv = MMKV.defaultMMKV();
  }

  @override
  Future<void> addNewPushupSet(PushupSet pushupSet) async {
    final current = await getAllPushupSets();
    final updated = [...current, pushupSet];
    mmkv?.encodeString(_pushupSetsKey, jsonEncode(updated));
  }

  @override
  Future<void> deletePushupSet(int id) async {
    final current = await getAllPushupSets();
    final filtered = current.where((set) => set.id != id).toList();
    mmkv?.encodeString(_pushupSetsKey, jsonEncode(filtered));
  }

  @override
  Future<List<PushupSet>> getAllPushupSets() async {
    final raw = mmkv?.decodeString(_pushupSetsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((e) => PushupSet.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
