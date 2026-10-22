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
import 'package:pushup_bro/features/jungle/jungle.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Matches the bottom of the island screen's sky gradient, so the fogged
/// horizon melts into the backdrop.
const islandHorizon = Color(0xFFDDF1FA);

/// The 3D island. Drag sideways to turn it; tap the jungle (or call
/// [IslandSceneState.goToJungle]) and Carlos runs into it before the jungle
/// screen opens.
class IslandScene extends StatefulWidget {
  const IslandScene({this.onJourneyChanged, super.key});

  /// Called with true when Carlos sets off for the jungle and with false
  /// once he is back on the island.
  final ValueChanged<bool>? onJourneyChanged;

  @override
  State<IslandScene> createState() => IslandSceneState();
}

class IslandSceneState extends State<IslandScene> {
  /// Built in [_populate]: geometry needs the engine's static resources.
  IslandWorld? _world;
  double _yaw = 0;
  double _yawVelocity = 0;

  /// 0 for the overview, 1 when following Carlos to the jungle.
  double _focus = 0;
  Scene? _scene;
  Camera? _lastCamera;
  Size _viewSize = Size.zero;

  /// Sends Carlos running into the jungle, then opens the jungle screen.
  void goToJungle() {
    final world = _world;
    if (world == null || world.running) return;
    widget.onJourneyChanged?.call(true);
    world.runToJungle(() async {
      await Navigator.of(context).pushNamed(Jungle.routeName);
      if (!mounted) return;
      _world?.stopRun();
      widget.onJourneyChanged?.call(false);
    });
  }

  void _onTapUp(TapUpDetails details) {
    final world = _world;
    final camera = _lastCamera;
    if (world == null || camera == null || _viewSize.isEmpty) return;
    final ray = camera.screenPointToRay(details.localPosition, _viewSize);
    final hit = _scene?.raycast(ray);
    if (hit != null && world.isJungle(hit.node)) goToJungle();
  }

  void _populate(Scene scene) {
    _scene = scene;
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
        fogStart: 50,
        fogEnd: 120,
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
    final running = _world?.running ?? false;
    if (running) {
      // Swing round so the jungle is straight ahead.
      final nearest = (_yaw / (math.pi * 2)).roundToDouble() * math.pi * 2;
      _yaw = springTo(_yaw, nearest, deltaSeconds, 2.5);
      _yawVelocity = 0;
    } else {
      // Let a flick keep turning the island for a moment.
      _yaw += _yawVelocity * deltaSeconds;
      _yawVelocity = springTo(_yawVelocity, 0, deltaSeconds, 3);
    }
    _focus = springTo(_focus, running ? 1 : 0, deltaSeconds, 2);
    _world?.update(deltaSeconds);
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final angle = _yaw + math.sin(t * 0.12) * 0.1 * (1 - _focus);
    // Far back: a portrait phone sees little horizontally. The camera backs
    // off slower than the island grows, so a bigger island fills more of the
    // screen. Following Carlos, it closes in on the jungle gate.
    final world = _world;
    final extent = world?.extent ?? 5.5;
    final overview = vm.Vector3(0, 0.3, -0.18 * extent);
    final target = world == null
        ? overview
        : overview + (world.jungleGate - overview) * (_focus * 0.85);
    final distance = 4.6 * (5.9 + 0.55 * (extent - 5.5)) * (1 - 0.6 * _focus);
    final height = distance * (1.0 - 0.3 * _focus);
    // Keep the fog beyond the island however far back the camera goes.
    _scene?.fog
      ?..start = distance * 1.9
      ..end = distance * 4.5;

    return _lastCamera = PerspectiveCamera(
      fovRadiansY: 32 * vm.degrees2Radians,
      position: target +
          vm.Vector3(
            math.sin(angle) * distance,
            height,
            math.cos(angle) * distance,
          ),
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<GameInventoryCubit, GameInventoryState>(
        listener: (context, state) => _syncInventory(state.inventory),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _viewSize = constraints.biggest;

            return GestureDetector(
              onTapUp: _onTapUp,
              onHorizontalDragUpdate: (details) {
                if (_world?.running ?? false) return;
                _yaw -= details.delta.dx * 0.008;
                _yawVelocity = 0;
              },
              onHorizontalDragEnd: (details) {
                if (_world?.running ?? false) return;
                _yawVelocity = -(details.primaryVelocity ?? 0) * 0.004;
              },
              child: SceneStage(
                populate: _populate,
                cameraBuilder: _camera,
                onTick: _tick,
              ),
            );
          },
        ),
      );
}
