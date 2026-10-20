import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class AccessoryMenu extends StatefulWidget {
  const AccessoryMenu({
    required this.closeMenu,
    super.key,
  });

  final VoidCallback closeMenu;

  @override
  State<AccessoryMenu> createState() => _AccessoryMenuState();
}

class _AccessoryMenuState extends State<AccessoryMenu> {
  bool _showBuyConfirmation = false;
  ShopBuyables? selectBuyable;
  bool cantBuy = false;
  String cantBuyReason = '';

  Future<void> selectItem(ShopBuyables buyable) async {
    if (await checktIfCanBuy(buyable)) {
      setState(() {
        cantBuyReason = '';
        cantBuy = false;
        _showBuyConfirmation = true;
        selectBuyable = buyable;
      });
    }
  }

  Future<bool> checktIfCanBuy(ShopBuyables buyable) async {
    final gameInvCubit = context.read<GameInventoryCubit>();
    await gameInvCubit.fetchInventory();
    final inventory = gameInvCubit.state.inventory;

    if (inventory.bananas < buyable.price) {
      setState(() {
        _showBuyConfirmation = false;
        cantBuy = true;
        cantBuyReason = 'Not enough bananas';
      });
      return false;
    }

    if (inventory.boughtItems.contains(buyable)) {
      setState(() {
        _showBuyConfirmation = false;
        cantBuy = true;
        cantBuyReason = 'Already bought';
      });
      return false;
    }

    return true;
  }

  Future<void> confirmPurchase() async {
    final gameInvCubit = context.read<GameInventoryCubit>();
    await gameInvCubit.fetchInventory();
    final inventory = gameInvCubit.state.inventory;
    final boughItem = selectBuyable ?? ShopBuyables.accessories;
    await gameInvCubit.updateInventory(
      inventory.copyWith(
        bananas: inventory.bananas - boughItem.price,
        boughtItems: [...inventory.boughtItems, boughItem],
      ),
    );
    widget.closeMenu();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, List<ShopBuyables>>(
        selector: (state) => state.inventory.boughtItems,
        builder: (context, boughItems) => Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ShopBuyables.accessoriesShopBuyables
                    .map(
                      (buyable) => GestureDetector(
                        onTap: () => selectItem(buyable),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 200,
                          ),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colorScheme.surface,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                buyable.genImg.image(
                                  width: 100,
                                ),
                                Text(
                                  buyable.getLocalizedName(context),
                                  style: context.textTheme.labelLarge?.copyWith(
                                    color: context.colorScheme.primary,
                                  ),
                                ),
                                if (boughItems.contains(buyable))
                                  Row(
                                    children: [
                                      Text(
                                        'Already bought',
                                        style: TextStyle(
                                          color: context.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      const Icon(
                                        CarbonIcons.checkmark,
                                        color: CupertinoColors.activeGreen,
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Text(
                                        buyable.price.toString(),
                                        style: context.textTheme.labelLarge
                                            ?.copyWith(
                                          color: context.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Assets.images.island.banana.image(
                                        width: 48,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (cantBuy)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceDim,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    cantBuyReason,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ),
              ),
            if (_showBuyConfirmation)
              Column(
                children: [
                  Text(
                    'Buying ${selectBuyable?.getLocalizedName(context)}',
                    style: context.textTheme.headlineSmall,
                  ),
                  PBButton(
                    'Confirm',
                    callback: confirmPurchase,
                  ),
                ],
              ),
          ],
        ),
      );
}
