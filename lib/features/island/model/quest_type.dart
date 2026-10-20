import 'package:flutter/material.dart';

enum QuestType {
  intro(dismissable: false),
  dailyLogin(dismissable: false),
  jungleQuest(dismissable: true),
  community(dismissable: true),
  doubleValue(dismissable: false, canAppearAsJungleQuest: true),
  fastPushups(dismissable: false, canAppearAsJungleQuest: true),
  longPushups(dismissable: false, canAppearAsJungleQuest: true);

  const QuestType({
    required this.dismissable,
    this.canAppearAsJungleQuest = false,
  });

  final bool dismissable;
  final bool canAppearAsJungleQuest;

  String getLocalizedTitle(BuildContext context) => switch (this) {
        intro => 'Intro Quest',
        community => 'Coming together',
        dailyLogin => 'Daily Login',
        jungleQuest => 'Jungle Quest',
        _ => 'Nothingburger',
      };

  List<QuestType> get jungleQuests => QuestType.values
      .where((questType) => questType.canAppearAsJungleQuest)
      .toList();
}
