import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
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
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned.fill(
              top: context.sizeOf.height * 0.2,
              left: 20,
              right: 20,
              bottom: context.sizeOf.height * 0.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.gameColorsTheme.map,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            menuType.getLocalizedTitle(context),
                            style: context.textTheme.bodyLarge,
                          ),
                        ),
                        const Spacer(),
                        if (menuType != GameMenuType.quest)
                          const BananaCounter(),
                        const SizedBox(width: 8),
                      ],
                    ),
                    switch (menuType) {
                      GameMenuType.shop => ShopMenu(
                          closeMenu: closeMenu,
                        ),
                      GameMenuType.accessories => AccessoryMenu(
                          closeMenu: closeMenu,
                        ),
                      GameMenuType.monkey => MonkeyMenu(
                          closeMenu: closeMenu,
                        ),
                      _ => const SizedBox.shrink(),
                    },
                    const Spacer(),
                    Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: closeMenu,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 16,
                              bottom: 16,
                            ),
                            child: Text(
                              'Close',
                              style: context.textTheme.displaySmall?.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
