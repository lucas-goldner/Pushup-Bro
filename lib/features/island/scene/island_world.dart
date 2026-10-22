import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/island/scene/jungle_patch.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _sea = Color(0xFF3FB2D6);
const _shallows = Color(0xFF8BDCE8);
const _foam = Color(0xFFF4FBFF);
const _sand = Color(0xFFF1DAA9);
const _grass = Color(0xFF8CCB6E);
const _white = Color(0xFFFAF8F4);
const _navy = Color(0xFF17203A);
const _glass = Color(0xFF7FC4E8);
const _banana = Color(0xFFF5C343);

const sandTop = 0.22;
const grassTop = 0.36;

/// Grass radius of a brand new island; every building adds [_growth].
const _baseRadius = 4.2;
const _growth = 0.7;
const _sandMargin = 1.3;

/// Building slots, as angles from the island's front (+Z), filled in the
/// order the buildings were bought. The jungle takes the back.
const _slots = [0.75, -0.75, 1.55, -1.55, 2.25];

/// How fast (m/s) Carlos runs to the jungle.
const _runSpeed = 2.1;

/// Something on the island placed in polar coordinates, so it moves out
/// with the coast as the island grows. `offset` is relative to the grass
/// radius; `minBuildings` hides it until the island has that many.
typedef _Prop = ({
  Node node,
  double angle,
  double offset,
  double top,
  int minBuildings,
});

/// The player's island: terrain, sea, palms, a patch of jungle, the
/// buildings they bought, and Carlos wandering around. The island grows with
/// every building. Build it once the engine is ready, add [root] to a scene
/// and call [update] every frame.
class IslandWorld {
  IslandWorld() {
    _sandNode = meshNode(_sandGeometry(_radius), _sandMaterial);
    _grassNode = meshNode(_grassGeometry(_radius), _grassMaterial);
    root
      ..add(_buildSea())
      ..add(_sandNode)
      ..add(_grassNode)
      ..add(jungle.root);
    for (final prop in _props()) {
      _scenery.add(prop);
      root.add(prop.node);
    }

    _buildings = {
      ShopBuyables.none: _foodTruck(),
      ShopBuyables.accessories: _accessoriesShop(),
      ShopBuyables.airport: _airport(),
      ShopBuyables.gym: _gym(),
      ShopBuyables.monkeyAdoption: _adoptionHut(),
    };
    for (final building in _buildings.values) {
      root.add(building..visible = false);
    }
    _buildings[ShopBuyables.none]!.visible = true;
    root.add(gorilla.root..scale = vm.Vector3.all(0.9));
    _layout();
  }

  final Node root = Node(name: 'island');
  final GorillaRig gorilla = GorillaRig();
  final JunglePatch jungle = JunglePatch();
  late final Map<ShopBuyables, Node> _buildings;
  final List<_Prop> _scenery = [];
  final PhysicallyBasedMaterial _sandMaterial = matte(_sand, roughness: 0.95);
  final PhysicallyBasedMaterial _grassMaterial = matte(_grass, roughness: 0.9);
  late final Node _sandNode;
  late final Node _grassNode;
  late final Node _foamRing;
  late final Node _shallowsRing;

  /// Buildings on the island in purchase order, the food truck first.
  List<ShopBuyables> _order = [ShopBuyables.none];
  double _radius = _baseRadius;
  double _builtRadius = _baseRadius;
  double _time = 0;
  double _lap = 0;
  double _greeting = 0;
  vm.Vector3 _greetToward = vm.Vector3(0, 0, 1);

  vm.Vector3? _runFrom;
  double _runProgress = 0;
  void Function()? _onArrive;

  /// The island's current grass radius, growing towards its target.
  double get radius => _radius;

  /// The grass radius the island grows to with its current buildings.
  double get targetRadius => _baseRadius + _growth * (_order.length - 1);

  /// Outer edge of the beach.
  double get extent => _radius + _sandMargin;

  /// The jungle's centre on the ground.
  vm.Vector3 get jungleCenter => vm.Vector3(0, grassTop, -(_radius - 1.75));

  /// The jungle's gate, where Carlos goes in.
  vm.Vector3 get jungleGate => jungleCenter + jungle.gate;

  /// Whether Carlos is on his way to the jungle.
  bool get running => _runFrom != null;

  /// Whether Carlos is stopped, waving at the camera.
  bool get greeting => _greeting > 0;

  /// The top of Carlos's head, for hanging a speech bubble over it.
  vm.Vector3 get carlosHead =>
      gorilla.root.position + vm.Vector3(0, 1.05 * gorilla.root.scale.y, 0);

  /// Whether [node] is part of Carlos.
  bool isCarlos(Node node) => _within(node, gorilla.root);

  /// Whether [node] is part of the jungle: a tree, a rock, the hill...
  bool isJungle(Node node) => _within(node, jungle.root);

  /// Stops Carlos's laps for [seconds] to turn towards [toward] (a world
  /// direction, usually the camera) and wave.
  void greet(vm.Vector3 toward, {double seconds = 3.4}) {
    if (running) return;
    _greeting = seconds;
    _greetToward = vm.Vector3(toward.x, 0, toward.z)..normalize();
  }

  static bool _within(Node node, Node ancestor) {
    for (Node? n = node; n != null; n = n.parent) {
      if (identical(n, ancestor)) return true;
    }

    return false;
  }

  /// Shows the buildings in [owned], in the order they were bought; the food
  /// truck is always there. The island grows to make room.
  void showOwned(List<ShopBuyables> owned) {
    final bought = [
      for (final item in owned)
        if (ShopBuyables.buildingsShopBuyables.contains(item)) item,
    ];
    _order = [ShopBuyables.none, ...bought.toSet()];
    for (final MapEntry(:key, :value) in _buildings.entries) {
      value.visible = _order.contains(key);
    }
    _layout();
  }

  /// Sends Carlos running to the jungle gate; [onArrive] fires once he is
  /// through it.
  void runToJungle(void Function() onArrive) {
    if (running) return;
    _runFrom = gorilla.root.position.clone();
    _runProgress = 0;
    _onArrive = onArrive;
  }

  /// Puts Carlos back on his laps, e.g. after returning from the jungle.
  void stopRun() {
    _runFrom = null;
    _onArrive = null;
    gorilla
      ..walkSpeed = 1
      ..root.visible = true;
  }

  void update(double deltaSeconds) {
    _time += deltaSeconds;

    final target = targetRadius;
    _radius = springTo(_radius, target, deltaSeconds, 1.6);
    if ((_radius - _builtRadius).abs() > 0.01) _resize();

    final runFrom = _runFrom;
    if (runFrom != null) {
      _updateRun(runFrom, deltaSeconds);
    } else if (_greeting > 0) {
      _greeting -= deltaSeconds;
      gorilla
        ..activity = GorillaActivity.wave
        ..root.rotation = vm.Quaternion.fromTwoVectors(
          vm.Vector3(0, 0, 1),
          _greetToward,
        );
    } else {
      _updateLap(deltaSeconds);
    }
    gorilla.update(deltaSeconds);
    jungle.update(deltaSeconds);

    _foamRing.scale = vm.Vector3.all(
      extent / 5.5 * (1 + 0.012 * math.sin(_time * 1.3)),
    );
  }

  void _updateLap(double deltaSeconds) {
    // Carlos walks laps in front of the jungle, pausing every so often.
    final walking = (_time % 12) < 8.5;
    gorilla.activity = walking ? GorillaActivity.walking : GorillaActivity.idle;
    if (walking) _lap += deltaSeconds * 0.32;
    final lapRadius = _radius * 0.17;
    gorilla.root
      ..position = vm.Vector3(
        math.cos(_lap) * lapRadius,
        grassTop,
        math.sin(_lap) * lapRadius + _radius * 0.22,
      )
      // Face along the lap: the tangent of the circle.
      ..rotation = vm.Quaternion.fromTwoVectors(
        vm.Vector3(0, 0, 1),
        vm.Vector3(-math.sin(_lap), 0, math.cos(_lap)),
      );
  }

  void _updateRun(vm.Vector3 from, double deltaSeconds) {
    // Run to just in front of the gate, then on through it into the trees.
    final gate = jungleGate;
    final front = gate + vm.Vector3(0, 0, 0.5);
    final inside = gate + vm.Vector3(0, jungleFloorTop, -0.7);
    final firstLeg = (front - from).length;
    final total = firstLeg + (inside - front).length;
    _runProgress += deltaSeconds * _runSpeed;
    final vm.Vector3 position;
    final vm.Vector3 heading;
    if (_runProgress < firstLeg) {
      heading = front - from;
      position = from + heading.normalized() * _runProgress;
    } else {
      heading = inside - front;
      final t = ((_runProgress - firstLeg) / (total - firstLeg)).clamp(0, 1);
      position = front + heading * t.toDouble();
    }
    heading.y = 0;
    gorilla
      ..activity = GorillaActivity.walking
      ..walkSpeed = 2.2
      ..root.position = position;
    if (heading.length2 > 1e-6) {
      gorilla.root.rotation = vm.Quaternion.fromTwoVectors(
        vm.Vector3(0, 0, 1),
        heading.normalized(),
      );
    }
    if (_runProgress >= total) {
      final onArrive = _onArrive;
      _onArrive = null;
      gorilla.root.visible = false;
      onArrive?.call();
    }
  }

  /// Rebuilds the coast for the current radius and moves everything on it.
  void _resize() {
    _builtRadius = _radius;
    // A fresh mesh: swapping a primitive's geometry doesn't re-upload it.
    _sandNode.mesh = Mesh(_sandGeometry(_radius), _sandMaterial);
    _grassNode.mesh = Mesh(_grassGeometry(_radius), _grassMaterial);
    _shallowsRing.scale = vm.Vector3.all(extent / 5.5);
    _layout();
  }

  /// Places the buildings, the jungle and the scenery for the current
  /// radius.
  void _layout() {
    jungle.root.position = jungleCenter;
    for (final (i, item) in _order.indexed) {
      final angle = _slots[i % _slots.length];
      final r = _radius * 0.6;
      _buildings[item]!
        ..position =
            vm.Vector3(math.sin(angle) * r, grassTop, math.cos(angle) * r)
        // Turn the fronts mostly towards the camera.
        ..rotation =
            yaw(angle * 0.55 + (item == ShopBuyables.none ? math.pi : 0))
        ..visible = true;
    }
    final buildings = _order.length - 1;
    for (final prop in _scenery) {
      final r = _radius + prop.offset;
      prop.node
        ..visible = buildings >= prop.minBuildings
        ..position = vm.Vector3(
          math.sin(prop.angle) * r,
          prop.top,
          math.cos(prop.angle) * r,
        );
    }
  }

  MeshGeometry _sandGeometry(double grassRadius) => plateau(
        radius: (a) =>
            (grassRadius + _sandMargin) *
            (1 + 0.05 * math.sin(3 * a + 0.5) + 0.03 * math.sin(5 * a + 2)),
        top: sandTop,
        bottom: -0.4,
        bottomScale: 1.1,
      );

  MeshGeometry _grassGeometry(double grassRadius) => plateau(
        radius: (a) =>
            grassRadius *
            (1 + 0.06 * math.sin(2 * a + 1) + 0.04 * math.sin(4 * a)),
        top: grassTop,
        bottom: 0.15,
        bottomScale: 1.03,
      );

  Node _buildSea() {
    // Both rings are sized for a 5.5 m beach and scaled with the island.
    // They float well clear of the sea so they don't z-fight with it when
    // the camera pulls far back.
    _foamRing = meshNode(
      RingGeometry(innerRadius: 5.35, outerRadius: 5.95, segments: 128),
      matte(_foam, roughness: 0.6),
      position: vm.Vector3(0, 0.1, 0),
    );
    _shallowsRing = meshNode(
      RingGeometry(innerRadius: 5, outerRadius: 8.4, segments: 128),
      matte(_shallows, roughness: 0.2),
      position: vm.Vector3(0, 0.05, 0),
    );

    return Node(name: 'sea')
      ..add(
        meshNode(
          DiscGeometry(radius: 220, segments: 96),
          matte(_sea, roughness: 0.15),
        ),
      )
      ..add(_shallowsRing)
      ..add(_foamRing);
  }

  List<_Prop> _props() {
    final random = math.Random(3);
    _Prop prop(
      Node node,
      double angle,
      double offset, {
      double top = grassTop,
      int minBuildings = 0,
    }) =>
        (
          node: node,
          angle: angle,
          offset: offset,
          top: top,
          minBuildings: minBuildings,
        );

    return [
      // Palms along the beach.
      prop(palmTree(lean: 0.4), 1.15, 0.55, top: sandTop),
      prop(palmTree(lean: 3.4, height: 1.7), -1.1, 0.6, top: sandTop),
      prop(palmTree(lean: 2.4, height: 2.3), 2.05, 0.5, top: sandTop),
      prop(palmTree(lean: -0.6, height: 1.6), -2.1, 0.55, top: sandTop),
      prop(palmTree(lean: 1.2, height: 1.9), 0.42, 0.7, top: sandTop),
      prop(
        palmTree(lean: 4.1, height: 1.8),
        -0.45,
        0.65,
        top: sandTop,
        minBuildings: 1,
      ),
      prop(
        palmTree(lean: 5, height: 2.1),
        2.6,
        0.55,
        top: sandTop,
        minBuildings: 2,
      ),
      prop(
        palmTree(lean: 0.9, height: 1.7),
        -2.65,
        0.6,
        top: sandTop,
        minBuildings: 3,
      ),
      // Rocks at the water's edge.
      prop(rock(0.3, turn: 1), 0.12, 0.9, top: sandTop),
      prop(rock(0.18, turn: 2), 0.2, 1.05, top: sandTop),
      prop(rock(0.26, turn: 3), -0.25, 0.95, top: sandTop),
      prop(rock(0.22, turn: 4), 1.7, 0.95, top: sandTop, minBuildings: 2),
      prop(rock(0.2, turn: 5), -1.8, 0.9, top: sandTop, minBuildings: 4),
      // Bushes and flowers on the grass.
      prop(bush(), 0.22, -0.55),
      prop(bush(size: 0.9), -0.3, -0.5),
      prop(bush(size: 1.1), 1.15, -0.45),
      prop(bush(), -1.15, -0.5),
      prop(flowers(random), 0.05, -0.35),
      prop(flowers(random), 0.95, -0.6, minBuildings: 1),
      prop(flowers(random), -0.9, -0.65, minBuildings: 2),
      prop(bush(size: 0.8), 1.9, -0.5, minBuildings: 3),
      prop(flowers(random), -1.95, -0.55, minBuildings: 4),
      // The island fills in as it grows.
      prop(bush(size: 1.2), 0, -1.3, minBuildings: 1),
      prop(flowers(random), 1.15, -1.4, minBuildings: 1),
      prop(palmTree(lean: 2, height: 1.5), -1.15, -1.5, minBuildings: 2),
      prop(bush(size: 0.9), -1.05, -1.1, minBuildings: 2),
      prop(bush(), 1.9, -1, minBuildings: 2),
      prop(rock(0.2, mossy: true), -1.9, -1, minBuildings: 2),
      prop(flowers(random), 2.6, -1.2, minBuildings: 3),
      prop(bush(size: 1.1), -2.6, -1.2, minBuildings: 3),
      prop(palmTree(lean: 4, height: 1.4), 1.2, -1.9, minBuildings: 3),
      prop(flowers(random), -0.2, -1.8, minBuildings: 4),
      prop(rock(0.16, mossy: true), 0.45, -1.6, minBuildings: 4),
      prop(bush(size: 0.8), 2.2, -2, minBuildings: 4),
    ];
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
