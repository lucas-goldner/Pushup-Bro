import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/night.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/island/visit/island_visit_page.dart';
import 'package:pushup_bro/features/island/widgets/island_scene.dart';

const _kFlightDuration = Duration(milliseconds: 1700);

/// Clouds rushing past, as (x, start y, size, speed).
const _kClouds = [
  (0.12, 0.1, 90.0, 1.0),
  (0.78, 0.35, 120.0, 1.3),
  (0.4, 0.65, 70.0, 0.8),
  (0.9, 0.85, 100.0, 1.1),
  (0.2, 0.5, 60.0, 1.5),
];

/// Takes off for [uid]'s island (who goes by [name]): a short flight, then
/// the visit replaces it, so going back lands at the airport again.
Future<void> flyToIsland(
  BuildContext context, {
  required String uid,
  required String name,
}) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, _, __) => TakeOffPage(uid: uid, name: name),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

/// The flight: the little plane climbs across the sky through the clouds,
/// with a whoosh, and "Flying to Mia's island…".
class TakeOffPage extends StatefulWidget {
  const TakeOffPage({required this.uid, required this.name, super.key});

  final String uid;
  final String name;

  @override
  State<TakeOffPage> createState() => _TakeOffPageState();
}

class _TakeOffPageState extends State<TakeOffPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: _kFlightDuration,
  );

  final bool _night = isNight(DateTime.now());

  @override
  void initState() {
    super.initState();
    GameAudio.instance.play(Sfx.whoosh);
    unawaited(_fly());
  }

  Future<void> _fly() async {
    await _flight.forward();
    if (!mounted) return;
    await openIslandVisit(context, uid: widget.uid, replace: true);
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sky = islandSky(context, night: _night);
    final cloud = context.gameColors.onGame.withValues(
      alpha: _night ? 0.18 : 0.8,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sky.top, sky.horizon],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;

            return AnimatedBuilder(
              animation: _flight,
              builder: (context, _) {
                final t = _flight.value;
                final climb = Curves.easeInCubic.transform(t);
                // From low on the left up and away to the top right.
                final plane = Offset(
                  size.width * (-0.1 + 1.25 * Curves.easeIn.transform(t)),
                  size.height * (0.78 - 0.7 * climb),
                );

                return Stack(
                  children: [
                    for (final (x, y, cloudSize, speed) in _kClouds)
                      Positioned(
                        left: size.width * x - cloudSize / 2,
                        top: size.height * ((y + t * speed) % 1.2) -
                            cloudSize / 2,
                        child: _Cloud(size: cloudSize, color: cloud),
                      ),
                    Positioned(
                      left: plane.dx - 36,
                      top: plane.dy - 36,
                      child: Transform.rotate(
                        // The icon points up; tilt it along the climb.
                        angle: math.pi / 2 - 0.5 - 0.3 * climb,
                        child: Icon(
                          CarbonIcons.plane,
                          size: 72,
                          color: context.gameColors.red,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(PBSpace.xxl),
                          child: Opacity(
                            opacity: (t * 4).clamp(0, 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PBSpace.xl,
                                vertical: PBSpace.md,
                              ),
                              decoration: BoxDecoration(
                                color: context.colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(PBRadius.pill),
                                boxShadow: context.cardShadow,
                              ),
                              child: Text(
                                context.l10n.airportFlyingTo(widget.name),
                                textAlign: TextAlign.center,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A soft cloud of three puffs.
class _Cloud extends StatelessWidget {
  const _Cloud({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget puff(double scale) => Container(
          width: size * scale,
          height: size * scale,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );

    return SizedBox(
      width: size * 1.6,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(left: 0, bottom: 0, child: puff(0.55)),
          Positioned(left: size * 0.35, bottom: 0, child: puff(0.8)),
          Positioned(right: 0, bottom: 0, child: puff(0.6)),
        ],
      ),
    );
  }
}
