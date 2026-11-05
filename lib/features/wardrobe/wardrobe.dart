import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/extensions/shop_buyables.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/wardrobe/widgets/cosmetic_tile.dart';
import 'package:pushup_bro/features/wardrobe/widgets/wardrobe_stage.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// Carlos's wardrobe: try on fur and face colours, hats, eyewear, outfits
/// and mats on a turntable, buy them with bananas and wear them.
///
/// Owned things are worn as soon as they are tapped; anything else is
/// tried on until it is bought or the wardrobe is left. With more monkeys
/// on the island, a switch at the top picks who is being dressed, starting
/// with the one at [monkey].
class Wardrobe extends StatefulWidget {
  const Wardrobe({this.monkey = 0, super.key});
  static const routeName = '/wardrobe';

  /// The index in `GameInventory.monkeys` of the monkey to dress first.
  final int monkey;

  @override
  State<Wardrobe> createState() => _WardrobeState();
}

class _WardrobeState extends State<Wardrobe> {
  CosmeticSlot _slot = CosmeticSlot.fur;

  /// Being tried on, not owned yet.
  Cosmetic? _tryingOn;

  /// The index of the monkey being dressed.
  late int _dressing = widget.monkey;

  int _dressingIn(GameInventory inventory) =>
      _dressing.clamp(0, inventory.monkeys.length - 1);

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
          ).dressMonkey(_dressingIn(inventory), look),
        );
  }

  /// Dresses the monkey at [index] instead.
  void _switchTo(int index) {
    GameAudio.instance.play(Sfx.tap);
    setState(() {
      _tryingOn = null;
      _dressing = index;
    });
  }

  /// Plays as the monkey being dressed: the first one is the one shown
  /// everywhere.
  void _playAs(GameInventory inventory) {
    final index = _dressingIn(inventory);
    if (index == 0) return;
    GameAudio.instance.play(Sfx.equip);
    setState(() {
      _tryingOn = null;
      _dressing = 0;
    });
    unawaited(
      context
          .read<GameInventoryCubit>()
          .updateInventory(inventory.playAs(index)),
    );
  }

  void _tap(GameInventory inventory, Cosmetic cosmetic) {
    GameAudio.instance.play(Sfx.equip);
    final look = inventory.monkeys[_dressingIn(inventory)].look;
    if (inventory.owns(cosmetic.id)) {
      setState(() => _tryingOn = null);
      unawaited(_save(inventory, look: look.wearing(cosmetic)));
    } else {
      setState(() => _tryingOn = cosmetic);
    }
  }

  Future<void> _buy(GameInventory inventory, Cosmetic cosmetic) async {
    GameAudio.instance.play(Sfx.purchase);
    await _save(
      inventory,
      look: inventory.monkeys[_dressingIn(inventory)].look.wearing(cosmetic),
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
          final dressing = _dressingIn(inventory);
          final worn = inventory.monkeys[dressing].look;
          final tryingOn = _tryingOn;
          final shown = tryingOn == null ? worn : worn.wearing(tryingOn);

          return Scaffold(
            backgroundColor: context.colorScheme.surfaceContainerLow,
            body: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.45),
                        radius: 0.9,
                        // A soft spotlight on the turntable.
                        colors: context.isDark
                            ? [
                                context.colorScheme.surfaceBright,
                                context.colorScheme.surfaceContainerLowest,
                              ]
                            : [
                                context.colorScheme.surface,
                                context.colorScheme.secondaryContainer,
                              ],
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
                          context.l10n.wardrobeTitle,
                          style: context.textTheme.headlineLarge,
                        ),
                        const Spacer(),
                        const BananaCounter(),
                      ],
                    ),
                  ),
                ),
                if (inventory.monkeys.length > 1)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.paddingOf(context).top + 66,
                    child: _CharacterSwitch(
                      inventory: inventory,
                      dressing: dressing,
                      onPick: _switchTo,
                      onPlayAs: () => _playAs(inventory),
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

  static const Map<CosmeticSlot, (String Function(S), String)> _slotLabels = {
    CosmeticSlot.fur: (_furLabel, '🦍'),
    CosmeticSlot.face: (_faceLabel, '😊'),
    CosmeticSlot.hat: (_hatsLabel, '🎩'),
    CosmeticSlot.eyewear: (_eyesLabel, '🕶️'),
    CosmeticSlot.outfit: (_outfitsLabel, '🎽'),
    CosmeticSlot.matColor: (_matLabel, '🟦'),
    CosmeticSlot.matPattern: (_patternLabel, '🏁'),
  };

  @override
  Widget build(BuildContext context) {
    final locked =
        slot.needsAccessoriesShop && !inventory.boughtItems.hasAccessories;
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.52,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(PBRadius.sheet)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow
                .withValues(alpha: context.isDark ? 0.5 : 0.12),
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
                      label: label(context.l10n),
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
                  child: Center(child: _action(context, locked)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, bool locked) {
    final cosmetic = tryingOn;
    if (cosmetic == null) return const SizedBox.shrink();
    if (cosmetic.exclusive) {
      return SheetTag(
        '🦎 ${context.l10n.trekExclusiveInfo}',
        color: context.gameColors.jungle,
      );
    }
    if (locked) {
      return SheetTag(
        context.l10n.wardrobeLocked,
        icon: CarbonIcons.locked,
        color: context.gameColors.orange,
      );
    }
    final missing = cosmetic.price - inventory.bananas;
    if (missing > 0) {
      return SheetTag(
        context.l10n.wardrobeNeedMore(missing, cosmetic.label(context.l10n)),
        icon: CarbonIcons.warning_alt,
        color: context.gameColors.red,
      );
    }

    return PillButton(
      label: context.l10n.wardrobeBuy(
        cosmetic.label(context.l10n),
        cosmetic.price,
      ),
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
        color: selected
            ? context.colorScheme.primary
            : context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.pill),
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
                  style: context.textTheme.labelMedium?.copyWith(
                    fontSize: 14,
                    color: selected
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onSurface,
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
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: context.cardShadow,
        ),
        child: Material(
          color: context.colorScheme.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: context.colorScheme.onSurface),
            ),
          ),
        ),
      );
}

String _furLabel(S l) => l.slotFur;
String _faceLabel(S l) => l.slotFace;
String _hatsLabel(S l) => l.slotHats;
String _eyesLabel(S l) => l.slotEyes;
String _outfitsLabel(S l) => l.slotOutfits;
String _matLabel(S l) => l.slotMat;
String _patternLabel(S l) => l.slotPattern;

/// Who is being dressed, once more monkeys live on the island, and a
/// button to play as them.
class _CharacterSwitch extends StatelessWidget {
  const _CharacterSwitch({
    required this.inventory,
    required this.dressing,
    required this.onPick,
    required this.onPlayAs,
  });

  final GameInventory inventory;
  final int dressing;
  final ValueChanged<int> onPick;
  final VoidCallback onPlayAs;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final (i, monkey) in inventory.monkeys.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: i == dressing
                      ? context.colorScheme.primary
                      : context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(PBRadius.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                    onTap: () => onPick(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(
                          // A star marks the one being played as.
                          '${i == 0 ? '⭐' : monkey.look.species == //
                              MonkeyLook.lizard ? '👑' : '🐵'} ${monkey.name}',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: i == dressing
                                ? context.colorScheme.onPrimary
                                : context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (dressing != 0)
              Material(
                color: context.tint(context.gameColors.banana),
                borderRadius: BorderRadius.circular(PBRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(PBRadius.pill),
                  onTap: onPlayAs,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: Text(
                        '⭐ ${context.l10n.playAs}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
