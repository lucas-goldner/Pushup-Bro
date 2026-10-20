import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';

class GameInventoryCubit extends Cubit<GameInventoryState> {
  GameInventoryCubit(this._dbProvider) : super(GameInventoryStateInitial());
  final DBProvider _dbProvider;

  Future<void> updateInventory(GameInventory inventory) async {
    emit(GameInventoryFetching());
    await _dbProvider.updateInventory(inventory);
    emit(GameInventoryLoaded(inventory));
  }

  Future<void> createInventory() async {
    emit(GameInventoryFetching());
    final inventory = await _dbProvider.createInventory();
    emit(GameInventoryLoaded(inventory));
  }

  Future<void> fetchInventory() async {
    emit(GameInventoryFetching());
    final inventory = await _dbProvider.getInventory();
    emit(GameInventoryLoaded(inventory));
  }
}
