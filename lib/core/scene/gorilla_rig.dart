import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _fur = Color(0xFF302F36);
const _skin = Color(0xFFA9A7BD);
const _eyeWhite = Color(0xFFFAFAFF);
const _pupil = Color(0xFF15141A);
const _hatPink = Color(0xFFF0707E);
const _hatWhite = Color(0xFFF4F1EA);
const _hatPompom = Color(0xFFF5C343);

// Bone lengths, in the rig's local units (the gorilla is ~1.6 long).
const _torsoLength = 0.72;
const _upperArm = 0.44;
const _forearm = 0.42;
const _thigh = 0.32;
const _shin = 0.31;
const _shoulderWidth = 0.30;
const _hipWidth = 0.20;

/// What the gorilla is doing; poses blend smoothly between these.
enum GorillaActivity { idle, pushups, walking }

/// A stylized gorilla assembled from primitives and posed procedurally.
///
/// Local space: +Z is where the gorilla faces, +Y is up, the ground is y = 0.
/// Add [root] to a scene, then call [update] every frame.
class GorillaRig {
  GorillaRig() {
    final fur = matte(_fur);
    final skin = matte(_skin, roughness: 0.7);

    _hips = meshNode(SphereGeometry(radius: 0.30), fur);
    _torso = meshNode(CapsuleGeometry(radius: 0.31, height: _torsoLength), fur);
    _chest = meshNode(SphereGeometry(radius: 0.40), fur);
    _belly = meshNode(SphereGeometry(radius: 0.24), skin);

    for (final _ in [0, 1]) {
      _upperArms.add(
        meshNode(CapsuleGeometry(radius: 0.13, height: _upperArm), fur),
      );
      _forearms.add(
        meshNode(CapsuleGeometry(radius: 0.12, height: _forearm), fur),
      );
      _hands.add(meshNode(SphereGeometry(radius: 0.125), skin));
      _thighs.add(meshNode(CapsuleGeometry(radius: 0.14, height: _thigh), fur));
      _shins.add(meshNode(CapsuleGeometry(radius: 0.12, height: _shin), fur));
      _feet.add(
        meshNode(
          reshaped(SphereGeometry(radius: 0.12), vm.Vector3(1, 0.75, 1.35)),
          skin,
        ),
      );
    }

    _head = Node(name: 'head')
      ..scale = vm.Vector3.all(1.25)
      ..addAll(_buildHead(fur, skin));
    _hat = _buildPartyHat()..visible = false;
    _head.add(_hat);

    root
      ..add(_hips)
      ..add(_torso)
      ..add(_chest)
      ..add(_belly)
      ..add(_head)
      ..addAll(_upperArms)
      ..addAll(_forearms)
      ..addAll(_hands)
      ..addAll(_thighs)
      ..addAll(_shins)
      ..addAll(_feet);

    update(0);
  }

  /// Place, rotate and scale this node to put the gorilla in a scene.
  final Node root = Node(name: 'gorilla');

  /// What the gorilla should be doing; the pose eases into it.
  GorillaActivity activity = GorillaActivity.idle;

  /// Whether the gorilla is currently at the bottom of a pushup.
  bool inPushup = false;

  /// Whether to wear the party hat.
  bool get partyHat => _hat.visible;
  set partyHat(bool value) => _hat.visible = value;

  late final Node _hips;
  late final Node _torso;
  late final Node _chest;
  late final Node _belly;
  late final Node _head;
  late final Node _hat;
  late final List<Node> _eyesOpen;
  late final List<Node> _eyesClosed;
  final _upperArms = <Node>[];
  final _forearms = <Node>[];
  final _hands = <Node>[];
  final _thighs = <Node>[];
  final _shins = <Node>[];
  final _feet = <Node>[];

  double _time = 0;
  double _depth = 0;
  double _walkPhase = 0;
  final _weights = <GorillaActivity, double>{
    GorillaActivity.idle: 1,
    GorillaActivity.pushups: 0,
    GorillaActivity.walking: 0,
  };

  List<Node> _buildHead(Material fur, Material skin) {
    final eyeWhite = matte(_eyeWhite, roughness: 0.25);
    final pupil = matte(_pupil, roughness: 0.2);

    _eyesOpen = [
      for (final side in [-1.0, 1.0]) ...[
        meshNode(
          SphereGeometry(radius: 0.058, segments: 20, rings: 12),
          eyeWhite,
          position: vm.Vector3(0.085 * side, 0.05, 0.255),
        ),
        meshNode(
          SphereGeometry(radius: 0.03, segments: 16, rings: 10),
          pupil,
          position: vm.Vector3(0.088 * side, 0.052, 0.305),
        ),
      ],
    ];
    _eyesClosed = [
      for (final side in [-1.0, 1.0])
        meshNode(
          CapsuleGeometry(radius: 0.012, height: 0.08, radialSegments: 8),
          pupil,
          position: vm.Vector3(0.085 * side, 0.045, 0.300),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
        )..visible = false,
    ];

    return [
      meshNode(SphereGeometry(radius: 0.30), fur),
      // Face mask and muzzle.
      meshNode(
        reshaped(SphereGeometry(radius: 0.2), vm.Vector3(1.05, 0.95, 0.75)),
        skin,
        position: vm.Vector3(0, -0.01, 0.15),
      ),
      meshNode(
        reshaped(SphereGeometry(radius: 0.14), vm.Vector3(1.15, 0.8, 0.9)),
        skin,
        position: vm.Vector3(0, -0.11, 0.21),
      ),
      for (final side in [-1.0, 1.0])
        meshNode(
          SphereGeometry(radius: 0.018, segments: 12, rings: 8),
          matte(_pupil),
          position: vm.Vector3(0.035 * side, -0.085, 0.335),
        ),
      // Brow ridge.
      meshNode(
        CapsuleGeometry(radius: 0.045, height: 0.2),
        fur,
        position: vm.Vector3(0, 0.12, 0.215),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
      ),
      // Tuft on top of the head.
      meshNode(
        CylinderGeometry(bottomRadius: 0.13, topRadius: 0, height: 0.22),
        fur,
        position: vm.Vector3(0, 0.3, -0.02),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.35),
      ),
      for (final side in [-1.0, 1.0])
        meshNode(
          SphereGeometry(radius: 0.075),
          skin,
          position: vm.Vector3(0.28 * side, 0.02, -0.02),
        ),
      ..._eyesOpen,
      ..._eyesClosed,
    ];
  }

  Node _buildPartyHat() {
    final hat = Node(name: 'party-hat')
      ..position = vm.Vector3(0.06, 0.29, 0.04)
      ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -0.3);
    const height = 0.42;
    const bottomRadius = 0.15;
    const bands = 5;
    for (var i = 0; i < bands; i++) {
      final r0 = bottomRadius * (1 - i / bands);
      final r1 = bottomRadius * (1 - (i + 1) / bands);
      hat.add(
        meshNode(
          CylinderGeometry(
            bottomRadius: r0,
            topRadius: r1,
            height: height / bands,
            bottomCap: i == 0,
            topCap: false,
          ),
          matte(i.isEven ? _hatPink : _hatWhite, roughness: 0.6),
          position: vm.Vector3(0, height / bands * (i + 0.5), 0),
        ),
      );
    }

    return hat
      ..add(
        meshNode(
          SphereGeometry(radius: 0.05),
          matte(_hatPompom, roughness: 0.9),
          position: vm.Vector3(0, height, 0),
        ),
      );
  }

  /// Advances the animation by [deltaSeconds] and re-poses every part.
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    for (final entry in GorillaActivity.values) {
      _weights[entry] = springTo(
        _weights[entry]!,
        entry == activity ? 1 : 0,
        deltaSeconds,
        5,
      );
    }
    _depth = springTo(_depth, inPushup ? 1 : 0, deltaSeconds, 14);
    _walkPhase += deltaSeconds * 5.5 * _weights[GorillaActivity.walking]!;

    final pose = _Pose.blend([
      (_Pose.idle(_time), _weights[GorillaActivity.idle]!),
      (_Pose.pushup(_depth), _weights[GorillaActivity.pushups]!),
      (_Pose.walk(_walkPhase), _weights[GorillaActivity.walking]!),
    ]);
    _apply(pose);
    _blink();
  }

  void _apply(_Pose pose) {
    // The torso axis, tipped up from +Z by the body pitch, and its normal.
    final along =
        vm.Vector3(0, math.sin(pose.bodyPitch), math.cos(pose.bodyPitch));
    final bodyUp =
        vm.Vector3(0, math.cos(pose.bodyPitch), -math.sin(pose.bodyPitch));
    final pelvis = pose.pelvis;
    final shoulders = pelvis + along * _torsoLength;
    final breath = 1 + 0.025 * math.sin(_time * 2.4);

    _hips.position = pelvis;
    placeBetween(_torso, pelvis, shoulders);
    _chest
      ..position = shoulders - along * 0.08 + bodyUp * 0.04
      ..scale = vm.Vector3.all(breath);
    _belly.position = pelvis + along * 0.36 - bodyUp * 0.2;

    final neck = shoulders + along * 0.3 + bodyUp * 0.3;
    // The head is not parented to the torso, so it faces +Z by default; a
    // positive nod tips the face down.
    final facing = vm.Vector3(
      math.sin(pose.headYaw) * math.cos(pose.headNod),
      -math.sin(pose.headNod),
      math.cos(pose.headYaw) * math.cos(pose.headNod),
    );
    _head
      ..position = neck
      ..rotation = vm.Quaternion.fromTwoVectors(vm.Vector3(0, 0, 1), facing);

    for (var i = 0; i < 2; i++) {
      final side = i == 0 ? -1.0 : 1.0;
      final lateral = vm.Vector3(side, 0, 0);

      final shoulder = shoulders + lateral * _shoulderWidth - bodyUp * 0.05;
      final (elbow, hand) = solveTwoBone(
        shoulder,
        pose.hands[i],
        _upperArm,
        _forearm,
        lateral * 0.6 - along,
      );
      placeBetween(_upperArms[i], shoulder, elbow);
      placeBetween(_forearms[i], elbow, hand);
      _hands[i].position = hand + vm.Vector3(0, 0.06, 0);

      final hip = pelvis + lateral * _hipWidth;
      final (knee, foot) = solveTwoBone(
        hip,
        pose.feet[i],
        _thigh,
        _shin,
        lateral * 0.4 + pose.kneeBend,
      );
      placeBetween(_thighs[i], hip, knee);
      placeBetween(_shins[i], knee, foot);
      _feet[i].position = foot + vm.Vector3(0, 0.05, 0.05);
    }
  }

  void _blink() {
    // A quick blink every ~3.7 seconds.
    final closed = (_time % 3.7) < 0.12;
    for (final eye in _eyesOpen) {
      eye.visible = !closed;
    }
    for (final eye in _eyesClosed) {
      eye.visible = closed;
    }
  }
}

class _Pose {
  _Pose({
    required this.pelvis,
    required this.bodyPitch,
    required this.hands,
    required this.feet,
    vm.Vector3? kneeBend,
    this.headYaw = 0,
    this.headNod = 0,
  }) : kneeBend = kneeBend ?? vm.Vector3(0, 0, 1);

  /// Standing on all fours, breathing and glancing around.
  factory _Pose.idle(double time) {
    final sway = math.sin(time * 1.2) * 0.015;

    return _Pose(
      pelvis: vm.Vector3(sway, 0.52 + math.sin(time * 2.4) * 0.01, -0.36),
      bodyPitch: 0.42,
      hands: [vm.Vector3(-0.34, 0, 0.42), vm.Vector3(0.34, 0, 0.42)],
      feet: [vm.Vector3(-0.24, 0, -0.38), vm.Vector3(0.24, 0, -0.38)],
      headYaw: math.sin(time * 0.6) * 0.45,
      headNod: math.sin(time * 0.9) * 0.06,
    );
  }

  /// A plank pivoting on the toes; [depth] 0 is arms extended, 1 is down.
  factory _Pose.pushup(double depth) {
    const toes = -1.02;
    // Just short of the full leg length, so the legs stay nearly straight.
    const toeToPelvis = _thigh + _shin - 0.02;
    final angle = _lerp(0.5, 0.17, depth);
    final line = vm.Vector3(0, math.sin(angle), math.cos(angle));

    return _Pose(
      pelvis: vm.Vector3(0, 0, toes) + line * toeToPelvis,
      bodyPitch: angle,
      hands: [vm.Vector3(-0.42, 0, 0.12), vm.Vector3(0.42, 0, 0.12)],
      feet: [vm.Vector3(-0.15, 0, toes), vm.Vector3(0.15, 0, toes)],
      // Knees sag towards the floor instead of folding forwards.
      kneeBend: vm.Vector3(0, -1, 0),
      // Glance towards the camera (on the +X side) between reps.
      headYaw: 0.55,
      headNod: _lerp(0.15, 0.3, depth),
    );
  }

  /// Knuckle-walking; [phase] advances one stride per 2π.
  factory _Pose.walk(double phase) {
    vm.Vector3 step(double x, double z, double offset) {
      final s = phase + offset;

      return vm.Vector3(
        x,
        math.max(0, math.sin(s)) * 0.1,
        z + math.cos(s) * 0.14,
      );
    }

    return _Pose(
      pelvis: vm.Vector3(0, 0.53 + math.sin(phase * 2) * 0.02, -0.36),
      bodyPitch: 0.4,
      hands: [step(-0.32, 0.42, 0), step(0.32, 0.42, math.pi)],
      feet: [step(-0.24, -0.38, math.pi), step(0.24, -0.38, 0)],
      headNod: math.sin(phase * 2) * 0.05,
    );
  }

  factory _Pose.blend(List<(_Pose, double)> weighted) {
    final total = weighted.fold<double>(0, (sum, e) => sum + e.$2);
    vm.Vector3 mix(vm.Vector3 Function(_Pose) pick) => weighted.fold(
          vm.Vector3.zero(),
          (sum, e) => sum + pick(e.$1) * (e.$2 / total),
        );
    double mixValue(double Function(_Pose) pick) =>
        weighted.fold(0, (sum, e) => sum + pick(e.$1) * (e.$2 / total));

    return _Pose(
      pelvis: mix((p) => p.pelvis),
      bodyPitch: mixValue((p) => p.bodyPitch),
      hands: [mix((p) => p.hands[0]), mix((p) => p.hands[1])],
      feet: [mix((p) => p.feet[0]), mix((p) => p.feet[1])],
      kneeBend: mix((p) => p.kneeBend),
      headYaw: mixValue((p) => p.headYaw),
      headNod: mixValue((p) => p.headNod),
    );
  }

  final vm.Vector3 pelvis;
  final double bodyPitch;
  final List<vm.Vector3> hands;
  final List<vm.Vector3> feet;
  final vm.Vector3 kneeBend;
  final double headYaw;
  final double headNod;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
