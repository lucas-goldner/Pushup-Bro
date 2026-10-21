import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _sea = Color(0xFF3FB2D6);
const _shallows = Color(0xFF8BDCE8);
const _foam = Color(0xFFF4FBFF);
const _sand = Color(0xFFF1DAA9);
const _grass = Color(0xFF8CCB6E);
const _bark = Color(0xFF9A6B47);
const _frond = Color(0xFF4CA85A);
const _coconut = Color(0xFF6B4A2F);
const _rock = Color(0xFF9BA1B0);
const _bush = Color(0xFF5DAA55);
const _white = Color(0xFFFAF8F4);
const _navy = Color(0xFF17203A);
const _glass = Color(0xFF7FC4E8);
const _banana = Color(0xFFF5C343);

const sandTop = 0.22;
const grassTop = 0.36;

/// The player's island: terrain, sea, palms, the buildings they bought, and
/// Carlos wandering around. Build it once the engine is ready, add [root] to
/// a scene and call [update] every frame.
class IslandWorld {
  IslandWorld() {
    root
      ..add(_buildSea())
      ..add(
        meshNode(
          _plateau(
            radius: (a) =>
                4.3 *
                (1 + 0.06 * math.sin(3 * a + 0.5) + 0.04 * math.sin(5 * a + 2)),
            top: sandTop,
            bottom: -0.4,
            bottomScale: 1.12,
          ),
          matte(_sand, roughness: 0.95),
        ),
      )
      ..add(
        meshNode(
          _plateau(
            radius: (a) =>
                3.0 * (1 + 0.08 * math.sin(2 * a + 1) + 0.05 * math.sin(4 * a)),
            top: grassTop,
            bottom: 0.15,
            bottomScale: 1.04,
          ),
          matte(_grass, roughness: 0.9),
        ),
      )
      ..addAll(_buildScenery());

    _buildings = {
      ShopBuyables.accessories: _accessoriesShop()
        ..position = vm.Vector3(-1.75, grassTop, 1)
        ..rotation = _yaw(0.5),
      ShopBuyables.airport: _airport()
        ..position = vm.Vector3(1.9, grassTop, -1.35)
        ..rotation = _yaw(-0.6),
      ShopBuyables.gym: _gym()
        ..position = vm.Vector3(-1.75, grassTop, -1.45)
        ..rotation = _yaw(0.6),
      ShopBuyables.monkeyAdoption: _adoptionHut()
        ..position = vm.Vector3(0.05, grassTop, -2.15),
    };
    for (final building in _buildings.values) {
      root.add(building..visible = false);
    }
    root
      ..add(
        _foodTruck()
          ..position = vm.Vector3(1.75, grassTop, 1)
          ..rotation = _yaw(-0.45),
      )
      ..add(gorilla.root..scale = vm.Vector3.all(0.9));
  }

  final Node root = Node(name: 'island');
  final GorillaRig gorilla = GorillaRig();
  late final Map<ShopBuyables, Node> _buildings;
  late final Node _foamRing;
  double _time = 0;
  double _lap = 0;

  /// Shows the buildings in [owned]; the food truck shop is always there.
  void showOwned(List<ShopBuyables> owned) {
    for (final MapEntry(:key, :value) in _buildings.entries) {
      value.visible = owned.contains(key);
    }
  }

  void update(double deltaSeconds) {
    _time += deltaSeconds;

    // Carlos walks laps around the middle, pausing every so often.
    final walking = (_time % 12) < 8.5;
    gorilla.activity = walking ? GorillaActivity.walking : GorillaActivity.idle;
    if (walking) _lap += deltaSeconds * 0.32;
    const lapRadius = 0.85;
    gorilla.root
      ..position = vm.Vector3(
        math.cos(_lap) * lapRadius,
        grassTop,
        math.sin(_lap) * lapRadius + 0.25,
      )
      // Face along the lap: the tangent of the circle.
      ..rotation = vm.Quaternion.fromTwoVectors(
        vm.Vector3(0, 0, 1),
        vm.Vector3(-math.sin(_lap), 0, math.cos(_lap)),
      );
    gorilla.update(deltaSeconds);

    _foamRing.scale = vm.Vector3.all(1 + 0.012 * math.sin(_time * 1.3));
  }

  Node _buildSea() {
    _foamRing = meshNode(
      RingGeometry(innerRadius: 4.2, outerRadius: 4.75, segments: 96),
      matte(_foam, roughness: 0.6),
      position: vm.Vector3(0, 0.02, 0),
    );

    return Node(name: 'sea')
      ..add(
        meshNode(
          DiscGeometry(radius: 60, segments: 96),
          matte(_sea, roughness: 0.15),
        ),
      )
      ..add(
        meshNode(
          RingGeometry(innerRadius: 4, outerRadius: 6.6, segments: 96),
          matte(_shallows, roughness: 0.2),
          position: vm.Vector3(0, 0.01, 0),
        ),
      )
      ..add(_foamRing);
  }

  List<Node> _buildScenery() => [
        _palm(vm.Vector3(-3.25, sandTop, -1.3), lean: 0.4),
        _palm(vm.Vector3(2.85, sandTop, -2.35), lean: 2.4, height: 2.3),
        _palm(vm.Vector3(-1, grassTop, -2.75), lean: 1.4, height: 1.8),
        _palm(vm.Vector3(-3.5, sandTop, 1.75), lean: -0.6, height: 1.6),
        _palm(vm.Vector3(3.55, sandTop, 0.4), lean: 3.4, height: 1.7),
        _rockAt(vm.Vector3(2.9, sandTop, 2.3), 0.3),
        _rockAt(vm.Vector3(3.15, sandTop, 2), 0.18),
        _rockAt(vm.Vector3(-2.6, sandTop, 2.7), 0.26),
        _rockAt(vm.Vector3(0.9, sandTop, 3.6), 0.2),
        _bushAt(vm.Vector3(0.6, grassTop, 1.95)),
        _bushAt(vm.Vector3(-0.85, grassTop, 2.15)),
        _bushAt(vm.Vector3(2.5, grassTop, -0.2)),
        _bushAt(vm.Vector3(-2.45, grassTop, -0.15)),
      ];

  Node _palm(vm.Vector3 base, {double lean = 0, double height = 2}) {
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
    final frondMaterial = matte(_frond, roughness: 0.75)..doubleSided = true;
    final tree = Node(name: 'palm')
      ..position = base
      ..rotation = _yaw(lean)
      ..add(meshNode(trunk, matte(_bark)));

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
    for (var i = 0; i < 3; i++) {
      final angle = i / 3 * math.pi * 2;
      tree.add(
        meshNode(
          SphereGeometry(radius: 0.075, segments: 16, rings: 10),
          matte(_coconut, roughness: 0.7),
          position: top +
              vm.Vector3(math.cos(angle) * 0.09, -0.08, math.sin(angle) * 0.09),
        ),
      );
    }

    return tree;
  }

  Node _rockAt(vm.Vector3 position, double size) => meshNode(
        reshaped(
          IcosphereGeometry(radius: size, subdivisions: 1),
          vm.Vector3(1.3, 0.75, 1),
          rotation: _yaw(position.x * 3),
        ),
        matte(_rock, roughness: 0.9),
        position: position + vm.Vector3(0, size * 0.25, 0),
      );

  Node _bushAt(vm.Vector3 position) {
    final material = matte(_bush);

    return Node(name: 'bush')
      ..position = position
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.22),
          material,
          position: vm.Vector3(0, 0.12, 0),
        ),
      )
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.16),
          material,
          position: vm.Vector3(0.2, 0.08, 0.05),
        ),
      )
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.15),
          material,
          position: vm.Vector3(-0.18, 0.07, 0.08),
        ),
      );
  }

  Node _foodTruck() {
    final wheel = matte(_navy, roughness: 0.6);

    return Node(name: 'shop')
      ..add(
        _box(vm.Vector3(1, 0.55, 0.58), _white, vm.Vector3(-0.1, 0.42, 0)),
      )
      ..add(
        _box(
          vm.Vector3(0.36, 0.46, 0.56),
          const Color(0xFF5CC6C9),
          vm.Vector3(0.56, 0.37, 0),
        ),
      )
      ..add(_box(vm.Vector3(0.2, 0.18, 0.5), _glass, vm.Vector3(0.66, 0.48, 0)))
      // Serving hatch facing the island centre.
      ..add(
        _box(
          vm.Vector3(0.5, 0.22, 0.04),
          _navy,
          vm.Vector3(-0.12, 0.5, -0.3),
        ),
      )
      ..add(
        _box(
          vm.Vector3(0.6, 0.04, 0.16),
          const Color(0xFFF26B5B),
          vm.Vector3(-0.12, 0.64, -0.36),
        ),
      )
      ..addAll([
        for (final x in [-0.38, 0.46])
          for (final z in [-0.29, 0.29])
            meshNode(
              CylinderGeometry(bottomRadius: 0.1, topRadius: 0.1, height: 0.08),
              wheel,
              position: vm.Vector3(x, 0.1, z),
              rotation:
                  vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
            ),
      ])
      // A giant banana on the roof.
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.42, 0.78, 0),
              vm.Vector3(-0.2, 0.84, 0),
              vm.Vector3(0.05, 0.86, 0),
              vm.Vector3(0.28, 0.98, 0),
            ]),
            radius: 0.075,
            stations: 20,
          ),
          matte(_banana, roughness: 0.55),
        ),
      );
  }

  Node _accessoriesShop() {
    final shop = Node(name: 'accessories')
      ..add(
        _box(
          vm.Vector3(0.9, 0.62, 0.7),
          const Color(0xFFF4A6A6),
          vm.Vector3(0, 0.31, 0),
        ),
      )
      ..add(_box(vm.Vector3(1, 0.08, 0.8), _white, vm.Vector3(0, 0.66, 0)))
      ..add(
        _box(vm.Vector3(0.22, 0.36, 0.04), _navy, vm.Vector3(0, 0.18, 0.36)),
      )
      ..add(
        _box(
          vm.Vector3(0.22, 0.2, 0.04),
          _glass,
          vm.Vector3(-0.3, 0.38, 0.36),
        ),
      )
      ..add(
        _box(
          vm.Vector3(0.22, 0.2, 0.04),
          _glass,
          vm.Vector3(0.3, 0.38, 0.36),
        ),
      );
    // Striped awning above the door.
    for (var i = 0; i < 5; i++) {
      shop.add(
        _box(
          vm.Vector3(0.18, 0.03, 0.22),
          i.isEven ? const Color(0xFF5CC6C9) : _white,
          vm.Vector3(-0.36 + i * 0.18, 0.54, 0.44),
          tilt: 0.45,
        ),
      );
    }
    // A big cap on the roof, like the shop's sign.
    const cap = Color(0xFF4D7CF0);

    return shop
      ..add(
        meshNode(
          SphereGeometry(radius: 0.2),
          matte(cap, roughness: 0.6),
          position: vm.Vector3(0, 0.72, 0),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            CylinderGeometry(bottomRadius: 0.2, topRadius: 0.2, height: 0.03),
            vm.Vector3(1, 1, 1.4),
          ),
          matte(cap, roughness: 0.6),
          position: vm.Vector3(0, 0.73, 0.14),
        ),
      );
  }

  Node _airport() => Node(name: 'airport')
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.17, topRadius: 0.14, height: 1.1),
        matte(_white),
        position: vm.Vector3(0, 0.55, 0),
      ),
    )
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.24, topRadius: 0.3, height: 0.22),
        matte(_glass, roughness: 0.2),
        position: vm.Vector3(0, 1.21, 0),
      ),
    )
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.32, topRadius: 0.05, height: 0.16),
        matte(const Color(0xFFF26B5B)),
        position: vm.Vector3(0, 1.4, 0),
      ),
    )
    ..add(_box(vm.Vector3(0.9, 0.42, 0.6), _white, vm.Vector3(0.62, 0.21, 0.1)))
    ..add(
      _box(vm.Vector3(0.7, 0.3, 0.04), _navy, vm.Vector3(0.62, 0.17, 0.41)),
    );

  Node _gym() => Node(name: 'gym')
    ..add(
      _box(
        vm.Vector3(0.95, 0.58, 0.8),
        const Color(0xFFF29E4C),
        vm.Vector3(0, 0.29, 0),
      ),
    )
    ..add(_box(vm.Vector3(1.02, 0.07, 0.86), _white, vm.Vector3(0, 0.615, 0)))
    ..add(_box(vm.Vector3(0.26, 0.34, 0.04), _navy, vm.Vector3(0, 0.17, 0.41)))
    // A dumbbell sign on the roof.
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.035, topRadius: 0.035, height: 0.7),
        matte(_navy),
        position: vm.Vector3(0, 0.82, 0),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
      ),
    )
    ..addAll([
      for (final x in [-0.3, 0.3])
        meshNode(
          CylinderGeometry(bottomRadius: 0.16, topRadius: 0.16, height: 0.1),
          matte(_navy),
          position: vm.Vector3(x, 0.82, 0),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
        ),
    ]);

  Node _adoptionHut() => Node(name: 'adoption')
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.45, topRadius: 0.42, height: 0.5),
        matte(const Color(0xFFC8955F)),
        position: vm.Vector3(0, 0.25, 0),
      ),
    )
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.64, topRadius: 0, height: 0.55),
        matte(const Color(0xFFE8C468)),
        position: vm.Vector3(0, 0.77, 0),
      ),
    )
    ..add(_box(vm.Vector3(0.2, 0.32, 0.04), _navy, vm.Vector3(0, 0.16, 0.44)));

  Node _box(
    vm.Vector3 size,
    Color color,
    vm.Vector3 position, {
    double tilt = 0,
  }) =>
      meshNode(
        reshaped(
          CuboidGeometry(vm.Vector3.all(1)),
          size,
          rotation: tilt == 0
              ? null
              : vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), tilt),
        ),
        matte(color, roughness: 0.7),
        position: position,
      );
}

vm.Quaternion _yaw(double angle) =>
    vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle);

/// A tapered plateau whose outline follows [radius] (by angle), with a flat
/// top at [top] and walls flaring out by [bottomScale] down to [bottom].
MeshGeometry _plateau({
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
