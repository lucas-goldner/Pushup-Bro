import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/debug/debug.dart';
import 'package:pushup_bro/features/island/island.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/pushup_tracking.dart';
import 'package:pushup_bro/features/settings/settings.dart';
import 'package:pushup_bro/features/stats/stats_page.dart';

/// The menu's pages, in the order the menu lists them.
enum MenuTabInfo {
  pushupTracking,
  island,
  stats,
  settings,
  debug;
}

extension MenuTabInfoExtension on MenuTabInfo {
  String getMenuTitle(BuildContext context) => switch (this) {
        MenuTabInfo.pushupTracking => context.l10n.home,
        MenuTabInfo.island => context.l10n.island,
        MenuTabInfo.stats => context.l10n.stats,
        MenuTabInfo.settings => context.l10n.settings,
        MenuTabInfo.debug => 'Debug',
      };

  IconData get icon => switch (this) {
        MenuTabInfo.pushupTracking => CarbonIcons.home,
        MenuTabInfo.island => CarbonIcons.airport_location,
        MenuTabInfo.stats => CarbonIcons.chart_column,
        MenuTabInfo.settings => CarbonIcons.settings,
        MenuTabInfo.debug => CarbonIcons.debug,
      };

  String get routeName => switch (this) {
        MenuTabInfo.pushupTracking => PushupTracking.routeName,
        MenuTabInfo.island => Island.routeName,
        MenuTabInfo.stats => StatsPage.routeName,
        MenuTabInfo.settings => Settings.routeName,
        MenuTabInfo.debug => Debug.routeName,
      };

  Future<void> navigate(BuildContext context) {
    BlocProvider.of<PushupCubit>(context).resetAndReturnCurrentPushupSet();

    return Navigator.of(context)
        .pushReplacementNamed(routeName, arguments: context);
  }
}
