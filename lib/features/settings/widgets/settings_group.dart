import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A small caps heading above a [SettingsGroup].
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PBSpace.xl + PBSpace.sm,
          PBSpace.xl,
          PBSpace.xl,
          PBSpace.sm,
        ),
        child: Text(
          title.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// An iOS style inset grouped list: rows on one white rounded card,
/// split by inset hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: PBSpace.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PBRadius.lg),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    // Inset past the icon tile, like iOS.
                    const Divider(indent: 64, endIndent: PBSpace.lg),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      );
}

/// A row in a [SettingsGroup]: a tinted icon tile, a label and a trailing
/// icon (a chevron by default).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
    this.trailing,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// The icon tile's colour; the theme's secondary by default.
  final Color? color;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colorScheme.secondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.lg,
          vertical: PBSpace.md,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.tint(color),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: context.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: PBSpace.sm),
            trailing ??
                Icon(
                  CarbonIcons.chevron_right,
                  size: 18,
                  color: context.colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}
