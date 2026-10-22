import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/shop_buyables.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/wardrobe/widgets/cosmetic_tile.dart';
import 'package:pushup_bro/features/wardrobe/widgets/wardrobe_stage.dart';

/// Carlos's wardrobe: try on fur and face colours, hats, eyewear, outfits
/// and mats on a turntable, buy them with bananas and wear them.
///
/// Owned things are worn as soon as they are tapped; anything else is
/// tried on until it is bought or the wardrobe is left.
class Wardrobe extends StatefulWidget {
  const Wardrobe({super.key});
  static const routeName = '/wardrobe';

  @override
  State<Wardrobe> createState() => _WardrobeState();
}

class _WardrobeState extends State<Wardrobe> {
  CosmeticSlot _slot = CosmeticSlot.fur;

  /// Being tried on, not owned yet.
  Cosmetic? _tryingOn;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<GameInventoryCubit>().fetchInventory());
  }

  Future<void> _save(
    GameInventory inventory, {
    required MonkeyLook look,
    int spent = 0,
    String? bought,
  }) async {
    await context.read<GameInventoryCubit>().updateInventory(
          inventory.copyWith(
            bananas: inventory.bananas - spent,
            ownedCosmetics: [
              ...inventory.ownedCosmetics,
              if (bought != null) bought,
            ],
            monkeys: [
              inventory.monkeys.first.copyWith(look: look),
              ...inventory.monkeys.skip(1),
            ],
          ),
        );
  }

  void _tap(GameInventory inventory, Cosmetic cosmetic) {
    final look = inventory.monkeys.first.look;
    if (inventory.owns(cosmetic.id)) {
      setState(() => _tryingOn = null);
      unawaited(_save(inventory, look: look.wearing(cosmetic)));
    } else {
      setState(() => _tryingOn = cosmetic);
    }
  }

  Future<void> _buy(GameInventory inventory, Cosmetic cosmetic) async {
    await _save(
      inventory,
      look: inventory.monkeys.first.look.wearing(cosmetic),
      spent: cosmetic.price,
      bought: cosmetic.id,
    );
    if (mounted) setState(() => _tryingOn = null);
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, GameInventory>(
        selector: (state) => state.inventory,
        builder: (context, inventory) {
          final worn = inventory.monkeys.first.look;
          final tryingOn = _tryingOn;
          final shown = tryingOn == null ? worn : worn.wearing(tryingOn);

          return Scaffold(
            backgroundColor: background,
            body: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.45),
                        radius: 0.9,
                        colors: [Color(0xFFFFFFFF), Color(0xFFDDE6FF)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: WardrobeStage(look: shown),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _RoundButton(
                          icon: CarbonIcons.arrow_left,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Wardrobe',
                          style: pageTitleTextStyle.copyWith(
                            color: background2,
                          ),
                        ),
                        const Spacer(),
                        const BananaCounter(),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _Drawer(
                    slot: _slot,
                    inventory: inventory,
                    shown: shown,
                    tryingOn: tryingOn,
                    onSlot: (slot) => setState(() {
                      _slot = slot;
                      _tryingOn = null;
                    }),
                    onTap: (cosmetic) => _tap(inventory, cosmetic),
                    onBuy: (cosmetic) => _buy(inventory, cosmetic),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Drawer extends StatelessWidget {
  const _Drawer({
    required this.slot,
    required this.inventory,
    required this.shown,
    required this.tryingOn,
    required this.onSlot,
    required this.onTap,
    required this.onBuy,
  });

  final CosmeticSlot slot;
  final GameInventory inventory;
  final MonkeyLook shown;
  final Cosmetic? tryingOn;
  final ValueChanged<CosmeticSlot> onSlot;
  final ValueChanged<Cosmetic> onTap;
  final ValueChanged<Cosmetic> onBuy;

  static const Map<CosmeticSlot, (String, String)> _slotLabels = {
    CosmeticSlot.fur: ('Fur', '🦍'),
    CosmeticSlot.face: ('Face', '😊'),
    CosmeticSlot.hat: ('Hats', '🎩'),
    CosmeticSlot.eyewear: ('Eyes', '🕶️'),
    CosmeticSlot.outfit: ('Outfits', '🎽'),
    CosmeticSlot.matColor: ('Mat', '🟦'),
    CosmeticSlot.matPattern: ('Pattern', '🏁'),
  };

  @override
  Widget build(BuildContext context) {
    final locked =
        slot.needsAccessoriesShop && !inventory.boughtItems.hasAccessories;
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: background2.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final MapEntry(key: each, value: (label, emoji))
                    in _slotLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SlotChip(
                      label: label,
                      emoji: emoji,
                      selected: each == slot,
                      onTap: () => onSlot(each),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    media.padding.bottom + 96,
                  ),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                  children: [
                    for (final cosmetic in Cosmetic.inSlot(slot))
                      CosmeticTile(
                        cosmetic: cosmetic,
                        matColor: shown.matBaseColor,
                        owned: inventory.owns(cosmetic.id),
                        worn: shown.idFor(slot) == cosmetic.id &&
                            tryingOn?.id != cosmetic.id,
                        tryingOn: tryingOn?.id == cosmetic.id,
                        locked: locked && !cosmetic.free,
                        onTap: () => onTap(cosmetic),
                      ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: media.padding.bottom + 16,
                  child: Center(child: _action(locked)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(bool locked) {
    final cosmetic = tryingOn;
    if (cosmetic == null) return const SizedBox.shrink();
    if (locked) {
      return const SheetTag(
        'Build the Accessories Shop to unlock',
        icon: CarbonIcons.locked,
        color: Color(0xFFF5A623),
      );
    }
    final missing = cosmetic.price - inventory.bananas;
    if (missing > 0) {
      return SheetTag(
        '$missing more bananas for ${cosmetic.name}',
        icon: CarbonIcons.warning_alt,
        color: const Color(0xFFE5534B),
      );
    }

    return PillButton(
      label: 'Buy ${cosmetic.name} · ${cosmetic.price}',
      icon: CarbonIcons.shopping_bag,
      onPressed: () => onBuy(cosmetic),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? background2 : background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: buttonTextStyle.copyWith(
                    color: selected ? Colors.white : background2,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: background2),
          ),
        ),
      );
}
