import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// The app's primary call to action: a solid, rounded pill. Primary by
/// default (navy, or white in dark mode); a game colour like
/// `context.gameColors.red` makes it white on that colour.
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;

  /// Smaller, to sit in a row with other things.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? context.colorScheme.primary;
    final ink = color == null
        ? context.colorScheme.onPrimary
        : context.gameColors.onGame;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: compact ? 48 : 60,
      constraints: BoxConstraints(minWidth: compact ? 0 : 240),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        boxShadow: context.glow(color ?? context.colorScheme.shadow),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          onTap: () {
            GameAudio.instance.play(Sfx.tap);
            onPressed();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: ink, size: 22),
                  const SizedBox(width: 10),
                ],
                // Long translations shrink instead of overflowing.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: ink,
                        fontSize: compact ? 16 : 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
