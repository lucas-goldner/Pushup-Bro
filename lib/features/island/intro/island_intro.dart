import 'dart:async';
import 'dart:math' as math;

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

/// How long the storm blows before anyone speaks.
const _kStormLead = Duration(milliseconds: 1600);

/// One step of the intro: a story card over the scene, or a line of
/// dialog. Its beach pose is what Carlos does on the beach meanwhile.
typedef IntroBeat = ({
  IntroSet set,
  String Function(S l)? card,
  Line? line,
  int beachPose,
});

IntroBeat _card(IntroSet set, String Function(S l) text) =>
    (set: set, card: text, line: null, beachPose: 0);

IntroBeat _say(
  IntroSet set,
  Character speaker,
  String Function(S l) text, {
  int beachPose = 0,
}) =>
    (set: set, card: null, line: (speaker, text), beachPose: beachPose);

/// The intro, beat by beat: banana night in the village, the storm that
/// blows Carlos away, and waking up on the island's beach.
final List<IntroBeat> introBeats = [
  _card(IntroSet.village, (l) => l.introCardLongAgo),
  _say(IntroSet.village, Character.gus, (l) => l.introGus1),
  _say(IntroSet.village, Character.carlos, (l) => l.introCarlos1),
  _say(IntroSet.village, Character.gus, (l) => l.introGus2),
  _say(IntroSet.village, Character.carlos, (l) => l.introCarlos2),
  _card(IntroSet.storm, (l) => l.introCardStorm),
  _say(IntroSet.storm, Character.gus, (l) => l.introGus3),
  _say(IntroSet.storm, Character.carlos, (l) => l.introCarlos3),
  _say(IntroSet.storm, Character.gus, (l) => l.introGus4),
  _card(IntroSet.beach, (l) => l.introCardMorning),
  _say(IntroSet.beach, Character.coco, (l) => l.introCoco1),
  _say(IntroSet.beach, Character.carlos, (l) => l.introCarlos4, beachPose: 1),
  _say(IntroSet.beach, Character.coco, (l) => l.introCoco2, beachPose: 1),
  _say(IntroSet.beach, Character.coco, (l) => l.introCoco3, beachPose: 2),
  _say(IntroSet.beach, Character.carlos, (l) => l.introCarlos5, beachPose: 3),
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

  @override
  void initState() {
    super.initState();
    _beat = widget.startAt;
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
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
    if (beat.set == IntroSet.storm) _lightning(delta);
    _world?.beachPose = beat.beachPose;
    // "CARLOOOS!": off he goes.
    if (beat.set == IntroSet.storm &&
        beat.line?.$1 == Character.gus &&
        _beat == introBeats.lastIndexWhere((b) => b.set == IntroSet.storm)) {
      _world?.blowAway(_setTime);
    }
    setState(() {});
  }

  /// Flashes at set moments in the storm, with a rumble.
  void _lightning(double delta) {
    for (final at in const [0.3, 1.9, 2.5, 4.4]) {
      if (_setTime >= at && _thunder.add(at)) {
        _flash = _reduceMotion ? 0.35 : 1;
        GameAudio.instance.play(Sfx.roar, gain: 0.5);
      }
    }
    _flash = math.max(0, _flash - delta * 3.5);
  }

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
            vm.Vector3(drift, 2.4, 7.2 - _setTime * 0.25),
            vm.Vector3(0, 0.6, -1.2),
          );
        }
        if (beat.line?.$1 == Character.gus) {
          // From the fire's side, so we see his face.
          final gus = world.gus.root.position;
          final front = (IntroWorld.fire - gus)
            ..y = 0
            ..normalize();
          final side = vm.Vector3(front.z, 0, -front.x);
          return (
            gus + front * 3.0 + side * (0.8 + drift) + vm.Vector3(0, 1.2, 0),
            gus + vm.Vector3(0, 0.75, 0),
          );
        }
        final carlos = world.carlosHead;
        return (
          carlos + vm.Vector3(1.3 + drift, 0.75, 2.9),
          carlos + vm.Vector3(-0.3, -0.2, 0),
        );
      case IntroSet.storm:
        // Watch him go up, with a shudder in the wind.
        final shake = _reduceMotion
            ? vm.Vector3.zero()
            : vm.Vector3(
                math.sin(_time * 31) * 0.04,
                math.sin(_time * 23) * 0.03,
                0,
              );
        final carlos = world.carlos.root.position;
        final follow = vm.Vector3(
          carlos.x.clamp(-1, 3),
          (carlos.y + 0.6).clamp(0.6, 4.5),
          carlos.z,
        );
        return (
          vm.Vector3(0.6, 1.8 + follow.y * 0.4, 6.4) + shake,
          follow,
        );
      case IntroSet.beach:
        if (beat.card != null) {
          // High over the beach, sinking down to him.
          final sink = math.min(1, _setTime / 3);
          return (
            vm.Vector3(-0.6, 4.2 - sink * 1.6, 7.2 - sink * 1.4),
            IntroWorld.carlosBeach.clone(),
          );
        }
        final mid = (IntroWorld.carlosBeach + IntroWorld.cocoBeach) * 0.5;
        final speaker = beat.line?.$1;
        final lean = speaker == Character.coco ? 0.35 : -0.25;
        return (
          mid + vm.Vector3(lean + drift * 0.5, 1.35, 3.9),
          mid + vm.Vector3(lean * 0.5, 0.35, 0),
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
    // The storm's speakers wait for the wind to pick up first.
    final speaking = line != null &&
        (!storm || _setTime > _kStormLead.inMilliseconds / 1000);

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
          if (storm) ...[
            IgnorePointer(
              child: ColoredBox(
                color: const Color(0xFF0A1020).withValues(alpha: 0.35),
              ),
            ),
            if (!_reduceMotion)
              IgnorePointer(
                child: CustomPaint(painter: _RainPainter(_time)),
              ),
            IgnorePointer(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: _flash * 0.75),
              ),
            ),
          ],
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
            child: ColoredBox(
              color: Colors.black.withValues(alpha: _black.clamp(0, 1)),
            ),
          ),
          IgnorePointer(
            child: ColoredBox(
              color: context.gameColors.onGame.withValues(alpha: _white),
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

/// Slanted rain streaks blowing across the screen.
class _RainPainter extends CustomPainter {
  _RainPainter(this.time);

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final random = math.Random(3);
    for (var i = 0; i < 140; i++) {
      final speed = 900 + random.nextDouble() * 500;
      final x0 = random.nextDouble() * (size.width + 200);
      final y0 = random.nextDouble() * size.height;
      final y = (y0 + time * speed) % (size.height + 40) - 20;
      final x = (x0 - time * speed * 0.35) % (size.width + 200) - 100;
      canvas.drawLine(Offset(x, y), Offset(x - 7, y + 20), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) => oldDelegate.time != time;
}
