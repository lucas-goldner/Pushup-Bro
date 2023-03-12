import 'dart:async';

import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

class AirPodsMotionProvider {
  Stream<DeviceMotionData> listenForAirPodsMotionData() =>
      FlutterAirpods.getAirPodsDeviceMotionUpdates;
}
