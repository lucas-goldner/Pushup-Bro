import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _wood = Color(0xFFC8955F);
const _darkWood = Color(0xFF8E6038);
const _ribbon = Color(0xFFF26B5B);
const _gold = Color(0xFFF2C14E);
const _pink = Color(0xFFF4A6A6);
const _white = Color(0xFFFAF8F4);
const _pot = Color(0xFFD9785A);

/// How high (m) a crate starts its fall, and how long it takes.
const _dropHeight = 7.0;
const _fallSeconds = 3.2;

/// Most crates shown at once; more wait their turn.
const _maxCrates = 6;

/// Where crates land around their anchor, in metres: a loose pile.
const _slots = [
  (0.0, 0.0),
  (-1.1, 0.2),
  (1.1, 0.25),
  (-0.5, 0.75),
  (0.6, -0.6),
  (-1.0, -0.65),
];

/// Crates are drawn a little bigger than life, to read from up high.
const _crateScale = 1.35;

/// Gifts friends dropped from the airport, as crates on the island: each
/// floats down on a parachute, lands with a bounce and then hops now and
/// then until it's opened. Add [root] to the scene, call [sync] with the
/// drops to show and [update] every frame.
class IslandDrops {
  final Node root = Node(name: 'drops');
  final Map<String, _Crate> _crates = {};
  double _time = 0;

  /// Called once a falling crate touches the ground.
  void Function(GiftDrop drop)? onLanded;

  /// Shows [drops] (up to six). New ones fall from the sky when [fall],
  /// otherwise they're already there, like gifts that came while away.
  void sync(List<GiftDrop> drops, {bool fall = false}) {
    final shown = drops.take(_maxCrates).toList();
    final ids = {for (final drop in shown) drop.id};
    for (final id in [..._crates.keys]) {
      if (ids.contains(id)) continue;
      root.remove(_crates.remove(id)!.node);
    }
    final used = {for (final crate in _crates.values) crate.slot};
    for (final drop in shown) {
      if (_crates.containsKey(drop.id)) continue;
      final slot = List.generate(_maxCrates, (i) => i)
          .firstWhere((i) => !used.contains(i), orElse: () => 0);
      used.add(slot);
      final crate = _Crate.build(drop, slot: slot, fall: fall);
      _crates[drop.id] = crate;
      root.add(crate.node);
    }
  }

  /// The drop whose crate [node] is part of, if any.
  GiftDrop? dropOf(Node node) {
    for (final crate in _crates.values) {
      for (Node? n = node; n != null; n = n.parent) {
        if (identical(n, crate.node)) return crate.drop;
      }
    }

    return null;
  }

  /// Just above each crate, for its sender's name tag.
  Iterable<(GiftDrop, vm.Vector3)> get tagSpots => [
        for (final crate in _crates.values)
          // Every other tag sits higher, so neighbours' don't overlap.
          (
            crate.drop,
            crate.node.position +
                vm.Vector3(0, crate.slot.isOdd ? 1.3 : 0.75, 0),
          ),
      ];

  /// Moves the crates on for [deltaSeconds]; [anchor] is the spot on the
  /// ground they land around.
  void update(double deltaSeconds, {required vm.Vector3 anchor}) {
    _time += deltaSeconds;
    for (final crate in _crates.values) {
      final (dx, dz) = _slots[crate.slot];
      final ground = vm.Vector3(anchor.x + dx, anchor.y, anchor.z + dz);
      if (crate.fall < 1) {
        crate.fall = math.min(1, crate.fall + deltaSeconds / _fallSeconds);
        // Slow and steady under the canopy, swaying a little.
        final height = _dropHeight * (1 - crate.fall);
        final sway =
            math.sin(_time * 2.2 + crate.slot) * 0.12 * (1 - crate.fall);
        crate.node
          ..scale = vm.Vector3.all(_crateScale)
          ..position = ground + vm.Vector3(sway, height, 0)
          ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), sway * 0.8);
        if (crate.fall >= 1) {
          crate.landed = 0;
          onLanded?.call(crate.drop);
        }
        continue;
      }
      crate.landed += deltaSeconds;
      // Squash on landing, then spring back.
      final squash = crate.landed < 0.45
          ? 1 - 0.22 * math.sin(crate.landed / 0.45 * math.pi)
          : 1.0;
      // Every few seconds a little hop, so it looks worth a tap.
      final beat = (_time + crate.slot * 0.7) % 3.6;
      final hop = beat < 0.36 ? math.sin(beat / 0.36 * math.pi) * 0.09 : 0.0;
      crate.node
        ..position = ground + vm.Vector3(0, hop, 0)
        ..rotation = yaw(crate.slot * 0.9)
        ..scale = vm.Vector3(2 - squash, squash, 2 - squash) * _crateScale;
      // The canopy folds away once it's down.
      final canopy = crate.canopy;
      if (canopy.visible) {
        final fold = math.max(0, 1 - crate.landed / 0.5).toDouble();
        canopy.scale = vm.Vector3(fold, fold, fold);
        if (fold <= 0) canopy.visible = false;
      }
    }
  }
}

class _Crate {
  _Crate(this.drop, this.node, this.canopy, {required this.slot});

  factory _Crate.build(GiftDrop drop, {required int slot, required bool fall}) {
    final node = Node(name: 'drop')..add(_body(drop.gift));
    final canopy = _canopy();
    node.add(canopy);
    bakeStatic(node, moving: {canopy});
    final crate = _Crate(drop, node, canopy, slot: slot);
    if (!fall) {
      crate
        ..fall = 1
        ..landed = 10;
      canopy.visible = false;
    }

    return crate;
  }

  final GiftDrop drop;
  final Node node;
  final Node canopy;
  final int slot;

  /// 0 to 1 on the way down.
  double fall = 0;

  /// Seconds since it landed.
  double landed = 0;
}

Node _box(vm.Vector3 size, Color color, vm.Vector3 position) => meshNode(
      reshaped(CuboidGeometry(vm.Vector3.all(1)), size),
      matte(color, roughness: 0.75),
      position: position,
    );

/// The gift itself, standing on the ground at the origin.
Node _body(GiftKind gift) {
  if (gift == GiftKind.flowers) {
    final bouquet = Node(name: 'bouquet')
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.13, topRadius: 0.17, height: 0.22),
          matte(_pot),
          position: vm.Vector3(0, 0.11, 0),
        ),
      );
    final random = math.Random(5);
    for (var i = 0; i < 2; i++) {
      bouquet.add(
        flowers(random)
          ..position = vm.Vector3(i == 0 ? -0.04 : 0.05, 0.2, 0)
          ..scale = vm.Vector3.all(0.9),
      );
    }

    return bouquet;
  }
  final (shell, trim, band) = switch (gift) {
    GiftKind.small => (_wood, _darkWood, _darkWood),
    GiftKind.big => (_pink, _white, _ribbon),
    GiftKind.golden => (_gold, _white, _ribbon),
    GiftKind.flowers => (_wood, _darkWood, _darkWood),
  };
  const size = 0.38;
  final crate = Node(name: 'crate')
    ..add(_box(vm.Vector3.all(size), shell, vm.Vector3(0, size / 2, 0)))
    // Bands round the middle both ways, like a tied parcel.
    ..add(
      _box(
        vm.Vector3(size + 0.02, size + 0.02, 0.07),
        band,
        vm.Vector3(0, size / 2, 0),
      ),
    )
    ..add(
      _box(
        vm.Vector3(0.07, size + 0.02, size + 0.02),
        band,
        vm.Vector3(0, size / 2, 0),
      ),
    )
    // A trim on the lid's edge.
    ..add(
      _box(
        vm.Vector3(size + 0.03, 0.04, size + 0.03),
        trim,
        vm.Vector3(0, size, 0),
      ),
    );
  if (gift != GiftKind.small) {
    // A bow on top.
    for (final side in [-1, 1]) {
      crate.add(
        meshNode(
          sphere(0.07),
          matte(band, roughness: 0.6),
          position: vm.Vector3(side * 0.06, size + 0.06, 0),
        ),
      );
    }
  } else {
    // A banana stencilled on the front.
    crate.add(
      banana()
        ..scale = vm.Vector3.all(0.55)
        ..position = vm.Vector3(0, size / 2, size / 2 + 0.03),
    );
  }

  return crate;
}

/// A striped parachute over the gift, with its cords.
Node _canopy() {
  final canopy = Node(name: 'canopy')
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.52, topRadius: 0.14, height: 0.26),
        matte(_ribbon, roughness: 0.6),
        position: vm.Vector3(0, 1.12, 0),
      ),
    )
    ..add(
      meshNode(
        CylinderGeometry(bottomRadius: 0.15, topRadius: 0.02, height: 0.1),
        matte(_white),
        position: vm.Vector3(0, 1.3, 0),
      ),
    );
  final cord = matte(_white);
  for (final (x, z) in [(1, 1), (1, -1), (-1, 1), (-1, -1)]) {
    final from = vm.Vector3(x * 0.16, 0.4, z * 0.16);
    final to = vm.Vector3(x * 0.34, 1, z * 0.34);
    final node = meshNode(
      CylinderGeometry(
        bottomRadius: 0.008,
        topRadius: 0.008,
        height: (to - from).length,
      ),
      cord,
    );
    placeBetween(node, from, to);
    canopy.add(node);
  }

  return canopy;
}
