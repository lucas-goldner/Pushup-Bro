import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// Marks a day with a workout: a soft leaf green circle.
class PBCalendarEvent extends StatelessWidget {
  const PBCalendarEvent({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: IgnorePointer(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.tint(context.gameColors.leaf),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
}
