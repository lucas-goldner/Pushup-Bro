import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/provider/airpods_motion_provider.dart';

import '../../mocks/mock_model/mock_device_motion_data.dart';
import '../../mocks/mock_service/mock_air_pods_motion_service.dart';

void main() {
  final airPodsMotionService = MockAirPodsMotionService();
  final airpodsMotionprovider =
      AirPodsMotionProvider(airPodsMotionService: airPodsMotionService);
  final deviceMotionData = DeviceMotionDataMocks().mockDefaultDeviceMotionData;

  group('test AirPodsMotionProvider', () {
    test('test listenForAirPodsMotionData', () async {
      expect(
        airpodsMotionprovider.listenForAirPodsMotionData(),
        emits(deviceMotionData),
      );
    });
  });
}
