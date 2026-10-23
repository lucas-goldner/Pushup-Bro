import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart' show GorillaRig;
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Procedural hats, eyewear, outfits and mats for [GorillaRig]'s looks.
///
/// Hats and eyewear are built in the head's space (radius 0.36, face
/// towards +Z); outfits in the torso's (+Y up the body, belly towards +Z).
/// Nodes named `spin` are turned around +Y every frame by the rig.

const _navy = Color(0xFF17203A);
const _white = Color(0xFFFAF8F4);
const _red = Color(0xFFE5534B);
const _yellow = Color(0xFFF5C343);
const _pink = Color(0xFFF26B8A);
const _blue = Color(0xFF4D7CF0);

final vm.Vector3 _yAxis = vm.Vector3(0, 1, 0);
final vm.Vector3 _zAxis = vm.Vector3(0, 0, 1);

PhysicallyBasedMaterial _gold() =>
    matte(const Color(0xFFE8B83A), roughness: 0.3)..metallicFactor = 0.85;

PhysicallyBasedMaterial _glossy(Color color) => matte(color, roughness: 0.15);

/// A sphere's surface between polar angles [from] and [to] (0 at +Y), open
/// at both ends: a dome when [from] is 0, a band otherwise.
MeshGeometry sphereBand({
  required double radius,
  double from = 0,
  double to = math.pi / 2,
  int segments = 40,
  int rings = 12,
}) {
  final builder = GeometryBuilder(deduplicate: false);
  final grid = <List<int>>[];
  for (var i = 0; i <= rings; i++) {
    final polar = from + (to - from) * i / rings;
    final row = <int>[];
    for (var j = 0; j <= segments; j++) {
      final azimuth = j / segments * math.pi * 2;
      final normal = vm.Vector3(
        math.sin(polar) * math.cos(azimuth),
        math.cos(polar),
        math.sin(polar) * math.sin(azimuth),
      );
      builder.normal(normal);
      row.add(builder.addVertex(normal * radius));
    }
    grid.add(row);
  }
  for (var i = 0; i < rings; i++) {
    for (var j = 0; j < segments; j++) {
      final upper = grid[i];
      final lower = grid[i + 1];
      builder
        ..addTriangle(upper[j], upper[j + 1], lower[j])
        ..addTriangle(upper[j + 1], lower[j + 1], lower[j]);
    }
  }

  return builder.build();
}

/// A flat five-pointed star of outer radius [radius] and [depth], facing
/// +Z.
MeshGeometry starPrism(double radius, double depth) {
  final builder = GeometryBuilder(deduplicate: false);
  final outline = [
    for (var i = 0; i < 10; i++)
      vm.Vector2(
        math.sin(i / 10 * math.pi * 2) * (i.isEven ? radius : radius * 0.45),
        math.cos(i / 10 * math.pi * 2) * (i.isEven ? radius : radius * 0.45),
      ),
  ];
  for (final side in [1.0, -1.0]) {
    builder.normal(vm.Vector3(0, 0, side));
    final center = builder.addVertex(vm.Vector3(0, 0, side * depth / 2));
    final ring = [
      for (final p in outline)
        builder.addVertex(vm.Vector3(p.x, p.y, side * depth / 2)),
    ];
    for (var i = 0; i < 10; i++) {
      final j = (i + 1) % 10;
      if (side > 0) {
        builder.addTriangle(center, ring[j], ring[i]);
      } else {
        builder.addTriangle(center, ring[i], ring[j]);
      }
    }
  }

  return builder.build();
}

Node _part(
  Geometry geometry,
  Material material, {
  vm.Vector3? at,
  vm.Quaternion? rotation,
  String name = '',
}) =>
    meshNode(
      geometry,
      material,
      position: at,
      rotation: rotation,
      name: name,
    );

/// The hat for cosmetic [id], or null for none.
Node? buildHat(String id) => switch (id) {
      'hat.party' => _partyHat(),
      'hat.sweatband' => _sweatband(),
      'hat.cap' => _cap(),
      'hat.beanie' => _beanie(),
      'hat.banana' => _bananaHat(),
      'hat.flowers' => _flowerCrown(),
      'hat.chef' => _chefHat(),
      'hat.propeller' => _propellerCap(),
      'hat.top' => _topHat(),
      'hat.cowboy' => _cowboyHat(),
      'hat.pirate' => _pirateHat(),
      'hat.wizard' => _wizardHat(),
      'hat.viking' => _vikingHelmet(),
      'hat.crown' => _crown(),
      'hat.halo' => _halo(),
      'hat.gecko' => _geckoBuddy(),
      'hat.lizardcrown' => _lizardCrown(),
      _ => null,
    };

Node _partyHat() {
  final hat = Node(name: 'party-hat')
    ..position = vm.Vector3(-0.1, 0.32, -0.02)
    ..rotation = vm.Quaternion.fromTwoVectors(_yAxis, vm.Vector3(-0.3, 1, 0));
  const height = 0.36;
  const bottomRadius = 0.13;
  const bands = 5;
  for (var i = 0; i < bands; i++) {
    final r0 = bottomRadius * (1 - i / bands);
    final r1 = bottomRadius * (1 - (i + 1) / bands);
    hat.add(
      _part(
        CylinderGeometry(
          bottomRadius: r0,
          topRadius: r1,
          height: height / bands,
          bottomCap: i == 0,
          topCap: false,
        ),
        matte(i.isEven ? const Color(0xFFF0707E) : _white, roughness: 0.6),
        at: vm.Vector3(0, height / bands * (i + 0.5), 0),
      ),
    );
  }

  return hat
    ..add(
      _part(
        SphereGeometry(radius: 0.045),
        matte(_yellow, roughness: 0.9),
        at: vm.Vector3(0, height, 0),
      ),
    );
}

Node _sweatband() => Node(name: 'sweatband')
  ..add(
    _part(
      TorusGeometry(radius: 0.345, tubeRadius: 0.04, tubularSegments: 10),
      matte(_red, roughness: 0.8),
      at: vm.Vector3(0, 0.13, 0),
    ),
  )
  ..add(
    _part(
      TorusGeometry(radius: 0.36, tubeRadius: 0.012, tubularSegments: 8),
      matte(_white),
      at: vm.Vector3(0, 0.13, 0),
    ),
  );

Node _cap() {
  final cap = matte(_blue, roughness: 0.7);

  return Node(name: 'cap')
    ..add(
      _part(
        reshaped(sphereBand(radius: 1, to: 1.22), vm.Vector3.all(0.375)),
        cap..doubleSided = true,
      ),
    )
    // The brim sticks out over the brow, tipped down a touch.
    ..add(
      _part(
        reshaped(
          CylinderGeometry(bottomRadius: 0.2, topRadius: 0.2, height: 0.02),
          vm.Vector3(1.1, 1, 0.9),
        ),
        matte(_navy, roughness: 0.7),
        at: vm.Vector3(0, 0.15, 0.34),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.25),
      ),
    )
    ..add(
      _part(
        SphereGeometry(radius: 0.035),
        matte(_white),
        at: vm.Vector3(0, 0.375, 0),
      ),
    );
}

Node _beanie() {
  const polar = 1.15;

  return Node(name: 'beanie')
    ..add(
      _part(
        reshaped(sphereBand(radius: 1, to: polar), vm.Vector3.all(0.38)),
        matte(const Color(0xFFE8A33D))..doubleSided = true,
      ),
    )
    ..add(
      _part(
        TorusGeometry(
          radius: math.sin(polar) * 0.38,
          tubeRadius: 0.05,
          tubularSegments: 10,
        ),
        matte(const Color(0xFFD08A28)),
        at: vm.Vector3(0, math.cos(polar) * 0.38, 0),
      ),
    )
    ..add(
      _part(
        IcosphereGeometry(radius: 0.09, subdivisions: 1),
        matte(_red, roughness: 0.95),
        at: vm.Vector3(0, 0.42, 0),
      ),
    );
}

/// A banana lying over the head, its ends drooping to the ears.
Node _bananaHat() => Node(name: 'banana-hat')
  ..add(
    banana()
      ..position = vm.Vector3(0, 0.43, 0.01)
      ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi),
  );

Node _flowerCrown() {
  final crown = Node(name: 'flower-crown');
  const flowers = 8;
  final colors = [_pink, _yellow, const Color(0xFFB98AF2), _white];
  for (var i = 0; i < flowers; i++) {
    final a = i / flowers * math.pi * 2;
    final at = vm.Vector3(math.sin(a) * 0.31, 0.19, math.cos(a) * 0.31);
    final petals = matte(colors[i % colors.length], roughness: 0.6);
    for (var p = 0; p < 5; p++) {
      final pa = p / 5 * math.pi * 2;
      crown.add(
        _part(
          SphereGeometry(radius: 0.032, segments: 10, rings: 8),
          petals,
          at: at + vm.Vector3(math.cos(pa) * 0.035, math.sin(pa) * 0.035, 0),
        ),
      );
    }
    crown.add(
      _part(
        SphereGeometry(radius: 0.022, segments: 10, rings: 8),
        matte(i.isEven ? _yellow : const Color(0xFFFF9F43)),
        at: at + vm.Vector3(0, 0, 0.02),
      ),
    );
  }

  return crown;
}

Node _chefHat() {
  final cloth = matte(_white, roughness: 0.9);

  return Node(name: 'chef-hat')
    ..add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.27,
          topRadius: 0.29,
          height: 0.2,
          topCap: false,
        ),
        cloth,
        at: vm.Vector3(0, 0.32, 0),
      ),
    )
    ..addAll([
      for (final (x, z) in [
        (0.0, 0.0),
        (0.14, 0.08),
        (-0.14, 0.08),
        (0.1, -0.12),
        (-0.1, -0.12),
      ])
        _part(
          IcosphereGeometry(radius: 0.17),
          cloth,
          at: vm.Vector3(x, 0.5, z),
        ),
    ]);
}

Node _propellerCap() {
  final cap = Node(name: 'propeller-cap');
  for (var i = 0; i < 4; i++) {
    // Four coloured wedges of the dome.
    cap.add(
      _part(
        reshaped(
          sphereBand(radius: 1, to: 1.25, segments: 10),
          vm.Vector3.all(0.375),
          rotation: vm.Quaternion.axisAngle(_yAxis, i * math.pi / 2),
        ),
        matte(i.isEven ? _red : _yellow)..doubleSided = true,
      ),
    );
  }
  final blades = Node(name: 'spin')
    ..position = vm.Vector3(0, 0.47, 0)
    ..add(
      _part(
        reshaped(
          CuboidGeometry(vm.Vector3.all(1)),
          vm.Vector3(0.5, 0.01, 0.07),
        ),
        matte(_blue),
      ),
    );

  return cap
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.012, topRadius: 0.012, height: 0.1),
        matte(_navy),
        at: vm.Vector3(0, 0.42, 0),
      ),
    )
    ..add(blades);
}

Node _topHat() {
  final felt = matte(const Color(0xFF22222A), roughness: 0.55);

  return Node(name: 'top-hat')
    ..position = vm.Vector3(0.03, 0, 0)
    ..rotation = vm.Quaternion.axisAngle(_zAxis, -0.12)
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.36, topRadius: 0.36, height: 0.02),
        felt,
        at: vm.Vector3(0, 0.28, 0),
      ),
    )
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.21, topRadius: 0.22, height: 0.38),
        felt,
        at: vm.Vector3(0, 0.47, 0),
      ),
    )
    ..add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.214,
          topRadius: 0.214,
          height: 0.06,
          topCap: false,
          bottomCap: false,
        ),
        matte(_red),
        at: vm.Vector3(0, 0.33, 0),
      ),
    );
}

Node _cowboyHat() {
  final leather = matte(const Color(0xFF9A6B47), roughness: 0.8);

  return Node(name: 'cowboy-hat')
    ..rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.12)
    ..add(
      _part(
        reshaped(
          CylinderGeometry(bottomRadius: 0.46, topRadius: 0.46, height: 0.025),
          vm.Vector3(1, 1, 0.85),
        ),
        leather,
        at: vm.Vector3(0, 0.27, 0),
      ),
    )
    ..addAll([
      for (final side in [-1.0, 1.0])
        _part(
          reshaped(
            TorusGeometry(radius: 0.2, tubeRadius: 0.035),
            vm.Vector3(0.25, 1, 1.9),
          ),
          leather,
          at: vm.Vector3(side * 0.42, 0.31, 0),
        ),
    ])
    ..add(
      _part(
        reshaped(
          IcosphereGeometry(radius: 0.24),
          vm.Vector3(1, 0.8, 1.05),
        ),
        leather,
        at: vm.Vector3(0, 0.37, 0),
      ),
    )
    ..add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.245,
          topRadius: 0.24,
          height: 0.05,
          topCap: false,
          bottomCap: false,
        ),
        matte(_navy),
        at: vm.Vector3(0, 0.31, 0),
      ),
    );
}

Node _pirateHat() => Node(name: 'pirate-hat')
  ..add(
    _part(
      reshaped(
        IcosphereGeometry(radius: 0.3),
        vm.Vector3(1.55, 0.75, 0.55),
      ),
      matte(const Color(0xFF22222A), roughness: 0.6),
      at: vm.Vector3(0, 0.4, 0),
    ),
  )
  ..add(
    _part(
      reshaped(
        TorusGeometry(radius: 0.3, tubeRadius: 0.015),
        vm.Vector3(1.5, 1, 0.55),
      ),
      _gold(),
      at: vm.Vector3(0, 0.33, 0),
    ),
  )
  // Skull and crossbones on the front.
  ..add(
    _part(
      SphereGeometry(radius: 0.045, segments: 16, rings: 10),
      matte(_white),
      at: vm.Vector3(0, 0.44, 0.15),
    ),
  )
  ..addAll([
    for (final a in [0.6, -0.6])
      _part(
        CylinderGeometry(bottomRadius: 0.01, topRadius: 0.01, height: 0.13),
        matte(_white),
        at: vm.Vector3(0, 0.39, 0.155),
        rotation: vm.Quaternion.axisAngle(_zAxis, a),
      ),
  ]);

Node _wizardHat() {
  final cloth = matte(const Color(0xFF5B3FB5), roughness: 0.7);
  final hat = Node(name: 'wizard-hat')
    ..rotation = vm.Quaternion.axisAngle(_zAxis, 0.1)
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.42, topRadius: 0.42, height: 0.02),
        cloth,
        at: vm.Vector3(0, 0.27, 0),
      ),
    )
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.26, topRadius: 0, height: 0.62),
        cloth,
        at: vm.Vector3(0, 0.58, 0),
      ),
    );
  final star = matte(_yellow, roughness: 0.4);
  for (final (x, y, z, size) in [
    (0.1, 0.45, 0.17, 0.05),
    (-0.08, 0.62, 0.11, 0.035),
    (0.04, 0.75, 0.07, 0.03),
  ]) {
    hat.add(
      _part(
        starPrism(size, 0.015),
        star,
        at: vm.Vector3(x, y, z),
      ),
    );
  }

  return hat;
}

Node _vikingHelmet() {
  final metal = matte(const Color(0xFFB8BECB), roughness: 0.35)
    ..metallicFactor = 0.7
    ..doubleSided = true;
  final horn = matte(const Color(0xFFF1E6CF), roughness: 0.6);
  final helmet = Node(name: 'viking-helmet')
    ..add(
      _part(
        reshaped(sphereBand(radius: 1, to: 1.2), vm.Vector3.all(0.385)),
        metal,
      ),
    )
    ..add(
      _part(
        TorusGeometry(radius: 0.355, tubeRadius: 0.035, tubularSegments: 10),
        _gold(),
        at: vm.Vector3(0, 0.14, 0),
      ),
    );
  for (final side in [-1.0, 1.0]) {
    helmet
      ..add(
        _part(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(side * 0.3, 0.2, 0),
              vm.Vector3(side * 0.45, 0.26, 0),
              vm.Vector3(side * 0.52, 0.42, 0),
            ]),
            radius: 0.05,
            radialSegments: 10,
            stations: 12,
          ),
          horn,
        ),
      )
      ..add(
        _part(
          CylinderGeometry(bottomRadius: 0.05, topRadius: 0, height: 0.14),
          horn,
          at: vm.Vector3(side * 0.53, 0.48, 0),
          rotation: vm.Quaternion.axisAngle(_zAxis, -side * 0.25),
        ),
      );
  }

  return helmet;
}

Node _crown() {
  final gold = _gold();
  final crown = Node(name: 'crown')
    ..add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.24,
          topRadius: 0.26,
          height: 0.12,
          topCap: false,
          bottomCap: false,
        ),
        gold..doubleSided = true,
        at: vm.Vector3(0, 0.36, 0),
      ),
    );
  for (var i = 0; i < 6; i++) {
    final a = i / 6 * math.pi * 2;
    crown
      ..add(
        _part(
          CylinderGeometry(bottomRadius: 0.06, topRadius: 0, height: 0.12),
          gold,
          at: vm.Vector3(math.sin(a) * 0.25, 0.47, math.cos(a) * 0.25),
        ),
      )
      ..add(
        _part(
          SphereGeometry(radius: 0.022, segments: 12, rings: 8),
          _glossy(i.isEven ? _red : _blue),
          at: vm.Vector3(math.sin(a) * 0.262, 0.36, math.cos(a) * 0.262),
        ),
      );
  }

  return crown;
}

Node _halo() => Node(name: 'spin')
  ..position = vm.Vector3(0, 0.55, 0)
  ..add(
    _part(
      TorusGeometry(radius: 0.22, tubeRadius: 0.028),
      UnlitMaterial()..baseColorFactor = linearColor(const Color(0xFFFFE27A)),
    ),
  );

/// A little gecko napping on top of the head.
Node _geckoBuddy() {
  final skin = matte(const Color(0xFF5DBB63), roughness: 0.6);

  return Node(name: 'gecko-buddy')
    ..position = vm.Vector3(0, 0.36, -0.02)
    ..add(
      _part(
        reshaped(SphereGeometry(radius: 0.1), vm.Vector3(0.8, 0.55, 1.5)),
        skin,
      ),
    )
    ..add(
      _part(
        reshaped(SphereGeometry(radius: 0.075), vm.Vector3(1, 0.75, 1.15)),
        skin,
        at: vm.Vector3(0, 0.03, 0.16),
      ),
    )
    ..addAll([
      for (final side in [-1.0, 1.0]) ...[
        _part(
          SphereGeometry(radius: 0.022, segments: 12, rings: 8),
          _glossy(const Color(0xFF15141B)),
          at: vm.Vector3(side * 0.045, 0.07, 0.2),
        ),
        for (final z in [-0.08, 0.08])
          _part(
            reshaped(SphereGeometry(radius: 0.03), vm.Vector3(1.6, 0.5, 0.9)),
            skin,
            at: vm.Vector3(side * 0.08, -0.03, z),
          ),
      ],
    ])
    ..add(
      _part(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3(0, 0, -0.13),
            vm.Vector3(0.06, -0.03, -0.24),
            vm.Vector3(0, -0.08, -0.32),
            vm.Vector3(-0.06, -0.08, -0.36),
          ]),
          radius: 0.025,
          radialSegments: 8,
          stations: 16,
        ),
        skin,
      ),
    );
}

/// The Lizard King's crown: tall gold spikes and emeralds.
Node _lizardCrown() {
  final gold = _gold();
  final crown = Node(name: 'lizard-crown')
    ..add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.25,
          topRadius: 0.27,
          height: 0.12,
          topCap: false,
          bottomCap: false,
        ),
        gold..doubleSided = true,
        at: vm.Vector3(0, 0.34, 0),
      ),
    );
  for (var i = 0; i < 7; i++) {
    final a = i / 7 * math.pi * 2;
    final tall = i == 0 ? 0.24 : 0.16;
    crown
      ..add(
        _part(
          CylinderGeometry(bottomRadius: 0.055, topRadius: 0, height: tall),
          gold,
          at: vm.Vector3(
            math.sin(a) * 0.255,
            0.4 + tall / 2,
            math.cos(a) * 0.255,
          ),
        ),
      )
      ..add(
        _part(
          IcosphereGeometry(radius: i == 0 ? 0.04 : 0.024, subdivisions: 1),
          _glossy(const Color(0xFF2FA37A)),
          at: vm.Vector3(math.sin(a) * 0.272, 0.34, math.cos(a) * 0.272),
        ),
      );
  }

  return crown;
}

/// The eyewear for cosmetic [id], or null for none.
Node? buildEyewear(String id) => switch (id) {
      'eyes.shades' => _glasses(
          lens: (side) => _part(
            reshaped(
              SphereGeometry(radius: 0.08, segments: 20, rings: 12),
              vm.Vector3(1.15, 0.85, 0.35),
            ),
            _glossy(const Color(0xFF15141B)),
          ),
          frame: _navy,
        ),
      'eyes.nerd' => _glasses(
          lens: (side) => _part(
            TorusGeometry(radius: 0.07, tubeRadius: 0.012),
            matte(const Color(0xFF6B4A2F)),
            rotation: vm.Quaternion.fromTwoVectors(_yAxis, _zAxis),
          ),
          frame: const Color(0xFF6B4A2F),
        ),
      'eyes.hearts' => _glasses(
          lens: (side) => _heartLens(),
          frame: _pink,
        ),
      'eyes.stars' => _glasses(
          lens: (side) => _part(starPrism(0.09, 0.02), _glossy(_yellow)),
          frame: _yellow,
        ),
      'eyes.mustache' => _mustache(),
      'eyes.monocle' => _monocle(),
      'eyes.visor' => _visor(),
      'eyes.chameleon' => _chameleonEyes(),
      _ => null,
    };

Node _glasses({
  required Node Function(double side) lens,
  required Color frame,
}) {
  final material = matte(frame, roughness: 0.4);
  final glasses = Node(name: 'glasses')
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.01, topRadius: 0.01, height: 0.07),
        material,
        at: vm.Vector3(0, 0.06, 0.41),
        rotation: vm.Quaternion.axisAngle(_zAxis, math.pi / 2),
      ),
    );
  for (final side in [-1.0, 1.0]) {
    glasses
      ..add(lens(side)..position = vm.Vector3(side * 0.092, 0.05, 0.41))
      // Arms running back to the ears.
      ..add(
        _part(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(side * 0.16, 0.06, 0.38),
              vm.Vector3(side * 0.27, 0.06, 0.28),
              vm.Vector3(side * 0.33, 0.05, 0.1),
            ]),
            radius: 0.009,
            radialSegments: 6,
            stations: 10,
          ),
          material,
        ),
      );
  }

  return glasses;
}

Node _heartLens() {
  final red = _glossy(const Color(0xFFE5374B));

  return Node(name: 'heart')
    ..addAll([
      for (final x in [-0.03, 0.03])
        _part(
          reshaped(
            SphereGeometry(radius: 0.042, segments: 14, rings: 10),
            vm.Vector3(1, 1, 0.45),
          ),
          red,
          at: vm.Vector3(x, 0.015, 0),
        ),
    ])
    ..add(
      _part(
        reshaped(
          CuboidGeometry(vm.Vector3.all(1)),
          vm.Vector3(0.062, 0.062, 0.035),
          rotation: vm.Quaternion.axisAngle(_zAxis, math.pi / 4),
        ),
        red,
        at: vm.Vector3(0, -0.02, 0),
      ),
    );
}

Node _mustache() {
  final hair = matte(const Color(0xFF4A3426), roughness: 0.9);

  return Node(name: 'mustache')
    ..addAll([
      for (final side in [-1.0, 1.0])
        _part(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3(0, -0.085, 0.41),
              vm.Vector3(side * 0.06, -0.1, 0.41),
              vm.Vector3(side * 0.11, -0.085, 0.39),
              vm.Vector3(side * 0.13, -0.05, 0.37),
            ]),
            radius: 0.022,
            radialSegments: 10,
            stations: 16,
          ),
          hair,
        ),
    ]);
}

Node _monocle() {
  final gold = _gold();

  return Node(name: 'monocle')
    ..add(
      _part(
        TorusGeometry(radius: 0.072, tubeRadius: 0.012),
        gold,
        at: vm.Vector3(0.092, 0.05, 0.415),
        rotation: vm.Quaternion.fromTwoVectors(_yAxis, _zAxis),
      ),
    )
    ..add(
      _part(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3(0.15, 0, 0.4),
            vm.Vector3(0.19, -0.12, 0.36),
            vm.Vector3(0.2, -0.22, 0.3),
          ]),
          radius: 0.006,
          radialSegments: 5,
          stations: 12,
        ),
        gold,
      ),
    );
}

Node _visor() => Node(name: 'visor')
  ..add(
    _part(
      reshaped(
        sphereBand(radius: 1, from: 1.2, to: 1.75, segments: 48, rings: 4),
        vm.Vector3(0.39, 0.39, 0.4),
      ),
      UnlitMaterial()
        ..baseColorFactor = linearColor(const Color(0xFF5CE1E6))
        ..doubleSided = true,
      at: vm.Vector3(0, -0.05, 0),
    ),
  );

/// Chameleon eyes: two swivelling cone turrets.
Node _chameleonEyes() {
  final skin = matte(const Color(0xFF8B5FD9), roughness: 0.6);

  return Node(name: 'chameleon-eyes')
    ..addAll([
      for (final side in [-1.0, 1.0]) ...[
        _part(
          CylinderGeometry(
            bottomRadius: 0.075,
            topRadius: 0.05,
            height: 0.09,
            radialSegments: 16,
          ),
          skin,
          at: vm.Vector3(side * 0.092, 0.05, 0.41),
          rotation: vm.Quaternion.fromTwoVectors(
            _yAxis,
            vm.Vector3(side * 0.3, 0.1, 1),
          ),
        ),
        _part(
          SphereGeometry(radius: 0.04, segments: 16, rings: 10),
          _glossy(_yellow),
          at: vm.Vector3(side * 0.106, 0.055, 0.455),
        ),
        _part(
          SphereGeometry(radius: 0.02, segments: 12, rings: 8),
          _glossy(const Color(0xFF15141B)),
          at: vm.Vector3(side * 0.11, 0.057, 0.488),
        ),
      ],
    ]);
}

/// A cord with crocodile teeth around the neck.
Node _toothNecklace() {
  final cord = matte(const Color(0xFF6B4A2F), roughness: 0.9);
  final tooth = matte(const Color(0xFFF4EDE1), roughness: 0.4);
  final necklace = Node(name: 'tooth-necklace')
    ..position = vm.Vector3(0, 0.22, 0.03)
    ..rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.4)
    ..add(
      _part(
        TorusGeometry(radius: 0.19, tubeRadius: 0.01, tubularSegments: 8),
        cord,
      ),
    );
  for (var i = -3; i <= 3; i++) {
    final a = i * 0.32;
    necklace.add(
      _part(
        CylinderGeometry(
          bottomRadius: 0,
          topRadius: 0.024,
          height: i == 0 ? 0.09 : 0.065,
          radialSegments: 8,
        ),
        tooth,
        at: vm.Vector3(math.sin(a) * 0.19, -0.03, math.cos(a) * 0.19),
      ),
    );
  }

  return necklace;
}

/// A costume lizard tail, curling out behind.
Node _lizardTail() {
  final scales = matte(const Color(0xFF3FAE6A), roughness: 0.7);
  final tail = Node(name: 'costume-tail');
  for (var i = 0; i < 7; i++) {
    final t = i / 6;
    tail.add(
      _part(
        SphereGeometry(radius: 0.12 * (1 - t * 0.75), segments: 18),
        scales,
        at: vm.Vector3(
          math.sin(t * 2.2) * 0.12,
          -0.2 - t * 0.12,
          -0.16 - t * 0.5,
        ),
      ),
    );
  }

  return tail;
}

/// The parts of outfit [id]: on the torso, and on each forearm (the right,
/// on -X, first).
({List<Node> torso, List<Node> forearms}) buildOutfit(String id) =>
    switch (id) {
      'outfit.wristbands' => (
          torso: const <Node>[],
          forearms: [_wristband(), _wristband()],
        ),
      'outfit.bowtie' => (torso: [_bowTie()], forearms: const <Node>[]),
      'outfit.tank' => (torso: _tankTop(), forearms: const <Node>[]),
      'outfit.scarf' => (torso: [_scarf()], forearms: const <Node>[]),
      'outfit.lei' => (torso: [_lei()], forearms: const <Node>[]),
      'outfit.tutu' => (torso: [_tutu()], forearms: const <Node>[]),
      'outfit.cape' => (torso: [_cape()], forearms: const <Node>[]),
      'outfit.chain' => (torso: [_chain()], forearms: const <Node>[]),
      'outfit.tooth' => (torso: [_toothNecklace()], forearms: const <Node>[]),
      'outfit.tail' => (torso: [_lizardTail()], forearms: const <Node>[]),
      _ => (torso: const <Node>[], forearms: const <Node>[]),
    };

Node _wristband() => _part(
      TorusGeometry(radius: 0.08, tubeRadius: 0.03, tubularSegments: 10),
      matte(_red),
      at: vm.Vector3(0, -0.05, 0),
    );

Node _bowTie() {
  final cloth = matte(_red, roughness: 0.6);

  return Node(name: 'bow-tie')
    ..position = vm.Vector3(0, 0.25, 0.17)
    ..addAll([
      for (final side in [-1.0, 1.0])
        _part(
          CylinderGeometry(
            bottomRadius: 0.06,
            topRadius: 0.01,
            height: 0.1,
            radialSegments: 12,
          ),
          cloth,
          at: vm.Vector3(side * 0.05, 0, 0),
          rotation: vm.Quaternion.axisAngle(_zAxis, side * math.pi / 2),
        ),
    ])
    ..add(_part(SphereGeometry(radius: 0.025), cloth));
}

List<Node> _tankTop() {
  final shirt = matte(_red, roughness: 0.8)..doubleSided = true;

  return [
    _part(
      reshaped(
        sphereBand(radius: 1, from: 0.55, to: 2.35),
        vm.Vector3(0.285, 0.33, 0.265),
      ),
      shirt,
    ),
    _part(
      reshaped(
        TorusGeometry(radius: 1, tubeRadius: 0.05, tubularSegments: 8),
        vm.Vector3(0.198, 0.33, 0.185),
      ),
      matte(_white),
      at: vm.Vector3(0, -0.23, 0),
    ),
    _part(
      starPrism(0.07, 0.01),
      matte(_white),
      at: vm.Vector3(0, 0.02, 0.266),
    ),
  ];
}

Node _scarf() {
  final wool = matte(const Color(0xFF2FA37A), roughness: 0.95);

  return Node(name: 'scarf')
    ..add(
      _part(
        TorusGeometry(radius: 0.17, tubeRadius: 0.06, tubularSegments: 10),
        wool,
        at: vm.Vector3(0, 0.26, 0.02),
      ),
    )
    ..add(
      _part(
        TubeGeometry(
          CatmullRomPath([
            vm.Vector3(0.1, 0.24, 0.18),
            vm.Vector3(0.13, 0.12, 0.25),
            vm.Vector3(0.14, -0.02, 0.27),
          ]),
          radius: 0.045,
          radialSegments: 8,
          stations: 10,
        ),
        wool,
      ),
    );
}

Node _lei() {
  final lei = Node(name: 'lei')
    ..position = vm.Vector3(0, 0.22, 0.02)
    ..rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.35);
  const flowers = 14;
  for (var i = 0; i < flowers; i++) {
    final a = i / flowers * math.pi * 2;
    lei.add(
      _part(
        IcosphereGeometry(radius: 0.045, subdivisions: 1),
        matte(
          [_pink, _yellow, const Color(0xFFFF9F43)][i % 3],
          roughness: 0.7,
        ),
        at: vm.Vector3(math.sin(a) * 0.2, 0, math.cos(a) * 0.19),
      ),
    );
  }

  return lei;
}

Node _tutu() {
  final tulle = matte(const Color(0xFFF7A8C8), roughness: 0.9)
    ..doubleSided = true;

  return Node(name: 'tutu')
    ..addAll([
      for (final (y, r) in [(-0.14, 0.42), (-0.1, 0.38)])
        _part(
          CylinderGeometry(
            bottomRadius: r,
            topRadius: 0.25,
            height: 0.08,
            radialSegments: 18,
            topCap: false,
            bottomCap: false,
          ),
          tulle,
          at: vm.Vector3(0, y, 0),
        ),
    ]);
}

Node _cape() {
  final cloth = matte(_red, roughness: 0.7)..doubleSided = true;

  return Node(name: 'cape')
    ..add(
      _part(
        RibbonGeometry(
          CatmullRomPath([
            vm.Vector3(0, 0.26, -0.18),
            vm.Vector3(0, 0.05, -0.3),
            vm.Vector3(0, -0.3, -0.36),
          ]),
          width: 0.46,
          stations: 16,
          alignment: RibbonAlignment.path,
          up: vm.Vector3(0, 0, 1),
        ),
        cloth,
      ),
    )
    ..add(
      _part(
        SphereGeometry(radius: 0.035),
        _gold(),
        at: vm.Vector3(0, 0.25, 0.17),
      ),
    );
}

Node _chain() {
  final gold = _gold();

  return Node(name: 'chain')
    ..add(
      _part(
        TorusGeometry(radius: 0.2, tubeRadius: 0.016, tubularSegments: 8),
        gold,
        at: vm.Vector3(0, 0.2, 0.04),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.45),
      ),
    )
    ..add(
      _part(
        CylinderGeometry(bottomRadius: 0.06, topRadius: 0.06, height: 0.02),
        gold,
        at: vm.Vector3(0, 0.08, 0.25),
        rotation: vm.Quaternion.fromTwoVectors(_yAxis, vm.Vector3(0, 0.3, 1)),
      ),
    );
}

/// An exercise mat in [look]'s colour and pattern, its top 0.022 above the
/// ground, about 1 by 1.8 metres times [size] (long along Z).
Node buildMat(MonkeyLook look, {double size = 1}) => meshNode(
      matGeometry(look.matBaseColor, look.matPattern, size: size),
      PhysicallyBasedMaterial()
        ..metallicFactor = 0
        ..roughnessFactor = 0.7,
      name: 'mat',
    );

/// The mat's mesh with vertex colours; see [buildMat].
MeshGeometry matGeometry(Color base, String pattern, {double size = 1}) {
  final builder = GeometryBuilder(deduplicate: false);
  final a = 0.5 * size;
  final b = 0.9 * size;
  const top = 0.022;
  const segments = 72;
  final baseColor = linearColor(base);
  final edge = linearColor(
    Color.from(
      alpha: 1,
      red: base.r * 0.8,
      green: base.g * 0.8,
      blue: base.b * 0.8,
    ),
  );

  // The top: a fan in the base colour.
  builder
    ..color(baseColor)
    ..normal(vm.Vector3(0, 1, 0));
  final center = builder.addVertex(vm.Vector3(0, top, 0));
  final rim = [
    for (var i = 0; i < segments; i++)
      builder.addVertex(
        vm.Vector3(
          math.cos(i / segments * math.pi * 2) * a,
          top,
          math.sin(i / segments * math.pi * 2) * b,
        ),
      ),
  ];
  for (var i = 0; i < segments; i++) {
    builder.addTriangle(center, rim[(i + 1) % segments], rim[i]);
  }

  // The side, a shade darker.
  builder.color(edge);
  for (var i = 0; i < segments; i++) {
    final a0 = i / segments * math.pi * 2;
    final a1 = (i + 1) / segments * math.pi * 2;
    builder.normal(
      vm.Vector3(math.cos((a0 + a1) / 2), 0, math.sin((a0 + a1) / 2)),
    );
    final p0 = vm.Vector3(math.cos(a0) * a, top, math.sin(a0) * b);
    final p1 = vm.Vector3(math.cos(a1) * a, top, math.sin(a1) * b);
    final i0 = builder.addVertex(p0);
    final i1 = builder.addVertex(p1);
    final i2 = builder.addVertex(p1..y = 0);
    final i3 = builder.addVertex(p0..y = 0);
    builder
      ..addTriangle(i0, i1, i2)
      ..addTriangle(i0, i2, i3);
  }

  // The pattern: runs of same-coloured cells just above the top, kept
  // inside a margin so the outline stays smooth.
  if (pattern != 'pattern.solid') {
    builder.normal(vm.Vector3(0, 1, 0));
    const cell = 0.018;
    const lift = top + 0.003;
    final margin = 0.04 * size;
    for (var z = -b; z < b; z += cell) {
      final zc = z + cell / 2;
      Color? runColor;
      double? runStart;
      void flush(double end) {
        final color = runColor;
        final start = runStart;
        if (color == null || start == null) return;
        builder.color(linearColor(color));
        final v0 = builder.addVertex(vm.Vector3(start, lift, z));
        final v1 = builder.addVertex(vm.Vector3(end, lift, z));
        final v2 = builder.addVertex(vm.Vector3(end, lift, z + cell));
        final v3 = builder.addVertex(vm.Vector3(start, lift, z + cell));
        builder
          ..addTriangle(v0, v2, v1)
          ..addTriangle(v0, v3, v2);
      }

      for (var x = -a; x < a; x += cell) {
        final xc = x + cell / 2;
        final inside =
            math.pow(xc / (a - margin), 2) + math.pow(zc / (b - margin), 2) < 1;
        final color = inside
            ? matPatternColor(pattern, base, xc / size, zc / size)
            : null;
        if (color != runColor) {
          flush(x);
          runColor = color;
          runStart = x;
        }
      }
      flush(a);
    }
  }

  return builder.build();
}
