import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/island/widgets/game_menus/shop_menu.dart';

/// The island's building shop, as a sheet.
class GameMenu extends StatelessWidget {
  const GameMenu({
    required this.closeMenu,
    required this.menuVisible,
    super.key,
  });

  final VoidCallback closeMenu;
  final bool menuVisible;

  @override
  Widget build(BuildContext context) => Visibility(
        visible: menuVisible,
        child: IslandSheet(
          title: context.l10n.shopTitle,
          subtitle: context.l10n.shopSubtitle,
          badge: '🏗️',
          accent: const Color(0xFFF5A623),
          onClose: closeMenu,
          trailing: const BananaCounter(),
          child: ShopMenu(closeMenu: closeMenu),
        ),
      );
}
