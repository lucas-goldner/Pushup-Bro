import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

class AirPodsMotionProvider {
  AirPodsMotionProvider({
    this.airPodsMotionService = const AirPodsMotionService(),
  });

  AirPodsMotionService airPodsMotionService;

  Stream<DeviceMotionData> listenForAirPodsMotionData() =>
      airPodsMotionService.getMotionData();
}

@visibleForTesting
class AirPodsMotionService {
  const AirPodsMotionService();

  Stream<DeviceMotionData> getMotionData() =>
      FlutterAirpods.getAirPodsDeviceMotionUpdates;
}
