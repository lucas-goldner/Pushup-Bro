import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/island/buildings/open_building.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// A round button on the island's top bar while the gym is built and
/// today's gym workout isn't won yet; opens the gym.
class GymChallengeChip extends StatelessWidget {
  const GymChallengeChip({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, bool>(
        selector: (state) =>
            state.inventory.boughtItems.contains(ShopBuyables.gym) &&
            !state.inventory.gym.completedOn(DateTime.now()),
        builder: (context, show) {
          if (!show) return const SizedBox.shrink();
          final scheme = context.colorScheme;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: context.l10n.gymChallengeChip,
              child: Semantics(
                button: true,
                label: context.l10n.gymChallengeChip,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: context.cardShadow,
                  ),
                  child: Material(
                    color: scheme.surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        GameAudio.instance.play(Sfx.tap);
                        unawaited(openBuilding(context, ShopBuyables.gym));
                      },
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '🏋️',
                              style: TextStyle(fontSize: size * 0.46),
                            ),
                            // Something new waits.
                            Positioned(
                              top: size * 0.12,
                              right: size * 0.12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: context.gameColors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
