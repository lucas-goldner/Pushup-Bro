import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

/// A white card floating over a dimmed backdrop, with a title row and an
/// optional close button; used for the island's menus and quests.
class SheetPanel extends StatelessWidget {
  const SheetPanel({
    required this.title,
    required this.child,
    this.trailing,
    this.onClose,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: ColoredBox(color: background2.withValues(alpha: 0.35)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: background2.withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: pageTitleTextStyle.copyWith(
                                  fontSize: 26,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            if (trailing != null) trailing!,
                            if (onClose != null)
                              IconButton(
                                onPressed: onClose,
                                style: IconButton.styleFrom(
                                  backgroundColor: background,
                                ),
                                icon: const Icon(
                                  CarbonIcons.close,
                                  color: primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
