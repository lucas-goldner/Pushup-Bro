import 'dart:async';

import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pushup_bro/provider/airpods_motion_provider.dart';

import '../mock_model/mock_device_motion_data.dart';

class MockAirPodsMotionService extends Mock implements AirPodsMotionService {
  @override
  Stream<DeviceMotionData> getMotionData() {
    final deviceMotionData =
        DeviceMotionDataMocks().mockDefaultDeviceMotionData;
    final controller = StreamController<DeviceMotionData>(sync: true)
      ..add(deviceMotionData);

    return controller.stream;
  }
}
