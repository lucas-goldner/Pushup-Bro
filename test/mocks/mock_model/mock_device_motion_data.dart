import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/calibrated_magnetic_field.dart';
import 'package:flutter_airpods/models/calibrated_magnetic_field_accuracy.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:flutter_airpods/models/gravity.dart';
import 'package:flutter_airpods/models/magnetic_field.dart';
import 'package:flutter_airpods/models/quaternion.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:flutter_airpods/models/user_acceleration.dart';

@visibleForTesting
class DeviceMotionDataMocks {
  DeviceMotionData mockDefaultDeviceMotionData = const DeviceMotionData(
    Attitude(Quaternion(0, 1, 2, 3), 4, 5, 6),
    Gravity(0, 1, 2),
    RotationRate(0, 1, 2),
    UserAcceleration(0, 1, 2),
    CalibratedMagneticField(
      MagneticField(0, 1, 2),
      MagneticFieldCalibrationAccuracy.low,
    ),
    0,
  );

  Stream<DeviceMotionData> get mockDeviceMotionDataStream {
    final deviceMotionData =
        DeviceMotionDataMocks().mockDefaultDeviceMotionData;
    final controller = StreamController<DeviceMotionData>(sync: true)
      ..add(deviceMotionData);

    return controller.stream;
  }

  List<DeviceMotionData> get mockDeviceMotionData =>
      [mockDefaultDeviceMotionData];
}
