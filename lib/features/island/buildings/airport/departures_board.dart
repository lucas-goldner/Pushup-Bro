import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

const _kFlapDuration = Duration(milliseconds: 700);

/// How long each later letter keeps flipping after the one before.
const _kFlapStagger = 0.06;

const _kFlapGlyphs = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789';

/// The board's colours: navy like a real departures board by day; in dark
/// mode a raised dark surface, so it still stands out.
({Color board, Color ink, Color tile, Color amber}) boardColors(
  BuildContext context,
) {
  final scheme = context.colorScheme;
  final board = context.isDark ? scheme.surfaceContainerHigh : scheme.primary;
  final ink = context.isDark ? scheme.onSurface : scheme.onPrimary;

  return (
    board: board,
    ink: ink,
    tile: Color.alphaBlend(ink.withValues(alpha: 0.08), board),
    amber: context.gameColors.banana,
  );
}

/// A bro's flight number, the same every time: `PB 214`.
String flightNumber(String uid) {
  final hash = uid.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) % 100003);

  return 'PB${100 + hash % 900}';
}

/// The gate for the [index]th flight on the board: A1, B1, C1, A2…
String gateFor(int index) => '${'ABC'[index % 3]}${index ~/ 3 + 1}';

/// Text on split-flap tiles that flip through letters before settling,
/// like an airport board.
class FlapText extends StatefulWidget {
  const FlapText(
    this.text, {
    this.color,
    this.size = 14,
    this.delay = 0,
    super.key,
  });

  final String text;
  final Color? color;
  final double size;

  /// Extra wait (0 to 1 of the flip) before the first letter settles, so
  /// rows further down settle later.
  final double delay;

  @override
  State<FlapText> createState() => _FlapTextState();
}

class _FlapTextState extends State<FlapText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: _kFlapDuration * (1 + widget.delay),
  )..forward();

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = boardColors(context);
    final ink = widget.color ?? colors.amber;
    final size = widget.size;

    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = _flip.value * (1 + widget.delay) - widget.delay;
        final frame = (_flip.value * 24).floor();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, char) in widget.text.characters.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _Tile(
                  char: char == ' ' ||
                          t >= 0.4 + i * _kFlapStagger ||
                          i * _kFlapStagger > 0.6
                      ? char
                      : _kFlapGlyphs[
                          (frame * 7 + i * 13) % _kFlapGlyphs.length],
                  size: size,
                  ink: ink,
                  tile: colors.tile,
                  line: colors.board,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.char,
    required this.size,
    required this.ink,
    required this.tile,
    required this.line,
  });

  final String char;
  final double size;
  final Color ink;
  final Color tile;
  final Color line;

  @override
  Widget build(BuildContext context) => Container(
        width: size * 0.95,
        height: size * 1.45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: char == ' ' ? null : tile,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              char,
              style: TextStyle(
                fontSize: size,
                height: 1,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            // The split across the middle of each flap.
            if (char != ' ')
              Positioned(
                left: 0,
                right: 0,
                child: Container(height: 1, color: line),
              ),
          ],
        ),
      );
}

/// One flight on the board: the flight number, the bro and their island,
/// the gate, and whether it's boarding or the gift is already dropped.
class FlightRow extends StatelessWidget {
  const FlightRow({
    required this.bro,
    required this.index,
    required this.giftDropped,
    required this.onTap,
    super.key,
  });

  final Bro bro;
  final int index;
  final bool giftDropped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = boardColors(context);
    final name = friendLabel(context, bro.profile, bro.name);
    final delay = math.min(index * 0.15, 0.9);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(PBRadius.md),
        onTap: () {
          GameAudio.instance.play(Sfx.tap);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PBSpace.sm,
            vertical: PBSpace.sm,
          ),
          child: Row(
            children: [
              FlapText(flightNumber(bro.uid), size: 12, delay: delay),
              const SizedBox(width: PBSpace.sm),
              BroAvatar(look: bro.profile.look, size: 34),
              const SizedBox(width: PBSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l.airportLevel(bro.profile.islandLevel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.ink.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        const SizedBox(width: PBSpace.xs),
                        _Status(dropped: giftDropped),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PBSpace.sm),
              FlapText(
                gateFor(index),
                size: 12,
                delay: delay,
                color: colors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Boarding" with a blinking light, or "Gift dropped" once it's done.
class _Status extends StatefulWidget {
  const _Status({required this.dropped});

  final bool dropped;

  @override
  State<_Status> createState() => _StatusState();
}

class _StatusState extends State<_Status> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color =
        widget.dropped ? context.gameColors.leaf : boardColors(context).amber;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: widget.dropped
                ? const AlwaysStoppedAnimation(1)
                : Tween<double>(begin: 0.25, end: 1).animate(_blink),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              widget.dropped ? l.airportGiftSent : l.airportBoarding,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
