import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/minimized_profile.dart';

/// A ranked person: their card with the level and a rank chip; the top
/// three rank in banana.
class LeaderboardProfile extends StatelessWidget {
  const LeaderboardProfile({
    required this.user,
    required this.ranking,
    this.highlight = false,
    super.key,
  });
  final User user;
  final int ranking;

  /// The learner's own row.
  final bool highlight;

  @override
  Widget build(BuildContext context) => ProfileCard(
        highlight: highlight ? context.colorScheme.secondary : null,
        child: MinimizedProfile(
          user.toMinimizedUser(),
          subtitle: context.l10n.level(user.level),
          leadingItem: SheetTag(
            '#$ranking',
            color: ranking <= 3
                ? context.gameColors.orange
                : context.colorScheme.secondary,
          ),
        ),
      );
}
