import 'package:flutter/material.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/island/widgets/community_goal.dart';
import 'package:pushup_bro/features/pro/widgets/just_looking_pill.dart';

class IslandTopBar extends StatelessWidget {
  const IslandTopBar({
    required this.openQuest,
    this.locked = false,
    this.onJustLooking,
    super.key,
  });

  final void Function(QuestType questType) openQuest;

  /// Without Pro, a "Just looking" pill takes the community goal's place.
  final bool locked;
  final VoidCallback? onJustLooking;

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            if (locked)
              JustLookingPill(onTap: onJustLooking)
            else
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
