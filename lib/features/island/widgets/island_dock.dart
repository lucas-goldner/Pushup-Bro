import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// The island's own places, as a floating row of three tiles at the
/// bottom: the shop, Carlos's wardrobe and the jungle. The bros live in a
/// bubble above it (see `BrosBubble`).
class IslandDock extends StatelessWidget {
  const IslandDock({
    required this.onShop,
    required this.onCarlos,
    required this.onJungle,
    this.locked = false,
    super.key,
  });

  /// Without Pro every tile wears a little lock (and opens a lock sheet).
  final bool locked;

  final VoidCallback onShop;
  final VoidCallback onCarlos;
  final VoidCallback onJungle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(PBSpace.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(PBRadius.lg + 2),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          _DockTile(
            icon: CarbonIcons.store,
            label: context.l10n.islandShop,
            onTap: onShop,
            color: locked ? null : scheme.primary,
            foreground: scheme.onPrimary,
            locked: locked,
          ),
          const SizedBox(width: PBSpace.sm),
          _DockTile(
            icon: CarbonIcons.face_satisfied,
            label: context.l10n.islandCarlos,
            onTap: onCarlos,
            locked: locked,
          ),
          const SizedBox(width: PBSpace.sm),
          // The way into the game, in the jungle's own green.
          _DockTile(
            icon: CarbonIcons.tree,
            label: context.l10n.islandJungle,
            onTap: onJungle,
            color: locked ? null : context.gameColors.jungle,
            foreground: context.gameColors.onGame,
            locked: locked,
          ),
        ],
      ),
    );
  }
}

class _DockTile extends StatelessWidget {
  const _DockTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.foreground,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// The tile's fill; the plain tile colour without one.
  final Color? color;

  /// The icon and label colour on [color].
  final Color? foreground;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fill = color;
    final foreground =
        fill == null ? scheme.onSurface : this.foreground ?? scheme.onPrimary;

    return Expanded(
      child: Material(
        color: fill ?? scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PBRadius.md + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.md + 2),
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: foreground, size: 26),
                    if (locked)
                      Positioned(
                        right: -9,
                        bottom: -5,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.surfaceContainerLow,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            CarbonIcons.locked,
                            size: 9,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontSize: 15,
                        color: foreground,
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
