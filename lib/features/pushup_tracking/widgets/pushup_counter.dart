import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// The live rep count: a big number on a floating card, so it stays
/// readable over the bright gym in both light and dark mode.
class PushupCounter extends StatelessWidget {
  const PushupCounter(this.pushups, {super.key});
  final int pushups;

  @override
  Widget build(BuildContext context) => Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(PBRadius.lg),
            boxShadow: context.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PBSpace.xxl,
              PBSpace.md,
              PBSpace.xxl,
              PBSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedFlipCounter(
                  value: pushups,
                  textStyle: context.textTheme.displayLarge!.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: PBSpace.xs),
                Text(
                  context.l10n.pushupsLabel.toUpperCase(),
                  style: context.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2.4,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
