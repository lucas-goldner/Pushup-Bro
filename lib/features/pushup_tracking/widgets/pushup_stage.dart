import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/features/pushup_tracking/scene/gym_world.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The 3D gym: Carlos on his mat in front of a class of gym buddies.
///
/// Everyone idles until [tracking] turns on, then the whole class holds a
/// plank and dips in step with every pushup [PushupCubit] counts.
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
  GymWorld? _gym;

  @override
  void didUpdateWidget(covariant PushupStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGym();
  }

  void _syncGym() {
    _gym
      ?..tracking = widget.tracking
      ..inPushup = context.read<PushupCubit>().state.inPushup
      ..carlos.partyHat = widget.partyHat;
  }

  void _populate(Scene scene) {
    final gym = _gym = GymWorld();
    _syncGym();
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.35, -1, -0.5),
        castsShadow: true,
        shadowSoftness: 0.25,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
      )
      ..add(gym.root);
  }

  Camera _camera(Duration elapsed) {
    // Looks past Carlos at the class behind him, drifting slowly so the
    // scene never feels static. Far back with a narrow lens: a portrait
    // phone sees little horizontally.
    final t = elapsed.inMicroseconds / 1e6;
    final angle = gymViewAngle + math.sin(t * 0.18) * 0.06;
    final target = gymToWorld(vm.Vector3(0, 0.55, -1.7));
    const distance = 8.6;

    return PerspectiveCamera(
      fovRadiansY: 32 * vm.degrees2Radians,
      position: target +
          vm.Vector3(
            math.sin(angle) * distance,
            2.4,
            math.cos(angle) * distance,
          ),
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<PushupCubit, PushupState>(
        listenWhen: (previous, current) =>
            previous.inPushup != current.inPushup,
        listener: (context, state) => _gym?.inPushup = state.inPushup,
        child: SceneStage(
          populate: _populate,
          cameraBuilder: _camera,
          onTick: (deltaSeconds) => _gym?.update(deltaSeconds),
        ),
      );
}
