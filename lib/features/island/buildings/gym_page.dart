import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/audio/music_scope.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/one_move.dart';
import 'package:pushup_bro/features/island/buildings/gym/gym_challenge_page.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_log.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_reward.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_coach_stage.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_today_card.dart';

/// The gym on the island: Grandpa Gus's daily workout, one of a kind only
/// the gym hands out, the gym streak with its gear gifts, and the workouts
/// coming up on the next days.
class GymPage extends StatefulWidget {
  const GymPage({this.showScene = true, super.key});

  /// The 3D gym behind the header (off in widget tests).
  final bool showScene;

  @override
  State<GymPage> createState() => _GymPageState();
}

class _GymPageState extends State<GymPage> with OneMove {
  /// Keeps the countdown to the next workout ticking, and swaps the
  /// workout at midnight.
  Timer? _clock;
  bool _white = false;

  /// Scrolled far enough that the cards pass under the top bar, which
  /// then gets a backdrop.
  final ValueNotifier<bool> _scrolled = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    unawaited(context.read<DBCubit>().getAllPushupSets());
    _clock = Timer.periodic(
      const Duration(seconds: 20),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scrolled.dispose();
    super.dispose();
  }

  Future<void> _start(GymChallenge challenge, {required bool replay}) =>
      oneMove(() async {
        GameAudio.instance.play(Sfx.whoosh);
        setState(() => _white = true);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        // This page fades through white itself, so the route swaps in an
        // instant while the screen is white.
        await Navigator.of(context).push(
          PageRouteBuilder<bool>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => MusicScope(
              track: MusicTrack.challenge,
              child: GymChallengePage(challenge: challenge, replay: replay),
            ),
          ),
        );
        if (mounted) setState(() => _white = false);
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final sets = context.watch<DBCubit>().state.pushupSets;
    final inventory = context.watch<GameInventoryCubit>().state.inventory;
    final log = inventory.gym;
    final challenge = todaysGymChallenge(sets, now);
    final done = log.completedOn(now);
    final upcoming = _upcoming(now, gymPlayerSeed(sets, now));
    final safe = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final sceneHeight = (size.height * 0.34).clamp(180.0, 320.0);
    final scheme = context.colorScheme;

    // The home gym's music, in the island's gym.
    return MusicScope(
      track: MusicTrack.home,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.secondaryContainer,
                      scheme.surfaceContainerLow,
                    ],
                    stops: const [0, 0.5],
                  ),
                ),
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _scrolled.value =
                    notification.metrics.pixels > sceneHeight - 40;

                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: safe.top + sceneHeight,
                      child: widget.showScene
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                GymCoachStage(
                                  tracking: false,
                                  look: inventory.monkeys.first.look,
                                  mood: done
                                      ? CoachMood.cheering
                                      : CoachMood.watching,
                                ),
                                // The gym floor fades into the page.
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 48,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            scheme.surfaceContainerLow
                                                .withValues(alpha: 0),
                                            scheme.surfaceContainerLow,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      PBSpace.lg,
                      0,
                      PBSpace.lg,
                      safe.bottom + PBSpace.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GymTodayCard(
                                  challenge: challenge,
                                  done: done,
                                  nextIn: GymChallenge.untilNext(now),
                                  onStart: () => unawaited(
                                    _start(challenge, replay: done),
                                  ),
                                ),
                                const SizedBox(height: PBSpace.lg),
                                _StreakCard(
                                  log: log,
                                  now: now,
                                  owns: inventory.owns,
                                ),
                                const SizedBox(height: PBSpace.xl),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: PBSpace.xs),
                                  child: Text(
                                    l.gymWorkouts,
                                    style: context.textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(height: PBSpace.md),
                                for (final (kind, days) in upcoming) ...[
                                  _WorkoutRow(
                                    kind: kind,
                                    days: days,
                                    wins: log.completed[kind.name] ?? 0,
                                  ),
                                  const SizedBox(height: PBSpace.sm),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: safe.top + 72,
              child: IgnorePointer(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _scrolled,
                  builder: (context, scrolled, _) => AnimatedOpacity(
                    opacity: scrolled ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.surfaceContainerLow,
                            scheme.surfaceContainerLow.withValues(alpha: 0),
                          ],
                          stops: const [0.7, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: safe.top + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: context.cardShadow,
                    ),
                    child: Material(
                      color: scheme.surface,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            CarbonIcons.arrow_left,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: PBSpace.md),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(PBRadius.pill),
                        boxShadow: context.cardShadow,
                      ),
                      child: Text(
                        '🏋️ ${l.buildingGym}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _white ? 1 : 0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: ColoredBox(color: context.gameColors.flash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Every kind of workout and in how many days it's next on, soonest
  /// first.
  static List<(GymChallengeKind, int)> _upcoming(DateTime now, int seed) {
    final next = <GymChallengeKind, int>{};
    final count = GymChallengeKind.values.length;
    for (var day = 0; next.length < count && day < count * 3; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      next.putIfAbsent(
        GymChallenge.kindForDay(date, seed: seed),
        () => day,
      );
    }

    return [
      for (final MapEntry(:key, :value) in next.entries) (key, value),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
  }
}

/// The gym streak, the week towards the next piece of gear, and the best.
class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.log,
    required this.now,
    required this.owns,
  });

  final GymLog log;
  final DateTime now;

  /// Whether the player owns a cosmetic.
  final bool Function(String id) owns;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final scheme = context.colorScheme;
    final streak = log.streakOn(now);
    final doneToday = log.completedOn(now);
    // Days of this week's run that are done.
    final filled = streak == 0
        ? 0
        : streak % kGymGiftEvery == 0 && doneToday
            ? kGymGiftEvery
            : streak % kGymGiftEvery;
    final gear = kGymGear.where((id) => !owns(id)).firstOrNull;
    final left = doneToday && filled == kGymGiftEvery
        ? kGymGiftEvery
        : kGymGiftEvery - filled;

    return SheetCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(PBSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SheetBadge('🔥', color: game.orange, size: 48),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.gymStreak, style: context.textTheme.bodySmall),
                    Text(
                      l.statsDays(streak),
                      style: context.textTheme.headlineSmall,
                    ),
                    if (log.bestStreak > 0)
                      Text(
                        '${l.statsBestStreak}: '
                        '${l.statsDays(log.bestStreak)}',
                        style: context.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var day = 1; day <= kGymGiftEvery; day++) ...[
                if (day > 1) const SizedBox(width: 6),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: day <= filled
                            ? game.orange
                            : scheme.surfaceContainerHigh,
                      ),
                      child: day == kGymGiftEvery
                          ? const FittedBox(
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: Text('🎁'),
                              ),
                            )
                          : day <= filled
                              ? Icon(
                                  CarbonIcons.checkmark,
                                  size: 14,
                                  color: game.onGame,
                                )
                              : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            gear == null ? l.gymGiftCrateIn(left) : l.gymGiftIn(left),
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({
    required this.kind,
    required this.days,
    required this.wins,
  });

  final GymChallengeKind kind;

  /// Days until it's on (0: today).
  final int days;
  final int wins;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = days == 0;

    return SheetCard(
      selected: today,
      padding: const EdgeInsets.all(PBSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetBadge(kind.emoji, size: 44),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.title(l), style: context.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  kind.description(l),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall,
                ),
                const SizedBox(height: PBSpace.sm),
                Wrap(
                  spacing: PBSpace.sm,
                  runSpacing: PBSpace.xs,
                  children: [
                    SheetTag(
                      switch (days) {
                        0 => l.gymToday,
                        1 => l.gymTomorrow,
                        _ => l.gymInDays(days),
                      },
                      icon: today ? CarbonIcons.star_filled : CarbonIcons.time,
                      color:
                          today ? null : context.colorScheme.onSurfaceVariant,
                    ),
                    if (wins > 0)
                      SheetTag(
                        l.gymWonTimes(wins),
                        color: context.gameColors.jungle,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
