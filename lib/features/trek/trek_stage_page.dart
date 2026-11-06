import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart' hide Material;
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/audio/music_places.dart';
import 'package:pushup_bro/core/audio/music_scope.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/one_move.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/widgets/speech_bubble.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_tracker.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_window.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/tracking_mode_picker.dart';
import 'package:pushup_bro/features/quest/scene/location_world.dart';
import 'package:pushup_bro/features/quest/widgets/dialog_box.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/boon.dart';
import 'package:pushup_bro/features/trek/model/tower_week.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/scene/trek_world.dart';
import 'package:pushup_bro/features/trek/widgets/battle_hud.dart';
import 'package:pushup_bro/features/trek/widgets/difficulty_picker.dart';
import 'package:pushup_bro/features/trek/widgets/rest_panel.dart';
import 'package:pushup_bro/features/trek/widgets/tower_panel.dart';
import 'package:pushup_bro/features/trek/widgets/trek_result.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// How long the rest between waves is, at most.
const restSeconds = 20;

enum _Phase { title, intro, ready, fight, rest, outro, results, knockedOut }

/// The rewards of a won stage, worked out when it ends.
class TrekReward {
  const TrekReward({
    required this.xp,
    required this.levelsGained,
    required this.stars,
    required this.bananas,
    required this.loot,
    required this.adopted,
    this.pushups = 0,
    this.damage = 0,
    this.bestCombo = 0,
    this.bestComboBefore = 0,
    this.goals = const [],
    this.floor = 0,
    this.bestFloor = 0,
  });

  final int xp;
  final int levelsGained;
  final int stars;
  final int bananas;

  /// The cosmetic won, the first time only.
  final String? loot;

  /// Whether King Komo just joined the island.
  final bool adopted;

  /// For the share video: pushups, damage dealt and the longest quick
  /// combo of the stage, and the best combo of every stage before.
  final int pushups;
  final int damage;
  final int bestCombo;
  final int bestComboBefore;

  /// The stage's star goals and whether each was met.
  final List<(StageGoal, bool)> goals;

  /// In the tower: the floor reached, and the best before this climb.
  final int floor;
  final int bestFloor;
}

/// One stage of the Jungle Trek from start to finish: a title card, the
/// story, then wave after wave of reptiles fought with pushups, rests in
/// between, and the ending with its rewards.
class TrekStagePage extends StatefulWidget {
  const TrekStagePage({required this.stage, super.key});
  static const routeName = '/trek/stage';

  final TrekStage stage;

  @override
  State<TrekStagePage> createState() => _TrekStagePageState();
}

class _TrekStagePageState extends State<TrekStagePage> with OneMove {
  _Phase _phase = _Phase.title;
  int _line = 0;
  late Battle _battle;
  TrekWorld? _world;
  Size _viewSize = Size.zero;
  double? _lastCameraTime;
  Camera? _lastCamera;
  bool _white = true;

  /// Leaving: the camera window is gone.
  bool _closing = false;

  vm.Vector3 _cameraTarget = vm.Vector3(0, 0.6, -2);
  vm.Vector3 _cameraPosition = vm.Vector3(1.5, 2.6, 7);

  // Tracking.
  StreamSubscription<PushupState>? _pushupSubscription;
  int _counted = 0;
  double _damage = 0;
  int _bestCombo = 0;
  DateTime? _downSince;
  DateTime? _lastRep;
  int? _volume;
  bool _listening = false;

  // Feedback.
  final List<Popup> _popups = [];
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final Map<Foe, Offset> _anchors = {};
  double _shake = 0;
  double _hurt = 0;
  String? _banner;

  /// The banner's colour; the game's white when null.
  Color? _bannerColor;
  double _bannerTime = 0;
  String? _taunt;
  double _tauntTime = 0;

  // Juice: a white flash, a short freeze on big hits, and slow motion for
  // the blow that wins.
  double _flash = 0;
  double _freeze = 0;
  double _slowMo = 0;
  int _chargeTick = -1;

  // Rest.
  double _restLeft = 0;
  List<Boon> _offer = const [];
  Boon? _picked;
  TrekReward? _reward;

  TrekStage get _stage => widget.stage;
  bool get _tower => _stage.endless;

  List<TrekLine> get _lines => switch (_phase) {
        _Phase.intro => _stage.intro,
        _Phase.outro => _stage.outro,
        _ => const [],
      };

  @override
  void initState() {
    super.initState();
    _battle = _newBattle();
    unawaited(
      context
          .read<SharedPreferencesCubit>()
          .getVolume()
          .then((volume) => _volume = volume),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _white = false);
    });
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (mounted && _phase == _Phase.title) _toIntro();
      }),
    );
  }

  @override
  void dispose() {
    _stopListening();
    _frame.dispose();
    super.dispose();
  }

  void _toIntro() => setState(() {
        // The tower has no story: straight to the fight.
        _phase = _tower ? _Phase.ready : _Phase.intro;
        _line = 0;
      });

  void _next() {
    if (_line < _lines.length - 1) {
      setState(() => _line++);
    } else if (_phase == _Phase.intro) {
      GameAudio.instance.play(Sfx.ready);
      setState(() => _phase = _Phase.ready);
    } else if (_phase == _Phase.outro) {
      setState(() => _phase = _Phase.results);
    }
  }

  TrackingMode get _trackingMode =>
      context.read<SharedPreferencesCubit>().state.trackingMode;

  /// Keeps the camera running between getting ready and the fight.
  final GlobalKey _cameraKey = GlobalKey();

  /// The camera window, while the camera counts: a preview to line up in
  /// while getting ready, counting once the fight is on.
  Widget _cameraWindow(EdgeInsets safe, {required bool active}) => !_closing &&
          context.watch<SharedPreferencesCubit>().state.trackingMode ==
              TrackingMode.camera
      ? Positioned.fill(
          child: CameraWindow(
            key: _cameraKey,
            corner: active ? Alignment.bottomRight : Alignment.topRight,
            topInset: 124,
            bottomInset: 8,
            child: CameraTrackerView(
              active: active,
              onDown: context.read<PushupCubit>().down,
              onUp: () => context.read<PushupCubit>().up(_volume ?? 10),
            ),
          ),
        )
      : const SizedBox.shrink();

  void _startListening() {
    if (_listening) return;
    _listening = true;
    final pushupCubit = context.read<PushupCubit>()
      ..resetAndReturnCurrentPushupSet();
    _counted = 0;
    _downSince = null;
    // The camera counts on its own; only AirPods need their stream.
    if (_trackingMode == TrackingMode.airpods) {
      context.read<AirPodsTrackerCubit>().getAirPodsMotionData();
    }
    _pushupSubscription = pushupCubit.stream.listen(_onPushupState);
    _world?.tracking = true;
  }

  /// Stops tracking, keeping the pushups of this stretch to save.
  void _stopListening() {
    if (!_listening) return;
    _listening = false;
    unawaited(_pushupSubscription?.cancel());
    _pushupSubscription = null;
    if (mounted) {
      context.read<AirPodsTrackerCubit>().stopListening();
      _sets.add(context.read<PushupCubit>().resetAndReturnCurrentPushupSet());
    }
    _world
      ?..tracking = false
      ..inPushup = false;
  }

  /// Every stretch of pushups, saved together at the end.
  final List<PushupSet> _sets = [];

  void _fight() {
    GameAudio.instance.play(Sfx.fight);
    _startListening();
    setState(() => _phase = _Phase.fight);
  }

  void _onPushupState(PushupState state) {
    _world?.inPushup = state.inPushup;
    if (state.inPushup) _downSince ??= DateTime.now();
    if (state.pushups.length > _counted) {
      _counted = state.pushups.length;
      final now = DateTime.now();
      final down = _downSince;
      final last = _lastRep;
      _lastRep = now;
      final hit = _battle.rep(
        held: down == null ? 0 : now.difference(down).inMilliseconds / 1000,
        sinceLast:
            last == null ? null : now.difference(last).inMilliseconds / 1000,
      );
      if (hit != null) {
        _damage += hit.damage;
        if (hit.combo > _bestCombo) _bestCombo = hit.combo;
        _land(hit);
      }
    }
    if (!state.inPushup) _downSince = null;
  }

  void _land(Hit hit) {
    final l = context.l10n;
    _world?.fire(
      hit,
      onLand: () {
        if (!mounted) return;
        final game = context.gameColors;
        final scheme = context.colorScheme;
        final audio = GameAudio.instance
          ..play(
            switch (hit.kind) {
              RepKind.normal => Sfx.hitNormal,
              RepKind.held => Sfx.hitHeld,
              RepKind.quick => Sfx.hitQuick,
            },
          );
        if (hit.superEffective) audio.play(Sfx.superEffective, gain: 0.8);
        if (hit.weak) audio.play(Sfx.weak);
        if (hit.critical) audio.play(Sfx.crit);
        if (hit.combo >= 2) audio.play(Sfx.combo, gain: 0.7);
        if (hit.defeated) audio.play(Sfx.defeatEnemy);
        if (hit.phase != null) audio.play(Sfx.roar);
        if (hit.note == HitNote.splash) audio.play(Sfx.splash);
        if (hit.note == HitNote.shieldBroken) audio.play(Sfx.unlock);
        if (hit.superEffective || hit.critical) {
          _freeze = 0.07;
          _flash = math.max(_flash, 0.35);
        }
        if (hit.last) {
          _slowMo = 1.4;
          _flash = 1;
        }
        final chained = hit.chained;
        if (chained != null) {
          _world?.actorFor(chained)?.hit();
          final chainAt = _anchors[chained];
          if (chainAt != null) {
            _popups.add(
              Popup(
                text: '⚡${hit.chainDamage.round()}',
                color: game.banana,
                at: chainAt + const Offset(0, 40),
              ),
            );
          }
        }
        final at = _anchors[hit.foe] ??
            Offset(_viewSize.width / 2, _viewSize.height / 3);
        _popups.add(
          Popup(
            text: '${hit.damage.round()}',
            color: hit.superEffective
                ? hit.kind.color
                : hit.weak
                    ? Color.lerp(
                        game.onGame,
                        scheme.onSurfaceVariant,
                        context.isDark ? 0.6 : 0.35,
                      )!
                    : game.onGame,
            at: at + const Offset(0, 40),
            big: hit.superEffective || hit.critical,
          ),
        );
        if (hit.critical) {
          _popups.add(
            Popup(
              text: l.criticalHit,
              color: Color.lerp(game.banana, game.onGame, 0.3)!,
              at: at + const Offset(0, 10),
            ),
          );
        }
        final noted = switch (hit.note) {
          HitNote.splash => l.noteSplash,
          HitNote.unseen => l.noteUnseen,
          HitNote.shielded => l.noteShield,
          HitNote.shieldBroken => l.noteShieldBroken,
          HitNote.mirrored => l.noteMirrored,
          HitNote.staggered => l.noteStaggered,
          HitNote.none => null,
        };
        _showBanner(
          hit.revealed
              ? l.noteRevealed
              : chained != null
                  ? l.noteChain
                  : noted ??
                      (hit.superEffective
                          ? l.superEffective
                          : hit.weak
                              ? l.notEffective
                              : hit.kind.label(l)),
          hit.note == HitNote.shieldBroken || hit.note == HitNote.shielded
              ? ScaleColor.blue.color
              : hit.note == HitNote.staggered
                  ? game.banana
                  : hit.superEffective
                      ? hit.kind.color
                      : null,
        );
        final phase = hit.phase;
        if (phase != null) {
          _world?.recolor(hit.foe);
          final line = _stage.phaseLines[phase - 1];
          _taunt = line.$2(l);
          _tauntTime = 3.5;
        }
        setState(() {});
        if (_battle.waveCleared) unawaited(_onWaveCleared());
      },
    );
  }

  void _showBanner(String text, Color? color, {double seconds = 1.2}) {
    _banner = text;
    _bannerColor = color;
    _bannerTime = seconds;
  }

  Future<void> _onWaveCleared() async {
    if (_phase != _Phase.fight) return;
    _stopListening();
    if (_battle.won) {
      GameAudio.instance.play(Sfx.defeatEnemy);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      GameAudio.instance.play(Sfx.victory);
      await _claimRewards();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.outro;
        _line = 0;
      });
    } else {
      GameAudio.instance.play(Sfx.waveClear);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      GameAudio.instance.play(Sfx.rest);
      _battle.rest();
      setState(() {
        _phase = _Phase.rest;
        _restLeft = restSeconds.toDouble();
        _offer = _battle.offerBoons();
        _picked = null;
      });
    }
  }

  /// Leaves the tower between floors, keeping what the climb earned.
  void _stopClimb() {
    if (_phase != _Phase.rest) return;
    GameAudio.instance.play(Sfx.victory);
    unawaited(
      _claimTower().then((_) {
        if (mounted) setState(() => _phase = _Phase.results);
      }),
    );
  }

  void _pick(Boon boon) {
    if (_picked != null) return;
    GameAudio.instance.play(Sfx.equip);
    _battle.take(boon);
    setState(() => _picked = boon);
  }

  void _endRest() {
    if (_phase != _Phase.rest) return;
    // Out of time (or straight on) without picking: the first one.
    if (_picked == null && _offer.isNotEmpty) _battle.take(_offer.first);
    _battle.nextWave();
    _world?.spawn(_battle.foes);
    _fight();
  }

  void _knockOut() {
    GameAudio.instance.play(Sfx.defeat, gain: 1.4);
    _stopListening();
    if (_tower) {
      // The climb ends here: what it earned, and how high it got.
      unawaited(
        _claimTower().then((_) {
          if (mounted) setState(() => _phase = _Phase.results);
        }),
      );
      return;
    }
    setState(() => _phase = _Phase.knockedOut);
  }

  /// A fresh battle at the difficulty picked on the map.
  Battle _newBattle() {
    final trek = context.read<GameInventoryCubit>().state.inventory.trek;
    final difficulty = difficultyOf(trek);

    return _tower
        ? Battle.tower(trek, difficulty: difficulty)
        : Battle(_stage, trek, difficulty: difficulty);
  }

  /// The tower's rewards: bananas and XP per floor, and the bests.
  Future<void> _claimTower() async {
    final inventoryCubit = context.read<GameInventoryCubit>();
    final dbCubit = context.read<DBCubit>();
    await inventoryCubit.fetchInventory();
    final inventory = inventoryCubit.state.inventory;
    final floor = _battle.wave;
    final bestBefore = inventory.trek.towerBest;
    final xp = _battle.earnedXp + _battle.clearXp;
    final (gained, levels) = inventory.trek.gainXp(xp);
    final bananas =
        ((_battle.reps + floor * 15) * _battle.difficulty.rewards).round();
    await inventoryCubit.updateInventory(
      inventory.copyWith(
        bananas: inventory.bananas + bananas,
        trek: gained.climbed(floor, towerWeekOf(DateTime.now())),
      ),
    );
    for (final set in _sets) {
      if (set.pushups.isNotEmpty) await dbCubit.writeNewPushupsetToDB(set);
    }
    _sets.clear();
    _reward = TrekReward(
      xp: xp,
      levelsGained: levels,
      stars: 0,
      bananas: bananas,
      loot: null,
      adopted: false,
      pushups: _battle.reps,
      damage: _damage.round(),
      bestCombo: _bestCombo,
      floor: floor,
      bestFloor: bestBefore,
    );
  }

  void _retry() {
    final xp = _battle.xp;
    _battle = _newBattle()..xp = xp;
    _world?.spawn(_battle.foes);
    setState(() => _phase = _Phase.ready);
  }

  Future<void> _claimRewards() async {
    final inventoryCubit = context.read<GameInventoryCubit>();
    final dbCubit = context.read<DBCubit>();
    await inventoryCubit.fetchInventory();
    final inventory = inventoryCubit.state.inventory;
    final first = !inventory.trek.cleared(_stage.id);
    final xp = _battle.earnedXp + _battle.clearXp;
    final (gained, levels) = inventory.trek.gainXp(xp);
    final progress = gained.clear(_stage.id, _battle.stars);
    // He needs a free spot on the island; if it was full he joins at the
    // next boss win once there's room.
    final adopt =
        _stage.boss && inventory.komoToCome && inventory.hasRoomForMonkey;
    final bananas =
        ((_battle.reps + (first ? 50 : 10)) * _battle.difficulty.rewards)
            .round();
    await inventoryCubit.updateInventory(
      inventory.copyWith(
        bananas: inventory.bananas + bananas,
        trek: progress,
        ownedCosmetics: [
          ...inventory.ownedCosmetics,
          if (first && !inventory.owns(_stage.loot)) _stage.loot,
          if (adopt) ...['fur.jade', 'pattern.scales', 'hat.lizardcrown'],
        ],
        monkeys: [
          ...inventory.monkeys,
          if (adopt)
            AdoptableMonkey(name: 'King Komo', look: MonkeyLook.kingKomo),
        ],
      ),
    );
    for (final set in _sets) {
      if (set.pushups.isNotEmpty) {
        await dbCubit.writeNewPushupsetToDB(set);
      }
    }
    _sets.clear();
    final prefs = SharedPreferencesProvider();
    final bestComboBefore =
        await prefs.getSharedPrefInt(SharedPreferencesKey.trekBestCombo) ?? 0;
    if (_bestCombo > bestComboBefore) {
      await prefs.writeIntToSharedPrefs(
        SharedPreferencesKey.trekBestCombo,
        value: _bestCombo,
      );
    }
    _reward = TrekReward(
      xp: xp,
      levelsGained: levels,
      stars: _battle.stars,
      bananas: bananas,
      loot: first ? _stage.loot : null,
      adopted: adopt,
      pushups: _battle.reps,
      damage: _damage.round(),
      bestCombo: _bestCombo,
      bestComboBefore: bestComboBefore,
      goals: [for (final goal in _stage.goals) (goal, _battle.met(goal))],
    );
  }

  Future<void> _leave() => oneMove(() async {
        _stopListening();
        GameAudio.instance.play(Sfx.whoosh);
        // The camera shuts down first, while this screen is still up.
        setState(() {
          _white = true;
          _closing = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!popIfOnTop() && mounted) {
          setState(() {
            _white = false;
            _closing = false;
          });
        }
      });

  void _populate(Scene scene) {
    final inventory = context.read<GameInventoryCubit>().state.inventory;
    final world = _world = TrekWorld(
      _stage,
      look: inventory.monkeys.first.look,
    )..spawn(_battle.foes);
    final (_, horizon) = skyFor(_stage.location);
    final dark = _stage.location == ChallengeLocation.throne ||
        _stage.location == ChallengeLocation.swamp;
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.4, -1, -0.5),
        intensity: dark ? 2.2 : 3.2,
        color: dark ? vm.Vector3(0.85, 0.9, 1) : vm.Vector3(1, 0.97, 0.92),
        castsShadow: true,
        shadowSoftness: 0.3,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        colorGradingEnabled: true,
        saturation: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
        fogEnabled: true,
        fogMode: FogMode.linear,
        fogColor: linearColor(horizon).xyz,
        fogStart: 14,
        fogEnd: 55,
      )
      ..add(world.root);
  }

  void _tick(double deltaSeconds) {
    final world = _world;
    if (world == null) return;
    final speaking = _phase == _Phase.intro || _phase == _Phase.outro;
    final speaker = speaking && _line < _lines.length ? _lines[_line].$1 : null;
    aimGorillasAtCameraWindow(_lastCamera, _viewSize);
    world.location.carlos.talking = speaker == Character.carlos;
    world.location.guest.talking = speaker == Character.coco;
    for (final foe in _battle.foes) {
      world.actorFor(foe)?.talking = speaker != null &&
          speaker != Character.carlos &&
          speaker != Character.coco;
    }
    // A short freeze on big hits, slow motion for the winning blow.
    var dt = deltaSeconds;
    if (_freeze > 0) {
      _freeze -= deltaSeconds;
      dt = 0;
    } else if (_slowMo > 0) {
      _slowMo -= deltaSeconds;
      dt *= 0.25;
    }
    _flash = math.max(0, _flash - deltaSeconds * 3);
    world.update(dt);

    if (_phase == _Phase.fight) {
      final l = context.l10n;
      final game = context.gameColors;
      final audio = GameAudio.instance;
      final events = _battle.tick(dt, bracing: _downSince != null);
      for (final strike in events.strikes) {
        final foe = strike.foe;
        if (strike.blocked) {
          audio
            ..play(Sfx.hold)
            ..play(Sfx.superEffective, gain: 0.9);
          world.block(foe);
          _freeze = 0.12;
          _flash = 0.6;
          _showBanner(l.heavyBlocked, ScaleColor.blue.color, seconds: 1.6);
          continue;
        }
        audio
          ..play(Sfx.enemyAttack)
          ..play(Sfx.hurt, gain: strike.heavy ? 1.3 : 0.8);
        if (strike.heavy) audio.play(Sfx.roar);
        world.strike(foe);
        _shake = strike.heavy ? 1.6 : 1;
        _hurt = strike.heavy ? 1.5 : 1;
        if (strike.heavy) _showBanner(l.heavyTaken, game.red, seconds: 1.6);
        // How much it took, over Carlos at the bottom of the view.
        _popups.add(
          Popup(
            text: '-${strike.damage.round()}',
            color: const Color(0xFFE5534B),
            at: Offset(_viewSize.width * 0.42, _viewSize.height * 0.62),
            big: true,
          ),
        );
      }
      for (final _ in events.windUps) {
        audio.play(Sfx.roar, gain: 0.8);
        _chargeTick = -1;
      }
      // A tick every second of a wind-up.
      final charging = _battle.target?.charging;
      if (charging != null && charging.ceil() != _chargeTick) {
        _chargeTick = charging.ceil();
        audio.play(Sfx.tick);
      }
      for (final foe in events.dives) {
        audio.play(Sfx.splash);
        world.puff(foe, ScaleColor.blue.color);
        _showBanner(l.noteDived, ScaleColor.blue.color, seconds: 1.8);
      }
      for (final foe in events.surfaces) {
        audio.play(Sfx.splash);
        world.puff(foe, ScaleColor.blue.color);
        _showBanner(l.noteSurfaced, null);
      }
      for (final foe in events.vanishes) {
        audio.play(Sfx.whoosh);
        world.puff(foe, game.purple);
        _showBanner(l.noteVanished, game.purple, seconds: 1.8);
      }
      for (final foe in events.reveals) {
        audio.play(Sfx.pop);
        world.puff(foe, game.purple);
      }
      if (events.heals.isNotEmpty) {
        audio.play(Sfx.star);
        world.heal(_battle.foes);
        _showBanner(l.noteHealed, game.leaf);
      }
      for (final foe in events.colorShifts) {
        audio.play(Sfx.pop);
        world.recolor(foe);
        _showBanner(context.l10n.enemyColourChanges, foe.color.color);
      }
      if (_battle.lost) _knockOut();
    }
    if (_phase == _Phase.rest) {
      _restLeft -= deltaSeconds;
      if (_restLeft <= 0) _endRest();
    }

    _shake = math.max(0, _shake - deltaSeconds * 2.5);
    _hurt = math.max(0, _hurt - deltaSeconds * 2);
    _bannerTime = math.max(0, _bannerTime - deltaSeconds);
    _tauntTime = math.max(0, _tauntTime - deltaSeconds);
    for (final popup in [..._popups]) {
      popup.age += deltaSeconds / 1.1;
      if (popup.age >= 1) _popups.remove(popup);
    }
    _frame.value++;
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final enemies = vm.Vector3(0, 0.55, -2.4);
    vm.Vector3 target;
    vm.Vector3 position;
    switch (_phase) {
      case _Phase.title:
        target = enemies;
        position =
            vm.Vector3(math.sin(t * 0.3) * 2, 2.8 - math.min(1, t / 3), 7.5);
      case _Phase.intro || _Phase.outro:
        // Close on whoever speaks: the reptiles, or over Carlos's shoulder.
        final speaker = _line < _lines.length ? _lines[_line].$1 : null;
        if (speaker == Character.carlos || speaker == Character.coco) {
          target = vm.Vector3(-0.4, 0.7, 0.8);
          position = vm.Vector3(2.7, 1.7, -2.5);
        } else {
          target = enemies + vm.Vector3(0, 0.2, 0);
          position = vm.Vector3(1.8, 1.9, 2.4);
        }
      case _Phase.rest:
        target = vm.Vector3(0, 0.6, 0.6);
        position = vm.Vector3(
          math.sin(t * 0.2) * 4.6,
          2.2,
          0.6 + math.cos(t * 0.2) * 4.6,
        );
      case _:
        // Over Carlos's shoulder at the enemies, held like a phone.
        final sway = math.sin(t * 0.9) * 0.15 + math.sin(t * 2.3) * 0.04;
        target = vm.Vector3(0.25, 0.5, -1.6);
        position = vm.Vector3(1.6 + sway, 3.3 + math.sin(t * 1.7) * 0.04, 4.6);
    }
    // Eased by time, not frames, so slow devices don't lag behind.
    final dt = _lastCameraTime == null ? 0.0 : t - _lastCameraTime!;
    _lastCameraTime = t;
    final ease = _phase == _Phase.title ? 1.0 : 1 - math.exp(-dt * 4);
    _cameraTarget += (target - _cameraTarget) * ease;
    _cameraPosition += (position - _cameraPosition) * ease;
    final shake = vm.Vector3(
      math.sin(t * 60) * 0.04 * _shake,
      math.cos(t * 50) * 0.03 * _shake,
      0,
    );

    final camera = PerspectiveCamera(
      fovRadiansY: 42 * vm.degrees2Radians,
      position: _cameraPosition + shake,
      target: _cameraTarget.clone(),
    );
    _lastCamera = camera;
    // Pin the health bars with the camera this frame renders with.
    final world = _world;
    if (world != null) {
      for (final foe in _battle.foes) {
        final at = camera.worldToScreen(world.barAnchor(foe), _viewSize);
        if (at != null) _anchors[foe] = at;
      }
    }

    return camera;
  }

  @override
  Widget build(BuildContext context) {
    MusicScope.set(
      context,
      switch (_phase) {
        _Phase.ready ||
        _Phase.fight ||
        _Phase.rest =>
          trekMusic(_stage.location, boss: _stage.boss),
        _Phase.results => MusicTrack.victory,
        _Phase.knockedOut => MusicTrack.defeat,
        _ => MusicTrack.story,
      },
    );
    final (top, bottom) = skyFor(_stage.location);

    return BlocListener<AirPodsTrackerCubit, AirPodsTrackerState>(
      listener: (context, state) {
        if (state.isListening && _listening) {
          context.read<PushupCubit>().listenForPushupEvents(
                state.currentMotionData,
                _volume ?? 10,
              );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_leave());
        },
        child: Scaffold(
          backgroundColor: bottom,
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [top, bottom],
                      stops: const [0, 0.6],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _viewSize = constraints.biggest;

                    return SceneStage(
                      populate: _populate,
                      cameraBuilder: _camera,
                      onTick: _tick,
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: ValueListenableBuilder<int>(
                  valueListenable: _frame,
                  builder: (context, _, __) => Stack(children: _overlay()),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _white ? 1 : 0,
                    duration: const Duration(milliseconds: 450),
                    // The same white the jungle fades through.
                    child: ColoredBox(color: context.gameColors.flash),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _overlay() {
    final l = context.l10n;
    final safe = MediaQuery.paddingOf(context);
    final close = Positioned(
      top: safe.top + 8,
      left: 16,
      child: _GlassButton(icon: CarbonIcons.close, onPressed: _leave),
    );
    final battling = _phase == _Phase.fight || _phase == _Phase.ready;

    return [
      if (_flash > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.5 * _flash),
            ),
          ),
        ),
      if (_hurt > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    context.gameColors.red.withValues(alpha: 0.45 * _hurt),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (battling) ...[
        for (final foe in _battle.foes)
          if (foe.alive && _anchors[foe] != null)
            Positioned(
              left: _anchors[foe]!.dx - 56,
              top: _anchors[foe]!.dy - 48,
              child: FoeBar(foe: foe, targeted: foe == _battle.target),
            ),
        Positioned(
          top: safe.top + 8,
          left: 72,
          right: 16,
          child: PlayerBar(
            hp: _battle.hp,
            maxHp: _battle.maxHp,
            level: _battle.stats.level,
            wave: _battle.wave + 1,
            // The tower counts floors, not waves.
            waves: _tower ? 0 : _stage.waves.length,
            shake: _shake,
          ),
        ),
        if (_battle.target case final target?)
          Positioned(
            top: safe.top + 74,
            left: 24,
            right: 24,
            child: Center(
              child: target.charging == null
                  ? WeaknessHint(foe: target)
                  : HeavyAlert(
                      left: target.charging!,
                      total: target.difficulty.windUp,
                      bracing: _downSince != null,
                    ),
            ),
          ),
      ],
      if (_tauntTime > 0 && _taunt != null)
        Positioned(
          top: safe.top + 120,
          left: 24,
          right: 24,
          child: Center(child: SpeechBubble(_taunt!, key: ValueKey(_taunt))),
        ),
      PopupLayer(popups: _popups),
      if (_bannerTime > 0 && _banner != null && _phase == _Phase.fight)
        Positioned(
          left: 0,
          right: 0,
          top: _viewSize.height * 0.52,
          child: Opacity(
            opacity: math.min(1, _bannerTime * 3),
            child: Text(
              _banner!,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                color: _bannerColor ?? context.gameColors.onGame,
                shadows: [
                  Shadow(
                    color: context.colorScheme.shadow
                        .withValues(alpha: context.isDark ? 0.6 : 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ..._phaseOverlay(l, safe, close),
    ];
  }

  List<Widget> _phaseOverlay(S l, EdgeInsets safe, Widget close) {
    switch (_phase) {
      case _Phase.title:
        return [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toIntro,
              child: Center(
                child: _TitleCard(
                  number: _stage.number,
                  title: _stage.title(l),
                  emoji: _stage.emoji,
                ),
              ),
            ),
          ),
        ];
      case _Phase.intro || _Phase.outro:
        return [
          close,
          Positioned(
            top: safe.top + 8,
            right: 16,
            child: _GlassButton(
              icon: CarbonIcons.skip_forward,
              label: l.questSkip,
              onPressed: () => setState(() {
                _phase = _phase == _Phase.intro ? _Phase.ready : _Phase.results;
              }),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: safe.bottom + 20,
            child: DialogBox(line: _lines[_line], onNext: _next),
          ),
        ];
      case _Phase.ready:
        return [
          close,
          Positioned(
            left: 16,
            right: 16,
            bottom: safe.bottom + 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TrackingModePicker(onDark: true),
                const SizedBox(height: 12),
                PillButton(
                  label: l.trekStartFight,
                  icon: CarbonIcons.lightning,
                  color: context.gameColors.red,
                  onPressed: _fight,
                ),
              ],
            ),
          ),
          _cameraWindow(safe, active: false),
        ];
      case _Phase.fight:
        return [
          close,
          Positioned(
            left: 16,
            bottom: safe.bottom + 24,
            child: RepMeter(
              holding: _downSince == null
                  ? 0
                  : DateTime.now().difference(_downSince!).inMilliseconds /
                      1000,
              combo: _battle.combo,
              reps: _battle.reps,
            ),
          ),
          _cameraWindow(safe, active: true),
        ];
      case _Phase.rest:
        return [
          Positioned.fill(
            child: RestPanel(
              secondsLeft: _restLeft,
              hp: _battle.hp,
              maxHp: _battle.maxHp,
              nextWave: _battle.upcoming,
              onReady: _endRest,
              offer: _offer,
              picked: _picked,
              onPick: _pick,
              onStop: _tower ? _stopClimb : null,
            ),
          ),
        ];
      case _Phase.results:
        return [
          Positioned.fill(
            child: _tower
                ? TowerResult(reward: _reward, onDone: _leave)
                : TrekResult(
                    stage: _stage,
                    reward: _reward,
                    onDone: _leave,
                  ),
          ),
        ];
      case _Phase.knockedOut:
        return [
          Positioned.fill(
            child: KnockedOutPanel(onRetry: _retry, onLeave: _leave),
          ),
        ];
    }
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({
    required this.number,
    required this.title,
    required this.emoji,
  });

  final int number;
  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: context.colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(PBRadius.pill),
                boxShadow: context.cardShadow,
              ),
              child: Text(
                // The tower has no stage number.
                number < 1
                    ? context.l10n.trekTitle
                    : '${context.l10n.trekTitle} · '
                        '${context.l10n.trekStageNumber(number)}',
                style: context.textTheme.titleSmall?.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PBSpace.xxl),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.displaySmall?.copyWith(
                  fontSize: 38,
                  color: context.gameColors.onGame,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: context.colorScheme.shadow.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onPressed, this.label});

  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.cardShadow,
        ),
        child: Material(
          color: context.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(PBRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(PBRadius.pill),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: label == null ? 12 : 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: context.colorScheme.onSurface, size: 22),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: context.textTheme.titleSmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
