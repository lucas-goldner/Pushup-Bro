import 'package:circular_clip_route/circular_clip_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/features/debug/debug.dart';
import 'package:pushup_bro/features/friends/friends.dart';
import 'package:pushup_bro/features/island/island.dart';
import 'package:pushup_bro/features/jungle/jungle.dart';
import 'package:pushup_bro/features/leaderboard/leaderboard.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';
import 'package:pushup_bro/features/menu/widgets/page_container.dart';
import 'package:pushup_bro/features/progress/progress.dart';
import 'package:pushup_bro/features/pushup_tracking/pushup_tracking.dart';
import 'package:pushup_bro/features/settings/settings.dart';
import 'package:pushup_bro/features/settings/view/settings_language.dart';
import 'package:pushup_bro/features/settings/view/settings_volume.dart';

Route<CupertinoPageRoute<Widget>> generateRoutes(
  RouteSettings settings,
) =>
    switch (settings.name) {
      PushupTracking.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            PushupTracking(),
            menuTab: MenuTabInfo.pushupTracking,
          ),
        ),
      Progress.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            Progress(),
            menuTab: MenuTabInfo.progress,
          ),
        ),
      Friends.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          PageContainer(
            Friends(),
            menuTab: MenuTabInfo.friends,
          ),
        ),
      Leaderboard.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            Leaderboard(),
            menuTab: MenuTabInfo.leaderbaord,
          ),
        ),
      Settings.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            Settings(),
            menuTab: MenuTabInfo.settings,
          ),
        ),
      Island.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            Island(),
            menuTab: MenuTabInfo.island,
            showTitle: false,
          ),
        ),
      Debug.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            Debug(),
            menuTab: MenuTabInfo.debug,
          ),
        ),
      // Carlos has just run in through the jungle's gate: fade in on him.
      Jungle.routeName => PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, _, __) => const Jungle(),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      LanguageSetting.routeName => CupertinoPageRoute(
          builder: (context) => const LanguageSetting(),
        ),
      VolumeSetting.routeName => CupertinoPageRoute(
          builder: (context) => const VolumeSetting(),
        ),
      _ => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            PushupTracking(),
            menuTab: MenuTabInfo.pushupTracking,
          ),
        ),
    };

Route<CupertinoPageRoute<Widget>> navigateToPushupTracking(
  BuildContext context,
) =>
    _revealCircular(
      context,
      const PageContainer(
        PushupTracking(),
        menuTab: MenuTabInfo.pushupTracking,
      ),
    );

Route<CupertinoPageRoute<Widget>> _revealCircular(
  BuildContext? context,
  Widget widget,
) {
  if (context == null) {
    return CupertinoPageRoute(
      builder: (context) => widget,
    );
  }

  return CircularClipRoute(
    expandFrom: context,
    builder: (_) => widget,
  );
}
