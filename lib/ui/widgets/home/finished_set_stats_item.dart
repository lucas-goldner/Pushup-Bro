import 'package:flutter/material.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';

class FinishedSetStatsItem extends StatelessWidget {
  const FinishedSetStatsItem({
    required this.icon, required this.text, super.key,
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: PBColors.background2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              text,
              style: PBTextStyles.defaultTextStyle,
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
