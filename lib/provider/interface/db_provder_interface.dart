import 'package:pushup_bro/features/pushups/model/pushup_set.dart';

abstract class DBProviderInterface {
  Future<List<PushupSet>> getAllPushupSets();
  Future<void> addNewPushupSet(PushupSet pushupSet);
  Future<void> deletePushupSet(int id);
}
