import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart' hide Material;
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/audio/music_scope.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/widgets/speech_bubble.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_tracker.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/features/quest/scene/location_world.dart';
import 'package:pushup_bro/features/quest/widgets/challenge_hud.dart';
import 'package:pushup_bro/features/quest/widgets/dialog_box.dart';
import 'package:pushup_bro/features/quest/widgets/quest_result.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// What the guests shout while Carlos does pushups.
List<String> _cheersOf(Character guest, S l) => switch (guest) {
      Character.coco => [l.cheerCoco1, l.cheerCoco2, l.cheerCoco3],
      Character.shelldon => [l.cheerShelldon1, l.cheerShelldon2],
      Character.jag => [l.cheerJag1, l.cheerJag2, l.cheerJag3],
      Character.stranger => [l.cheerStranger1, l.cheerStranger2],
      _ => [l.cheerReptile1, l.cheerReptile2, l.cheerReptile3],
    };

enum _Phase { title, intro, challenge, outro, results }

/// A jungle quest from start to finish, in one 3D location: a title card,
/// the story as a cutscene, the pushup challenge, and the ending with the
/// rewards. Pops with true when the quest was won.
class QuestPage extends StatefulWidget {
  const QuestPage({required this.quest, this.replay = false, super.key});
  static const routeName = '/quest';

  final JungleQuest quest;

  /// Already won today: no bonus this time.
  final bool replay;

  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> {
  _Phase _phase = _Phase.title;
  int _line = 0;
  LocationWorld? _world;
  Size _viewSize = Size.zero;
  Camera? _lastCamera;

  // Smoothed camera, so cuts between speakers glide.
  vm.Vector3 _cameraTarget = vm.Vector3(0, 0.8, -2);
  vm.Vector3 _cameraPosition = vm.Vector3(0, 3, 9);

  // The challenge.
  bool _started = false;
  int _pushups = 0;
  int _held = 0;
  DateTime? _downSince;
  double _holding = 0;
  double _remaining = 0;
  Timer? _clock;
  StreamSubscription<PushupState>? _pushupSubscription;
  int? _volume;

  // The ending.
  bool _won = false;
  int _bananas = 0;

  // A cheer over the guest's head.
  final ValueNotifier<Offset?> _cheerAnchor = ValueNotifier(null);
  String _cheer = '';
  double _cheerTime = 0;
  int _cheerCount = 0;

  /// Fades in out of white, and back to white when leaving.
  bool _white = true;

  JungleQuest get _quest => widget.quest;

  List<Line> get _lines => switch (_phase) {
        _Phase.intro => _quest.intro,
        _Phase.outro => _won ? _quest.win : _quest.lose,
        _ => const [],
      };

  @override
  void initState() {
    super.initState();
    final rule = _quest.rule;
    if (rule is TimedRule) _remaining = rule.seconds.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _white = false);
    });
    unawaited(
      context
          .read<SharedPreferencesCubit>()
          .getVolume()
          .then((volume) => _volume = volume),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (mounted && _phase == _Phase.title) _toIntro();
      }),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    unawaited(_pushupSubscription?.cancel());
    _cheerAnchor.dispose();
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
      _toChallenge();
    } else if (_phase == _Phase.outro) {
      setState(() => _phase = _Phase.results);
    }
  }

  void _toChallenge() {
    _world?.stageChallenge();
    setState(() => _phase = _Phase.challenge);
  }

  void _start() {
    final pushupCubit = context.read<PushupCubit>()
      ..resetAndReturnCurrentPushupSet();
    // The camera counts on its own; only AirPods need their stream.
    if (context.read<SharedPreferencesCubit>().state.trackingMode ==
        TrackingMode.airpods) {
      context.read<AirPodsTrackerCubit>().getAirPodsMotionData();
    }
    _pushupSubscription = pushupCubit.stream.listen(_onPushupState);
    _world?.tracking = true;
    setState(() => _started = true);
    final rule = _quest.rule;
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final down = _downSince;
      final before = _remaining;
      final wasHolding = _holding;
      setState(() {
        if (rule is TimedRule) {
          _remaining = math.max(0, _remaining - 0.1);
        }
        _holding = down == null
            ? 0
            : DateTime.now().difference(down).inMilliseconds / 1000;
      });
      // Tick down the last five seconds, and chime when a hold is long
      // enough.
      if (rule is TimedRule &&
          _remaining < 5 &&
          before.ceil() != _remaining.ceil()) {
        GameAudio.instance.play(Sfx.tick);
      }
      if (rule is HoldRule &&
          wasHolding < rule.seconds &&
          _holding >= rule.seconds) {
        GameAudio.instance.play(Sfx.hold);
      }
      if (rule is TimedRule && _remaining <= 0) unawaited(_finish());
    });
  }

  void _onPushupState(PushupState state) {
    _world?.inPushup = state.inPushup;
    final rule = _quest.rule;
    if (state.inPushup) {
      _downSince ??= DateTime.now();
    }
    if (state.pushups.length > _pushups) {
      final down = _downSince;
      final heldFor = down == null
          ? 0.0
          : DateTime.now().difference(down).inMilliseconds / 1000;
      setState(() {
        _pushups = state.pushups.length;
        if (rule is HoldRule && heldFor >= rule.seconds) _held++;
      });
    }
    if (!state.inPushup) _downSince = null;
    _world?.progress = (_score / rule.goal).clamp(0, 1).toDouble();
    if ((rule is TargetRule || rule is HoldRule) && _score >= rule.goal) {
      unawaited(_finish());
    }
  }

  int get _score => _quest.rule is HoldRule ? _held : _pushups;

  Future<void> _finish() async {
    if (!_started) return;
    _started = false;
    _clock?.cancel();
    unawaited(_pushupSubscription?.cancel());
    final airpods = context.read<AirPodsTrackerCubit>()..stopListening();
    final dbCubit = context.read<DBCubit>();
    final inventoryCubit = context.read<GameInventoryCubit>();
    final set = context.read<PushupCubit>().resetAndReturnCurrentPushupSet();
    _world?.tracking = false;
    _world?.inPushup = false;
    final won = _score >= _quest.rule.goal;
    final bananas = widget.replay
        ? set.pushups.length
        : _quest.reward(pushups: set.pushups.length, won: won);

    // Keep the set and the bananas even if the ending is skipped.
    if (set.pushups.isNotEmpty) await dbCubit.writeNewPushupsetToDB(set);
    await inventoryCubit.fetchInventory();
    final inventory = inventoryCubit.state.inventory;
    await inventoryCubit.updateInventory(
      inventory.copyWith(
        bananas: inventory.bananas + bananas,
        quests: won && !widget.replay
            ? inventory.quests.complete(_quest.id, DateTime.now())
            : null,
      ),
    );
    airpods.stopListening();
    if (!mounted) return;
    GameAudio.instance.play(won ? Sfx.questComplete : Sfx.defeat, gain: 1.2);
    _world
      ?..stageCutscene()
      ..guest.cheering = won;
    setState(() {
      _won = won;
      _bananas = bananas;
      _phase = _Phase.outro;
      _line = 0;
    });
  }

  Future<void> _leave() async {
    if (_started) {
      _started = false;
      _clock?.cancel();
      unawaited(_pushupSubscription?.cancel());
      context.read<AirPodsTrackerCubit>().stopListening();
      context.read<PushupCubit>().resetAndReturnCurrentPushupSet();
    }
    GameAudio.instance.play(Sfx.whoosh);
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop(_won);
  }

  void _populate(Scene scene) {
    final inventory = context.read<GameInventoryCubit>().state.inventory;
    final world = _world = LocationWorld(
      _quest.location,
      look: inventory.monkeys.first.look,
      guest: _quest.guest,
    );
    final night = _quest.location == ChallengeLocation.moonBeach;
    final (_, horizon) = skyFor(_quest.location);
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.4, -1, -0.5),
        intensity: night ? 1.6 : 3.2,
        color: night
            ? vm.Vector3(0.75, 0.8, 1)
            : _quest.location == ChallengeLocation.volcano
                ? vm.Vector3(1, 0.8, 0.65)
                : vm.Vector3(1, 1, 1),
        castsShadow: true,
        shadowSoftness: 0.3,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: night ? 1.0 : 1.05,
        colorGradingEnabled: true,
        saturation: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
        fogEnabled: true,
        fogMode: FogMode.linear,
        fogColor: linearColor(horizon).xyz,
        fogStart: 18,
        fogEnd: 70,
      )
      ..add(world.root);
  }

  void _tick(double deltaSeconds) {
    final world = _world;
    if (world == null) return;
    final speaking = _phase == _Phase.intro || _phase == _Phase.outro;
    final speaker = speaking && _line < _lines.length ? _lines[_line].$1 : null;
    world.carlos.talking = speaker == Character.carlos;
    world.guest.talking = speaker != null && speaker != Character.carlos;
    world.update(deltaSeconds);

    // Cheers while Carlos works.
    if (_phase != _Phase.challenge || !_started) {
      _cheerTime = math.min(_cheerTime, 0);
    } else {
      _cheerTime -= deltaSeconds;
      if (_cheerTime <= -2.5) {
        final cheers = _cheersOf(_quest.guest, context.l10n);
        setState(() => _cheer = cheers[_cheerCount++ % cheers.length]);
        _cheerTime = 2.2;
      }
    }
    final camera = _lastCamera;
    _cheerAnchor.value = _cheerTime > 0 && camera != null
        ? camera.worldToScreen(
            world.focusOn(_quest.guest) + vm.Vector3(0, 0.45, 0),
            _viewSize,
          )
        : null;
  }

  Camera _camera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final world = _world;
    vm.Vector3 target;
    vm.Vector3 position;
    switch (_phase) {
      case _Phase.title:
        // A slow establishing push-in.
        final push = math.min(1, t / 3).toDouble();
        target = vm.Vector3(0, 1.2, -3);
        position =
            vm.Vector3(math.sin(t * 0.2) * 1.5, 3.4 - push, 10 - push * 2);
      case _Phase.intro || _Phase.outro || _Phase.results:
        final speaker =
            _line < _lines.length ? _lines[_line].$1 : Character.carlos;
        if (world == null || _phase == _Phase.results) {
          target = vm.Vector3(0, 0.7, 0);
          position = vm.Vector3(0, 1.6, 5);
        } else {
          // Over the listener's shoulder at whoever speaks.
          final listener =
              speaker == Character.carlos ? _quest.guest : Character.carlos;
          final speakerAt = world.focusOn(speaker);
          final listenerAt = world.focusOn(listener);
          final away = vm.Vector3(
            listenerAt.x - speakerAt.x,
            0,
            listenerAt.z - speakerAt.z,
          )..normalize();
          target = speakerAt + vm.Vector3(0, -0.1, 0);
          position = listenerAt + away * 2.1 + vm.Vector3(0, 0.6, 3.2);
        }
      case _Phase.challenge:
        // Like someone filming on a phone: a slow sway and bob.
        final angle =
            0.45 + math.sin(t * 0.25) * 0.12 + math.sin(t * 1.1) * 0.02;
        target = vm.Vector3(0.45, 0.6, -0.4);
        position = target +
            vm.Vector3(
              math.sin(angle) * 5.4,
              1.6 + math.sin(t * 1.7) * 0.04,
              math.cos(angle) * 5.4,
            );
    }
    final ease = _phase == _Phase.title ? 1.0 : 0.08;
    _cameraTarget += (target - _cameraTarget) * ease;
    _cameraPosition += (position - _cameraPosition) * ease;

    return _lastCamera = PerspectiveCamera(
      fovRadiansY: 40 * vm.degrees2Radians,
      position: _cameraPosition.clone(),
      target: _cameraTarget.clone(),
    );
  }

  @override
  Widget build(BuildContext context) {
    MusicScope.set(
      context,
      switch (_phase) {
        _Phase.challenge => MusicTrack.challenge,
        _Phase.results when _won => MusicTrack.victory,
        _ => MusicTrack.story,
      },
    );
    final (top, bottom) = skyFor(_quest.location);

    return BlocListener<AirPodsTrackerCubit, AirPodsTrackerState>(
      listener: (context, state) {
        if (state.isListening && _started) {
          context.read<PushupCubit>().listenForPushupEvents(
                state.currentMotionData,
                _volume ?? 10,
              );
        }
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
              child: IgnorePointer(
                child: ValueListenableBuilder<Offset?>(
                  valueListenable: _cheerAnchor,
                  builder: (context, anchor, _) => anchor == null
                      ? const SizedBox.shrink()
                      : Stack(
                          children: [
                            Positioned(
                              left: (anchor.dx - 110)
                                  .clamp(8, _viewSize.width - 228),
                              top: anchor.dy - 70,
                              width: 220,
                              child: SpeechBubble(
                                _cheer,
                                key: ValueKey(_cheer),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            ..._overlay(),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _white ? 1 : 0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _overlay() {
    final safe = MediaQuery.paddingOf(context);
    final close = Positioned(
      top: safe.top + 8,
      left: 16,
      child: _GlassButton(icon: CarbonIcons.close, onPressed: _leave),
    );

    switch (_phase) {
      case _Phase.title:
        return [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toIntro,
              child: Center(child: _TitleCard(quest: _quest)),
            ),
          ),
        ];
      case _Phase.intro || _Phase.outro:
        final last = _line == _lines.length - 1;

        return [
          close,
          Positioned(
            top: safe.top + 8,
            right: 16,
            child: _GlassButton(
              icon: CarbonIcons.skip_forward,
              label: context.l10n.questSkip,
              onPressed: () {
                if (_phase == _Phase.intro) {
                  _toChallenge();
                } else {
                  setState(() => _phase = _Phase.results);
                }
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: safe.bottom + 20,
            child: DialogBox(
              line: _lines[_line],
              onNext: _next,
              trailing: last && _phase == _Phase.intro
                  ? PillButton(
                      label: context.l10n.questLetsDoThis,
                      icon: CarbonIcons.play_filled_alt,
                      onPressed: _toChallenge,
                    )
                  : null,
            ),
          ),
        ];
      case _Phase.challenge:
        return [
          close,
          Positioned.fill(
            child: ChallengeHud(
              quest: _quest,
              started: _started,
              pushups: _pushups,
              held: _held,
              holding: _holding,
              remaining: _remaining,
              onStart: _start,
              onFinish: _finish,
            ),
          ),
          if (context.watch<SharedPreferencesCubit>().state.trackingMode ==
              TrackingMode.camera)
            Positioned(
              right: 16,
              bottom: safe.bottom + (_started ? 96 : 150),
              width: 120,
              height: 160,
              child: CameraTrackerView(
                active: _started,
                onDown: context.read<PushupCubit>().down,
                onUp: () => context.read<PushupCubit>().up(_volume ?? 10),
              ),
            ),
        ];
      case _Phase.results:
        return [
          Positioned.fill(
            child: QuestResult(
              quest: _quest,
              won: _won,
              pushups: _pushups,
              bananas: _bananas,
              onDone: _leave,
            ),
          ),
        ];
    }
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.quest});

  final JungleQuest quest;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${quest.location.emoji}  ${quest.location.name(context.l10n)}',
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
                quest.title(context.l10n),
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
