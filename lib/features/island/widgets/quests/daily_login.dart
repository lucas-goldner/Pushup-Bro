import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// Ten free bananas a day: today's to claim, and the next few days.
class DailyLogin extends StatelessWidget {
  const DailyLogin({
    required this.onClose,
    super.key,
  });
  final VoidCallback onClose;

  Future<void> takeBananas(BuildContext context) async {
    final gameInvCubit = context.read<GameInventoryCubit>();
    await gameInvCubit.fetchInventory();
    final inv = gameInvCubit.state.inventory;
    GameAudio.instance.play(Sfx.banana);
    await gameInvCubit.updateInventory(
      inv.copyWith(
        bananas: inv.bananas + 10,
      ),
    );
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.dailyInfo,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: PBSpace.sm),
              Expanded(
                child: _Day(
                  label: i == 0
                      ? context.l10n.dailyToday
                      : '${today.add(Duration(days: i)).day}',
                  today: i == 0,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: PillButton(
            label: context.l10n.dailyClaim,
            icon: CarbonIcons.gift,
            color: context.gameColors.orange,
            onPressed: () => takeBananas(context),
          ),
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.label, required this.today});

  final String label;
  final bool today;

  @override
  Widget build(BuildContext context) => SheetCard(
        selected: today,
        accent: context.gameColors.orange,
        color: today
            ? context.gameColors.cream
            : context.colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: today ? 1 : 0.45,
              child: Assets.images.island.banana.image(width: 34),
            ),
            Text(
              '×10',
              style: context.textTheme.labelMedium?.copyWith(
                color: today
                    ? context.colorScheme.onSurface
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}
