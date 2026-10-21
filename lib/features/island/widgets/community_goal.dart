import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

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
          width: 200,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: LinearProgressIndicator(
                  value: getProgress(count),
                  backgroundColor: context.colorScheme.primary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.secondary,
                  ),
                  minHeight: 40,
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$goal Bananas',
                      style: context.textTheme.labelLarge,
                    ),
                    const SizedBox(width: 8),
                    Assets.images.island.banana.image(width: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
