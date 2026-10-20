import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/feature_variants.dart';

sealed class FeatureSwitchState extends Equatable {
  const FeatureSwitchState(this.featureVariant);
  final FeatureVariants featureVariant;

  @override
  List<Object?> get props => [featureVariant];
}

class FeatureSwitchStateHookmodel extends FeatureSwitchState {
  const FeatureSwitchStateHookmodel() : super(FeatureVariants.hookmodel);
}

class FeatureSwitchStateGamification extends FeatureSwitchState {
  const FeatureSwitchStateGamification() : super(FeatureVariants.gamification);
}
