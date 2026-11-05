import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_editor.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_inventory.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_preview.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// The accessory shop: decorations for the island on a turntable, bought
/// with bananas. A bought one stands on the island right away; "Place it"
/// goes back to the island to move it where it belongs.
class DecorPage extends StatefulWidget {
  const DecorPage({this.preview = true, super.key});

  /// Whether to show the 3D turntable (off in widget tests, which have no
  /// GPU).
  final bool preview;

  @override
  State<DecorPage> createState() => _DecorPageState();
}

class _DecorPageState extends State<DecorPage> {
  DecorItem _selected = DecorItem.values.first;

  /// The piece just bought, offered to be placed.
  int? _bought;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<GameInventoryCubit>().fetchInventory());
  }

  void _pick(DecorItem item) {
    GameAudio.instance.play(Sfx.tap);
    setState(() {
      _selected = item;
      _bought = null;
    });
  }

  Future<void> _buy(GameInventory inventory) async {
    final bought = inventory.buyDecor(_selected);
    if (bought == null) return;
    GameAudio.instance.play(Sfx.purchase);
    await context.read<GameInventoryCubit>().updateInventory(bought);
    if (mounted) setState(() => _bought = bought.decor.length - 1);
  }

  /// Back to the island, in edit mode with [select] picked.
  void _edit(int? select) {
    decorEditRequests.add(select);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, GameInventory>(
        selector: (state) => state.inventory,
        builder: (context, inventory) {
          final media = MediaQuery.of(context);

          return Scaffold(
            backgroundColor: context.colorScheme.surfaceContainerLow,
            body: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.5),
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
                if (widget.preview)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: media.padding.top + 64,
                    height: media.size.height * 0.4,
                    child: DecorPreview(item: _selected),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PBSpace.lg,
                      PBSpace.sm,
                      PBSpace.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        _RoundButton(
                          icon: CarbonIcons.arrow_left,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: PBSpace.md),
                        // Long names shrink instead of being cut off.
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.l10n.buildingAccessories,
                              maxLines: 1,
                              style: context.textTheme.headlineMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: PBSpace.sm),
                        const BananaCounter(),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _Drawer(
                    inventory: inventory,
                    selected: _selected,
                    bought: _bought,
                    onPick: _pick,
                    onBuy: () => _buy(inventory),
                    onEdit: _edit,
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
    required this.inventory,
    required this.selected,
    required this.bought,
    required this.onPick,
    required this.onBuy,
    required this.onEdit,
  });

  final GameInventory inventory;
  final DecorItem selected;
  final int? bought;
  final ValueChanged<DecorItem> onPick;
  final VoidCallback onBuy;
  final ValueChanged<int?> onEdit;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.52,
      constraints: const BoxConstraints(maxWidth: 720),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PBSpace.xl,
              PBSpace.lg,
              PBSpace.lg,
              PBSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.label(context.l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleLarge,
                      ),
                      Text(
                        switch (inventory.ownedDecor(selected)) {
                          0 => context.l10n.decorShopSubtitle,
                          final owned => context.l10n.decorOwned(owned),
                        },
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (inventory.decor.isNotEmpty) ...[
                  const SizedBox(width: PBSpace.sm),
                  _EditButton(onTap: () => onEdit(null)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GridView.count(
                  // Three a row on the smallest phones, so names fit.
                  crossAxisCount: media.size.width < 360 ? 3 : 4,
                  padding: EdgeInsets.fromLTRB(
                    PBSpace.lg,
                    PBSpace.xs,
                    PBSpace.lg,
                    media.padding.bottom + 132,
                  ),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.7,
                  children: [
                    for (final item in DecorItem.values)
                      _DecorTile(
                        item: item,
                        owned: inventory.ownedDecor(item),
                        affordable: inventory.bananas >= item.price,
                        selected: item == selected,
                        onTap: () => onPick(item),
                      ),
                  ],
                ),
                // The grid fades out under the buttons.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: media.padding.bottom + 120,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colorScheme.surface.withValues(alpha: 0),
                            context.colorScheme.surface,
                          ],
                          stops: const [0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: PBSpace.lg,
                  right: PBSpace.lg,
                  bottom: media.padding.bottom + PBSpace.lg,
                  child: Center(child: _action(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context) {
    final bought = this.bought;
    if (bought != null && bought < inventory.decor.length) {
      // Just bought: off to the island to put it in its place.
      final standing = inventory.decor[bought].placed;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            // Solid, so it reads over the tiles.
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(PBRadius.sm),
            ),
            child: SheetTag(
              standing
                  ? context.l10n.decorBought
                  : context.l10n.decorIslandFull,
              icon: standing ? CarbonIcons.checkmark : CarbonIcons.warning_alt,
              color: standing
                  ? context.gameColors.jungle
                  : context.gameColors.orange,
            ),
          ),
          const SizedBox(height: PBSpace.sm),
          _boughtActions(context, bought, standing: standing),
        ],
      );
    }
    final missing = selected.price - inventory.bananas;
    if (missing > 0) {
      return SheetTag(
        context.l10n.shopNeedMore(missing),
        icon: CarbonIcons.warning_alt,
        color: context.gameColors.red,
      );
    }

    return PillButton(
      label: context.l10n.decorBuy(selected.price),
      icon: CarbonIcons.shopping_bag,
      onPressed: onBuy,
    );
  }

  Widget _boughtActions(
    BuildContext context,
    int bought, {
    required bool standing,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: PillButton(
              label: context.l10n.decorPlace,
              icon: CarbonIcons.move,
              color: context.gameColors.jungle,
              compact: true,
              onPressed: () => onEdit(standing ? bought : null),
            ),
          ),
          if (inventory.bananas >= selected.price) ...[
            const SizedBox(width: PBSpace.sm),
            Flexible(
              child: PillButton(
                label: context.l10n.decorBuy(selected.price),
                icon: CarbonIcons.shopping_bag,
                compact: true,
                onPressed: onBuy,
              ),
            ),
          ],
        ],
      );
}

/// One decoration in the shop: its emoji, name, price and how many the
/// player has.
class _DecorTile extends StatelessWidget {
  const _DecorTile({
    required this.item,
    required this.owned,
    required this.affordable,
    required this.selected,
    required this.onTap,
  });

  final DecorItem item;
  final int owned;
  final bool affordable;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PBRadius.md + 4),
                border: Border.all(
                  color: selected ? scheme.secondary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(PBRadius.md),
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(PBSpace.sm),
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (owned > 0)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondary,
                          borderRadius: BorderRadius.circular(PBRadius.pill),
                        ),
                        child: Text(
                          '×$owned',
                          style: context.textTheme.labelSmall?.copyWith(
                            letterSpacing: 0,
                            color: scheme.onSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PBSpace.xs),
          Text(
            item.label(context.l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.images.island.banana.image(width: 16),
              const SizedBox(width: 2),
              Text(
                '${item.price}',
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  color: affordable ? scheme.onSurface : context.gameColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Edit island": back to the island to move the decorations around.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.tint(context.colorScheme.secondary),
        borderRadius: BorderRadius.circular(PBRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          onTap: () {
            GameAudio.instance.play(Sfx.tap);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CarbonIcons.paint_brush,
                  size: 16,
                  color: context.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.decorEditIsland,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.secondary,
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
