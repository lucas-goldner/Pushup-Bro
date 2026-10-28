import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';

/// A menu entry: a floating white pill with a tinted icon and the title.
class MenuTab extends StatelessWidget {
  const MenuTab({
    required this.drawerController,
    required this.menuInfo,
    required this.itemSlideInterval,
    super.key,
  });

  final AnimationController drawerController;
  final Interval itemSlideInterval;
  final MenuTabInfo menuInfo;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: drawerController,
        builder: (context, child) {
          final animationPercent = Curves.easeOut.transform(
            itemSlideInterval.transform(drawerController.value),
          );
          final opacity = animationPercent;
          final slideDistance = (1.0 - animationPercent) * 150;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(slideDistance, 0),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () => menuInfo.navigate(context),
          child: Padding(
            padding: const EdgeInsets.only(top: PBSpace.md, right: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(PBRadius.pill),
                boxShadow: context.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.tint(context.colorScheme.secondary),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      menuInfo.icon,
                      size: 18,
                      color: context.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: PBSpace.md),
                  Text(
                    menuInfo.getMenuTitle(context),
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
