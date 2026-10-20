import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_state.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';

class DBCubit extends Cubit<DBState> {
  DBCubit(this._dbProvider) : super(DBStateInitial());
  final DBProvider _dbProvider;

  Future<void> writeNewPushupsetToDB(PushupSet pushupSet) async {
    await _dbProvider.addNewPushupSet(pushupSet);
    await getAllPushupSets();
  }

  Future<void> deletePushupSetFromDB(int id) async {
    await _dbProvider.deletePushupSet(id);
    await getAllPushupSets();
  }

  Future<List<PushupSet>> getAllPushupSets() async {
    final pushupsets = await _dbProvider.getAllPushupSets();
    emit(state.copyWith(pushupSets: pushupsets));
    return pushupsets;
  }

  Future<void> getUser() async {
    final user = await _dbProvider.getUser();
    emit(state.copyWith(user: user));
  }

  Future<void> createUser({int xp = 0, int level = 1}) async {
    final user = await _dbProvider.createUser(xp: xp, level: level);
    emit(state.copyWith(user: user));
  }

  Future<void> updateUser({int xp = 0, int level = 1}) async {
    final userToUpdate = state.user.copyWith(xp: xp, level: level);
    await _dbProvider.updateUser(userToUpdate);
    emit(state.copyWith(user: userToUpdate));
  }

  Future<void> wipeUser() async {
    await _dbProvider.updateUser(User.empty());
    emit(state.copyWith(user: User.empty()));
  }
}
