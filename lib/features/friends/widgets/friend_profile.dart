import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/friend.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/minimized_profile.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/core/widgets/profile_image_box.dart';
import 'package:pushup_bro/core/widgets/streak_star.dart';

/// A friend's card; with a shared streak going it grows to show the
/// streak and the challenge button.
class FriendProfile extends StatelessWidget {
  const FriendProfile(this.friend, {super.key});
  final Friend friend;

  @override
  Widget build(BuildContext context) => ProfileCard(
        child: Visibility(
          visible: friend.hasSharedStreakGoing,
          replacement: MinimizedProfile(friend.toMinimizedUser()),
          child: Padding(
            padding: const EdgeInsets.all(PBSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ProfileImageBox(
                      friend.image,
                      size: const Size(64, 64),
                      iconSize: 28,
                    ),
                    const SizedBox(width: PBSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: context.textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              StreakStar(friend.sharedStreak),
                              const SizedBox(width: PBSpace.sm),
                              Flexible(
                                child: Text(
                                  context.l10n.sharedStreak,
                                  style: context.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PBSpace.lg),
                PBButton(
                  friend.hasSharedStreakGoing
                      ? context.l10n.acceptChallenge
                      : context.l10n.sendChallenge,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      );
}
