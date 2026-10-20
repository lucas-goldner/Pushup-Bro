import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';

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
            padding: const EdgeInsets.only(top: 16, right: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.onSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    Icon(menuInfo.icon),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      menuInfo.getMenuTitle(context),
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.surfaceBright,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
