import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Merges the meshes under [root] that never move into a few big meshes,
/// one per kind of material, so the scene draws in a handful of calls
/// instead of hundreds. Each mesh's colour is baked into vertex colours, so
/// the result looks exactly as before.
///
/// Subtrees in [keep] are left untouched (characters, anything whose
/// materials change). Nodes in [moving], and hidden nodes (they may be
/// shown later), keep their own transform: their contents are merged in
/// their own space instead, so they can still move or toggle. Use
/// [findMoving] to collect the nodes an animation moves.
///
/// With [shadowStatic] the merged meshes are cached in the shadow map too;
/// pass it only when [root] itself never moves.
///
/// With [keepMaterials] meshes are only merged with others sharing their
/// very material, which they keep, so a material changed later (a fur
/// colour) still shows.
void bakeStatic(
  Node root, {
  Set<Node> keep = const {},
  Set<Node> moving = const {},
  bool shadowStatic = false,
  bool keepMaterials = false,
}) {
  final batches = <Object, _Batch>{};

  void visit(Node node, vm.Matrix4 toRoot) {
    for (final child in [...node.children]) {
      if (keep.contains(child)) continue;
      if (moving.contains(child) || !child.visible) {
        bakeStatic(
          child,
          keep: keep,
          moving: moving,
          keepMaterials: keepMaterials,
        );
        continue;
      }
      final transform = toRoot * child.localTransform as vm.Matrix4;
      final mesh = child.mesh;
      if (mesh != null && _canMerge(child, mesh)) {
        for (final primitive in mesh.primitives) {
          final key = keepMaterials
              ? (primitive.material, child.shadowCastingMode)
              : _Key.of(primitive.material, child.shadowCastingMode);
          (batches[key] ??= _Batch(bakeColor: !keepMaterials))
              .add(primitive, transform);
        }
        child.mesh = null;
      }
      visit(child, transform);
    }
  }

  visit(root, vm.Matrix4.identity());
  for (final MapEntry(:key, value: batch) in batches.entries) {
    if (batch.vertexCount == 0) continue;
    final (material, shadows) = switch (key) {
      final _Key k => (k.material(), k.shadows),
      (final Material m, final ShadowCastingMode s) => (m, s),
      _ => throw StateError('Unknown batch key $key'),
    };
    root.add(
      Node(name: 'baked', mesh: Mesh(batch.build(), material))
        ..shadowCastingMode = shadows
        ..shadowStatic = shadowStatic,
    );
  }
}

/// The nodes under [root] whose transform, visibility, mesh or material
/// colour changes while [animate] is called with the steps 1 to [steps]:
/// the ones [bakeStatic] must not merge into their parents.
Set<Node> findMoving(
  Node root,
  void Function(int step) animate, {
  int steps = 8,
}) {
  final before = <Node, _Snapshot>{};
  void record(Node node) {
    before[node] = _Snapshot(node);
    node.children.forEach(record);
  }

  record(root);
  final moving = <Node>{};
  for (var step = 1; step <= steps; step++) {
    animate(step);
    for (final MapEntry(key: node, value: snapshot) in before.entries) {
      if (!snapshot.matches(node)) moving.add(node);
    }
  }

  return moving;
}

class _Snapshot {
  _Snapshot(Node node)
      : transform = node.localTransform.clone(),
        visible = node.visible,
        mesh = node.mesh,
        colors = _colors(node);

  final vm.Matrix4 transform;
  final bool visible;
  final Mesh? mesh;
  final List<vm.Vector4> colors;

  static List<vm.Vector4> _colors(Node node) => [
        for (final primitive in node.mesh?.primitives ?? <MeshPrimitive>[])
          switch (primitive.material) {
            final PhysicallyBasedMaterial m => m.baseColorFactor.clone(),
            final UnlitMaterial m => m.baseColorFactor.clone(),
            _ => vm.Vector4.zero(),
          },
      ];

  bool matches(Node node) {
    if (node.visible != visible || !identical(node.mesh, mesh)) return false;
    final now = node.localTransform.storage;
    for (var i = 0; i < 16; i++) {
      if ((now[i] - transform.storage[i]).abs() > 1e-6) return false;
    }
    final current = _colors(node);
    for (var i = 0; i < colors.length; i++) {
      if ((current[i] - colors[i]).length2 > 1e-9) return false;
    }

    return true;
  }
}

/// Whether every primitive of [mesh] is a plain, untextured, opaque
/// material on readable triangle geometry.
bool _canMerge(Node node, Mesh mesh) {
  for (final primitive in mesh.primitives) {
    if (!primitive.visible || !primitive.castsShadow) return false;
    if (primitive.drawSelector != null) return false;
    if (!primitive.geometry.isReadable) return false;
    switch (primitive.material) {
      case final PhysicallyBasedMaterial m:
        if (m.baseColorTexture != null ||
            m.metallicRoughnessTexture != null ||
            m.normalTexture != null ||
            m.emissiveTexture != null ||
            m.occlusionTexture != null ||
            m.alphaMode != AlphaMode.opaque) {
          return false;
        }
      case final UnlitMaterial m:
        if (m.baseColorTexture != null || m.alphaMode != AlphaMode.opaque) {
          return false;
        }
      default:
        return false;
    }
  }

  return true;
}

/// What makes materials interchangeable once their colours are baked.
@immutable
class _Key {
  const _Key({
    required this.unlit,
    required this.metallic,
    required this.roughness,
    required this.doubleSided,
    required this.shadows,
  });

  factory _Key.of(Material material, ShadowCastingMode shadows) =>
      switch (material) {
        final PhysicallyBasedMaterial m => _Key(
            unlit: false,
            metallic: m.metallicFactor,
            roughness: m.roughnessFactor,
            doubleSided: m.doubleSided,
            shadows: shadows,
          ),
        _ => _Key(
            unlit: true,
            metallic: 0,
            roughness: 0,
            doubleSided: material.doubleSided,
            shadows: shadows,
          ),
      };

  final bool unlit;
  final double metallic;
  final double roughness;
  final bool doubleSided;
  final ShadowCastingMode shadows;

  Material material() => unlit
      ? (UnlitMaterial()..doubleSided = doubleSided)
      : (PhysicallyBasedMaterial()
        ..metallicFactor = metallic
        ..roughnessFactor = roughness
        ..doubleSided = doubleSided);

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.unlit == unlit &&
      other.metallic == metallic &&
      other.roughness == roughness &&
      other.doubleSided == doubleSided &&
      other.shadows == shadows;

  @override
  int get hashCode =>
      Object.hash(unlit, metallic, roughness, doubleSided, shadows);
}

/// Vertices gathered for one merged mesh.
class _Batch {
  _Batch({required this.bakeColor});

  /// Whether the source materials' colours go into the vertex colours (for
  /// a fresh white material) or the vertex colours stay as they were.
  final bool bakeColor;

  final _positions = <double>[];
  final _normals = <double>[];
  final _colors = <double>[];
  final _indices = <int>[];

  int get vertexCount => _positions.length ~/ 3;

  void add(MeshPrimitive primitive, vm.Matrix4 transform) {
    final data = primitive.geometry.extractMeshData();
    final positions = data.positions;
    final normals = data.normals;
    final colors = data.colors;
    final count = positions.length ~/ 3;
    final tint = !bakeColor
        ? (vm.Vector4.all(1), 1.0)
        : switch (primitive.material) {
            final PhysicallyBasedMaterial m => (
                m.baseColorFactor,
                m.vertexColorWeight
              ),
            final UnlitMaterial m => (m.baseColorFactor, m.vertexColorWeight),
            _ => (vm.Vector4.all(1), 1.0),
          };
    final normalMatrix = transform.getNormalMatrix();
    final base = vertexCount;
    final p = vm.Vector3.zero();
    final n = vm.Vector3.zero();
    for (var i = 0; i < count; i++) {
      p.setValues(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2]);
      transform.transform3(p);
      _positions.addAll([p.x, p.y, p.z]);
      if (normals != null) {
        n.setValues(normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]);
        normalMatrix.transform(n);
        n.normalize();
      } else {
        n.setValues(0, 1, 0);
      }
      _normals.addAll([n.x, n.y, n.z]);
      // The shader multiplies the vertex colour (blended in by the
      // material's weight) by the base colour; bake both together.
      final (factor, weight) = tint;
      for (var c = 0; c < 4; c++) {
        final vertex = colors == null ? 1.0 : colors[i * 4 + c];
        _colors.add(factor[c] * (1 + (vertex - 1) * weight));
      }
    }
    final indices = data.indices ?? [for (var i = 0; i < count; i++) i];
    // A mirroring transform turns the triangles inside out; flip them back.
    final flip = transform.determinant() < 0;
    for (var t = 0; t + 2 < indices.length; t += 3) {
      final a = base + indices[t];
      final b = base + indices[t + 1];
      final c = base + indices[t + 2];
      _indices.addAll(flip ? [a, c, b] : [a, b, c]);
    }
  }

  MeshGeometry build() => MeshGeometry.fromArrays(
        positions: Float32List.fromList(_positions),
        normals: Float32List.fromList(_normals),
        colors: Float32List.fromList(_colors),
        indices: _indices,
      );
}
