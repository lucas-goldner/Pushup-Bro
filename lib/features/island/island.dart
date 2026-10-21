import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/beach_overlay.dart';
import 'package:pushup_bro/features/island/widgets/game_menu.dart';
import 'package:pushup_bro/features/island/widgets/game_objects.dart';
import 'package:pushup_bro/features/island/widgets/grass_overlay.dart';
import 'package:pushup_bro/features/island/widgets/ground.dart';
import 'package:pushup_bro/features/island/widgets/island_top_bar.dart';
import 'package:pushup_bro/features/island/widgets/quest_dialog.dart';
import 'package:pushup_bro/features/island/widgets/walking_monkey.dart';

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

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Ground(),
          GrassOverlay(openQuest),
          const BeachOverlay(),
          WalkingMonkey(
            onMenuOpen: openMenu,
          ),
          GameObjects(
            onMenuOpen: openMenu,
          ),
          GameMenu(
            closeMenu: closeMenu,
            menuVisible: _menuVisible,
            menuType: _gameMenuType,
          ),
          if (!_firstTimeVisiting && !_menuVisible && !_isNewDayVisible)
            IslandTopBar(
              openQuest: openQuest,
            ),
          if (_questVisible)
            QuestDialog(
              questVisible: _questVisible,
              onClose: closeQuest,
              questType: _quest,
            ),
          if (_isNewDayVisible)
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
