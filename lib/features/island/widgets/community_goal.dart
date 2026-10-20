import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';

class CommunityGoal extends StatelessWidget {
  const CommunityGoal({
    required this.openMenu,
    super.key,
  });

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
          height: 40,
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: background2.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(CarbonIcons.trophy, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: getProgress(count).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: background,
                    valueColor: const AlwaysStoppedAnimation(accentColor),
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
