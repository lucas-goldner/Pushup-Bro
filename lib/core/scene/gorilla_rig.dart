import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/costumes.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _fur = Color(0xFF3B3A45);
const _face = Color(0xFFC9C4DD);
const _eye = Color(0xFF15141B);
const _sparkle = Color(0xFFFFFFFF);
const _blush = Color(0xFFF4A3B4);

// Chibi proportions: a big head on a small round body with stubby limbs.
// The baby stands about one unit tall.
const _headRadius = 0.36;
const _torsoLength = 0.26;
const _upperArm = 0.16;
const _forearm = 0.15;
const _thigh = 0.16;
const _shin = 0.16;
const _shoulderWidth = 0.22;
const _hipWidth = 0.12;

/// What the gorilla is doing; poses blend smoothly between these.
///
/// The gym exercises ([deadlift], [benchPress], [curls], [gobletSquat])
/// follow [GorillaRig.inPushup] just like [pushups], so a whole gym can rep
/// in step. They need props (a bar, dumbbells, a bench) placed by the caller
/// using [GorillaRig.hand].
enum GorillaActivity {
  idle,
  pushups,
  walking,
  deadlift,

  /// Lying on its back with the head towards -Z, on a bench top at y 0.24.
  benchPress,
  curls,
  gobletSquat,

  /// Running with something held in front of the belly (a rolled-up mat).
  carrying,

  /// Jumping for joy with both arms waving in the air.
  dance,

  /// Standing and waving hello with its left paw.
  wave,
}

/// A cute baby gorilla assembled from primitives and posed procedurally.
///
/// Local space: +Z is where the gorilla faces, +Y is up, the ground is y = 0.
/// Add [root] to a scene, then call [update] every frame.
class GorillaRig {
  /// [furColor] and [faceColor] tint the baby; [timeOffset] shifts its idle
  /// animation so several gorillas side by side do not move in lockstep.
  GorillaRig({
    Color furColor = _fur,
    Color faceColor = _face,
    double timeOffset = 0,
    MonkeyLook? look,
  }) : _time = timeOffset {
    final fur = _furMaterial = matte(furColor, roughness: 0.75);
    final face = _faceMaterial = matte(faceColor, roughness: 0.6);

    _torso = meshNode(
      reshaped(SphereGeometry(radius: 0.27), vm.Vector3(1, 1.15, 0.92)),
      fur,
    )..add(
        // Light belly patch on the torso's front (its local +Z).
        meshNode(
          reshaped(SphereGeometry(radius: 0.19), vm.Vector3(0.95, 1.05, 0.5)),
          face,
          position: vm.Vector3(0, -0.02, 0.18),
        ),
      );

    for (final _ in [0, 1]) {
      _upperArms.add(
        meshNode(CapsuleGeometry(radius: 0.075, height: _upperArm), fur),
      );
      _forearms.add(
        meshNode(CapsuleGeometry(radius: 0.075, height: _forearm), fur),
      );
      _hands.add(meshNode(SphereGeometry(radius: 0.085), face));
      _thighs.add(
        meshNode(CapsuleGeometry(radius: 0.085, height: _thigh), fur),
      );
      _shins.add(meshNode(CapsuleGeometry(radius: 0.085, height: _shin), fur));
      _feet.add(
        meshNode(
          reshaped(SphereGeometry(radius: 0.09), vm.Vector3(1, 0.7, 1.35)),
          face,
        ),
      );
    }

    final gorillaEyes = _buildEyes(
      openAt: (side) => vm.Vector3(0.088 * side, 0.045, 0.372),
      radius: 0.058,
    );
    final lizardEyes = _buildEyes(
      openAt: (side) => vm.Vector3(0.15 * side, 0.14, 0.3),
      radius: 0.07,
    );
    _eyesOpen = [...gorillaEyes.open, ...lizardEyes.open];
    _eyesClosed = [...gorillaEyes.closed, ...lizardEyes.closed];
    _gorillaHead
      ..addAll(_buildHead(fur, face))
      ..addAll(gorillaEyes.open)
      ..addAll(gorillaEyes.closed);
    _lizardHead
      ..addAll(_buildLizardHead(fur, face))
      ..addAll(lizardEyes.open)
      ..addAll(lizardEyes.closed)
      ..visible = false;
    _tail = _buildTail(fur)..visible = false;
    _head = Node(name: 'head')
      ..add(_gorillaHead)
      ..add(_lizardHead)
      ..add(_hatSlot)
      ..add(_eyewearSlot);
    _torso
      ..add(_outfitSlot)
      ..add(_tail);
    for (final (i, forearm) in _forearms.indexed) {
      forearm.add(_forearmSlots[i]);
    }

    root
      ..add(_torso)
      ..add(_head)
      ..addAll(_upperArms)
      ..addAll(_forearms)
      ..addAll(_hands)
      ..addAll(_thighs)
      ..addAll(_shins)
      ..addAll(_feet);

    if (look != null) this.look = look;
    update(0);
  }

  /// Place, rotate and scale this node to put the gorilla in a scene.
  final Node root = Node(name: 'gorilla');

  /// What the gorilla should be doing; the pose eases into it.
  GorillaActivity activity = GorillaActivity.idle;

  /// Whether the gorilla is currently at the bottom of a pushup.
  bool inPushup = false;

  /// Stride rate while walking; above 1 the waddle becomes a run.
  double walkSpeed = 1;

  /// Where hand [index] (0 is the gorilla's right, on -X) currently is, in
  /// [root]'s space.
  vm.Vector3 hand(int index) => _hands[index].position;

  /// Jumps straight to [activity]'s pose instead of easing into it.
  void settle() {
    for (final entry in GorillaActivity.values) {
      _weights[entry] = entry == activity ? 1 : 0;
    }
    update(0);
  }

  /// The gorilla's colours and costume. Its mat is the caller's (see
  /// [buildMat]).
  MonkeyLook get look => _look;
  set look(MonkeyLook value) {
    if (value == _look && _dressed) return;
    _dressed = true;
    _look = value;
    _furMaterial.baseColorFactor = linearColor(value.furColor);
    _faceMaterial.baseColorFactor = linearColor(value.faceColor);
    final lizard = value.species == MonkeyLook.lizard;
    _gorillaHead.visible = !lizard;
    _lizardHead.visible = lizard;
    _tail.visible = lizard;
    // The lizard's eyes sit wider and higher; its head is flatter.
    _eyewearSlot
      ..position = lizard ? vm.Vector3(0, 0.095, -0.075) : vm.Vector3.zero()
      ..scale = lizard ? vm.Vector3(1.6, 1, 1) : vm.Vector3.all(1);
    _hatSlot.position = lizard ? vm.Vector3(0, -0.035, 0) : vm.Vector3.zero();
    _dress(_hatSlot, [buildHat(value.hat)].nonNulls.toList());
    _dress(
      _eyewearSlot,
      [buildEyewear(value.eyewear)].nonNulls.toList(),
    );
    final outfit = buildOutfit(value.outfit);
    _dress(_outfitSlot, outfit.torso);
    for (final (i, slot) in _forearmSlots.indexed) {
      _dress(slot, [if (i < outfit.forearms.length) outfit.forearms[i]]);
    }
    _spinners
      ..clear()
      ..addAll(_findSpinners(_hatSlot));
  }

  MonkeyLook _look = const MonkeyLook();
  bool _dressed = false;
  late final PhysicallyBasedMaterial _furMaterial;
  late final PhysicallyBasedMaterial _faceMaterial;
  final Node _hatSlot = Node(name: 'hat');
  final Node _eyewearSlot = Node(name: 'eyewear');
  final Node _outfitSlot = Node(name: 'outfit');
  final List<Node> _forearmSlots = [Node(), Node()];
  final List<Node> _spinners = [];

  late final Node _torso;
  late final Node _head;
  final Node _gorillaHead = Node(name: 'gorilla-head');
  final Node _lizardHead = Node(name: 'lizard-head');
  late final Node _tail;
  late final List<Node> _eyesOpen;
  late final List<Node> _eyesClosed;
  final _upperArms = <Node>[];
  final _forearms = <Node>[];
  final _hands = <Node>[];
  final _thighs = <Node>[];
  final _shins = <Node>[];
  final _feet = <Node>[];

  double _time;
  double _depth = 0;
  double _walkPhase = 0;
  final _weights = <GorillaActivity, double>{
    for (final activity in GorillaActivity.values)
      activity: activity == GorillaActivity.idle ? 1 : 0,
  };

  /// Eyes at [openAt] (by side), with happy "^ ^" arcs for blinking.
  ({List<Node> open, List<Node> closed}) _buildEyes({
    required vm.Vector3 Function(double side) openAt,
    required double radius,
  }) {
    final eye = matte(_eye, roughness: 0.08);
    final sparkle = UnlitMaterial()..baseColorFactor = linearColor(_sparkle);
    final dark = matte(_eye, roughness: 0.4);

    return (
      open: [
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            SphereGeometry(radius: radius, segments: 24),
            eye,
            position: openAt(side),
          ),
          meshNode(
            SphereGeometry(radius: radius * 0.33, segments: 12, rings: 8),
            sparkle,
            position: openAt(side) +
                vm.Vector3(radius * 0.35, radius * 0.43, radius * 0.83),
          ),
        ],
      ],
      closed: [
        for (final side in [-1.0, 1.0])
          meshNode(
            TubeGeometry(
              CatmullRomPath([
                openAt(side) +
                    vm.Vector3(-radius * 0.78, -radius * 0.26, 0.028),
                openAt(side) + vm.Vector3(0, radius * 0.26, 0.038),
                openAt(side) + vm.Vector3(radius * 0.78, -radius * 0.26, 0.028),
              ]),
              radius: 0.011,
              radialSegments: 8,
              stations: 12,
            ),
            dark,
          )..visible = false,
      ],
    );
  }

  List<Node> _buildHead(Material fur, Material face) {
    final dark = matte(_eye, roughness: 0.4);

    return [
      meshNode(
        SphereGeometry(radius: _headRadius, segments: 40, rings: 24),
        fur,
      ),
      // A heart-shaped face: two brow lobes over a wide muzzle.
      for (final side in [-1.0, 1.0])
        meshNode(
          SphereGeometry(radius: 0.15),
          face,
          position: vm.Vector3(0.085 * side, 0.035, 0.25),
        ),
      meshNode(
        reshaped(SphereGeometry(radius: 0.16), vm.Vector3(1.25, 0.85, 0.9)),
        face,
        position: vm.Vector3(0, -0.11, 0.25),
      ),
      // Button nose and a little smile.
      meshNode(
        reshaped(SphereGeometry(radius: 0.04), vm.Vector3(1.4, 0.8, 0.8)),
        dark,
        position: vm.Vector3(0, -0.06, 0.385),
      ),
      meshNode(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3(-0.045, -0.135, 0.378),
            vm.Vector3(0, -0.158, 0.388),
            vm.Vector3(0.045, -0.135, 0.378),
          ]),
          radius: 0.009,
          radialSegments: 8,
          stations: 12,
        ),
        dark,
      ),
      for (final side in [-1.0, 1.0])
        meshNode(
          reshaped(SphereGeometry(radius: 0.05), vm.Vector3(1.3, 0.75, 0.5)),
          matte(_blush, roughness: 0.7),
          position: vm.Vector3(0.175 * side, -0.07, 0.31),
          rotation: vm.Quaternion.fromTwoVectors(
            vm.Vector3(0, 0, 1),
            vm.Vector3(0.5 * side, 0, 1),
          ),
        ),
      // Round ears with light insides.
      for (final side in [-1.0, 1.0]) ...[
        meshNode(
          SphereGeometry(radius: 0.085),
          fur,
          position: vm.Vector3(0.34 * side, 0.03, -0.02),
        ),
        meshNode(
          SphereGeometry(radius: 0.052),
          face,
          position: vm.Vector3(0.37 * side, 0.03, 0.02),
        ),
      ],
      // A small tuft of hair.
      meshNode(
        SphereGeometry(radius: 0.075),
        fur,
        position: vm.Vector3(0, 0.34, 0.04),
      ),
      meshNode(
        SphereGeometry(radius: 0.05),
        fur,
        position: vm.Vector3(0.07, 0.36, 0),
      ),
    ];
  }

  /// A cute komodo head: a round skull, a long smiling snout, big eyes on
  /// top and a little crest. Coloured by the fur (scales) and face (belly)
  /// materials like the gorilla's.
  List<Node> _buildLizardHead(Material scales, Material belly) {
    final dark = matte(_eye, roughness: 0.4);
    final crest = matte(const Color(0xFFF5A623), roughness: 0.6);

    return [
      meshNode(
        reshaped(
          SphereGeometry(radius: _headRadius, segments: 40, rings: 24),
          vm.Vector3(1, 0.86, 1),
        ),
        scales,
      ),
      // The snout, with a pale jaw underneath.
      meshNode(
        reshaped(
          SphereGeometry(radius: 0.24, rings: 18),
          vm.Vector3(1.05, 0.62, 1.15),
        ),
        scales,
        position: vm.Vector3(0, -0.06, 0.24),
      ),
      meshNode(
        reshaped(
          SphereGeometry(radius: 0.22, segments: 28),
          vm.Vector3(1, 0.42, 1.08),
        ),
        belly,
        position: vm.Vector3(0, -0.13, 0.25),
      ),
      for (final side in [-1.0, 1.0]) ...[
        // Bumps the big eyes sit in.
        meshNode(
          SphereGeometry(radius: 0.105),
          scales,
          position: vm.Vector3(0.15 * side, 0.12, 0.24),
        ),
        // Nostrils.
        meshNode(
          SphereGeometry(radius: 0.018, segments: 10, rings: 8),
          dark,
          position: vm.Vector3(0.055 * side, 0.03, 0.495),
        ),
        meshNode(
          reshaped(SphereGeometry(radius: 0.05), vm.Vector3(1.3, 0.7, 0.5)),
          matte(_blush, roughness: 0.7),
          position: vm.Vector3(0.21 * side, -0.07, 0.31),
          rotation: vm.Quaternion.fromTwoVectors(
            vm.Vector3(0, 0, 1),
            vm.Vector3(0.6 * side, 0, 1),
          ),
        ),
      ],
      // A wide, happy smile along the snout.
      meshNode(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3(-0.18, -0.08, 0.36),
            vm.Vector3(-0.08, -0.11, 0.46),
            vm.Vector3(0, -0.115, 0.48),
            vm.Vector3(0.08, -0.11, 0.46),
            vm.Vector3(0.18, -0.08, 0.36),
          ]),
          radius: 0.009,
          radialSegments: 8,
          stations: 20,
        ),
        dark,
      ),
      // A crest of soft spikes from the brow to the back of the head.
      for (final (i, (y, z, size)) in [
        (0.3, 0.12, 0.06),
        (0.33, 0.0, 0.075),
        (0.29, -0.13, 0.065),
        (0.2, -0.24, 0.05),
      ].indexed)
        meshNode(
          CylinderGeometry(
            bottomRadius: size * 0.7,
            topRadius: 0,
            height: size * 1.6,
            radialSegments: 10,
          ),
          crest,
          position: vm.Vector3(0, y, z),
          rotation: vm.Quaternion.axisAngle(
            vm.Vector3(1, 0, 0),
            -0.3 - i * 0.25,
          ),
        ),
    ];
  }

  /// A chunky, segmented tail out of the back of the torso, curling along
  /// the ground.
  Node _buildTail(Material scales) {
    final tail = Node(name: 'tail');
    const segments = 7;
    for (var i = 0; i < segments; i++) {
      final t = i / (segments - 1);
      tail.add(
        meshNode(
          SphereGeometry(radius: 0.13 * (1 - t * 0.75), segments: 20),
          scales,
          position: vm.Vector3(
            math.sin(t * 2.2) * 0.12,
            -0.2 - t * 0.12,
            -0.16 - t * 0.5,
          ),
        ),
      );
    }

    return tail;
  }

  static void _dress(Node slot, List<Node> parts) {
    [...slot.children].forEach(slot.remove);
    slot.addAll(parts);
  }

  static Iterable<Node> _findSpinners(Node node) sync* {
    if (node.name == 'spin') yield node;
    for (final child in node.children) {
      yield* _findSpinners(child);
    }
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
    _walkPhase += deltaSeconds *
        7 *
        walkSpeed *
        (_weights[GorillaActivity.walking]! +
            _weights[GorillaActivity.carrying]!);

    final pose = _Pose.blend([
      for (final MapEntry(key: activity, value: weight) in _weights.entries)
        if (weight > 0.001)
          (
            switch (activity) {
              GorillaActivity.idle => _Pose.idle(_time),
              GorillaActivity.pushups => _Pose.pushup(_depth),
              GorillaActivity.walking => _Pose.walk(_walkPhase),
              GorillaActivity.deadlift => _Pose.deadlift(_depth, _time),
              GorillaActivity.benchPress => _Pose.benchPress(_depth),
              GorillaActivity.curls => _Pose.curls(_depth, _time),
              GorillaActivity.gobletSquat => _Pose.gobletSquat(_depth, _time),
              GorillaActivity.carrying => _Pose.carry(_walkPhase),
              GorillaActivity.dance => _Pose.dance(_time),
              GorillaActivity.wave => _Pose.wave(_time),
            },
            weight,
          ),
    ]);
    _apply(pose);
    _blink();
    for (final spinner in _spinners) {
      spinner.rotation =
          vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), _time * 9);
    }
  }

  void _apply(_Pose pose) {
    // The torso axis, tipped up from +Z by the body pitch, and its normal.
    final along =
        vm.Vector3(0, math.sin(pose.bodyPitch), math.cos(pose.bodyPitch));
    final bodyUp =
        vm.Vector3(0, math.cos(pose.bodyPitch), -math.sin(pose.bodyPitch));
    final pelvis = pose.pelvis;
    final shoulders = pelvis + along * _torsoLength;
    final breath = 1 + 0.02 * math.sin(_time * 2.6);

    _torso
      ..position = pelvis + along * 0.13
      ..rotation = alongY(along)
      ..scale = vm.Vector3.all(breath);

    // A neckless chibi head, sitting on top of (or in front of) the body.
    final facing = vm.Vector3(
      math.sin(pose.headYaw) * math.cos(pose.headNod),
      -math.sin(pose.headNod),
      math.cos(pose.headYaw) * math.cos(pose.headNod),
    );
    _head
      ..position = shoulders + along * 0.2 + vm.Vector3(0, 0.1, 0)
      ..rotation = vm.Quaternion.fromTwoVectors(vm.Vector3(0, 0, 1), facing) *
          vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), pose.headTilt);

    for (var i = 0; i < 2; i++) {
      final side = i == 0 ? -1.0 : 1.0;
      final lateral = vm.Vector3(side, 0, 0);

      final shoulder =
          shoulders + lateral * _shoulderWidth - along * 0.05 - bodyUp * 0.02;
      final (elbow, hand) = solveTwoBone(
        shoulder,
        pose.hands[i],
        _upperArm,
        _forearm,
        switch (pose.elbowPole) {
          final pole? => vm.Vector3(pole.x * side, pole.y, pole.z),
          null => lateral * 0.7 - along * 0.5 - bodyUp * 0.3,
        },
      );
      placeBetween(_upperArms[i], shoulder, elbow);
      placeBetween(_forearms[i], elbow, hand);
      _hands[i].position = hand;

      final hip = pelvis + lateral * _hipWidth;
      final (knee, foot) = solveTwoBone(
        hip,
        pose.feet[i],
        _thigh,
        _shin,
        lateral * 0.3 + pose.kneeBend,
      );
      placeBetween(_thighs[i], hip, knee);
      placeBetween(_shins[i], knee, foot);
      _feet[i].position = foot + vm.Vector3(0, -0.02, 0.04);
    }
  }

  void _blink() {
    // A quick blink every ~3.4 seconds.
    final closed = (_time % 3.4) < 0.14;
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
    this.headTilt = 0,
    this.elbowPole,
  }) : kneeBend = kneeBend ?? vm.Vector3(0, 0, 1);

  /// Sitting up with paws on its knees, bobbing and glancing around.
  factory _Pose.idle(double time) {
    final bob = math.sin(time * 2.6) * 0.008;

    return _Pose(
      pelvis: vm.Vector3(math.sin(time * 1.1) * 0.01, 0.2 + bob, -0.04),
      bodyPitch: 1.42,
      hands: [
        vm.Vector3(-0.2, 0.2 + bob, 0.19),
        vm.Vector3(0.2, 0.2 + bob, 0.19),
      ],
      feet: [vm.Vector3(-0.15, 0.06, 0.25), vm.Vector3(0.15, 0.06, 0.25)],
      kneeBend: vm.Vector3(0, 1, 0),
      headYaw: math.sin(time * 0.55) * 0.4,
      headNod: math.sin(time * 0.8) * 0.06 - 0.05,
      headTilt: math.sin(time * 0.7) * 0.14,
    );
  }

  /// A stubby plank; [depth] 0 is arms extended, 1 is chest to the floor.
  factory _Pose.pushup(double depth) {
    final shoulderHeight = _lerp(0.36, 0.22, depth);
    final pelvisHeight = _lerp(0.25, 0.21, depth);
    final pitch = math.asin((shoulderHeight - pelvisHeight) / _torsoLength);

    return _Pose(
      pelvis: vm.Vector3(0, pelvisHeight, -0.18),
      bodyPitch: pitch,
      hands: [vm.Vector3(-0.25, 0.05, 0.12), vm.Vector3(0.25, 0.05, 0.12)],
      feet: [vm.Vector3(-0.1, 0.04, -0.46), vm.Vector3(0.1, 0.04, -0.46)],
      // Knees sag towards the floor instead of folding forwards.
      kneeBend: vm.Vector3(0, -1, 0),
      // Look up and over to the camera (on the +X side) between reps.
      headYaw: 0.45,
      headNod: _lerp(-0.25, -0.1, depth),
    );
  }

  /// Waddling upright; [phase] advances one stride per 2π.
  factory _Pose.walk(double phase) {
    vm.Vector3 foot(double x, double offset) {
      final s = phase + offset;

      return vm.Vector3(
        x,
        0.04 + math.max(0, math.sin(s)) * 0.06,
        math.cos(s) * 0.08,
      );
    }

    vm.Vector3 hand(double x, double offset) =>
        vm.Vector3(x, 0.26, -math.cos(phase + offset) * 0.08);

    return _Pose(
      pelvis: vm.Vector3(
        math.sin(phase) * 0.03,
        0.3 + math.cos(phase * 2) * 0.012,
        0,
      ),
      bodyPitch: 1.45,
      hands: [hand(-0.27, 0), hand(0.27, math.pi)],
      feet: [foot(-0.12, math.pi), foot(0.12, 0)],
      headTilt: math.sin(phase) * 0.12,
    );
  }

  /// Lifting a barbell from the floor; [depth] 1 is the bar on the floor.
  factory _Pose.deadlift(double depth, double time) {
    final barHeight = _lerp(0.3, 0.11, depth);

    return _Pose(
      pelvis:
          vm.Vector3(0, _lerp(0.31, 0.2, depth), _lerp(-0.02, -0.12, depth)),
      bodyPitch: _lerp(1.45, 0.8, depth),
      hands: [
        vm.Vector3(-0.2, barHeight, _lerp(0.13, 0.2, depth)),
        vm.Vector3(0.2, barHeight, _lerp(0.13, 0.2, depth)),
      ],
      feet: [vm.Vector3(-0.13, 0.04, 0.04), vm.Vector3(0.13, 0.04, 0.04)],
      headNod: _lerp(-0.05, 0.25, depth),
      headYaw: math.sin(time * 0.5) * 0.2 * (1 - depth),
      elbowPole: vm.Vector3(0.3, 0, -1),
    );
  }

  /// Pressing a bar while lying on its back; [depth] 1 is the bar at the
  /// chest. The head points to -Z.
  factory _Pose.benchPress(double depth) {
    const chest = 0.47;

    return _Pose(
      pelvis: vm.Vector3(0, chest, 0.12),
      bodyPitch: math.pi,
      hands: [
        vm.Vector3(-0.21, _lerp(chest + 0.29, chest + 0.12, depth), -0.1),
        vm.Vector3(0.21, _lerp(chest + 0.29, chest + 0.12, depth), -0.1),
      ],
      // Little legs hanging off the end of the bench.
      feet: [vm.Vector3(-0.17, 0.12, 0.36), vm.Vector3(0.17, 0.12, 0.36)],
      kneeBend: vm.Vector3(0, 1, 0.4),
      headNod: -math.pi / 2 + 0.25,
      elbowPole: vm.Vector3(1, -0.7, 0),
    );
  }

  /// Dumbbell curls; [depth] 1 is the weights up at the shoulders.
  factory _Pose.curls(double depth, double time) {
    final bob = math.sin(time * 2.6) * 0.006;

    return _Pose(
      pelvis: vm.Vector3(0, 0.3 + bob, 0),
      bodyPitch: _lerp(1.5, 1.42, depth),
      hands: [
        vm.Vector3(-0.21, _lerp(0.24, 0.48, depth), _lerp(0.1, 0.17, depth)),
        vm.Vector3(0.21, _lerp(0.24, 0.48, depth), _lerp(0.1, 0.17, depth)),
      ],
      feet: [vm.Vector3(-0.12, 0.04, 0.02), vm.Vector3(0.12, 0.04, 0.02)],
      headYaw: math.sin(time * 0.45) * 0.25 * (1 - depth),
      headNod: _lerp(-0.05, 0.12, depth),
      elbowPole: vm.Vector3(0.35, -1, -0.5),
    );
  }

  /// Squatting with a kettlebell held at the chest; [depth] 1 is the bottom
  /// of the squat.
  factory _Pose.gobletSquat(double depth, double time) {
    final handHeight = _lerp(0.44, 0.33, depth);
    final handDepth = _lerp(0.22, 0.24, depth);

    return _Pose(
      pelvis: vm.Vector3(0, _lerp(0.3, 0.16, depth), _lerp(0, -0.12, depth)),
      bodyPitch: _lerp(1.45, 1.2, depth),
      hands: [
        vm.Vector3(-0.06, handHeight, handDepth),
        vm.Vector3(0.06, handHeight, handDepth),
      ],
      feet: [vm.Vector3(-0.17, 0.04, 0.05), vm.Vector3(0.17, 0.04, 0.05)],
      kneeBend: vm.Vector3(0.6, 0, 1),
      headYaw: math.sin(time * 0.5 + 1) * 0.2 * (1 - depth),
      elbowPole: vm.Vector3(0.6, -1, 0),
    );
  }

  /// [_Pose.walk] with both hands together in front, holding something.
  factory _Pose.carry(double phase) {
    final walk = _Pose.walk(phase);
    final lift = math.cos(phase * 2) * 0.01;

    return _Pose(
      pelvis: walk.pelvis,
      bodyPitch: 1.42,
      hands: [
        vm.Vector3(-0.17, 0.33 + lift, 0.21),
        vm.Vector3(0.17, 0.33 + lift, 0.21),
      ],
      feet: walk.feet,
      headTilt: walk.headTilt,
      elbowPole: vm.Vector3(0.6, -1, 0),
    );
  }

  /// Hopping on the spot with arms up, wiggling side to side.
  factory _Pose.dance(double time) {
    final hop = math.sin(time * 7).abs() * 0.1;
    final sway = math.sin(time * 3.5);

    return _Pose(
      pelvis: vm.Vector3(sway * 0.04, 0.3 + hop, 0),
      bodyPitch: 1.5,
      hands: [
        vm.Vector3(-0.31, 0.74 + hop + sway * 0.05, 0.06),
        vm.Vector3(0.31, 0.74 + hop - sway * 0.05, 0.06),
      ],
      feet: [
        vm.Vector3(-0.13, 0.04 + hop * 0.8, 0.03),
        vm.Vector3(0.13, 0.04 + hop * 0.8, 0.03),
      ],
      headTilt: sway * 0.22,
      headNod: -0.15,
      elbowPole: vm.Vector3(1, 0, 0),
    );
  }

  /// Standing tall, waving its left paw high over its head.
  factory _Pose.wave(double time) {
    final swing = math.sin(time * 9);

    return _Pose(
      pelvis: vm.Vector3(0, 0.3 + math.sin(time * 4.5).abs() * 0.01, 0),
      bodyPitch: 1.5,
      hands: [
        vm.Vector3(-0.24, 0.24, 0.08),
        vm.Vector3(0.3 + swing * 0.07, 0.72, 0.1),
      ],
      feet: [vm.Vector3(-0.12, 0.04, 0.02), vm.Vector3(0.12, 0.04, 0.02)],
      headTilt: -0.18 + swing * 0.05,
      headNod: -0.12,
      elbowPole: vm.Vector3(1, -0.4, 0),
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
      headTilt: mixValue((p) => p.headTilt),
      // Poles don't blend meaningfully; follow the dominant pose.
      elbowPole: weighted.reduce((a, b) => a.$2 >= b.$2 ? a : b).$1.elbowPole,
    );
  }

  final vm.Vector3 pelvis;
  final double bodyPitch;
  final List<vm.Vector3> hands;
  final List<vm.Vector3> feet;
  final vm.Vector3 kneeBend;
  final double headYaw;
  final double headNod;
  final double headTilt;

  /// Where the elbows point, for the gorilla's left arm (+X); mirrored for
  /// the right. Null uses the default, out and behind the shoulders.
  final vm.Vector3? elbowPole;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
