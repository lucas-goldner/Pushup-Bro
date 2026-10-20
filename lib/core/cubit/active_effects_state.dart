import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/active_effects.dart';

sealed class ActiveEffectsState extends Equatable {
  const ActiveEffectsState(this.effects);

  final List<ActiveEffects> effects;

  bool isActive(ActiveEffects? effect) => effects.contains(effect);

  @override
  List<Object?> get props => [effects];
}

class ActiveEffectsStateInitial extends ActiveEffectsState {
  ActiveEffectsStateInitial() : super(List<ActiveEffects>.empty());
}

class ActiveEffectsStateActivated extends ActiveEffectsState {
  const ActiveEffectsStateActivated(super.effects);
}
