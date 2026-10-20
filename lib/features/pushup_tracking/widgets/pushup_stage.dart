import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:vector_math/vector_math.dart' as vm;

const _matColor = Color(0xFF5E9EFF);

/// The 3D gorilla on its workout mat.
///
/// It idles until [tracking] turns on, then holds a plank and dips in step
/// with every pushup [PushupCubit] counts.
class PushupStage extends StatefulWidget {
  const PushupStage({
    required this.tracking,
    required this.partyHat,
    super.key,
  });

  final bool tracking;
  final bool partyHat;

  @override
  State<PushupStage> createState() => _PushupStageState();
}

class _PushupStageState extends State<PushupStage> {
  /// Built in [_populate]: geometry needs the engine's static resources.
  GorillaRig? _rig;

  @override
  void didUpdateWidget(covariant PushupStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRig();
  }

  void _syncRig() {
    _rig
      ?..activity =
          widget.tracking ? GorillaActivity.pushups : GorillaActivity.idle
      ..partyHat = widget.partyHat
      ..inPushup = context.read<PushupCubit>().state.inPushup;
  }

  void _populate(Scene scene) {
    final rig = _rig = GorillaRig();
    _syncRig();
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.45, -1, -0.35),
        intensity: 3.2,
        castsShadow: true,
        shadowSoftness: 0.25,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
      )
      ..add(
        // Catches the gorilla's shadow on the otherwise invisible floor.
        meshNode(
          DiscGeometry(radius: 4, segments: 48),
          ShadowCatcherMaterial(shadowIntensity: 0.35, softness: 0.6),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            CylinderGeometry(radialSegments: 48),
            vm.Vector3(1.2, 0.02, 2.5),
          ),
          matte(_matColor, roughness: 0.7),
          position: vm.Vector3(0, 0.012, -0.3),
        ),
      )
      ..add(rig.root);
  }

  Camera _camera(Duration elapsed) {
    // A three-quarter view that drifts slowly so the scene never feels static.
    final t = elapsed.inMicroseconds / 1e6;
    final angle = 1.05 + math.sin(t * 0.18) * 0.1;
    // Far back with a narrow lens: a portrait phone sees little horizontally.
    const distance = 9.2;

    return PerspectiveCamera(
      fovRadiansY: 30 * vm.degrees2Radians,
      position: vm.Vector3(
        math.sin(angle) * distance,
        3.4,
        math.cos(angle) * distance - 0.3,
      ),
      target: vm.Vector3(0, 0.35, -0.3),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<PushupCubit, PushupState>(
        listenWhen: (previous, current) =>
            previous.inPushup != current.inPushup,
        listener: (context, state) => _rig?.inPushup = state.inPushup,
        child: SceneStage(
          populate: _populate,
          cameraBuilder: _camera,
          onTick: (deltaSeconds) => _rig?.update(deltaSeconds),
        ),
      );
}
