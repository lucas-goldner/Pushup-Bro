import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_models.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/scene/island_night.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _ringOk = Color(0xFFFFD23F);
const _ringBlocked = Color(0xFFE5534B);
const _flame = Color(0xFFFF7A1A);
const _flameCore = Color(0xFFFFE07A);

/// The decorations standing on an island, at [ground] height. Each kind is
/// modelled and baked once, and every piece of that kind shares its
/// meshes, so a crowded island stays cheap. The bonfire's flame flickers
/// and the bonfire and lanterns glow at night, like the torches.
class DecorLayer {
  DecorLayer({this.ground = 0}) {
    root.add(_ring);
  }

  final double ground;
  final Node root = Node(name: 'decor');
  final List<_Shown> _shown = [];
  double _time = 0;
  bool _night = false;
  int? _selected;

  /// Baked once per kind for the app's lifetime; only clones go on screen.
  static final Map<DecorItem, Node> _models = {};

  static Node model(DecorItem item) => _models.putIfAbsent(item, () {
        final node = buildDecor(item);
        bakeStatic(node);

        return node;
      });

  static final Mesh _flameMesh = () {
    final template = Node()
      ..add(
        meshNode(
          reshaped(sphere(0.07, segments: 12, rings: 8), vm.Vector3(1, 2, 1)),
          UnlitMaterial()..baseColorFactor = linearColor(_flame),
          position: vm.Vector3(0, 0.07, 0),
        ),
      )
      ..add(
        meshNode(
          reshaped(sphere(0.08, segments: 12, rings: 8), vm.Vector3(1, 1.1, 1)),
          UnlitMaterial()..baseColorFactor = linearColor(_flameCore),
        ),
      );
    bakeStatic(template);

    return template.children.singleWhere((n) => n.name == 'baked').mesh!;
  }();

  static final Mesh _haloMesh =
      Mesh(nightGlowDisc(0.34), nightGlow(const Color(0xFFFFB050), 0.6));
  static final Mesh _poolMesh =
      Mesh(nightGlowDisc(1), nightGlow(const Color(0xFFFF9A3C), 0.55));

  final Node _ring = Node(
    name: 'decor ring',
    mesh: Mesh(
      RingGeometry(innerRadius: 0.82, outerRadius: 1, segments: 40),
      UnlitMaterial()..baseColorFactor = linearColor(_ringOk),
    ),
  )
    ..visible = false
    ..shadowCastingMode = ShadowCastingMode.off;

  late final Mesh _ringOkMesh = _ring.mesh!;
  late final Mesh _ringBlockedMesh = Mesh(
    RingGeometry(innerRadius: 0.82, outerRadius: 1, segments: 40),
    UnlitMaterial()..baseColorFactor = linearColor(_ringBlocked),
  );

  /// Shows [pieces] (the ones [DecorPiece.placed]); with [selected], a ring
  /// marks that piece, red while it's [blocked] where it is.
  void show(
    List<DecorPiece> pieces, {
    int? selected,
    bool blocked = false,
  }) {
    for (var i = 0; i < pieces.length; i++) {
      final piece = pieces[i];
      if (i < _shown.length && _shown[i].item != piece.item) {
        root.remove(_shown[i].node);
        _shown[i] = _Shown(piece.item);
        root.add(_shown[i].node);
      } else if (i >= _shown.length) {
        _shown.add(_Shown(piece.item));
        root.add(_shown.last.node);
      }
      _shown[i].node
        ..visible = piece.placed
        ..position = vm.Vector3(piece.x, ground, piece.z)
        ..rotation = yaw(piece.angle);
    }
    while (_shown.length > pieces.length) {
      root.remove(_shown.removeLast().node);
    }
    final ringed =
        selected != null && selected < pieces.length && pieces[selected].placed
            ? pieces[selected]
            : null;
    _selected = ringed == null ? null : selected;
    _ring.visible = ringed != null;
    if (ringed != null) {
      _ring
        ..mesh = blocked ? _ringBlockedMesh : _ringOkMesh
        ..position = vm.Vector3(ringed.x, ground + 0.025, ringed.z)
        ..scale = vm.Vector3.all(ringed.item.radius + 0.1);
    }
    _light();
  }

  /// The index of the piece [node] is part of, or null.
  int? pieceOf(Node node) {
    for (Node? n = node; n != null; n = n.parent) {
      for (final (i, shown) in _shown.indexed) {
        if (identical(n, shown.node)) return shown.node.visible ? i : null;
      }
    }

    return null;
  }

  bool get night => _night;
  set night(bool value) {
    if (value == _night) return;
    _night = value;
    _light();
  }

  void _light() {
    for (final shown in _shown) {
      shown.halo?.visible = _night;
      shown.pool?.visible = _night;
    }
  }

  /// Flickers the flames, turns the night glow towards the [eye] (the
  /// camera) and makes the selection ring breathe.
  void update(double deltaSeconds, {vm.Vector3? eye}) {
    _time += deltaSeconds;
    for (final (i, shown) in _shown.indexed) {
      if (!shown.node.visible) continue;
      final t = _time + i * 1.3;
      final flicker = math.sin(t * 9.1) * 0.6 + math.sin(t * 23.7) * 0.4;
      final flame = shown.flame;
      if (flame != null) {
        final width = 1 + 0.06 * math.sin(t * 13.3);
        flame.scale = vm.Vector3(width, 1 + 0.16 * flicker, width) * 1.5;
      }
      final halo = shown.halo;
      if (halo == null || !_night) continue;
      halo.scale = vm.Vector3.all(1 + 0.08 * flicker);
      shown.pool?.scale = vm.Vector3.all(
        shown.item.radius * 2.2 * (1 + 0.05 * math.sin(t * 7.3)),
      );
      if (eye != null) {
        final at = shown.node.position + vm.Vector3(0, halo.position.y, 0);
        halo.rotation = shown.node.rotation.conjugated() * alongY(eye - at);
      }
    }
    if (_selected != null && _ring.visible) {
      final base = _shown[_selected!].item.radius + 0.1;
      _ring.scale = vm.Vector3.all(base * (1 + 0.05 * math.sin(_time * 5)));
    }
  }
}

/// One piece on screen: a copy of its kind's baked model, and its flame
/// and night glow when it has them.
class _Shown {
  _Shown(this.item) {
    final model = DecorLayer.model(item);
    node.add(model.clone());
    final glow = item.glow;
    if (glow == null) return;
    if (item == DecorItem.bonfire) {
      node.add(
        flame = Node(name: 'flame', mesh: DecorLayer._flameMesh.clone())
          ..position = vm.Vector3(0, glow, 0)
          ..shadowCastingMode = ShadowCastingMode.off,
      );
    }
    node
      ..add(
        halo = Node(name: 'halo', mesh: DecorLayer._haloMesh.clone())
          ..position = vm.Vector3(0, glow + 0.05, 0)
          ..shadowCastingMode = ShadowCastingMode.off
          ..raycastable = false
          ..visible = false,
      )
      // Just above the ground so the warm pool doesn't z-fight with it.
      ..add(
        pool = Node(name: 'pool', mesh: DecorLayer._poolMesh.clone())
          ..position = vm.Vector3(0, 0.014, 0)
          ..shadowCastingMode = ShadowCastingMode.off
          ..raycastable = false
          ..visible = false,
      );
  }

  final DecorItem item;
  final Node node = Node(name: 'decor piece');
  Node? flame;
  Node? halo;
  Node? pool;
}
