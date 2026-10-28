import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Floats per vertex in the skinned layout: position 3, normal 3, two tex
/// coords 2 each, colour 4, tangent 4, joints 4, weights 4.
const _floatsPerVertex = 26;

/// Draws the meshes under [group] as one skinned mesh per material, each
/// mesh-bearing node becoming a bone that carries its own vertices.
///
/// The nodes keep moving as before (a rig poses its limbs node by node),
/// but the GPU places their vertices, so a figure of dozens of parts draws
/// in a handful of calls. Hide a part by scaling its node to (almost)
/// nothing rather than with `visible`; hiding [group] hides all of it.
/// Subtrees in [skip] are left as they are (costume slots, parts toggled
/// on their own).
void skinMeshes(Node group, {Set<Node> skip = const {}}) {
  final parts = <Material, List<(MeshPrimitive, Node)>>{};

  void visit(Node node) {
    if (skip.contains(node)) return;
    final mesh = node.mesh;
    if (mesh != null && mesh.primitives.every(_canSkin)) {
      for (final primitive in mesh.primitives) {
        (parts[primitive.material] ??= []).add((primitive, node));
      }
      node.mesh = null;
    }
    node.children.forEach(visit);
  }

  visit(group);
  for (final MapEntry(key: material, value: list) in parts.entries) {
    // Each mesh gets a skin of just the bones it uses, since the engine
    // works out every bone of a skin once per mesh per frame.
    final bones = <Node>[];
    final indexed = [
      for (final (primitive, node) in list)
        (
          primitive,
          bones.contains(node)
              ? bones.indexOf(node)
              : (bones..add(node)).length - 1,
        ),
    ];
    // Each vertex is stored in its bone's own space, so the bind pose is
    // the identity for every bone.
    final skin = Skin()
      ..joints.addAll(bones)
      ..inverseBindMatrices
          .addAll([for (final _ in bones) vm.Matrix4.identity()]);
    group.add(
      Node(name: 'skinned', mesh: Mesh(_build(indexed), material))
        ..skin = skin
        // Its vertices sit wherever the bones are, not around this node.
        ..frustumCulled = false,
    );
  }
}

bool _canSkin(MeshPrimitive primitive) =>
    primitive.visible &&
    primitive.geometry is! SkinnedGeometry &&
    primitive.geometry.isReadable;

SkinnedGeometry _build(List<(MeshPrimitive, int)> parts) {
  final vertices = <double>[];
  final indices = <int>[];
  for (final (primitive, bone) in parts) {
    final data = primitive.geometry.extractMeshData();
    final positions = data.positions;
    final normals = data.normals;
    final colors = data.colors;
    final count = positions.length ~/ 3;
    final base = vertices.length ~/ _floatsPerVertex;
    for (var i = 0; i < count; i++) {
      vertices
        ..addAll([positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2]])
        ..addAll(
          normals == null
              ? const [0.0, 1.0, 0.0]
              : [normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]],
        )
        ..addAll(const [0.0, 0.0, 0.0, 0.0])
        ..addAll(
          colors == null
              ? const [1.0, 1.0, 1.0, 1.0]
              : [
                  colors[i * 4],
                  colors[i * 4 + 1],
                  colors[i * 4 + 2],
                  colors[i * 4 + 3],
                ],
        )
        ..addAll(const [0.0, 0.0, 0.0, 0.0])
        // One bone per vertex, fully weighted.
        ..addAll([bone.toDouble(), 0.0, 0.0, 0.0])
        ..addAll(const [1.0, 0.0, 0.0, 0.0]);
    }
    final source = data.indices ?? [for (var i = 0; i < count; i++) i];
    indices.addAll([for (final index in source) base + index]);
  }

  final vertexCount = vertices.length ~/ _floatsPerVertex;
  // 16-bit indices; a figure's parts stay well under that.
  if (vertexCount > 0xFFFF) {
    throw StateError('Too many vertices to skin in one mesh: $vertexCount');
  }

  return SkinnedGeometry()
    ..uploadVertexData(
      Float32List.fromList(vertices),
      vertexCount,
      Uint16List.fromList(indices),
    );
}
