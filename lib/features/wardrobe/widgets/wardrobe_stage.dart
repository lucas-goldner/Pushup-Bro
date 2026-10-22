import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/costumes.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Carlos on his mat on a slowly turning stand; drag to spin him. He waves
/// whenever his [look] changes.
class WardrobeStage extends StatefulWidget {
  const WardrobeStage({required this.look, super.key});

  final MonkeyLook look;

  @override
  State<WardrobeStage> createState() => _WardrobeStageState();
}

class _WardrobeStageState extends State<WardrobeStage> {
  final GorillaRig _carlos = GorillaRig();
  Node? _mat;
  double _turn = 0.5;
  double _spin = 0;
  double _waving = 0;

  @override
  void didUpdateWidget(covariant WardrobeStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.look != widget.look) _dress();
  }

  void _dress() {
    final changedMat = widget.look.matColor != _carlos.look.matColor ||
        widget.look.matPattern != _carlos.look.matPattern;
    _carlos.look = widget.look;
    if (changedMat) _mat?.mesh = buildMat(widget.look).mesh;
    // A happy wave for every new thing, except mats he's sitting on.
    if (!changedMat) _waving = 1.6;
  }

  void _populate(Scene scene) {
    _carlos
      ..look = widget.look
      ..settle();
    final mat = _mat = buildMat(widget.look)..position = vm.Vector3(0, 0, -0.1);
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.4, -1, -0.6),
        intensity: 3.2,
        castsShadow: true,
        shadowSoftness: 0.3,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.7,
      )
      ..add(
        Node(name: 'stand')
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: 1.25,
                topRadius: 1.2,
                height: 0.08,
                radialSegments: 64,
              ),
              matte(const Color(0xFFFFFFFF), roughness: 0.5),
              position: vm.Vector3(0, -0.04, 0),
            ),
          ),
      )
      ..add(mat)
      ..add(_carlos.root);
  }

  void _tick(double deltaSeconds) {
    _turn += (0.25 + _spin) * deltaSeconds;
    _spin = springTo(_spin, 0, deltaSeconds, 2.5);
    _waving = math.max(0, _waving - deltaSeconds);
    _carlos.activity =
        _waving > 0 ? GorillaActivity.wave : GorillaActivity.idle;
    final turn = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), _turn);
    _carlos.root.rotation = turn;
    _mat?.rotation = turn;
    _carlos.update(deltaSeconds);
  }

  Camera _camera(Duration elapsed) {
    // Aimed a little above him, so he sits in the open space under the
    // top bar.
    final target = vm.Vector3(0, 0.62, 0);

    return PerspectiveCamera(
      fovRadiansY: 30 * vm.degrees2Radians,
      position: target + vm.Vector3(0, 0.75, 4.1),
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
