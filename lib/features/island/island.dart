import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/fold_safe.dart';
import 'package:pushup_bro/features/island/intro/island_intro.dart';
import 'package:pushup_bro/features/island/model/daily_bananas.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/share/island_share_page.dart';
import 'package:pushup_bro/features/island/widgets/bros_bubble.dart';
import 'package:pushup_bro/features/island/widgets/game_menu.dart';
import 'package:pushup_bro/features/island/widgets/island_dock.dart';
import 'package:pushup_bro/features/island/widgets/island_scene.dart';
import 'package:pushup_bro/features/island/widgets/island_top_bar.dart';
import 'package:pushup_bro/features/island/widgets/quest_dialog.dart';
import 'package:pushup_bro/features/menu/widgets/menu_circle_button.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pro/pro_access.dart';
import 'package:pushup_bro/features/social/account/upgrade_sheet.dart';
import 'package:pushup_bro/features/social/widgets/inbox_banner.dart';
import 'package:pushup_bro/features/wardrobe/wardrobe.dart';

class Island extends StatefulWidget {
  const Island({super.key});
  static const routeName = '/island';

  /// Today's leaderboard and the bros, opened from the dock.
  static const todayRoute = '/island/today';
  static const brosRoute = '/island/bros';

  @override
  State<Island> createState() => _IslandState();
}

class _IslandState extends State<Island> with TickerProviderStateMixin {
  bool _menuVisible = false;
  bool _questVisible = false;
  QuestType _quest = QuestType.intro;
  bool _firstTimeVisiting = false;
  bool _isNewDayVisible = false;
  bool _journeying = false;
  final _sceneKey = GlobalKey<IslandSceneState>();

  /// The first visit: the intro film plays, then the camera zooms out from
  /// Carlos to the island, then the welcome card asks to help him.
  bool _film = false;
  bool _welcomeCard = false;
  late final AnimationController _introZoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
    value: 1,
  );

  /// White over the island while it loads after the film.
  late final AnimationController _introWhite = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 0,
  );

  /// Whether the island is view only (no Pro, free days over).
  bool _locked(ProState state) =>
      !state.hasAccess(context.read<ProCubit>().now);

  /// Runs [action] once the player may use [place]; without Pro, its lock
  /// sheet comes first.
  Future<void> _guarded(ProLockPlace place, VoidCallback action) async {
    if (!await ensureProAccess(context, place: place)) return;
    if (mounted) action();
  }

  void openMenu() => setState(() => _menuVisible = true);

  void openWardrobe() => Navigator.of(context).pushNamed(Wardrobe.routeName);

  void _goToJungle() => _sceneKey.currentState?.goToJungle();

  void closeMenu() => setState(() {
        _menuVisible = false;
      });

  void openQuest(QuestType questType) => setState(() {
        _quest = questType;
        _questVisible = true;
      });

  void closeQuest() => setState(() {
        _questVisible = false;
      });

  void closeDailyLogin() => setState(() {
        _isNewDayVisible = false;
      });

  /// After the film: the island fades in close on Carlos, he waves, and
  /// the camera pulls back to show the whole island.
  Future<void> _afterFilm() async {
    final hello = context.l10n.greet2;
    _introWhite.value = 1;
    _introZoom.value = 1;
    setState(() => _film = false);
    // Give the island's scene a moment to load under the white.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _introWhite.reverse();
    if (!mounted) return;
    _sceneKey.currentState?.waveHello(hello);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await _introZoom.animateTo(0, curve: Curves.easeInOutCubic);
    if (mounted) setState(() => _welcomeCard = true);
  }

  void firstTimeVisiting() {
    setState(() {
      _firstTimeVisiting = false;
      _welcomeCard = false;
      _menuVisible = false;
    });
    unawaited(
      context
          .read<SharedPreferencesCubit>()
          .setFirstTimeIslandVisited(isFirstVisit: false),
    );
    unawaited(context.read<GameInventoryCubit>().createInventory());
  }

  @override
  void initState() {
    super.initState();
    _firstTimeVisiting =
        context.read<SharedPreferencesCubit>().state.firstTimeIslandVisited ??
            true;

    if (_firstTimeVisiting) {
      _film = true;
    } else {
      _introZoom.value = 0;
    }
    unawaited(_offerDailyBananas());
  }

  @override
  void dispose() {
    _introZoom.dispose();
    _introWhite.dispose();
    super.dispose();
  }

  /// Opens the daily gift only when today's bananas are still to claim.
  Future<void> _offerDailyBananas() async {
    final available = await DailyBananas().available();
    if (available && mounted) setState(() => _isNewDayVisible = true);
  }

  bool get _hudVisible =>
      !_firstTimeVisiting &&
      !_menuVisible &&
      !_isNewDayVisible &&
      !_questVisible &&
      !_journeying;

  @override
  Widget build(BuildContext context) => BlocBuilder<ProCubit, ProState>(
        builder: (context, pro) => _island(context, locked: _locked(pro)),
      );

  /// Locked, the island stays to look at: the HUD shows with locks and
  /// the intro, daily login, shop and quests wait until it's unlocked.
  Widget _island(BuildContext context, {required bool locked}) => Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [islandSky(context).top, islandSky(context).horizon],
                  stops: const [0, 0.55],
                ),
              ),
            ),
          ),
          // The film plays on its own stage; the island waits behind it.
          if (!_film || locked)
            Positioned.fill(
              child: IslandScene(
                key: _sceneKey,
                intro: locked ? null : _introZoom,
                locked: locked,
                onLockedTap: (place) => _guarded(place, () {}),
                onJourneyChanged: (journeying) =>
                    setState(() => _journeying = journeying),
              ),
            ),
          if (locked ? !_journeying : _hudVisible) ...[
            FoldSafe(
              anchor: const Offset(double.maxFinite, 0),
              alignment: Alignment.topCenter,
              child: IslandTopBar(
                openQuest: (quest) => _guarded(
                  ProLockPlace.jungle,
                  () => openQuest(quest),
                ),
                locked: locked,
                onJustLooking: () => showPaywall(context),
              ),
            ),
            // On a half-open iPhone Duo, in the half by the thumb and off
            // the fold; never wider than a phone's.
            FoldSafe(
              maxWidth: 560,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // The bros, free for everyone like the rest of the
                        // social side.
                        BrosBubble(
                          onTap: () => Navigator.of(context)
                              .pushNamed(Island.todayRoute),
                        ),
                        const SizedBox(height: 12),
                        IslandDock(
                          locked: locked,
                          onShop: () => _guarded(ProLockPlace.shop, openMenu),
                          onCarlos: () =>
                              _guarded(ProLockPlace.carlos, openWardrobe),
                          onJungle: () =>
                              _guarded(ProLockPlace.jungle, _goToJungle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Sharing the island, right under the menu button.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 60),
                child: Semantics(
                  label: context.l10n.islandShareButton,
                  child: MenuCircleButton(
                    icon: CarbonIcons.qr_code,
                    onTap: () => openIslandShare(context),
                  ),
                ),
              ),
            ),
            // Friends' waves and bananas, under the top row.
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(76, 64, 12, 0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: InboxBanner(),
                ),
              ),
            ),
            const AccountUpgradePrompt(),
          ],
          if (locked)
            const SizedBox.shrink()
          else ...[
            GameMenu(
              closeMenu: closeMenu,
              menuVisible: _menuVisible && !_firstTimeVisiting,
            ),
            if (_questVisible)
              QuestDialog(
                questVisible: _questVisible,
                onClose: closeQuest,
                questType: _quest,
              ),
            if (_isNewDayVisible && !_firstTimeVisiting)
              QuestDialog(
                questVisible: _isNewDayVisible,
                onClose: closeDailyLogin,
                questType: QuestType.dailyLogin,
              ),
            if (_firstTimeVisiting && _welcomeCard)
              QuestDialog(
                questVisible: _welcomeCard,
                onClose: firstTimeVisiting,
                questType: QuestType.intro,
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _introWhite,
                  child: ColoredBox(color: context.gameColors.onGame),
                ),
              ),
            ),
            if (_film)
              Positioned.fill(
                child: IslandIntro(onDone: () => unawaited(_afterFilm())),
              ),
          ],
        ],
      );
}
