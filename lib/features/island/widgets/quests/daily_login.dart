import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class DailyLogin extends StatelessWidget {
  const DailyLogin({
    required this.onClose,
    super.key,
  });
  final VoidCallback onClose;

  List<int> getNextThreeDaysDaytimes() {
    final today = DateTime.now();
    final result = <int>[];

    for (var i = 1; i <= 3; i++) {
      final nextDay = today.add(Duration(days: i));
      result.add(nextDay.day);
    }

    return result;
  }

  Future<void> takeBananas(BuildContext context) async {
    final gameInvCubit = context.read<GameInventoryCubit>();
    await gameInvCubit.fetchInventory();
    final inv = gameInvCubit.state.inventory;
    await gameInvCubit.updateInventory(
      inv.copyWith(
        bananas: inv.bananas + 10,
      ),
    );
    onClose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Enjoy free 10 bananas every day!',
              style: context.textTheme.displaySmall,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: getNextThreeDaysDaytimes()
                .map(
                  (day) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => takeBananas(context),
                      child: _buildDayWidget(context: context, day: day),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );

  Widget _buildDayWidget({
    required BuildContext context,
    required int day,
  }) =>
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.toString(),
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '10x',
                  style: context.textTheme.bodyMedium,
                ),
                Assets.images.island.banana.image(
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
      );
}
