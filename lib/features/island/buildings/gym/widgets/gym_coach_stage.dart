import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart' show yaw;
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_window.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/features/pushup_tracking/scene/gym_world.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Where Grandpa Gus stands, in the gym's camera-aligned frame: in front
/// Carlos's mat and to his left on screen, so neither hides the other.
final _coachSpot = vm.Vector3(1, 0, -0.35);

/// What the coach is up to.
enum CoachMood { watching, resting, cheering }

/// The home gym (see [GymWorld]) with Grandpa Gus standing by Carlos's mat
/// as coach: watching while Carlos works, waving through rests and
/// dancing when a workout is won.
class GymCoachStage extends StatefulWidget {
  const GymCoachStage({
    required this.tracking,
    required this.look,
    this.mood = CoachMood.watching,
    this.buddies,
    super.key,
  });

  final bool tracking;
  final MonkeyLook look;
  final CoachMood mood;

  /// How many gym buddies train behind Carlos (the app's own draw if null).
  final int? buddies;

  @override
  State<GymCoachStage> createState() => _GymCoachStageState();
}

class _GymCoachStageState extends State<GymCoachStage> {
  GymWorld? _gym;
  final GorillaRig _gus = GorillaRig(timeOffset: 0.9);
  Camera? _lastCamera;
  Size _viewSize = Size.zero;

  @override
  void didUpdateWidget(covariant GymCoachStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    _gym
      ?..tracking = widget.tracking
      ..inPushup = context.read<PushupCubit>().state.inPushup
      ..carlosLook = widget.look;
    _gus.activity = switch (widget.mood) {
      CoachMood.watching => GorillaActivity.idle,
      CoachMood.resting => GorillaActivity.wave,
      CoachMood.cheering => GorillaActivity.dance,
    };
  }

  void _populate(Scene scene) {
    final gym = _gym = GymWorld(buddies: widget.buddies);
    _gus.look = kGusLook;
    _gus.root
      ..position = gymToWorld(_coachSpot)
      // Turned half towards the camera, half towards Carlos.
      ..rotation = yaw(gymViewAngle - 0.5)
      ..scale = vm.Vector3.all(1.1);
    gym.root.add(_gus.root);
    _sync();
    scene
      ..directionalLight = fitShadowCascades(
        DirectionalLight(
          direction: vm.Vector3(-0.35, -1, -0.5),
          castsShadow: true,
          shadowSoftness: 0.25,
        ),
        visibleDepth: 20,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
      )
      ..add(gym.root);
  }

  Camera _camera(Duration elapsed) {
    // The home gym's floating phone camera (see PushupStage), aimed a
    // little to the side so Gus and Carlos share the frame.
    final t = elapsed.inMicroseconds / 1e6;
    final angle = gymViewAngle + math.sin(t * 0.18) * 0.06;
    final right = vm.Vector3(math.cos(angle), 0, -math.sin(angle));
    final sway = math.sin(t * 0.9) * 0.14 + math.sin(t * 2.3 + 1) * 0.05;
    final bob = math.sin(t * 1.7 + 0.5) * 0.04 + math.sin(t * 3.1) * 0.02;
    final target = gymToWorld(vm.Vector3(0.35, 0.55, -1.7));
    const distance = 8.6;

    return _lastCamera = PerspectiveCamera(
      fovRadiansY: 32 * vm.degrees2Radians,
      position: target +
          right * sway +
          vm.Vector3(
            math.sin(angle) * distance,
            2.3 + bob,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            _viewSize = constraints.biggest;

            return SceneStage(
              populate: _populate,
              cameraBuilder: _camera,
              onTick: (deltaSeconds) {
                aimGorillasAtCameraWindow(_lastCamera, _viewSize);
                _gym?.update(deltaSeconds);
                _gus.update(deltaSeconds);
              },
            );
          },
        ),
      );
}
