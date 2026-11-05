import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/buildings/adoption/island_friends.dart';
import 'package:pushup_bro/features/island/buildings/airport/airport_plane.dart';
import 'package:pushup_bro/features/island/buildings/airport/gift_drop_actions.dart';
import 'package:pushup_bro/features/island/buildings/airport/gift_tag.dart';
import 'package:pushup_bro/features/island/buildings/airport/island_drops.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_editor.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_placement.dart';
import 'package:pushup_bro/features/island/model/island_snapshot.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart';
import 'package:pushup_bro/features/island/widgets/speech_bubble.dart';
import 'package:pushup_bro/features/jungle/jungle.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/widgets/lock_pin.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The island's sky behind the 3D scene. By day the theme's ice blue washed
/// with white, so it stays bright in dark mode like the world itself; at
/// night (see `isNight`) a deep night blue in either theme. The fog uses
/// its `horizon` too, so the far sea melts into the backdrop.
typedef IslandSky = ({Color top, Color horizon});

IslandSky islandSky(BuildContext context, {bool night = false}) {
  if (night) return (top: _nightTop, horizon: _nightHorizon);
  final game = context.gameColors;

  return (
    top: Color.lerp(game.ice, game.onGame, 0.5)!,
    horizon: Color.lerp(game.ice, game.onGame, 0.85)!,
  );
}

const _nightTop = Color(0xFF0A1230);
const _nightHorizon = Color(0xFF1B2D5C);

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
    this.snapshot,
    this.greetings,
    this.rise,
    this.intro,
    this.night = false,
    this.onBuildingTap,
    this.decorEditor,
    this.onDecorLongPress,
    this.drops,
    super.key,
  });

  /// While it's [DecorEditor.active], the island shows its pieces instead:
  /// taps pick a decoration, dragging one moves it over the ground, and
  /// dragging anywhere else still turns the island.
  final DecorEditor? decorEditor;

  /// Called with the decoration held down on the player's own island, to
  /// start moving it.
  final ValueChanged<int>? onDecorLongPress;

  /// Gifts to show falling onto a friend's island (the visitor's own
  /// drop). The player's own island shows the gifts waiting for them.
  final List<GiftDrop>? drops;

  /// Called with the building tapped on the player's own island (the food
  /// truck is [ShopBuyables.none]).
  final ValueChanged<ShopBuyables>? onBuildingTap;

  /// Whether to show the island at night: moonlit, with torches burning.
  /// Callers decide with `isNight`, so the sky behind matches.
  final bool night;

  /// 1 for a close-up of Carlos, 0 for the normal view: the first visit
  /// zooms out from him to the whole island after the intro film.
  final ValueListenable<double>? intro;

  /// A friend's island to visit instead of the player's own: read-only,
  /// with no shop, quests or jungle trip. Drag still turns it, and tapping
  /// their Carlos makes him wave and say one of [greetings].
  final IslandSnapshot? snapshot;
  final List<String>? greetings;

  /// 0 for the normal view; towards 1 the camera rises until it looks
  /// straight down on the island, turning a little and closing in (the
  /// start of "Share my island").
  final ValueListenable<double>? rise;

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
  IslandFriends? _friends;
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

  /// The player's decorations as saved, shown while not editing.
  List<DecorPiece> _decor = const [];

  /// The decoration being dragged, and where on it the finger took hold.
  int? _dragging;
  vm.Vector2 _grab = vm.Vector2.zero();

  /// 1 while editing: the camera stops drifting, so pieces stay under the
  /// finger.
  double _still = 0;

  bool get _editing => widget.decorEditor?.active ?? false;
  bool _wasEditing = false;

  /// Gifts from friends as crates, and the airport's plane.
  IslandDrops? _crates;
  AirportPlane? _plane;
  OwnGiftDrops? _ownDrops;
  List<GiftDrop> _waiting = const [];
  bool _dropsSeen = false;

  /// Where the senders' name tags sit over the crates.
  final ValueNotifier<List<(GiftDrop, Offset)>> _dropTags = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    widget.decorEditor?.addListener(_showDecor);
    if (widget.snapshot != null) {
      _waiting = widget.drops ?? const [];
      return;
    }
    // Nullable: an island without an account (a preview) has no gifts.
    final account = context.read<AccountCubit?>();
    if (account == null) return;
    _ownDrops = OwnGiftDrops(account, (drops) {
      _waiting = drops;
      // Gifts already there on opening don't fall; new ones do.
      _crates?.sync(drops, fall: _dropsSeen);
      _dropsSeen = true;
    })
      ..start();
  }

  /// Opens a gift on the player's own island.
  void _openDrop(GiftDrop drop) {
    if (widget.snapshot != null) return;
    _waiting = [..._waiting.where((other) => other.id != drop.id)];
    _crates?.sync(_waiting);
    unawaited(openGiftDrop(context, drop));
  }

  /// The crates land on the open lawn in front, a little towards the
  /// airport when there is one, where neither palms nor buildings hide
  /// them.
  vm.Vector3 _dropAnchor(IslandWorld world) {
    final airport = world.spotOf(ShopBuyables.airport);

    return vm.Vector3(
      (airport?.x ?? 0) * 0.15,
      grassTop,
      world.radius * 0.68,
    );
  }

  @override
  void didUpdateWidget(IslandScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decorEditor != widget.decorEditor) {
      oldWidget.decorEditor?.removeListener(_showDecor);
      widget.decorEditor?.addListener(_showDecor);
    }
    // Night can fall (or end) while the island is open.
    final scene = _scene;
    if (widget.night != oldWidget.night && scene != null) _light(scene);
    if (widget.snapshot != null && widget.drops != oldWidget.drops) {
      _waiting = widget.drops ?? const [];
      _crates?.sync(_waiting, fall: true);
    }
  }

  @override
  void dispose() {
    widget.decorEditor?.removeListener(_showDecor);
    _whiteout.dispose();
    _bubbleAnchor.dispose();
    _pins.dispose();
    _ownDrops?.dispose();
    _dropTags.dispose();
    super.dispose();
  }

  /// Carlos turns to the camera, waves and says [line].
  void waveHello(String line) {
    final world = _world;
    final camera = _lastCamera;
    if (world == null || camera == null) return;
    world.greet(camera.position - world.gorilla.root.position, seconds: 3);
    setState(() => _bubble = line);
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
    if (_editing) {
      widget.decorEditor?.select(_decorAt(details.localPosition));
      return;
    }
    final ray = camera.screenPointToRay(details.localPosition, _viewSize);
    final hit = _scene?.raycast(ray);
    // Carlos is small from up here, so anywhere near him counts too.
    final carlos = camera.worldToScreen(
      world.gorilla.root.position + vm.Vector3(0, 0.5, 0),
      _viewSize,
    );
    final nearCarlos =
        carlos != null && (carlos - details.localPosition).distance < 56;
    final drop = hit == null ? null : _crates?.dropOf(hit.node);
    if (drop != null) {
      _openDrop(drop);
      return;
    }
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
      final lines = widget.greetings ?? _greetings(context.l10n);
      setState(() => _bubble = lines[_greetingCount++ % lines.length]);
    } else if (widget.snapshot == null &&
        hit != null &&
        world.isJungle(hit.node)) {
      goToJungle();
    } else if (widget.snapshot == null && hit != null) {
      final building = world.buildingOf(hit.node);
      if (building != null) widget.onBuildingTap?.call(building);
    }
  }

  void _populate(Scene scene) {
    _scene = scene;
    final world = _world = IslandWorld();
    final friends = _friends = IslandFriends();
    world.root.add(friends.root);
    final snapshot = widget.snapshot;
    if (snapshot == null) {
      final inventory = context.read<GameInventoryCubit>().state.inventory;
      _syncInventory(inventory);
      friends.looks = inventory.islandFriends;
    } else {
      world
        ..showOwned(snapshot.bought)
        ..gorilla.look = snapshot.look;
      friends.looks = snapshot.friends;
      _decor = snapshot.decor;
      _showDecor();
    }
    _light(scene);
    scene.add(world.root);
    final crates = _crates = IslandDrops()
      ..onLanded = ((_) => GameAudio.instance.play(Sfx.pop))
      ..sync(_waiting, fall: widget.snapshot != null);
    final plane = _plane = AirportPlane();
    scene
      ..add(crates.root)
      ..add(plane.root);
  }

  /// Sunlight by day; by night a dim, cool moon and a darker world, so the
  /// torches' flames (which ignore the light) glow against it.
  void _light(Scene scene) {
    final night = widget.night;
    _world?.night = night;
    final horizon = linearColor(islandSky(context, night: night).horizon);
    scene
      ..directionalLight = night
          ? DirectionalLight(
              direction: vm.Vector3(0.45, -1, -0.5),
              intensity: 0.55,
              color: vm.Vector3(0.6, 0.72, 1),
              castsShadow: true,
              shadowSoftness: 0.35,
            )
          : DirectionalLight(
              direction: vm.Vector3(-0.5, -1, -0.45),
              intensity: 3.4,
              castsShadow: true,
              shadowSoftness: 0.2,
            )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        environmentIntensity: night ? 0.1 : 1,
        colorGradingEnabled: true,
        saturation: night ? 0.85 : 1.1,
        temperature: night ? -0.25 : 0,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
        fogEnabled: true,
        // Only the far sea fades into the sky; the island stays crisp.
        fogMode: FogMode.linear,
        fogColor: horizon.xyz,
        fogStart: 50,
        fogEnd: 120,
      );
  }

  void _syncInventory(GameInventory inventory) {
    _world
      ?..showOwned(inventory.boughtItems)
      ..gorilla.look = inventory.monkeys.first.look;
    _decor = inventory.decor;
    _showDecor();
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
    // While the first visit zooms out from him, the intro frames him.
    final intro = (widget.intro?.value ?? 0) > 0;
    _closeUp = springTo(_closeUp, greeting && !intro ? 1 : 0, deltaSeconds, 3);
    final camera = _lastCamera;
    _bubbleAnchor.value = greeting && world != null && camera != null
        ? camera.worldToScreen(world.carlosHead, _viewSize)
        : null;
    _placePins(world, camera);
    if (world != null) {
      _crates?.update(deltaSeconds, anchor: _dropAnchor(world));
      _plane?.update(
        deltaSeconds,
        airport: world.spotOf(ShopBuyables.airport),
      );
    }
    _placeDropTags(camera);
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
    _still = springTo(_still, _editing ? 1 : 0, deltaSeconds, 3);
    world?.update(deltaSeconds, eye: camera?.position);
    if (world != null) _friends?.update(deltaSeconds, radius: world.radius);
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

  void _placeDropTags(Camera? camera) {
    final crates = _crates;
    if (crates == null || camera == null || _waiting.isEmpty) {
      if (_dropTags.value.isNotEmpty) _dropTags.value = [];
      return;
    }
    _dropTags.value = [
      for (final (drop, spot) in crates.tagSpots)
        if (camera.worldToScreen(spot, _viewSize) case final point?)
          (drop, point),
    ];
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final angle = _yaw + math.sin(t * 0.12) * 0.1 * (1 - _focus) * (1 - _still);
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
    final intro = widget.intro?.value ?? 0;
    if (world != null && intro > 0.001) {
      final carlos = world.gorilla.root.position + vm.Vector3(0, 0.5, 0);
      target += (carlos - target) * intro;
      distance += (4.2 - distance) * intro;
      height += (1.5 - height) * intro;
    }
    // Keep the fog beyond the island however far back the camera goes. At
    // night it closes in a little, so the dark sea melts into the sky.
    final fogFrom = widget.night ? 1.5 : 1.9;
    final fogTo = widget.night ? 3.6 : 4.5;
    _scene?.fog
      ?..start = distance * fogFrom
      ..end = distance * fogTo;
    // Rising to look straight down: the same distance, all of it overhead
    // (a sliver stays sideways so the camera still knows which way is
    // up), turning a little and closing in by about 12%.
    final rise = widget.rise?.value ?? 0;
    final range = math.sqrt(distance * distance + height * height);
    final sideways = distance * (1 - rise * 0.985);
    final turned = angle + rise * 0.6;
    final up = (height + (range - height) * rise) * (1 - 0.12 * rise);
    if (rise > 0) target = target + (vm.Vector3(0, 0, 0) - target) * rise;

    return _lastCamera = PerspectiveCamera(
      fovRadiansY: 32 * vm.degrees2Radians,
      position: target +
          vm.Vector3(
            math.sin(turned) * sideways,
            up,
            math.cos(turned) * sideways,
          ),
      target: target,
    );
  }

  /// Shows the pieces being edited, or else the saved ones as they fit on
  /// the island now.
  void _showDecor() {
    final world = _world;
    if (world == null) return;
    final editor = widget.decorEditor;
    if (editor != null && editor.active) {
      world.decor.show(
        editor.pieces,
        selected: editor.selected,
        blocked: editor.blocked,
      );
    } else {
      world.decor.show(DecorPlacement(world.plan).settle(_decor));
    }
    // Rebuilt when edit mode starts or ends, so the gestures follow it.
    final editing = editor?.active ?? false;
    if (editing != _wasEditing && mounted) {
      setState(() => _wasEditing = editing);
    }
  }

  /// Where the finger at [point] meets the island's ground, or null above
  /// the horizon.
  vm.Vector2? _groundAt(Offset point) {
    final camera = _lastCamera;
    if (camera == null || _viewSize.isEmpty) return null;
    final ray = camera.screenPointToRay(point, _viewSize);
    if (ray.direction.y > -1e-4) return null;
    final t = (grassTop - ray.origin.y) / ray.direction.y;
    final hit = ray.origin + ray.direction * t;

    return vm.Vector2(hit.x, hit.z);
  }

  /// The decoration under [point]: the one the finger touches, or else one
  /// standing close to where it meets the ground (small ones are hard to
  /// hit from up here).
  int? _decorAt(Offset point) {
    final world = _world;
    final camera = _lastCamera;
    if (world == null || camera == null || _viewSize.isEmpty) return null;
    final hit = _scene?.raycast(camera.screenPointToRay(point, _viewSize));
    final touched = hit == null ? null : world.decor.pieceOf(hit.node);
    if (touched != null) return touched;
    final ground = _groundAt(point);
    if (ground == null) return null;
    final editor = widget.decorEditor;
    final pieces = editor != null && editor.active
        ? editor.pieces
        : DecorPlacement(world.plan).settle(_decor);
    int? nearest;
    var best = double.infinity;
    for (final (i, piece) in pieces.indexed) {
      if (!piece.placed) continue;
      final distance = ground.distanceTo(vm.Vector2(piece.x, piece.z));
      if (distance < piece.item.radius + 0.25 && distance < best) {
        best = distance;
        nearest = i;
      }
    }

    return nearest;
  }

  void _editDragStart(DragStartDetails details) {
    final editor = widget.decorEditor;
    if (editor == null) return;
    final index = _decorAt(details.localPosition);
    final ground = _groundAt(details.localPosition);
    if (index == null || ground == null) {
      _dragging = null;
      return;
    }
    editor.select(index);
    _dragging = index;
    final piece = editor.pieces[index];
    _grab = ground - vm.Vector2(piece.x, piece.z);
  }

  void _editDragUpdate(DragUpdateDetails details) {
    if (_dragging == null) {
      _yaw -= details.delta.dx * 0.008;
      _yawVelocity = 0;
      return;
    }
    final ground = _groundAt(details.localPosition);
    if (ground == null) return;
    final at = ground - _grab;
    widget.decorEditor?.dragTo(at.x, at.y);
  }

  void _editDragEnd(DragEndDetails details) {
    if (_dragging == null) {
      _yawVelocity = -details.velocity.pixelsPerSecond.dx * 0.004;
      return;
    }
    _dragging = null;
    widget.decorEditor?.endDrag();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<GameInventoryCubit, GameInventoryState>(
        listenWhen: (_, __) => widget.snapshot == null,
        listener: (context, state) {
          _syncInventory(state.inventory);
          // Saving passes through an empty inventory for a moment.
          if (state is! GameInventoryFetching) {
            _friends?.looks = state.inventory.islandFriends;
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _viewSize = constraints.biggest;

            final editing = _editing;

            return GestureDetector(
              onTapUp: _onTapUp,
              onLongPressStart: widget.onDecorLongPress == null || editing
                  ? null
                  : (details) {
                      final index = _decorAt(details.localPosition);
                      if (index != null) widget.onDecorLongPress?.call(index);
                    },
              onPanStart: editing ? _editDragStart : null,
              onPanUpdate: editing ? _editDragUpdate : null,
              onPanEnd: editing ? _editDragEnd : null,
              onHorizontalDragUpdate: editing
                  ? null
                  : (details) {
                      if (_world?.running ?? false) return;
                      _yaw -= details.delta.dx * 0.008;
                      _yawVelocity = 0;
                    },
              onHorizontalDragEnd: editing
                  ? null
                  : (details) {
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
                  Positioned.fill(
                    child: ValueListenableBuilder<List<(GiftDrop, Offset)>>(
                      valueListenable: _dropTags,
                      builder: (context, tags, _) => Stack(
                        children: [
                          for (final (drop, point) in tags)
                            Positioned(
                              left: point.dx - 60,
                              top: point.dy - 30,
                              width: 120,
                              child: Center(
                                child: GiftTag(
                                  drop: drop,
                                  onTap: widget.snapshot == null
                                      ? () => _openDrop(drop)
                                      : null,
                                ),
                              ),
                            ),
                        ],
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
