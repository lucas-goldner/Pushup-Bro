import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/critters.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/features/island/scene/jungle_patch.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Where the intro is.
enum IntroSet {
  /// Banana night in the tribe's jungle village, before the storm.
  village,

  /// The storm over the village, blowing Carlos away.
  storm,

  /// The next morning, on the beach of the island he washed up on.
  beach,
}

/// The rest of the tribe, dancing round the fire.
const _kTribe = [
  MonkeyLook(fur: 'fur.cocoa', face: 'face.peach', hat: 'hat.flowers'),
  MonkeyLook(fur: 'fur.ginger', face: 'face.cream', outfit: 'outfit.lei'),
  MonkeyLook(fur: 'fur.golden', face: 'face.sand', hat: 'hat.party'),
  MonkeyLook(fur: 'fur.midnight', face: 'face.mocha', hat: 'hat.banana'),
];

/// The island intro's 3D world: the tribe's village on banana night and
/// the beach Carlos wakes up on. [set] shows one of them; the storm plays
/// in the village. Call [update] every frame with the time since the
/// current set started.
class IntroWorld {
  IntroWorld({required MonkeyLook carlosLook})
      : carlos = GorillaActor(look: carlosLook) {
    _village = _buildVillage();
    _beach = _buildBeach();
    root
      ..add(_village)
      ..add(_beach)
      ..add(carlos.root);
    show(IntroSet.village);
  }

  final Node root = Node(name: 'intro');
  final GorillaActor carlos;
  final GorillaActor gus = GorillaActor(look: kGusLook);
  final List<GorillaActor> tribe = [
    for (final look in _kTribe) GorillaActor(look: look),
  ];
  final Parrot coco = Parrot();

  late final Node _village;
  late final Node _beach;
  late final JunglePatch _jungle;
  final List<Node> _flames = [];
  final List<Node> _waves = [];
  final List<Node> _palms = [];
  final Node _banana = Node(name: 'flying-banana');

  IntroSet _set = IntroSet.village;
  IntroSet get set => _set;

  /// When the storm blew Carlos away, in seconds since the storm began;
  /// null while he is still tumbling over the village.
  double? blownAt;

  /// Sends Carlos off over the trees, [time] seconds into the storm.
  void blowAway(double time) => blownAt ??= time;

  /// What Carlos does on the beach: 0 lying in the sand, 1 sitting up,
  /// 2 standing, 3 cheering.
  int beachPose = 0;

  /// Where the tribe dances round the fire, and where Carlos does pushups.
  static final fire = vm.Vector3(0, 0, -1.2);
  static final carlosHome = vm.Vector3(0.2, 0, 1.1);
  static final carlosBeach = vm.Vector3(0, 0, 0.6);
  static final cocoBeach = vm.Vector3(1.05, 0, 0.1);

  /// Carlos's head, for framing him.
  vm.Vector3 get carlosHead =>
      carlos.root.position + vm.Vector3(0, carlos.eyeHeight * 0.8, 0);

  /// Shows [set] and puts everyone where it starts.
  void show(IntroSet set) {
    _set = set;
    _village.visible = set != IntroSet.beach;
    _beach.visible = set == IntroSet.beach;
    _banana.visible = set == IntroSet.storm;
    carlos.root.rotation = vm.Quaternion.identity();
    switch (set) {
      case IntroSet.village:
        carlos.rig
          ..activity = GorillaActivity.pushups
          ..settle();
        carlos.root.position = carlosHome.clone();
      case IntroSet.storm:
        blownAt = null;
        carlos.rig.activity = GorillaActivity.dance;
        carlos.root.position = carlosHome.clone();
      case IntroSet.beach:
        beachPose = 0;
        carlos.rig
          ..activity = GorillaActivity.benchPress
          ..inPushup = false
          ..settle();
        _layCarlos();
    }
  }

  /// Lying on his back in the sand, across the view, out cold.
  void _layCarlos() {
    // The bench press pose lies on a bench top 0.24 up; the sand is lower.
    carlos.root
      ..position = carlosBeach + vm.Vector3(0, -0.22, 0)
      ..rotation = yaw(math.pi / 2);
  }

  /// Advances everything by [deltaSeconds]; [time] is the time since the
  /// current set started.
  void update(double deltaSeconds, double time) {
    switch (_set) {
      case IntroSet.village:
        _villageLife(time);
      case IntroSet.storm:
        _storm(time);
      case IntroSet.beach:
        _beachLife(time);
    }
    for (final (i, flame) in _flames.indexed) {
      final flicker = 1 + 0.18 * math.sin(time * 13 + i * 2.1);
      flame.scale =
          vm.Vector3(1, flicker * (_set == IntroSet.storm ? 0.4 : 1), 1);
    }
    _jungle.update(deltaSeconds * (_set == IntroSet.storm ? 4 : 1));
    carlos.update(deltaSeconds);
    gus.update(deltaSeconds);
    for (final monkey in tribe) {
      monkey.update(deltaSeconds);
    }
    coco.update(deltaSeconds);
  }

  /// The tribe dances round the fire; Carlos does pushups in front.
  void _villageLife(double time) {
    carlos.rig.inPushup = math.sin(time * 4.2) > 0;
    _danceRound(time, wild: false);
  }

  /// The tribe dances (or clings on in the storm) in a ring round the fire.
  void _danceRound(double time, {required bool wild}) {
    final everyone = [gus, ...tribe];
    for (final (i, monkey) in everyone.indexed) {
      final a = i / everyone.length * math.pi * 2 + time * (wild ? 0 : 0.35);
      final ring = i == 0 ? 1.15 : 1.35;
      monkey.root
        ..position =
            fire + vm.Vector3(math.sin(a) * ring, 0, math.cos(a) * ring)
        ..rotation = yaw(a + math.pi);
      monkey.rig.activity = wild ? GorillaActivity.wave : GorillaActivity.dance;
    }
  }

  /// The storm: the trees whip about, the tribe waves goodbye and Carlos is
  /// lifted up, tumbling, and blown away over the trees with his banana.
  void _storm(double time) {
    _danceRound(0, wild: true);
    for (final (i, palm) in _palms.indexed) {
      palm.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 0, 1),
        -0.22 - 0.12 * math.sin(time * 5 + i),
      );
    }
    // Lifted off his feet, he tumbles in the wind over the village until
    // [blowAway] sends him off over the trees.
    final lift = math.min(1, math.max(0, time - 0.6) / 1.2);
    final eased = lift * lift * (3 - 2 * lift);
    final hover = carlosHome +
        vm.Vector3(
          math.sin(time * 1.7) * 0.35 * eased,
          eased * (1.4 + math.sin(time * 2.3) * 0.2),
          0,
        );
    final gone = blownAt == null ? 0.0 : math.max<double>(0, time - blownAt!);
    carlos.root
      ..position = hover + vm.Vector3(gone * gone * 3, gone * gone * 2.2, -gone)
      ..rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0.3, 0.2, 1)..normalize(),
        eased * (time * 2.2 + gone * gone * 6),
      );
    // The banana slips out of his paw and flies off on its own.
    final slip = math.max(0, time - 3.2);
    _banana
      ..position = carlos.root.position +
          vm.Vector3(0.3 + slip * 2.2, 0.5 + slip * 1.1, slip * 0.6)
      ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), time * 9);
  }

  /// Waves roll up the beach; Coco watches from her perch while Carlos
  /// comes round.
  void _beachLife(double time) {
    for (final (i, wave) in _waves.indexed) {
      final t = (time * 0.35 + i / _waves.length) % 1;
      wave.position = vm.Vector3(0, -0.04 + t * 0.03, 4.6 - t * 1.6);
    }
    coco.root
      ..position = cocoBeach
      ..rotation = yaw(-math.pi / 2.6);
    switch (beachPose) {
      case 0:
        if (carlos.rig.activity != GorillaActivity.benchPress) {
          carlos.rig.activity = GorillaActivity.benchPress;
        }
        _layCarlos();
      case 1:
        carlos.root
          ..position = carlosBeach
          ..rotation = yaw(0.35);
        carlos.rig.activity = GorillaActivity.idle;
      case 2:
        carlos.root
          ..position = carlosBeach
          ..rotation = yaw(0.2);
        carlos.rig
          ..activity = GorillaActivity.walking
          ..walkSpeed = 0;
      default:
        carlos.root
          ..position = carlosBeach
          ..rotation = yaw(0.2);
        carlos.rig.activity = GorillaActivity.dance;
    }
  }

  Node _buildVillage() {
    final random = math.Random(11);
    final village = Node(name: 'village')
      // The clearing.
      ..add(
        meshNode(
          plateau(
            radius: (a) => 18,
            top: -0.02,
            bottom: -0.6,
            bottomScale: 1,
            segments: 48,
          ),
          matte(const Color(0xFF4F9A48), roughness: 0.95),
        ),
      )
      // Trampled earth round the fire.
      ..add(
        meshNode(
          DiscGeometry(radius: 2.4, segments: 40),
          matte(const Color(0xFFB98A5A), roughness: 0.95),
          position: fire + vm.Vector3(0, 0.005, 0),
        ),
      );
    _jungle = JunglePatch(radius: 7.5, clearing: true, seed: 9);
    village.add(_jungle.root..position = vm.Vector3(0, -0.14, -4.5));

    // The campfire: a ring of stones, crossed logs and flickering flames.
    final fireNode = Node(name: 'fire')..position = fire;
    for (var i = 0; i < 9; i++) {
      final a = i / 9 * math.pi * 2;
      fireNode.add(
        rock(0.16, turn: i * 1.3)
          ..position = vm.Vector3(math.sin(a) * 0.42, 0, math.cos(a) * 0.42),
      );
    }
    final wood = matte(const Color(0xFF7A4A2A));
    for (var i = 0; i < 3; i++) {
      fireNode.add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.05, topRadius: 0.05, height: 0.62),
          wood,
          position: vm.Vector3(0, 0.08, 0),
          rotation: yaw(i * math.pi / 3) *
              vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2.3),
        ),
      );
    }
    for (final (color, size, height) in [
      (const Color(0xFFFF7A2E), 0.26, 0.62),
      (const Color(0xFFFFC23D), 0.17, 0.46),
      (const Color(0xFFFFF0A8), 0.08, 0.28),
    ]) {
      final flame = Node(name: 'flame')
        ..add(
          meshNode(
            CylinderGeometry(bottomRadius: size, topRadius: 0, height: height),
            UnlitMaterial()..baseColorFactor = linearColor(color),
            position: vm.Vector3(0, height / 2 + 0.05, 0),
          ),
        );
      _flames.add(flame);
      fireNode.add(flame);
    }
    village.add(fireNode);

    // Two huts with leafy roofs behind the fire.
    for (final (x, z, turn) in [(-2.6, -2.6, 0.5), (2.5, -2.9, -0.4)]) {
      village.add(
        _hut()
          ..position = vm.Vector3(x, 0, z)
          ..rotation = yaw(turn),
      );
    }

    // A pile of bananas: it's banana night.
    for (var i = 0; i < 7; i++) {
      village.add(
        banana()
          ..position = vm.Vector3(
            -1.6 + (i % 4) * 0.18,
            0.06 + (i ~/ 4) * 0.1,
            0.1 + (i % 3) * 0.12,
          )
          ..rotation = yaw(i * 0.9)
          ..scale = vm.Vector3.all(0.5),
      );
    }

    // Palms at the edge of the clearing, for the storm to whip about.
    for (final (x, z) in [(-3.6, 0.6), (3.8, 0.2), (-4.4, -1.6), (4.6, -2.0)]) {
      final palm = palmTree(lean: 0.1, height: 2.4)
        ..position = vm.Vector3(x, 0, z);
      _palms.add(palm);
      village.add(palm);
    }
    for (var i = 0; i < 10; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final r = 2.8 + random.nextDouble() * 2;
      village.add(
        (i.isEven ? fern(random) : flowers(random))
          ..position = vm.Vector3(math.sin(a) * r, 0, math.cos(a) * r + 0.6),
      );
    }

    village
      ..add(gus.root)
      ..addAll(tribe.map((monkey) => monkey.root))
      ..add(
        _banana
          ..add(banana()..scale = vm.Vector3.all(0.55))
          ..visible = false,
      );

    return village;
  }

  /// A round hut: mud walls, a doorway and a cone of thatch.
  Node _hut() => Node(name: 'hut')
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.75, topRadius: 0.7, height: 0.8),
        matte(const Color(0xFFC9925E)),
        position: vm.Vector3(0, 0.4, 0),
      ),
    )
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 1.05, topRadius: 0, height: 0.9),
        matte(const Color(0xFFD9B45A)),
        position: vm.Vector3(0, 1.22, 0),
      ),
    )
    ..add(
      meshNode(
        CuboidGeometry(vm.Vector3(0.34, 0.5, 0.1)),
        matte(const Color(0xFF4A3020)),
        position: vm.Vector3(0, 0.25, 0.72),
      ),
    );

  Node _buildBeach() {
    final random = math.Random(4);
    final beach = Node(name: 'beach')
      // The sea all the way to the horizon.
      ..add(
        meshNode(
          DiscGeometry(radius: 120, segments: 64),
          matte(const Color(0xFF3FA9D8), roughness: 0.15),
          position: vm.Vector3(0, -0.06, 0),
        ),
      )
      // The sand, sloping into the sea towards the camera.
      ..add(
        meshNode(
          plateau(
            radius: (a) => 7.5 + math.sin(a * 3) * 0.6,
            top: 0,
            bottom: -0.4,
            bottomScale: 1.3,
            segments: 64,
          ),
          matte(const Color(0xFFF2DCA6), roughness: 0.95),
          position: vm.Vector3(0, -0.02, -4),
        ),
      );
    // Foam rolling up the sand.
    final foam = matte(const Color(0xFFFFFFFF), roughness: 0.4);
    for (var i = 0; i < 3; i++) {
      final wave = meshNode(
        reshaped(
          SphereGeometry(rings: 6),
          vm.Vector3(6, 0.02, 0.18),
        ),
        foam,
      );
      _waves.add(wave);
      beach.add(wave);
    }
    for (final (x, z, lean) in [
      (-2.4, -1.2, 0.25),
      (-3.4, -2.8, -0.1),
      (2.8, -2.2, -0.3),
      (4.2, -4.0, 0.1),
    ]) {
      beach.add(
        palmTree(lean: lean, height: 2.2 + random.nextDouble() * 0.6)
          ..position = vm.Vector3(x, 0, z),
      );
    }
    for (var i = 0; i < 5; i++) {
      beach.add(
        rock(0.2 + random.nextDouble() * 0.25, turn: i * 2.0)
          ..position = vm.Vector3(
            -3 + random.nextDouble() * 6.5,
            0,
            1.4 + random.nextDouble() * 0.8,
          ),
      );
    }
    beach
      ..add(bush(size: 0.9)..position = vm.Vector3(-1.8, 0, -2.6))
      ..add(bush(size: 0.7)..position = vm.Vector3(1.9, 0, -3.1))
      ..add(coco.root);

    return beach;
  }
}
