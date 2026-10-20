import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/active_effects_state.dart';
import 'package:pushup_bro/core/model/active_effects.dart';

class ActiveEffectsCubit extends Cubit<ActiveEffectsState> {
  ActiveEffectsCubit() : super(ActiveEffectsStateInitial());

  void addEffect(ActiveEffects effect) {
    if (state.effects.contains(effect)) return;
    emit(ActiveEffectsStateActivated([...state.effects, effect]));
  }

  void clearEffects() => emit(
        const ActiveEffectsStateActivated([]),
      );
}
