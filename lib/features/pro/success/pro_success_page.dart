import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';
import 'package:pushup_bro/core/widgets/phone_canvas.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

const _kUnlockStart = 3.2;
const _kUnlockEvery = 0.32;
const _kBurstAt = 1.0;

/// The celebration right after buying or restoring Pro: a flash, Carlos
/// jumping in, confetti, and every Pro feature unlocking one by one.
class ProSuccessPage extends StatefulWidget {
  const ProSuccessPage({this.plan, super.key});

  /// The plan just bought; null after a restore.
  final ProPlanKind? plan;

  /// Shows the celebration over everything and waits until it's closed.
  static Future<void> show(BuildContext context, {ProPlanKind? plan}) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        PageRouteBuilder<void>(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, _, __) => ProSuccessPage(plan: plan),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  State<ProSuccessPage> createState() => _ProSuccessPageState();
}

class _ProSuccessPageState extends State<ProSuccessPage>
    with SingleTickerProviderStateMixin {
  final _timers = <Timer>[];
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _loop.repeat();
    void at(double seconds, VoidCallback cue) => _timers.add(
          Timer(Duration(milliseconds: (seconds * 1000).round()), cue),
        );
    at(_kBurstAt, () {
      GameAudio.instance.play(Sfx.levelUp);
      unawaited(HapticFeedback.heavyImpact());
    });
    at(1.5, () => GameAudio.instance.play(Sfx.star));
    for (var i = 0; i < ProFeature.values.length; i++) {
      at(_kUnlockStart + i * _kUnlockEvery + 0.25, () {
        GameAudio.instance.play(Sfx.unlock);
        unawaited(HapticFeedback.lightImpact());
      });
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _loop.dispose();
    super.dispose();
  }

  String _planLine(BuildContext context) {
    final l = context.l10n;
    return switch (widget.plan) {
      ProPlanKind.weekly => l.proSuccessWeekly,
      ProPlanKind.yearly => l.proSuccessYearly,
      ProPlanKind.lifetime => l.proSuccessLifetime,
      null => l.proSuccessRestored,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const white = PBPalette.white;

    return MotionClock(
      duration: const Duration(seconds: 9),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.55),
              radius: 1.2,
              colors: [
                Color(0xFF8DBBFF),
                Color(0xFF5E9EFF),
                Color(0xFF3D7BF5),
                Color(0xFF2A5FD6),
              ],
              stops: [0, 0.4, 0.75, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _Sunburst(spin: _loop)),
              const Positioned.fill(child: _Flash()),
              Positioned.fill(
                child: PhoneCanvas(
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: PBSpace.lg),
                      child: Column(
                        children: [
                          const SizedBox(height: PBSpace.lg),
                          const SizedBox(height: 250, child: _Hero()),
                          const Pop(at: 1.5, child: _ProPill()),
                          const SizedBox(height: PBSpace.md),
                          BlurWords(
                            l.proSuccessTitle,
                            at: 1.75,
                            stagger: 0.12,
                            textAlign: TextAlign.center,
                            accent: context.gameColors.banana,
                            style: context.textTheme.headlineLarge
                                ?.copyWith(color: white, fontSize: 34),
                          ),
                          Reveal(
                            at: 2.3,
                            offset: 8,
                            child: Padding(
                              padding: const EdgeInsets.only(top: PBSpace.xs),
                              child: Text(
                                l.proSuccessSub,
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: white.withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: PBSpace.lg),
                          const Expanded(child: _FeatureGrid()),
                          Reveal(
                            at: 5.3,
                            offset: 6,
                            child: Text(
                              _planLine(context),
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: white.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                          const SizedBox(height: PBSpace.md),
                          Reveal(
                            at: 5.5,
                            child: _Breathing(
                              child: _WhiteButton(
                                label: l.proSuccessCta,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                          const SizedBox(height: PBSpace.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(child: _Confetti()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white flash of the purchase moment.
class _Flash extends StatelessWidget {
  const _Flash();

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final t = (clock.value / 0.7).clamp(0.0, 1.0);
          return t >= 1
              ? const SizedBox.shrink()
              : ColoredBox(
                  color: PBPalette.white.withValues(alpha: 0.95 * (1 - t)),
                );
        },
      ),
    );
  }
}

/// Soft rays turning slowly behind Carlos.
class _Sunburst extends StatelessWidget {
  const _Sunburst({required this.spin});

  final Animation<double> spin;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([clock, spin]),
      builder: (context, _) => CustomPaint(
        painter: _SunburstPainter(
          open: Curves.easeOutCubic.transform((clock.value / 1).clamp(0, 1)),
          turn: spin.value,
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter({required this.open, required this.turn});

  final double open;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.22);
    final radius = size.longestSide * 0.75 * (0.4 + 0.6 * open);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = RadialGradient(
      colors: [
        PBPalette.white.withValues(alpha: 0.2 * open),
        PBPalette.white.withValues(alpha: 0),
      ],
    ).createShader(rect);
    final paint = Paint()..shader = shader;
    const rays = 16;
    for (var i = 0; i < rays; i++) {
      final start = turn * math.pi * 2 + i * math.pi * 2 / rays;
      canvas.drawArc(rect, start, math.pi / rays * 0.8, true, paint);
    }
    canvas.drawCircle(
      center,
      150 * open,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE478).withValues(alpha: 0.7 * open),
            const Color(0x00FFD43B),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 150)),
    );
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.open != open || old.turn != turn;
}

/// Carlos jumps in, lands with a squash, then dances; golden rings and
/// bananas around him.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final s = clock.value;
        // Jump in: up from below with an overshoot.
        final jump =
            Curves.easeOutBack.transform(((s - 0.25) / 0.8).clamp(0, 1));
        // Squash on landing, then a gentle dance.
        final squash = s > 1.05 && s < 1.4
            ? math.sin((s - 1.05) / 0.35 * math.pi) * 0.08
            : 0.0;
        final dance = s > 2 ? math.sin((s - 2) * math.pi / 0.7) : 0.0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final start in const [0.95, 1.55]) _ring(s, start),
            Positioned(
              left: 0,
              top: 60,
              child: _banana(s, 1.3, -0.4, dance),
            ),
            Positioned(
              right: 0,
              top: 30,
              child: _banana(s, 1.4, 0.45, -dance),
            ),
            Opacity(
              opacity: jump.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - jump) * 260 - dance.abs() * 10),
                child: Transform.rotate(
                  angle: dance * 0.05,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.diagonal3Values(
                      1 + squash * 0.6,
                      1 - squash,
                      1,
                    ),
                    child: Assets.images.proHeroDance.image(height: 240),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ring(double s, double start) {
    final t = ((s - start) / 0.8).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final size = 60 + 300 * Curves.easeOut.transform(t);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: PBPalette.banana.withValues(alpha: 1 - t),
            width: 6,
          ),
        ),
      ),
    );
  }

  Widget _banana(double s, double at, double tilt, double bob) {
    final t = Curves.easeOutBack.transform(((s - at) / 0.6).clamp(0, 1));
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, bob * 6),
        child: Transform.rotate(
          angle: tilt,
          child: Transform.scale(
            scale: 0.2 + 0.8 * t,
            child: Assets.images.island.banana.image(width: 56),
          ),
        ),
      ),
    );
  }
}

class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(PBRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.lg,
          vertical: PBSpace.xs + 3,
        ),
        color: PBPalette.navy800,
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CarbonIcons.star_filled,
                  size: 16,
                  color: PBPalette.banana,
                ),
                const SizedBox(width: PBSpace.xs + 2),
                Text(
                  'PRO',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: PBPalette.banana,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
            // A shine sweeping across.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: clock,
                builder: (context, _) {
                  final t = ((clock.value - 2.1) / 0.8).clamp(0.0, 1.0);
                  if (t <= 0 || t >= 1) return const SizedBox.shrink();
                  return FractionalTranslation(
                    translation: Offset(-1 + 2.2 * t, 0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0xB3FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Pro features, each unlocking with a wiggle and a check.
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: PBSpace.sm + 2,
        crossAxisSpacing: PBSpace.sm + 2,
        childAspectRatio: 2.1,
        children: [
          for (final (i, feature) in ProFeature.values.indexed)
            Reveal(
              at: 2.5 + i * 0.09,
              offset: 30,
              child: _FeatureTile(feature: feature, index: i),
            ),
        ],
      );
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.index});

  final ProFeature feature;
  final int index;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);
    final unlockAt = _kUnlockStart + index * _kUnlockEvery;

    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final s = clock.value;
        final lock = ((s - unlockAt) / 0.3).clamp(0.0, 1.0);
        final check = Curves.easeOutBack
            .transform(((s - unlockAt - 0.25) / 0.4).clamp(0, 1));
        final glow = ((s - unlockAt - 0.25) / 0.45).clamp(0.0, 1.0);
        final ring = glow > 0 && glow < 1 ? math.sin(glow * math.pi) : 0.0;

        return Transform.scale(
          scale: 1 + ring * 0.05,
          child: Container(
            padding: const EdgeInsets.all(PBSpace.sm),
            decoration: BoxDecoration(
              color: PBPalette.white,
              borderRadius: BorderRadius.circular(PBRadius.md),
              boxShadow: [
                if (ring > 0)
                  BoxShadow(
                    color: PBPalette.banana.withValues(alpha: ring),
                    spreadRadius: 3,
                  ),
                BoxShadow(
                  color: PBPalette.navy800.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PBPalette.mist100,
                    borderRadius: BorderRadius.circular(PBRadius.sm),
                  ),
                  child: Icon(
                    feature.icon,
                    size: 18,
                    color: feature.color(context),
                  ),
                ),
                const SizedBox(width: PBSpace.sm - 2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.label(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: PBPalette.navy800,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        feature.caption(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: PBPalette.navy800.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (lock < 1)
                        Transform.rotate(
                          angle: math.sin(lock * math.pi * 3) * 0.35,
                          child: Transform.scale(
                            scale: 1 - lock,
                            child: const Icon(
                              CarbonIcons.locked,
                              size: 16,
                              color: PBPalette.navy800,
                            ),
                          ),
                        ),
                      if (check > 0)
                        Transform.scale(
                          scale: check,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: PBPalette.leaf,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CarbonIcons.checkmark,
                              size: 14,
                              color: PBPalette.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PBPalette.white,
              borderRadius: BorderRadius.circular(PBRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: PBPalette.navy800.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Text(
              label,
              style: context.textTheme.titleMedium
                  ?.copyWith(color: PBPalette.navy800),
            ),
          ),
        ),
      );
}

/// The button gently grows and shrinks to invite a tap.
class _Breathing extends StatelessWidget {
  const _Breathing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final s = clock.value;
        final t = s > 6.4 && s < 7.6 ? math.sin((s - 6.4) / 1.2 * math.pi) : 0;
        return Transform.scale(scale: 1 + t * 0.04, child: child);
      },
    );
  }
}

/// About 64 pieces of confetti bursting from Carlos and falling.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) =>
          CustomPaint(painter: _ConfettiPainter(seconds: clock.value)),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.seconds});

  final double seconds;

  static const List<Color> _colors = [
    PBPalette.banana,
    PBPalette.leaf,
    PBPalette.orange,
    PBPalette.white,
    PBPalette.red,
    PBPalette.purpleLight,
    PBPalette.iceLight,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.24);
    final random = math.Random(7);
    for (var i = 0; i < 64; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = 110 + random.nextDouble() * 170;
      final fall = 420 + random.nextDouble() * 260;
      final drift = (random.nextDouble() - 0.5) * 120;
      final spin = (random.nextDouble() - 0.5) * 4 * math.pi;
      final delay = random.nextDouble() * 0.12;
      final life = 2.4 + random.nextDouble();
      final round = random.nextDouble() < 0.3;
      final width = [7.0, 9.0, 11.0][random.nextInt(3)];

      final t = (seconds - _kBurstAt - delay) / life;
      if (t <= 0 || t >= 1) continue;
      final burst = Curves.easeOutCubic.transform((t / 0.22).clamp(0, 1));
      final x = math.cos(angle) * distance * burst + drift * t;
      final y = math.sin(angle) * distance * 0.8 * burst -
          60 * burst +
          fall * math.pow(t, 2);
      final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: opacity);

      canvas
        ..save()
        ..translate(origin.dx + x, origin.dy + y)
        ..rotate(spin * t);
      if (round) {
        canvas.drawCircle(Offset.zero, width / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: width * 1.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.seconds != seconds;
}
