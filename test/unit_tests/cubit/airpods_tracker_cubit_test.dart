import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/cubit/airpods_tracker/airpods_tracker_cubit.dart';
import 'package:pushup_bro/cubit/airpods_tracker/airpods_tracker_state.dart';
import 'package:pushup_bro/provider/airpods_motion_provider.dart';

import '../../mocks/mock_model/mock_device_motion_data.dart';
import '../../mocks/mock_provider/mock_airpods_motion_provider.dart';

void main() {
  late AirPodsMotionProvider airPodsMotionProvider;
  late AirPodsTrackerCubit airPodsTrackerCubit;
  final deviceMotionMock = DeviceMotionDataMocks().mockDefaultDeviceMotionData;

  setUp(() {
    airPodsMotionProvider = MockAirpodsMotionProvider();
    airPodsTrackerCubit = AirPodsTrackerCubit(airPodsMotionProvider);
  });

  group('Test AirPodsTrackerCubit', () {
    group('Test getAirPodsMotionData', () {
      blocTest<AirPodsTrackerCubit, AirPodsTrackerState>(
        'test getAirPodsMotionData for data',
        build: () => airPodsTrackerCubit,
        act: (cubit) => cubit.getAirPodsMotionData(),
        expect: () => [
          AirPodsTrackerStateListening(deviceMotionMock),
        ],
      );
    });

    group('Test stopListening', () {
      blocTest<AirPodsTrackerCubit, AirPodsTrackerState>(
        'test stopListening to stop listening state',
        build: () => airPodsTrackerCubit,
        act: (cubit) async => {
          cubit.getAirPodsMotionData(),
          await Future<void>.delayed(const Duration(seconds: 3)),
          cubit.stopListening(),
        },
        expect: () => [
          AirPodsTrackerStateListening(deviceMotionMock),
          const AirPodsTrackerStateInitial()
        ],
      );
    });
  });
}
