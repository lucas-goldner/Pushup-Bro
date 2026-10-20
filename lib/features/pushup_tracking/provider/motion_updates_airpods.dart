import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

Stream<DeviceMotionData> motionUpdates() =>
    FlutterAirpods.getAirPodsDeviceMotionUpdates;
