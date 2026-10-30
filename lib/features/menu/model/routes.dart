import 'package:circular_clip_route/circular_clip_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/audio/music_scope.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/debug/debug.dart';
import 'package:pushup_bro/features/friends/add_bro_page.dart';
import 'package:pushup_bro/features/friends/bros_added_page.dart';
import 'package:pushup_bro/features/friends/friends.dart';
import 'package:pushup_bro/features/island/island.dart';
import 'package:pushup_bro/features/island/share/island_share_page.dart';
import 'package:pushup_bro/features/island/visit/island_visit_page.dart';
import 'package:pushup_bro/features/island/widgets/island_subpage.dart';
import 'package:pushup_bro/features/jungle/jungle.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/leaderboard/leaderboard.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';
import 'package:pushup_bro/features/menu/widgets/page_container.dart';
import 'package:pushup_bro/features/onboarding/onboarding_gate.dart';
import 'package:pushup_bro/features/progress/progress.dart';
import 'package:pushup_bro/features/pushup_tracking/pushup_tracking.dart';
import 'package:pushup_bro/features/quest/quest_page.dart';
import 'package:pushup_bro/features/settings/settings.dart';
import 'package:pushup_bro/features/settings/view/settings_body.dart';
import 'package:pushup_bro/features/settings/view/settings_language.dart';
import 'package:pushup_bro/features/settings/view/settings_volume.dart';
import 'package:pushup_bro/features/social/account/account_page.dart';
import 'package:pushup_bro/features/social/account/restore_page.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_map_page.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';
import 'package:pushup_bro/features/wardrobe/wardrobe.dart';

/// The app's navigator, for opening screens from outside the widget tree
/// (a tapped push notification).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey();

Route<CupertinoPageRoute<Widget>> generateRoutes(
  RouteSettings settings,
) =>
    switch (settings.name) {
      PushupTracking.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const MusicScope(
            track: MusicTrack.home,
            child: PageContainer(
              PushupTracking(),
              menuTab: MenuTabInfo.pushupTracking,
              overScene: true,
            ),
          ),
        ),
      Progress.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const MusicScope(
            track: MusicTrack.home,
            child: PageContainer(
              Progress(),
              menuTab: MenuTabInfo.progress,
            ),
          ),
        ),
      Friends.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const PageContainer(
            Friends(),
            menuTab: MenuTabInfo.friends,
          ),
        ),
      Leaderboard.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const MusicScope(
            track: MusicTrack.home,
            child: PageContainer(
              Leaderboard(),
              menuTab: MenuTabInfo.leaderbaord,
            ),
          ),
        ),
      Settings.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const MusicScope(
            track: MusicTrack.home,
            child: PageContainer(
              Settings(),
              menuTab: MenuTabInfo.settings,
            ),
          ),
        ),
      Island.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const MusicScope(
            track: MusicTrack.island,
            child: PageContainer(
              Island(),
              menuTab: MenuTabInfo.island,
              showTitle: false,
            ),
          ),
        ),
      Debug.routeName => _revealCircular(
          settings.arguments as BuildContext?,
          const MusicScope(
            track: MusicTrack.home,
            child: PageContainer(
              Debug(),
              menuTab: MenuTabInfo.debug,
            ),
          ),
        ),
      // The island and the jungle fade through white themselves, so the
      // routes swap in an instant while the screen is white.
      Jungle.routeName => PageRouteBuilder(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, __) => const MusicScope(
            track: MusicTrack.jungle,
            child: Jungle(),
          ),
        ),
      QuestPage.routeName => PageRouteBuilder(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, __) {
            final (quest, replay) = settings.arguments! as (JungleQuest, bool);

            return MusicScope(
              track: MusicTrack.story,
              child: QuestPage(quest: quest, replay: replay),
            );
          },
        ),
      TrekMapPage.routeName => PageRouteBuilder(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, __) => const MusicScope(
            track: MusicTrack.story,
            child: TrekMapPage(),
          ),
        ),
      TrekStagePage.routeName => PageRouteBuilder(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, __) => MusicScope(
            track: MusicTrack.story,
            child: TrekStagePage(stage: settings.arguments! as TrekStage),
          ),
        ),
      Wardrobe.routeName => CupertinoPageRoute(
          settings: settings,
          builder: (context) => const Wardrobe(),
        ),
      LanguageSetting.routeName => CupertinoPageRoute(
          builder: (context) => const LanguageSetting(),
        ),
      VolumeSetting.routeName => CupertinoPageRoute(
          builder: (context) => const VolumeSetting(),
        ),
      BodySetting.routeName => CupertinoPageRoute(
          builder: (context) => const BodySetting(),
        ),
      AccountPage.routeName => CupertinoPageRoute(
          settings: settings,
          builder: (context) => const AccountPage(),
        ),
      RestorePage.routeName => CupertinoPageRoute(
          settings: settings,
          fullscreenDialog: true,
          builder: (context) => const RestorePage(),
        ),
      AddBroPage.routeName => CupertinoPageRoute(
          settings: settings,
          builder: (context) => AddBroPage(code: settings.arguments as String?),
        ),
      BrosAddedPage.routeName => CupertinoPageRoute(
          settings: settings,
          builder: (context) {
            final (friend, name) = settings.arguments! as (BroProfile, String);
            return BrosAddedPage(friend: friend, name: name);
          },
        ),
      // Today and Bros from the island's dock, with a way back to it.
      Island.todayRoute => CupertinoPageRoute(
          settings: settings,
          builder: (context) => MusicScope(
            track: MusicTrack.home,
            child: IslandSubpage(
              title: context.l10n.leaderboard,
              child: const Leaderboard(),
            ),
          ),
        ),
      Island.brosRoute => CupertinoPageRoute(
          settings: settings,
          builder: (context) => IslandSubpage(
            title: context.l10n.friends,
            child: const Friends(),
          ),
        ),
      IslandVisitPage.routeName => CupertinoPageRoute(
          settings: settings,
          builder: (context) => MusicScope(
            track: MusicTrack.home,
            child: IslandVisitPage(uid: settings.arguments! as String),
          ),
        ),
      IslandSharePage.routeName => PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, _, __) => const IslandSharePage(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      // A friend's QR (or link) opened the app: add them.
      final String name when name.startsWith('/pb/') => CupertinoPageRoute(
          settings: settings,
          builder: (context) => AddBroPage(code: FriendCode.normalize(name)),
        ),
      // The app's start: the onboarding first, once.
      _ => _revealCircular(
          settings.arguments as BuildContext?,
          const OnboardingGate(
            child: MusicScope(
              track: MusicTrack.home,
              child: PageContainer(
                PushupTracking(),
                menuTab: MenuTabInfo.pushupTracking,
              ),
            ),
          ),
        ),
    };

Route<CupertinoPageRoute<Widget>> navigateToPushupTracking(
  BuildContext context,
) =>
    _revealCircular(
      context,
      const MusicScope(
        track: MusicTrack.home,
        child: PageContainer(
          PushupTracking(),
          menuTab: MenuTabInfo.pushupTracking,
        ),
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
