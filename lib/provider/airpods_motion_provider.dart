import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

class AirPodsMotionProvider {
  AirPodsMotionProvider({AirPodsMotionService? airPodsMotionService})
      : _airPodsMotionService =
            airPodsMotionService ?? const AirPodsMotionService(),
        super();

  final AirPodsMotionService _airPodsMotionService;

  Stream<DeviceMotionData> listenForAirPodsMotionData() =>
      _airPodsMotionService.getMotionData();
}

@visibleForTesting
class AirPodsMotionService {
  const AirPodsMotionService();

  Stream<DeviceMotionData> getMotionData() =>
      FlutterAirpods.getAirPodsDeviceMotionUpdates;
}
