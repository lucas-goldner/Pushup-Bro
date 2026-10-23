import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

/// The app's primary call to action: a solid, rounded pill.
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = background2,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;

  /// Smaller, to sit in a row with other things.
  final bool compact;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: compact ? 48 : 60,
        constraints: BoxConstraints(minWidth: compact ? 0 : 240),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: buttonTextStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 16 : 18,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
