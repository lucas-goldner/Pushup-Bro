import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/calibrated_magnetic_field.dart';
import 'package:flutter_airpods/models/calibrated_magnetic_field_accuracy.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:flutter_airpods/models/gravity.dart';
import 'package:flutter_airpods/models/magnetic_field.dart';
import 'package:flutter_airpods/models/quaternion.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:flutter_airpods/models/user_acceleration.dart';

/// Ticks per simulated pushup: down for one tick, up for one, then rest.
const _ticksPerPushup = 4;
const _tick = Duration(milliseconds: 500);

/// Mock AirPods motion for the web build: one pushup every two seconds,
/// using the same vertical acceleration thresholds `PushupCubit` checks.
Stream<DeviceMotionData> motionUpdates() => Stream.periodic(
      _tick,
      (tick) => switch (tick % _ticksPerPushup) {
        0 => _motion(-0.5),
        1 => _motion(0.5),
        _ => _motion(0),
      },
    );

DeviceMotionData _motion(double accelerationY) => DeviceMotionData(
      const Attitude(Quaternion(0, 0, 0, 1), 0, 0, 0),
      const Gravity(0, -1, 0),
      const RotationRate(0, 0, 0),
      UserAcceleration(0, accelerationY, 0),
      const CalibratedMagneticField(
        MagneticField(0, 0, 0),
        MagneticFieldCalibrationAccuracy.uncalibrated,
      ),
      0,
    );
