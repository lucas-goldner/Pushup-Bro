import 'dart:async';

import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pushup_bro/provider/airpods_motion_provider.dart';

import '../mock_model/mock_device_motion_data.dart';

final deviceMotionDataStream =
    DeviceMotionDataMocks().mockDeviceMotionDataStream;

class MockAirpodsMotionProvider extends Mock implements AirPodsMotionProvider {
  @override
  Stream<DeviceMotionData> listenForAirPodsMotionData() =>
      deviceMotionDataStream;
}

class MockAirPodsMotionService extends Mock implements AirPodsMotionService {
  @override
  Stream<DeviceMotionData> getMotionData() => deviceMotionDataStream;
}
