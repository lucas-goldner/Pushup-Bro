import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_window.dart';
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
    required this.look,
    super.key,
  });

  final bool tracking;
  final MonkeyLook look;

  @override
  State<PushupStage> createState() => _PushupStageState();
}

class _PushupStageState extends State<PushupStage> {
  /// Built in [_populate]: geometry needs the engine's static resources.
  GymWorld? _gym;
  Camera? _lastCamera;
  Size _viewSize = Size.zero;

  @override
  void didUpdateWidget(covariant PushupStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGym();
  }

  void _syncGym() {
    _gym
      ?..tracking = widget.tracking
      ..inPushup = context.read<PushupCubit>().state.inPushup
      ..carlosLook = widget.look;
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
    // Looks past Carlos at the gym behind him, far back with a narrow lens:
    // a portrait phone sees little horizontally. It floats like a phone held
    // up to film him: a slow drift, a side-to-side sway, a little bob and
    // roll, all from a few out-of-step sines so it never visibly repeats.
    final t = elapsed.inMicroseconds / 1e6;
    final angle = gymViewAngle + math.sin(t * 0.18) * 0.06;
    final right = vm.Vector3(math.cos(angle), 0, -math.sin(angle));
    final sway = math.sin(t * 0.9) * 0.18 + math.sin(t * 2.3 + 1) * 0.06;
    final bob = math.sin(t * 1.7 + 0.5) * 0.05 + math.sin(t * 3.1) * 0.02;
    final roll = math.sin(t * 1.1 + 2) * 0.025 + math.sin(t * 2.7) * 0.008;
    final target = gymToWorld(vm.Vector3(0, 0.55, -1.7)) +
        right * (math.sin(t * 1.3 + 2) * 0.05) +
        vm.Vector3(0, math.sin(t * 1.9 + 1) * 0.03, 0);
    const distance = 8.6;

    return _lastCamera = PerspectiveCamera(
      fovRadiansY: 32 * vm.degrees2Radians,
      position: target +
          right * sway +
          vm.Vector3(
            math.sin(angle) * distance,
            2.4 + bob,
            math.cos(angle) * distance,
          ),
      target: target,
      up: vm.Vector3(0, 1, 0) + right * roll,
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<PushupCubit, PushupState>(
        listenWhen: (previous, current) =>
            previous.inPushup != current.inPushup,
        listener: (context, state) => _gym?.inPushup = state.inPushup,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _viewSize = constraints.biggest;

            return SceneStage(
              populate: _populate,
              cameraBuilder: _camera,
              onTick: (deltaSeconds) {
                aimGorillasAtCameraWindow(_lastCamera, _viewSize);
                _gym?.update(deltaSeconds);
              },
            );
          },
        ),
      );
}
