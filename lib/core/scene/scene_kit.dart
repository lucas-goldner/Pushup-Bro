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

final Map<Object, Geometry> _shared = {};

/// The geometry for [key], built by [build] the first time and handed out
/// again after that, so a shape made over and over (in a loop, for every
/// character, for every spark) is generated and uploaded once. Only for
/// geometry that is never changed afterwards; the cache lives as long as
/// the app, so keep the keys to a handful of fixed shapes.
G sharedGeometry<G extends Geometry>(Object key, G Function() build) =>
    _shared.putIfAbsent(key, build) as G;

/// A shared [SphereGeometry] (see [sharedGeometry]).
SphereGeometry sphere(double radius, {int segments = 32, int rings = 16}) =>
    sharedGeometry(
      ('sphere', radius, segments, rings),
      () => SphereGeometry(radius: radius, segments: segments, rings: rings),
    );

/// A shared [IcosphereGeometry] (see [sharedGeometry]).
IcosphereGeometry icosphere(double radius, {int subdivisions = 2}) =>
    sharedGeometry(
      ('icosphere', radius, subdivisions),
      () => IcosphereGeometry(radius: radius, subdivisions: subdivisions),
    );

/// A shared [CapsuleGeometry] (see [sharedGeometry]).
CapsuleGeometry capsule(
  double radius,
  double height, {
  int radialSegments = 32,
  int capRings = 8,
}) =>
    sharedGeometry(
      ('capsule', radius, height, radialSegments, capRings),
      () => CapsuleGeometry(
        radius: radius,
        height: height,
        radialSegments: radialSegments,
        capRings: capRings,
      ),
    );

/// Keeps only the shadow cascades of [light] that something on screen can
/// sample, for a view where nothing past [visibleDepth] from a camera with
/// the [near] plane shows (fog swallows it, or the room ends there).
///
/// The light covers 150 m in four cascades by default, while these scenes
/// end a few metres away, so the far cascades were drawn every frame for
/// nobody. The cascades kept stay exactly where they were (the first split
/// is pinned and the rest spread as before), and shadows only fade out past
/// [visibleDepth], so the shadows look the same.
DirectionalLight fitShadowCascades(
  DirectionalLight light, {
  required double visibleDepth,
  double near = 0.1,
}) {
  final count = light.shadowCascadeCount.clamp(1, 4);
  final far = light.shadowMaxDistance;
  final lambda = light.shadowCascadeSplitLambda;
  if (light.firstCascadeFarBound != null || light.cascadeOverlap > 0) {
    return light;
  }
  // Where the engine splits the cascades (a blend of logarithmic and
  // uniform spacing).
  final splits = [
    near,
    for (var i = 1; i <= count; i++)
      lambda * near * math.pow(far / near, i / count) +
          (1 - lambda) * (near + (far - near) * i / count),
  ];
  for (var keep = 1; keep < count; keep++) {
    final end = splits[keep];
    // Shadows fade out over the last stretch before they end.
    final fadeFrom = end - math.max(light.shadowFadeRange, end * 0.1);
    if (fadeFrom < visibleDepth) continue;
    light
      ..shadowCascadeCount = keep
      ..shadowMaxDistance = end;
    if (keep >= 2) light.firstCascadeFarBound = splits[1];
    if (keep == 3) {
      // One split left between the pinned one and the end: blend it back
      // to where it was.
      final log = math.sqrt(splits[1] * splits[3]);
      final uniform = (splits[1] + splits[3]) / 2;
      light.shadowCascadeSplitLambda = (uniform - splits[2]) / (uniform - log);
    }
    break;
  }

  return light;
}

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
