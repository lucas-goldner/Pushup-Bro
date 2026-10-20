import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/booster_items.dart';

sealed class BoosterItemState extends Equatable {
  const BoosterItemState(this.items);

  final Map<BoosterItems, int> items;

  @override
  List<Object?> get props => [items];
}

class BoosterItemStateInitial extends BoosterItemState {
  BoosterItemStateInitial()
      : super(
          BoosterItems.values.asMap().map(
                (key, value) => MapEntry(value, 0),
              ),
        );
}

class BoosterItemStateLoaded extends BoosterItemState {
  const BoosterItemStateLoaded(super.items);
}
