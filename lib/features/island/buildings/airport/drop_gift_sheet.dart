import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/airport/gift_drop_actions.dart';
import 'package:pushup_bro/features/pro/widgets/pro_overlay_route.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// Picks a gift for [friend] (who goes by [name]) and drops it on their
/// island; returns the drop once it landed.
Future<GiftDrop?> showDropGiftSheet(
  BuildContext context, {
  required String friend,
  required String name,
}) =>
    showProOverlay<GiftDrop>(
      context,
      (context) => DropGiftSheet(friend: friend, name: name),
    );

String giftName(S l, GiftKind gift) => switch (gift) {
      GiftKind.small => l.dropGiftSmall,
      GiftKind.big => l.dropGiftBig,
      GiftKind.golden => l.dropGiftGolden,
      GiftKind.flowers => l.dropGiftFlowers,
    };

/// The gifts in a grid, what they cost and give, the player's bananas and
/// Drop it.
class DropGiftSheet extends StatefulWidget {
  const DropGiftSheet({required this.friend, required this.name, super.key});

  final String friend;
  final String name;

  @override
  State<DropGiftSheet> createState() => _DropGiftSheetState();
}

class _DropGiftSheetState extends State<DropGiftSheet> {
  GiftKind _gift = GiftKind.small;
  bool _dropping = false;
  String? _problem;

  Future<void> _drop() async {
    if (_dropping) return;
    final l = context.l10n;
    setState(() {
      _dropping = true;
      _problem = null;
    });
    final (outcome, drop) = await dropGiftOn(
      context,
      friend: widget.friend,
      gift: _gift,
    );
    if (!mounted) return;
    if (drop != null) {
      GameAudio.instance.play(Sfx.whoosh);
      Navigator.of(context).pop(drop);
      return;
    }
    setState(() {
      _dropping = false;
      _problem = switch (outcome) {
        DropOutcome.notEnoughBananas => l.dropNotEnough,
        DropOutcome.alreadyDropped => l.dropAlready(widget.name),
        DropOutcome.failed || DropOutcome.dropped => l.socialOffline,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void close() => Navigator.of(context).pop();

    return BlocSelector<GameInventoryCubit, GameInventoryState, int>(
      selector: (state) => state.inventory.bananas,
      builder: (context, bananas) => IslandSheet(
        title: l.visitDropGift,
        subtitle: l.dropSheetSubtitle(widget.name),
        badge: '🪂',
        accent: context.gameColors.banana,
        onClose: close,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in [
              [GiftKind.small, GiftKind.big],
              [GiftKind.golden, GiftKind.flowers],
            ]) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, gift) in row.indexed) ...[
                      if (i > 0) const SizedBox(width: PBSpace.md),
                      Expanded(
                        child: _GiftCard(
                          gift: gift,
                          selected: gift == _gift,
                          affordable: bananas >= gift.cost,
                          onTap: () => setState(() {
                            _gift = gift;
                            _problem = null;
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: PBSpace.md),
            ],
            if (_problem case final problem?)
              Padding(
                padding: const EdgeInsets.only(bottom: PBSpace.md),
                child: Text(
                  problem,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.gameColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Row(
              children: [
                Assets.images.island.banana.image(width: 26),
                const SizedBox(width: PBSpace.xs),
                // Never cut off: the button gives way instead.
                Text(
                  l.dropYouHave(bananas),
                  maxLines: 1,
                  style: context.textTheme.labelLarge,
                ),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Opacity(
                    opacity: bananas >= _gift.cost && !_dropping ? 1 : 0.5,
                    child: PillButton(
                      label: bananas >= _gift.cost
                          ? '${_gift.emoji} ${l.dropConfirm}'
                          : l.dropNotEnough,
                      compact: true,
                      color: context.gameColors.jungle,
                      onPressed: () => unawaited(_drop()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.gift,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final GiftKind gift;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return SheetCard(
      selected: selected,
      accent: context.gameColors.banana,
      onTap: () {
        GameAudio.instance.play(Sfx.tap);
        onTap();
      },
      padding: const EdgeInsets.all(PBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(gift.emoji, style: const TextStyle(fontSize: 30)),
              const Spacer(),
              BananaPrice(gift.cost, affordable: affordable),
            ],
          ),
          const SizedBox(height: PBSpace.sm),
          Text(
            giftName(l, gift),
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.dropGiftGives(gift.bananas),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
