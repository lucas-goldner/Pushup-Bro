import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/friend.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/friends/widgets/friend_profile.dart';

class Friends extends StatelessWidget {
  Friends({super.key});
  static const routeName = '/friends';

  final List<Friend> friends = [
    Friend(
      id: '1',
      name: 'Friend 1',
      image: 'https://picsum.photos/200',
      streak: 12,
      sharedStreak: 1,
    ),
    Friend(
      id: '2',
      name: 'Friend 2',
      image: 'https://picsum.photos/200',
      streak: 3,
      sharedStreak: 20,
    ),
    ...List.generate(
      8,
      (index) => Friend(id: '$index', name: 'Friend $index'),
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 64),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  PBSpace.lg,
                  PBSpace.sm,
                  PBSpace.lg,
                  PBSpace.xxl,
                ),
                children: [
                  _SectionTitle(context.l10n.openChallenges(2)),
                  ...friends.take(2).map(
                        (friend) => Padding(
                          padding: const EdgeInsets.only(bottom: PBSpace.md),
                          child: FriendProfile(friend),
                        ),
                      ),
                  const SizedBox(height: PBSpace.lg),
                  _SectionTitle(context.l10n.friends),
                  ...friends.skip(2).map(
                        (friend) => Padding(
                          padding: const EdgeInsets.only(bottom: PBSpace.md),
                          child: FriendProfile(friend),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PBSpace.xs,
          PBSpace.lg,
          PBSpace.xs,
          PBSpace.md,
        ),
        child: Text(title, style: context.textTheme.headlineSmall),
      );
}
