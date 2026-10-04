import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/cubit/db/db_cubit.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_cubit.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/pushup_set.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/common/pb_button.dart';
import 'package:pushup_bro/ui/widgets/home/finished_set_stats_item.dart';

class FinishedSetBottomSheet extends StatefulWidget {
  const FinishedSetBottomSheet(this.pushupSet, {super.key});
  final PushupSet pushupSet;

  @override
  State<FinishedSetBottomSheet> createState() => _FinishedSetBottomSheetState();
}

class _FinishedSetBottomSheetState extends State<FinishedSetBottomSheet> {
  double currentSliderValue = 0;

  Future<void> savePushupSet() async {
    await BlocProvider.of<DBCubit>(context).writeNewPushupsetToDB(
      widget.pushupSet.copyWith(effort: currentSliderValue.toInt()),
    );
  }

  Future<void> closeModalAndSave() async {
    final navigator = Navigator.of(context);
    final sharedPrefsCubit = BlocProvider.of<SharedPreferencesCubit>(context);
    await savePushupSet();
    navigator.pop(
      await sharedPrefsCubit.getFirstPushupCompleted(),
    );
  }

  void closeModal() {
    unawaited(
      showCupertinoDialog<Widget>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(S.of(context).closeWithoutSaving),
          content: Text(S.of(context).closeExplanation),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(
                S.of(context).cancel,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: Text(
                S.of(context).dontSave,
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => {
                Navigator.of(context).pop(),
                Navigator.of(context).pop(),
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);

    return Material(
      // The app runs a `CupertinoApp` with `brightness: Brightness.dark`, so
      // `Theme.of` now derives a dark Material theme from it. Pin the surface
      // and the foreground together so they can never drift apart again.
      color: PBColors.background,
      textStyle: PBTextStyles.defaultTextStyle,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: Text(
                    localized.congrats,
                    style: PBTextStyles.pageTitleTextStyle,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PBColors.background2,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: IconButton(
                      onPressed: closeModal,
                      icon: const Icon(
                        CarbonIcons.close,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                localized.difficulty,
                style: PBTextStyles.headerTextStyle,
              ),
            ),
            Slider(
              value: currentSliderValue,
              activeColor: PBColors.accentColor,
              inactiveColor: PBColors.secondaryColor,
              max: 5,
              divisions: 5,
              label: currentSliderValue.round().toString(),
              onChanged: (value) => setState(() => currentSliderValue = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  S.of(context).easyDifficulty,
                  style: PBTextStyles.defaultTextStyle,
                ),
                Text(
                  S.of(context).middleDifficulty,
                  style: PBTextStyles.defaultTextStyle,
                ),
                Text(
                  S.of(context).hardDifficulty,
                  style: PBTextStyles.defaultTextStyle,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
              child: Text(
                S.of(context).stats,
                style: PBTextStyles.headerTextStyle,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FinishedSetStatsItem(
                      icon: CarbonIcons.time,
                      text: S.of(context).completedInXMinutes(
                            widget.pushupSet.timeSpent.toString(),
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FinishedSetStatsItem(
                      icon: CarbonIcons.add_alt,
                      text: S.of(context).madeXPushups(
                            widget.pushupSet.pushups.length.toString(),
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FinishedSetStatsItem(
                      icon: CarbonIcons.chart_average,
                      text: S.of(context).onAverage(
                            '${widget.pushupSet.pushups.length}/${widget.pushupSet.timeSpent}',
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            PBButton(
              localized.saveSet,
              callback: closeModalAndSave,
            ),
          ],
        ),
      ),
    );
  }
}
