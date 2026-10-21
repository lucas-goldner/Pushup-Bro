import 'package:flutter/material.dart';
import 'package:pushup_bro/core/widgets/sheet_panel.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/quests/community_quest.dart';
import 'package:pushup_bro/features/island/widgets/quests/daily_login.dart';
import 'package:pushup_bro/features/island/widgets/quests/intro_quest.dart';
import 'package:pushup_bro/features/island/widgets/quests/jungle_quest.dart';

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
        child: SheetPanel(
          title: questType.getLocalizedTitle(context),
          onClose: questType.dismissable ? onClose : null,
          child: switch (questType) {
            QuestType.intro => IntroQuest(onClose: onClose),
            QuestType.community => CommunityQuest(onClose: onClose),
            QuestType.dailyLogin => DailyLogin(onClose: onClose),
            QuestType.jungleQuest => JungleQuest(onClose: onClose),
            _ => const SizedBox.shrink(),
          },
        ),
      );
}
