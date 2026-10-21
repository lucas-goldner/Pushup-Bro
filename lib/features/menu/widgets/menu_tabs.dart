import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/model/feature_variants.dart';
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
    final appFeatues = context.read<FeatureSwitchCubit>().state.featureVariant;
    final featuresForHookmodel = [
      MenuTabInfo.pushupTracking,
      MenuTabInfo.progress,
      MenuTabInfo.friends,
      MenuTabInfo.leaderbaord,
      MenuTabInfo.settings,
      MenuTabInfo.debug,
    ];
    final featuresForGamification = [
      MenuTabInfo.pushupTracking,
      MenuTabInfo.island,
      MenuTabInfo.settings,
      MenuTabInfo.debug,
    ];
    final menuTabsToUse = appFeatues == FeatureVariants.hookmodel
        ? featuresForHookmodel
        : featuresForGamification;

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
