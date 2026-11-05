import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// A set of [count] pushups at [at].
PushupSet setOf(int count, DateTime at, {int? id}) => PushupSet(
      [
        for (var i = 0; i < count; i++)
          Pushup(completedAt: at.add(Duration(seconds: i * 2))),
      ],
      3,
      id: id,
    );

void main() {
  group('the daily pick', () {
    test('is the same all day and changes at local midnight', () {
      final morning = DateTime(2026, 11, 5, 0, 0, 1);
      final night = DateTime(2026, 11, 5, 23, 59, 59);
      final tomorrow = DateTime(2026, 11, 6);
      expect(
        GymChallenge.kindForDay(night),
        GymChallenge.kindForDay(morning),
      );
      expect(
        GymChallenge.kindForDay(tomorrow),
        isNot(GymChallenge.kindForDay(night)),
      );
    });

    test('never repeats two days in a row', () {
      for (final seed in [0, 1, 42, 999]) {
        var day = DateTime(2026);
        var previous = GymChallenge.kindForDay(day, seed: seed);
        for (var i = 0; i < 400; i++) {
          day = DateTime(day.year, day.month, day.day + 1);
          final kind = GymChallenge.kindForDay(day, seed: seed);
          expect(kind, isNot(previous), reason: '$day, seed $seed');
          previous = kind;
        }
      }
    });

    test('hands out every kind once in each round', () {
      final count = GymChallengeKind.values.length;
      // The first day of a round.
      var day = DateTime(2026, 11);
      while (dayNumber(day) % count != 0) {
        day = DateTime(day.year, day.month, day.day + 1);
      }
      for (var round = 0; round < 10; round++) {
        final kinds = {
          for (var i = 0; i < count; i++)
            GymChallenge.kindForDay(
              DateTime(day.year, day.month, day.day + round * count + i),
            ),
        };
        expect(kinds, GymChallengeKind.values.toSet());
      }
    });

    test('differs between players', () {
      final days = [
        for (var i = 0; i < 16; i++) DateTime(2026, 11, 1 + i),
      ];
      final a = days.map((d) => GymChallenge.kindForDay(d, seed: 1)).toList();
      final b = days.map((d) => GymChallenge.kindForDay(d, seed: 2)).toList();
      expect(a, isNot(b));
    });

    test('keeps its targets all day, even after more sets today', () {
      final now = DateTime(2026, 11, 5, 9);
      final history = [setOf(20, DateTime(2026, 11, 3, 18), id: 7)];
      final before = todaysGymChallenge(history, now);
      final after = todaysGymChallenge(
        [...history, setOf(60, DateTime(2026, 11, 5, 8))],
        DateTime(2026, 11, 5, 22),
      );
      expect(after.kind, before.kind);
      expect(after.target, before.target);
    });

    test('counts down to midnight', () {
      expect(
        GymChallenge.untilNext(DateTime(2026, 11, 5, 23, 59, 30)),
        const Duration(seconds: 30),
      );
      expect(
        GymChallenge.untilNext(DateTime(2026, 11, 5, 18)),
        const Duration(hours: 6),
      );
    });
  });

  group('strength', () {
    final now = DateTime(2026, 11, 5, 12);

    test('is a beginner without sets', () {
      final strength = GymStrength.fromSets(const [], now);
      expect(strength.typical, GymStrength.beginner.typical);
      expect(strength.best, 0);
    });

    test('uses the median recent set and the best ever, not today', () {
      final strength = GymStrength.fromSets(
        [
          setOf(10, DateTime(2026, 11, 4)),
          setOf(30, DateTime(2026, 11, 3)),
          setOf(12, DateTime(2026, 11, 2)),
          setOf(40, DateTime(2026, 6)),
          setOf(99, DateTime(2026, 11, 5, 8)),
        ],
        now,
      );
      expect(strength.best, 40);
      expect(strength.typical, 12);
    });

    test('remembers most of the best after a long break', () {
      final strength =
          GymStrength.fromSets([setOf(20, DateTime(2026, 3))], now);
      expect(strength.typical, 14);
      expect(strength.best, 20);
    });
  });

  group('targets', () {
    const weak = GymStrength(typical: 5, best: 7);
    const strong = GymStrength(typical: 40, best: 55);

    test('grow with the player for every kind', () {
      for (final kind in GymChallengeKind.values) {
        final easy = GymChallenge.build(kind, weak);
        final hard = GymChallenge.build(kind, strong);
        expect(hard.target, greaterThan(easy.target), reason: kind.name);
      }
    });

    test('stay doable for a beginner', () {
      for (final kind in GymChallengeKind.values) {
        final challenge = GymChallenge.build(kind, GymStrength.beginner);
        expect(challenge.target, greaterThan(0), reason: kind.name);
        for (final set in challenge.repBlocks) {
          expect(set.reps, lessThanOrEqualTo(16), reason: kind.name);
        }
      }
    });

    test('a pyramid climbs to a peak and back down', () {
      final pyramid = GymChallenge.build(
        GymChallengeKind.pyramid,
        const GymStrength(typical: 10, best: 15),
      );
      expect(
        pyramid.repBlocks.map((set) => set.reps),
        [1, 2, 3, 4, 5, 4, 3, 2, 1],
      );
      expect(pyramid.target, 25);
      expect(pyramid.blocks.whereType<RestBlock>(), hasLength(8));
    });

    test('a max set is one more than the best', () {
      final max = GymChallenge.build(GymChallengeKind.maxSet, strong);
      expect(max.target, 56);
      expect(max.best, 55);
    });

    test('pays more than any jungle quest', () {
      final challenge = GymChallenge.build(GymChallengeKind.tempo, weak);
      expect(challenge.reward(pushups: 10, won: true), 100);
      expect(challenge.reward(pushups: 10, won: false), 10);
    });

    test('a deck shuffles by day', () {
      final a = GymChallenge.build(
        GymChallengeKind.deckOfCards,
        strong,
        day: 1,
      );
      final b = GymChallenge.build(
        GymChallengeKind.deckOfCards,
        strong,
        day: 2,
      );
      expect(a.repBlocks, hasLength(6));
      expect(
        a.repBlocks.map((set) => set.tag),
        isNot(b.repBlocks.map((set) => set.tag)),
      );
    });

    test('has a goal line in every language', () async {
      for (final locale in S.delegate.supportedLocales) {
        final l = await S.load(locale);
        for (final kind in GymChallengeKind.values) {
          final challenge = GymChallenge.build(kind, strong);
          expect(challenge.goal(l), isNotEmpty);
          expect(kind.title(l), isNotEmpty);
          expect(kind.description(l), isNotEmpty);
        }
      }
    });
  });
}
