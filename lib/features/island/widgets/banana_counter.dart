import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class BananaCounter extends StatelessWidget {
  const BananaCounter({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, int>(
        selector: (state) => state.inventory.bananas,
        builder: (context, count) => Container(
          height: 40,
          padding: const EdgeInsets.only(left: 8, right: 14),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(PBRadius.pill),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.images.island.banana.image(width: 28),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
}
