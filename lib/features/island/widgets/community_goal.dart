import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

class CommunityGoal extends StatelessWidget {
  const CommunityGoal({
    required this.openMenu,
    this.width = 150,
    this.height = 40,
    super.key,
  });

  /// Null fills the width it's given.
  final double? width;
  final double height;

  final void Function() openMenu;

  @override
  Widget build(BuildContext context) {
    const todaysBananas = 1000;
    const goal = 10000;
    double getProgress(int userBananas) => (userBananas + todaysBananas) / goal;

    return BlocSelector<GameInventoryCubit, GameInventoryState, int>(
      selector: (state) => state.inventory.bananas,
      builder: (context, count) => GestureDetector(
        onTap: openMenu,
        child: Container(
          height: height,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(PBRadius.pill),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            children: [
              Icon(
                CarbonIcons.trophy,
                size: 18,
                color: context.gameColors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PBRadius.pill),
                  child: LinearProgressIndicator(
                    value: getProgress(count).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: context.colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(
                      context.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
