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
import 'package:pushup_bro/core/widgets/fold_safe.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption_widgets.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/wardrobe/wardrobe.dart';
import 'package:pushup_bro/features/wardrobe/widgets/wardrobe_stage.dart';

/// The adoption centre: meet a few monkeys hoping for an island home,
/// name one and adopt it, then dress up, rename and pick who trains in
/// the home gym among the monkeys already living on the island.
class AdoptionPage extends StatefulWidget {
  const AdoptionPage({this.effects = true, super.key});

  /// Whether to show the picked monkey in 3D and throw confetti; tests
  /// can do neither.
  final bool effects;

  @override
  State<AdoptionPage> createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> {
  int _picked = 0;

  /// How often "Meet others" was tapped: new monkeys each time.
  int _round = 0;

  /// Names the player gave candidates before adopting them.
  final Map<int, String> _names = {};

  /// The same monkeys all day, until one is adopted or others are met.
  List<AdoptableMonkey> _candidates(GameInventory inventory) {
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    final candidates = Adoption.candidates(
      day * 1009 + inventory.adoptedCount * 31 + _round * 7,
      taken: [for (final monkey in inventory.monkeys) monkey.name],
      takenPersonalities: [
        for (final monkey in inventory.monkeys) monkey.personality,
      ],
    );

    return [
      for (final (i, monkey) in candidates.indexed)
        monkey.copyWith(name: _names[i]),
    ];
  }

  void _meetOthers() {
    GameAudio.instance.play(Sfx.whoosh);
    setState(() {
      _round++;
      _picked = 0;
      _names.clear();
    });
  }

  Future<void> _adopt(GameInventory inventory, AdoptableMonkey monkey) async {
    final adopted = inventory.adopt(monkey);
    if (adopted == null) return;
    GameAudio.instance.play(Sfx.purchase);
    await context.read<GameInventoryCubit>().updateInventory(adopted);
    if (!mounted) return;
    setState(() {
      _picked = 0;
      _names.clear();
    });
    GameAudio.instance.play(Sfx.levelUp);
    await showWelcome(
      context,
      monkey: adopted.monkeys.last,
      trainer: adopted.monkeys.first.name,
      confetti: widget.effects,
    );
  }

  Future<void> _renameCandidate(AdoptableMonkey monkey) async {
    final name = await askMonkeyName(context, monkey.name);
    if (name != null && mounted) setState(() => _names[_picked] = name);
  }

  Future<void> _rename(GameInventory inventory, int index) async {
    final cubit = context.read<GameInventoryCubit>();
    final name = await askMonkeyName(context, inventory.monkeys[index].name);
    if (name == null) return;
    await cubit.updateInventory(
      cubit.state.inventory.renameMonkey(index, name),
    );
  }

  void _trainInGym(GameInventory inventory, int index, bool train) {
    GameAudio.instance.play(train ? Sfx.equip : Sfx.tap);
    unawaited(
      context.read<GameInventoryCubit>().updateInventory(
            inventory.trainInGym(index, train: train),
          ),
    );
  }

  void _dressUp(int index) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => Wardrobe(monkey: index),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GameInventoryCubit, GameInventoryState>(
        // Saving passes through an empty inventory for a moment.
        buildWhen: (_, current) => current is! GameInventoryFetching,
        builder: (context, state) {
          final inventory = state.inventory;
          final candidates = _candidates(inventory);
          final picked = candidates[_picked.clamp(0, candidates.length - 1)];
          final full = !inventory.hasRoomForMonkey;
          final extras = inventory.extras;
          final spots = inventory.freeSpotPrices;
          final media = MediaQuery.of(context);

          return Scaffold(
            backgroundColor: context.colorScheme.surfaceContainerLow,
            body: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.6),
                        radius: 1.1,
                        // A warm glow, like the centre's lamps.
                        colors: [
                          Color.alphaBlend(
                            context.tint(context.gameColors.banana),
                            context.colorScheme.surface,
                          ),
                          context.colorScheme.surfaceContainerLow,
                        ],
                      ),
                    ),
                  ),
                ),
                FoldSafe(
                  maxWidth: 560,
                  alignment: Alignment.topCenter,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SafeArea(
                          bottom: false,
                          child: _Header(full: full),
                        ),
                      ),
                      if (!full) ...[
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: (media.size.height * 0.3).clamp(170, 300),
                            child: widget.effects
                                ? WardrobeStage(look: picked.look)
                                : Center(
                                    child: BroAvatar(
                                      look: picked.look,
                                      size: 120,
                                    ),
                                  ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: PBSpace.lg,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _Candidates(
                              candidates: candidates,
                              picked: _picked,
                              onPick: (i) {
                                GameAudio.instance.play(Sfx.pop);
                                setState(() => _picked = i);
                              },
                              onMeetOthers: _meetOthers,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            PBSpace.lg,
                            PBSpace.md,
                            PBSpace.lg,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _PickedCard(
                              monkey: picked,
                              inventory: inventory,
                              onRename: () => _renameCandidate(picked),
                              onAdopt: () => _adopt(inventory, picked),
                            ),
                          ),
                        ),
                      ],
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          PBSpace.lg,
                          PBSpace.xl,
                          PBSpace.lg,
                          PBSpace.sm,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.adoptionYourMonkeys,
                                  style: context.textTheme.titleLarge,
                                ),
                              ),
                              SheetTag(
                                context.l10n.adoptionSpots(
                                  extras.length,
                                  Adoption.maxExtras,
                                ),
                                color: context.gameColors.jungle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          PBSpace.lg,
                          0,
                          PBSpace.lg,
                          media.padding.bottom + PBSpace.xl,
                        ),
                        sliver: SliverList.list(
                          children: [
                            for (final (i, monkey) in extras.indexed)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: PBSpace.sm,
                                ),
                                child: MonkeyCard(
                                  monkey: monkey,
                                  trainer: inventory.monkeys.first.name,
                                  onGym: (train) =>
                                      _trainInGym(inventory, i + 1, train),
                                  onDressUp: () => _dressUp(i + 1),
                                  onRename: () => _rename(inventory, i + 1),
                                ),
                              ),
                            for (final (i, price) in spots.indexed)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: PBSpace.sm,
                                ),
                                child: FreeSpotCard(price: price, next: i == 0),
                              ),
                            // He can't join a full island.
                            if (inventory.komoToCome && spots.length == 1)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: PBSpace.xs,
                                ),
                                child: Text(
                                  '👑 ${context.l10n.adoptionKomoSpot}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.full});

  final bool full;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _BackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.buildingAdoption,
                    maxLines: 2,
                    style: context.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 8),
                const BananaCounter(),
              ],
            ),
            const SizedBox(height: PBSpace.sm),
            Text(
              full
                  ? '🎉 ${context.l10n.adoptionFull}'
                  : context.l10n.adoptionSubtitle,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

class _Candidates extends StatelessWidget {
  const _Candidates({
    required this.candidates,
    required this.picked,
    required this.onPick,
    required this.onMeetOthers,
  });

  final List<AdoptableMonkey> candidates;
  final int picked;
  final ValueChanged<int> onPick;
  final VoidCallback onMeetOthers;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              for (final (i, monkey) in candidates.indexed) ...[
                if (i > 0) const SizedBox(width: PBSpace.sm),
                Expanded(
                  child: CandidateChip(
                    monkey: monkey,
                    selected: i == picked,
                    onTap: () => onPick(i),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: PBSpace.sm),
          CardAction(
            icon: CarbonIcons.renew,
            label: context.l10n.adoptionMeetOthers,
            onTap: onMeetOthers,
          ),
        ],
      );
}

/// The picked candidate: name (tap to change it), personality and the
/// adopt button with its price.
class _PickedCard extends StatelessWidget {
  const _PickedCard({
    required this.monkey,
    required this.inventory,
    required this.onRename,
    required this.onAdopt,
  });

  final AdoptableMonkey monkey;
  final GameInventory inventory;
  final VoidCallback onRename;
  final VoidCallback onAdopt;

  @override
  Widget build(BuildContext context) {
    final price = inventory.nextAdoptionPrice ?? 0;
    final missing = price - inventory.bananas;

    return SheetCard(
      color: context.colorScheme.surface,
      padding: const EdgeInsets.all(PBSpace.lg),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(PBRadius.sm),
            onTap: onRename,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      monkey.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CarbonIcons.edit,
                    size: 18,
                    semanticLabel: context.l10n.adoptionRename,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (monkeyLine(context.l10n, monkey) case final line?) ...[
            const SizedBox(height: 4),
            Text(
              '“$line”',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: PBSpace.lg),
          if (missing > 0)
            // Not a SheetTag: long translations need a second line.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.tint(context.gameColors.red),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          CarbonIcons.warning_alt,
                          size: 14,
                          color: context.gameColors.red,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.adoptionNeedMore(missing, monkey.name),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.gameColors.red,
                ),
              ),
            )
          else
            PillButton(
              label: context.l10n.adoptionAdopt(monkey.name, price),
              icon: CarbonIcons.favorite,
              color: context.gameColors.jungle,
              onPressed: onAdopt,
            ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

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
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                CarbonIcons.arrow_left,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
}
