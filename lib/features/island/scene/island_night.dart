import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _wood = Color(0xFF6B4226);
const _band = Color(0xFFC89B62);
const _bowl = Color(0xFF3B2A1E);
const _flame = Color(0xFFFF7A1A);
const _core = Color(0xFFFFE07A);

/// Where the flame sits on its pole.
const _flameHeight = 0.8;

/// Torches stand a little bigger than they are built, to read from afar.
const _torchScale = 1.25;

/// How far (m) past the beach the moon's reflection lies on the sea.
const _moonPathDistance = 10.0;

/// What the island adds at night: tiki torches and the moon's path on the
/// sea. Every torch shares the same few meshes, and the flames flicker by
/// scaling their nodes, so nothing is rebuilt while they burn. Built only
/// once night first falls.
class IslandNight {
  IslandNight(int torches) {
    final pole = _merged([
      meshNode(
        CylinderGeometry(bottomRadius: 0.04, topRadius: 0.03, height: 0.72),
        matte(_wood),
        position: vm.Vector3(0, 0.36, 0),
      ),
      meshNode(
        CylinderGeometry(bottomRadius: 0.045, topRadius: 0.045, height: 0.05),
        matte(_band),
        position: vm.Vector3(0, 0.62, 0),
      ),
      meshNode(
        CylinderGeometry(bottomRadius: 0.035, topRadius: 0.08, height: 0.1),
        matte(_bowl),
        position: vm.Vector3(0, 0.75, 0),
      ),
    ]);
    // A yellow base under an orange tip, merged into one unlit mesh.
    final flame = _merged([
      meshNode(
        reshaped(SphereGeometry(radius: 0.065), vm.Vector3(1, 1.9, 1)),
        UnlitMaterial()..baseColorFactor = linearColor(_flame),
        position: vm.Vector3(0, 0.06, 0),
      ),
      meshNode(
        reshaped(SphereGeometry(radius: 0.072), vm.Vector3(1, 1.1, 1)),
        UnlitMaterial()..baseColorFactor = linearColor(_core),
      ),
    ]);
    final halo = Mesh(_softDisc(0.32), _glow(const Color(0xFFFFB050), 0.6));
    final pool = Mesh(_softDisc(0.9), _glow(const Color(0xFFFF9A3C), 0.6));

    root.add(_moonPath);
    for (var i = 0; i < torches; i++) {
      final torch = _Torch(
        flame: Node(name: 'flame', mesh: flame.clone())
          ..position = vm.Vector3(0, _flameHeight, 0)
          ..shadowCastingMode = ShadowCastingMode.off,
        halo: Node(name: 'halo', mesh: halo.clone())
          ..position = vm.Vector3(0, _flameHeight + 0.04, 0)
          ..shadowCastingMode = ShadowCastingMode.off,
        // Just above the ground so the warm pool doesn't z-fight with it.
        pool: Node(name: 'pool', mesh: pool.clone())
          ..position = vm.Vector3(0, 0.012, 0)
          ..shadowCastingMode = ShadowCastingMode.off,
        phase: i * 1.7,
      );
      _torches.add(torch);
      root.add(
        torch.node
          ..scale = vm.Vector3.all(_torchScale)
          ..add(Node(name: 'pole', mesh: pole.clone()))
          ..add(torch.flame)
          ..add(torch.halo)
          ..add(torch.pool),
      );
    }
  }

  final Node root = Node(name: 'night');
  final List<_Torch> _torches = [];
  double _time = 0;

  /// A pale streak on the sea, stretched towards the camera like moonlight
  /// on water. The moon itself is out of sight above the camera.
  final Node _moonPath = Node(
    name: 'moon path',
    mesh: Mesh(_softDisc(1), _glow(const Color(0xFFDCE8FF), 0.45)),
  )..shadowCastingMode = ShadowCastingMode.off;

  /// Stands torch [index] at [position] on the ground, or hides it.
  void place(int index, vm.Vector3 position, {bool visible = true}) {
    _torches[index].node
      ..position = position
      ..visible = visible;
  }

  /// Flickers the flames: two quick waves per torch, out of step with the
  /// others, stretch each flame and pulse its glow. The halos turn to face
  /// the [eye] (the camera), so they always look round, and the moon's path
  /// lies on the far side of an island reaching [reach] from its centre.
  void update(
    double deltaSeconds, {
    required double reach,
    vm.Vector3? eye,
  }) {
    _time += deltaSeconds;
    if (eye != null) _placeMoonPath(eye, reach);
    for (final torch in _torches) {
      if (!torch.node.visible) continue;
      final t = _time + torch.phase;
      final flicker = math.sin(t * 9.1) * 0.6 + math.sin(t * 23.7) * 0.4;
      final width = 1 + 0.06 * math.sin(t * 13.3);
      torch.flame.scale = vm.Vector3(width, 1 + 0.16 * flicker, width);
      torch.halo.scale = vm.Vector3.all(1 + 0.08 * flicker);
      torch.pool.scale = vm.Vector3.all(1 + 0.05 * math.sin(t * 7.3));
      if (eye != null) {
        final halo = torch.node.position + torch.halo.position * _torchScale;
        torch.halo.rotation = alongY(eye - halo);
      }
    }
  }

  void _placeMoonPath(vm.Vector3 eye, double reach) {
    final away = vm.Vector3(-eye.x, 0, -eye.z);
    if (away.length2 < 1e-6) return;
    away.normalize();
    // Just above the shallows ring, and shimmering a little.
    final shimmer = 1 + 0.04 * math.sin(_time * 1.7);
    _moonPath
      ..position = away * (reach + _moonPathDistance) + vm.Vector3(0, 0.08, 0)
      ..rotation = vm.Quaternion.fromTwoVectors(vm.Vector3(0, 0, 1), away)
      ..scale = vm.Vector3(1.7 * shimmer, 1, 9);
  }

  /// One mesh out of [parts], which all share its kind of material.
  static Mesh _merged(List<Node> parts) {
    final template = Node()..addAll(parts);
    bakeStatic(template);

    return template.children.singleWhere((n) => n.name == 'baked').mesh!;
  }

  /// A soft see-through glow that ignores the moonlight.
  static UnlitMaterial _glow(Color color, double alpha) => UnlitMaterial()
    ..baseColorFactor = (linearColor(color)..a = alpha)
    ..alphaMode = AlphaMode.blend
    ..doubleSided = true;

  /// A flat disc facing +Y that fades from opaque in the middle to clear at
  /// its [radius], through its vertex colours' alpha.
  static MeshGeometry _softDisc(double radius) {
    const segments = 24;
    const rings = 4;
    final positions = <double>[0, 0, 0];
    final colors = <double>[1, 1, 1, 1];
    for (var ring = 1; ring <= rings; ring++) {
      final t = ring / rings;
      final alpha = math.pow(1 - t, 2).toDouble();
      for (var i = 0; i < segments; i++) {
        final a = i / segments * math.pi * 2;
        positions
            .addAll([math.cos(a) * radius * t, 0, math.sin(a) * radius * t]);
        colors.addAll([1, 1, 1, alpha]);
      }
    }
    final indices = <int>[
      for (var i = 0; i < segments; i++) ...[0, 1 + (i + 1) % segments, 1 + i],
    ];
    for (var ring = 1; ring < rings; ring++) {
      final inner = 1 + (ring - 1) * segments;
      final outer = inner + segments;
      for (var i = 0; i < segments; i++) {
        final next = (i + 1) % segments;
        indices.addAll([
          inner + i,
          inner + next,
          outer + i,
          inner + next,
          outer + next,
          outer + i,
        ]);
      }
    }

    return MeshGeometry.fromArrays(
      positions: Float32List.fromList(positions),
      normals: Float32List.fromList([
        for (var i = 0; i < positions.length ~/ 3; i++) ...[0, 1, 0],
      ]),
      colors: Float32List.fromList(colors),
      indices: indices,
    );
  }
}

class _Torch {
  _Torch({
    required this.flame,
    required this.halo,
    required this.pool,
    required this.phase,
  });

  final Node node = Node(name: 'torch');
  final Node flame;
  final Node halo;
  final Node pool;
  final double phase;
}
