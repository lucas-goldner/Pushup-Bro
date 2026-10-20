import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/feature_switch_state.dart';
import 'package:pushup_bro/core/model/feature_variants.dart';

class FeatureSwitchCubit extends Cubit<FeatureSwitchState> {
  FeatureSwitchCubit() : super(const FeatureSwitchStateGamification());

  void switchFeature(FeatureVariants featureSwitchState) =>
      switch (featureSwitchState) {
        FeatureVariants.hookmodel => emit(const FeatureSwitchStateHookmodel()),
        FeatureVariants.gamification =>
          emit(const FeatureSwitchStateGamification()),
      };
}
