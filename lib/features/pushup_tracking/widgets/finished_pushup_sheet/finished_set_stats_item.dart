import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A soft inner card with a tinted icon tile and a stat about the set.
class FinishedSetStatsItem extends StatelessWidget {
  const FinishedSetStatsItem({
    required this.icon,
    required this.text,
    super.key,
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = context.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(PBSpace.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PBRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.tint(accent),
              borderRadius: BorderRadius.circular(PBRadius.sm),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: context.textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}
