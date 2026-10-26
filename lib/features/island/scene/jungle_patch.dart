import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _jungleFloor = Color(0xFF4E9B4A);
const _jungleEdge = Color(0xFF3D7F3E);
const _dirt = Color(0xFFB98A5A);
const _water = Color(0xFF6FD3EA);
const _waterFoam = Color(0xFFE6F8FF);
const _cliff = Color(0xFF8A8F9C);
const _gateWood = Color(0xFF8A5A36);

/// Height of the jungle floor above the node's origin.
const jungleFloorTop = 0.16;

/// A dense patch of rainforest: towering trees, palms, ferns, flowers and
/// toadstools on a mossy hill, with a waterfall tumbling into a pond, a
/// wooden gate and parrots circling above the canopy.
///
/// Built around the origin with its gate on the +Z side. As a [clearing] the
/// middle is left open (for Carlos to stand in) and the plants crowd the rim
/// instead, for the jungle screen's close-up.
class JunglePatch {
  JunglePatch({
    this.radius = 2.1,
    this.clearing = false,
    int seed = 7,
    bool fixed = false,
  }) : _random = math.Random(seed) {
    root
      ..add(_hill())
      ..add(_waterfall())
      ..addAll(_plants())
      ..addAll(_wildlife());
    // A clearing is seen from its gate, which would only block the view.
    if (!clearing) root.add(_gate());
    // Merge everything that doesn't sway, fly or ripple into a few meshes.
    final moving = findMoving(root, (step) => update(0.37));
    _time = 0;
    update(0);
    bakeStatic(root, moving: moving, shadowStatic: fixed);
  }

  final double radius;
  final bool clearing;
  final Node root = Node(name: 'jungle');
  final math.Random _random;

  final List<Node> _canopies = [];
  final List<({Node node, double phase, double speed, double orbit})> _parrots =
      [];
  final List<({Node node, Node left, Node right, vm.Vector3 home})>
      _butterflies = [];
  late final Node _fall;
  late final Node _splash;
  double _time = 0;

  /// Where the gate is, in the patch's local space.
  vm.Vector3 get gate => vm.Vector3(0, jungleFloorTop, radius * 0.92);

  void update(double deltaSeconds) {
    _time += deltaSeconds;
    for (final (i, canopy) in _canopies.indexed) {
      final sway = math.sin(_time * 0.9 + i * 1.7) * 0.035;
      canopy.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(math.cos(i * 2.1), 0, math.sin(i * 2.1)),
        sway,
      );
    }
    for (final parrot in _parrots) {
      final a = _time * parrot.speed + parrot.phase;
      parrot.node
        ..position = vm.Vector3(
          math.cos(a) * parrot.orbit,
          (clearing ? 2.6 : 3.2) + math.sin(a * 2.3) * 0.18,
          math.sin(a) * parrot.orbit,
        )
        // Fly along the orbit's tangent (counter-clockwise seen from above).
        ..rotation = vm.Quaternion.fromTwoVectors(
          vm.Vector3(0, 0, 1),
          vm.Vector3(-math.sin(a), 0, math.cos(a)) * -parrot.speed.sign,
        );
    }
    for (final (i, b) in _butterflies.indexed) {
      final t = _time * 0.8 + i * 2.4;
      b.node.position = b.home +
          vm.Vector3(
            math.sin(t) * 0.35,
            math.sin(t * 1.7) * 0.12,
            math.cos(t * 0.7) * 0.3,
          );
      final flap = 0.25 + math.sin(_time * 18 + i) * 0.9;
      b.left.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), flap);
      b.right.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -flap);
    }
    // The water's surface ripples by squashing the splash ring.
    _splash.scale = vm.Vector3.all(1 + 0.06 * math.sin(_time * 5));
    _fall.position = vm.Vector3(
      _fall.position.x,
      math.sin(_time * 9) * 0.01,
      _fall.position.z,
    );
  }

  Node _hill() => Node(name: 'hill')
    ..add(
      meshNode(
        plateau(
          radius: (a) =>
              radius *
              1.08 *
              (1 + 0.05 * math.sin(5 * a + 1) + 0.03 * math.sin(9 * a)),
          top: jungleFloorTop - 0.04,
          bottom: -0.1,
          bottomScale: 1.08,
        ),
        matte(_jungleEdge, roughness: 0.95),
      ),
    )
    ..add(
      meshNode(
        plateau(
          radius: (a) =>
              radius *
              (1 + 0.06 * math.sin(4 * a + 2) + 0.03 * math.sin(7 * a)),
          top: jungleFloorTop,
          bottom: 0,
          bottomScale: 1.02,
        ),
        matte(_jungleFloor, roughness: 0.95),
      ),
    )
    // A dirt path from the gate into the trees.
    ..add(
      meshNode(
        reshaped(
          CylinderGeometry(bottomRadius: 1, topRadius: 1, height: 0.02),
          vm.Vector3(0.22, 1, radius * (clearing ? 0.5 : 0.42)),
        ),
        matte(_dirt, roughness: 0.95),
        position: vm.Vector3(
          0,
          jungleFloorTop + 0.005,
          radius * (clearing ? 0.55 : 0.55),
        ),
      ),
    );

  /// A rocky cliff at the back with water spilling down into a pond.
  Node _waterfall() {
    final back = -radius * 0.62;
    final cliffHeight = clearing ? 2.2 : 1.5;
    final node = Node(name: 'waterfall');
    final cliffMaterial = matte(_cliff, roughness: 0.9);
    for (final (dx, dy, size) in [
      (-0.42, 0.25, 0.48),
      (0.45, 0.22, 0.44),
      (-0.3, 0.75, 0.4),
      (0.32, 0.8, 0.38),
      (0.0, 1.15, 0.36),
      (-0.55, 1.05, 0.3),
      (0.55, 1.2, 0.28),
    ]) {
      node.add(
        meshNode(
          reshaped(
            IcosphereGeometry(radius: size, subdivisions: 1),
            vm.Vector3(1.2, 1, 0.9),
            rotation: yaw(dx * 5 + dy),
          ),
          cliffMaterial,
          position: vm.Vector3(
            dx,
            jungleFloorTop + dy * cliffHeight / 1.5,
            back - 0.25,
          ),
        ),
      );
    }
    // Moss on top of the cliff.
    node.add(
      meshNode(
        reshaped(
          IcosphereGeometry(subdivisions: 1),
          vm.Vector3(1.6, 0.4, 1),
        ),
        matte(moss),
        position: vm.Vector3(0, jungleFloorTop + cliffHeight * 1.0, back - 0.3),
      ),
    );

    final waterMaterial = UnlitMaterial()
      ..baseColorFactor = linearColor(_water);
    _fall = Node(name: 'fall')
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(0.26, cliffHeight * 0.9, 0.05),
          ),
          waterMaterial,
          position: vm.Vector3(
            0,
            jungleFloorTop + cliffHeight * 0.48,
            back + 0.02,
          ),
        ),
      );
    final pondZ = back + 0.35;
    _splash = meshNode(
      RingGeometry(innerRadius: 0.16, outerRadius: 0.24),
      UnlitMaterial()..baseColorFactor = linearColor(_waterFoam),
      position: vm.Vector3(0, jungleFloorTop + 0.03, pondZ - 0.12),
    );

    return node
      ..add(_fall)
      ..add(
        meshNode(
          DiscGeometry(radius: 0.48, segments: 40),
          waterMaterial,
          position: vm.Vector3(0, jungleFloorTop + 0.02, pondZ),
        ),
      )
      ..add(_splash)
      ..addAll([
        for (var i = 0; i < 7; i++)
          rock(0.08 + (i % 3) * 0.03, turn: i * 1.3, mossy: i.isEven)
            ..position = vm.Vector3(
              math.cos(i / 7 * math.pi * 2) * 0.55,
              jungleFloorTop,
              pondZ + math.sin(i / 7 * math.pi * 2) * 0.5,
            ),
      ]);
  }

  /// A wooden gate with a vine-wrapped lintel and a banana sign.
  Node _gate() {
    final wood = matte(_gateWood, roughness: 0.8);
    final at = gate;
    final node = Node(name: 'gate')..position = at;
    for (final x in [-0.32, 0.32]) {
      node.add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.05,
            topRadius: 0.045,
            height: 0.8,
            radialSegments: 8,
          ),
          wood,
          position: vm.Vector3(x, 0.4, 0),
        ),
      );
    }
    node
      ..add(
        meshNode(
          reshaped(
            CylinderGeometry(
              bottomRadius: 0.045,
              topRadius: 0.045,
              height: 0.86,
              radialSegments: 8,
            ),
            vm.Vector3.all(1),
            rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
          ),
          wood,
          position: vm.Vector3(0, 0.8, 0),
        ),
      )
      // Vine coiled along the lintel.
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              for (var i = 0; i <= 12; i++)
                vm.Vector3(
                  -0.42 + i * 0.07,
                  0.8 + math.sin(i * 1.6) * 0.05,
                  math.cos(i * 1.6) * 0.05,
                ),
            ]),
            radius: 0.014,
            radialSegments: 5,
            stations: 40,
          ),
          matte(const Color(0xFF3E7D3A)),
        ),
      )
      // A little sign hanging from the lintel.
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(0.34, 0.14, 0.03),
          ),
          matte(const Color(0xFFF1DAA9)),
          position: vm.Vector3(0, 0.66, 0.03),
        ),
      )
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.08, 0.65, 0.05),
              vm.Vector3(0, 0.63, 0.05),
              vm.Vector3(0.08, 0.68, 0.05),
            ]),
            radius: 0.022,
            stations: 10,
          ),
          matte(const Color(0xFFF5C343), roughness: 0.5),
        ),
      );
    for (final x in [-0.32, 0.32]) {
      node.add(
        meshNode(
          IcosphereGeometry(radius: 0.08, subdivisions: 1),
          matte(leafGreens[0]),
          position: vm.Vector3(x, 0.84, 0),
        ),
      );
    }

    return node;
  }

  /// Places plants in rings: tall trees at the back, smaller ones forward,
  /// undergrowth everywhere, keeping the path and the pond open.
  List<Node> _plants() {
    final nodes = <Node>[];
    final taken = <(double, double, double)>[];
    final pondZ = -radius * 0.62 + 0.35;

    bool free(double x, double z, double clearance) {
      if (x * x + z * z > radius * radius * 0.86) return false;
      // The path to the gate.
      if (x.abs() < 0.32 && z > -0.1) return false;
      // The pond and the cliff.
      if (x.abs() < 0.8 && z < pondZ + 0.6) return false;
      if (clearing && x * x + z * z < math.pow(radius * 0.42, 2)) return false;
      for (final (tx, tz, r) in taken) {
        final dx = tx - x;
        final dz = tz - z;
        if (dx * dx + dz * dz < math.pow(r + clearance, 2)) return false;
      }

      return true;
    }

    void place(
      int count,
      double clearance,
      Node Function() build, {
      double minR = 0,
      double maxR = 1,
      bool backOnly = false,
      bool tall = false,
    }) {
      var placed = 0;
      for (var tries = 0; placed < count && tries < count * 60; tries++) {
        final angle = _random.nextDouble() * math.pi * 2;
        final r =
            radius * (minR + (maxR - minR) * math.sqrt(_random.nextDouble()));
        final x = math.cos(angle) * r;
        final z = math.sin(angle) * r;
        if (backOnly && z > radius * 0.15) continue;
        // In a clearing, keep the view from the front open.
        if (clearing && tall && z > -radius * 0.1 && x.abs() < radius * 0.7) {
          continue;
        }
        if (!free(x, z, clearance)) continue;
        taken.add((x, z, clearance));
        nodes.add(
          build()
            ..position = vm.Vector3(x, jungleFloorTop, z)
            ..rotation = yaw(_random.nextDouble() * math.pi * 2),
        );
        placed++;
      }
    }

    final scale = clearing ? 1.25 : 1.0;
    place(
      clearing ? 4 : 3,
      0.55,
      () => umbrellaTree(_random, height: (2.6 + _random.nextDouble()) * scale),
      minR: 0.35,
      backOnly: true,
      tall: true,
    );
    place(
      clearing ? 12 : 8,
      0.42,
      () => broadleafTree(
        _random,
        height: (1.3 + _random.nextDouble() * 0.9) * scale,
      ),
      minR: 0.2,
      tall: true,
    );
    place(
      clearing ? 5 : 3,
      0.35,
      () => palmTree(
        lean: _random.nextDouble() * math.pi * 2,
        height: 1.5 + _random.nextDouble() * 0.6,
      ),
      minR: 0.5,
      tall: true,
    );
    place(clearing ? 18 : 12, 0.18, () => fern(_random, size: 0.9 * scale));
    place(clearing ? 10 : 7, 0.12, () => flowers(_random));
    place(
      clearing ? 8 : 5,
      0.12,
      () => mushroom(size: 0.9 + _random.nextDouble() * 0.6),
    );
    place(
      clearing ? 6 : 4,
      0.2,
      () => rock(0.14 + _random.nextDouble() * 0.1, mossy: true),
    );
    place(
      clearing ? 8 : 6,
      0.25,
      () => bush(
        size: 0.8 + _random.nextDouble() * 0.5,
        color: leafGreens[_random.nextInt(leafGreens.length)],
      ),
      minR: 0.6,
    );

    nodes.forEach(_collectCanopies);

    return nodes;
  }

  void _collectCanopies(Node node) {
    if (node.name == 'canopy') _canopies.add(node);
    node.children.forEach(_collectCanopies);
  }

  List<Node> _wildlife() {
    final nodes = <Node>[];
    for (final (i, (body, wing)) in [
      (const Color(0xFFE5534B), const Color(0xFF3F7DE0)),
      (const Color(0xFF3F7DE0), const Color(0xFFF5C343)),
      (const Color(0xFF44B37A), const Color(0xFFE5534B)),
    ].indexed) {
      final parrot = _parrot(body, wing);
      _parrots.add(
        (
          node: parrot,
          phase: i * 2.1,
          speed: i.isEven ? 0.55 : -0.45,
          orbit: radius * (0.45 + i * 0.12),
        ),
      );
      nodes.add(parrot);
    }
    for (var i = 0; i < (clearing ? 5 : 3); i++) {
      final color = flowerColors[(i * 2 + 1) % flowerColors.length];
      final left = Node()
        ..add(
          meshNode(
            reshaped(
              DiscGeometry(radius: 0.06, segments: 12),
              vm.Vector3(1, 1, 0.7),
            ),
            matte(color, roughness: 0.5)..doubleSided = true,
            position: vm.Vector3(-0.055, 0, 0),
          ),
        );
      final right = Node()
        ..add(
          meshNode(
            reshaped(
              DiscGeometry(radius: 0.06, segments: 12),
              vm.Vector3(1, 1, 0.7),
            ),
            matte(color, roughness: 0.5)..doubleSided = true,
            position: vm.Vector3(0.055, 0, 0),
          ),
        );
      final angle = i * 2.4 + 0.6;
      final home = vm.Vector3(
        math.cos(angle) * radius * 0.55,
        jungleFloorTop + 0.55 + i * 0.08,
        math.sin(angle) * radius * 0.55,
      );
      final node = Node(name: 'butterfly')
        ..add(left)
        ..add(right)
        ..add(
          meshNode(
            CapsuleGeometry(radius: 0.012, height: 0.08),
            matte(const Color(0xFF2B2B2B)),
            rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
          ),
        );
      _butterflies.add((node: node, left: left, right: right, home: home));
      nodes.add(node);
    }

    return nodes;
  }

  /// A chunky little parrot, its beak pointing along +Z.
  Node _parrot(Color body, Color wing) {
    final bodyMaterial = matte(body, roughness: 0.6);
    final wingMaterial = matte(wing, roughness: 0.6);

    return Node(name: 'parrot')
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.1, segments: 16, rings: 10),
            vm.Vector3(0.85, 0.8, 1.3),
          ),
          bodyMaterial,
        ),
      )
      ..add(
        meshNode(
          SphereGeometry(radius: 0.07, segments: 14, rings: 10),
          bodyMaterial,
          position: vm.Vector3(0, 0.06, 0.12),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.025,
            topRadius: 0,
            height: 0.06,
            radialSegments: 8,
          ),
          matte(const Color(0xFFF5C343), roughness: 0.5),
          position: vm.Vector3(0, 0.05, 0.2),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0])
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.1, segments: 12, rings: 8),
              vm.Vector3(1.3, 0.2, 0.8),
            ),
            wingMaterial,
            position: vm.Vector3(side * 0.13, 0.03, -0.01),
          ),
      ])
      // Tail feathers.
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(0.06, 0.02, 0.2),
          ),
          wingMaterial,
          position: vm.Vector3(0, -0.01, -0.2),
        ),
      );
  }
}
