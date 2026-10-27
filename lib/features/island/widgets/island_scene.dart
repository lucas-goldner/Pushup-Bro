import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart';
import 'package:pushup_bro/features/island/widgets/speech_bubble.dart';
import 'package:pushup_bro/features/jungle/jungle.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/widgets/lock_pin.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The island's day sky behind the 3D scene: the theme's ice blue washed
/// with white, so it stays bright in dark mode like the world itself. The
/// fog uses its `horizon` too, so the far sea melts into the backdrop.
typedef IslandSky = ({Color top, Color horizon});

IslandSky islandSky(BuildContext context) {
  final game = context.gameColors;

  return (
    top: Color.lerp(game.ice, game.onGame, 0.5)!,
    horizon: Color.lerp(game.ice, game.onGame, 0.85)!,
  );
}

/// Things Carlos says when he's tapped.
List<String> _greetings(S l) =>
    [l.greet1, l.greet2, l.greet3, l.greet4, l.greet5, l.greet6, l.greet7];

/// The 3D island. Drag sideways to turn it. Tap Carlos and the camera
/// closes in while he waves and says hi; tap the jungle (or call
/// [IslandSceneState.goToJungle]) and he runs in, the camera dives after
/// him and everything fades to white before the jungle screen opens.
class IslandScene extends StatefulWidget {
  const IslandScene({
    this.onJourneyChanged,
    this.locked = false,
    this.onLockedTap,
    super.key,
  });

  /// Called with true when Carlos sets off for the jungle and with false
  /// once he is back on the island.
  final ValueChanged<bool>? onJourneyChanged;

  /// Without Pro the island can only be looked at: lock pins float over
  /// the jungle, the shop and Carlos, and tapping them calls [onLockedTap].
  final bool locked;
  final ValueChanged<ProLockPlace>? onLockedTap;

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

  /// 0 to 1 while the camera dives through the jungle gate after him.
  double _dive = 0;
  bool _diving = false;

  /// 0 for the overview, 1 for a close-up of Carlos saying hi.
  double _closeUp = 0;
  int _greetingCount = 0;

  Scene? _scene;
  Camera? _lastCamera;
  Size _viewSize = Size.zero;

  /// How white the screen is: up during the dive, down on the way back.
  final ValueNotifier<double> _whiteout = ValueNotifier(0);

  /// Where Carlos's speech bubble points, and what it says.
  final ValueNotifier<Offset?> _bubbleAnchor = ValueNotifier(null);
  String _bubble = '';

  /// Where the lock pins sit on screen while the island is locked.
  final ValueNotifier<Map<ProLockPlace, Offset>> _pins = ValueNotifier({});

  @override
  void dispose() {
    _whiteout.dispose();
    _bubbleAnchor.dispose();
    _pins.dispose();
    super.dispose();
  }

  /// Sends Carlos running into the jungle, then opens the jungle screen.
  void goToJungle() {
    final world = _world;
    if (world == null || world.running) return;
    widget.onJourneyChanged?.call(true);
    GameAudio.instance.play(Sfx.whoosh);
    world.runToJungle(() => _diving = true);
  }

  Future<void> _enterJungle() async {
    await Navigator.of(context).pushNamed(Jungle.routeName);
    if (!mounted) return;
    _world?.stopRun();
    _dive = 0;
    widget.onJourneyChanged?.call(false);
  }

  void _onTapUp(TapUpDetails details) {
    final world = _world;
    final camera = _lastCamera;
    if (world == null || camera == null || _viewSize.isEmpty) return;
    if (world.running) return;
    final ray = camera.screenPointToRay(details.localPosition, _viewSize);
    final hit = _scene?.raycast(ray);
    // Carlos is small from up here, so anywhere near him counts too.
    final carlos = camera.worldToScreen(
      world.gorilla.root.position + vm.Vector3(0, 0.5, 0),
      _viewSize,
    );
    final nearCarlos =
        carlos != null && (carlos - details.localPosition).distance < 56;
    if (widget.locked) {
      final place = nearCarlos || (hit != null && world.isCarlos(hit.node))
          ? ProLockPlace.carlos
          : hit == null
              ? null
              : world.isJungle(hit.node)
                  ? ProLockPlace.jungle
                  : world.isBuilding(hit.node)
                      ? ProLockPlace.shop
                      : null;
      if (place != null) widget.onLockedTap?.call(place);
      return;
    }
    if (nearCarlos || (hit != null && world.isCarlos(hit.node))) {
      world.greet(camera.position - world.gorilla.root.position);
      setState(
        () => _bubble = _greetings(context.l10n)[_greetingCount++ % 7],
      );
    } else if (hit != null && world.isJungle(hit.node)) {
      goToJungle();
    }
  }

  void _populate(Scene scene) {
    _scene = scene;
    final world = _world = IslandWorld();
    _syncInventory(context.read<GameInventoryCubit>().state.inventory);
    final horizon = linearColor(islandSky(context).horizon);
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
      ..gorilla.look = inventory.monkeys.first.look;
  }

  void _tick(double deltaSeconds) {
    final world = _world;
    final running = world?.running ?? false;
    if (_diving) {
      _dive = math.min(1, _dive + deltaSeconds / 1.1);
      // Fade to white over the second half of the dive.
      _whiteout.value = ((_dive - 0.35) / 0.65).clamp(0, 1).toDouble();
      if (_dive >= 1) {
        _diving = false;
        unawaited(_enterJungle());
      }
    } else if (!running && _whiteout.value > 0) {
      // Back from the jungle: fade the white away again.
      _whiteout.value = math.max(0, _whiteout.value - deltaSeconds / 0.7);
    }
    final greeting = world?.greeting ?? false;
    _closeUp = springTo(_closeUp, greeting ? 1 : 0, deltaSeconds, 3);
    final camera = _lastCamera;
    _bubbleAnchor.value = greeting && world != null && camera != null
        ? camera.worldToScreen(world.carlosHead, _viewSize)
        : null;
    _placePins(world, camera);
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
    world?.update(deltaSeconds);
  }

  void _placePins(IslandWorld? world, Camera? camera) {
    if (!widget.locked || world == null || camera == null) {
      if (_pins.value.isNotEmpty) _pins.value = {};
      return;
    }
    _pins.value = {
      for (final (place, spot) in [
        (ProLockPlace.jungle, world.jungleSpot),
        (ProLockPlace.shop, world.shopSpot),
        (ProLockPlace.carlos, world.carlosHead + vm.Vector3(0, 0.45, 0)),
      ])
        if (camera.worldToScreen(spot, _viewSize) case final point?)
          place: point,
    };
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final angle = _yaw + math.sin(t * 0.12) * 0.1 * (1 - _focus);
    // Far back: a portrait phone sees little horizontally. The camera backs
    // off slower than the island grows, so a bigger island fills more of the
    // screen. Following Carlos, it closes in on the jungle gate.
    // Diving after him, it flies on through the gate; saying hi, it
    // closes in on Carlos.
    final world = _world;
    final extent = world?.extent ?? 5.5;
    final overview = vm.Vector3(0, 0.3, -0.18 * extent);
    var target = world == null
        ? overview
        : overview + (world.jungleGate - overview) * (_focus * 0.85);
    var distance = 4.6 * (5.9 + 0.55 * (extent - 5.5)) * (1 - 0.6 * _focus);
    var height = distance * (1.0 - 0.3 * _focus);
    if (world != null && _dive > 0) {
      final dive = _dive * _dive * (3 - 2 * _dive);
      final through = world.jungleGate + vm.Vector3(0, 0.5, -1.2);
      target += (through - target) * dive;
      distance *= 1 - 0.9 * dive;
      height *= 1 - 0.85 * dive;
    }
    if (world != null && _closeUp > 0.001) {
      final carlos = world.gorilla.root.position + vm.Vector3(0, 0.55, 0);
      target += (carlos - target) * _closeUp;
      distance += (5.5 - distance) * _closeUp;
      height += (2.2 - height) * _closeUp;
    }
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SceneStage(
                      populate: _populate,
                      cameraBuilder: _camera,
                      onTick: _tick,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<Offset?>(
                        valueListenable: _bubbleAnchor,
                        builder: (context, anchor, _) => anchor == null
                            ? const SizedBox.shrink()
                            : Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: anchor.dy - 80,
                                    child: Center(
                                      child: SpeechBubble(
                                        _bubble,
                                        key: ValueKey(_bubble),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (widget.locked)
                    Positioned.fill(
                      child: ValueListenableBuilder<Map<ProLockPlace, Offset>>(
                        valueListenable: _pins,
                        builder: (context, pins, _) => Stack(
                          children: [
                            for (final MapEntry(key: place, value: point)
                                in pins.entries)
                              Positioned(
                                left: point.dx - _pinSize(place) / 2,
                                top: point.dy - _pinSize(place) / 2,
                                child: LockPin(
                                  size: _pinSize(place),
                                  phase: place.index / 3,
                                  label: _pinLabel(context, place),
                                  onTap: () => widget.onLockedTap?.call(place),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _whiteout,
                        builder: (context, white, _) => white <= 0
                            ? const SizedBox.shrink()
                            : ColoredBox(
                                color: context.gameColors.onGame
                                    .withValues(alpha: white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

double _pinSize(ProLockPlace place) => place == ProLockPlace.jungle ? 48 : 40;

String _pinLabel(BuildContext context, ProLockPlace place) => switch (place) {
      ProLockPlace.jungle => context.l10n.proLockJungleTitle,
      ProLockPlace.shop => context.l10n.proLockShopTitle,
      ProLockPlace.carlos => context.l10n.proLockCarlosTitle,
    };
