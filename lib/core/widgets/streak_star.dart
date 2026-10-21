import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class StreakStar extends StatelessWidget {
  const StreakStar(this.days, {super.key});
  final int days;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: ShapeDecoration(
              gradient: context.progressTheme.streakStarGradient,
              shape: const StarBorder(
                pointRounding: 0.25,
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: FittedBox(
                child: Text(
                  '$days',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
