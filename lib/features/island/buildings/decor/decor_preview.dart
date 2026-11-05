import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_layer.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// [item] on a little patch of island, slowly turning; drag to spin it.
/// The camera backs off for the big ones.
class DecorPreview extends StatefulWidget {
  const DecorPreview({required this.item, super.key});

  final DecorItem item;

  @override
  State<DecorPreview> createState() => _DecorPreviewState();
}

class _DecorPreviewState extends State<DecorPreview> {
  /// Built in [_populate]: geometry needs the engine's static resources.
  DecorLayer? _layer;
  double _turn = 0.6;
  double _spin = 0;

  /// The little patch of island it stands on, sized to it.
  final Node _patch = Node(name: 'patch');

  /// How far back the camera stands and how high it looks, easing towards
  /// the item's size.
  double _distance = 0;
  double _lookAt = 0;

  @override
  void didUpdateWidget(covariant DecorPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) _show();
  }

  void _show() => _layer?.show([DecorPiece(item: widget.item, placed: true)]);

  /// How far the item reaches out from its centre, and how tall it is.
  (double, double) _size() {
    final bounds = DecorLayer.model(widget.item).combinedLocalBounds;
    if (bounds == null) return (widget.item.radius, 0.6);
    final reach = [
      bounds.min.x.abs(),
      bounds.max.x.abs(),
      bounds.min.z.abs(),
      bounds.max.z.abs(),
    ].reduce(math.max);

    return (reach, bounds.max.y);
  }

  void _populate(Scene scene) {
    final layer = _layer = DecorLayer(ground: 0.08);
    _show();
    _patch
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 1.12,
            topRadius: 1.08,
            height: 0.12,
            radialSegments: 48,
          ),
          matte(const Color(0xFFF1DAA9), roughness: 0.95),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: 0.92,
            topRadius: 0.9,
            height: 0.04,
            radialSegments: 48,
          ),
          matte(const Color(0xFF8CCB6E), roughness: 0.9),
          position: vm.Vector3(0, 0.06, 0),
        ),
      );
    scene
      ..directionalLight = fitShadowCascades(
        DirectionalLight(
          direction: vm.Vector3(-0.4, -1, -0.6),
          intensity: 3.2,
          castsShadow: true,
          shadowSoftness: 0.3,
        ),
        visibleDepth: 12,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.7,
      )
      ..add(layer.root..add(_patch));
  }

  void _tick(double deltaSeconds) {
    _turn += (0.3 + _spin) * deltaSeconds;
    _spin = springTo(_spin, 0, deltaSeconds, 2.5);
    _layer
      ?..root.rotation = yaw(_turn)
      ..update(deltaSeconds);
  }

  Camera _camera(Duration elapsed) {
    final (reach, height) = _size();
    final patch = reach + 0.3;
    _patch.scale = vm.Vector3(patch, 1, patch);
    // Far enough back for the patch and the item's height to fit.
    final fit = math.max(patch * 1.1, height * 0.95) /
        math.tan(15 * vm.degrees2Radians);
    final lookAt = height * 0.45;
    _distance = _distance == 0 ? fit : _distance + (fit - _distance) * 0.12;
    _lookAt = _lookAt == 0 ? lookAt : _lookAt + (lookAt - _lookAt) * 0.12;
    final target = vm.Vector3(0, _lookAt, 0);

    return PerspectiveCamera(
      fovRadiansY: 30 * vm.degrees2Radians,
      position: target + vm.Vector3(0, _distance * 0.42, _distance),
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onHorizontalDragUpdate: (details) {
          _turn += details.delta.dx * 0.012;
          _spin = 0;
        },
        onHorizontalDragEnd: (details) =>
            _spin = (details.primaryVelocity ?? 0) * 0.004,
        child: SceneStage(
          populate: _populate,
          cameraBuilder: _camera,
          onTick: _tick,
        ),
      );
}
