import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/motion_updates.dart';

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

  /// Real AirPods on device; simulated pushups on the web.
  Stream<DeviceMotionData> getMotionData() => motionUpdates();
}
