import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
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
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned.fill(
              top: context.sizeOf.height * 0.2,
              left: 20,
              right: 20,
              bottom: context.sizeOf.height * 0.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.gameColorsTheme.map,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            top: 20,
                          ),
                          child: Text(
                            questType.getLocalizedTitle(context),
                            style: context.textTheme.bodyLarge,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Expanded(
                      child: switch (questType) {
                        QuestType.intro => IntroQuest(
                            onClose: onClose,
                          ),
                        QuestType.community => CommunityQuest(
                            onClose: onClose,
                          ),
                        QuestType.dailyLogin => DailyLogin(
                            onClose: onClose,
                          ),
                        QuestType.jungleQuest => JungleQuest(
                            onClose: onClose,
                          ),
                        _ => const SizedBox.shrink()
                      },
                    ),
                    if (questType.dismissable)
                      Row(
                        children: [
                          const Spacer(),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: onClose,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    bottom: 20,
                                  ),
                                  child: Text(
                                    'Close',
                                    style: context.textTheme.displaySmall
                                        ?.copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
