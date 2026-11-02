import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scene/scene.dart' hide Material;
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/island/intro/intro_world.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/quest/widgets/dialog_box.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// How long a story card stays before the story goes on by itself.
const _kCardTime = Duration(milliseconds: 2800);

/// How long the screen takes to fade through black between places.
const _kCutTime = Duration(milliseconds: 450);

/// When the lightning strikes, in seconds into the storm.
const _kStrike = 0.5;

/// One step of the intro: a story card over the scene, or a line of
/// dialog. `step` is what happens meanwhile: the storm's stage (see
/// [IntroWorld.stormStage]) in the storm, Carlos's pose on the beach.
typedef IntroBeat = ({
  IntroSet set,
  String Function(S l)? card,
  Line? line,
  int step,
});

IntroBeat _card(IntroSet set, String Function(S l) text) =>
    (set: set, card: text, line: null, step: 0);

IntroBeat _say(
  IntroSet set,
  Character speaker,
  String Function(S l) text, {
  int step = 0,
}) =>
    (set: set, card: null, line: (speaker, text), step: step);

/// The intro, beat by beat: banana night in the village, the storm (a
/// lightning strike, the tribe running for the huts, and a tornado that
/// flings Carlos far away), and waking up on the island's beach.
final List<IntroBeat> introBeats = [
  _card(IntroSet.village, (l) => l.introCardLongAgo),
  _say(IntroSet.village, Character.gus, (l) => l.introGus1),
  _say(IntroSet.village, Character.carlos, (l) => l.introCarlos1),
  _say(IntroSet.village, Character.gus, (l) => l.introGus2),
  _say(IntroSet.village, Character.carlos, (l) => l.introCarlos2),
  _card(IntroSet.storm, (l) => l.introCardStorm),
  _say(IntroSet.storm, Character.gus, (l) => l.introGus3, step: 1),
  _say(IntroSet.storm, Character.carlos, (l) => l.introCarlos3, step: 2),
  _say(IntroSet.storm, Character.gus, (l) => l.introGusTornado, step: 3),
  _say(IntroSet.storm, Character.carlos, (l) => l.introCarlosBanana, step: 4),
  _say(IntroSet.storm, Character.gus, (l) => l.introGus4, step: 5),
  _card(IntroSet.beach, (l) => l.introCardMorning),
  _say(IntroSet.beach, Character.coco, (l) => l.introCoco1),
  _say(IntroSet.beach, Character.carlos, (l) => l.introCarlos4, step: 1),
  _say(IntroSet.beach, Character.coco, (l) => l.introCoco2, step: 1),
  _say(
    IntroSet.beach,
    Character.carlos,
    (l) => l.introCarlosWorried,
    step: 1,
  ),
  _say(IntroSet.beach, Character.coco, (l) => l.introCoco3, step: 2),
  _say(IntroSet.beach, Character.carlos, (l) => l.introCarlos5, step: 3),
];

/// The sky behind each place, top to bottom.
(Color, Color) _skyFor(IntroSet set) => switch (set) {
      // Banana night: a warm sunset.
      IntroSet.village => (const Color(0xFF4B3A8F), const Color(0xFFF7A86B)),
      IntroSet.storm => (const Color(0xFF151A26), const Color(0xFF3F4A5E)),
      // The next morning: bright and fresh.
      IntroSet.beach => (const Color(0xFF6FC0F0), const Color(0xFFFFEBC8)),
    };

/// The first visit to the island as a short film: Carlos with his tribe on
/// banana night, the storm that blows him away, and waking up on this
/// island's beach, where Coco tells him what to do. Tap to go on; [onDone]
/// fires at the end (or on Skip), with the screen white for the island to
/// fade in from.
class IslandIntro extends StatefulWidget {
  const IslandIntro({
    required this.onDone,
    this.scene = true,
    this.startAt = 0,
    this.hold = false,
    super.key,
  });

  /// Story cards wait for a tap instead of going on by themselves, for
  /// previews.
  @visibleForTesting
  final bool hold;

  final VoidCallback onDone;

  /// The beat to start at, for previews and tests.
  @visibleForTesting
  final int startAt;

  /// Off in widget tests, which have no GPU for the 3D stage.
  @visibleForTesting
  final bool scene;

  @override
  State<IslandIntro> createState() => _IslandIntroState();
}

class _IslandIntroState extends State<IslandIntro>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  IntroWorld? _world;
  int _beat = 0;

  /// Seconds since the intro started, and since the current place did.
  double _time = 0;
  double _setTime = 0;
  Duration _last = Duration.zero;

  /// When the current beat started, for the card's timer and the storm's
  /// lead.
  double _beatStart = 0;

  /// Black between places, white at the end.
  double _black = 1;
  double _white = 0;
  bool _cutting = false;
  bool _leaving = false;

  /// The lightning's flash, 0 to 1.
  double _flash = 0;
  final _thunder = <double>{};

  // A smoothed camera, so cuts between speakers glide.
  vm.Vector3 _cameraTarget = vm.Vector3(0, 0.6, -1);
  vm.Vector3 _cameraPosition = vm.Vector3(0, 2.6, 7.5);
  bool _snapCamera = true;

  IntroBeat get _current => introBeats[_beat];

  /// Ticks every frame, for the overlays (rain, flashes, fades) only.
  final ValueNotifier<double> _frame = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _beat = widget.startAt;
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _tick(Duration elapsed) {
    final delta = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _time += delta;
    _setTime += delta;
    final beat = _current;
    // Fade in from black, and out again when cutting or leaving.
    if (_leaving) {
      _white = math.min(1, _white + delta / 0.6);
      if (_white >= 1) {
        _ticker.stop();
        widget.onDone();
        return;
      }
    } else if (!_cutting) {
      _black = math.max(0, _black - delta / (_kCutTime.inMilliseconds / 1000));
    }
    if (beat.card != null &&
        !widget.hold &&
        !_cutting &&
        _time - _beatStart > _kCardTime.inMilliseconds / 1000) {
      unawaited(_next());
    }
    if (beat.set == IntroSet.storm) {
      _lightning(delta);
      _world?.stormStage = beat.step;
    } else {
      _world?.beachPose = beat.step;
    }
    // Only the overlays change every frame; the rest waits for a new beat.
    _frame.value = _time;
  }

  /// The strike (two flashes and a bang, as the bolt hits the palm), then
  /// a rumble every few seconds while the storm rages.
  void _lightning(double delta) {
    final rumble = _setTime < 2 ? -1 : ((_setTime - 2) / 4.5).floor();
    for (final at in [_kStrike, _kStrike + 0.35, 100.0 + rumble]) {
      if (_setTime >= math.min(at, _setTime) && _thunder.add(at)) {
        if (at < 100 || rumble >= 0) {
          _flash = _reduceMotion ? 0.35 : (at < 100 ? 1 : 0.6);
          if (at != _kStrike + 0.35) {
            GameAudio.instance.play(Sfx.roar, gain: at < 100 ? 0.7 : 0.4);
          }
        }
      }
    }
    _flash = math.max(0, _flash - delta * 3.5);
  }

  /// Whether the rain is pouring yet (after the strike).
  bool get _pouring => _setTime > _kStrike;

  /// Goes on to the next beat, through black when the place changes.
  Future<void> _next() async {
    if (_cutting || _leaving) return;
    if (_beat == introBeats.length - 1) {
      _leave();
      return;
    }
    final next = introBeats[_beat + 1];
    if (next.set != _current.set && next.set == IntroSet.beach) {
      _cutting = true;
      final fade = _kCutTime.inMilliseconds / 1000;
      while (_black < 1 && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        _black = math.min(1, _black + 0.016 / fade);
      }
      if (!mounted) return;
      _cutting = false;
      GameAudio.instance.play(Sfx.splash, gain: 0.6);
    }
    _go(_beat + 1);
  }

  void _go(int beat) {
    final previous = _current.set;
    setState(() {
      _beat = beat;
      _beatStart = _time;
    });
    final set = _current.set;
    if (set != previous) {
      _setTime = 0;
      _thunder.clear();
      _world?.show(set);
      _snapCamera = set == IntroSet.beach;
      if (set == IntroSet.storm) GameAudio.instance.play(Sfx.whoosh);
    }
  }

  void _leave() {
    if (_leaving) return;
    GameAudio.instance.play(Sfx.whoosh);
    setState(() => _leaving = true);
  }

  void _populate(Scene scene) {
    final look = context.read<GameInventoryCubit>().state.inventory.monkeys;
    final world = _world = IntroWorld(
      carlosLook: look.isEmpty ? const MonkeyLook() : look.first.look,
    )..show(_current.set);
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.5, -1, -0.45),
        intensity: 3.2,
        castsShadow: true,
        shadowSoftness: 0.2,
      )
      ..environmentSettings = EnvironmentSettings(
        exposure: 1.05,
        colorGradingEnabled: true,
        saturation: 1.1,
        ambientOcclusionEnabled: true,
        ambientOcclusionIntensity: 0.8,
      )
      ..add(world.root);
  }

  void _onTick(double deltaSeconds) => _world?.update(deltaSeconds, _setTime);

  /// Where the camera looks from and at for the current beat.
  (vm.Vector3 position, vm.Vector3 target) _shot() {
    final world = _world;
    final beat = _current;
    if (world == null) return (_cameraPosition, _cameraTarget);
    final drift = math.sin(_time * 0.3) * 0.25;
    switch (beat.set) {
      case IntroSet.village:
        if (beat.card != null) {
          // Establishing: the whole village round the fire.
          return (
            vm.Vector3(drift, 2.4, 7.2 - math.min(_setTime, 3) * 0.25),
            vm.Vector3(0, 0.6, -1.2),
          );
        }
        if (beat.line?.$1 == Character.gus) {
          // In front of him, the dancers behind.
          final gus = world.gus.root.position;
          return (
            gus + vm.Vector3(1.2 + drift, 1.3, 3.4),
            gus + vm.Vector3(0.2, 0.95, 0),
          );
        }
        final carlos = world.carlosHead;
        return (
          carlos + vm.Vector3(1.3 + drift, 0.75, 2.9),
          carlos + vm.Vector3(-0.3, -0.2, 0),
        );
      case IntroSet.storm:
        // A shudder in the wind.
        final shake = _reduceMotion
            ? vm.Vector3.zero()
            : vm.Vector3(
                math.sin(_time * 31) * 0.035,
                math.sin(_time * 23) * 0.025,
                0,
              );
        final carlos = world.carlos.root.position;
        final tornado = world.tornadoFoot;
        final (position, target) = switch (beat.step) {
          // The strike: the whole clearing and the palm on the right.
          0 => (vm.Vector3(-0.4, 2.6, 7.6), vm.Vector3(1.4, 1.4, -0.8)),
          // Gus shouting the tribe into the huts.
          1 => (
              IntroWorld.gusSpot + vm.Vector3(2.2, 1.6, 4.4),
              IntroWorld.gusSpot + vm.Vector3(1.6, 0.9, -1.4),
            ),
          // Over Carlos's shoulder: the tornado coming.
          2 => (
              carlos + vm.Vector3(1.6, 1.5, 2.6),
              tornado + vm.Vector3(0, 2, 0),
            ),
          // Wide: it reaches him.
          3 => (vm.Vector3(1.2, 2.2, 8.4), tornado + vm.Vector3(0, 1.8, 0)),
          // Up with him, round and round.
          4 => (
              tornado + vm.Vector3(0.4, 1.6 + carlos.y * 0.6, 6.6),
              vm.Vector3(tornado.x, carlos.y + 0.3, tornado.z),
            ),
          // Watching him fly off into the sky.
          _ => (
              vm.Vector3(-1.5, 1.6, 7.5),
              vm.Vector3(2.4, 4.2, -8),
            ),
        };
        return (position + shake, target);
      case IntroSet.beach:
        if (beat.card != null) {
          // High over the beach, sinking down to him.
          final sink = math.min(1, _setTime / 3);
          return (
            vm.Vector3(-0.6, 4.2 - sink * 1.6, 7.2 - sink * 1.4),
            IntroWorld.carlosBeach.clone(),
          );
        }
        // Both of them in the frame, leaning towards whoever speaks.
        final mid = IntroWorld.carlosBeach * 0.7 + IntroWorld.cocoBeach * 0.3;
        final speaker = beat.line?.$1;
        final lean = speaker == Character.coco ? 0.2 : -0.2;
        return (
          mid + vm.Vector3(lean + drift * 0.5, 1.7, 5.4),
          mid + vm.Vector3(lean * 0.5, 0.45, 0),
        );
    }
  }

  Duration _lastFrame = Duration.zero;

  Camera _camera(Duration elapsed) {
    final dt = ((elapsed - _lastFrame).inMicroseconds / 1e6).clamp(0.0, 0.5);
    _lastFrame = elapsed;
    final (position, target) = _shot();
    if (_snapCamera) {
      _cameraPosition = position;
      _cameraTarget = target;
      _snapCamera = false;
    } else {
      // The spring keeps cuts between speakers smooth.
      _cameraPosition = vm.Vector3(
        springTo(_cameraPosition.x, position.x, dt, 2.2),
        springTo(_cameraPosition.y, position.y, dt, 2.2),
        springTo(_cameraPosition.z, position.z, dt, 2.2),
      );
      _cameraTarget = vm.Vector3(
        springTo(_cameraTarget.x, target.x, dt, 2.6),
        springTo(_cameraTarget.y, target.y, dt, 2.6),
        springTo(_cameraTarget.z, target.z, dt, 2.6),
      );
    }

    return PerspectiveCamera(
      fovRadiansY: 38 * vm.degrees2Radians,
      position: _cameraPosition,
      target: _cameraTarget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final beat = _current;
    final (top, horizon) = _skyFor(beat.set);
    final line = beat.line;
    final card = beat.card;
    final storm = beat.set == IntroSet.storm;
    final speaking = line != null;

    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, horizon],
                stops: const [0, 0.6],
              ),
            ),
          ),
          if (widget.scene)
            SceneStage(
              populate: _populate,
              cameraBuilder: _camera,
              onTick: _onTick,
              warmUp: true,
            ),
          if (storm)
            IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _frame,
                builder: (context, time, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: const Color(0xFF0A1020)
                          .withValues(alpha: _pouring ? 0.42 : 0.3),
                    ),
                    if (!_reduceMotion)
                      CustomPaint(
                        painter: _RainPainter(time, heavy: _pouring),
                      ),
                    ColoredBox(
                      color: Colors.white.withValues(alpha: _flash * 0.75),
                    ),
                  ],
                ),
              ),
            ),
          // Letterbox bars for the film look.
          const IgnorePointer(child: _Letterbox()),
          // Tap anywhere to go on.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: card != null ? _next : null,
          ),
          if (card != null)
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: PBSpace.xl),
                  child: _StoryCard(
                    text: card(context.l10n),
                    key: ValueKey(_beat),
                  ),
                ),
              ),
            ),
          if (speaking)
            // Like the quests: pinned to the bottom, as tall as its text.
            Positioned(
              left: PBSpace.lg,
              right: PBSpace.lg,
              bottom: MediaQuery.paddingOf(context).bottom + PBSpace.xl,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DialogBox(line: line, onNext: _next),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(PBSpace.md),
                child: TextButton(
                  onPressed: _leave,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Text(context.l10n.introSkip),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: _frame,
              builder: (context, _, __) => Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black.withValues(alpha: _black.clamp(0, 1)),
                  ),
                  ColoredBox(
                    color: context.gameColors.onGame.withValues(alpha: _white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A story card: a line of narration, fading and rising in.
class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PBSpace.xl,
            vertical: PBSpace.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(PBRadius.lg),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
}

/// Thin black bars at the top and bottom, like a film.
class _Letterbox extends StatelessWidget {
  const _Letterbox();

  @override
  Widget build(BuildContext context) {
    final bar = MediaQuery.sizeOf(context).height * 0.06;

    return Column(
      children: [
        Container(height: bar, color: Colors.black),
        const Spacer(),
        Container(height: bar, color: Colors.black),
      ],
    );
  }
}

/// Slanted rain streaks blowing across the screen: a drizzle, then a
/// downpour once the lightning has struck.
class _RainPainter extends CustomPainter {
  _RainPainter(this.time, {required this.heavy});

  final double time;
  final bool heavy;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: heavy ? 0.42 : 0.3)
      ..strokeWidth = heavy ? 1.6 : 1.2
      ..strokeCap = StrokeCap.round;
    final random = math.Random(3);
    final drops = heavy ? 320 : 70;
    final slant = heavy ? 0.6 : 0.3;
    final length = heavy ? 34.0 : 18.0;
    final points = <Offset>[];
    for (var i = 0; i < drops; i++) {
      final speed = (heavy ? 1500 : 900) + random.nextDouble() * 500;
      final x0 = random.nextDouble() * (size.width + 300);
      final y0 = random.nextDouble() * size.height;
      final y = (y0 + time * speed) % (size.height + 60) - 30;
      final x = (x0 - time * speed * slant) % (size.width + 300) - 150;
      points
        ..add(Offset(x, y))
        ..add(Offset(x - length * slant, y + length));
    }
    // One draw call for all the drops.
    canvas.drawPoints(PointMode.lines, points, paint);
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.heavy != heavy;
}
