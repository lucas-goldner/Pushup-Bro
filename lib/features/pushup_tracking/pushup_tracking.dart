import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/finished_pushup_sheet/finished_set_bottom_sheet.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/news_banner/news_banner.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/pushup_counter.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/pushup_stage.dart';
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
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFDDE6FF), background],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BlocSelector<GameInventoryCubit, GameInventoryState,
                  AdoptableMonkey>(
                selector: (state) => state.inventory.monkeys.first,
                builder: (context, monkey) => PushupStage(
                  tracking: started,
                  partyHat: monkey.accessory == ShopBuyables.accessoryPartyHat,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  PushupTrackingTopRow(
                    toggleNewsVisibility: toggleNewsVisibility,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 140,
                    // Counting happens in the listener, which sees every
                    // motion sample; a builder only sees the one that is
                    // current when a frame is drawn, and would miss reps
                    // whenever a frame takes longer than a sample.
                    child:
                        BlocConsumer<AirPodsTrackerCubit, AirPodsTrackerState>(
                      listener: (context, airPodsState) {
                        if (airPodsState.isListening && started) {
                          context.read<PushupCubit>().listenForPushupEvents(
                                airPodsState.currentMotionData,
                                future.data ?? 10,
                              );
                        }
                      },
                      buildWhen: (previous, current) =>
                          previous.isListening != current.isListening,
                      builder: (context, airPodsState) {
                        if (airPodsState.isListening && started) {
                          return BlocSelector<PushupCubit, PushupState, int>(
                            selector: (state) => state.pushups.length,
                            builder: (context, pushups) =>
                                PushupCounter(pushups),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            started
                                ? context.l10n.lookingForAirpods
                                : context.l10n.readyCaption,
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: primaryColor.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  PushupTrackingBottomRow(
                    toggleListeningUpdates: toggleListeningUpdates,
                  ),
                  const SizedBox(height: 32),
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
