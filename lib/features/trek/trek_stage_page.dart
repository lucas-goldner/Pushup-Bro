import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart' hide Material;
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/widgets/speech_bubble.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/features/quest/scene/location_world.dart';
import 'package:pushup_bro/features/quest/widgets/dialog_box.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/scene/trek_world.dart';
import 'package:pushup_bro/features/trek/widgets/battle_hud.dart';
import 'package:pushup_bro/features/trek/widgets/rest_panel.dart';
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
  });

  final int xp;
  final int levelsGained;
  final int stars;
  final int bananas;

  /// The cosmetic won, the first time only.
  final String? loot;

  /// Whether King Komo just joined the island.
  final bool adopted;
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

class _TrekStagePageState extends State<TrekStagePage> {
  _Phase _phase = _Phase.title;
  int _line = 0;
  late Battle _battle;
  TrekWorld? _world;
  Size _viewSize = Size.zero;
  double? _lastCameraTime;
  bool _white = true;

  vm.Vector3 _cameraTarget = vm.Vector3(0, 0.6, -2);
  vm.Vector3 _cameraPosition = vm.Vector3(1.5, 2.6, 7);

  // Tracking.
  StreamSubscription<PushupState>? _pushupSubscription;
  int _counted = 0;
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
  Color _bannerColor = Colors.white;
  double _bannerTime = 0;
  String? _taunt;
  double _tauntTime = 0;

  // Rest.
  double _restLeft = 0;
  TrekReward? _reward;

  TrekStage get _stage => widget.stage;

  List<TrekLine> get _lines => switch (_phase) {
        _Phase.intro => _stage.intro,
        _Phase.outro => _stage.outro,
        _ => const [],
      };

  @override
  void initState() {
    super.initState();
    _battle =
        Battle(_stage, context.read<GameInventoryCubit>().state.inventory.trek);
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
        _phase = _Phase.intro;
        _line = 0;
      });

  void _next() {
    if (_line < _lines.length - 1) {
      setState(() => _line++);
    } else if (_phase == _Phase.intro) {
      setState(() => _phase = _Phase.ready);
    } else if (_phase == _Phase.outro) {
      setState(() => _phase = _Phase.results);
    }
  }

  void _startListening() {
    if (_listening) return;
    _listening = true;
    final pushupCubit = context.read<PushupCubit>()
      ..resetAndReturnCurrentPushupSet();
    _counted = 0;
    _downSince = null;
    context.read<AirPodsTrackerCubit>().getAirPodsMotionData();
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
      if (hit != null) _land(hit);
    }
    if (!state.inPushup) _downSince = null;
  }

  void _land(Hit hit) {
    final l = context.l10n;
    _world?.fire(
      hit,
      onLand: () {
        if (!mounted) return;
        final at = _anchors[hit.foe] ??
            Offset(_viewSize.width / 2, _viewSize.height / 3);
        _popups.add(
          Popup(
            text: '${hit.damage.round()}',
            color: hit.superEffective
                ? hit.kind.color
                : hit.weak
                    ? const Color(0xFFBFC6D4)
                    : Colors.white,
            at: at + const Offset(0, 40),
            big: hit.superEffective || hit.critical,
          ),
        );
        if (hit.critical) {
          _popups.add(
            Popup(
              text: l.criticalHit,
              color: const Color(0xFFFFE27A),
              at: at + const Offset(0, 10),
            ),
          );
        }
        _showBanner(
          hit.superEffective
              ? l.superEffective
              : hit.weak
                  ? l.notEffective
                  : hit.kind.label(l),
          hit.superEffective ? hit.kind.color : Colors.white,
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

  void _showBanner(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerTime = 1.2;
  }

  Future<void> _onWaveCleared() async {
    if (_phase != _Phase.fight) return;
    _stopListening();
    if (_battle.won) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await _claimRewards();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.outro;
        _line = 0;
      });
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _battle.rest();
      setState(() {
        _phase = _Phase.rest;
        _restLeft = restSeconds.toDouble();
      });
    }
  }

  void _endRest() {
    if (_phase != _Phase.rest) return;
    _battle.nextWave();
    _world?.spawn(_battle.foes);
    _fight();
  }

  void _knockOut() {
    _stopListening();
    setState(() => _phase = _Phase.knockedOut);
  }

  void _retry() {
    final xp = _battle.xp;
    _battle =
        Battle(_stage, context.read<GameInventoryCubit>().state.inventory.trek)
          ..xp = xp;
    _world?.spawn(_battle.foes);
    setState(() => _phase = _Phase.ready);
  }

  Future<void> _claimRewards() async {
    final inventoryCubit = context.read<GameInventoryCubit>();
    final dbCubit = context.read<DBCubit>();
    await inventoryCubit.fetchInventory();
    final inventory = inventoryCubit.state.inventory;
    final first = !inventory.trek.cleared(_stage.id);
    final xp = _battle.xp + _battle.clearXp;
    final (gained, levels) = inventory.trek.gainXp(xp);
    final progress = gained.clear(_stage.id, _battle.stars);
    final adopt = first &&
        _stage.boss &&
        !inventory.monkeys.any((m) => m.look.species == MonkeyLook.lizard);
    final bananas = _battle.reps + (first ? 50 : 10);
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
    _reward = TrekReward(
      xp: xp,
      levelsGained: levels,
      stars: _battle.stars,
      bananas: bananas,
      loot: first ? _stage.loot : null,
      adopted: adopt,
    );
  }

  Future<void> _leave() async {
    _stopListening();
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop();
  }

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
    world.location.carlos.talking = speaker == Character.carlos;
    world.location.guest.talking = speaker == Character.coco;
    for (final foe in _battle.foes) {
      world.actorFor(foe)?.talking = speaker != null &&
          speaker != Character.carlos &&
          speaker != Character.coco;
    }
    world.update(deltaSeconds);

    if (_phase == _Phase.fight) {
      final events = _battle.tick(deltaSeconds);
      for (final foe in events.strikes) {
        world.strike(foe);
        _shake = 1;
        _hurt = 1;
      }
      for (final foe in events.colorShifts) {
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
                    child: const ColoredBox(color: Colors.white),
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
      if (_hurt > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE5374B).withValues(alpha: 0.45 * _hurt),
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
            waves: _stage.waves.length,
            shake: _shake,
          ),
        ),
        if (_battle.target != null)
          Positioned(
            top: safe.top + 74,
            left: 24,
            right: 24,
            child: Center(child: WeaknessHint(foe: _battle.target!)),
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
              style: pageTitleTextStyle.copyWith(
                fontSize: 26,
                color: _bannerColor,
                shadows: const [
                  Shadow(color: Color(0xAA000000), blurRadius: 10),
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
            child: Center(
              child: PillButton(
                label: l.trekStartFight,
                icon: CarbonIcons.lightning,
                color: const Color(0xFFE5534B),
                onPressed: _fight,
              ),
            ),
          ),
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
        ];
      case _Phase.rest:
        return [
          Positioned.fill(
            child: RestPanel(
              secondsLeft: _restLeft,
              hp: _battle.hp,
              maxHp: _battle.maxHp,
              nextWave: _stage.waves[_battle.wave + 1],
              onReady: _endRest,
            ),
          ),
        ];
      case _Phase.results:
        return [
          Positioned.fill(
            child: TrekResult(
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
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${context.l10n.trekTitle} · '
                '${context.l10n.trekStageNumber(number)}',
                style: buttonTextStyle.copyWith(
                  color: background2,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: pageTitleTextStyle.copyWith(
                  fontSize: 38,
                  color: Colors.white,
                  height: 1.1,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 18),
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
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? 12 : 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: background2, size: 22),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: buttonTextStyle.copyWith(
                      color: background2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
