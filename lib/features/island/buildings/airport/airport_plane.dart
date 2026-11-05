import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _white = Color(0xFFFAF8F4);
const _red = Color(0xFFF26B5B);
const _glass = Color(0xFF7FC4E8);

/// One round trip, in seconds: parked, take-off, away, landing, turning.
const _parked = 5.0;
const _takeOff = 6.0;
const _away = 7.0;
const _landing = 6.0;
const _turn = 2.0;
const double _cycle = _parked + _takeOff + _away + _landing + _turn;

/// How far (m) the plane flies out before the fog swallows it, and how
/// steeply it climbs once it's off the ground.
const _range = 32.0;
const _climb = 0.3;

/// A little plane at the airport that takes off over the sea now and then
/// and comes back to land. One baked mesh moving along a fixed path, so it
/// costs next to nothing.
class AirportPlane {
  AirportPlane() {
    bakeStatic(root);
    root.visible = false;
  }

  final Node root = _plane();
  double _time = 0;

  /// Moves the plane on for [deltaSeconds]. [airport] is where the
  /// airport stands on the ground, or null while it isn't built.
  void update(double deltaSeconds, {required vm.Vector3? airport}) {
    if (airport == null) {
      root.visible = false;
      return;
    }
    _time = (_time + deltaSeconds) % _cycle;
    final out = vm.Vector3(airport.x, 0, airport.z);
    if (out.length2 < 1e-6) out.setValues(0, 0, 1);
    out.normalize();
    // Parked on the grass beside the airport, on the side away from the
    // camera (gifts land on the near side), nose to the sea.
    final side = vm.Vector3(out.z, 0, -out.x);
    if (side.z < 0) side.negate();
    final park = airport + out * 0.5 - side * 0.8 + vm.Vector3(0, 0.02, 0);
    final outward = math.atan2(out.x, out.z);

    var t = _time;
    double distance;
    var heading = outward;
    var visible = true;
    if ((t -= _parked) < 0) {
      distance = 0;
    } else if ((t -= _takeOff) < 0) {
      // Speeding up along the ground, then off.
      final s = (t + _takeOff) / _takeOff;
      distance = _range * s * s;
    } else if ((t -= _away) < 0) {
      distance = _range;
      visible = false;
    } else if ((t -= _landing) < 0) {
      // In from the sea, slowing down to a stop.
      final s = (t + _landing) / _landing;
      distance = _range * (1 - s) * (1 - s);
      heading = outward + math.pi;
    } else {
      // Turning round to face the sea again.
      final s = (t + _turn) / _turn;
      distance = 0;
      heading = outward + math.pi * (1 + s * s * (3 - 2 * s));
    }
    final height = math.max(0, distance - 1.6) * _climb;
    root
      ..visible = visible
      ..position = park + out * distance + vm.Vector3(0, height, 0)
      ..rotation = yaw(heading) *
          vm.Quaternion.axisAngle(
            vm.Vector3(1, 0, 0),
            height > 0 ? -0.18 : 0,
          );
  }
}

/// A small white plane with red trim, nose along +Z, wheels at 0.
Node _plane() {
  final white = matte(_white, roughness: 0.5);
  final red = matte(_red, roughness: 0.6);
  final along = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2);
  MeshGeometry box(double x, double y, double z) =>
      reshaped(CuboidGeometry(vm.Vector3.all(1)), vm.Vector3(x, y, z));

  return Node(name: 'plane')
    ..add(
      meshNode(
        capsule(0.065, 0.36),
        white,
        position: vm.Vector3(0, 0.12, 0),
        rotation: along,
      ),
    )
    ..add(
      meshNode(
        sphere(0.05),
        red,
        position: vm.Vector3(0, 0.12, 0.24),
      ),
    )
    ..add(
      meshNode(
        box(0.09, 0.04, 0.08),
        matte(_glass, roughness: 0.2),
        position: vm.Vector3(0, 0.17, 0.12),
      ),
    )
    ..add(
      meshNode(
        box(0.62, 0.02, 0.12),
        red,
        position: vm.Vector3(0, 0.1, 0.03),
      ),
    )
    ..add(
      meshNode(
        box(0.24, 0.015, 0.06),
        white,
        position: vm.Vector3(0, 0.13, -0.2),
      ),
    )
    ..add(
      meshNode(box(0.015, 0.12, 0.08), red, position: vm.Vector3(0, 0.2, -0.2)),
    );
}
