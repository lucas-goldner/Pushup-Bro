import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/costumes.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Someone in a jungle story: placed by [root] (facing +Z), animated by
/// [update]. While [talking] they bob along to their words; while
/// [cheering] they hop about.
abstract class Actor {
  Node get root;

  /// How high their eyes are above the ground, for framing them.
  double get eyeHeight;

  bool talking = false;
  bool cheering = false;

  void update(double deltaSeconds);
}

final vm.Vector3 _up = vm.Vector3(0, 1, 0);
final vm.Vector3 _forward = vm.Vector3(0, 0, 1);

Node _eye(double radius, vm.Vector3 at) {
  final eye = Node(name: 'eye')..position = at;

  return eye
    ..add(
      meshNode(
        SphereGeometry(radius: radius, segments: 16, rings: 10),
        matte(const Color(0xFFFFFFFF), roughness: 0.3),
      ),
    )
    ..add(
      meshNode(
        SphereGeometry(radius: radius * 0.58, segments: 14, rings: 8),
        matte(const Color(0xFF15141B), roughness: 0.1),
        position: vm.Vector3(0, 0, radius * 0.6),
      ),
    )
    ..add(
      meshNode(
        SphereGeometry(radius: radius * 0.18, segments: 8, rings: 6),
        UnlitMaterial()..baseColorFactor = linearColor(const Color(0xFFFFFFFF)),
        position: vm.Vector3(radius * 0.25, radius * 0.3, radius * 1.05),
      ),
    );
}

/// Carlos (or any gorilla) as an [Actor].
class GorillaActor extends Actor {
  GorillaActor({MonkeyLook look = const MonkeyLook()}) {
    rig
      ..look = look
      ..activity = GorillaActivity.walking
      ..walkSpeed = 0
      ..settle();
  }

  final GorillaRig rig = GorillaRig();
  double _time = 0;

  @override
  Node get root => rig.root;

  @override
  double get eyeHeight => 0.85;

  @override
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    if (cheering) {
      rig.activity = GorillaActivity.dance;
    } else if (rig.activity == GorillaActivity.dance) {
      rig.activity = GorillaActivity.walking;
    }
    rig.update(deltaSeconds);
    // A talking bob layered over the standing pose.
    final bob = talking ? math.sin(_time * 14).abs() * 0.025 : 0.0;
    rig.root.position =
        vm.Vector3(rig.root.position.x, bob, rig.root.position.z);
  }
}

/// Coco: a chatty scarlet macaw on a perch.
class Parrot extends Actor {
  Parrot() {
    final red = matte(const Color(0xFFE5374B), roughness: 0.55);
    final blue = matte(const Color(0xFF3F7DE0), roughness: 0.55);
    final yellow = matte(const Color(0xFFF5C343), roughness: 0.55);
    final wood = matte(const Color(0xFF8A5A36));

    // A perch to sit at a gorilla's eye level.
    root
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.04, topRadius: 0.03, height: 0.62),
          wood,
          position: vm.Vector3(0, 0.31, 0),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.025, topRadius: 0.025, height: 0.4),
          wood,
          position: vm.Vector3(0, 0.62, 0),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.16, topRadius: 0.12, height: 0.04),
          wood,
          position: vm.Vector3(0, 0.02, 0),
        ),
      )
      ..add(_bird);

    _bird
      ..position = vm.Vector3(0, 0.64, 0)
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.13, segments: 24, rings: 14),
            vm.Vector3(0.9, 1.25, 0.95),
          ),
          red,
          position: vm.Vector3(0, 0.15, 0),
        ),
      )
      ..add(_head)
      // Tail feathers hanging behind the perch.
      ..addAll([
        for (final (x, color, length) in [
          (-0.03, blue, 0.34),
          (0.03, red, 0.4),
          (0.0, yellow, 0.3),
        ])
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.05, length, 0.02),
            ),
            color,
            position: vm.Vector3(x, 0.02 - length / 2 + 0.05, -0.1),
            rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.25),
          ),
      ]);
    for (final side in [-1.0, 1.0]) {
      final wing = Node()
        ..position = vm.Vector3(side * 0.11, 0.24, -0.01)
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.1, segments: 16, rings: 10),
              vm.Vector3(0.35, 1.3, 0.8),
            ),
            blue,
            position: vm.Vector3(side * 0.01, -0.09, 0),
          ),
        )
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.08, segments: 14, rings: 8),
              vm.Vector3(0.3, 1, 0.75),
            ),
            yellow,
            position: vm.Vector3(side * 0.02, -0.02, 0.01),
          ),
        );
      _wings.add(wing);
      _bird.add(wing);
    }

    _head
      ..position = vm.Vector3(0, 0.36, 0.03)
      ..add(
        meshNode(
          SphereGeometry(radius: 0.1, segments: 22, rings: 14),
          red,
        ),
      )
      // White face patches around big eyes.
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.05, segments: 14, rings: 10),
              vm.Vector3(1, 1.1, 0.5),
            ),
            matte(const Color(0xFFF4EDE1)),
            position: vm.Vector3(side * 0.055, 0, 0.07),
          ),
          _eye(0.03, vm.Vector3(side * 0.058, 0.015, 0.088)),
        ],
      ])
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.045, topRadius: 0, height: 0.12),
          matte(const Color(0xFFF1E6CF), roughness: 0.4),
          position: vm.Vector3(0, -0.02, 0.12),
          rotation: vm.Quaternion.fromTwoVectors(_up, vm.Vector3(0, -0.6, 1)),
        ),
      )
      ..add(_beak..position = vm.Vector3(0, -0.055, 0.08));
    _beak.add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.03, topRadius: 0, height: 0.06),
        matte(const Color(0xFF2B2B2B), roughness: 0.4),
        rotation: vm.Quaternion.fromTwoVectors(_up, vm.Vector3(0, -0.4, 1)),
      ),
    );
  }

  @override
  final Node root = Node(name: 'parrot');
  final Node _bird = Node(name: 'bird');
  final Node _head = Node(name: 'head');
  final Node _beak = Node(name: 'beak');
  final List<Node> _wings = [];
  double _time = 0;

  @override
  double get eyeHeight => 1;

  @override
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    final hop = cheering ? math.sin(_time * 9).abs() * 0.12 : 0.0;
    _bird.position = vm.Vector3(0, 0.64 + hop, 0);
    final flap = cheering
        ? 0.9 + math.sin(_time * 22) * 0.6
        : talking
            ? 0.15 + math.sin(_time * 10) * 0.12
            : 0.05;
    for (final (i, wing) in _wings.indexed) {
      wing.rotation = vm.Quaternion.axisAngle(
        _forward,
        (i == 0 ? -1 : 1) * flap,
      );
    }
    final chatter = talking ? math.sin(_time * 16).abs() * 0.4 : 0.0;
    _beak.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), chatter);
    _head.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 0, 1),
      math.sin(_time * (talking ? 3 : 1.2)) * 0.18,
    );
  }
}

/// Sir Shelldon: an ancient tortoise in a tiny top hat.
class Tortoise extends Actor {
  Tortoise() {
    final skin = matte(const Color(0xFF8DBF6A), roughness: 0.8);
    final shell = matte(const Color(0xFF3E7D3A), roughness: 0.6);
    final plates = matte(const Color(0xFF6B9B3A), roughness: 0.7);

    root
      ..add(
        meshNode(
          reshaped(sphereBand(radius: 1, to: 1.62), vm.Vector3(0.5, 0.42, 0.6)),
          shell..doubleSided = true,
          position: vm.Vector3(0, 0.16, 0),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            CylinderGeometry(height: 0.06),
            vm.Vector3(1.02, 1, 1.22),
          ),
          matte(const Color(0xFFE8D2A8)),
          position: vm.Vector3(0, 0.15, 0),
        ),
      );
    // Raised plates on the shell.
    for (final (x, z) in [
      (0.0, 0.0),
      (0.2, 0.2),
      (-0.2, 0.2),
      (0.2, -0.2),
      (-0.2, -0.2),
      (0.0, 0.33),
      (0.0, -0.33),
    ]) {
      final y = 0.16 +
          0.42 *
              math.sqrt(
                math.max(
                  0,
                  1 - (x / 0.5) * (x / 0.5) - (z / 0.6) * (z / 0.6),
                ),
              );
      root.add(
        meshNode(
          reshaped(
            IcosphereGeometry(radius: 0.12, subdivisions: 1),
            vm.Vector3(1, 0.3, 1),
          ),
          plates,
          position: vm.Vector3(x, y - 0.02, z),
        ),
      );
    }
    for (final (x, z) in [
      (-0.33, 0.3),
      (0.33, 0.3),
      (-0.33, -0.3),
      (0.33, -0.3),
    ]) {
      root.add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.09, topRadius: 0.08, height: 0.2),
          skin,
          position: vm.Vector3(x, 0.1, z),
        ),
      );
    }
    root.add(_neck..position = vm.Vector3(0, 0.3, 0.52));
    _neck
      ..add(
        meshNode(
          CapsuleGeometry(radius: 0.09, height: 0.22),
          skin,
          position: vm.Vector3(0, 0.08, 0),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.5),
        ),
      )
      ..add(_head..position = vm.Vector3(0, 0.25, 0.1));
    _head
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.15, segments: 22, rings: 14),
            vm.Vector3(1, 0.9, 1.15),
          ),
          skin,
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0])
          _eye(0.04, vm.Vector3(side * 0.07, 0.05, 0.12)),
      ])
      // Sleepy eyelids.
      ..addAll([
        for (final side in [-1.0, 1.0])
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.045, segments: 14, rings: 8),
              vm.Vector3(1.05, 0.55, 1),
            ),
            skin,
            position: vm.Vector3(side * 0.07, 0.075, 0.12),
          ),
      ])
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.05, -0.05, 0.15),
              vm.Vector3(0, -0.07, 0.165),
              vm.Vector3(0.05, -0.05, 0.15),
            ]),
            radius: 0.007,
            radialSegments: 6,
            stations: 10,
          ),
          matte(const Color(0xFF2B2B2B)),
        ),
      )
      // A distinguished little top hat.
      ..add(
        Node()
          ..position = vm.Vector3(0.02, 0.12, -0.01)
          ..rotation = vm.Quaternion.axisAngle(_forward, -0.2)
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: 0.11,
                topRadius: 0.11,
                height: 0.012,
              ),
              matte(const Color(0xFF22222A)),
            ),
          )
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: 0.065,
                topRadius: 0.07,
                height: 0.12,
              ),
              matte(const Color(0xFF22222A)),
              position: vm.Vector3(0, 0.06, 0),
            ),
          )
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: 0.068,
                topRadius: 0.068,
                height: 0.02,
                topCap: false,
                bottomCap: false,
              ),
              matte(const Color(0xFFE5534B)),
              position: vm.Vector3(0, 0.02, 0),
            ),
          ),
      );
  }

  @override
  final Node root = Node(name: 'tortoise');
  final Node _neck = Node(name: 'neck');
  final Node _head = Node(name: 'head');
  double _time = 0;

  @override
  double get eyeHeight => 0.6;

  @override
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    // Slow nods while talking; a stately little hop when cheering.
    final nod = talking ? math.sin(_time * 3) * 0.12 : math.sin(_time) * 0.03;
    _head.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), nod);
    final stretch = cheering ? 0.06 + math.sin(_time * 6) * 0.04 : 0.0;
    _neck.position = vm.Vector3(0, 0.3 + stretch, 0.52 + stretch);
    final hop = cheering ? math.sin(_time * 6).abs() * 0.05 : 0.0;
    root.position = vm.Vector3(root.position.x, hop, root.position.z);
  }
}

/// Jag: a smug, golden jaguar sitting up tall.
class Jaguar extends Actor {
  Jaguar() {
    final fur = matte(const Color(0xFFE8A33D), roughness: 0.7);
    final cream = matte(const Color(0xFFF4E3C3), roughness: 0.7);
    final spot = matte(const Color(0xFF4A3426), roughness: 0.8);

    root
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.25, segments: 26),
            vm.Vector3(1, 1.3, 1),
          ),
          fur,
          position: vm.Vector3(0, 0.36, -0.05),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.16, segments: 20, rings: 12),
            vm.Vector3(1, 1.4, 0.6),
          ),
          cream,
          position: vm.Vector3(0, 0.4, 0.12),
        ),
      )
      // Haunches and paws.
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.14, segments: 18, rings: 10),
              vm.Vector3(0.8, 0.9, 1.3),
            ),
            fur,
            position: vm.Vector3(side * 0.17, 0.12, -0.02),
          ),
          meshNode(
            CapsuleGeometry(radius: 0.055, height: 0.28),
            fur,
            position: vm.Vector3(side * 0.1, 0.2, 0.16),
          ),
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.065, segments: 14, rings: 8),
              vm.Vector3(1, 0.7, 1.3),
            ),
            cream,
            position: vm.Vector3(side * 0.1, 0.04, 0.2),
          ),
        ],
      ]);
    // Rosette spots over the body.
    final random = math.Random(4);
    for (var i = 0; i < 16; i++) {
      final a =
          random.nextDouble() * math.pi * 1.4 - math.pi * 0.2 + math.pi / 2;
      final y = 0.2 + random.nextDouble() * 0.36;
      final ry =
          0.25 * math.sqrt(math.max(0.2, 1 - math.pow((y - 0.36) / 0.33, 2)));
      root.add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.025, segments: 8, rings: 6),
            vm.Vector3(1, 1, 0.4),
          ),
          spot,
          position: vm.Vector3(
            math.cos(a) * ry * (random.nextBool() ? 1 : -1),
            y,
            -0.05 - math.sin(a) * ry * 0.9,
          ),
        ),
      );
    }

    root.add(_tail);
    _tail.add(
      meshNode(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3(0, 0.1, -0.28),
            vm.Vector3(0.18, 0.06, -0.38),
            vm.Vector3(0.36, 0.12, -0.3),
            vm.Vector3(0.42, 0.3, -0.18),
          ]),
          radius: 0.04,
          radialSegments: 10,
          stations: 20,
        ),
        fur,
      ),
    );

    root.add(_head..position = vm.Vector3(0, 0.78, 0.02));
    _head
      ..add(
        meshNode(SphereGeometry(radius: 0.2, segments: 28, rings: 18), fur),
      )
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.1, segments: 18, rings: 12),
            vm.Vector3(1.3, 0.8, 0.9),
          ),
          cream,
          position: vm.Vector3(0, -0.06, 0.15),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.035, segments: 12, rings: 8),
            vm.Vector3(1.3, 0.8, 0.8),
          ),
          matte(const Color(0xFF6B3A3A), roughness: 0.4),
          position: vm.Vector3(0, -0.02, 0.235),
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            CylinderGeometry(bottomRadius: 0.07, topRadius: 0, height: 0.12),
            fur,
            position: vm.Vector3(side * 0.13, 0.17, -0.02),
            rotation: vm.Quaternion.axisAngle(_forward, -side * 0.35),
          ),
          meshNode(
            CylinderGeometry(bottomRadius: 0.04, topRadius: 0, height: 0.07),
            cream,
            position: vm.Vector3(side * 0.13, 0.16, 0),
            rotation: vm.Quaternion.axisAngle(_forward, -side * 0.35),
          ),
          // Half-closed, smug eyes.
          _eye(0.04, vm.Vector3(side * 0.08, 0.04, 0.16)),
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.045, segments: 14, rings: 8),
              vm.Vector3(1.1, 0.5, 1),
            ),
            fur,
            position: vm.Vector3(side * 0.08, 0.07, 0.165),
          ),
          for (final (x, y) in [(0.06, 0.12), (0.12, 0.06), (-0.0, 0.15)])
            meshNode(
              reshaped(
                SphereGeometry(radius: 0.02, segments: 8, rings: 6),
                vm.Vector3(1, 1, 0.4),
              ),
              spot,
              position: vm.Vector3(side * x, y, 0.1 + (0.15 - y) * 0.4),
            ),
        ],
      ])
      // A cheeky grin.
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.06, -0.08, 0.2),
              vm.Vector3(0, -0.1, 0.225),
              vm.Vector3(0.07, -0.07, 0.2),
            ]),
            radius: 0.008,
            radialSegments: 6,
            stations: 10,
          ),
          matte(const Color(0xFF2B2B2B)),
        ),
      );
  }

  @override
  final Node root = Node(name: 'jaguar');
  final Node _head = Node(name: 'head');
  final Node _tail = Node(name: 'tail');
  double _time = 0;

  @override
  double get eyeHeight => 0.85;

  @override
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    _tail.rotation = vm.Quaternion.axisAngle(
      _up,
      math.sin(_time * (cheering ? 6 : 1.6)) * 0.3,
    );
    final tilt = talking ? math.sin(_time * 5) * 0.12 : 0.08;
    _head.rotation = vm.Quaternion.axisAngle(_forward, tilt);
    final hop = cheering ? math.sin(_time * 8).abs() * 0.08 : 0.0;
    root.position = vm.Vector3(root.position.x, hop, root.position.z);
  }
}
