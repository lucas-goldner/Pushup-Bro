import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart' show yaw;
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

/// A gym buddy: their look, the exercise they do at their station (in view
/// space: x sideways, z depth away from the camera, turned `turn` radians
/// from facing the camera), and where they unroll their mat to do pushups
/// alongside Carlos.
typedef _Look = ({
  Color fur,
  Color face,
  Color mat,
  GorillaActivity exercise,
  (double, double) station,
  double turn,
  (double, double) pushupSpot,
});

const _buddies = <_Look>[
  (
    fur: Color(0xFFC27A3A),
    face: Color(0xFFF2D2B0),
    mat: Color(0xFFF59AB0),
    exercise: GorillaActivity.deadlift,
    station: (0.95, 4.6),
    turn: -0.3,
    pushupSpot: (0.8, 1.9),
  ),
  (
    fur: Color(0xFFE6E4EE),
    face: Color(0xFFF7D9DE),
    mat: Color(0xFF7DD9B5),
    exercise: GorillaActivity.benchPress,
    station: (-0.8, 5.4),
    // Side on, so the press reads in profile.
    turn: math.pi / 2,
    pushupSpot: (-0.8, 1.9),
  ),
  (
    fur: Color(0xFF6B4A3A),
    face: Color(0xFFD9B99B),
    mat: Color(0xFFF6CF5C),
    exercise: GorillaActivity.gobletSquat,
    station: (0.6, 6.9),
    turn: -0.15,
    pushupSpot: (0.45, 3.3),
  ),
  (
    fur: Color(0xFF56637F),
    face: Color(0xFFC9D3E6),
    mat: Color(0xFFB7A6F2),
    exercise: GorillaActivity.curls,
    station: (-0.55, 7.4),
    turn: 0.2,
    pushupSpot: (-0.45, 3.3),
  ),
];

/// How fast (m/s) the buddies run to fetch their mats and back.
const _runSpeed = 1.9;

/// How long everyone dances after a set.
const _danceSeconds = 3.2;

/// Where the buddies fetch their mats from: just off either side of the
/// screen.
const _exitX = 3.2;
const _exitZ = -2.6;

/// The home screen's gym: Carlos on his mat at the origin, with gym buddies
/// in different colours working out around the room: deadlifts, bench
/// press, goblet squats and curls, each at their own pace.
///
/// When a set starts they drop their weights, run off to fetch their mats,
/// unroll them around Carlos and do every pushup in step with him. When it
/// ends, everyone dances, then the buddies take their mats away and go back
/// to their stations.
///
/// Build it once the engine is ready, add [root] to a scene and call
/// [update] every frame.
class GymWorld {
  GymWorld() {
    // A frame whose -Z points away from the camera, so the room and the
    // stations are laid out in screen terms whichever way the camera looks.
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

    for (final (i, look) in _buddies.indexed) {
      final rig = GorillaRig(
        furColor: look.fur,
        faceColor: look.face,
        timeOffset: i * 1.7 + 0.6,
      );
      final station = vm.Vector3(look.station.$1, 0, -look.station.$2);
      final (equipment, weights) = _stationKit(look.exercise);
      _view.add(
        Node(name: 'station')
          ..position = station
          ..rotation = yaw(look.turn)
          ..addAll(equipment),
      );
      final roll = _rolledMat(look.mat)..visible = false;
      final mat = _mat(
        look.mat,
        vm.Vector3(look.pushupSpot.$1, 0, -look.pushupSpot.$2),
        size: 0.8,
      )..visible = false;
      _view
        ..addAll([for (final weight in weights) weight.node])
        ..add(roll)
        ..add(mat)
        ..add(rig.root);
      _crew.add(
        _GymBuddy(
          rig: rig,
          exercise: look.exercise,
          station: station,
          turn: look.turn,
          pushupSpot: vm.Vector3(look.pushupSpot.$1, 0, -look.pushupSpot.$2),
          exitX: look.pushupSpot.$1.sign * _exitX,
          weights: weights,
          roll: roll,
          mat: mat,
          // Everyone keeps their own pace until they join Carlos.
          repSeconds: 2.1 + i * 0.37,
        ),
      );
    }
  }

  final Node root = Node(name: 'gym');

  /// The player's gorilla, in front of everyone.
  final GorillaRig carlos = GorillaRig();
  final _crew = <_GymBuddy>[];
  late final Node _view;

  bool _tracking = false;
  bool _inPushup = false;
  double _carlosDance = 0;

  /// Carlos holds a plank while a set is being tracked, and the buddies
  /// join in; when it ends, everyone celebrates.
  bool get tracking => _tracking;
  set tracking(bool value) {
    if (value == _tracking) return;
    _tracking = value;
    if (value) {
      _carlosDance = 0;
      carlos.activity = GorillaActivity.pushups;
      for (final buddy in _crew) {
        buddy.joinPushups();
      }
    } else {
      _carlosDance = _danceSeconds;
      carlos.activity = GorillaActivity.dance;
      for (final buddy in _crew) {
        buddy.celebrate();
      }
    }
  }

  /// Carlos dips on every rep, and every buddy on their mat dips with him.
  bool get inPushup => _inPushup;
  set inPushup(bool value) {
    _inPushup = value;
    carlos.inPushup = value;
  }

  void update(double deltaSeconds) {
    if (_carlosDance > 0) {
      _carlosDance -= deltaSeconds;
      if (_carlosDance <= 0) carlos.activity = GorillaActivity.idle;
    }
    carlos.update(deltaSeconds);
    for (final buddy in _crew) {
      buddy.update(deltaSeconds, inPushup: _inPushup);
    }
  }

  /// The static equipment for [exercise]'s station (in station space), and
  /// the weights the buddy lifts (placed by [_GymBuddy] in view space).
  (List<Node>, List<_Weight>) _stationKit(GorillaActivity exercise) =>
      switch (exercise) {
        GorillaActivity.deadlift => (
            [_platform()],
            [_Weight(_barbell(0.8, 0.105), restHeight: 0.105)],
          ),
        GorillaActivity.benchPress => (
            [_pressBench()],
            // Racked on the bench's uprights between sets.
            [_Weight(_barbell(0.9, 0.09), rack: vm.Vector3(0, 0.8, -0.42))],
          ),
        GorillaActivity.curls => (
            [_mat(const Color(0xFFB7A6F2), vm.Vector3.zero(), size: 0.7)],
            [
              for (final hand in [0, 1])
                _Weight(
                  _handDumbbell(const Color(0xFF5E9EFF)),
                  hand: hand,
                  restHeight: 0.05,
                ),
            ],
          ),
        GorillaActivity.gobletSquat => (
            [_mat(const Color(0xFF7DD9B5), vm.Vector3.zero(), size: 0.7)],
            // Hanging by its handle between the paws.
            [
              _Weight(
                _kettlebell(const Color(0xFFF5C343)),
                gripOffset: vm.Vector3(0, -0.3, 0),
              ),
            ],
          ),
        _ => (const [], const []),
      };

  /// A mat rolled up across X, for carrying.
  Node _rolledMat(Color color) => Node(name: 'rolled-mat')
    ..add(
      meshNode(
        CylinderGeometry(
          bottomRadius: 0.09,
          topRadius: 0.09,
          height: 0.7,
          radialSegments: 24,
        ),
        matte(color, roughness: 0.7),
        rotation: vm.Quaternion.fromTwoVectors(
          vm.Vector3(0, 1, 0),
          vm.Vector3(1, 0, 0),
        ),
      ),
    );

  /// A barbell [length] long across X, centred on its grip, with plates of
  /// [plateRadius].
  Node _barbell(double length, double plateRadius) {
    final across = vm.Quaternion.fromTwoVectors(
      vm.Vector3(0, 1, 0),
      vm.Vector3(1, 0, 0),
    );
    final plates = matte(_rubber);

    return Node(name: 'barbell')
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.014,
            topRadius: 0.014,
            height: length,
          ),
          matte(_steel, roughness: 0.25)..metallicFactor = 0.8,
          rotation: across,
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            CylinderGeometry(
              bottomRadius: plateRadius,
              topRadius: plateRadius,
              height: 0.05,
              radialSegments: 24,
            ),
            plates,
            position: vm.Vector3(side * (length / 2 - 0.1), 0, 0),
            rotation: across,
          ),
          meshNode(
            CylinderGeometry(
              bottomRadius: plateRadius * 0.7,
              topRadius: plateRadius * 0.7,
              height: 0.04,
              radialSegments: 24,
            ),
            matte(_bag, roughness: 0.5),
            position: vm.Vector3(side * (length / 2 - 0.145), 0, 0),
            rotation: across,
          ),
        ],
      ]);
  }

  /// A rubber lifting platform with a wooden centre.
  Node _platform() => Node(name: 'platform')
    ..add(_box(vm.Vector3(1.2, 0.03, 0.9), _rubber, vm.Vector3(0, 0.015, 0.05)))
    ..add(
      _box(
        vm.Vector3(0.5, 0.035, 0.88),
        const Color(0xFFE2BE95),
        vm.Vector3(0, 0.018, 0.05),
      ),
    );

  /// A flat bench running along Z, sized for a baby gorilla, with uprights
  /// at the head end (-Z).
  Node _pressBench() {
    final steel = matte(_steel, roughness: 0.35)..metallicFactor = 0.6;

    return Node(name: 'press-bench')
      ..add(_box(vm.Vector3(0.34, 0.07, 1), _navy, vm.Vector3(0, 0.205, -0.1)))
      ..addAll([
        for (final z in [-0.5, 0.3])
          _box(vm.Vector3(0.26, 0.17, 0.06), _steel, vm.Vector3(0, 0.085, z)),
        for (final x in [-0.27, 0.27])
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.05, 0.85, 0.05),
            ),
            steel,
            position: vm.Vector3(x, 0.425, -0.42),
          ),
      ]);
  }

  /// A small dumbbell held by its handle, which runs across X.
  Node _handDumbbell(Color color) {
    final weight = matte(color, roughness: 0.5);
    final across = vm.Quaternion.fromTwoVectors(
      vm.Vector3(0, 1, 0),
      vm.Vector3(1, 0, 0),
    );

    return Node(name: 'hand-dumbbell')
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.016, topRadius: 0.016, height: 0.2),
          matte(_steel, roughness: 0.3),
          rotation: across,
        ),
      )
      ..addAll([
        for (final x in [-0.085, 0.085])
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.05,
              topRadius: 0.05,
              height: 0.05,
              radialSegments: 6,
            ),
            weight,
            position: vm.Vector3(x, 0, 0),
            rotation: across,
          ),
      ]);
  }

  Node _mat(Color color, vm.Vector3 at, {double size = 1}) => meshNode(
        reshaped(
          CylinderGeometry(radialSegments: 48),
          vm.Vector3(size, 0.02, 1.8 * size),
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
    const far = -18.0;
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
    const z = -9.5;
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
    const z = -8.6;

    return [
      _dumbbellRack()..position = vm.Vector3(-1.9, 0, z),
      _barbellRack()..position = vm.Vector3(1.9, 0, z),
      _punchingBag()..position = vm.Vector3(-3.6, 0, z + 0.4),
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

/// Something a buddy lifts: held in a hand ([hand]) or both (the grip
/// between them), and put down on the floor at [restHeight] or back on a
/// [rack] (in station space).
class _Weight {
  _Weight(
    this.node, {
    this.hand,
    this.restHeight = 0,
    this.rack,
    vm.Vector3? gripOffset,
  }) : gripOffset = gripOffset ?? vm.Vector3.zero();

  final Node node;
  final int? hand;
  final double restHeight;
  final vm.Vector3? rack;
  final vm.Vector3 gripOffset;

  bool held = true;
  vm.Vector3 rest = vm.Vector3.zero();
  vm.Vector3 from = vm.Vector3.zero();

  /// Progress of the latest drop or pick-up, 0 to 1.
  double moved = 1;
}

/// One step of a buddy's routine; returns true once it is finished.
typedef _Step = bool Function(double deltaSeconds);

/// A gym buddy's routine: working out at their station until a set starts,
/// then fetching their mat to do pushups with Carlos, and back again.
///
/// Everything lives in the gym's view space (see [gymToWorld]).
class _GymBuddy {
  _GymBuddy({
    required this.rig,
    required this.exercise,
    required this.station,
    required this.turn,
    required this.pushupSpot,
    required this.exitX,
    required this.weights,
    required this.roll,
    required this.mat,
    required this.repSeconds,
  })  : _position = station.clone(),
        _heading = turn {
    rig
      ..activity = exercise
      ..settle();
  }

  final GorillaRig rig;
  final GorillaActivity exercise;
  final vm.Vector3 station;
  final double turn;
  final vm.Vector3 pushupSpot;
  final double exitX;
  final List<_Weight> weights;
  final Node roll;
  final Node mat;
  final double repSeconds;

  vm.Vector3 _position;
  double _heading;
  double _time = 0;
  bool _holding = true;
  bool _carrying = false;
  bool _matDown = false;
  bool _withCarlos = false;
  final List<_Step> _steps = [];

  /// Drop the weights, fetch the mat and do pushups next to Carlos.
  void joinPushups() {
    _steps.clear();
    _withCarlos = true;
    if (_holding) _steps.add(_dropWeights());
    if (_matDown) {
      _steps.add(_instant(() => rig.activity = GorillaActivity.pushups));
      return;
    }
    if (!_carrying) {
      _steps
        ..add(_run(vm.Vector3(exitX, 0, _exitZ)))
        ..add(_instant(() => _carrying = true));
    }
    _steps
      ..add(_run(pushupSpot))
      ..add(_unrollMat());
  }

  /// Dance, then take the mat away and get back to the weights.
  void celebrate() {
    _steps.clear();
    _withCarlos = false;
    final matOut = _matDown || _carrying;
    _steps.add(
      _timed(
        _danceSeconds,
        start: () {
          rig.activity = GorillaActivity.dance;
        },
      ),
    );
    if (_matDown) _steps.add(_rollMat());
    if (matOut) {
      _steps
        ..add(_run(vm.Vector3(exitX, 0, _exitZ)))
        ..add(_instant(() => _carrying = false));
    }
    if (_holding) {
      _steps.add(_instant(() => rig.activity = exercise));
    } else {
      _steps
        ..add(_run(station))
        ..add(_pickUpWeights());
    }
  }

  void update(double deltaSeconds, {required bool inPushup}) {
    _time += deltaSeconds;
    if (_steps.isNotEmpty && _steps.first(deltaSeconds)) _steps.removeAt(0);
    // Reps in step with Carlos on the mat; at their own pace at the
    // station.
    rig.inPushup =
        _withCarlos ? inPushup : (_time % repSeconds) > repSeconds / 2;

    rig.root
      ..position = _position
      ..rotation = yaw(_heading);
    rig.update(deltaSeconds);

    final grip = (rig.hand(0) + rig.hand(1)) * 0.5;
    for (final weight in weights) {
      final hand = weight.hand;
      final held =
          _toView(hand == null ? grip : rig.hand(hand)) + weight.gripOffset;
      final target = weight.held ? held : weight.rest;
      weight.moved = math.min(1, weight.moved + deltaSeconds / 0.35);
      // Eased in, like falling or a heave up.
      final t = weight.moved * weight.moved;
      weight.node.position = weight.from + (target - weight.from) * t;
      if (weight.held) weight.node.rotation = yaw(_heading);
    }
    roll
      ..visible = _carrying
      ..position = _toView(grip)
      ..rotation = yaw(_heading);
  }

  vm.Vector3 _toView(vm.Vector3 local) {
    final c = math.cos(_heading);
    final s = math.sin(_heading);

    return _position +
        vm.Vector3(
          local.x * c + local.z * s,
          local.y,
          -local.x * s + local.z * c,
        );
  }

  _Step _instant(void Function() action) => (_) {
        action();
        return true;
      };

  _Step _timed(
    double seconds, {
    void Function()? start,
    void Function(double t)? tick,
    void Function()? end,
  }) {
    var elapsed = -1.0;

    return (deltaSeconds) {
      if (elapsed < 0) {
        elapsed = 0;
        start?.call();
      }
      elapsed += deltaSeconds;
      final t = math.min(1, elapsed / seconds).toDouble();
      tick?.call(t);
      if (t < 1) return false;
      end?.call();
      return true;
    };
  }

  _Step _run(vm.Vector3 to) => (deltaSeconds) {
        rig
          ..activity =
              _carrying ? GorillaActivity.carrying : GorillaActivity.walking
          ..walkSpeed = 2.2;
        final offset = to - _position;
        final distance = offset.length;
        final step = _runSpeed * deltaSeconds;
        if (distance <= step) {
          _position = to.clone();
          return true;
        }
        _position += offset * (step / distance);
        _heading = _turnTowards(math.atan2(offset.x, offset.z), deltaSeconds);
        return false;
      };

  double _turnTowards(double target, double deltaSeconds) {
    var delta = (target - _heading) % (math.pi * 2);
    if (delta > math.pi) delta -= math.pi * 2;

    return _heading + delta * math.min(1, deltaSeconds * 10);
  }

  _Step _dropWeights() => _timed(
        0.35,
        start: () {
          _holding = false;
          for (final weight in weights) {
            final rack = weight.rack;
            final position = weight.node.position.clone();
            weight
              ..held = false
              ..from = position
              ..moved = 0
              ..rest = rack != null
                  ? station + _rotate(rack, turn)
                  : (position..y = weight.restHeight);
          }
        },
      );

  _Step _pickUpWeights() => _timed(
        0.45,
        start: () {
          _heading = turn;
          rig.activity = exercise;
          for (final weight in weights) {
            weight
              ..held = true
              ..from = weight.node.position.clone()
              ..moved = 0;
          }
        },
        end: () => _holding = true,
      );

  _Step _unrollMat() => _timed(
        0.45,
        start: () {
          _heading = 0;
          _carrying = false;
          _matDown = true;
          rig.activity = GorillaActivity.pushups;
          mat.visible = true;
        },
        tick: (t) => mat.scale = vm.Vector3(1, 1, math.max(0.05, t)),
      );

  _Step _rollMat() => _timed(
        0.4,
        start: () => rig.activity = GorillaActivity.idle,
        tick: (t) => mat.scale = vm.Vector3(1, 1, math.max(0.05, 1 - t)),
        end: () {
          mat.visible = false;
          _matDown = false;
          _carrying = true;
        },
      );
}

vm.Vector3 _rotate(vm.Vector3 v, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);

  return vm.Vector3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
}
