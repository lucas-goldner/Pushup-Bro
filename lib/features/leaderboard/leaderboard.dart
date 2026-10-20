import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/extensions/list_ext.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/features/leaderboard/widgets/leaderboard_profile.dart';

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});
  static const routeName = '/leaderboard';

  @override
  Widget build(BuildContext context) {
    final user = context.read<DBCubit>().state.user;

    final leaderBoardUsers = <User>[
      ...List.generate(
        100,
        (index) => User(
          name: 'User $index',
          image: '',
          streak: 0,
          longestStreak: 0,
          level: math.Random().nextInt(10),
          xp: 0,
          friends: [],
        ),
      ),
      user.copyWith(name: 'YOU'),
    ]..sort((a, b) => b.level.compareTo(a.level));

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Column(
          children: [
            const SizedBox(height: 64),
            const SearchBar(
              hintText: 'Search',
            ),
            Flexible(
              child: ListView(
                children: [
                  ...leaderBoardUsers.mapIndexed(
                    (index, user) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: LeaderboardProfile(
                            user: user,
                            ranking: index + 1,
                          ),
                        ),
                        const Divider(
                          indent: 60,
                          endIndent: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
