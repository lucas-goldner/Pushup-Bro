import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/notices/free_days_sheets.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';

class Debug extends StatefulWidget {
  const Debug({super.key});
  static const routeName = '/debug';

  @override
  State<Debug> createState() => _DebugState();
}

class _DebugState extends State<Debug> {
  /// A set of 5 to 44 pushups, one every 2 seconds, at a random time in
  /// the last 60 days: something for the stats page to show.
  Future<void> addPushups() async {
    final random = math.Random();
    final start = DateTime.now().subtract(
      Duration(minutes: random.nextInt(60 * 24 * 60)),
    );
    final pushupSet = PushupSet(
      List<Pushup>.generate(
        5 + random.nextInt(40),
        (index) => Pushup(completedAt: start.add(Duration(seconds: 2 * index))),
      ),
      1 + random.nextInt(5),
    );

    await context.read<DBCubit>().writeNewPushupsetToDB(pushupSet);
  }

  Future<void> resetPushups() async {
    final dbCubit = context.read<DBCubit>();
    final pushups = await context.read<DBCubit>().getAllPushupSets();
    final pushupIds = pushups.map((e) => e.id).toList();
    for (final id in pushupIds) {
      await dbCubit.deletePushupSetFromDB(id);
    }
  }

  Future<void> wiperUser() => context.read<DBCubit>().wipeUser();

  /// Shows the island's intro film again on the next visit.
  Future<void> replayIslandIntro() => context
      .read<SharedPreferencesCubit>()
      .setFirstTimeIslandVisited(isFirstVisit: true);

  void add100Bananas() => context.read<GameInventoryCubit>().updateInventory(
        context.read<GameInventoryCubit>().state.inventory.copyWith(
              bananas:
                  context.read<GameInventoryCubit>().state.inventory.bananas +
                      100,
            ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PBSpace.lg,
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: PBSpace.xxl),
            children: [
              const SizedBox(height: 64),
              Text(
                'Pushups Debug',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Add pushups',
                callback: addPushups,
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Reset pushups',
                callback: resetPushups,
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Wiper user',
                callback: wiperUser,
                expanded: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Gamification Debug',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Add 100 Bananas',
                callback: add100Bananas,
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Replay island intro',
                callback: replayIslandIntro,
                expanded: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Pushup Bro Pro Debug',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              BlocSelector<ProCubit, ProState, bool>(
                selector: (state) => state.simulateLocked,
                builder: (context, locked) => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Simulate free days over',
                    style: context.textTheme.titleSmall,
                  ),
                  value: locked,
                  onChanged: (value) =>
                      context.read<ProCubit>().simulateLocked(locked: value),
                ),
              ),
              const SizedBox(height: 12),
              PBButton(
                'Show paywall',
                callback: () => showPaywall(context),
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Show free days welcome',
                callback: () async {
                  final pro = context.read<ProCubit>();
                  await showFreeDaysWelcome(
                    context,
                    freeSince: pro.state.freeSince ?? pro.now,
                    now: pro.now,
                  );
                },
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Show last free day',
                callback: () async {
                  if (await showLastFreeDay(
                        context,
                        left: const Duration(hours: 9),
                      ) &&
                      context.mounted) {
                    await showPaywall(context);
                  }
                },
                expanded: true,
              ),
            ],
          ),
        ),
      );
}
