import 'package:flutter/cupertino.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/provider/interface/db_provder_interface.dart';

class DBProvider implements DBProviderInterface {
  @visibleForTesting
  Isar? db;

  @override
  bool get initialized => db != null;

  @override
  Future<void> loadDB() async {
    final dir = await getApplicationSupportDirectory();
    db ??= await Isar.open([PushupSetSchema], directory: dir.path);
  }

  @override
  Future<void> addNewPushupSet(PushupSet pushupSet) async {
    await db?.writeTxn(() async {
      await db?.pushupSets.put(pushupSet);
    });
  }

  @override
  Future<void> deletePushupSet(int id) async {
    await db?.writeTxn(() async {
      await db?.pushupSets.delete(id);
    });
  }

  @override
  Future<List<PushupSet>> getAllPushupSets() async =>
      await db?.pushupSets.where(distinct: true).findAll() ?? [];
}
