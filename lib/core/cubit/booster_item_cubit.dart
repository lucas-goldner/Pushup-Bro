import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/booster_item_state.dart';
import 'package:pushup_bro/core/model/booster_items.dart';

class BoosterItemCubit extends Cubit<BoosterItemState> {
  BoosterItemCubit() : super(BoosterItemStateInitial());

  void addItems({required BoosterItems item, required int amount}) {
    final itemsAmount = state.items[item];
    if (itemsAmount == null) {
      return;
    }
    final newItemsAmount = itemsAmount + amount;

    emit(
      BoosterItemStateLoaded({
        ...state.items,
        item: newItemsAmount,
      }),
    );
  }

  void consumeItem({required BoosterItems item}) {
    final itemsAmount = state.items[item];
    if (itemsAmount == null || itemsAmount == 0) {
      return;
    }
    final newItemsAmount = itemsAmount - 1;

    emit(
      BoosterItemStateLoaded({
        ...state.items,
        item: newItemsAmount,
      }),
    );
  }
}
