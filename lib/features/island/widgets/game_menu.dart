import 'package:flutter/material.dart';
import 'package:pushup_bro/core/widgets/sheet_panel.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/island/widgets/game_menus/accessory_menu.dart';
import 'package:pushup_bro/features/island/widgets/game_menus/monkey_menu.dart';
import 'package:pushup_bro/features/island/widgets/game_menus/shop_menu.dart';

class GameMenu extends StatelessWidget {
  const GameMenu({
    required this.closeMenu,
    required this.menuVisible,
    required this.menuType,
    super.key,
  });

  final VoidCallback closeMenu;
  final bool menuVisible;
  final GameMenuType menuType;

  @override
  Widget build(BuildContext context) => Visibility(
        visible: menuVisible,
        child: SheetPanel(
          title: menuType.getLocalizedTitle(context),
          onClose: closeMenu,
          trailing: menuType == GameMenuType.quest
              ? null
              : const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: BananaCounter(),
                ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: switch (menuType) {
              GameMenuType.shop => ShopMenu(closeMenu: closeMenu),
              GameMenuType.accessories => AccessoryMenu(closeMenu: closeMenu),
              GameMenuType.monkey => MonkeyMenu(closeMenu: closeMenu),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );
}
