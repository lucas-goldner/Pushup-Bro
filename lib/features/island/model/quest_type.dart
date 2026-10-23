import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

/// The island's quest sheets. The jungle's daily quests live in
/// `features/jungle/model/jungle_quest.dart`.
enum QuestType {
  intro(dismissable: false),
  dailyLogin(dismissable: false),
  community(dismissable: true);

  const QuestType({required this.dismissable});

  final bool dismissable;

  String getLocalizedTitle(BuildContext context) => switch (this) {
        intro => context.l10n.questIntroTitle,
        community => context.l10n.questCommunityTitle,
        dailyLogin => context.l10n.questDailyTitle,
      };
}
