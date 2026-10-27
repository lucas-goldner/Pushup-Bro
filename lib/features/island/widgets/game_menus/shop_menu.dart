import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// The island's building shop: a grid of buildings; pick one, then build
/// it for its price in bananas.
class ShopMenu extends StatefulWidget {
  const ShopMenu({
    required this.closeMenu,
    super.key,
  });

  final VoidCallback closeMenu;

  @override
  State<ShopMenu> createState() => _ShopMenuState();
}

class _ShopMenuState extends State<ShopMenu> {
  ShopBuyables? _selected;

  Future<void> _build(ShopBuyables building) async {
    final gameInvCubit = context.read<GameInventoryCubit>();
    await gameInvCubit.fetchInventory();
    final inventory = gameInvCubit.state.inventory;
    if (inventory.bananas < building.price ||
        inventory.boughtItems.contains(building)) {
      return;
    }
    GameAudio.instance.play(Sfx.purchase);
    await gameInvCubit.updateInventory(
      inventory.copyWith(
        bananas: inventory.bananas - building.price,
        boughtItems: [...inventory.boughtItems, building],
      ),
    );
    widget.closeMenu();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, GameInventory>(
        selector: (state) => state.inventory,
        builder: (context, inventory) {
          final selected = _selected;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
                children: [
                  for (final building in ShopBuyables.buildingsShopBuyables)
                    _BuildingCard(
                      building: building,
                      built: inventory.boughtItems.contains(building),
                      affordable: inventory.bananas >= building.price,
                      selected: building == selected,
                      onTap: () => setState(() => _selected = building),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (selected != null)
                Center(
                  child: _action(selected, inventory),
                ),
            ],
          );
        },
      );

  Widget _action(ShopBuyables building, GameInventory inventory) {
    if (inventory.boughtItems.contains(building)) {
      return SheetTag(
        context.l10n.shopAlreadyBuilt(building.getLocalizedName(context)),
        icon: CarbonIcons.checkmark_filled,
        color: context.gameColors.jungle,
      );
    }
    final missing = building.price - inventory.bananas;
    if (missing > 0) {
      return SheetTag(
        context.l10n.shopNeedMore(missing),
        icon: CarbonIcons.warning_alt,
        color: context.gameColors.red,
      );
    }

    return PillButton(
      label: context.l10n.shopBuild(building.price),
      icon: CarbonIcons.construction,
      onPressed: () => _build(building),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({
    required this.building,
    required this.built,
    required this.affordable,
    required this.selected,
    required this.onTap,
  });

  final ShopBuyables building;
  final bool built;
  final bool affordable;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SheetCard(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: built ? 0.55 : 1,
                child: building.genImg.image(fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              building.getLocalizedName(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (built)
              SheetTag(
                context.l10n.shopBuilt,
                icon: CarbonIcons.checkmark,
                color: context.gameColors.jungle,
              )
            else
              BananaPrice(building.price, affordable: affordable),
          ],
        ),
      );
}
