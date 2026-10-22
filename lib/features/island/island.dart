import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/game_menu.dart';
import 'package:pushup_bro/features/island/widgets/island_dock.dart';
import 'package:pushup_bro/features/island/widgets/island_scene.dart';
import 'package:pushup_bro/features/island/widgets/island_top_bar.dart';
import 'package:pushup_bro/features/island/widgets/quest_dialog.dart';

class Island extends StatefulWidget {
  const Island({super.key});
  static const routeName = '/island';

  @override
  State<Island> createState() => _IslandState();
}

class _IslandState extends State<Island> {
  bool _menuVisible = false;
  bool _questVisible = false;
  GameMenuType _gameMenuType = GameMenuType.shop;
  QuestType _quest = QuestType.intro;
  bool _firstTimeVisiting = false;
  bool _isNewDayVisible = false;
  bool _journeying = false;
  final _sceneKey = GlobalKey<IslandSceneState>();

  void openMenu(GameMenuType gameMenuType) => setState(() {
        _gameMenuType = gameMenuType;
        _menuVisible = true;
      });

  void closeMenu() => setState(() {
        _menuVisible = false;
      });

  void openQuest({
    required GameMenuType gameMenuType,
    required QuestType questType,
  }) =>
      setState(() {
        _quest = questType;
        _gameMenuType = gameMenuType;
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
    const newDay = true;
    if (newDay) {
      _isNewDayVisible = true;
    }
  }

  bool get _hudVisible =>
      !_firstTimeVisiting &&
      !_menuVisible &&
      !_isNewDayVisible &&
      !_questVisible &&
      !_journeying;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF9CD6F2), islandHorizon],
                  stops: [0, 0.55],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IslandScene(
              key: _sceneKey,
              onJourneyChanged: (journeying) =>
                  setState(() => _journeying = journeying),
            ),
          ),
          if (_hudVisible) ...[
            IslandTopBar(openQuest: openQuest),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: IslandDock(
                    onShop: () => openMenu(GameMenuType.shop),
                    onAccessories: () => openMenu(GameMenuType.accessories),
                    onCarlos: () => openMenu(GameMenuType.monkey),
                    onJungle: () => _sceneKey.currentState?.goToJungle(),
                  ),
                ),
              ),
            ),
          ],
          GameMenu(
            closeMenu: closeMenu,
            menuVisible: _menuVisible && !_firstTimeVisiting,
            menuType: _gameMenuType,
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
      );
}
