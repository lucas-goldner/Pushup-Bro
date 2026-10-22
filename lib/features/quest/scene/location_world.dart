import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/costumes.dart';
import 'package:pushup_bro/core/scene/critters.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The sky behind each location, top to bottom, drawn by Flutter behind
/// the transparent scene.
(Color, Color) skyFor(ChallengeLocation location) => switch (location) {
      ChallengeLocation.volcano => (
          const Color(0xFF3B1A2E),
          const Color(0xFFF2784B)
        ),
      ChallengeLocation.moonBeach => (
          const Color(0xFF0B1030),
          const Color(0xFF3A3F8F)
        ),
      ChallengeLocation.temple => (
          const Color(0xFF1F5A4C),
          const Color(0xFFB9E3C6)
        ),
      ChallengeLocation.skyIsland => (
          const Color(0xFF6FB7F2),
          const Color(0xFFFFE6F2)
        ),
    };

/// Builds the guest of a quest as an [Actor].
Actor actorFor(Character character) => switch (character) {
      Character.coco => Parrot(),
      Character.shelldon => Tortoise(),
      Character.jag => Jaguar(),
      Character.stranger => GorillaActor(
          look: const MonkeyLook(
            fur: 'fur.slate',
            face: 'face.frost',
            eyewear: 'eyes.shades',
            outfit: 'outfit.cape',
          ),
        ),
      Character.carlos => GorillaActor(),
    };

/// A quest location in 3D: its scenery, Carlos and the quest's guest.
///
/// In a cutscene they stand facing each other in the middle; during the
/// challenge Carlos does pushups on his mat while the guest watches from the
/// side and cheers. Set [progress] (0 to 1) as the challenge goes on;
/// some places react to it.
class LocationWorld {
  LocationWorld(
    this.location, {
    required MonkeyLook look,
    required Character guest,
  })  : carlos = GorillaActor(look: look),
        guest = actorFor(guest),
        _mat = buildMat(look) {
    root
      ..add(
        switch (location) {
          ChallengeLocation.volcano => _volcano(),
          ChallengeLocation.moonBeach => _moonBeach(),
          ChallengeLocation.temple => _temple(),
          ChallengeLocation.skyIsland => _skyIsland(),
        },
      )
      ..add(_mat..visible = false)
      ..add(carlos.root)
      ..add(this.guest.root);
    stageCutscene();
  }

  final ChallengeLocation location;
  final Node root = Node(name: 'location');
  final GorillaActor carlos;
  final Actor guest;
  final Node _mat;
  final List<void Function(double, double)> _animations = [];
  final _random = math.Random(5);
  double _time = 0;
  bool _challenge = false;

  /// How far the challenge has got, 0 to 1.
  double progress = 0;

  /// Where Carlos and the guest stand in the cutscene.
  static final carlosMark = vm.Vector3(-0.55, 0, 0.25);
  static final guestMark = vm.Vector3(0.7, 0, 0);

  void stageCutscene() {
    _challenge = false;
    _mat.visible = false;
    carlos.root
      ..position = carlosMark.clone()
      ..rotation = yaw(1);
    carlos.rig
      ..activity = GorillaActivity.walking
      ..walkSpeed = 0;
    guest.root
      ..position = guestMark.clone()
      ..rotation = yaw(-1.1);
  }

  void stageChallenge() {
    _challenge = true;
    _mat
      ..visible = true
      ..position = vm.Vector3(0, 0, -0.1);
    carlos
      ..talking = false
      ..root.position = vm.Vector3.zero()
      ..root.rotation = vm.Quaternion.identity();
    carlos.rig.activity = GorillaActivity.idle;
    guest
      ..talking = false
      ..root.position = vm.Vector3(1.25, 0, -0.9)
      ..root.rotation = yaw(-0.5);
  }

  /// Carlos holds a plank while the set is tracked; the guest cheers.
  bool get tracking => guest.cheering;
  set tracking(bool value) {
    carlos.rig.activity =
        value ? GorillaActivity.pushups : GorillaActivity.idle;
    guest.cheering = value;
  }

  bool get inPushup => carlos.rig.inPushup;
  set inPushup(bool value) => carlos.rig.inPushup = value;

  /// The point to frame when [character] speaks.
  vm.Vector3 focusOn(Character character) {
    final actor = character == Character.carlos ? carlos : guest;

    return actor.root.position + vm.Vector3(0, actor.eyeHeight, 0);
  }

  void update(double deltaSeconds) {
    _time += deltaSeconds;
    if (_challenge) {
      carlos.rig.update(deltaSeconds);
    } else {
      carlos.update(deltaSeconds);
    }
    guest.update(deltaSeconds);
    for (final animate in _animations) {
      animate(_time, deltaSeconds);
    }
  }

  Node _unlit(Geometry geometry, Color color, {vm.Vector3? at}) => meshNode(
        geometry,
        UnlitMaterial()..baseColorFactor = linearColor(color),
        position: at,
      );

  /// Things that rise from [from] (a random spread) to [height] and start
  /// again, like embers or bubbles.
  void _risers(
    Node parent, {
    required int count,
    required Node Function() build,
    required vm.Vector3 Function() from,
    required double height,
    required double speed,
    double grow = 0,
  }) {
    for (var i = 0; i < count; i++) {
      final node = build();
      final start = from();
      final phase = _random.nextDouble();
      parent.add(node);
      _animations.add((time, _) {
        final t = (time * speed / height + phase) % 1;
        node
          ..position = start +
              vm.Vector3(
                math.sin(time * 1.3 + phase * 9) * 0.3 * t,
                t * height,
                0,
              )
          ..scale = vm.Vector3.all(1 + grow * t);
      });
    }
  }

  Node _volcano() {
    final scene = Node(name: 'volcano');
    const lava = Color(0xFFFF7A2F);
    scene
      ..add(
        meshNode(
          plateau(
            radius: (a) => 12 * (1 + 0.05 * math.sin(5 * a)),
            top: 0,
            bottom: -0.5,
            bottomScale: 1.05,
          ),
          matte(const Color(0xFF3A2E2E), roughness: 0.95),
        ),
      )
      // The volcano itself, glowing at the top, lava running down.
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 7,
            topRadius: 1.8,
            height: 6,
            radialSegments: 48,
          ),
          matte(const Color(0xFF4A3634), roughness: 0.9),
          position: vm.Vector3(0, 3, -16),
        ),
      )
      ..add(
        _unlit(
          CylinderGeometry(bottomRadius: 1.7, topRadius: 1.7, height: 0.1),
          lava,
          at: vm.Vector3(0, 6.02, -16),
        ),
      );
    for (final (x, wobble) in [(-0.9, 0.4), (0.4, -0.5), (1.3, 0.3)]) {
      scene.add(
        _unlit(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(x * 1.2, 6, -16 + 1.6),
              vm.Vector3(x * 2 + wobble, 4, -16 + 3.5),
              vm.Vector3(x * 3 - wobble, 2, -16 + 5.2),
              vm.Vector3(x * 4, 0.1, -16 + 6.9),
            ]),
            radius: 0.22,
            radialSegments: 8,
            stations: 24,
          ),
          lava,
        ),
      );
    }
    // Lava cracks across the ground.
    for (var i = 0; i < 5; i++) {
      final x0 = -5.0 + i * 2.4;
      scene.add(
        _unlit(
          RibbonGeometry(
            CatmullRomPath([
              vm.Vector3(x0, 0.01, -9),
              vm.Vector3(x0 + 0.6, 0.01, -6),
              vm.Vector3(x0 - 0.4, 0.01, -4),
              vm.Vector3(x0 + 0.5 * (i.isEven ? 1 : -1), 0.01, -2.5),
            ]),
            width: 0.12,
            stations: 30,
          ),
          lava,
        ),
      );
    }
    for (final (x, z, size) in [
      (-2.6, -1.5, 0.5),
      (2.8, -2.2, 0.6),
      (-3.5, -4.5, 0.8),
      (3.6, -5.0, 0.7),
      (-1.6, 1.4, 0.3),
      (2.2, 1.2, 0.35),
    ]) {
      scene.add(
        rock(size, turn: x, color: const Color(0xFF5A4A48))
          ..position = vm.Vector3(x, 0, z),
      );
    }
    _risers(
      scene,
      count: 40,
      build: () => _unlit(
        IcosphereGeometry(radius: 0.03, subdivisions: 0),
        _random.nextBool() ? const Color(0xFFFFB347) : lava,
      ),
      from: () => vm.Vector3(
        (_random.nextDouble() - 0.5) * 9,
        0,
        -_random.nextDouble() * 9 + 1,
      ),
      height: 4,
      speed: 1.1,
    );
    _risers(
      scene,
      count: 7,
      build: () => meshNode(
        IcosphereGeometry(radius: 0.8, subdivisions: 1),
        matte(const Color(0xFF7A6A6A), roughness: 1),
      ),
      from: () => vm.Vector3(
        (_random.nextDouble() - 0.5) * 1.5,
        6.4,
        -16,
      ),
      height: 7,
      speed: 0.8,
      grow: 1.6,
    );

    return scene;
  }

  Node _moonBeach() {
    final scene = Node(name: 'moon-beach')
      ..add(
        meshNode(
          DiscGeometry(radius: 120, segments: 64),
          matte(const Color(0xFF1B2B5C), roughness: 0.1),
          position: vm.Vector3(0, -0.05, 0),
        ),
      )
      ..add(
        meshNode(
          plateau(
            radius: (a) => 6 * (1 + 0.08 * math.sin(3 * a + 1)),
            top: 0,
            bottom: -0.4,
            bottomScale: 1.2,
          ),
          matte(const Color(0xFFD9C79A), roughness: 0.95),
        ),
      )
      // A huge moon over the sea, with a glow and its path on the water.
      ..add(
        _unlit(
          CylinderGeometry(bottomRadius: 6, topRadius: 6, height: 0.1),
          const Color(0xFF2E3577),
          at: vm.Vector3(0, 11, -60),
        )..rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
      )
      ..add(
        _unlit(
          CylinderGeometry(bottomRadius: 4.6, topRadius: 4.6, height: 0.1),
          const Color(0xFFF6F1D8),
          at: vm.Vector3(0, 11, -59.8),
        )..rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
      )
      ..add(
        _unlit(
          RibbonGeometry(
            CatmullRomPath([
              vm.Vector3(0, -0.02, -58),
              vm.Vector3(0, -0.02, -30),
              vm.Vector3(0, -0.02, -7),
            ]),
            width: 3.5,
            stations: 8,
          ),
          const Color(0xFF8D93D8),
        ),
      );
    // Stars on a far dome.
    for (var i = 0; i < 140; i++) {
      final a = _random.nextDouble() * math.pi - math.pi;
      final e = 0.12 + _random.nextDouble() * 1.2;
      final star = _unlit(
        IcosphereGeometry(
          radius: 0.12 + _random.nextDouble() * 0.15,
          subdivisions: 0,
        ),
        const Color(0xFFFFFFFF),
        at: vm.Vector3(
          math.cos(a) * math.cos(e) * 80,
          math.sin(e) * 80,
          math.sin(a) * math.cos(e) * 80,
        ),
      );
      final phase = _random.nextDouble() * 6;
      scene.add(star);
      _animations.add((time, _) {
        star.scale = vm.Vector3.all(0.7 + 0.3 * math.sin(time * 2 + phase));
      });
    }
    for (final (x, z, lean, height) in [
      (-3.2, -2.5, 0.4, 2.4),
      (3.4, -3.0, 2.6, 2.1),
      (-4.2, 0.5, -0.4, 1.8),
      (4.4, 0.2, 3.2, 1.9),
    ]) {
      scene.add(
        palmTree(lean: lean, height: height)..position = vm.Vector3(x, 0, z),
      );
    }
    // Tiki torches.
    for (final x in [-1.8, 1.8]) {
      final flame = _unlit(
        IcosphereGeometry(radius: 0.09, subdivisions: 1),
        const Color(0xFFFFB347),
        at: vm.Vector3(x, 1.18, -1.4),
      );
      scene
        ..add(
          meshNode(
            CylinderGeometry(bottomRadius: 0.04, topRadius: 0.05, height: 1.1),
            matte(const Color(0xFF8A5A36)),
            position: vm.Vector3(x, 0.55, -1.4),
          ),
        )
        ..add(flame);
      _animations.add((time, _) {
        flame.scale = vm.Vector3(1, 1.2 + math.sin(time * 13 + x) * 0.25, 1);
      });
    }
    // Fireflies.
    for (var i = 0; i < 26; i++) {
      final home = vm.Vector3(
        (_random.nextDouble() - 0.5) * 9,
        0.4 + _random.nextDouble() * 1.8,
        -_random.nextDouble() * 6 + 1,
      );
      final fly = _unlit(
        IcosphereGeometry(radius: 0.03, subdivisions: 0),
        const Color(0xFFE4FF8A),
        at: home,
      );
      final phase = _random.nextDouble() * 9;
      scene.add(fly);
      _animations.add((time, _) {
        fly
          ..position = home +
              vm.Vector3(
                math.sin(time * 0.7 + phase) * 0.4,
                math.sin(time * 1.1 + phase * 2) * 0.2,
                math.cos(time * 0.5 + phase) * 0.3,
              )
          ..scale =
              vm.Vector3.all(0.6 + 0.5 * math.sin(time * 4 + phase).abs());
      });
    }
    // The waterline breathes in and out.
    final foam = meshNode(
      RingGeometry(innerRadius: 5.9, outerRadius: 6.5, segments: 96),
      matte(const Color(0xFFB8C4F0), roughness: 0.6),
      position: vm.Vector3(0, 0.01, 0),
    );
    scene.add(foam);
    _animations.add((time, _) {
      foam.scale = vm.Vector3.all(1 + math.sin(time * 0.9) * 0.02);
    });

    return scene;
  }

  Node _temple() {
    final stone = matte(const Color(0xFFA8A396), roughness: 0.9);
    final darkStone = matte(const Color(0xFF8C8778), roughness: 0.9);
    final scene = Node(name: 'temple')
      ..add(
        meshNode(
          plateau(
            radius: (a) => 14,
            top: -0.02,
            bottom: -0.6,
            bottomScale: 1,
            segments: 48,
          ),
          matte(const Color(0xFF4E8A45), roughness: 0.95),
        ),
      );
    // A courtyard of stone tiles.
    for (var x = -3; x <= 3; x++) {
      for (var z = -4; z <= 2; z++) {
        scene.add(
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.94, 0.08, 0.94),
            ),
            (x + z).isEven ? stone : darkStone,
            position: vm.Vector3(x.toDouble(), 0.02, z.toDouble()),
          ),
        );
      }
    }
    // The stepped pyramid with the Golden Banana on top.
    for (var level = 0; level < 5; level++) {
      final size = 9.0 - level * 1.6;
      scene.add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(size, 0.9, size * 0.6),
          ),
          level.isEven ? stone : darkStone,
          position: vm.Vector3(0, 0.45 + level * 0.9, -11 - level * 0.2),
        ),
      );
    }
    final idol = Node(name: 'idol')
      ..position = vm.Vector3(0, 5.2, -12)
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.6, 0.4, 0),
              vm.Vector3(-0.2, 0.05, 0),
              vm.Vector3(0.3, 0.05, 0),
              vm.Vector3(0.65, 0.5, 0),
            ]),
            radius: 0.22,
            radialSegments: 14,
            stations: 28,
          ),
          matte(const Color(0xFFE8B83A), roughness: 0.25)..metallicFactor = 0.9,
        ),
      )
      ..add(
        _unlit(
          TorusGeometry(radius: 1, tubeRadius: 0.04),
          const Color(0xFFFFE27A),
        )..rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
      );
    scene.add(idol);
    _animations.add((time, _) {
      idol
        ..rotation = yaw(math.sin(time * 0.6) * 0.4)
        ..position = vm.Vector3(0, 5.2 + math.sin(time * 1.4) * 0.12, -12);
    });
    // Pillars wrapped in vines, a couple of them broken.
    for (final (x, z, height) in [
      (-3.8, -1.0, 2.6),
      (3.8, -1.0, 2.6),
      (-3.8, -4.2, 1.6),
      (3.8, -4.2, 2.6),
    ]) {
      scene
        ..add(
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.32,
              topRadius: 0.28,
              height: height,
            ),
            stone,
            position: vm.Vector3(x, height / 2, z),
          ),
        )
        ..add(
          meshNode(
            TubeGeometry(
              CatmullRomPath([
                for (var i = 0; i <= 10; i++)
                  vm.Vector3(
                    x + math.cos(i * 1.2) * 0.33,
                    i / 10 * height,
                    z + math.sin(i * 1.2) * 0.33,
                  ),
              ]),
              radius: 0.035,
              radialSegments: 6,
              stations: 40,
            ),
            matte(const Color(0xFF3E7D3A)),
          ),
        );
    }
    // Torches either side of the steps.
    for (final x in [-2.4, 2.4]) {
      final flame = _unlit(
        CylinderGeometry(bottomRadius: 0.13, topRadius: 0, height: 0.36),
        const Color(0xFFFF9F43),
        at: vm.Vector3(x, 1.45, -6.2),
      );
      scene
        ..add(
          meshNode(
            CylinderGeometry(bottomRadius: 0.08, topRadius: 0.16, height: 1.3),
            darkStone,
            position: vm.Vector3(x, 0.65, -6.2),
          ),
        )
        ..add(flame);
      _animations.add((time, _) {
        flame.scale = vm.Vector3(
          1 + math.sin(time * 11 + x) * 0.1,
          1 + math.sin(time * 15 + x) * 0.25,
          1,
        );
      });
    }
    final random = math.Random(9);
    for (final (x, z) in [
      (-6.5, -3.0),
      (6.5, -3.5),
      (-7.5, 1.0),
      (7.2, 1.2),
      (-5.5, -7.0),
      (5.8, -7.5),
    ]) {
      scene.add(
        broadleafTree(random, height: 2.4 + random.nextDouble())
          ..position = vm.Vector3(x, 0, z),
      );
    }

    return scene;
  }

  Node _skyIsland() {
    final scene = Node(name: 'sky-island')
      ..add(
        meshNode(
          plateau(
            radius: (a) => 4.2 * (1 + 0.07 * math.sin(4 * a + 1)),
            top: 0,
            bottom: -0.3,
            bottomScale: 1.02,
          ),
          matte(const Color(0xFF8CCB6E), roughness: 0.9),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.4,
            topRadius: 4.3,
            height: 4,
            radialSegments: 40,
          ),
          matte(const Color(0xFF9A6B47), roughness: 0.95),
          position: vm.Vector3(0, -2.3, 0),
        ),
      );
    final random = math.Random(2);
    for (var i = 0; i < 6; i++) {
      final a = i / 6 * math.pi * 2 + 0.4;
      scene.add(
        (i.isEven ? bush(size: 1.3) : flowers(random))
          ..position =
              vm.Vector3(math.cos(a) * 3.3, 0, math.sin(a) * 3.3 - 0.5),
      );
    }
    // Clouds drifting by, above and below.
    for (var i = 0; i < 16; i++) {
      final cloud = Node(name: 'cloud');
      final puffs = 3 + random.nextInt(3);
      for (var p = 0; p < puffs; p++) {
        cloud.add(
          meshNode(
            IcosphereGeometry(
              radius: 0.6 + random.nextDouble() * 0.6,
            ),
            matte(const Color(0xFFFFFFFF), roughness: 1),
            position:
                vm.Vector3(p * 0.8 - puffs * 0.4, random.nextDouble() * 0.3, 0),
          ),
        );
      }
      final home = vm.Vector3(
        (random.nextDouble() - 0.5) * 30,
        -4 + random.nextDouble() * 10,
        -6 - random.nextDouble() * 18,
      );
      final speed = 0.2 + random.nextDouble() * 0.3;
      scene.add(cloud);
      _animations.add((time, _) {
        cloud.position = home + vm.Vector3((time * speed + 15) % 30 - 15, 0, 0);
      });
    }
    // Little floating rocks bobbing about.
    for (final (x, y, z) in [
      (-5.5, 1.2, -4.0),
      (6.0, 2.4, -6.0),
      (-3.5, 3.6, -10.0),
    ]) {
      final rockIsland = Node()
        ..add(
          meshNode(
            CylinderGeometry(bottomRadius: 0.1, topRadius: 0.8, height: 0.9),
            matte(const Color(0xFF9A6B47)),
            position: vm.Vector3(0, -0.45, 0),
          ),
        )
        ..add(
          meshNode(
            CylinderGeometry(bottomRadius: 0.8, topRadius: 0.8, height: 0.12),
            matte(const Color(0xFF8CCB6E)),
          ),
        );
      scene.add(rockIsland);
      _animations.add((time, _) {
        rockIsland.position = vm.Vector3(x, y + math.sin(time + x) * 0.25, z);
      });
    }
    // The rainbow bridge: a stripe for every sixth of the way.
    const colors = [
      Color(0xFFF26B5B),
      Color(0xFFFF9F43),
      Color(0xFFF5C343),
      Color(0xFF7DD9B5),
      Color(0xFF5E9EFF),
      Color(0xFFB98AF2),
    ];
    final stripes = <Node>[];
    for (final (i, color) in colors.indexed) {
      final radius = 9.0 - i * 0.42;
      final stripe = _unlit(
        TubeGeometry(
          CatmullRomPath([
            for (var s = 0; s <= 24; s++)
              vm.Vector3(
                math.cos(s / 24 * math.pi) * radius,
                math.sin(s / 24 * math.pi) * radius - 3,
                -14,
              ),
          ]),
          radius: 0.22,
          radialSegments: 8,
          stations: 60,
        ),
        color,
      );
      stripes.add(stripe);
      scene.add(stripe);
    }
    _animations.add((time, deltaSeconds) {
      // Before the challenge the whole rainbow shows; during it, it is
      // painted in stripe by stripe.
      final shown =
          _challenge ? (progress * colors.length).floor() : colors.length;
      for (final (i, stripe) in stripes.indexed) {
        stripe.visible = i < shown;
      }
    });

    return scene;
  }
}
