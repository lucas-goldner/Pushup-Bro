import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/model/feature_variants.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/item_menu/item_menu.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/start_pushups_button.dart';

class PushupTrackingBottomRow extends StatelessWidget {
  const PushupTrackingBottomRow({
    required this.toggleListeningUpdates,
    super.key,
  });

  final VoidCallback toggleListeningUpdates;

  @override
  Widget build(BuildContext context) {
    final featureVariant =
        context.read<FeatureSwitchCubit>().state.featureVariant;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: Center(
                child: StartPushupsButton(
                  toggleListeningUpdates,
                ),
              ),
            ),
            switch (featureVariant) {
              FeatureVariants.hookmodel => const SizedBox(
                  width: 40,
                ),
              FeatureVariants.gamification => const SizedBox.shrink(),
            },
            const Spacer(),
          ],
        ),
        switch (featureVariant) {
          FeatureVariants.hookmodel => const Row(
              children: [
                Spacer(),
                ItemMenu(),
                SizedBox(
                  width: 20,
                ),
              ],
            ),
          FeatureVariants.gamification => const SizedBox(
              width: 56,
              height: 200,
            ),
        },
      ],
    );
  }
}
