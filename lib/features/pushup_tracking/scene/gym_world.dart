import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _wall = Color(0xFFEEF1F7);
const _accent = Color(0xFF5E9EFF);
const _navy = Color(0xFF17203A);
const _window = Color(0xFFD6ECFF);
const _white = Color(0xFFFAFAFC);
const _steel = Color(0xFF9AA3B5);
const _rubber = Color(0xFF2C2F3A);
const _plant = Color(0xFF4CA85A);
const _pot = Color(0xFFE9D8C4);
const _bag = Color(0xFFE5534B);
const _planks = [Color(0xFFD9B48A), Color(0xFFCFA77A), Color(0xFFE2BE95)];

/// The angle (around +Y, from +Z) the home camera looks at the gym from.
const gymViewAngle = 0.8;

/// Maps a point from the camera-aligned gym frame (-Z away from the
/// camera) into world space: a turn of [gymViewAngle] around +Y.
vm.Vector3 gymToWorld(vm.Vector3 local) {
  final c = math.cos(gymViewAngle);
  final s = math.sin(gymViewAngle);

  return vm.Vector3(
    local.x * c + local.z * s,
    local.y,
    -local.x * s + local.z * c,
  );
}

/// A gym-buddy's look: fur, face and the colour of their mat.
typedef _Buddy = ({Color fur, Color face, Color mat, (double, double) spot});

// Spots are in view space: x is sideways, z is depth away from the camera.
const _buddies = <_Buddy>[
  (
    fur: Color(0xFFC27A3A),
    face: Color(0xFFF2D2B0),
    mat: Color(0xFFF59AB0),
    spot: (0.72, 2.5),
  ),
  (
    fur: Color(0xFFE6E4EE),
    face: Color(0xFFF7D9DE),
    mat: Color(0xFF7DD9B5),
    spot: (-0.72, 2.5),
  ),
  (
    fur: Color(0xFF6B4A3A),
    face: Color(0xFFD9B99B),
    mat: Color(0xFFF6CF5C),
    spot: (0.4, 4.5),
  ),
  (
    fur: Color(0xFF56637F),
    face: Color(0xFFC9D3E6),
    mat: Color(0xFFB7A6F2),
    spot: (-0.45, 4.5),
  ),
];

/// The home screen's gym: Carlos on his mat at the origin with a class of
/// differently coloured gorillas behind him who copy every rep.
///
/// Build it once the engine is ready, add [root] to a scene and call
/// [update] every frame.
class GymWorld {
  GymWorld() {
    // A frame whose -Z points away from the camera, so the room and the
    // class are laid out in screen terms whichever way the camera looks.
    _view = Node(name: 'gym-view')
      ..rotation = vm.Quaternion.fromTwoVectors(
        vm.Vector3(0, 0, 1),
        vm.Vector3(math.sin(gymViewAngle), 0, math.cos(gymViewAngle)),
      )
      ..add(_floor())
      ..add(_backWall())
      ..addAll(_equipment());
    root
      ..add(_view)
      ..add(_mat(_accent, vm.Vector3.zero()))
      ..add(carlos.root);

    for (var i = 0; i < _buddies.length; i++) {
      final buddy = _buddies[i];
      final rig = GorillaRig(
        furColor: buddy.fur,
        faceColor: buddy.face,
        timeOffset: i * 1.7 + 0.6,
      );
      final spot = gymToWorld(vm.Vector3(buddy.spot.$1, 0, -buddy.spot.$2));
      rig.root.position = spot;
      _class.add(rig);
      root
        ..add(_mat(buddy.mat, spot))
        ..add(rig.root);
    }
  }

  final Node root = Node(name: 'gym');

  /// The player's gorilla, in front of the class.
  final GorillaRig carlos = GorillaRig();
  final _class = <GorillaRig>[];
  late final Node _view;

  bool _tracking = false;
  bool _inPushup = false;

  /// Everyone holds a plank while a set is being tracked.
  bool get tracking => _tracking;
  set tracking(bool value) {
    _tracking = value;
    final activity = value ? GorillaActivity.pushups : GorillaActivity.idle;
    carlos.activity = activity;
    for (final rig in _class) {
      rig.activity = activity;
    }
  }

  /// The whole class dips together with Carlos on every rep.
  bool get inPushup => _inPushup;
  set inPushup(bool value) {
    _inPushup = value;
    carlos.inPushup = value;
    for (final rig in _class) {
      rig.inPushup = value;
    }
  }

  void update(double deltaSeconds) {
    carlos.update(deltaSeconds);
    for (final rig in _class) {
      rig.update(deltaSeconds);
    }
  }

  Node _mat(Color color, vm.Vector3 at) => meshNode(
        reshaped(
          CylinderGeometry(radialSegments: 48),
          vm.Vector3(1, 0.02, 1.8),
        ),
        matte(color, roughness: 0.7),
        position: at + vm.Vector3(0, 0.012, -0.1),
      );

  /// Wooden planks, one quad each, tinted plank by plank.
  Node _floor() {
    final builder = GeometryBuilder(deduplicate: false)
      ..normal(vm.Vector3(0, 1, 0));
    const plankWidth = 0.42;
    const halfWidth = 9.0;
    const near = 6.0;
    const far = -16.0;
    for (var i = 0; i * plankWidth < halfWidth * 2; i++) {
      final x0 = -halfWidth + i * plankWidth;
      final x1 = x0 + plankWidth;
      builder.color(linearColor(_planks[(i * 7) % _planks.length]));
      final a = builder.addVertex(vm.Vector3(x0, 0, near));
      final b = builder.addVertex(vm.Vector3(x1, 0, near));
      final c = builder.addVertex(vm.Vector3(x1, 0, far));
      final d = builder.addVertex(vm.Vector3(x0, 0, far));
      builder
        ..addTriangle(a, b, c)
        ..addTriangle(a, c, d);
    }

    return meshNode(
      builder.build(),
      PhysicallyBasedMaterial()
        ..metallicFactor = 0
        ..roughnessFactor = 0.55,
    );
  }

  Node _backWall() {
    const z = -7.5;
    final wall = Node(name: 'back-wall')
      ..add(_box(vm.Vector3(20, 9, 0.3), _wall, vm.Vector3(0, 4.5, z)))
      // A brand-blue stripe and a dark skirting board along the wall.
      ..add(
        _box(
          vm.Vector3(20, 0.45, 0.06),
          _accent,
          vm.Vector3(0, 1.35, z + 0.18),
        ),
      )
      ..add(
        _box(
          vm.Vector3(20, 0.18, 0.08),
          _navy,
          vm.Vector3(0, 0.09, z + 0.19),
        ),
      );

    // Tall windows letting in daylight.
    final glass = UnlitMaterial()..baseColorFactor = linearColor(_window);
    for (final x in [-3.6, -1.2, 1.2, 3.6]) {
      wall
        ..add(
          _box(
            vm.Vector3(1.7, 2.5, 0.08),
            _white,
            vm.Vector3(x, 3.2, z + 0.17),
          ),
        )
        ..add(
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(1.5, 2.3, 0.04),
            ),
            glass,
            position: vm.Vector3(x, 3.2, z + 0.23),
          ),
        )
        ..add(
          _box(
            vm.Vector3(0.06, 2.3, 0.06),
            _white,
            vm.Vector3(x, 3.2, z + 0.26),
          ),
        )
        ..add(
          _box(
            vm.Vector3(1.5, 0.06, 0.06),
            _white,
            vm.Vector3(x, 3.2, z + 0.26),
          ),
        );
    }

    return wall;
  }

  List<Node> _equipment() {
    const z = -6.6;

    return [
      _dumbbellRack()..position = vm.Vector3(-1.9, 0, z),
      _barbellRack()..position = vm.Vector3(1.9, 0, z),
      _punchingBag()..position = vm.Vector3(-3.6, 0, z + 0.4),
      _bench()..position = vm.Vector3(0.1, 0, z + 0.9),
      _plantPot()..position = vm.Vector3(3.5, 0, z + 0.3),
      _plantPot()..position = vm.Vector3(-0.3, 0, z - 0.2),
      for (final (x, color) in [
        (2.7, const Color(0xFFF26B5B)),
        (2.95, const Color(0xFF5CC6C9)),
        (-2.75, const Color(0xFFF5C343)),
      ])
        _kettlebell(color)..position = vm.Vector3(x, 0, z + 1.1),
    ];
  }

  Node _dumbbellRack() {
    final rack = Node(name: 'dumbbell-rack');
    final steel = matte(_steel, roughness: 0.35)..metallicFactor = 0.6;
    for (final x in [-0.75, 0.75]) {
      rack.add(
        meshNode(
          reshaped(CuboidGeometry(vm.Vector3.all(1)), vm.Vector3(0.08, 1, 0.5)),
          steel,
          position: vm.Vector3(x, 0.5, 0),
        ),
      );
    }
    const colors = [
      Color(0xFFF26B5B),
      Color(0xFF5E9EFF),
      Color(0xFFF5C343),
      Color(0xFF7DD9B5),
    ];
    for (final (row, y) in [(0, 0.42), (1, 0.82)]) {
      rack.add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(1.5, 0.05, 0.45),
          ),
          steel,
          position: vm.Vector3(0, y - 0.08, 0),
        ),
      );
      for (var i = 0; i < 3; i++) {
        rack.add(
          _dumbbell(colors[(i + row) % colors.length])
            ..position = vm.Vector3(-0.45 + i * 0.45, y, 0),
        );
      }
    }

    return rack;
  }

  Node _dumbbell(Color color) {
    final weight = matte(color, roughness: 0.5);
    final sideways = vm.Quaternion.fromTwoVectors(
      vm.Vector3(0, 1, 0),
      vm.Vector3(0, 0, 1),
    );

    return Node(name: 'dumbbell')
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.025, topRadius: 0.025, height: 0.34),
          matte(_steel, roughness: 0.3),
          rotation: sideways,
        ),
      )
      ..addAll([
        for (final z in [-0.13, 0.13])
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.08,
              topRadius: 0.08,
              height: 0.08,
              radialSegments: 6,
            ),
            weight,
            position: vm.Vector3(0, 0, z),
            rotation: sideways,
          ),
      ]);
  }

  Node _barbellRack() {
    final steel = matte(_steel, roughness: 0.35)..metallicFactor = 0.6;
    final rack = Node(name: 'barbell-rack');
    for (final x in [-0.7, 0.7]) {
      rack
        ..add(
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.08, 1.7, 0.08),
            ),
            steel,
            position: vm.Vector3(x, 0.85, 0),
          ),
        )
        ..add(
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.4, 0.04, 0.5),
            ),
            matte(_rubber),
            position: vm.Vector3(x, 0.02, 0),
          ),
        );
    }
    final across = vm.Quaternion.fromTwoVectors(
      vm.Vector3(0, 1, 0),
      vm.Vector3(1, 0, 0),
    );

    return rack
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.025, topRadius: 0.025, height: 2),
          matte(_steel, roughness: 0.25)..metallicFactor = 0.8,
          position: vm.Vector3(0, 1.35, 0.06),
          rotation: across,
        ),
      )
      ..addAll([
        for (final x in [-0.85, 0.85])
          meshNode(
            CylinderGeometry(bottomRadius: 0.24, topRadius: 0.24, height: 0.07),
            matte(_rubber),
            position: vm.Vector3(x, 1.35, 0.06),
            rotation: across,
          ),
      ]);
  }

  Node _punchingBag() => Node(name: 'punching-bag')
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.012, topRadius: 0.012, height: 0.9),
        matte(_steel, roughness: 0.3),
        position: vm.Vector3(0, 2.75, 0),
      ),
    )
    ..add(
      meshNode(
        CapsuleGeometry(radius: 0.26, height: 0.85),
        matte(_bag, roughness: 0.6),
        position: vm.Vector3(0, 1.75, 0),
      ),
    )
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.27, topRadius: 0.27, height: 0.06),
        matte(_navy),
        position: vm.Vector3(0, 2.1, 0),
      ),
    );

  Node _bench() => Node(name: 'bench')
    ..add(_box(vm.Vector3(1.3, 0.1, 0.36), _navy, vm.Vector3(0, 0.45, 0)))
    ..addAll([
      for (final x in [-0.5, 0.5])
        _box(vm.Vector3(0.08, 0.42, 0.3), _steel, vm.Vector3(x, 0.21, 0)),
    ]);

  Node _plantPot() {
    final leaves = matte(_plant);

    return Node(name: 'plant')
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.17, topRadius: 0.22, height: 0.42),
          matte(_pot),
          position: vm.Vector3(0, 0.21, 0),
        ),
      )
      ..addAll([
        for (final (x, y, z, r) in [
          (0.0, 0.62, 0.0, 0.24),
          (0.12, 0.8, 0.04, 0.17),
          (-0.1, 0.78, -0.05, 0.16),
          (0.02, 0.98, 0.0, 0.12),
        ])
          meshNode(
            IcosphereGeometry(radius: r, subdivisions: 1),
            leaves,
            position: vm.Vector3(x, y, z),
          ),
      ]);
  }

  Node _kettlebell(Color color) {
    final bell = matte(color, roughness: 0.45);

    return Node(name: 'kettlebell')
      ..add(
        meshNode(
          SphereGeometry(radius: 0.14),
          bell,
          position: vm.Vector3(0, 0.14, 0),
        ),
      )
      ..add(
        meshNode(
          TorusGeometry(radius: 0.09, tubeRadius: 0.025),
          bell,
          position: vm.Vector3(0, 0.3, 0),
          rotation: vm.Quaternion.fromTwoVectors(
            vm.Vector3(0, 1, 0),
            vm.Vector3(0, 0, 1),
          ),
        ),
      );
  }

  Node _box(vm.Vector3 size, Color color, vm.Vector3 at) => meshNode(
        reshaped(CuboidGeometry(vm.Vector3.all(1)), size),
        matte(color, roughness: 0.7),
        position: at,
      );
}
