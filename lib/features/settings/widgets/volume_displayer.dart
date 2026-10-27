import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// The sound volume as a meter of ten rising bars on a white card: lit
/// bars run from green to red, the rest stay soft.
class VolumeDisplayer extends StatelessWidget {
  const VolumeDisplayer(this.volume, {super.key});
  final int volume;

  Color _barColor(BuildContext context, int i) {
    final game = context.gameColors;
    final stops = [game.leaf, game.banana, game.orange, game.red];
    final t = i / 9 * (stops.length - 1);
    final from = t.floor().clamp(0, stops.length - 2);

    return Color.lerp(stops[from], stops[from + 1], t - from)!;
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: PBSpace.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.xl,
          vertical: PBSpace.xl,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i <= 9; i++) ...[
              if (i > 0) const SizedBox(width: PBSpace.sm),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 18 + i * 6,
                  decoration: BoxDecoration(
                    color: i < volume
                        ? _barColor(context, i)
                        : context.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
