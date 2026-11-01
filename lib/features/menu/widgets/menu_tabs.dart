import 'package:flutter/material.dart';
import 'package:pushup_bro/core/flavor.dart';
import 'package:pushup_bro/core/model/environment.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';
import 'package:pushup_bro/features/menu/widgets/menu_tab.dart';

class MenuTabs extends StatelessWidget {
  const MenuTabs(
    this.drawerController,
    this.itemSlideIntervals, {
    required this.open,
    super.key,
  });
  final AnimationController drawerController;
  final List<Interval> itemSlideIntervals;
  final bool open;

  @override
  Widget build(BuildContext context) {
    // The debug tools are for dev builds only.
    final dev = Flavor.getCurrentEnvironment == Environment.dev.getFlavorName();
    final menuTabsToUse = [
      for (final tab in MenuTabInfo.values)
        if (dev || tab != MenuTabInfo.debug) tab,
    ];

    return IgnorePointer(
      ignoring: !open,
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < menuTabsToUse.length; ++i) ...[
              MenuTab(
                drawerController: drawerController,
                menuInfo: menuTabsToUse[i],
                itemSlideInterval: itemSlideIntervals[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
