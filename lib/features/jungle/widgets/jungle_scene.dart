import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/island/scene/jungle_patch.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Matches the bottom of the jungle screen's gradient, so the fog melts
/// into the backdrop: a pale, misty leaf green.
Color jungleMistOf(BuildContext context) =>
    Color.lerp(context.gameColors.leaf, context.gameColors.onGame, 0.635)!;

/// A clearing deep in the jungle. Carlos wanders in through the gate and
/// sits down in the middle while parrots circle overhead.
class JungleScene extends StatefulWidget {
  const JungleScene({this.onReady, super.key});

  /// Called once the whole clearing is drawn.
  final VoidCallback? onReady;

  @override
  State<JungleScene> createState() => _JungleSceneState();
}

class _JungleSceneState extends State<JungleScene> {
  /// Built in [_populate]: geometry needs the engine's static resources.
  JunglePatch? _jungle;
  final GorillaRig _carlos = GorillaRig();
  double _time = 0;

  void _populate(Scene scene) {
    final jungle = _jungle = JunglePatch(
      radius: 4.2,
      clearing: true,
      seed: 11,
      fixed: true,
    );
    final inventory = context.read<GameInventoryCubit>().state.inventory;
    _carlos.look = inventory.monkeys.first.look;
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.4, -1, -0.3),
        castsShadow: true,
        shadowSoftness: 0.3,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        colorGradingEnabled: true,
        saturation: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.9,
        fogEnabled: true,
        fogMode: FogMode.linear,
        fogColor: linearColor(jungleMistOf(context)).xyz,
        fogStart: 12,
        fogEnd: 30,
      )
      ..add(jungle.root)
      ..add(_carlos.root);
  }

  void _tick(double deltaSeconds) {
    _time += deltaSeconds;
    final jungle = _jungle;
    if (jungle == null) return;
    // Walk in from the gate to the middle of the clearing, then sit.
    const walkIn = 1.8;
    final start = jungle.gate;
    final end = vm.Vector3(0, jungleFloorTop, -0.4);
    final t = (_time / walkIn).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - t, 2).toDouble();
    _carlos
      ..activity = t < 1 ? GorillaActivity.walking : GorillaActivity.idle
      ..root.position = start + (end - start) * eased
      ..root.rotation = t < 1
          ? vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), math.pi)
          : vm.Quaternion.identity()
      ..update(deltaSeconds);
    jungle.update(deltaSeconds);
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final angle = math.sin(t * 0.15) * 0.25;
    final target = vm.Vector3(0, -0.5, 0.4);
    const distance = 9.5;

    return PerspectiveCamera(
      fovRadiansY: 40 * vm.degrees2Radians,
      position: target +
          vm.Vector3(
            math.sin(angle) * distance,
            2.8,
            math.cos(angle) * distance,
          ),
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) => SceneStage(
        populate: _populate,
        cameraBuilder: _camera,
        onTick: _tick,
        // Compile the shaders first, so the clearing never shows half drawn.
        warmUp: true,
        onReady: widget.onReady,
      );
}
