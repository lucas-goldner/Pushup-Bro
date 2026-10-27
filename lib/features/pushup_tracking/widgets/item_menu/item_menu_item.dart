import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/active_effects_cubit.dart';
import 'package:pushup_bro/core/cubit/active_effects_state.dart';
import 'package:pushup_bro/core/cubit/booster_item_cubit.dart';
import 'package:pushup_bro/core/cubit/booster_item_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/booster_items.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

@immutable
class ItemMenuItem extends StatelessWidget {
  const ItemMenuItem({
    required this.item,
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;
  final BoosterItems item;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PBRadius.lg),
              boxShadow: context.cardShadow,
            ),
            child: Material(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(PBRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(PBRadius.lg),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: onPressed,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: item.getIcon().image(width: 44, height: 44),
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<ActiveEffectsCubit, ActiveEffectsState>(
            builder: (context, state) {
              final isActive = state.isActive(
                item.getCorrespondingEffect(),
              );

              return Positioned(
                right: -6,
                bottom: -6,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? context.gameColors.leaf
                        : context.colorScheme.secondary,
                    border: Border.all(
                      color: context.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Center(
                      child: isActive
                          ? Icon(
                              CarbonIcons.checkmark,
                              size: 14,
                              color: context.gameColors.onGame,
                            )
                          : BlocBuilder<BoosterItemCubit, BoosterItemState>(
                              builder: (context, state) => Text(
                                state.items[item].toString(),
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: context.colorScheme.onSecondary,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
}
