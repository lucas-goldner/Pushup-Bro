import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/features/share/model/flex_stat.dart';
import 'package:pushup_bro/features/share/model/recap.dart';

/// A set of [count] pushups finished on [day].
PushupSet setOn(DateTime day, int count) => PushupSet(
      [
        for (var i = 0; i < count; i++)
          Pushup(completedAt: day.add(Duration(seconds: i * 2))),
      ],
      5,
      id: day.microsecondsSinceEpoch + count,
    );

void main() {
  final now = DateTime(2026, 10, 28, 19);

  group('pickFlexStats', () {
    test('never shows a drop or a zero', () {
      final picked = pickFlexStats(
        gains: const [
          FlexStat(FlexKind.moreThanLast, -5),
          FlexStat(FlexKind.kcal, 0),
        ],
        fillers: const [FlexStat(FlexKind.total, 300)],
      );
      expect(picked, const [FlexStat(FlexKind.total, 300)]);
    });

    test('puts gains before fillers and keeps four', () {
      final picked = pickFlexStats(
        gains: const [
          FlexStat(FlexKind.moreThanLast, 10),
          FlexStat(FlexKind.kcal, 50),
        ],
        fillers: const [
          FlexStat(FlexKind.total, 300),
          FlexStat(FlexKind.bananas, 40),
          FlexStat(FlexKind.streak, 3),
        ],
      );
      expect(picked.map((s) => s.kind), [
        FlexKind.moreThanLast,
        FlexKind.kcal,
        FlexKind.total,
        FlexKind.bananas,
      ]);
    });

    test('shows each kind once', () {
      final picked = pickFlexStats(
        gains: const [FlexStat(FlexKind.streak, 12)],
        fillers: const [FlexStat(FlexKind.streak, 12)],
      );
      expect(picked, hasLength(1));
    });
  });

  group('Recap.workout', () {
    test('flexes more than last time, calories and a new best', () {
      final recap = Recap.workout(
        set: setOn(now, 40),
        history: [
          setOn(now.subtract(const Duration(days: 2)), 32),
          setOn(now.subtract(const Duration(days: 1)), 30),
        ],
        now: now,
        weightKg: 82,
      );

      expect(recap.vsLast, 10);
      expect(recap.flex, [
        const FlexStat(FlexKind.moreThanLast, 10),
        const FlexStat(FlexKind.kcal, 15),
        const FlexStat(FlexKind.inARow, 40, best: true),
        const FlexStat(FlexKind.streak, 3),
      ]);
    });

    test('a smaller set than last time still only shows gains', () {
      final recap = Recap.workout(
        set: setOn(now, 20),
        history: [setOn(now.subtract(const Duration(days: 1)), 30)],
        now: now,
        weightKg: 82,
      );

      expect(
        recap.flex.map((s) => s.kind),
        isNot(contains(FlexKind.moreThanLast)),
      );
      expect(recap.flex.every((s) => s.value > 0), isTrue);
      expect(recap.flex.map((s) => s.kind), contains(FlexKind.total));
    });

    test('the very first set is not called a new best', () {
      final recap = Recap.workout(set: setOn(now, 12), history: [], now: now);

      expect(recap.flex.where((s) => s.best), isEmpty);
      expect(recap.flex, isNotEmpty);
    });
  });

  group('Recap.trek', () {
    test('marks a combo above every earlier stage as a new best', () {
      final recap = Recap.trek(
        title: 'Fern Trail',
        pushups: 30,
        damage: 412,
        bestCombo: 7,
        bestComboBefore: 5,
        stars: 3,
        bananas: 80,
        weightKg: 82,
      );

      expect(recap.flex, [
        const FlexStat(FlexKind.damage, 412),
        const FlexStat(FlexKind.combo, 7, best: true),
        const FlexStat(FlexKind.pushups, 30),
        const FlexStat(FlexKind.kcal, 11),
      ]);
    });

    test('a first combo is not a new best', () {
      final recap = Recap.trek(
        title: 'Fern Trail',
        pushups: 10,
        damage: 100,
        bestCombo: 3,
        bestComboBefore: 0,
        stars: 1,
        bananas: 60,
      );

      expect(recap.flex.where((s) => s.best), isEmpty);
    });
  });
}
