import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

class PushupCounter extends StatelessWidget {
  const PushupCounter(this.pushups, {super.key});
  final int pushups;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedFlipCounter(
            value: pushups,
            textStyle: pushupTextStyle.copyWith(
              fontSize: 96,
              height: 1,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.pushupsLabel.toUpperCase(),
            style: defaultTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
}
