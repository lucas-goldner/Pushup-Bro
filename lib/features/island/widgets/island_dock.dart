import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/extensions/shop_buyables.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// The island's actions, as a floating row of tiles at the bottom.
class IslandDock extends StatelessWidget {
  const IslandDock({
    required this.onShop,
    required this.onAccessories,
    required this.onCarlos,
    required this.onJungle,
    this.locked = false,
    super.key,
  });

  /// Without Pro every tile wears a little lock (and opens a lock sheet).
  final bool locked;

  final VoidCallback onShop;
  final VoidCallback onAccessories;
  final VoidCallback onCarlos;
  final VoidCallback onJungle;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, List<ShopBuyables>>(
        selector: (state) => state.inventory.boughtItems,
        builder: (context, boughtItems) => Container(
          padding: const EdgeInsets.all(PBSpace.sm),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(PBRadius.lg + 2),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DockTile(
                icon: CarbonIcons.store,
                label: context.l10n.islandShop,
                onTap: onShop,
                highlighted: !locked,
                locked: locked,
              ),
              if (boughtItems.hasAccessories)
                _DockTile(
                  icon: CarbonIcons.shopping_bag,
                  label: context.l10n.islandAccessories,
                  onTap: onAccessories,
                  locked: locked,
                ),
              _DockTile(
                icon: CarbonIcons.face_satisfied,
                label: context.l10n.islandCarlos,
                onTap: onCarlos,
                locked: locked,
              ),
              _DockTile(
                icon: CarbonIcons.tree,
                label: context.l10n.islandJungle,
                onTap: onJungle,
                locked: locked,
              ),
            ],
          ),
        ),
      );
}

class _DockTile extends StatelessWidget {
  const _DockTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final foreground = highlighted ? scheme.onPrimary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: highlighted ? scheme.primary : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PBRadius.md + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.md + 2),
          onTap: onTap,
          child: SizedBox(
            width: 74,
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: foreground, size: 24),
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
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    color: foreground,
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
