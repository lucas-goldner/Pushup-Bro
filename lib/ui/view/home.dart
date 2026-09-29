import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pushup_bro/cubit/airpods_tracker/airpods_tracker_cubit.dart';
import 'package:pushup_bro/cubit/airpods_tracker/airpods_tracker_state.dart';
import 'package:pushup_bro/cubit/pushups/pushup_cubit.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_cubit.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/ui/widgets/home/finished_set_bottom_sheet.dart';
import 'package:pushup_bro/ui/widgets/home/monkey.dart';
import 'package:pushup_bro/ui/widgets/home/pushup_counter.dart';
import 'package:pushup_bro/ui/widgets/home/start_pushups_button.dart';
import 'package:rive/rive.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  static const routeName = '/';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool finished = false;
  bool started = false;

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
      setState(() {
        finished = false;
        started = true;
      });
    }
  }

  Future<void> openBottomSheet(PushupSet pushups) async {
    // final navigator =
    Navigator.of(context);
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

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: BlocProvider.of<SharedPreferencesCubit>(context).getVolume(),
        builder: (context, future) => Stack(
          children: [
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Spacer(),
                        const Monkey(),
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
                              return Text(S.of(context).lookingForAirpods);
                            }

                            return const SizedBox();
                          },
                        ),
                        const Spacer(),
                        StartPushupsButton(
                          toggleListeningUpdates,
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
