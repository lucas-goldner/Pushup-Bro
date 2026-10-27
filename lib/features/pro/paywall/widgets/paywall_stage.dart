import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// How long each scene of the stage plays.
const kPaywallSceneDuration = Duration(milliseconds: 2800);
const _kSceneSeconds = 2.8;
const _kStageHeight = 300.0;

/// The paywall's stage: one little scene per [ProFeature], with story-like
/// progress bars on top and a caption pill at the bottom. Tapping skips to
/// the next scene.
///
/// [progress] runs from 0 to 1 over [kPaywallSceneDuration] for the
/// current [scene]; [loop] repeats forever and drives the idle motion.
class PaywallStage extends StatelessWidget {
  const PaywallStage({
    required this.scene,
    required this.progress,
    required this.loop,
    required this.onTap,
    super.key,
  });

  final ProFeature scene;
  final Animation<double> progress;
  final Animation<double> loop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: context.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: _kStageHeight,
          child: Semantics(
            button: true,
            label: scene.caption(context),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: KeyedSubtree(
                        key: ValueKey(scene),
                        child: _scene(scene),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    right: 14,
                    child: _Bars(scene: scene.index, progress: progress),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _Pill(
                          scene.caption(context),
                          key: ValueKey(scene),
                          height: 34,
                          fontSize: 14,
                          color: scheme.surface.withValues(alpha: 0.94),
                          ink: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene(ProFeature scene) => switch (scene) {
        ProFeature.trek => _TrekScene(progress, loop),
        ProFeature.quests => _QuestScene(progress, loop),
        ProFeature.island => _IslandScene(progress, loop),
        ProFeature.wardrobe => _WardrobeScene(progress, loop),
        ProFeature.coach => _CoachScene(progress, loop),
        ProFeature.widgets => _WidgetsScene(progress, loop),
      };
}

class _Bars extends StatelessWidget {
  const _Bars({required this.scene, required this.progress});

  final int scene;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final white = context.gameColors.onGame;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => Row(
        children: [
          for (var i = 0; i < ProFeature.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: white.withValues(alpha: 0.45),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: i < scene
                            ? 1
                            : i == scene
                                ? progress.value
                                : 0,
                        child: ColoredBox(color: white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Seconds into the current scene.
double _seconds(Animation<double> progress) => progress.value * _kSceneSeconds;

/// Pops [child] in (fade and grow) [delay] seconds into the scene.
class _Pop extends StatelessWidget {
  const _Pop(this.progress, {required this.child, this.delay = 0});

  final Animation<double> progress;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: progress,
        child: child,
        builder: (context, child) {
          final x = Curves.easeOutCubic.transform(
            ((_seconds(progress) - delay) / 0.5).clamp(0.0, 1.0),
          );

          return Opacity(
            opacity: x,
            child: Transform.scale(scale: 0.85 + 0.15 * x, child: child),
          );
        },
      );
}

/// Bobs [child] up and down by [amplitude], [speed] times per loop.
class _Bob extends StatelessWidget {
  const _Bob(
    this.loop, {
    required this.child,
    this.amplitude = 8,
    this.speed = 2,
  });

  final Animation<double> loop;
  final double amplitude;
  final int speed;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: loop,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            amplitude * (1 - math.cos(loop.value * speed * 2 * math.pi)) / 2,
          ),
          child: child,
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(
    this.label, {
    required this.color,
    required this.ink,
    this.height = 30,
    this.fontSize = 13,
    super.key,
  });

  final String label;
  final Color color;
  final Color ink;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: PBSpace.md + 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.cardShadow,
        ),
        // Centred vertically but only as wide as the label, so pills in a
        // Wrap sit side by side instead of stretching across the stage.
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium
                ?.copyWith(fontSize: fontSize, color: ink),
          ),
        ),
      );
}

/// A soft white card floating over a scene.
BoxDecoration _floating(BuildContext context, {double radius = 16}) =>
    BoxDecoration(
      color: context.colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: context.cardShadow,
    );

/// Carlos fights King Komo: Komo's health drains as damage pops up.
class _TrekScene extends StatelessWidget {
  const _TrekScene(this.progress, this.loop);

  final Animation<double> progress;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [game.leaf, game.jungleDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.85,
                child:
                    Assets.images.trek.landmarkThroneOfScales.image(width: 230),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 38,
            child: _Pop(
              progress,
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: PBSpace.md,
                  vertical: PBSpace.sm,
                ),
                decoration: _floating(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.charKomo,
                      style:
                          context.textTheme.labelSmall?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: AnimatedBuilder(
                            animation: progress,
                            builder: (context, _) => Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _health(progress.value),
                                child: ColoredBox(color: game.red),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 26,
            bottom: 54,
            child: _Pop(
              progress,
              delay: 0.1,
              child: Assets.images.proHeroKomo.image(height: 150),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 50,
            child: _Bob(
              loop,
              child: Assets.images.proHeroPushup.image(width: 170),
            ),
          ),
          Positioned(
            right: 80,
            top: 104,
            child: _Hit('−24', start: 0.7, progress: progress, glow: game.held),
          ),
          Positioned(
            right: 104,
            top: 128,
            child: _Hit(
              '−31',
              start: 1.8,
              progress: progress,
              glow: game.orange,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Komo's health over the scene: full, then two hits.
  static double _health(double t) {
    double lerp(double from, double to, double a, double b) =>
        from + (to - from) * ((t - a) / (b - a)).clamp(0.0, 1.0);
    if (t < 0.3) return 1;
    if (t < 0.45) return lerp(1, 0.7, 0.3, 0.45);
    if (t < 0.7) return 0.7;
    if (t < 0.85) return lerp(0.7, 0.36, 0.7, 0.85);

    return 0.36;
  }
}

/// A damage number that pops up and floats away.
class _Hit extends StatelessWidget {
  const _Hit(
    this.text, {
    required this.start,
    required this.progress,
    required this.glow,
    this.size = 28,
  });

  final String text;
  final double start;
  final Animation<double> progress;
  final Color glow;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final x = ((_seconds(progress) - start) / 1.2).clamp(0.0, 1.0);
          if (x <= 0 || x >= 1) return const SizedBox.shrink();
          final double opacity;
          final double dy;
          final double scale;
          if (x < 0.2) {
            final k = x / 0.2;
            opacity = k;
            dy = 8 * (1 - k);
            scale = 0.7 + 0.38 * k;
          } else if (x < 0.6) {
            final k = (x - 0.2) / 0.4;
            opacity = 1;
            dy = -12 * k;
            scale = 1.08 - 0.08 * k;
          } else {
            final k = (x - 0.6) / 0.4;
            opacity = 1 - k;
            dy = -12 - 14 * k;
            scale = 1;
          }

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                child: Text(
                  text,
                  style: context.textTheme.displaySmall?.copyWith(
                    fontSize: size,
                    color: context.gameColors.onGame,
                    shadows: [
                      Shadow(
                        color: glow.withValues(alpha: 0.9),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// Today's jungle quest with its timer running down.
class _QuestScene extends StatelessWidget {
  const _QuestScene(this.progress, this.loop);

  final Animation<double> progress;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;

    return Stack(
      fit: StackFit.expand,
      children: [
        Assets.images.island.jungle.image(fit: BoxFit.cover),
        Positioned(
          left: 18,
          bottom: 50,
          child: _Pop(
            progress,
            child: Assets.images.proHeroWave.image(height: 170),
          ),
        ),
        Positioned(
          right: 14,
          top: 38,
          child: _Pop(
            progress,
            delay: 0.25,
            child: Container(
              width: 170,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: _floating(context, radius: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.questDaily,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: game.jungle,
                    ),
                  ),
                  const SizedBox(height: PBSpace.sm),
                  Text(
                    context.l10n.proSceneQuestTitle,
                    style: context.textTheme.headlineSmall
                        ?.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: PBSpace.sm),
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 30,
                        child: AnimatedBuilder(
                          animation: progress,
                          builder: (context, _) => CircularProgressIndicator(
                            value: 1 - progress.value,
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                            color: game.jungle,
                            backgroundColor:
                                context.colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      ),
                      const SizedBox(width: PBSpace.sm),
                      Text(
                        context.l10n.proSceneQuestLeft,
                        style: context.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Monkey Island grows: buildings pop up on a little island.
class _IslandScene extends StatelessWidget {
  const _IslandScene(this.progress, this.loop);

  final Animation<double> progress;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final scheme = context.colorScheme;
    final l = context.l10n;
    final buildings = [
      (Assets.images.island.gym, -110.0, 92.0),
      (Assets.images.island.airport, -20.0, 106.0),
      (Assets.images.island.monkeyAdoption, 70.0, 92.0),
      (Assets.images.island.accessoriesShop, 18.0, 70.0),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(game.ice, game.onGame, 0.45)!,
            game.ice,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = constraints.maxWidth / 2;

          return Stack(
            children: [
              // The island: a beach ring around the grass.
              Positioned(
                left: center - 160,
                bottom: 40,
                child: _Bob(
                  loop,
                  amplitude: 3,
                  speed: 1,
                  child: Container(
                    width: 320,
                    height: 120,
                    decoration: BoxDecoration(
                      color: game.sand,
                      borderRadius:
                          const BorderRadius.all(Radius.elliptical(160, 60)),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 280,
                      height: 96,
                      decoration: BoxDecoration(
                        color: game.grass,
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(140, 48)),
                      ),
                    ),
                  ),
                ),
              ),
              for (final (i, (image, dx, bottom)) in buildings.indexed)
                Positioned(
                  left: center + dx - 45,
                  bottom: bottom,
                  child: _Pop(
                    progress,
                    delay: 0.2 + 0.2 * i,
                    child: image.image(width: 90),
                  ),
                ),
              Positioned(
                left: 14,
                top: 34,
                child: _Pop(
                  progress,
                  delay: 0.2,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.only(left: 6, right: 14),
                    decoration: _floating(context, radius: PBRadius.pill),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Assets.images.island.banana.image(width: 26),
                        const SizedBox(width: 4),
                        Text(
                          '+120',
                          style: context.textTheme.labelLarge
                              ?.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 78,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (i, label) in [
                      l.buildingGym,
                      l.buildingAirport,
                      l.buildingAdoption,
                      l.islandShop,
                    ].indexed)
                      _Pop(
                        progress,
                        delay: 0.5 + 0.2 * i,
                        child: _Pill(
                          label,
                          color: scheme.surface.withValues(alpha: 0.94),
                          ink: scheme.onSurface,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Carlos dressed up, with what he wears popping up around him.
class _WardrobeScene extends StatelessWidget {
  const _WardrobeScene(this.progress, this.loop);

  final Animation<double> progress;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l = context.l10n;
    Widget tag(String label, double delay, {bool dark = false}) => _Pop(
          progress,
          delay: delay,
          child: _Pill(
            label,
            color: dark ? scheme.primary : scheme.surface,
            ink: dark ? scheme.onPrimary : scheme.onSurface,
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 0.9,
          colors: [scheme.surface, scheme.secondaryContainer],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 46,
            child: Center(
              child: _Pop(
                progress,
                child: _Bob(
                  loop,
                  amplitude: 4,
                  child: Assets.images.proHeroDance.image(height: 200),
                ),
              ),
            ),
          ),
          Positioned(left: 20, top: 54, child: tag(l.cosHatCrown, 0.3)),
          Positioned(right: 22, top: 84, child: tag(l.cosOutfitCape, 0.6)),
          Positioned(left: 26, top: 150, child: tag(l.cosEyesShades, 0.9)),
          Positioned(
            right: 26,
            top: 166,
            child: tag(l.proSceneFurs, 1.2, dark: true),
          ),
        ],
      ),
    );
  }
}

/// The camera coach tracking Carlos's pushups with a pose skeleton.
class _CoachScene extends StatelessWidget {
  const _CoachScene(this.progress, this.loop);

  final Animation<double> progress;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            game.jungleDeep,
            Color.lerp(game.jungleDeep, scheme.shadow, 0.45)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Center(
              child: _Bob(
                loop,
                speed: 1,
                child: Assets.images.proHeroPushup.image(width: 220),
              ),
            ),
          ),
          Positioned.fill(
            child: _Bob(
              loop,
              speed: 1,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => CustomPaint(
                  painter: _SkeletonPainter(
                    // Green on a good rep, blue while holding.
                    color: Color.lerp(
                      game.leaf,
                      game.held,
                      (math.sin(progress.value * 2 * math.pi) + 1) / 2,
                    )!,
                    joint: game.onGame,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 34,
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: PBSpace.md),
              decoration: BoxDecoration(
                color: scheme.scrim.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(PBRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: game.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.proFeatureCoach,
                    style: context.textTheme.labelSmall
                        ?.copyWith(fontSize: 12, color: game.onGame),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 26,
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => Text(
                '${10 + (progress.value * 3).floor().clamp(0, 2)}',
                style: context.textTheme.displayMedium
                    ?.copyWith(fontSize: 52, color: game.onGame),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.color, required this.joint});

  final Color color;
  final Color joint;

  /// The pose in the design's 350 × 300 frame.
  static const _lines = [
    [Offset(110, 170), Offset(142, 200), Offset(118, 232)],
    [Offset(142, 170), Offset(212, 190), Offset(272, 218)],
    [Offset(142, 170), Offset(110, 170)],
  ];
  static const _joints = [
    Offset(110, 170),
    Offset(142, 200),
    Offset(118, 232),
    Offset(142, 170),
    Offset(212, 190),
    Offset(272, 218),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate((size.width - 350) / 2, 0);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final line in _lines) {
      final path = Path()..moveTo(line.first.dx, line.first.dy);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, stroke);
    }
    final dot = Paint()..color = joint;
    for (final point in _joints) {
      canvas.drawCircle(point, 5, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.joint != joint;
}

/// A streak widget and new app icons.
class _WidgetsScene extends StatelessWidget {
  const _WidgetsScene(this.progress, this.loop);

  final Animation<double> progress;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final scheme = context.colorScheme;
    final icons = [
      Assets.images.appIcons.classic,
      Assets.images.appIcons.komo,
      Assets.images.appIcons.party,
      Assets.images.appIcons.midnight,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [game.ice, scheme.secondaryContainer],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 44,
            child: _Pop(
              progress,
              child: Container(
                width: 148,
                height: 148,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(CarbonIcons.fire, size: 13, color: game.orange),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.proSceneStreak,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: game.orange,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '14',
                      style: context.textTheme.displayMedium
                          ?.copyWith(color: scheme.onInverseSurface),
                    ),
                    Text(
                      context.l10n.proSceneStreakDays,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.onInverseSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 44,
            child: SizedBox(
              width: 142,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (i, icon) in icons.indexed)
                    _Pop(
                      progress,
                      delay: 0.3 + 0.2 * i,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: context.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: icon.image(width: 66, height: 66),
                        ),
                      ),
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
