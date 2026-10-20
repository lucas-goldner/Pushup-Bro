import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';

sealed class GameInventoryState extends Equatable {
  const GameInventoryState(this.inventory);

  final GameInventory inventory;

  @override
  List<Object?> get props => [inventory];
}

class GameInventoryStateInitial extends GameInventoryState {
  GameInventoryStateInitial()
      : super(
          GameInventory(
            bananas: 0,
            boughtItems: const [],
            monkeys: [
              AdoptableMonkey.carlos(),
            ],
          ),
        );
}

class GameInventoryFetching extends GameInventoryState {
  GameInventoryFetching()
      : super(
          GameInventory(
            bananas: 0,
            boughtItems: const [],
            monkeys: [
              AdoptableMonkey.carlos(),
            ],
          ),
        );
}

class GameInventoryLoaded extends GameInventoryState {
  const GameInventoryLoaded(super.inventory);
}
