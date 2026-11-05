// Build switches are read from the environment on purpose.
// ignore_for_file: do_not_use_environment
import 'dart:convert';

import 'package:flutter_scene/scene.dart';

/// Build with `--dart-define=SCENE_STATS=true` to have every [Scene] shown
/// by `SceneStage` print what it holds and what a frame costs, once it has
/// settled: nodes, mesh nodes, triangles, distinct geometries and materials,
/// and the engine's counters for the last frame (draw calls per pass).
const bool kSceneStats = bool.fromEnvironment('SCENE_STATS');

/// How many triangles each skinned geometry holds (one can't be read back),
/// filled in by `skinMeshes` while [kSceneStats] is on.
final Expando<int> skinnedTriangles = Expando('triangles');

/// Prints [scene]'s statistics under [label] (see [kSceneStats]).
void printSceneStats(String label, Scene scene) {
  var nodes = 0;
  var visibleMeshNodes = 0;
  var primitives = 0;
  var triangles = 0;
  var unreadable = 0;
  var gorillas = 0;
  final geometries = <Object>{};
  final materials = <Object>{};

  void visit(Node node, {required bool shown}) {
    nodes++;
    if (node.name == 'gorilla' && shown && node.visible) gorillas++;
    final visible = shown && node.visible;
    final mesh = node.mesh;
    if (mesh != null && visible) {
      visibleMeshNodes++;
      for (final primitive in mesh.primitives) {
        if (!primitive.visible) continue;
        primitives++;
        geometries.add(primitive.geometry);
        materials.add(primitive.material);
        final geometry = primitive.geometry;
        final skinned = skinnedTriangles[geometry];
        if (skinned != null) {
          triangles += skinned;
        } else if (geometry.isReadable) {
          triangles += geometry.extractMeshData().triangleCount;
        } else {
          unreadable++;
        }
      }
    }
    for (final child in node.children) {
      visit(child, shown: visible);
    }
  }

  visit(scene.root, shown: true);
  final frame = scene.renderStats.latest;
  final passes = <String, Object>{
    for (final view in frame?.views ?? <RenderViewStats>[])
      for (final pass in view.passes)
        '${view.viewIndex}:${pass.name}':
            '${pass.counters.draws}d ${pass.counters.vertices}v',
  };
  // A plain print, so it shows in a release build's console too.
  // ignore: avoid_print
  print(
    'SCENE_STATS $label ${jsonEncode({
          'gorillas': gorillas,
          'nodes': nodes,
          'meshNodes': visibleMeshNodes,
          'primitives': primitives,
          'triangles': triangles,
          'unreadable': unreadable,
          'geometries': geometries.length,
          'materials': materials.length,
          'draws': frame?.counters.draws,
          'vertices': frame?.counters.vertices,
          'cpuMicros': frame?.cpuMicros,
          'passes': passes,
        })}',
  );
}
