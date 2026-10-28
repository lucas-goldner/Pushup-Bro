import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/critters.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The reptiles of the Jungle Trek, built from primitives like Carlos.
///
/// Every reptile faces +Z and stands on y = 0. Its `color` tints its scales
/// (a chameleon's changes mid-fight); `hit`, `lunge` and `defeat` play short
/// reactions on top of its idle animation.

final vm.Vector3 _up = vm.Vector3(0, 1, 0);

Color _lighter(Color color, double amount) =>
    Color.lerp(color, const Color(0xFFFFFFFF), amount)!;

Color _darker(Color color, double amount) =>
    Color.lerp(color, const Color(0xFF000000), amount)!;

/// A big cute eye: white, a dark pupil and a sparkle.
Node _eye(double radius, vm.Vector3 at) => Node(name: 'eye')
  ..position = at
  ..add(
    meshNode(
      SphereGeometry(radius: radius, segments: 16, rings: 10),
      matte(const Color(0xFFFFFFFF), roughness: 0.3),
    ),
  )
  ..add(
    meshNode(
      SphereGeometry(radius: radius * 0.6, segments: 14, rings: 8),
      matte(const Color(0xFF15141B), roughness: 0.1),
      position: vm.Vector3(0, 0, radius * 0.55),
    ),
  )
  ..add(
    meshNode(
      SphereGeometry(radius: radius * 0.2, segments: 8, rings: 6),
      UnlitMaterial()..baseColorFactor = linearColor(const Color(0xFFFFFFFF)),
      position: vm.Vector3(radius * 0.25, radius * 0.3, radius * 1.05),
    ),
  );

/// An angry little eyebrow over an eye at [at], slanting down to the
/// middle.
Node _brow(double side, vm.Vector3 at, Material material) => meshNode(
      reshaped(
        CuboidGeometry(vm.Vector3.all(1)),
        vm.Vector3(0.09, 0.022, 0.03),
      ),
      material,
      position: at,
      rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), side * 0.35),
    );

/// A tail of shrinking spheres along [points].
List<Node> _tail(List<vm.Vector3> points, double radius, Material material) => [
      for (final (i, point) in points.indexed)
        meshNode(
          SphereGeometry(
            radius: radius * (1 - i / points.length * 0.8),
            segments: 16,
            rings: 10,
          ),
          material,
          position: point,
        ),
    ];

/// Any Trek enemy.
abstract class Reptile extends Actor {
  Reptile(Color color) : _base = color {
    _skin = matte(color, roughness: 0.6);
    _belly = matte(_lighter(color, 0.55), roughness: 0.7);
    _accent = matte(_darker(color, 0.35), roughness: 0.6);
    root.add(body);
  }

  @override
  final Node root = Node(name: 'reptile');

  /// Everything that squashes, lunges and spins; [root] only places it.
  final Node body = Node(name: 'body');

  late final PhysicallyBasedMaterial _skin;
  late final PhysicallyBasedMaterial _belly;
  late final PhysicallyBasedMaterial _accent;
  Color _base;
  double _time = math.Random().nextDouble() * 10;
  double _hit = 0;
  double _lunge = 0;
  double _defeat = -1;

  /// How tall it is, for hanging a health bar over it.
  double get height;

  @override
  double get eyeHeight => height * 0.8;

  Color get color => _base;
  set color(Color value) {
    _base = value;
    _belly.baseColorFactor = linearColor(_lighter(value, 0.55));
    _accent.baseColorFactor = linearColor(_darker(value, 0.35));
  }

  /// Gone after its defeat animation.
  bool get gone => _defeat >= 1;

  void hit() => _hit = 1;

  void lunge() => _lunge = 1;

  void defeat() {
    if (_defeat < 0) _defeat = 0;
  }

  /// The idle, between reactions.
  void animate(double time);

  @override
  void update(double deltaSeconds) {
    _time += deltaSeconds;
    _hit = math.max(0, _hit - deltaSeconds * 3);
    _lunge = math.max(0, _lunge - deltaSeconds * 2.2);
    if (_defeat >= 0) _defeat = math.min(1, _defeat + deltaSeconds * 1.6);

    // Flash white when hit.
    _skin.baseColorFactor = linearColor(
      Color.lerp(_base, const Color(0xFFFFFFFF), _hit * 0.75)!,
    );
    final squash = math.sin(_hit * math.pi) * 0.25;
    final leap = math.sin(_lunge * math.pi);
    final gone = _defeat < 0 ? 0.0 : _defeat;
    body
      ..position = vm.Vector3(0, leap * 0.25 + gone * 0.6, leap * 0.9)
      ..scale = vm.Vector3(
            1 + squash * 0.6,
            1 - squash,
            1 + squash * 0.6,
          ) *
          (1 - gone)
      ..rotation = vm.Quaternion.axisAngle(_up, gone * math.pi * 3);
    if (gone >= 1) root.visible = false;
    animate(_time);
  }
}

/// A gecko (or, [skinny], a skink): a small lizard up on four legs.
class Gecko extends Reptile {
  Gecko(super.color, {this.skinny = false, double size = 1.6}) {
    body.scale = vm.Vector3.all(size);
    _size = size;
    final length = skinny ? 1.35 : 1.0;
    _torso
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.15, segments: 24, rings: 14),
            vm.Vector3(1, 0.68, 1.8 * length),
          ),
          _skin,
        ),
      )
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.13, segments: 20, rings: 12),
            vm.Vector3(0.95, 0.4, 1.7 * length),
          ),
          _belly,
          position: vm.Vector3(0, -0.04, 0),
        ),
      )
      ..add(_head..position = vm.Vector3(0, 0.07, 0.28 * length + 0.04));
    _head
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.13, segments: 22, rings: 14),
            vm.Vector3(1.05, 0.8, 1.15),
          ),
          _skin,
        ),
      )
      ..add(_eye(0.05, vm.Vector3(-0.07, 0.07, 0.07)))
      ..add(_eye(0.05, vm.Vector3(0.07, 0.07, 0.07)))
      ..add(_brow(1, vm.Vector3(-0.07, 0.125, 0.1), _accent))
      ..add(_brow(-1, vm.Vector3(0.07, 0.125, 0.1), _accent))
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.06, -0.035, 0.12),
              vm.Vector3(0, -0.05, 0.14),
              vm.Vector3(0.06, -0.035, 0.12),
            ]),
            radius: 0.008,
            radialSegments: 6,
            stations: 10,
          ),
          matte(const Color(0xFF2B2B2B)),
        ),
      );
    if (skinny) {
      // Racing stripes down the back.
      for (final x in [-0.05, 0.05]) {
        _torso.add(
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.04, segments: 10, rings: 6),
              vm.Vector3(0.4, 0.4, 6),
            ),
            _accent,
            position: vm.Vector3(x, 0.085, 0),
          ),
        );
      }
    }
    for (final (x, z) in [(-1, 1), (1, 1), (-1, -1), (1, -1)]) {
      _torso
        ..add(
          meshNode(
            CapsuleGeometry(radius: 0.035, height: 0.12),
            _skin,
            position: vm.Vector3(x * 0.13, -0.07, z * 0.15 * length),
            rotation: vm.Quaternion.fromTwoVectors(
              _up,
              vm.Vector3(x * 1.0, -0.8, 0),
            ),
          ),
        )
        ..add(
          meshNode(
            reshaped(SphereGeometry(radius: 0.04), vm.Vector3(1.3, 0.5, 1.3)),
            _belly,
            position: vm.Vector3(x * 0.19, -0.13, z * 0.15 * length + 0.02),
          ),
        );
    }
    _torso.addAll(
      _tail(
        [
          for (var i = 0; i < 7; i++)
            vm.Vector3(
              math.sin(i * 0.6) * 0.04 * i,
              -0.02 - i * 0.012,
              -0.25 * length - i * 0.07,
            ),
        ],
        0.07,
        _skin,
      ),
    );
    body.add(_torso..position = vm.Vector3(0, 0.15, 0));
  }

  final bool skinny;
  late final double _size;
  final Node _torso = Node(name: 'torso');
  final Node _head = Node(name: 'head');

  @override
  double get height => 0.38 * _size;

  @override
  void animate(double time) {
    final speed = skinny ? 7.0 : 3.0;
    _torso.position =
        vm.Vector3(0, 0.15 + math.sin(time * speed).abs() * 0.02, 0);
    _head.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 0, 1),
      math.sin(time * 1.4) * 0.15 + (talking ? math.sin(time * 14) * 0.1 : 0),
    );
  }
}

/// A big iguana with a spiky back and a dewlap.
class Iguana extends Gecko {
  Iguana(super.color) : super(size: 2.2) {
    for (var i = 0; i < 6; i++) {
      _torso.add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.03,
            topRadius: 0,
            height: 0.09 - i * 0.008,
            radialSegments: 8,
          ),
          _accent,
          position: vm.Vector3(0, 0.12 - i * 0.005, 0.2 - i * 0.08),
        ),
      );
    }
    _head.add(
      meshNode(
        reshaped(
          SphereGeometry(radius: 0.06, segments: 14, rings: 8),
          vm.Vector3(0.35, 1.2, 1),
        ),
        _belly,
        position: vm.Vector3(0, -0.09, 0.03),
      ),
    );
  }
}

/// A crocodile, low and long with a toothy grin; half in the water at y 0.
class Croc extends Reptile {
  Croc(super.color) {
    final teeth = matte(const Color(0xFFF4EDE1), roughness: 0.4);
    body
      ..scale = vm.Vector3.all(1.5)
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.2, segments: 26, rings: 14),
            vm.Vector3(1, 0.6, 2.4),
          ),
          _skin,
          position: vm.Vector3(0, 0.05, 0),
        ),
      )
      ..add(_jaw..position = vm.Vector3(0, 0.08, 0.38));
    // Ridged back.
    for (var i = 0; i < 7; i++) {
      body.add(
        meshNode(
          reshaped(
            IcosphereGeometry(radius: 0.05, subdivisions: 1),
            vm.Vector3(1, 0.6, 1),
          ),
          _accent,
          position: vm.Vector3(0, 0.16, 0.3 - i * 0.12),
        ),
      );
    }
    _jaw
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(0.24, 0.1, 0.36),
          ),
          _skin,
          position: vm.Vector3(0, 0, 0.14),
        ),
      )
      ..add(_eye(0.055, vm.Vector3(-0.08, 0.1, -0.02)))
      ..add(_eye(0.055, vm.Vector3(0.08, 0.1, -0.02)))
      ..add(_brow(1, vm.Vector3(-0.08, 0.16, 0.01), _accent))
      ..add(_brow(-1, vm.Vector3(0.08, 0.16, 0.01), _accent))
      ..addAll([
        for (final x in [-0.1, -0.05, 0.0, 0.05, 0.1])
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.015,
              topRadius: 0,
              height: 0.04,
              radialSegments: 6,
            ),
            teeth,
            position: vm.Vector3(x, -0.06, 0.3),
            rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi),
          ),
      ]);
    body.addAll(
      _tail(
        [
          for (var i = 0; i < 6; i++)
            vm.Vector3(math.sin(i * 0.7) * 0.05, 0.03, -0.45 - i * 0.1),
        ],
        0.11,
        _skin,
      ),
    );
  }

  final Node _jaw = Node(name: 'jaw');

  @override
  double get height => 0.45;

  @override
  void animate(double time) {
    // Bobbing in the water, jaw snapping now and then.
    body.position += vm.Vector3(0, math.sin(time * 1.6) * 0.03, 0);
    final snap = math.max(0, math.sin(time * 2.5)) * 0.3;
    _jaw.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -snap * 0.4);
  }
}

/// A chameleon with a curly tail, turret eyes and a crest, whose colour
/// shifts.
class Chameleon extends Reptile {
  Chameleon(super.color) {
    body
      ..scale = vm.Vector3.all(1.8)
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.17, segments: 24, rings: 14),
            vm.Vector3(0.75, 1.15, 1.3),
          ),
          _skin,
          position: vm.Vector3(0, 0.27, 0),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.14, segments: 22, rings: 12),
            vm.Vector3(0.75, 1, 1.15),
          ),
          _skin,
          position: vm.Vector3(0, 0.36, 0.2),
        ),
      )
      // The casque: a crest sweeping back over the head.
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.08,
            topRadius: 0,
            height: 0.2,
            radialSegments: 12,
          ),
          _accent,
          position: vm.Vector3(0, 0.47, 0.13),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.7),
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.06, segments: 16, rings: 10),
              vm.Vector3(1, 1, 1),
            ),
            _skin,
            position: vm.Vector3(side * 0.09, 0.39, 0.25),
          ),
          _eye(0.04, vm.Vector3(side * 0.11, 0.39, 0.29)),
          for (final z in [0.12, -0.1])
            meshNode(
              CapsuleGeometry(radius: 0.03, height: 0.16),
              _skin,
              position: vm.Vector3(side * 0.08, 0.1, z),
            ),
        ],
      ])
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(-0.05, 0.31, 0.34),
              vm.Vector3(0, 0.3, 0.36),
              vm.Vector3(0.05, 0.31, 0.34),
            ]),
            radius: 0.007,
            radialSegments: 6,
            stations: 10,
          ),
          matte(const Color(0xFF2B2B2B)),
        ),
      )
      // The curled tail.
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(0, 0.22, -0.2),
              vm.Vector3(0, 0.1, -0.33),
              for (var i = 0; i <= 12; i++)
                vm.Vector3(
                  0,
                  0.12 + math.sin(i / 12 * math.pi * 2) * 0.09 * (1 - i / 16),
                  -0.35 + math.cos(i / 12 * math.pi * 2) * 0.09 * (1 - i / 16),
                ),
            ]),
            radius: 0.03,
            radialSegments: 8,
            stations: 40,
          ),
          _skin,
        ),
      )
      // Belly stripes.
      ..addAll([
        for (final y in [0.18, 0.27, 0.36])
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.05, segments: 10, rings: 6),
              vm.Vector3(2.6, 0.35, 1),
            ),
            _belly,
            position: vm.Vector3(0, y, 0.2),
          ),
      ]);
  }

  @override
  double get height => 0.95;

  @override
  void animate(double time) {
    body.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 0, 1),
      math.sin(time * 1.2) * 0.06,
    );
  }
}

/// A coiled snake with its head raised.
class Snake extends Reptile {
  Snake(super.color) {
    for (var i = 0; i < 3; i++) {
      body.add(
        meshNode(
          TorusGeometry(
            radius: 0.22 - i * 0.05,
            tubeRadius: 0.075 - i * 0.008,
            tubularSegments: 12,
          ),
          i.isEven ? _skin : _accent,
          position: vm.Vector3(0, 0.07 + i * 0.12, 0),
        ),
      );
    }
    body
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(0.1, 0.38, 0),
              vm.Vector3(0.02, 0.55, 0.04),
              vm.Vector3(0, 0.66, 0.1),
            ]),
            radius: 0.06,
            stations: 16,
          ),
          _skin,
        ),
      )
      ..add(_head..position = vm.Vector3(0, 0.72, 0.15));
    _head
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.11, segments: 22, rings: 14),
            vm.Vector3(1.15, 0.75, 1.3),
          ),
          _skin,
        ),
      )
      ..add(_eye(0.045, vm.Vector3(-0.06, 0.05, 0.08)))
      ..add(_eye(0.045, vm.Vector3(0.06, 0.05, 0.08)))
      ..add(_brow(1, vm.Vector3(-0.06, 0.1, 0.1), _accent))
      ..add(_brow(-1, vm.Vector3(0.06, 0.1, 0.1), _accent))
      ..add(_tongue..position = vm.Vector3(0, -0.03, 0.14));
    final red = matte(const Color(0xFFE5374B), roughness: 0.5);
    _tongue
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.008, topRadius: 0.008, height: 0.1),
          red,
          position: vm.Vector3(0, 0, 0.05),
          rotation: vm.Quaternion.fromTwoVectors(_up, vm.Vector3(0, 0, 1)),
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0])
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.006,
              topRadius: 0.006,
              height: 0.04,
            ),
            red,
            position: vm.Vector3(side * 0.012, 0, 0.11),
            rotation: vm.Quaternion.fromTwoVectors(
              _up,
              vm.Vector3(side * 0.6, 0, 1),
            ),
          ),
      ]);
    body.scale = vm.Vector3.all(1.5);
  }

  final Node _head = Node(name: 'head');
  final Node _tongue = Node(name: 'tongue');

  @override
  double get height => 1.15;

  @override
  void animate(double time) {
    _head.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 1, 0),
      math.sin(time * 1.1) * 0.25,
    );
    final flick = (time * 1.7) % 1 < 0.25;
    _tongue.scale = vm.Vector3.all(flick ? 1 : 0.01);
  }
}

/// King Komo as an enemy: the Lizard King himself, as big as Carlos,
/// doing pushups on his own mat in a duel with him. A glowing ring under
/// him shows the colour of his current phase.
class KingKomo extends Reptile {
  KingKomo() : super(const Color(0xFF4FB35A)) {
    rig
      ..look = MonkeyLook.kingKomo
      ..activity = GorillaActivity.idle
      ..settle();
    _aura.baseColorFactor = linearColor(const Color(0xFF4FB35A));
    body
      ..add(rig.root)
      ..add(
        meshNode(
          RingGeometry(innerRadius: 0.55, outerRadius: 0.75, segments: 64),
          _aura,
          position: vm.Vector3(0, 0.03, 0),
        ),
      );
  }

  final GorillaRig rig = GorillaRig();
  final UnlitMaterial _aura = UnlitMaterial();

  @override
  double get height => 1.15;

  @override
  set color(Color value) {
    super.color = value;
    _aura.baseColorFactor = linearColor(value);
  }

  @override
  void animate(double time) {}

  @override
  void update(double deltaSeconds) {
    super.update(deltaSeconds);
    rig.update(deltaSeconds);
  }
}
