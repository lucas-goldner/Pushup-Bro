import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Procedural plants, rocks and terrain shared by the island and the jungle.

const bark = Color(0xFF9A6B47);
const darkBark = Color(0xFF6E4A33);
const frond = Color(0xFF4CA85A);
const rockGrey = Color(0xFF9BA1B0);
const moss = Color(0xFF6DAF4F);
const leafGreens = [
  Color(0xFF3F9A4A),
  Color(0xFF4FB05A),
  Color(0xFF2F8443),
  Color(0xFF66BE5E),
  Color(0xFF2A7A4F),
];
const flowerColors = [
  Color(0xFFF26B8A),
  Color(0xFFF5C343),
  Color(0xFFE5534B),
  Color(0xFFB98AF2),
  Color(0xFFFF9F43),
];

/// Rotation of [angle] radians around +Y.
vm.Quaternion yaw(double angle) =>
    vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle);

/// A tapered plateau whose outline follows [radius] (by angle), with a flat
/// top at [top] and walls flaring out by [bottomScale] down to [bottom].
MeshGeometry plateau({
  required double Function(double angle) radius,
  required double top,
  required double bottom,
  required double bottomScale,
  int segments = 96,
}) {
  final builder = GeometryBuilder(deduplicate: false);
  final center = builder.addVertex(vm.Vector3(0, top, 0));
  final capRing = <int>[];
  final sideTop = <int>[];
  final sideBottom = <int>[];
  for (var i = 0; i < segments; i++) {
    final angle = i / segments * math.pi * 2;
    final r = radius(angle);
    final x = math.cos(angle);
    final z = math.sin(angle);
    capRing.add(builder.addVertex(vm.Vector3(x * r, top, z * r)));
    sideTop.add(builder.addVertex(vm.Vector3(x * r, top, z * r)));
    sideBottom.add(
      builder.addVertex(
        vm.Vector3(x * r * bottomScale, bottom, z * r * bottomScale),
      ),
    );
  }
  for (var i = 0; i < segments; i++) {
    final j = (i + 1) % segments;
    // Wound counter-clockwise around the outward normal: +Y on the cap,
    // outwards on the walls.
    builder
      ..addTriangle(center, capRing[j], capRing[i])
      ..addTriangle(sideTop[i], sideTop[j], sideBottom[i])
      ..addTriangle(sideTop[j], sideBottom[j], sideBottom[i]);
  }

  return builder.build();
}

/// A curved palm with drooping fronds and coconuts, its base at the origin.
Node palmTree({double lean = 0, double height = 2}) {
  final top = vm.Vector3(0.22 * height, height, 0.05);
  final trunk = TubeGeometry(
    CatmullRomPath([
      vm.Vector3.zero(),
      vm.Vector3(0.08, height * 0.4, 0),
      vm.Vector3(0.28, height * 0.75, 0.03),
      top,
    ]),
    radius: 0.075,
    radialSegments: 10,
    stations: 24,
  );
  final frondMaterial = matte(frond, roughness: 0.75)..doubleSided = true;
  final tree = Node(name: 'palm')
    ..rotation = yaw(lean)
    ..add(meshNode(trunk, matte(bark)));

  const fronds = 7;
  for (var i = 0; i < fronds; i++) {
    final angle = i / fronds * math.pi * 2 + 0.3;
    final dir = vm.Vector3(math.cos(angle), 0, math.sin(angle));
    tree.add(
      meshNode(
        RibbonGeometry(
          CatmullRomPath([
            top,
            top + dir * 0.45 + vm.Vector3(0, 0.22, 0),
            top + dir * 0.9 + vm.Vector3(0, 0.05, 0),
            top + dir * 1.15 + vm.Vector3(0, -0.4, 0),
          ]),
          width: 0.3,
          stations: 16,
        ),
        frondMaterial,
      ),
    );
  }
  final coconut = matte(const Color(0xFF6B4A2F), roughness: 0.7);
  for (var i = 0; i < 3; i++) {
    final angle = i / 3 * math.pi * 2;
    tree.add(
      meshNode(
        SphereGeometry(radius: 0.075, segments: 16, rings: 10),
        coconut,
        position: top +
            vm.Vector3(math.cos(angle) * 0.09, -0.08, math.sin(angle) * 0.09),
      ),
    );
  }

  return tree;
}

/// A squashed, faceted boulder resting on the ground.
Node rock(
  double size, {
  double turn = 0,
  bool mossy = false,
  Color color = rockGrey,
}) {
  final node = Node(name: 'rock')
    ..add(
      meshNode(
        reshaped(
          IcosphereGeometry(radius: size, subdivisions: 1),
          vm.Vector3(1.3, 0.75, 1),
          rotation: yaw(turn),
        ),
        matte(color, roughness: 0.9),
        position: vm.Vector3(0, size * 0.25, 0),
      ),
    );
  if (mossy) {
    node.add(
      meshNode(
        reshaped(
          IcosphereGeometry(radius: size * 0.85, subdivisions: 1),
          vm.Vector3(1.25, 0.35, 0.95),
          rotation: yaw(turn + 0.4),
        ),
        matte(moss),
        position: vm.Vector3(0, size * 0.62, 0),
      ),
    );
  }

  return node;
}

/// A round cluster of leaves.
Node bush({double size = 1, Color color = const Color(0xFF5DAA55)}) {
  final material = matte(color);

  return Node(name: 'bush')
    ..add(
      meshNode(
        IcosphereGeometry(radius: 0.22 * size),
        material,
        position: vm.Vector3(0, 0.12 * size, 0),
      ),
    )
    ..add(
      meshNode(
        IcosphereGeometry(radius: 0.16 * size),
        material,
        position: vm.Vector3(0.2 * size, 0.08 * size, 0.05 * size),
      ),
    )
    ..add(
      meshNode(
        IcosphereGeometry(radius: 0.15 * size),
        material,
        position: vm.Vector3(-0.18 * size, 0.07 * size, 0.08 * size),
      ),
    );
}

/// A rainforest tree: a gently curved trunk under a lumpy, faceted canopy.
///
/// The canopy sits on its own child node (`canopy`) so callers can sway it.
Node broadleafTree(math.Random random, {double height = 1.8}) {
  final lean = vm.Vector3(
    (random.nextDouble() - 0.5) * 0.3,
    height,
    (random.nextDouble() - 0.5) * 0.3,
  );
  final tree = Node(name: 'broadleaf')
    ..add(
      meshNode(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3.zero(),
            vm.Vector3(lean.x * 0.2, height * 0.45, lean.z * 0.2),
            lean,
          ]),
          radius: 0.07 + height * 0.02,
          radialSegments: 9,
          stations: 16,
        ),
        matte(random.nextBool() ? bark : darkBark),
      ),
    );
  // Buttress roots flaring at the base.
  for (var i = 0; i < 4; i++) {
    final angle = i / 4 * math.pi * 2 + random.nextDouble();
    tree.add(
      meshNode(
        CylinderGeometry(
          bottomRadius: 0.07,
          topRadius: 0.01,
          height: 0.35,
          radialSegments: 6,
        ),
        matte(darkBark),
        position:
            vm.Vector3(math.cos(angle) * 0.08, 0.12, math.sin(angle) * 0.08),
        rotation: vm.Quaternion.fromTwoVectors(
          vm.Vector3(0, 1, 0),
          vm.Vector3(math.cos(angle), 1.6, math.sin(angle)),
        ),
      ),
    );
  }

  final canopy = Node(name: 'canopy')..position = lean;
  final green = leafGreens[random.nextInt(leafGreens.length)];
  final blobs = 4 + random.nextInt(3);
  for (var i = 0; i < blobs; i++) {
    final angle = i / blobs * math.pi * 2 + random.nextDouble();
    final spread = 0.25 + random.nextDouble() * 0.2;
    final r = 0.32 + random.nextDouble() * 0.2;
    canopy.add(
      meshNode(
        IcosphereGeometry(radius: r, subdivisions: 1),
        matte(_tint(green, random)),
        position: vm.Vector3(
          math.cos(angle) * spread,
          (random.nextDouble() - 0.3) * 0.25,
          math.sin(angle) * spread,
        ),
      ),
    );
  }
  canopy.add(
    meshNode(
      IcosphereGeometry(radius: 0.38, subdivisions: 1),
      matte(_tint(green, random)),
      position: vm.Vector3(0, 0.28, 0),
    ),
  );

  return tree..add(canopy);
}

/// A tall emergent tree with a flat umbrella crown and hanging vines.
///
/// The crown sits on its own child node (`canopy`) so callers can sway it.
Node umbrellaTree(math.Random random, {double height = 3}) {
  final top = vm.Vector3(0.15, height, -0.05);
  final tree = Node(name: 'umbrella')
    ..add(
      meshNode(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3.zero(),
            vm.Vector3(-0.05, height * 0.5, 0.04),
            top,
          ]),
          radius: 0.1,
          radialSegments: 10,
          stations: 18,
        ),
        matte(const Color(0xFFB59272)),
      ),
    );

  final canopy = Node(name: 'canopy')..position = top;
  final crown = reshaped(
    IcosphereGeometry(radius: 0.6, subdivisions: 1),
    vm.Vector3(1.5, 0.45, 1.3),
  );
  for (final (dx, dy, dz) in [
    (0.0, 0.1, 0.0),
    (0.45, 0.0, 0.2),
    (-0.4, -0.02, -0.15),
  ]) {
    canopy.add(
      meshNode(
        crown,
        matte(_tint(leafGreens[2], random)),
        position: vm.Vector3(dx, dy, dz),
        rotation: yaw(random.nextDouble() * math.pi),
      ),
    );
  }
  // Vines hanging from the crown, ending in a small leaf.
  final vine = matte(const Color(0xFF3E7D3A));
  for (var i = 0; i < 5; i++) {
    final angle = random.nextDouble() * math.pi * 2;
    final start =
        vm.Vector3(math.cos(angle) * 0.6, -0.15, math.sin(angle) * 0.5);
    final length = 0.8 + random.nextDouble() * 1.1;
    canopy
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              start,
              start + vm.Vector3(0.06, -length * 0.5, 0.04),
              start + vm.Vector3(-0.02, -length, 0.08),
            ]),
            radius: 0.012,
            radialSegments: 5,
            stations: 10,
          ),
          vine,
        ),
      )
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.05, subdivisions: 0),
          matte(moss),
          position: start + vm.Vector3(-0.02, -length, 0.08),
        ),
      );
  }

  return tree..add(canopy);
}

/// A fern: arching fronds fanning out from the ground.
Node fern(math.Random random, {double size = 1}) {
  final material = matte(
    leafGreens[random.nextInt(leafGreens.length)],
    roughness: 0.8,
  )..doubleSided = true;
  final node = Node(name: 'fern');
  const fronds = 6;
  for (var i = 0; i < fronds; i++) {
    final angle = i / fronds * math.pi * 2 + random.nextDouble() * 0.5;
    final dir = vm.Vector3(math.cos(angle), 0, math.sin(angle));
    node.add(
      meshNode(
        RibbonGeometry(
          CatmullRomPath([
            vm.Vector3(0, 0.02, 0),
            dir * 0.18 * size + vm.Vector3(0, 0.28 * size, 0),
            dir * 0.42 * size + vm.Vector3(0, 0.12 * size, 0),
          ]),
          width: 0.11 * size,
          stations: 10,
        ),
        material,
      ),
    );
  }

  return node;
}

/// A little clump of flowers on short stems.
Node flowers(math.Random random) {
  final node = Node(name: 'flowers');
  final stem = matte(const Color(0xFF3E7D3A));
  for (var i = 0; i < 4; i++) {
    final at = vm.Vector3(
      (random.nextDouble() - 0.5) * 0.3,
      0,
      (random.nextDouble() - 0.5) * 0.3,
    );
    final height = 0.12 + random.nextDouble() * 0.1;
    node
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.008,
            topRadius: 0.008,
            height: height,
            radialSegments: 5,
          ),
          stem,
          position: at + vm.Vector3(0, height / 2, 0),
        ),
      )
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.045, subdivisions: 1),
          matte(
            flowerColors[random.nextInt(flowerColors.length)],
            roughness: 0.5,
          ),
          position: at + vm.Vector3(0, height, 0),
        ),
      );
  }

  return node;
}

/// A red-capped toadstool with white spots.
Node mushroom({double size = 1}) => Node(name: 'mushroom')
  ..add(
    meshNode(
      CylinderGeometry(
        bottomRadius: 0.035 * size,
        topRadius: 0.028 * size,
        height: 0.12 * size,
        radialSegments: 10,
      ),
      matte(const Color(0xFFF4EDE1)),
      position: vm.Vector3(0, 0.06 * size, 0),
    ),
  )
  ..add(
    meshNode(
      reshaped(
        SphereGeometry(radius: 0.08 * size, segments: 16, rings: 10),
        vm.Vector3(1, 0.6, 1),
      ),
      matte(const Color(0xFFE5534B), roughness: 0.5),
      position: vm.Vector3(0, 0.13 * size, 0),
    ),
  )
  ..addAll([
    for (final (dx, dz) in [(0.03, 0.04), (-0.045, 0.01), (0.0, -0.05)])
      meshNode(
        SphereGeometry(radius: 0.012 * size, segments: 8, rings: 6),
        matte(const Color(0xFFFFFFFF)),
        position: vm.Vector3(dx * size, 0.165 * size, dz * size),
      ),
  ]);

Color _tint(Color base, math.Random random) {
  final shift = (random.nextDouble() - 0.5) * 0.12;

  return Color.from(
    alpha: 1,
    red: (base.r + shift).clamp(0, 1),
    green: (base.g + shift * 1.4).clamp(0, 1),
    blue: (base.b + shift).clamp(0, 1),
  );
}
