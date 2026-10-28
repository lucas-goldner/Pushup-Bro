import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A 48px white circle floating on a soft shadow, with an [icon]; centred
/// in a 56px square so the open and close buttons line up.
class MenuCircleButton extends StatelessWidget {
  const MenuCircleButton({
    required this.icon,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: context.cardShadow,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                splashFactory: NoSplash.splashFactory,
                onTap: onTap,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    icon,
                    size: 22,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
