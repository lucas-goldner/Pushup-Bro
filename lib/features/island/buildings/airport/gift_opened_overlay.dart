import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

const _kOpenDuration = Duration(milliseconds: 1400);

/// How many bananas burst out of the opened gift.
const _kBurst = 12;

/// A gift just opened: it pops up and bursts into bananas, the count rolls
/// up to what it held, and Collect closes it.
class GiftOpenedOverlay extends StatefulWidget {
  const GiftOpenedOverlay({required this.drop, super.key});

  final GiftDrop drop;

  @override
  State<GiftOpenedOverlay> createState() => _GiftOpenedOverlayState();
}

class _GiftOpenedOverlayState extends State<GiftOpenedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: _kOpenDuration,
  )..forward();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      const Duration(milliseconds: 500),
      () => GameAudio.instance.play(Sfx.banana),
    );
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drop = widget.drop;
    final name = drop.fromName.isEmpty ? '🦍' : drop.fromName;
    void close() => Navigator.of(context).pop();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: ColoredBox(
                  color: context.colorScheme.scrim
                      .withValues(alpha: context.isDark ? 0.5 : 0.3),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(PBSpace.xl),
              child: AnimatedBuilder(
                animation: _open,
                builder: (context, _) => _card(context, name, close),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String name, VoidCallback close) {
    final l = context.l10n;
    final drop = widget.drop;
    final t = _open.value;
    // The gift pops in, wiggles, then bursts open.
    final pop = Curves.elasticOut.transform((t / 0.45).clamp(0, 1));
    final burst = Curves.easeOutCubic.transform(((t - 0.3) / 0.7).clamp(0, 1));
    final count = (drop.bananas * ((t - 0.35) / 0.5).clamp(0, 1)).round();

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(
        PBSpace.xl,
        PBSpace.xl,
        PBSpace.xl,
        PBSpace.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              context.tint(context.gameColors.banana),
              context.colorScheme.surface,
            ),
            context.colorScheme.surface,
          ],
          stops: const [0, 0.5],
        ),
        borderRadius: BorderRadius.circular(PBRadius.lg),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _kBurst; i++)
                  _BurstBanana(index: i, progress: burst),
                Transform.rotate(
                  angle: math.sin(t * math.pi * 6) * 0.12 * (1 - burst),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * pop,
                    child: Text(
                      drop.gift.emoji,
                      style: const TextStyle(fontSize: 76),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PBSpace.sm),
          Text(
            l.dropOpenTitle(name),
            textAlign: TextAlign.center,
            style: context.textTheme.headlineMedium,
          ),
          if (drop.gift == GiftKind.flowers) ...[
            const SizedBox(height: PBSpace.xs),
            Text(
              l.dropOpenFlowers,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: PBSpace.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.images.island.banana.image(width: 30),
              const SizedBox(width: PBSpace.xs),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l.dropOpenBananas(count),
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PBSpace.lg),
          PillButton(
            label: l.dropOpenCollect,
            compact: true,
            color: context.gameColors.jungle,
            onPressed: close,
          ),
        ],
      ),
    );
  }
}

/// One banana flying out of the gift and fading as it falls.
class _BurstBanana extends StatelessWidget {
  const _BurstBanana({required this.index, required this.progress});

  final int index;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    final angle = -math.pi / 2 + (index / _kBurst - 0.5) * math.pi * 1.6;
    final reach = 70 + (index % 3) * 18.0;
    final x = math.cos(angle) * reach * progress;
    // Up and out, then gravity pulls them down a little.
    final y = math.sin(angle) * reach * progress + 60 * progress * progress;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: progress * (index.isEven ? 4 : -4),
        child: Opacity(
          opacity: (1 - progress * progress).clamp(0, 1),
          child: Assets.images.island.banana.image(width: 26),
        ),
      ),
    );
  }
}
