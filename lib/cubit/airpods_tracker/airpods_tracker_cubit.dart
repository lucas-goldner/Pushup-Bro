import 'dart:async';

import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/cubit/airpods_tracker/airpods_tracker_state.dart';
import 'package:pushup_bro/provider/airpods_motion_provider.dart';

class AirPodsTrackerCubit extends Cubit<AirPodsTrackerState> {
  AirPodsTrackerCubit(this._airPodsMotionProvider)
      : super(
          const AirPodsTrackerStateInitial(),
        );

  final AirPodsMotionProvider _airPodsMotionProvider;
  StreamSubscription<DeviceMotionData>? subscription;

  void getAirPodsMotionData() {
    subscription =
        _airPodsMotionProvider.listenForAirPodsMotionData().listen((event) {
      emit(AirPodsTrackerStateListening(event));
    });
  }

  void stopListening() {
    if (state.isListening) {
      subscription?.cancel();
      emit(
        const AirPodsTrackerStateInitial(),
      );
    }
  }
}
