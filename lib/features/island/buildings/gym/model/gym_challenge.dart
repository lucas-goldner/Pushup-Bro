import 'dart:math' as math;

import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// The workouts only the gym hands out, one a day.
enum GymChallengeKind {
  pyramid('🔺'),
  tempo('🐢'),
  emom('⏱️'),
  maxSet('💥'),
  burner('🔥'),
  plankPress('🧱'),
  deckOfCards('🃏'),
  gusDrill('📣');

  const GymChallengeKind(this.emoji);

  final String emoji;

  String title(S l) => switch (this) {
        pyramid => l.gymPyramid,
        tempo => l.gymTempo,
        emom => l.gymEmom,
        maxSet => l.gymMaxSet,
        burner => l.gymBurner,
        plankPress => l.gymPlankPress,
        deckOfCards => l.gymDeck,
        gusDrill => l.gymGusDrill,
      };

  String description(S l) => switch (this) {
        pyramid => l.gymPyramidInfo,
        tempo => l.gymTempoInfo,
        emom => l.gymEmomInfo,
        maxSet => l.gymMaxSetInfo,
        burner => l.gymBurnerInfo,
        plankPress => l.gymPlankPressInfo,
        deckOfCards => l.gymDeckInfo,
        gusDrill => l.gymGusDrillInfo,
      };
}

/// One part of a gym workout.
sealed class GymBlock {
  const GymBlock();
}

/// Pushups to do. With a [window], they have to be done within that many
/// seconds; with [holdWindow] the rest of the window is a rest once they
/// are (every minute on the minute). An [openEnded] block passes at [reps]
/// but keeps counting until its window runs out or the set stops.
class RepBlock extends GymBlock {
  const RepBlock(
    this.reps, {
    this.window,
    this.holdWindow = false,
    this.openEnded = false,
    this.tag,
  });

  final int reps;
  final double? window;
  final bool holdWindow;
  final bool openEnded;

  /// What the block is called on screen, like a card: "♠ 7".
  final String? tag;
}

/// A breather between sets.
class RestBlock extends GymBlock {
  const RestBlock(this.seconds);

  final double seconds;
}

/// A plank held for [seconds]; pushups don't count while it lasts.
class PlankBlock extends GymBlock {
  const PlankBlock(this.seconds);

  final double seconds;
}

/// How strong the player is, from their sets before today, so a day's
/// targets don't move while they train.
class GymStrength {
  const GymStrength({required this.typical, required this.best});

  factory GymStrength.fromSets(List<PushupSet> sets, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final earlier = [
      for (final set in sets)
        if (set.pushups.isNotEmpty && set.startedDate.isBefore(today)) set,
    ]..sort((a, b) => b.startedDate.compareTo(a.startedDate));
    if (earlier.isEmpty) return beginner;

    final best = earlier.map((set) => set.pushups.length).reduce(math.max);
    // A typical set is the median of the last ten in the past month; a
    // player back after a break gets most of their best.
    final monthAgo = today.subtract(const Duration(days: 30));
    final recent = [
      for (final set in earlier.take(10))
        if (!set.startedDate.isBefore(monthAgo)) set.pushups.length,
    ]..sort();
    final typical =
        recent.isEmpty ? (best * 0.7).round() : recent[recent.length ~/ 2];

    return GymStrength(typical: math.max(typical, 1), best: best);
  }

  /// A typical set's pushups.
  final int typical;

  /// The most pushups in one set, ever (0 with no sets).
  final int best;

  /// A beginner's: no sets yet.
  static const beginner = GymStrength(typical: 8, best: 0);
}

/// A seed for the player, so bros don't all get the same day's workout:
/// the id of their first set before today (0 without one).
int gymPlayerSeed(List<PushupSet> sets, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  int? first;
  for (final set in sets) {
    if (set.pushups.isEmpty || !set.startedDate.isBefore(today)) continue;
    if (first == null || set.id < first) first = set.id;
  }

  return (first ?? 0) % 1000003;
}

/// A gym workout with its targets set for the player.
class GymChallenge {
  const GymChallenge({
    required this.kind,
    required this.blocks,
    required this.passMark,
    this.tempoSeconds,
    this.idleCutoff,
    this.best = 0,
  });

  /// Built for a player of [strength]; [day] shuffles the deck of cards.
  factory GymChallenge.build(
    GymChallengeKind kind,
    GymStrength strength, {
    int day = 0,
  }) {
    final t = strength.typical.clamp(4, 60);
    int scaled(double factor, int min, int max) =>
        (t * factor).round().clamp(min, max);

    switch (kind) {
      case GymChallengeKind.pyramid:
        final peak = scaled(0.45, 2, 8);
        final steps = [
          for (var i = 1; i <= peak; i++) i,
          for (var i = peak - 1; i >= 1; i--) i,
        ];

        return GymChallenge(
          kind: kind,
          blocks: _withRests([for (final n in steps) RepBlock(n)], 8),
          passMark: steps.length,
        );
      case GymChallengeKind.tempo:
        return GymChallenge(
          kind: kind,
          blocks: [RepBlock(scaled(0.5, 3, 15))],
          passMark: 1,
          tempoSeconds: kTempoMinSeconds,
        );
      case GymChallengeKind.emom:
        final reps = scaled(0.4, 2, 15);

        return GymChallenge(
          kind: kind,
          blocks: [
            for (var i = 0; i < 5; i++)
              RepBlock(reps, window: 60, holdWindow: true),
          ],
          passMark: 5,
        );
      case GymChallengeKind.maxSet:
        final best = strength.best;

        return GymChallenge(
          kind: kind,
          blocks: [
            RepBlock(best > 0 ? best + 1 : t + 2, openEnded: true),
          ],
          passMark: 1,
          idleCutoff: 8,
          best: best,
        );
      case GymChallengeKind.burner:
        return GymChallenge(
          kind: kind,
          blocks: [RepBlock(scaled(1.6, 8, 150), window: 120, openEnded: true)],
          passMark: 1,
        );
      case GymChallengeKind.plankPress:
        final plank = ((15 + t) / 5).round().clamp(4, 9) * 5.0;
        final reps = scaled(0.4, 3, 12);

        return GymChallenge(
          kind: kind,
          blocks: [
            for (var round = 0; round < 3; round++) ...[
              if (round > 0) const RestBlock(10),
              PlankBlock(plank),
              RepBlock(reps),
            ],
          ],
          passMark: 3,
        );
      case GymChallengeKind.deckOfCards:
        final high = scaled(0.6, 4, 13);
        final low = math.max(2, (high / 3).round());
        final random = math.Random(day * 31 + 7);
        const suits = ['♠', '♥', '♣', '♦'];

        return GymChallenge(
          kind: kind,
          blocks: _withRests(
            [
              for (var i = 0; i < 6; i++)
                () {
                  final value = low + random.nextInt(high - low + 1);

                  return RepBlock(
                    value,
                    tag: '${suits[random.nextInt(4)]} ${_rank(value)}',
                  );
                }(),
            ],
            6,
          ),
          passMark: 6,
        );
      case GymChallengeKind.gusDrill:
        final reps = scaled(0.4, 3, 12);
        final calls = [reps, reps + 1, math.max(2, reps - 1), reps + 2, reps];

        return GymChallenge(
          kind: kind,
          blocks: _withRests(
            [
              for (final n in calls)
                RepBlock(
                  n,
                  window: (n * 2.5 + 5).clamp(12, 40).roundToDouble(),
                ),
            ],
            12,
          ),
          passMark: 4,
        );
    }
  }

  /// Today's workout for a player of [strength] (and [seed]).
  factory GymChallenge.forDay(
    DateTime date,
    GymStrength strength, {
    int seed = 0,
  }) =>
      GymChallenge.build(
        kindForDay(date, seed: seed),
        strength,
        day: dayNumber(date) + seed,
      );

  final GymChallengeKind kind;
  final List<GymBlock> blocks;

  /// Rep blocks that have to be passed to win.
  final int passMark;

  /// A rep only counts when the way down took at least this long.
  final double? tempoSeconds;

  /// The set ends after this long without a rep (once it's started).
  final double? idleCutoff;

  /// The best set to beat, for a max set.
  final int best;

  /// Extra bananas for winning: more than any jungle quest's.
  static const bonus = 80;

  /// Bananas per pushup, when won.
  static const bananaMultiplier = 2;

  List<RepBlock> get repBlocks => blocks.whereType<RepBlock>().toList();

  /// Pushups to do in all.
  int get target => repBlocks.fold(0, (sum, block) => sum + block.reps);

  /// Bananas earned for [pushups] pushups.
  int reward({required int pushups, required bool won}) =>
      won ? pushups * bananaMultiplier + bonus : pushups;

  /// What it takes, in a line.
  String goal(S l) {
    final reps = repBlocks;
    final first = reps.first;

    return switch (kind) {
      GymChallengeKind.pyramid => l.gymPyramidGoal(
          reps.map((block) => block.reps).reduce(math.max),
          target,
        ),
      GymChallengeKind.tempo => l.gymTempoGoal(first.reps),
      GymChallengeKind.emom => l.gymEmomGoal(first.reps, reps.length),
      GymChallengeKind.maxSet => l.gymMaxSetGoal(first.reps),
      GymChallengeKind.burner =>
        l.gymBurnerGoal(first.reps, (first.window ?? 0).round()),
      GymChallengeKind.plankPress => l.gymPlankPressGoal(
          reps.length,
          blocks.whereType<PlankBlock>().first.seconds.round(),
          first.reps,
        ),
      GymChallengeKind.deckOfCards => l.gymDeckGoal(reps.length, target),
      GymChallengeKind.gusDrill => l.gymGusDrillGoal(reps.length, passMark),
    };
  }

  /// Which workout the gym hands out on [date]: every kind once in a
  /// shuffled round, a new round after that, never the same two days in a
  /// row. [seed] gives each player their own order.
  static GymChallengeKind kindForDay(DateTime date, {int seed = 0}) {
    final count = GymChallengeKind.values.length;
    final day = dayNumber(date);

    return _round(day ~/ count, seed)[day % count];
  }

  /// The kinds in round [round]; when it would start with the kind the
  /// last round ended with, its first two swap.
  static List<GymChallengeKind> _round(int round, int seed) {
    final order = _shuffled(round, seed);
    if (order.first == _shuffled(round - 1, seed).last) {
      order
        ..[0] = order[1]
        ..[1] = _shuffled(round - 1, seed).last;
    }

    return order;
  }

  static List<GymChallengeKind> _shuffled(int round, int seed) =>
      List.of(GymChallengeKind.values)
        ..shuffle(math.Random(round * 7919 + seed * 104729 + 17));

  /// How long until the next workout: local midnight.
  static Duration untilNext(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).difference(now);
}

/// A rep only counts in a tempo set when the way down took this long; the
/// guide shows three seconds, this leaves a little slack.
const kTempoMinSeconds = 2.5;

List<GymBlock> _withRests(List<RepBlock> sets, double rest) => [
      for (final (i, set) in sets.indexed) ...[
        if (i > 0) RestBlock(rest),
        set,
      ],
    ];

String _rank(int value) => switch (value) {
      1 => 'A',
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      _ => '$value',
    };

/// The gym's workout on [now] for the player who did [sets].
GymChallenge todaysGymChallenge(List<PushupSet> sets, DateTime now) =>
    GymChallenge.forDay(
      now,
      GymStrength.fromSets(sets, now),
      seed: gymPlayerSeed(sets, now),
    );
