import 'package:flutter/material.dart';
import 'package:pushup_bro/model/enum/menu_tab.dart';
import 'package:pushup_bro/ui/widgets/common/menu/menu_tab.dart';

class MenuTabs extends StatefulWidget {
  const MenuTabs(
    this.drawerController,
    this.menuTabs,
    this.itemSlideIntervals, {
    required this.open,
    super.key,
  });
  final AnimationController drawerController;
  final List<Interval> itemSlideIntervals;
  final List<MenuTabInfo> menuTabs;
  final bool open;

  @override
  State<MenuTabs> createState() => _MenuState();
}

class _MenuState extends State<MenuTabs> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !widget.open,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.menuTabs.length; ++i) ...[
                MenuTab(
                  widget.drawerController,
                  widget.menuTabs[i],
                  widget.itemSlideIntervals[i],
                ),
              ],
            ],
          ),
        ),
      );
}
