import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Small helpers shared by the procedural 3D scenes.

final vm.Vector3 _up = vm.Vector3(0, 1, 0);

/// Converts an sRGB [color] to the linear RGBA flutter_scene materials expect.
vm.Vector4 linearColor(Color color) {
  double toLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  return vm.Vector4(
    toLinear(color.r),
    toLinear(color.g),
    toLinear(color.b),
    color.a,
  );
}

/// A non-metallic surface in [color].
PhysicallyBasedMaterial matte(Color color, {double roughness = 0.85}) =>
    PhysicallyBasedMaterial()
      ..baseColorFactor = linearColor(color)
      ..metallicFactor = 0
      ..roughnessFactor = roughness;

/// A node carrying one mesh, optionally placed at [position].
Node meshNode(
  Geometry geometry,
  Material material, {
  vm.Vector3? position,
  vm.Quaternion? rotation,
  String name = '',
}) {
  final node = Node(name: name, mesh: Mesh(geometry, material));
  if (position != null) node.position = position;
  if (rotation != null) node.rotation = rotation;

  return node;
}

/// Bakes a (possibly non-uniform) [scale] and optional [rotation] into
/// [geometry]. Scaling a lit node non-uniformly skews its normals, so shapes
/// like squashed rocks or long boxes are built this way instead.
MeshGeometry reshaped(
  Geometry geometry,
  vm.Vector3 scale, {
  vm.Quaternion? rotation,
}) {
  final transform = vm.Matrix4.compose(
    vm.Vector3.zero(),
    rotation ?? vm.Quaternion.identity(),
    scale,
  );

  return MeshGeometry.fromMeshData(
    geometry.extractMeshData().transformed(transform),
  );
}

/// Rotation that turns +Y onto [direction].
vm.Quaternion alongY(vm.Vector3 direction) {
  final dir = direction.normalized();
  final dot = _up.dot(dir);
  if (dot > 0.9999) return vm.Quaternion.identity();
  if (dot < -0.9999) {
    return vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi);
  }

  return vm.Quaternion.fromTwoVectors(_up, dir);
}

/// Places a +Y aligned limb [node] (a capsule) between joints [from] and [to].
void placeBetween(Node node, vm.Vector3 from, vm.Vector3 to) {
  node
    ..position = (from + to) * 0.5
    ..rotation = alongY(to - from);
}

/// Two-bone IK: the middle joint of a chain from [root] towards [target] with
/// bone lengths [a] and [b], bending towards [pole]. Returns the middle joint
/// and the reachable end point (the target, pulled in when out of reach).
(vm.Vector3, vm.Vector3) solveTwoBone(
  vm.Vector3 root,
  vm.Vector3 target,
  double a,
  double b,
  vm.Vector3 pole,
) {
  final toTarget = target - root;
  final dir = toTarget.normalized();
  final distance = toTarget.length.clamp((a - b).abs() + 1e-3, a + b - 1e-3);
  final cosA = (a * a + distance * distance - b * b) / (2 * a * distance);
  final sinA = math.sqrt(math.max(0, 1 - cosA * cosA));
  final bend = (pole - dir * pole.dot(dir)).normalized();
  final middle = root + dir * (a * cosA) + bend * (a * sinA);

  return (middle, root + dir * distance);
}

/// Critically damped spring towards [target]; frame-rate independent.
double springTo(
  double value,
  double target,
  double deltaSeconds,
  double speed,
) =>
    target + (value - target) * math.exp(-speed * deltaSeconds);
