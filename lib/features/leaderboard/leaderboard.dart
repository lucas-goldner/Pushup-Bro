import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/extensions/list_ext.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
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
      child: Column(
        children: [
          const SizedBox(height: 64),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: PBSpace.lg),
            child: SearchBar(
              hintText: 'Search',
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.lg,
                PBSpace.lg,
                PBSpace.lg,
                PBSpace.xxl,
              ),
              children: [
                ...leaderBoardUsers.mapIndexed(
                  (index, user) => Padding(
                    padding: const EdgeInsets.only(bottom: PBSpace.md),
                    child: LeaderboardProfile(
                      user: user,
                      ranking: index + 1,
                      highlight: user.name == 'YOU',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
