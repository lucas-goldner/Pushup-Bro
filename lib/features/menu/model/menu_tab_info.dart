import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/debug/debug.dart';
import 'package:pushup_bro/features/friends/friends.dart';
import 'package:pushup_bro/features/island/island.dart';
import 'package:pushup_bro/features/leaderboard/leaderboard.dart';
import 'package:pushup_bro/features/progress/progress.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/pushup_tracking.dart';
import 'package:pushup_bro/features/settings/settings.dart';

enum MenuTabInfo {
  pushupTracking,
  progress,
  // calendar,
  friends,
  leaderbaord,
  settings,
  island,
  debug;
}

extension MenuTabInfoExtension on MenuTabInfo {
  String getMenuTitle(BuildContext context) => switch (this) {
        MenuTabInfo.pushupTracking => context.l10n.home,
        MenuTabInfo.progress => context.l10n.progress,
        // MenuTabInfo.calendar => context.l10n.calendar,
        MenuTabInfo.friends => context.l10n.friends,
        MenuTabInfo.leaderbaord => context.l10n.leaderboard,
        MenuTabInfo.settings => context.l10n.settings,
        MenuTabInfo.debug => 'Debug',
        MenuTabInfo.island => context.l10n.island,
      };

  IconData get icon => switch (this) {
        MenuTabInfo.pushupTracking => CarbonIcons.home,
        MenuTabInfo.progress => CarbonIcons.skill_level,
        // MenuTabInfo.calendar => CarbonIcons.calendar,
        MenuTabInfo.friends => CarbonIcons.group,
        MenuTabInfo.leaderbaord => CarbonIcons.list_numbered,
        MenuTabInfo.settings => CarbonIcons.settings,
        MenuTabInfo.debug => CarbonIcons.debug,
        MenuTabInfo.island => CarbonIcons.airport_location,
      };

  Future<void> navigate(BuildContext context) {
    final navigator = Navigator.of(context);
    BlocProvider.of<PushupCubit>(context).resetAndReturnCurrentPushupSet();

    return switch (this) {
      MenuTabInfo.pushupTracking => navigator.pushReplacementNamed(
          PushupTracking.routeName,
          arguments: context,
        ),
      MenuTabInfo.progress => navigator.pushReplacementNamed(
          Progress.routeName,
          arguments: context,
        ),
      // MenuTabInfo.calendar => navigator.pushReplacementNamed(
      //     Calendar.routeName,
      //     arguments: context,
      //   ),
      MenuTabInfo.friends => navigator.pushReplacementNamed(
          Friends.routeName,
          arguments: context,
        ),
      MenuTabInfo.leaderbaord => navigator.pushReplacementNamed(
          Leaderboard.routeName,
          arguments: context,
        ),
      MenuTabInfo.settings => navigator.pushReplacementNamed(
          Settings.routeName,
          arguments: context,
        ),
      MenuTabInfo.debug => navigator.pushReplacementNamed(
          Debug.routeName,
          arguments: context,
        ),
      MenuTabInfo.island => navigator.pushReplacementNamed(
          Island.routeName,
          arguments: context,
        ),
    };
  }
}
