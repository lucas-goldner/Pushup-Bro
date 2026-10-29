import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';

extension ProStateFreeDays on ProState {
  /// Whether the free days are worth showing at [now]: they're running, the
  /// player has no Pro yet and the store could sell them some.
  bool showsFreeDays(DateTime now) =>
      storeAvailable &&
      plans.isNotEmpty &&
      !isPro &&
      !simulateLocked &&
      inFreeDays(now);
}

/// "2 free days left", or the hours on the last day.
String freeLeftLabel(BuildContext context, Duration left) {
  if (left < const Duration(hours: 24)) {
    return context.l10n
        .proFreeHoursLeft(math.max(1, (left.inMinutes / 60).ceil()));
  }

  return context.l10n.proFreeDaysLeft((left.inMinutes / 1440).ceil());
}

/// The pill that counts down the free days, or says they're over.
class FreeDaysChip extends StatelessWidget {
  const FreeDaysChip({required this.left, this.onTap, super.key});

  /// What's left of the free days; zero once they're over.
  final Duration left;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final over = left <= Duration.zero;
    final game = context.gameColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: PBSpace.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              over ? CarbonIcons.locked : CarbonIcons.time,
              size: 15,
              color: over ? game.red : game.orange,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                over
                    ? context.l10n.proFreeDaysOver
                    : freeLeftLabel(context, left),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The free days on the home screen, top right opposite the menu button:
/// a big clock and the number of days left ("5h" on the last day), so it
/// can't be missed. A lock once they're over.
class FreeDaysBadge extends StatelessWidget {
  const FreeDaysBadge({required this.left, this.onTap, super.key});

  /// What's left of the free days; zero once they're over.
  final Duration left;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final over = left <= Duration.zero;
    final game = context.gameColors;
    final lastDay = left < const Duration(hours: 24);
    final count = over
        ? ''
        : lastDay
            ? '${math.max(1, (left.inMinutes / 60).ceil())}h'
            : '${(left.inMinutes / 1440).ceil()}';

    return Semantics(
      button: true,
      label: over ? context.l10n.proFreeDaysOver : freeLeftLabel(context, left),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: over ? game.red : game.orange,
            borderRadius: BorderRadius.circular(PBRadius.pill),
            boxShadow: context.cardShadow,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  over ? CarbonIcons.locked : CarbonIcons.time,
                  size: 24,
                  color: game.onGame,
                ),
                if (count.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    count,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: game.onGame,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
