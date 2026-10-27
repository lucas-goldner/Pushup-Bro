import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/booster_item_cubit.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/cubit/feature_switch_state.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/booster_items.dart';
import 'package:pushup_bro/core/model/feature_variants.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';

class Debug extends StatefulWidget {
  const Debug({super.key});
  static const routeName = '/debug';

  @override
  State<Debug> createState() => _DebugState();
}

class _DebugState extends State<Debug> {
  Future<void> addPushups() async {
    final pushupSet = PushupSet(
      List<Pushup>.generate(
        math.Random().nextInt(40),
        (index) => Pushup(
          completedAt: DateTime(
            2024,
            math.Random().nextInt(12),
            math.Random().nextInt(30),
          ),
        ),
      ),
      math.Random().nextInt(5),
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

  void addBoosterItem() => context.read<BoosterItemCubit>().addItems(
        item: BoosterItems.doublePoints,
        amount: 1,
      );

  void addFriendShareItem() => context.read<BoosterItemCubit>().addItems(
        item: BoosterItems.friendBoost,
        amount: 1,
      );

  void add100Bananas() => context.read<GameInventoryCubit>().updateInventory(
        context.read<GameInventoryCubit>().state.inventory.copyWith(
              bananas:
                  context.read<GameInventoryCubit>().state.inventory.bananas +
                      100,
            ),
      );

  void switchToHookModel() => context.read<FeatureSwitchCubit>().switchFeature(
        FeatureVariants.hookmodel,
      );

  Future<void> switchToGamified() async {
    final sharedPrefsCubit = context.read<SharedPreferencesCubit>();
    final featuredSwitchCubit = context.read<FeatureSwitchCubit>();

    await sharedPrefsCubit.setFirstTimeIslandVisited(isFirstVisit: true);
    featuredSwitchCubit.switchFeature(
      FeatureVariants.gamification,
    );
  }

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
                'General App Debug',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              BlocBuilder<FeatureSwitchCubit, FeatureSwitchState>(
                builder: (context, state) => Text(
                  'Current app ${state.featureVariant.name}',
                  style: context.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              PBButton(
                'Switch to hook model',
                callback: switchToHookModel,
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Switch to gamified app',
                callback: switchToGamified,
                expanded: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Hook Model Debug',
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
              const SizedBox(height: 12),
              PBButton(
                'Add Booster Item',
                callback: addBoosterItem,
                expanded: true,
              ),
              const SizedBox(height: 12),
              PBButton(
                'Add Friendshare Item',
                callback: addFriendShareItem,
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
            ],
          ),
        ),
      );
}
