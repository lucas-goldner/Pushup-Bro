import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

/// What Pushup Bro Pro opens, in the order the paywall's stage shows them.
enum ProFeature {
  trek,
  quests,
  island,
  wardrobe,
  coach,
  widgets;

  IconData get icon => switch (this) {
        trek => CarbonIcons.lightning,
        quests => CarbonIcons.flag,
        island => CarbonIcons.tree,
        wardrobe => CarbonIcons.star,
        coach => CarbonIcons.camera,
        widgets => CarbonIcons.grid,
      };

  Color color(BuildContext context) {
    final game = context.gameColors;

    return switch (this) {
      trek => game.red,
      quests => game.jungle,
      island => game.ice,
      wardrobe => game.orange,
      coach => game.leaf,
      widgets => game.purple,
    };
  }

  String label(BuildContext context) {
    final l = context.l10n;

    return switch (this) {
      trek => l.proFeatureTrek,
      quests => l.proFeatureQuests,
      island => l.proFeatureIsland,
      wardrobe => l.proFeatureWardrobe,
      coach => l.proFeatureCoach,
      widgets => l.proFeatureWidgets,
    };
  }

  String caption(BuildContext context) {
    final l = context.l10n;

    return switch (this) {
      trek => l.proCaptionTrek,
      quests => l.proCaptionQuests,
      island => l.proCaptionIsland,
      wardrobe => l.proCaptionWardrobe,
      coach => l.proCaptionCoach,
      widgets => l.proCaptionWidgets,
    };
  }
}

/// The places on Monkey Island that are locked without Pro, each with its
/// own lock sheet.
enum ProLockPlace { jungle, shop, carlos }
