import 'package:equatable/equatable.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

class AirPodsTrackerState extends Equatable {
  const AirPodsTrackerState({
    this.currentMotionData,
    required this.isListening,
  });

  final DeviceMotionData? currentMotionData;
  final bool isListening;

  AirPodsTrackerState copyWith({
    DeviceMotionData? currentMotionData,
    required bool isListening,
  }) =>
      AirPodsTrackerState(
        currentMotionData: currentMotionData,
        isListening: isListening,
      );

  @override
  List<Object?> get props => [currentMotionData, isListening];
}

class AirPodsTrackerStateInitial extends AirPodsTrackerState {
  const AirPodsTrackerStateInitial() : super(isListening: false);
}

class AirPodsTrackerStateListening extends AirPodsTrackerState {
  const AirPodsTrackerStateListening(DeviceMotionData deviceMotionData)
      : super(currentMotionData: deviceMotionData, isListening: true);
}
