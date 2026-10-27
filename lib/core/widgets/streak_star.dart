import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A streak of [days], as a small flame pill.
class StreakStar extends StatelessWidget {
  const StreakStar(this.days, {super.key});
  final int days;

  @override
  Widget build(BuildContext context) {
    final flame = context.gameColors.orange;

    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 8, right: 12),
      decoration: BoxDecoration(
        color: context.tint(flame),
        borderRadius: BorderRadius.circular(PBRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CarbonIcons.fire, size: 16, color: flame),
          const SizedBox(width: PBSpace.xs),
          Text(
            '$days',
            style: context.textTheme.labelMedium?.copyWith(
              color: flame,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
