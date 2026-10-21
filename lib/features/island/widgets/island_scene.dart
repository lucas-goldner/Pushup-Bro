import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Matches the bottom of the island screen's sky gradient, so the fogged
/// horizon melts into the backdrop.
const islandHorizon = Color(0xFFDDF1FA);

/// The 3D island. Drag sideways to turn it.
class IslandScene extends StatefulWidget {
  const IslandScene({super.key});

  @override
  State<IslandScene> createState() => _IslandSceneState();
}

class _IslandSceneState extends State<IslandScene> {
  /// Built in [_populate]: geometry needs the engine's static resources.
  IslandWorld? _world;
  double _yaw = 0;
  double _yawVelocity = 0;

  void _populate(Scene scene) {
    final world = _world = IslandWorld();
    _syncInventory(context.read<GameInventoryCubit>().state.inventory);
    final horizon = linearColor(islandHorizon);
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.5, -1, -0.45),
        intensity: 3.4,
        castsShadow: true,
        shadowSoftness: 0.2,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        colorGradingEnabled: true,
        saturation: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
        fogEnabled: true,
        // Only the far sea fades into the sky; the island stays crisp.
        fogMode: FogMode.linear,
        fogColor: horizon.xyz,
        fogStart: 34,
        fogEnd: 70,
      )
      ..add(world.root);
  }

  void _syncInventory(GameInventory inventory) {
    _world
      ?..showOwned(inventory.boughtItems)
      ..gorilla.partyHat =
          inventory.monkeys.first.accessory == ShopBuyables.accessoryPartyHat;
  }

  void _tick(double deltaSeconds) {
    // Let a flick keep turning the island for a moment.
    _yaw += _yawVelocity * deltaSeconds;
    _yawVelocity = springTo(_yawVelocity, 0, deltaSeconds, 3);
    _world?.update(deltaSeconds);
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final angle = _yaw + math.sin(t * 0.12) * 0.1;
    // Far back: a portrait phone sees little horizontally, and the whole
    // grassy part of the island should fit between the HUD and the dock.
    const distance = 21.0;
    final target = vm.Vector3(0, 0.2, -0.9);

    return PerspectiveCamera(
      fovRadiansY: 32 * vm.degrees2Radians,
      position: target +
          vm.Vector3(
            math.sin(angle) * distance,
            18,
            math.cos(angle) * distance,
          ),
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<GameInventoryCubit, GameInventoryState>(
        listener: (context, state) => _syncInventory(state.inventory),
        child: GestureDetector(
          onHorizontalDragUpdate: (details) {
            _yaw -= details.delta.dx * 0.008;
            _yawVelocity = 0;
          },
          onHorizontalDragEnd: (details) =>
              _yawVelocity = -(details.primaryVelocity ?? 0) * 0.004,
          child: SceneStage(
            populate: _populate,
            cameraBuilder: _camera,
            onTick: _tick,
          ),
        ),
      );
}
