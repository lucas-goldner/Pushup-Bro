import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// Tells a player without Pro that the island is view only.
class JustLookingPill extends StatelessWidget {
  const JustLookingPill({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CarbonIcons.view, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              context.l10n.proJustLooking,
              style: context.textTheme.labelMedium?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
