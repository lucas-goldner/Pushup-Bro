import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/progress/widgets/last_seven_day_pushups.dart';
import 'package:pushup_bro/features/progress/widgets/profile.dart';

class Progress extends StatefulWidget {
  const Progress({super.key});
  static const String routeName = '/progress';

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  int selectedTab = 0;

  final List<User> leaderBoardUsers = [
    ...List.generate(
      100,
      (index) => User(
        name: 'User $index',
        image: 'https://picsum.photos/200',
        streak: 0,
        longestStreak: 0,
        friends: [],
        level: 0,
        xp: index,
      ),
    ),
  ];

  void changeTab(int index) => setState(() => selectedTab = index);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: BlocProvider.of<DBCubit>(context).getUser(),
        builder: (context, snapshot) {
          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const Profile(name: 'Your name', imageUrl: ''),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      PBButton.icon(
                        context.l10n.shareProfile,
                        icon: CarbonIcons.share,
                        callback: () => {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Expanded(child: LastSevenDayPushups()),
                ],
              ),
            ),
          );
        },
      );
}
