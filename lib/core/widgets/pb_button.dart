import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: expanded ?? false
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => callback?.call(),
                      style: ElevatedButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: context.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        text,
                        style: context.textTheme.labelLarge,
                      ),
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () => callback?.call(),
                style: ElevatedButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                  backgroundColor: context.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  text,
                  style: context.textTheme.labelLarge,
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: expanded ?? false
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => callback?.call(),
                      style: ElevatedButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: context.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (text.isNotEmpty)
                            Text(
                              text,
                              style: context.textTheme.labelLarge,
                            ),
                          if (text.isNotEmpty) const SizedBox(width: 8),
                          Flexible(
                            child: Icon(
                              icon,
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                          if (text.isNotEmpty) const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () => callback?.call(),
                style: ElevatedButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                  backgroundColor: context.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: context.textTheme.labelLarge,
                      ),
                    if (text.isNotEmpty) const SizedBox(width: 8),
                    Flexible(
                      child: Icon(
                        icon,
                        color: context.colorScheme.onPrimary,
                      ),
                    ),
                    if (text.isNotEmpty) const SizedBox(width: 8),
                  ],
                ),
              ),
      );
}
