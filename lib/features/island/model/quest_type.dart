import 'package:flutter/material.dart';

/// The island's quest sheets. The jungle's daily quests live in
/// `features/jungle/model/jungle_quest.dart`.
enum QuestType {
  intro(dismissable: false),
  dailyLogin(dismissable: false),
  community(dismissable: true);

  const QuestType({required this.dismissable});

  final bool dismissable;

  String getLocalizedTitle(BuildContext context) => switch (this) {
        intro => 'Welcome to the island',
        community => 'Coming together',
        dailyLogin => 'Daily bananas',
      };
}
