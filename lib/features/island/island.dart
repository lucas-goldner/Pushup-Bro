import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/island/model/daily_bananas.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/share/island_share_page.dart';
import 'package:pushup_bro/features/island/widgets/game_menu.dart';
import 'package:pushup_bro/features/island/widgets/island_dock.dart';
import 'package:pushup_bro/features/island/widgets/island_scene.dart';
import 'package:pushup_bro/features/island/widgets/island_top_bar.dart';
import 'package:pushup_bro/features/island/widgets/quest_dialog.dart';
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

class _IslandState extends State<Island> {
  bool _menuVisible = false;
  bool _questVisible = false;
  QuestType _quest = QuestType.intro;
  bool _firstTimeVisiting = false;
  bool _isNewDayVisible = false;
  bool _journeying = false;
  final _sceneKey = GlobalKey<IslandSceneState>();

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

  void firstTimeVisiting() {
    setState(() {
      _firstTimeVisiting = false;
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
      _menuVisible = true;
    }
    unawaited(_offerDailyBananas());
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
          Positioned.fill(
            child: IslandScene(
              key: _sceneKey,
              locked: locked,
              onLockedTap: (place) => _guarded(place, () {}),
              onJourneyChanged: (journeying) =>
                  setState(() => _journeying = journeying),
            ),
          ),
          if (locked ? !_journeying : _hudVisible) ...[
            IslandTopBar(
              openQuest: (quest) => _guarded(
                ProLockPlace.jungle,
                () => openQuest(quest),
              ),
              locked: locked,
              onJustLooking: () => showPaywall(context),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: IslandDock(
                    locked: locked,
                    onShop: () => _guarded(ProLockPlace.shop, openMenu),
                    onAccessories: () =>
                        _guarded(ProLockPlace.carlos, openWardrobe),
                    onCarlos: () => _guarded(ProLockPlace.carlos, openWardrobe),
                    onJungle: () => _guarded(ProLockPlace.jungle, _goToJungle),
                    // Free for everyone, like the rest of the social side.
                    onToday: () =>
                        Navigator.of(context).pushNamed(Island.todayRoute),
                    onBros: () =>
                        Navigator.of(context).pushNamed(Island.brosRoute),
                  ),
                ),
              ),
            ),
            // Friends' waves and bananas, and sharing the island.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 68, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ShareIslandButton(onTap: () => openIslandShare(context)),
                    const SizedBox(height: 12),
                    const InboxBanner(),
                  ],
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
            if (_firstTimeVisiting)
              QuestDialog(
                questVisible: _menuVisible,
                onClose: firstTimeVisiting,
                questType: QuestType.intro,
              ),
          ],
        ],
      );
}

/// A round button with the share icon: "Share my island".
class _ShareIslandButton extends StatelessWidget {
  const _ShareIslandButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.l10n.islandShareButton,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: context.cardShadow,
            ),
            child: Icon(
              CarbonIcons.qr_code,
              size: 22,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      );
}
