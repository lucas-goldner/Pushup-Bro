import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/stats/model/game_stats.dart';
import 'package:pushup_bro/features/stats/model/pushup_stats.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// Wednesday, 28 October 2026, 18:00.
final _now = DateTime(2026, 10, 28, 18);

/// A set of [count] pushups starting at [start], one every [every].
PushupSet _set(
  DateTime start,
  int count, {
  Duration every = const Duration(seconds: 2),
  int effort = 0,
}) =>
    PushupSet(
      [
        for (var i = 0; i < count; i++)
          Pushup(completedAt: start.add(every * i)),
      ],
      effort,
      id: start.microsecondsSinceEpoch,
    );

void main() {
  group('PushupStats', () {
    test('is empty without sets', () {
      final stats = PushupStats.from(const [], _now);

      expect(stats.isEmpty, isTrue);
      expect(stats.total, 0);
      expect(stats.sets, 0);
      expect(stats.averageSet, 0);
      expect(stats.bestPace, isNull);
      expect(stats.firstDay, isNull);
      expect(stats.favouriteWeekday, isNull);
      expect(stats.favouriteDayTime, isNull);
      expect(stats.usualEffort, isNull);
      expect(stats.bars(StatsRange.week).map((bar) => bar.pushups), [
        for (var i = 0; i < 7; i++) 0,
      ]);
    });

    test('adds up the totals, records and streaks', () {
      final stats = PushupStats.from(
        [
          // Today, Wednesday evening: 20 and 10.
          _set(DateTime(2026, 10, 28, 18), 20, effort: 3),
          _set(DateTime(2026, 10, 28, 7), 10, effort: 3),
          // Tuesday: 25 in one go.
          _set(DateTime(2026, 10, 27, 19), 25, effort: 4),
          // Monday.
          _set(DateTime(2026, 10, 26, 19), 5),
          // Last month, a lonely morning.
          _set(DateTime(2026, 9, 2, 8), 12, effort: 1),
        ],
        _now,
        weightKg: 80,
      );

      expect(stats.total, 72);
      expect(stats.sets, 5);
      expect(stats.activeDays, 4);
      expect(stats.today, 30);
      expect(stats.thisWeek, 60);
      expect(stats.thisMonth, 60);
      expect(stats.bestSet, 25);
      expect(stats.bestDay, 30);
      expect(stats.bestDayDate, DateTime(2026, 10, 28));
      expect(stats.averageSet, 14);
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
      expect(stats.firstDay, DateTime(2026, 9, 2));
      expect(stats.kcal, (72 * 0.0045 * 80).round());
      // One pushup every 2 s: the 5-pushup set is the quickest a minute.
      expect(stats.bestPace, closeTo(5 * 60 / 8, 0.01));
      expect(stats.favouriteWeekday, DateTime.wednesday);
      expect(stats.favouriteDayTime, DayTime.evening);
      expect(stats.usualEffort, 3);
    });

    test('a pace needs a set of at least five pushups', () {
      final stats = PushupStats.from(
        [_set(_now, 4, every: const Duration(milliseconds: 500))],
        _now,
      );

      expect(stats.bestPace, isNull);
    });

    test('bars cover the last week, month and year', () {
      final stats = PushupStats.from(
        [
          _set(DateTime(2026, 10, 28, 9), 8),
          _set(DateTime(2026, 10, 22, 9), 3),
          _set(DateTime(2026, 10, 21, 9), 99),
          _set(DateTime(2025, 11, 30, 9), 4),
          _set(DateTime(2025, 10, 30, 9), 100),
        ],
        _now,
      );

      final week = stats.bars(StatsRange.week);
      expect(week, hasLength(7));
      expect(week.first.start, DateTime(2026, 10, 22));
      expect(week.last.start, DateTime(2026, 10, 28));
      expect(week.map((bar) => bar.pushups), [3, 0, 0, 0, 0, 0, 8]);

      final month = stats.bars(StatsRange.month);
      expect(month, hasLength(30));
      expect(month.fold(0, (sum, bar) => sum + bar.pushups), 110);

      final year = stats.bars(StatsRange.year);
      expect(year, hasLength(12));
      expect(year.first.start, DateTime(2025, 11));
      expect(year.first.pushups, 4);
      expect(year.last.pushups, 110);
    });

    test('the heatmap ends with this week and hides the days to come', () {
      final stats = PushupStats.from(
        [_set(DateTime(2026, 10, 26, 9), 6)],
        _now,
      );
      final weeks = stats.heatmap();

      expect(weeks, hasLength(kStatsHeatmapWeeks));
      expect(weeks.every((week) => week.length == 7), isTrue);
      // Monday of this week, today, and Thursday to Sunday.
      expect(weeks.last, [6, 0, 0, null, null, null, null]);
      expect(weeks.first.every((day) => day == 0), isTrue);
    });

    test('splits the day into morning, afternoon, evening and night', () {
      expect(DayTime.of(DateTime(2026, 1, 1, 4, 59)), DayTime.night);
      expect(DayTime.of(DateTime(2026, 1, 1, 5)), DayTime.morning);
      expect(DayTime.of(DateTime(2026, 1, 1, 12)), DayTime.afternoon);
      expect(DayTime.of(DateTime(2026, 1, 1, 17)), DayTime.evening);
      expect(DayTime.of(DateTime(2026, 1, 1, 22)), DayTime.night);
    });
  });

  group('GameStats', () {
    test('starts at nothing collected', () {
      final stats = GameStats.from(GameInventory.empty(), level: 1, xp: 0);

      expect(stats.level, 1);
      expect(stats.levelProgress, 0);
      expect(stats.bananas, 0);
      expect(stats.buildings.have, 0);
      expect(stats.buildings.of, ShopBuyables.buildingsShopBuyables.length);
      expect(stats.monkeys, 1);
      expect(stats.questsTotal, 0);
      expect(stats.quests.of, JungleQuest.all.length);
      expect(stats.trekStages, (have: 0, of: TrekStage.all.length));
      expect(stats.trekStars.of, TrekStage.all.length * 3);
      // The default look is always owned.
      expect(stats.cosmetics.have, greaterThan(0));
      expect(stats.cosmetics.of, Cosmetic.all.length);
    });

    test('counts the island, quests and the Trek', () {
      final first = TrekStage.all[0].id;
      final second = TrekStage.all[1].id;
      final quest = JungleQuest.all.first.id;
      final inventory = GameInventory.empty().copyWith(
        bananas: 420,
        boughtItems: [ShopBuyables.airport, ShopBuyables.accessoryPartyHat],
        quests: QuestLog(completed: {quest: 3, 'gone': 2}),
        trek: TrekProgress(
          level: 4,
          power: 2,
          agility: 1,
          stars: {first: 3, second: 1},
        ),
      );

      final stats = GameStats.from(inventory, level: 3, xp: 40);

      expect(stats.levelProgress, closeTo(0.5, 0.001));
      expect(stats.bananas, 420);
      // The party hat is no building.
      expect(stats.buildings.have, 1);
      expect(stats.questsTotal, 5);
      expect(stats.quests.have, 1);
      expect(stats.trekLevel, 4);
      expect(stats.trekStages.have, 2);
      expect(stats.trekStars.have, 4);
      expect(stats.power, 2);
      expect(stats.agility, 1);
    });
  });
}
