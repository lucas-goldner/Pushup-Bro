import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/features/share/model/flex_stat.dart';
import 'package:pushup_bro/features/share/model/recap.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// How long a share video lasts.
const kRecapSeconds = 10.0;

/// The video's size in logical pixels; it's rendered at 2x (720 × 1280).
const kRecapSize = Size(360, 640);

/// When the flex wall starts, and the gap between its cards.
const kFlexStart = 3.2;
const kFlexEvery = 0.5;
const kOutroStart = 7.4;

/// The sounds of a recap, in seconds, for the video's audio track.
List<(double, String)> recapCues(Recap recap) => [
      (0.2, 'whoosh'),
      (2.1, 'star'),
      (kFlexStart - 0.1, 'level_up'),
      for (var i = 0; i < recap.flex.length; i++)
        (kFlexStart + 0.3 + i * kFlexEvery, 'pop'),
      (kOutroStart + 0.2, 'banana'),
    ];

/// One frame of a share video at [seconds]: a pure function of time, so
/// the preview and every rendered frame agree.
class RecapFrame extends StatelessWidget {
  const RecapFrame({required this.recap, required this.seconds, super.key});

  final Recap recap;
  final double seconds;

  static List<Color> _background(RecapKind kind) => switch (kind) {
        RecapKind.workout => const [Color(0xFF8DBBFF), Color(0xFF3D7BF5)],
        RecapKind.quest => const [Color(0xFF63C96E), Color(0xFF2E7D4F)],
        RecapKind.trek => const [Color(0xFF6B4FC9), Color(0xFF17203A)],
      };

  @override
  Widget build(BuildContext context) {
    final colors = _background(recap.kind);

    return SizedBox.fromSize(
      size: kRecapSize,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
          child: DefaultTextStyle(
            style:
                context.textTheme.bodyMedium!.copyWith(color: PBPalette.white),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RaysPainter(seconds)),
                ),
                if (seconds < kFlexStart + 0.4)
                  _fade(
                    out: _range(seconds, kFlexStart - 0.3, kFlexStart + 0.3),
                    child: _Intro(recap: recap, seconds: seconds),
                  ),
                if (seconds >= kFlexStart - 0.3 && seconds < kOutroStart + 0.4)
                  _fade(
                    out: _range(seconds, kOutroStart - 0.2, kOutroStart + 0.3),
                    child: _FlexWall(recap: recap, seconds: seconds),
                  ),
                if (seconds >= kOutroStart - 0.2)
                  _Outro(recap: recap, seconds: seconds),
                Positioned.fill(
                  child: CustomPaint(painter: _ConfettiPainter(seconds)),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: _Brand(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _fade({required double out, required Widget child}) =>
      Opacity(opacity: 1 - out, child: child);
}

/// How far [seconds] is between [from] and [to], 0 to 1.
double _range(double seconds, double from, double to) =>
    ((seconds - from) / (to - from)).clamp(0.0, 1.0);

/// The big number of the moment.
class _Intro extends StatelessWidget {
  const _Intro({required this.recap, required this.seconds});

  final Recap recap;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rise = Curves.easeOutBack.transform(_range(seconds, 0.1, 0.9));
    final count = Curves.easeOutCubic.transform(_range(seconds, 0.6, 2.1));
    final chip = Curves.easeOutBack.transform(_range(seconds, 2.1, 2.5));
    final headline = switch (recap.kind) {
      RecapKind.workout => l.recapPushupsToday,
      RecapKind.quest => l.recapQuestDone,
      RecapKind.trek => l.recapStageCleared,
    };
    final hero = switch (recap.kind) {
      RecapKind.workout => Assets.images.proHeroPushup,
      RecapKind.quest => Assets.images.proHeroWave,
      RecapKind.trek => Assets.images.proHeroKomo,
    };

    return Column(
      children: [
        const SizedBox(height: 56),
        Opacity(
          opacity: rise.clamp(0.0, 1.0),
          child: Text(
            headline.toUpperCase(),
            style: context.textTheme.labelLarge?.copyWith(
              color: PBPalette.white.withValues(alpha: 0.85),
              letterSpacing: 2,
            ),
          ),
        ),
        if (recap.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: Opacity(
              opacity: rise.clamp(0.0, 1.0),
              child: Text(
                recap.title!,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall
                    ?.copyWith(color: PBPalette.white),
              ),
            ),
          ),
        Text(
          '${(recap.pushups * count).round()}',
          style: context.textTheme.displayLarge?.copyWith(
            color: PBPalette.white,
            fontSize: 120,
          ),
        ),
        Text(
          l.flexPushups,
          style: context.textTheme.titleLarge?.copyWith(color: PBPalette.white),
        ),
        const SizedBox(height: 12),
        if (recap.vsLast > 0)
          Transform.scale(
            scale: chip,
            child: _Chip(
              icon: CarbonIcons.arrow_up,
              text: l.recapVsLast(recap.vsLast),
              color: PBPalette.leaf,
            ),
          ),
        Expanded(
          child: Transform.translate(
            offset: Offset(0, (1 - rise) * 200),
            child: hero.image(fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 56),
      ],
    );
  }
}

/// Up to four achievement cards slamming in under a title.
class _FlexWall extends StatelessWidget {
  const _FlexWall({required this.recap, required this.seconds});

  final Recap recap;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (recap.kind) {
      RecapKind.workout => l.flexWorkoutTitle,
      RecapKind.quest => l.flexQuestTitle,
      RecapKind.trek => l.flexTrekTitle,
    };
    final titleIn = Curves.easeOutBack
        .transform(_range(seconds, kFlexStart - 0.1, kFlexStart + 0.3));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 52),
      child: Column(
        children: [
          Transform.scale(
            scale: 0.6 + 0.4 * titleIn,
            child: Opacity(
              opacity: titleIn.clamp(0.0, 1.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.displaySmall?.copyWith(
                  color: PBPalette.banana,
                  fontSize: 38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final (i, stat) in recap.flex.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FlexCard(
                stat: stat,
                seconds: seconds - (kFlexStart + 0.3 + i * kFlexEvery),
              ),
            ),
          Expanded(
            child: Opacity(
              opacity: _range(seconds, kFlexStart + 2.4, kFlexStart + 3),
              child: Assets.images.proHeroDance.image(fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlexCard extends StatelessWidget {
  const _FlexCard({required this.stat, required this.seconds});

  final FlexStat stat;

  /// Seconds since this card started slamming in.
  final double seconds;

  static (IconData, Color) look(FlexKind kind) => switch (kind) {
        FlexKind.moreThanLast => (CarbonIcons.arrow_up, PBPalette.leaf),
        FlexKind.kcal => (CarbonIcons.fire, PBPalette.orange),
        FlexKind.inARow => (CarbonIcons.trophy, PBPalette.banana),
        FlexKind.streak => (CarbonIcons.fire, PBPalette.red),
        FlexKind.total => (CarbonIcons.chart_line, PBPalette.iceLight),
        FlexKind.bananas => (CarbonIcons.star_filled, PBPalette.banana),
        FlexKind.pushups => (CarbonIcons.chart_line, PBPalette.iceLight),
        FlexKind.stars => (CarbonIcons.star_filled, PBPalette.banana),
        FlexKind.damage => (CarbonIcons.lightning, PBPalette.red),
        FlexKind.combo => (CarbonIcons.flash, PBPalette.purpleLight),
      };

  static (String, String) text(S l, FlexStat stat) => switch (stat.kind) {
        FlexKind.moreThanLast => ('+${stat.value}', l.flexMoreThanLast),
        FlexKind.kcal => ('−${stat.value}', l.flexKcal),
        FlexKind.inARow => (
            '${stat.value}',
            stat.best ? l.flexBestInARow : l.flexInARow,
          ),
        FlexKind.streak => ('${stat.value}', l.flexStreak),
        FlexKind.total => ('${stat.value}', l.flexTotal),
        FlexKind.bananas => ('+${stat.value}', l.flexBananas),
        FlexKind.pushups => ('${stat.value}', l.flexPushups),
        FlexKind.stars => ('${stat.value}', l.flexStars),
        FlexKind.damage => ('${stat.value}', l.flexDamage),
        FlexKind.combo => (
            '×${stat.value}',
            stat.best ? l.flexBestCombo : l.flexCombo,
          ),
      };

  @override
  Widget build(BuildContext context) {
    if (seconds <= 0) return const SizedBox(height: 68);
    final slam = Curves.easeOutBack.transform((seconds / 0.35).clamp(0, 1));
    final roll = Curves.easeOutCubic.transform((seconds / 0.9).clamp(0, 1));
    final (icon, color) = look(stat.kind);
    final (value, label) = text(context.l10n, stat);
    // The number rolls up: the digits of the value, scaled by the roll.
    final digits = RegExp(r'\d+').firstMatch(value);
    final shown = digits == null
        ? value
        : value.replaceRange(
            digits.start,
            digits.end,
            '${(int.parse(digits.group(0)!) * roll).round()}',
          );

    return Transform.scale(
      scale: 1.6 - 0.6 * slam,
      child: Transform.rotate(
        angle: (1 - slam) * -0.12,
        child: Opacity(
          opacity: slam.clamp(0.0, 1.0),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: PBPalette.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CustomPaint(
                    painter: _BurstPainter(color: color, t: seconds),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: PBPalette.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  shown,
                  style: context.textTheme.headlineMedium
                      ?.copyWith(color: PBPalette.navy800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: PBPalette.navy800.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                if (stat.best)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PBPalette.banana,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CarbonIcons.trophy,
                      size: 14,
                      color: PBPalette.navy800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The closing line and the app.
class _Outro extends StatelessWidget {
  const _Outro({required this.recap, required this.seconds});

  final Recap recap;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Curves.easeOutBack
        .transform(_range(seconds, kOutroStart, kOutroStart + 0.6));
    final line = switch (recap.kind) {
      RecapKind.workout => l.recapCanYouBeat(recap.pushups),
      RecapKind.quest => l.recapNewQuestDaily,
      RecapKind.trek => l.recapJoin,
    };

    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.8 + 0.2 * t,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 220,
                  child: Assets.images.proHeroWave.image(fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Text(
                  line,
                  textAlign: TextAlign.center,
                  style: context.textTheme.displaySmall
                      ?.copyWith(color: PBPalette.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: PBPalette.white),
            const SizedBox(width: 6),
            Text(
              text,
              style: context.textTheme.labelLarge
                  ?.copyWith(color: PBPalette.white),
            ),
          ],
        ),
      );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Assets.images.appIcons.classic.image(width: 22, height: 22),
          ),
          const SizedBox(width: 8),
          Text(
            'Pushup Bro',
            style: context.textTheme.labelLarge?.copyWith(
              color: PBPalette.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
}

/// Slowly turning soft rays.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.seconds);

  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final radius = size.longestSide;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          PBPalette.white.withValues(alpha: 0.16),
          PBPalette.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    const rays = 14;
    final turn = seconds * 0.08;
    for (var i = 0; i < rays; i++) {
      final start = turn + i * math.pi * 2 / rays;
      canvas.drawArc(rect, start, math.pi / rays * 0.8, true, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.seconds != seconds;
}

/// Little rays bursting out of a card's icon as it lands.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final p = (t / 0.6).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - p)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (22 + 10 * p),
        center + direction * (28 + 16 * p),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// Confetti that falls while the flex wall fills.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.seconds);

  final double seconds;

  static const List<Color> _colors = [
    PBPalette.banana,
    PBPalette.leaf,
    PBPalette.orange,
    PBPalette.white,
    PBPalette.red,
    PBPalette.purpleLight,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(3);
    for (var i = 0; i < 46; i++) {
      final x = random.nextDouble() * size.width;
      final start = kFlexStart + random.nextDouble() * 2.4;
      final speed = 160 + random.nextDouble() * 140;
      final spin = (random.nextDouble() - 0.5) * 8;
      final w = 6 + random.nextDouble() * 4;
      final t = seconds - start;
      if (t <= 0 || t > 4) continue;
      final y = -20 + speed * t;
      if (y > size.height) continue;
      canvas
        ..save()
        ..translate(x + math.sin(t * 3 + i) * 12, y)
        ..rotate(spin * t)
        ..drawRect(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 1.6),
          Paint()..color = _colors[i % _colors.length],
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.seconds != seconds;
}
