import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/widgets/minimized_profile.dart';

class LeaderboardProfile extends StatelessWidget {
  const LeaderboardProfile({
    required this.user,
    required this.ranking,
    super.key,
  });
  final User user;
  final int ranking;

  @override
  Widget build(BuildContext context) => MinimizedProfile(
        user.toMinimizedUser(),
        leadingItem: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '#$ranking',
                style: context.textTheme.bodyLarge,
              ),
              Text(
                context.l10n.level(user.level),
                style: context.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
}
