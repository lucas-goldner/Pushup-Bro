import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/progress/model/level_scalings.dart';

/// The level and the experience towards the next one, over a thick
/// rounded bar.
class LevelBar extends StatelessWidget {
  LevelBar({
    required this.level,
    required this.experience,
    super.key,
  }) : _barWidth = LevelScaler().getCurrentExperienceRelativeToLevel(
          level,
          level,
          experience,
        );

  final int level;
  final int experience;
  final double _barWidth;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Text(
                context.l10n.level(level),
                style: context.textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '$experience / ${LevelScaler().getLevelScaling(level)}',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: PBSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(PBRadius.pill),
            child: LinearProgressIndicator(
              value: _barWidth,
              minHeight: 8,
              backgroundColor: context.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.secondary,
              ),
            ),
          ),
        ],
      );
}
