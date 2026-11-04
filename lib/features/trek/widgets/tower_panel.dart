import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';
import 'package:pushup_bro/features/trek/model/tower_week.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';
import 'package:pushup_bro/features/trek/widgets/difficulty_picker.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// The Canopy Tower on the Trek map: the bests, this week's race between
/// bros, and the way up. Locked until King Komo is beaten.
class TowerPanel extends StatelessWidget {
  const TowerPanel({
    required this.trek,
    required this.onClimb,
    super.key,
  });

  final TrekProgress trek;
  final VoidCallback onClimb;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;
    final open = brutalUnlocked(trek);
    final week = towerWeekOf(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SheetBadge(TrekStage.tower.emoji, color: game.purple),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Text(
                  l.towerTitle,
                  style: text.headlineSmall?.copyWith(height: 1.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: PBSpace.sm),
          Text(
            open ? l.towerBlurb : l.towerLocked,
            style: text.bodyMedium?.copyWith(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (open) ...[
            const SizedBox(height: PBSpace.md),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                SheetTag(
                  l.towerBest(trek.towerBest),
                  icon: CarbonIcons.trophy,
                  color: game.banana,
                ),
                SheetTag(
                  '${l.towerWeek}: ${l.towerFloor(trek.towerBestIn(week))}',
                  icon: CarbonIcons.calendar,
                  color: game.purple,
                ),
              ],
            ),
            const SizedBox(height: PBSpace.md),
            DifficultyPicker(trek: trek),
            const SizedBox(height: PBSpace.md),
            _BroRace(week: week, mine: trek.towerBestIn(week)),
            const SizedBox(height: PBSpace.md),
            PillButton(
              label: l.towerClimb,
              icon: CarbonIcons.arrow_up,
              color: game.purple,
              onPressed: onClimb,
            ),
          ] else ...[
            const SizedBox(height: 10),
            SheetTag(
              l.trekLocked,
              icon: CarbonIcons.locked,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

/// This week's best floors of the player and their bros, highest first.
class _BroRace extends StatelessWidget {
  const _BroRace({required this.week, required this.mine});

  final String week;
  final int mine;

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
        buildWhen: (previous, current) =>
            previous.status != current.status || previous.uid != current.uid,
        builder: (context, state) {
          final me = state.profile;
          if (state.status != AccountStatus.ready || me == null) {
            return const SizedBox.shrink();
          }

          return BlocProvider(
            key: ValueKey(me.uid),
            create: (context) =>
                BrosCubit(context.read<AccountCubit>().backend, me: me)
                  ..start(),
            child: BlocBuilder<BrosCubit, BrosState>(
              builder: (context, bros) => _Race(
                rows: [
                  for (final bro in bros.bros)
                    (bro.profile, bro.name, bro.profile.towerIn(week), false),
                  (me, '', mine, true),
                ]..sort((a, b) => b.$3.compareTo(a.$3)),
                alone: bros.loaded && bros.bros.isEmpty,
              ),
            ),
          );
        },
      );
}

class _Race extends StatelessWidget {
  const _Race({required this.rows, required this.alone});

  final List<(BroProfile, String, int, bool)> rows;
  final bool alone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.towerBros,
          style: text.labelMedium?.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (alone)
          Text(l.towerNoBros, style: text.bodySmall)
        else
          for (final (i, (profile, name, floor, isMe)) in rows.take(5).indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}', style: text.labelMedium),
                  ),
                  BroAvatar(look: profile.look, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMe ? l.boardYou : friendLabel(context, profile, name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: isMe ? FontWeight.w800 : null,
                      ),
                    ),
                  ),
                  Text(
                    l.towerFloor(floor),
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// The end of a climb: how high Carlos got, a new best, and the loot.
class TowerResult extends StatelessWidget {
  const TowerResult({required this.reward, required this.onDone, super.key});

  final TrekReward? reward;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;
    final reward = this.reward;
    final best = reward != null && reward.floor > reward.bestFloor;

    return ColoredBox(
      color: scheme.scrim.withValues(alpha: context.isDark ? 0.55 : 0.4),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: context.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🗼', style: TextStyle(fontSize: 46)),
                const SizedBox(height: PBSpace.sm),
                Text(
                  l.towerReached(reward?.floor ?? 0),
                  textAlign: TextAlign.center,
                  style: text.headlineMedium,
                ),
                if (best) ...[
                  const SizedBox(height: PBSpace.sm),
                  SheetTag(
                    l.towerNewBest,
                    icon: CarbonIcons.trophy,
                    color: game.banana,
                  ),
                ],
                if (reward != null) ...[
                  const SizedBox(height: PBSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '+${reward.xp}',
                          label: l.trekXpEarned,
                          icon: Icon(
                            CarbonIcons.star_filled,
                            color: scheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(
                          value: '+${reward.bananas}',
                          label: l.questBananas,
                          icon: Assets.images.island.banana.image(width: 28),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                PillButton(
                  label: l.trekBackToMap,
                  icon: CarbonIcons.map,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(PBRadius.md),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(value, style: context.textTheme.titleLarge),
            Text(label, style: context.textTheme.labelSmall),
          ],
        ),
      );
}
