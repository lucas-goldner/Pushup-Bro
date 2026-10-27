import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A solid pill button in the primary colour, like `PillButton` but a bit
/// smaller, for rows and lists. `expanded` stretches it to the full width.
sealed class PBButton extends StatelessWidget {
  const factory PBButton(
    String text, {
    VoidCallback? callback,
    bool? expanded,
  }) = _PBButton;

  const PBButton._({super.key});

  const factory PBButton.icon(
    String text, {
    required IconData icon,
    VoidCallback? callback,
    bool? expanded,
  }) = _PBButtonIcon;
}

class _PBButton extends PBButton {
  const _PBButton(
    this.text, {
    this.callback,
    this.expanded,
  }) : super._();

  final String text;
  final VoidCallback? callback;
  final bool? expanded;

  @override
  Widget build(BuildContext context) => _PillShell(
        callback: callback,
        expanded: expanded ?? false,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onPrimary,
          ),
        ),
      );
}

class _PBButtonIcon extends PBButton {
  const _PBButtonIcon(
    this.text, {
    required this.icon,
    this.callback,
    this.expanded,
  }) : super._();

  final String text;
  final IconData icon;
  final VoidCallback? callback;
  final bool? expanded;

  @override
  Widget build(BuildContext context) => _PillShell(
        callback: callback,
        expanded: expanded ?? false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.isNotEmpty) ...[
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: PBSpace.sm),
            ],
            Icon(icon, size: 20, color: context.colorScheme.onPrimary),
          ],
        ),
      );
}

/// The rounded, softly glowing fill shared by both buttons.
class _PillShell extends StatelessWidget {
  const _PillShell({
    required this.child,
    required this.callback,
    required this.expanded,
  });

  final Widget child;
  final VoidCallback? callback;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 52,
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        boxShadow: context.glow(context.colorScheme.shadow),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          splashFactory: NoSplash.splashFactory,
          onTap: () => callback?.call(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PBSpace.xl),
            child: Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PBSpace.sm),
      child:
          expanded ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
