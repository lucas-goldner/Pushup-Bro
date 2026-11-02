import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/critters.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
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

  // The storm's props.
  final Node _bolt = Node(name: 'lightning');
  final Node _tornado = Node(name: 'tornado');
  final List<Node> _funnel = [];
  final List<Node> _debris = [];
  final Node _twinkle = Node(name: 'twinkle');
  final Node _crab = Node(name: 'crab');
  final Node _beachBanana = Node(name: 'beach-banana');

  /// The palm the lightning hits.
  late final Node _struckPalm;

  /// Where the huts' doors are, for the tribe to run to.
  final List<vm.Vector3> _doors = [];

  /// Where each of the tribe was when they started running.
  final List<vm.Vector3> _fled = [];

  IntroSet _set = IntroSet.village;
  IntroSet get set => _set;

  /// How far the storm has got, one step per line:
  /// 0 the lightning strikes a palm and the rain pours,
  /// 1 the tribe runs for the huts,
  /// 2 a tornado shows up on the far side of the clearing,
  /// 3 it reaches Carlos and starts to lift him,
  /// 4 he spins up inside it, banana and all,
  /// 5 it flings him far away over the trees.
  int get stormStage => _stormStage;
  int _stormStage = 0;
  double _stageTime = 0;

  /// When each stage began, for the ones that carry on from the last.
  double _carlosSpin = 0;
  vm.Vector3 _flungFrom = vm.Vector3.zero();

  set stormStage(int stage) {
    if (stage == _stormStage) return;
    if (stage == 5) _flungFrom = carlos.root.position.clone();
    if (stage == 1) {
      _fled
        ..clear()
        ..addAll(tribe.map((monkey) => monkey.root.position.clone()));
    }
    _stormStage = stage;
    _stageTime = 0;
  }

  /// The tornado's foot, on the ground.
  vm.Vector3 get tornadoFoot => _tornado.position;

  /// Where Carlos was flung to, high over the trees.
  static final flungTo = vm.Vector3(9, 9, -26);

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
    _banana.visible = false;
    _bolt.visible = false;
    _tornado.visible = false;
    _twinkle.visible = false;
    carlos.root
      ..rotation = vm.Quaternion.identity()
      ..visible = true;
    for (final monkey in [gus, ...tribe]) {
      monkey.root.visible = set != IntroSet.beach;
    }
    switch (set) {
      case IntroSet.village:
        carlos.rig
          ..activity = GorillaActivity.pushups
          ..settle();
        carlos.root.position = carlosHome.clone();
      case IntroSet.storm:
        _stormStage = 0;
        _stageTime = 0;
        _carlosSpin = 0;
        carlos.rig
          ..activity = GorillaActivity.walking
          ..walkSpeed = 0;
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
    _stageTime += deltaSeconds;
    switch (_set) {
      case IntroSet.village:
        _villageLife(time);
      case IntroSet.storm:
        _storm(time, deltaSeconds);
      case IntroSet.beach:
        _beachLife(time);
    }
    carlos.update(deltaSeconds);
    if (_set == IntroSet.beach) {
      // The village is hidden: nothing there needs to move.
      coco.update(deltaSeconds);
      return;
    }
    for (final (i, flame) in _flames.indexed) {
      final flicker = 1 + 0.18 * math.sin(time * 13 + i * 2.1);
      // The rain beats the fire down.
      final rained = _set == IntroSet.storm ? 0.35 : 1.0;
      flame.scale = vm.Vector3(1, flicker * rained, 1);
    }
    _jungle.update(deltaSeconds * (_set == IntroSet.storm ? 4 : 1));
    gus.update(deltaSeconds);
    for (final monkey in tribe) {
      if (monkey.root.visible) monkey.update(deltaSeconds);
    }
  }

  /// The tribe dances round the fire; Carlos does pushups in front.
  void _villageLife(double time) {
    carlos.rig.inPushup = math.sin(time * 4.2) > 0;
    _danceRound(time, wild: false);
  }

  /// Where Gus stands: by the fire, facing the camera, keeping an eye on
  /// everyone.
  static final gusSpot = vm.Vector3(-1.5, 0, 0.6);

  /// The tribe dances (or waves goodbye in the storm) in a ring round the
  /// fire; Gus leads from beside it.
  void _danceRound(double time, {required bool wild}) {
    for (final (i, monkey) in tribe.indexed) {
      final a = i / tribe.length * math.pi * 2 + time * (wild ? 0 : 0.35);
      const ring = 1.35;
      monkey.root
        ..position =
            fire + vm.Vector3(math.sin(a) * ring, 0, math.cos(a) * ring)
        ..rotation = yaw(a + math.pi);
      monkey.rig.activity = wild ? GorillaActivity.wave : GorillaActivity.dance;
    }
    gus.root
      ..position = gusSpot
      ..rotation = yaw(0.5)
      ..scale = vm.Vector3.all(1.25);
    gus.rig.activity = wild ? GorillaActivity.wave : GorillaActivity.dance;
  }

  /// The storm, stage by stage (see [stormStage]).
  void _storm(double time, double deltaSeconds) {
    final t = _stageTime;
    // The wind: palms bend and whip, harder once the tornado is here.
    final gust = _stormStage >= 2 ? 1.6 : 1.0;
    for (final (i, palm) in _palms.indexed) {
      if (palm == _struckPalm && _stormStage == 0 && t > 0.5) continue;
      if (palm == _struckPalm && _stormStage > 0) continue;
      palm.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 0, 1),
        (-0.22 - 0.14 * math.sin(time * 5 + i)) * gust,
      );
    }
    _strike(t);
    _panic(t);
    _whirl(time);
    _carlosInStorm(t, deltaSeconds);
  }

  /// Stage 0: a bolt hits a palm, which topples over.
  void _strike(double t) {
    if (_stormStage != 0) {
      _bolt.visible = false;
      return;
    }
    // Two flickers, as lightning does.
    _bolt.visible = (t > 0.5 && t < 0.72) || (t > 0.82 && t < 0.92);
    if (t > 0.5) {
      final fall = math.min(1, (t - 0.5) / 0.9);
      _struckPalm.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 0, 1),
        -1.35 * fall * fall,
      );
    }
    // Everyone jumps at the bang.
    final startled = t > 0.55 && t < 1.6;
    for (final monkey in [gus, ...tribe]) {
      monkey.rig.activity =
          startled ? GorillaActivity.dance : GorillaActivity.wave;
    }
  }

  /// Stage 1 on: the tribe runs into the huts (and stays there); Gus waves
  /// them in, then waves at Carlos to come too.
  void _panic(double t) {
    if (_stormStage == 0) {
      _danceRound(0, wild: true);
      return;
    }
    for (final (i, monkey) in tribe.indexed) {
      final from = _fled.length > i ? _fled[i] : monkey.root.position;
      final door = _doors[i % _doors.length];
      final run = _stormStage == 1 ? math.min(1, t / 1.8) : 1.0;
      if (run >= 1) {
        monkey.root.visible = false;
        continue;
      }
      final heading = door - from;
      monkey.root
        ..visible = true
        ..position = from + heading * run.toDouble()
        ..rotation = yaw(math.atan2(heading.x, heading.z));
      monkey.rig
        ..activity = GorillaActivity.walking
        ..walkSpeed = 2.6;
    }
    gus.root
      ..position = gusSpot
      ..rotation = yaw(0.5);
    gus.rig.activity = GorillaActivity.wave;
  }

  /// Stage 2 on: the tornado sweeps in from the far side of the clearing
  /// and parks over Carlos; its rings spin and wobble, debris whirls round.
  void _whirl(double time) {
    if (_stormStage < 2) {
      _tornado.visible = false;
      return;
    }
    _tornado.visible = true;
    final start = vm.Vector3(-6.5, 0, -5);
    final end = carlosHome + vm.Vector3(-0.15, 0, -0.1);
    final travel = switch (_stormStage) {
      2 => math.min(1, _stageTime / 4) * 0.35,
      3 => 0.35 + math.min(1, _stageTime / 1.6) * 0.65,
      _ => 1.0,
    };
    final eased = travel * travel * (3 - 2 * travel);
    _tornado.position = start + (end - start) * eased;
    for (final (i, ring) in _funnel.indexed) {
      final h = i / _funnel.length;
      ring
        ..rotation = yaw(time * (6 + i * 0.7))
        ..position = vm.Vector3(
          math.sin(time * 2.1 + i * 0.6) * 0.18 * h,
          ring.position.y,
          math.cos(time * 1.7 + i * 0.5) * 0.18 * h,
        );
    }
    for (final (i, bit) in _debris.indexed) {
      final h = 0.4 + (i % 6) * 0.6;
      final r = 0.5 + h * 0.32;
      final a = time * (4 + i % 3) + i * 1.3;
      bit
        ..position = vm.Vector3(math.sin(a) * r, h, math.cos(a) * r)
        ..rotation = vm.Quaternion.axisAngle(
          vm.Vector3(1, 1, 0)..normalize(),
          time * 7 + i,
        );
    }
  }

  /// Carlos: watching the sky, then grabbed by the tornado, spun up
  /// inside it, and flung far away. He only turns round his middle, so he
  /// never dips into the ground.
  void _carlosInStorm(double t, double deltaSeconds) {
    final rig = carlos.rig;
    switch (_stormStage) {
      case 0 || 1 || 2:
        carlos.root
          ..position = carlosHome
          ..rotation = yaw(_stormStage == 2 ? -0.9 : 0.25);
        rig
          ..activity = _stormStage == 0 && t > 0.55 && t < 1.4
              ? GorillaActivity.dance
              : GorillaActivity.walking
          ..walkSpeed = 0;
        _banana.visible = false;
      case 3:
        // Pulled off his feet, legs flailing, still on the spot.
        final lift = math.min(1, t / 1.6).toDouble();
        _carlosSpin += deltaSeconds * (2 + lift * 6);
        carlos.root
          ..position = carlosHome +
              vm.Vector3(
                math.sin(_carlosSpin) * 0.25 * lift,
                0.35 * lift * lift,
                math.cos(_carlosSpin) * 0.25 * lift,
              )
          ..rotation = yaw(_carlosSpin);
        rig.activity = GorillaActivity.wave;
        _holdBanana();
      case 4:
        // Round and round, up inside the funnel.
        final up = math.min(1, t / 3).toDouble();
        _carlosSpin += deltaSeconds * 8;
        final r = 0.35 + up * 0.7;
        carlos.root
          ..position = _tornado.position +
              vm.Vector3(
                math.sin(_carlosSpin) * r,
                0.35 + up * 2.6,
                math.cos(_carlosSpin) * r,
              )
          ..rotation = yaw(_carlosSpin * 1.5) *
              vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.5 * up);
        rig.activity = GorillaActivity.dance;
        _holdBanana();
      default:
        // Flung out of the top and away, over the trees, until he is a
        // twinkle in the sky.
        final fly = math.min(1, t / 1.4).toDouble();
        final arc = _flungFrom +
            (flungTo - _flungFrom) * fly +
            vm.Vector3(0, math.sin(fly * math.pi) * 3, 0);
        _carlosSpin += deltaSeconds * 14;
        carlos.root
          ..visible = fly < 1
          ..position = arc
          ..rotation = vm.Quaternion.axisAngle(
            vm.Vector3(0.4, 0.3, 1)..normalize(),
            _carlosSpin,
          );
        _banana.visible = fly < 1;
        _banana
          ..position = arc + vm.Vector3(0.5 + fly, 0.2, 0)
          ..rotation = yaw(_carlosSpin * 2);
        final glint = ((t - 1.4) / 0.6).clamp(0.0, 1.0);
        _twinkle
          ..visible = glint > 0 && glint < 1
          ..position = flungTo
          ..scale = vm.Vector3.all(math.sin(glint * math.pi) * 1.4 + 0.001)
          ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), glint * 3);
    }
  }

  /// The banana stays in his paw, waving round with him.
  void _holdBanana() {
    _banana
      ..visible = true
      ..position = carlos.root.position + vm.Vector3(0.35, 0.75, 0.1)
      ..rotation = yaw(_carlosSpin);
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
    // A crab scuttles sideways across the sand and back.
    final scuttle = math.sin(time * 0.6);
    _crab
      ..position = vm.Vector3(-1.4 + scuttle * 0.9, 0, 1.5)
      ..rotation = yaw(math.pi / 2 + math.sin(time * 9) * 0.08);
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
    // Everything that never moves, merged into a few meshes below.
    final still = Node(name: 'village-still')
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

    // The campfire: a ring of stones and crossed logs; the flames move.
    for (var i = 0; i < 9; i++) {
      final a = i / 9 * math.pi * 2;
      still.add(
        rock(0.16, turn: i * 1.3)
          ..position =
              fire + vm.Vector3(math.sin(a) * 0.42, 0, math.cos(a) * 0.42),
      );
    }
    final wood = matte(const Color(0xFF7A4A2A));
    for (var i = 0; i < 3; i++) {
      still.add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.05, topRadius: 0.05, height: 0.62),
          wood,
          position: fire + vm.Vector3(0, 0.08, 0),
          rotation: yaw(i * math.pi / 3) *
              vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2.3),
        ),
      );
    }

    // Two huts behind the fire, the tribe's shelter in the storm.
    for (final (x, z, turn) in [(-2.6, -2.6, 0.5), (2.5, -2.9, -0.4)]) {
      still.add(
        _hut()
          ..position = vm.Vector3(x, 0, z)
          ..rotation = yaw(turn),
      );
      _doors.add(
        vm.Vector3(x, 0, z) +
            vm.Vector3(math.sin(turn), 0, math.cos(turn)) * 0.8,
      );
    }

    // A pile of bananas: it's banana night.
    for (var i = 0; i < 7; i++) {
      still.add(
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
    for (var i = 0; i < 10; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final r = 2.8 + random.nextDouble() * 2;
      still.add(
        (i.isEven ? fern(random) : flowers(random))
          ..position = vm.Vector3(math.sin(a) * r, 0, math.cos(a) * r + 0.6),
      );
    }
    bakeStatic(still, shadowStatic: true);

    final village = Node(name: 'village')..add(still);
    _jungle = JunglePatch(radius: 7.5, clearing: true, seed: 9);
    village.add(_jungle.root..position = vm.Vector3(0, -0.14, -4.5));

    // The flames, flickering (and beaten down by the rain).
    final fireNode = Node(name: 'fire')..position = fire;
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

    // Palms at the edge of the clearing, for the storm to whip about; the
    // lightning hits the one on the right.
    for (final (x, z) in [(-3.6, 0.6), (3.8, 0.2), (-4.4, -1.6), (4.6, -2.0)]) {
      final palm = palmTree(lean: 0.1, height: 2.4)
        ..position = vm.Vector3(x, 0, z);
      _palms.add(palm);
      village.add(palm);
    }
    _struckPalm = _palms[1];

    village
      ..add(gus.root)
      ..addAll(tribe.map((monkey) => monkey.root))
      ..add(
        _banana
          ..add(banana()..scale = vm.Vector3.all(0.55))
          ..visible = false,
      )
      ..add(_buildBolt(_struckPalm.position + vm.Vector3(0, 2.3, 0)))
      ..add(_buildTornado())
      ..add(_buildTwinkle());

    return village;
  }

  /// A jagged bolt from the sky down to [target].
  Node _buildBolt(vm.Vector3 target) {
    final glow = UnlitMaterial()
      ..baseColorFactor = linearColor(const Color(0xFFFFF6B0));
    final random = math.Random(2);
    var from = target + vm.Vector3(-1.2, 9, -3);
    for (var i = 1; i <= 7; i++) {
      final t = i / 7;
      final to = i == 7
          ? target
          : (target + vm.Vector3(-1.2, 9, -3) * (1 - t)) +
              vm.Vector3(
                (random.nextDouble() - 0.5) * 0.9,
                0,
                (random.nextDouble() - 0.5) * 0.5,
              );
      final segment = meshNode(
        CylinderGeometry(
          bottomRadius: 0.07 - t * 0.03,
          topRadius: 0.07 - t * 0.03,
        ),
        glow,
      );
      placeBetween(segment, from, to);
      _bolt.add(segment);
      from = to;
    }

    return _bolt..visible = false;
  }

  /// A cartoon tornado: stacked grey rings, wider at the top, each turning
  /// at its own speed, with leaves and twigs whirling round it.
  Node _buildTornado() {
    const rings = 11;
    for (var i = 0; i < rings; i++) {
      final h = i / (rings - 1);
      final shade = Color.lerp(
        const Color(0xFF6E7890),
        const Color(0xFFB4BCCB),
        h,
      )!;
      final ring = Node(name: 'funnel')
        ..position = vm.Vector3(0, 0.15 + h * 4.4, 0)
        ..add(
          meshNode(
            TorusGeometry(
              radius: 0.22 + h * h * 1.5,
              tubeRadius: 0.16 + h * 0.22,
              tubularSegments: 18,
            ),
            matte(shade, roughness: 0.9),
            rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
          ),
        );
      _funnel.add(ring);
      _tornado.add(ring);
    }
    final leaf = matte(const Color(0xFF4F9A48));
    final twig = matte(const Color(0xFF7A4A2A));
    for (var i = 0; i < 14; i++) {
      final bit = meshNode(
        CuboidGeometry(
          i.isEven ? vm.Vector3(0.16, 0.02, 0.1) : vm.Vector3(0.24, 0.03, 0.03),
        ),
        i.isEven ? leaf : twig,
      );
      _debris.add(bit);
      _tornado.add(bit);
    }

    return _tornado..visible = false;
  }

  /// The cartoon "ping" where Carlos disappears into the sky.
  Node _buildTwinkle() {
    final shine = UnlitMaterial()
      ..baseColorFactor = linearColor(const Color(0xFFFFFFFF));
    for (var i = 0; i < 4; i++) {
      _twinkle.add(
        meshNode(
          reshaped(
            SphereGeometry(segments: 8, rings: 4),
            vm.Vector3(0.06, 0.7, 0.06),
          ),
          shine,
          rotation: vm.Quaternion.axisAngle(
            vm.Vector3(0, 0, 1),
            i * math.pi / 4,
          ),
        ),
      );
    }

    return _twinkle..visible = false;
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
    final still = Node(name: 'beach-still')
      // The sea all the way to the horizon.
      ..add(
        meshNode(
          DiscGeometry(radius: 120, segments: 48),
          matte(const Color(0xFF3FA9D8), roughness: 0.6),
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
            segments: 48,
          ),
          matte(const Color(0xFFF2DCA6), roughness: 0.95),
          position: vm.Vector3(0, -0.02, -4),
        ),
      )
      // Green behind the beach: the island's jungle starts there.
      ..add(
        meshNode(
          plateau(
            radius: (a) => 6 + math.sin(a * 5) * 0.5,
            top: 0.25,
            bottom: -0.3,
            bottomScale: 1.15,
            segments: 40,
          ),
          matte(const Color(0xFF5DA84E), roughness: 0.95),
          position: vm.Vector3(0, 0, -11),
        ),
      );

    // A treeline of jungle and palms along the back of the beach.
    for (var i = 0; i < 9; i++) {
      final x = -7 + i * 1.75 + random.nextDouble() * 0.6;
      final z = -6.4 - random.nextDouble() * 1.6;
      still.add(
        (i.isEven
            ? broadleafTree(random, height: 2.4 + random.nextDouble())
            : palmTree(
                lean: (random.nextDouble() - 0.5) * 0.4,
                height: 2.6 + random.nextDouble() * 0.8,
              ))
          ..position = vm.Vector3(x, 0.2, z),
      );
    }
    for (var i = 0; i < 8; i++) {
      still.add(
        bush(size: 0.7 + random.nextDouble() * 0.5)
          ..position =
              vm.Vector3(-6 + i * 1.7, 0.1, -5.4 - random.nextDouble()),
      );
    }
    // Palms and rocks on the beach itself.
    for (final (x, z, lean) in [
      (-2.4, -1.2, 0.25),
      (-3.4, -2.8, -0.1),
      (2.8, -2.2, -0.3),
      (4.2, -4.0, 0.1),
    ]) {
      still.add(
        palmTree(lean: lean, height: 2.2 + random.nextDouble() * 0.6)
          ..position = vm.Vector3(x, 0, z),
      );
    }
    for (var i = 0; i < 5; i++) {
      still.add(
        rock(0.2 + random.nextDouble() * 0.25, turn: i * 2.0)
          ..position = vm.Vector3(
            -3 + random.nextDouble() * 6.5,
            0,
            1.4 + random.nextDouble() * 0.8,
          ),
      );
    }
    // Washed up with him: a driftwood log, a broken plank, shells and a
    // starfish.
    final driftwood = matte(const Color(0xFFB59272));
    still
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.09, topRadius: 0.07, height: 1.6),
          driftwood,
          position: vm.Vector3(-1.9, 0.07, 0.4),
          rotation: yaw(0.4) *
              vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
        ),
      )
      ..add(
        meshNode(
          CuboidGeometry(vm.Vector3(0.9, 0.05, 0.22)),
          driftwood,
          position: vm.Vector3(1.6, 0.03, 1.3),
          rotation: yaw(-0.6),
        ),
      );
    final shells = [
      matte(const Color(0xFFFFD7C2), roughness: 0.5),
      matte(const Color(0xFFFFFFFF), roughness: 0.5),
    ];
    for (var i = 0; i < 9; i++) {
      still.add(
        meshNode(
          reshaped(
            SphereGeometry(segments: 10, rings: 6),
            vm.Vector3(0.07, 0.03, 0.06),
          ),
          shells[i % 2],
          position: vm.Vector3(
            -2.5 + random.nextDouble() * 5,
            0.01,
            0.2 + random.nextDouble() * 2,
          ),
        ),
      );
    }
    final star = matte(const Color(0xFFFF8A5B), roughness: 0.8);
    for (var arm = 0; arm < 5; arm++) {
      still.add(
        meshNode(
          reshaped(
            SphereGeometry(segments: 8, rings: 5),
            vm.Vector3(0.05, 0.025, 0.13),
          ),
          star,
          position: vm.Vector3(0.9, 0.02, 1.9) +
              vm.Vector3(
                math.sin(arm * math.pi * 2 / 5) * 0.09,
                0,
                math.cos(arm * math.pi * 2 / 5) * 0.09,
              ),
          rotation: yaw(arm * math.pi * 2 / 5),
        ),
      );
    }
    // Other islands far out at sea, and clouds over the horizon.
    for (final (x, z, size) in [(-38.0, -60.0, 7.0), (30.0, -70.0, 9.0)]) {
      still
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(segments: 20, rings: 10),
              vm.Vector3(size, size * 0.35, size * 0.6),
            ),
            matte(const Color(0xFF6FAE6A)),
            position: vm.Vector3(x, -0.5, z),
          ),
        )
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(segments: 20, rings: 10),
              vm.Vector3(size * 1.15, size * 0.12, size * 0.7),
            ),
            matte(const Color(0xFFEAD7A6)),
            position: vm.Vector3(x, -0.4, z),
          ),
        );
    }
    final cloud = UnlitMaterial()
      ..baseColorFactor = linearColor(const Color(0xFFFFFFFF));
    for (final (x, y, z) in [
      (-26.0, 13.0, -70.0),
      (-6.0, 17.0, -80.0),
      (20.0, 12.0, -65.0),
      (38.0, 16.0, -75.0),
    ]) {
      for (var puff = 0; puff < 4; puff++) {
        still.add(
          meshNode(
            reshaped(
              SphereGeometry(segments: 14, rings: 8),
              vm.Vector3(3.4 - puff * 0.4, 1.6, 1.6),
            ),
            cloud,
            position: vm.Vector3(x + puff * 2.6, y + (puff.isOdd ? 0.8 : 0), z),
          ),
        );
      }
    }
    bakeStatic(still, shadowStatic: true);

    final beach = Node(name: 'beach')..add(still);
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

    // A little red crab.
    final shell = matte(const Color(0xFFE5533D), roughness: 0.6);
    _crab
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(segments: 14, rings: 8),
            vm.Vector3(0.13, 0.07, 0.1),
          ),
          shell,
          position: vm.Vector3(0, 0.07, 0),
        ),
      )
      ..add(_eyeStalk(-0.04))
      ..add(_eyeStalk(0.04));
    for (final side in [-1.0, 1.0]) {
      _crab.add(
        meshNode(
          reshaped(
            SphereGeometry(segments: 10, rings: 6),
            vm.Vector3(0.05, 0.035, 0.04),
          ),
          shell,
          position: vm.Vector3(side * 0.15, 0.06, 0.08),
        ),
      );
    }

    // His banana made it too, of course.
    _beachBanana.add(
      banana()
        ..scale = vm.Vector3.all(0.5)
        ..rotation = yaw(0.7),
    );
    _beachBanana.position = carlosBeach + vm.Vector3(-0.75, 0.03, 0.5);

    beach
      ..add(_crab)
      ..add(_beachBanana)
      ..add(coco.root);

    return beach;
  }

  static Node _eyeStalk(double x) => Node()
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.008, topRadius: 0.008, height: 0.07),
        matte(const Color(0xFFE5533D)),
        position: vm.Vector3(x, 0.15, 0.04),
      ),
    )
    ..add(
      meshNode(
        SphereGeometry(radius: 0.018, segments: 8, rings: 6),
        matte(const Color(0xFF15141B), roughness: 0.2),
        position: vm.Vector3(x, 0.19, 0.04),
      ),
    );
}
