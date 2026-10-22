import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

/// A small white card with an icon and a stat about the set.
class FinishedSetStatsItem extends StatelessWidget {
  const FinishedSetStatsItem({
    required this.icon,
    required this.text,
    super.key,
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: defaultTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: background2,
                ),
              ),
            ),
          ],
        ),
      );
}
