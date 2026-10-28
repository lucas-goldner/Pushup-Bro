import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/db_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/profile_image_box.dart';
import 'package:pushup_bro/core/widgets/streak_star.dart';
import 'package:pushup_bro/features/progress/widgets/level_bar.dart';

/// The learner's card: avatar, name, streak and level.
class Profile extends StatelessWidget {
  const Profile({
    required this.name,
    required this.imageUrl,
    super.key,
  });

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) => BlocSelector<DBCubit, DBState, User>(
        selector: (state) => state.user,
        builder: (context, user) => Container(
          padding: const EdgeInsets.all(PBSpace.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PBRadius.lg),
            color: context.colorScheme.surface,
            boxShadow: context.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ProfileImageBox(
                    imageUrl,
                    size: const Size(72, 72),
                    iconSize: 32,
                  ),
                  const SizedBox(width: PBSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: context.textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const StreakStar(2),
                            const SizedBox(width: PBSpace.sm),
                            Flexible(
                              child: Text(
                                context.l10n.dayStreak,
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
              const SizedBox(height: PBSpace.xl),
              LevelBar(level: user.level, experience: user.xp),
            ],
          ),
        ),
      );
}
