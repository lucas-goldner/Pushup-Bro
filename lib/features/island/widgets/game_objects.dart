import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/shop_buyables.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/island/widgets/game_objects/accessories_shop.dart';
import 'package:pushup_bro/features/island/widgets/game_objects/shop.dart';

class GameObjects extends StatelessWidget {
  const GameObjects({
    required this.onMenuOpen,
    super.key,
  });

  final void Function(GameMenuType) onMenuOpen;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, List<ShopBuyables>>(
        selector: (state) => state.inventory.boughtItems,
        builder: (context, boughtItems) => Stack(
          children: [
            Shop(
              onMenuOpen: onMenuOpen,
            ),
            if (boughtItems.hasAccessories)
              AccessoriesShop(
                onMenuOpen: onMenuOpen,
              ),
          ],
        ),
      );
}
