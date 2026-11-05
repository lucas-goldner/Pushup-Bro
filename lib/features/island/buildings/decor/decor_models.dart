import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _white = Color(0xFFFAF8F4);
const _navy = Color(0xFF17203A);
const _wood = Color(0xFFB07A4F);
const _darkWood = Color(0xFF7A5234);
const _sandy = Color(0xFFE9C987);
const _coral = Color(0xFFF26B5B);
const _teal = Color(0xFF5CC6C9);
const _yellow = Color(0xFFFFD23F);
const _pink = Color(0xFFF59AB8);
const _leaf = Color(0xFF4CA85A);
const _water = Color(0xFF5BC0E0);
const _stone = Color(0xFFB9B3A8);
const _straw = Color(0xFFE8C468);
const _gold = Color(0xFFF2C14E);

/// A low-poly model of [item], its base on the ground at the origin and its
/// front towards +Z, about as big as it stands on the island. Built from a
/// handful of plain shapes; bake it before use (see `bakeStatic`).
Node buildDecor(DecorItem item) => switch (item) {
      DecorItem.rubberDucky => _rubberDucky(),
      DecorItem.flowerBed => _flowerBed(),
      DecorItem.sandcastle => _sandcastle(),
      DecorItem.woodenSign => _woodenSign(),
      DecorItem.flamingo => _flamingo(),
      DecorItem.lanternPost => _lanternPost(),
      DecorItem.beachUmbrella => _beachUmbrella(),
      DecorItem.surfboardRack => _surfboardRack(),
      DecorItem.bonfire => _bonfire(),
      DecorItem.picnicTable => _picnicTable(),
      DecorItem.tikiTotem => _tikiTotem(),
      DecorItem.lilyPond => _lilyPond(),
      DecorItem.hammock => _hammock(),
      DecorItem.bananaStatue => _bananaStatue(),
      DecorItem.tikiBar => _tikiBar(),
      DecorItem.goldGorilla => _goldGorilla(),
    };

Node _rubberDucky() => Node(name: 'rubber ducky')
  // A puddle for it to float in.
  ..add(_disc(0.24, _water, 0.012, roughness: 0.15))
  ..add(
    _ball(0.12, _yellow, vm.Vector3(0, 0.09, -0.02), vm.Vector3(1, 0.75, 1.3)),
  )
  ..add(_ball(0.085, _yellow, vm.Vector3(0, 0.22, 0.08)))
  ..add(_box(0.08, 0.03, 0.08, const Color(0xFFFF8C1A), 0, 0.2, 0.17))
  ..add(
    _ball(0.05, _yellow, vm.Vector3(0, 0.15, -0.16), vm.Vector3(1, 1.2, 0.8)),
  )
  ..addAll([
    for (final x in [-0.04, 0.04])
      _ball(0.014, _navy, vm.Vector3(x, 0.25, 0.15)),
  ]);

Node _flowerBed() {
  final random = math.Random(7);
  final bed = Node(name: 'flower bed')
    ..add(_box(0.62, 0.06, 0.4, const Color(0xFF6B4A33), 0, 0.03, 0));
  // A low wooden border.
  for (final z in [-0.21, 0.21]) {
    bed.add(_box(0.68, 0.09, 0.05, _wood, 0, 0.045, z));
  }
  for (final x in [-0.32, 0.32]) {
    bed.add(_box(0.05, 0.09, 0.38, _wood, x, 0.045, 0));
  }
  for (final x in [-0.15, 0.15]) {
    bed.add(flowers(random)..position = vm.Vector3(x, 0.05, 0));
  }

  return bed;
}

Node _sandcastle() {
  final castle = Node(name: 'sandcastle')
    ..add(_box(0.42, 0.16, 0.42, _sandy, 0, 0.08, 0, roughness: 0.95))
    ..add(_box(0.22, 0.14, 0.22, _sandy, 0, 0.23, 0, roughness: 0.95))
    ..add(_box(0.08, 0.1, 0.03, _darkWood, 0, 0.05, 0.21));
  for (final x in [-0.2, 0.2]) {
    for (final z in [-0.2, 0.2]) {
      castle
        ..add(_cyl(0.07, 0.07, 0.24, _sandy, vm.Vector3(x, 0.12, z)))
        ..add(_cyl(0.085, 0, 0.09, _sandy, vm.Vector3(x, 0.285, z)));
    }
  }

  return castle
    ..add(_cyl(0.006, 0.006, 0.16, _darkWood, vm.Vector3(0, 0.38, 0)))
    ..add(_box(0.002, 0.05, 0.08, _coral, 0, 0.43, 0.04));
}

Node _woodenSign() => Node(name: 'wooden sign')
  ..add(_cyl(0.025, 0.025, 0.5, _darkWood, vm.Vector3(0, 0.25, 0)))
  ..add(_box(0.42, 0.2, 0.035, _wood, 0, 0.42, 0.02))
  ..add(
    banana()
      ..scale = vm.Vector3.all(0.42)
      ..position = vm.Vector3(0, 0.42, 0.05),
  );

Node _flamingo() {
  final legs = matte(const Color(0xFFE07B9B));

  return Node(name: 'flamingo')
    ..addAll([
      for (final x in [-0.03, 0.03])
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.008,
            topRadius: 0.008,
            height: 0.3,
            radialSegments: 6,
          ),
          legs,
          position: vm.Vector3(x, 0.15, 0),
        ),
    ])
    ..add(
      _ball(
        0.1,
        _pink,
        vm.Vector3(0, 0.36, -0.02),
        vm.Vector3(0.9, 0.8, 1.4),
      ),
    )
    // An S of a neck: two tilted segments.
    ..add(
      _cyl(
        0.018,
        0.018,
        0.18,
        _pink,
        vm.Vector3(0, 0.48, 0.07),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.5),
      ),
    )
    ..add(
      _cyl(
        0.018,
        0.018,
        0.14,
        _pink,
        vm.Vector3(0, 0.6, 0.08),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.4),
      ),
    )
    ..add(_ball(0.045, _pink, vm.Vector3(0, 0.67, 0.06)))
    ..add(
      _cyl(
        0.014,
        0.004,
        0.07,
        _navy,
        vm.Vector3(0, 0.65, 0.12),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 2.1),
      ),
    );
}

Node _lanternPost() => Node(name: 'lantern post')
  ..add(_cyl(0.07, 0.08, 0.06, _stone, vm.Vector3(0, 0.03, 0)))
  ..add(_cyl(0.025, 0.025, 0.74, _navy, vm.Vector3(0, 0.4, 0)))
  // The lamp: a dark cage around a warm glass that ignores the light.
  ..add(_box(0.14, 0.02, 0.14, _navy, 0, 0.78, 0))
  ..add(
    meshNode(
      reshaped(CuboidGeometry(vm.Vector3.all(1)), vm.Vector3(0.11, 0.13, 0.11)),
      UnlitMaterial()..baseColorFactor = linearColor(const Color(0xFFFFD98A)),
      position: vm.Vector3(0, 0.86, 0),
    ),
  )
  ..add(_cyl(0.1, 0.02, 0.07, _navy, vm.Vector3(0, 0.96, 0), segments: 4));

Node _beachUmbrella() {
  final umbrella = Node(name: 'beach umbrella')
    ..add(_cyl(0.015, 0.015, 0.9, _white, vm.Vector3(-0.1, 0.45, 0)))
    ..add(
      _cyl(0.48, 0.05, 0.16, _coral, vm.Vector3(-0.1, 0.88, 0), segments: 8),
    )
    ..add(_cyl(0.07, 0, 0.06, _white, vm.Vector3(-0.1, 0.99, 0), segments: 8))
    // A towel and a deck chair in its shade.
    ..add(_box(0.24, 0.01, 0.46, _teal, 0.24, 0.005, 0.05));
  // White stripes on the canopy: thin wedges just above it.
  for (var i = 0; i < 4; i++) {
    final angle = i * math.pi / 2;
    umbrella.add(
      _box(
        0.04,
        0.012,
        0.4,
        _white,
        -0.1 + math.sin(angle) * 0.22,
        0.902,
        math.cos(angle) * 0.22,
        rotation:
            yaw(angle) * vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.36),
      ),
    );
  }

  return umbrella
    ..add(
      _box(
        0.2,
        0.02,
        0.24,
        _yellow,
        -0.18,
        0.12,
        0.22,
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.1),
      ),
    )
    ..add(
      _box(
        0.2,
        0.02,
        0.22,
        _yellow,
        -0.18,
        0.2,
        0.05,
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.9),
      ),
    )
    ..addAll([
      for (final x in [-0.27, -0.09])
        for (final z in [0.12, 0.32])
          _cyl(0.008, 0.008, 0.12, _white, vm.Vector3(x, 0.06, z)),
    ]);
}

Node _surfboardRack() {
  final rack = Node(name: 'surfboard rack')
    ..addAll([
      for (final x in [-0.32, 0.32])
        _cyl(0.025, 0.025, 0.5, _darkWood, vm.Vector3(x, 0.25, -0.1)),
    ])
    ..add(
      _cyl(
        0.02,
        0.02,
        0.7,
        _darkWood,
        vm.Vector3(0, 0.46, -0.1),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
      ),
    );
  // Boards leaning on the bar.
  for (final (i, color) in [_coral, _teal, _yellow].indexed) {
    final x = -0.2 + i * 0.2;
    rack
      ..add(
        _ball(
          0.1,
          color,
          vm.Vector3(x, 0.33, 0.02),
          vm.Vector3(0.75, 3.4, 0.2),
          vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.32),
        ),
      )
      ..add(
        _box(
          0.02,
          0.5,
          0.012,
          _white,
          x,
          0.33,
          0.042,
          rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.32),
        ),
      );
  }

  return rack;
}

Node _bonfire() {
  final fire = Node(name: 'bonfire');
  // A ring of stones.
  for (var i = 0; i < 8; i++) {
    final angle = i * math.pi / 4;
    fire.add(
      _ball(
        0.07 + 0.01 * (i % 3),
        i.isEven ? _stone : const Color(0xFF9BA1B0),
        vm.Vector3(math.sin(angle) * 0.3, 0.04, math.cos(angle) * 0.3),
        vm.Vector3(1.2, 0.75, 1),
      ),
    );
  }
  // Logs leaning together.
  for (var i = 0; i < 3; i++) {
    final angle = i * math.pi * 2 / 3;
    fire.add(
      _cyl(
        0.03,
        0.03,
        0.3,
        _darkWood,
        vm.Vector3(math.sin(angle) * 0.08, 0.1, math.cos(angle) * 0.08),
        rotation:
            yaw(angle) * vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -0.7),
      ),
    );
  }

  return fire
    ..add(
      _disc(0.2, const Color(0xFF3B2A1E), 0.008, roughness: 1),
    );
}

Node _picnicTable() {
  const cloth = Color(0xFFE5534B);
  final table = Node(name: 'picnic table')
    ..add(_box(0.7, 0.04, 0.36, _wood, 0, 0.36, 0))
    // A red cloth across the middle.
    ..add(_box(0.3, 0.045, 0.37, cloth, 0, 0.362, 0))
    ..add(_box(0.06, 0.046, 0.37, _white, -0.07, 0.364, 0))
    ..add(_box(0.06, 0.046, 0.37, _white, 0.07, 0.364, 0))
    ..add(_box(0.18, 0.1, 0.12, _straw, 0.18, 0.43, 0))
    ..add(
      banana()
        ..scale = vm.Vector3.all(0.3)
        ..position = vm.Vector3(-0.18, 0.4, 0.04),
    );
  for (final z in [-0.3, 0.3]) {
    table.add(_box(0.7, 0.035, 0.14, _wood, 0, 0.2, z));
  }
  for (final x in [-0.28, 0.28]) {
    for (final z in [-0.3, 0.0, 0.3]) {
      final height = z == 0 ? 0.34 : 0.18;
      table.add(_box(0.04, height, 0.04, _darkWood, x, height / 2, z));
    }
  }

  return table;
}

Node _tikiTotem() {
  final totem = Node(name: 'tiki totem')
    ..add(
      _cyl(
        0.13,
        0.13,
        0.28,
        const Color(0xFF8A5A36),
        vm.Vector3(0, 0.14, 0),
        segments: 8,
      ),
    )
    ..add(
      _cyl(
        0.12,
        0.12,
        0.26,
        const Color(0xFFA5703F),
        vm.Vector3(0, 0.41, 0),
        segments: 8,
      ),
    )
    ..add(
      _cyl(
        0.13,
        0.11,
        0.24,
        const Color(0xFF8A5A36),
        vm.Vector3(0, 0.66, 0),
        segments: 8,
      ),
    );
  // A face on each block: eyes and a big mouth.
  for (final (y, mouth) in [(0.14, 0.12), (0.41, 0.08), (0.66, 0.1)]) {
    totem
      ..add(_box(mouth, 0.04, 0.04, _navy, 0, y - 0.05, 0.115))
      ..addAll([
        for (final x in [-0.05, 0.05])
          _box(
            0.04,
            0.035,
            0.04,
            y == 0.41 ? _yellow : _white,
            x,
            y + 0.04,
            0.11,
          ),
      ]);
  }
  // A crest of leaves on top.
  for (final angle in [-0.6, 0.0, 0.6]) {
    totem.add(
      _ball(
        0.06,
        _leaf,
        vm.Vector3(math.sin(angle) * 0.07, 0.85, 0),
        vm.Vector3(0.6, 1.8, 0.3),
        vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -angle),
      ),
    );
  }

  return totem;
}

Node _lilyPond() {
  final pond = Node(name: 'lily pond')
    ..add(
      meshNode(
        reshaped(
          CylinderGeometry(
            bottomRadius: 0.52,
            topRadius: 0.52,
            height: 0.03,
            radialSegments: 24,
          ),
          vm.Vector3(1, 1, 0.8),
        ),
        matte(_water, roughness: 0.15),
        position: vm.Vector3(0, 0.015, 0),
      ),
    );
  // Stones round the edge.
  for (var i = 0; i < 11; i++) {
    final angle = i * math.pi * 2 / 11;
    pond.add(
      _ball(
        0.06 + 0.015 * (i % 3),
        i % 3 == 0 ? const Color(0xFF9BA1B0) : _stone,
        vm.Vector3(math.sin(angle) * 0.56, 0.03, math.cos(angle) * 0.46),
        vm.Vector3(1.2, 0.7, 1),
      ),
    );
  }
  for (final (x, z, r) in [
    (-0.18, 0.08, 0.09),
    (0.16, -0.1, 0.08),
    (0.05, 0.18, 0.06),
  ]) {
    pond.add(_cyl(r, r, 0.012, _leaf, vm.Vector3(x, 0.035, z), segments: 10));
  }

  return pond
    ..add(
      _ball(
        0.035,
        _pink,
        vm.Vector3(-0.18, 0.06, 0.08),
        vm.Vector3(1, 0.7, 1),
      ),
    )
    ..add(
      _ball(
        0.03,
        _white,
        vm.Vector3(0.16, 0.055, -0.1),
        vm.Vector3(1, 0.7, 1),
      ),
    );
}

Node _hammock() {
  final hammock = Node(name: 'hammock');
  // Two short palm trunks with a tuft each.
  for (final x in [-0.62, 0.62]) {
    hammock
      ..add(
        _cyl(
          0.05,
          0.04,
          0.8,
          const Color(0xFF9A6B47),
          vm.Vector3(x, 0.4, 0),
          segments: 8,
        ),
      )
      ..add(
        _ball(
          0.16,
          _leaf,
          vm.Vector3(x, 0.84, 0),
          vm.Vector3(1.4, 0.45, 1.4),
        ),
      );
  }
  // The cloth sags between them in a few striped slats.
  const slats = 7;
  for (var i = 0; i < slats; i++) {
    final t = (i + 0.5) / slats * 2 - 1;
    final x = t * 0.5;
    final y = 0.36 + 0.2 * t * t;
    final slope = math.atan(0.4 * t);
    hammock.add(
      _box(
        0.15,
        0.02,
        0.3,
        i.isEven ? _teal : _white,
        x,
        y,
        0,
        rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), slope),
      ),
    );
  }

  return hammock
    ..addAll([
      for (final side in [-1, 1])
        _cyl(
          0.006,
          0.006,
          0.12,
          _straw,
          vm.Vector3(side * 0.58, 0.6, 0),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), side * 1.1),
        ),
    ]);
}

Node _bananaStatue() => Node(name: 'banana statue')
  ..add(_box(0.4, 0.12, 0.4, _stone, 0, 0.06, 0))
  ..add(_box(0.3, 0.3, 0.3, const Color(0xFFD9D2C5), 0, 0.27, 0))
  ..add(_box(0.36, 0.05, 0.36, _stone, 0, 0.445, 0))
  ..add(
    meshNode(
      bananaGeometry(),
      _goldMaterial(),
      position: vm.Vector3(0, 0.78, 0),
      rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2.4),
    )..scale = vm.Vector3.all(1.15),
  );

Node _tikiBar() {
  final bar = Node(name: 'tiki bar')
    ..add(_box(0.9, 0.06, 0.7, _wood, 0, 0.09, 0))
    ..add(_box(0.84, 0.36, 0.08, _darkWood, 0, 0.3, 0.26))
    ..add(_box(0.9, 0.04, 0.14, _wood, 0, 0.49, 0.28))
    // Stools along the counter.
    ..addAll([
      for (final x in [-0.25, 0.05, 0.3])
        _cyl(0.05, 0.05, 0.22, _coral, vm.Vector3(x, 0.11, 0.48), segments: 8),
    ])
    // A thatched pyramid roof on four poles.
    ..addAll([
      for (final x in [-0.4, 0.4])
        for (final z in [-0.3, 0.3])
          _cyl(
            0.03,
            0.03,
            0.82,
            _darkWood,
            vm.Vector3(x, 0.47, z),
            segments: 6,
          ),
    ])
    ..add(
      meshNode(
        reshaped(
          CylinderGeometry(
            bottomRadius: 0.78,
            topRadius: 0.04,
            height: 0.4,
            radialSegments: 4,
          ),
          vm.Vector3(1, 1, 0.82),
          rotation: yaw(math.pi / 4),
        ),
        matte(_straw, roughness: 0.95),
        position: vm.Vector3(0, 1.06, 0),
      ),
    )
    ..add(_ball(0.06, const Color(0xFF8A5A36), vm.Vector3(-0.2, 0.57, 0.28)))
    ..add(_cyl(0.03, 0.025, 0.08, _teal, vm.Vector3(0.18, 0.55, 0.28)));

  return bar;
}

Node _goldGorilla() {
  final gold = _goldMaterial();
  Node part(Geometry geometry, vm.Vector3 at, {vm.Quaternion? rotation}) =>
      meshNode(geometry, gold, position: at, rotation: rotation);

  return Node(name: 'gold gorilla')
    ..add(_cyl(0.34, 0.38, 0.12, _stone, vm.Vector3(0, 0.06, 0), segments: 8))
    ..add(
      _cyl(
        0.3,
        0.3,
        0.05,
        const Color(0xFFD9D2C5),
        vm.Vector3(0, 0.145, 0),
        segments: 8,
      ),
    )
    // Carlos flexing, in gold.
    ..add(
      part(
        reshaped(icosphere(0.2), vm.Vector3(1.1, 1, 0.85)),
        vm.Vector3(0, 0.42, 0),
      ),
    )
    ..add(part(icosphere(0.12), vm.Vector3(0, 0.68, 0.03)))
    ..add(
      part(
        reshaped(icosphere(0.06), vm.Vector3(1.2, 0.8, 1)),
        vm.Vector3(0, 0.64, 0.12),
      ),
    )
    ..addAll([
      for (final side in [-1, 1]) ...[
        part(
          capsule(0.05, 0.16, radialSegments: 8, capRings: 3),
          vm.Vector3(side * 0.25, 0.5, 0),
          rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), side * 1.2),
        ),
        part(
          capsule(0.045, 0.14, radialSegments: 8, capRings: 3),
          vm.Vector3(side * 0.33, 0.65, 0),
        ),
        part(
          icosphere(0.055, subdivisions: 1),
          vm.Vector3(side * 0.33, 0.77, 0),
        ),
        part(
          capsule(0.06, 0.1, radialSegments: 8, capRings: 3),
          vm.Vector3(side * 0.1, 0.24, 0),
        ),
      ],
    ]);
}

PhysicallyBasedMaterial _goldMaterial() => PhysicallyBasedMaterial()
  ..baseColorFactor = linearColor(_gold)
  ..metallicFactor = 0.55
  ..roughnessFactor = 0.32;

Node _box(
  double width,
  double height,
  double depth,
  Color color,
  double x,
  double y,
  double z, {
  vm.Quaternion? rotation,
  double roughness = 0.7,
}) =>
    meshNode(
      reshaped(
        CuboidGeometry(vm.Vector3.all(1)),
        vm.Vector3(width, height, depth),
        rotation: rotation,
      ),
      matte(color, roughness: roughness),
      position: vm.Vector3(x, y, z),
    );

Node _cyl(
  double bottom,
  double top,
  double height,
  Color color,
  vm.Vector3 at, {
  vm.Quaternion? rotation,
  int segments = 12,
}) =>
    meshNode(
      CylinderGeometry(
        bottomRadius: bottom,
        topRadius: top,
        height: height,
        radialSegments: segments,
      ),
      matte(color, roughness: 0.75),
      position: at,
      rotation: rotation,
    );

/// A faceted ball, squashed by [scale] (baked in, so it stays lit right).
Node _ball(
  double radius,
  Color color,
  vm.Vector3 at, [
  vm.Vector3? scale,
  vm.Quaternion? rotation,
]) =>
    meshNode(
      scale == null
          ? icosphere(radius, subdivisions: 1)
          : reshaped(
              icosphere(radius, subdivisions: 1),
              scale,
              rotation: rotation,
            ),
      matte(color, roughness: 0.6),
      position: at,
    );

/// A flat disc lying on the ground, just above it.
Node _disc(double radius, Color color, double y, {double roughness = 0.8}) =>
    meshNode(
      DiscGeometry(radius: radius, segments: 24),
      matte(color, roughness: roughness),
      position: vm.Vector3(0, y, 0),
    );
