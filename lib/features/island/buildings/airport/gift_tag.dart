import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';

/// The sender's name over a gift on the island; tapping it opens the gift
/// (a bigger target than the crate, which is small from up here).
class GiftTag extends StatelessWidget {
  const GiftTag({required this.drop, this.onTap, super.key});

  final GiftDrop drop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = drop.fromName.isEmpty ? '🦍' : drop.fromName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.sm + 2,
          vertical: PBSpace.xs,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          border: Border.all(color: context.gameColors.banana, width: 2),
          boxShadow: context.cardShadow,
        ),
        child: Text(
          '${drop.gift.emoji} $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
