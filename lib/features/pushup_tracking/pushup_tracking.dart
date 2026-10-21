import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/cubit/feature_switch_state.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/widgets/monkey.dart';
import 'package:pushup_bro/core/widgets/party_hat_monkey.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/finished_pushup_sheet/finished_set_bottom_sheet.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/news_banner/news_banner.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/pushup_counter.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/pushup_tracking_bottom_row.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/pushup_tracking_top_row.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:rive/rive.dart';

class PushupTracking extends StatefulWidget {
  const PushupTracking({super.key});
  static const String routeName = '/';

  @override
  State<PushupTracking> createState() => _PushupTrackingState();
}

class _PushupTrackingState extends State<PushupTracking> {
  bool finished = false;
  bool started = false;
  bool newsVisible = true;

  void toggleListeningUpdates() {
    final airpodsCubit = BlocProvider.of<AirPodsTrackerCubit>(context);
    final pushupCubit = BlocProvider.of<PushupCubit>(context);

    if (started && pushupCubit.getCurrentPushups() >= 1) {
      airpodsCubit.stopListening();
      final pushups = pushupCubit.resetAndReturnCurrentPushupSet();
      setState(() {
        finished = true;
        started = false;
      });
      unawaited(openBottomSheet(pushups));
    } else {
      airpodsCubit.getAirPodsMotionData();
      if (newsVisible) {
        setState(() => newsVisible = false);
      }
      setState(() {
        finished = false;
        started = true;
      });
    }
  }

  Future<void> openBottomSheet(PushupSet pushups) async {
    // final navigator = Navigator.of(context);
    // final firstPushupCompleted =
    await showCupertinoModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => FinishedSetBottomSheet(pushups),
    );

    // ?? false;
    // TODO(Implement-onboarding): Reenable onboarding and finish feature
    // if (!firstPushupCompleted) {
    //   await navigator.pushNamed(
    //     Onboarding.routeName,
    //     arguments: PushupSet([], 0),
    //   );
    // }
  }

  void toggleNewsVisibility() => setState(() => newsVisible = !newsVisible);

  @override
  void initState() {
    super.initState();
    newsVisible = false;
    unawaited(context.read<NewsCubit>().getNews());
  }

  @override
  void didUpdateWidget(covariant PushupTracking oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: BlocProvider.of<SharedPreferencesCubit>(context).getVolume(),
        builder: (context, future) => Stack(
          children: [
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      PushupTrackingTopRow(
                        toggleNewsVisibility: toggleNewsVisibility,
                      ),
                      const Spacer(
                        flex: 4,
                      ),
                      BlocBuilder<FeatureSwitchCubit, FeatureSwitchState>(
                        builder: (context, state) {
                          if (state is FeatureSwitchStateGamification) {
                            return BlocSelector<GameInventoryCubit,
                                GameInventoryState, AdoptableMonkey>(
                              selector: (state) =>
                                  state.inventory.monkeys.first,
                              builder: (context, monkey) =>
                                  PartyHatMonkey(monkey.accessory),
                            );
                          }

                          return const Monkey();
                        },
                      ),
                      BlocBuilder<AirPodsTrackerCubit, AirPodsTrackerState>(
                        builder: (context, airPodsState) {
                          if (airPodsState.isListening && started) {
                            final pushupCubit =
                                BlocProvider.of<PushupCubit>(context)
                                  ..listenForPushupEvents(
                                    airPodsState.currentMotionData,
                                    future.data ?? 10,
                                  );

                            return PushupCounter(
                              pushupCubit.getCurrentPushups(),
                            );
                          }

                          if (started) {
                            return Text(
                              context.l10n.lookingForAirpods,
                              style: context.textTheme.bodyMedium,
                            );
                          }

                          return const SizedBox();
                        },
                      ),
                      const Spacer(flex: 2),
                      PushupTrackingBottomRow(
                        toggleListeningUpdates: toggleListeningUpdates,
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            NewsBanner(newsVisible: newsVisible),
            if (finished)
              IgnorePointer(
                child: RiveWidgetBuilder(
                  fileLoader: Assets.rive.confetti.riveFileLoader(),
                  builder: (context, state) => switch (state) {
                    RiveLoading() => const SizedBox.shrink(),
                    RiveFailed() => const SizedBox.shrink(),
                    RiveLoaded(:final controller) =>
                      RiveWidget(controller: controller),
                  },
                ),
              ),
          ],
        ),
      );
}
