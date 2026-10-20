import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/extensions/shop_buyables.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// The island's actions, as a floating row of tiles at the bottom.
class IslandDock extends StatelessWidget {
  const IslandDock({
    required this.onShop,
    required this.onAccessories,
    required this.onCarlos,
    required this.onJungle,
    super.key,
  });

  final VoidCallback onShop;
  final VoidCallback onAccessories;
  final VoidCallback onCarlos;
  final VoidCallback onJungle;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, List<ShopBuyables>>(
        selector: (state) => state.inventory.boughtItems,
        builder: (context, boughtItems) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: background2.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DockTile(
                icon: CarbonIcons.store,
                label: context.l10n.islandShop,
                onTap: onShop,
                highlighted: true,
              ),
              if (boughtItems.hasAccessories)
                _DockTile(
                  icon: CarbonIcons.shopping_bag,
                  label: context.l10n.islandAccessories,
                  onTap: onAccessories,
                ),
              _DockTile(
                icon: CarbonIcons.face_satisfied,
                label: context.l10n.islandCarlos,
                onTap: onCarlos,
              ),
              _DockTile(
                icon: CarbonIcons.tree,
                label: context.l10n.islandJungle,
                onTap: onJungle,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? Colors.white : primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: highlighted ? background2 : background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            width: 74,
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: defaultTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
