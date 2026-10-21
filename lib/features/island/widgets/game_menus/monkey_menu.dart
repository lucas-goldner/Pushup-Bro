import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

class MonkeyMenu extends StatefulWidget {
  const MonkeyMenu({
    required this.closeMenu,
    super.key,
  });

  final VoidCallback closeMenu;

  @override
  State<MonkeyMenu> createState() => _MonkeyMenuState();
}

class _MonkeyMenuState extends State<MonkeyMenu> {
  void _equipAccessory(ShopBuyables buyAble) {
    final gameInvCubit = context.read<GameInventoryCubit>();
    final inventory = gameInvCubit.state.inventory;

    if (inventory.monkeys[0].accessory == buyAble) {
      unawaited(
        gameInvCubit.updateInventory(
          inventory.copyWith(
            monkeys: inventory.monkeys
                .map(
                  (monkey) => monkey.copyWith(
                    accessory: ShopBuyables.none,
                  ),
                )
                .toList(),
          ),
        ),
      );
      return;
    }

    unawaited(
      gameInvCubit.updateInventory(
        inventory.copyWith(
          monkeys: inventory.monkeys
              .map(
                (monkey) => monkey.copyWith(
                  accessory: buyAble,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, GameInventory>(
        selector: (state) => state.inventory,
        builder: (context, inventory) => Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ShopBuyables.accessoriesShopBuyables
                    .where(
                      (buyAble) => inventory.boughtItems.contains(buyAble),
                    )
                    .map(
                      (buyable) => GestureDetector(
                        onTap: () => _equipAccessory(buyable),
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
                                if (inventory.monkeys[0].accessory != buyable)
                                  Text(
                                    buyable.getLocalizedName(context),
                                    style:
                                        context.textTheme.labelLarge?.copyWith(
                                      color: context.colorScheme.primary,
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Text(
                                        buyable.getLocalizedName(context),
                                        style: context.textTheme.labelLarge
                                            ?.copyWith(
                                          color: context.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        CarbonIcons.checkmark,
                                        color: CupertinoColors.activeGreen,
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
          ],
        ),
      );
}
