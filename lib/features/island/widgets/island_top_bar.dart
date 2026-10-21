import 'package:flutter/material.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/island/widgets/community_goal.dart';

class IslandTopBar extends StatelessWidget {
  const IslandTopBar({
    required this.openQuest,
    super.key,
  });

  final void Function({
    required GameMenuType gameMenuType,
    required QuestType questType,
  }) openQuest;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Row(
          children: [
            const Spacer(),
            CommunityGoal(
              openMenu: () => openQuest(
                gameMenuType: GameMenuType.quest,
                questType: QuestType.community,
              ),
            ),
            const SizedBox(width: 8),
            const BananaCounter(),
            const SizedBox(width: 16),
          ],
        ),
      );
}
