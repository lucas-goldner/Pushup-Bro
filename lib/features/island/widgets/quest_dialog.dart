import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/quests/community_quest.dart';
import 'package:pushup_bro/features/island/widgets/quests/daily_login.dart';
import 'package:pushup_bro/features/island/widgets/quests/intro_quest.dart';

class QuestDialog extends StatelessWidget {
  const QuestDialog({
    required this.questVisible,
    required this.onClose,
    required this.questType,
    super.key,
  });

  final bool questVisible;
  final VoidCallback onClose;
  final QuestType questType;

  @override
  Widget build(BuildContext context) => Visibility(
        visible: questVisible,
        child: IslandSheet(
          title: questType.getLocalizedTitle(context),
          badge: switch (questType) {
            QuestType.intro => '🏝️',
            QuestType.community => '🤝',
            QuestType.dailyLogin => '🎁',
          },
          accent: switch (questType) {
            QuestType.intro => context.gameColors.ice,
            QuestType.community => context.gameColors.purple,
            QuestType.dailyLogin => context.gameColors.orange,
          },
          // The intro pages through its own story.
          scrollable: questType != QuestType.intro,
          onClose: questType.dismissable ? onClose : null,
          child: switch (questType) {
            QuestType.intro => IntroQuest(onClose: onClose),
            QuestType.community => CommunityQuest(onClose: onClose),
            QuestType.dailyLogin => DailyLogin(onClose: onClose),
          },
        ),
      );
}
