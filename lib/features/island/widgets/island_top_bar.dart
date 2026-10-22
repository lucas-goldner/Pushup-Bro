import 'package:flutter/material.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/island/widgets/community_goal.dart';

class IslandTopBar extends StatelessWidget {
  const IslandTopBar({
    required this.openQuest,
    super.key,
  });

  final void Function(QuestType questType) openQuest;

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            CommunityGoal(
              openMenu: () => openQuest(QuestType.community),
            ),
            const SizedBox(width: 8),
            const BananaCounter(),
            const SizedBox(width: 12),
          ],
        ),
      );
}
