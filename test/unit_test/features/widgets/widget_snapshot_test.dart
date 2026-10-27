import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/appearance.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/widgets/widget_snapshot.dart';
import 'package:pushup_bro/features/widgets/widget_sync.dart';

/// A set of [count] pushups done at [at].
PushupSet _set(DateTime at, int count) => PushupSet(
      [for (var i = 0; i < count; i++) Pushup(completedAt: at)],
      3,
      id: at.microsecondsSinceEpoch + count,
    );

const _plan =
    ProPlan(kind: ProPlanKind.yearly, price: r'$29.99', amount: 29.99);

void main() {
  // A Tuesday evening.
  final now = DateTime(2026, 10, 27, 20, 30);

  group('widgetDayKey', () {
    test('pads month and day', () {
      expect(widgetDayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });
  });

  group('lastSevenDays', () {
    test('counts pushups per day, oldest first, ending today', () {
      final days = lastSevenDays(
        [
          _set(DateTime(2026, 10, 27, 7), 12),
          _set(DateTime(2026, 10, 27, 19), 20),
          _set(DateTime(2026, 10, 25, 9), 15),
          _set(DateTime(2026, 10, 21, 0, 1), 8),
          // Older than seven days and in the future: left out.
          _set(DateTime(2026, 10, 20, 23, 59), 99),
          _set(DateTime(2026, 10, 28, 6), 99),
        ],
        now,
      );

      expect(days.map((d) => widgetDayKey(d.day)), [
        '2026-10-21',
        '2026-10-22',
        '2026-10-23',
        '2026-10-24',
        '2026-10-25',
        '2026-10-26',
        '2026-10-27',
      ]);
      expect(days.map((d) => d.pushups), [8, 0, 0, 0, 15, 0, 32]);
    });

    test('spans a month change', () {
      final days = lastSevenDays(
        [_set(DateTime(2026, 2, 28, 12), 5)],
        DateTime(2026, 3, 2, 8),
      );

      expect(widgetDayKey(days.first.day), '2026-02-24');
      expect(widgetDayKey(days.last.day), '2026-03-02');
      expect(days[4].pushups, 5);
    });

    test('is all zeros without pushups', () {
      final days = lastSevenDays(const [], now);
      expect(days, hasLength(7));
      expect(days.every((d) => d.pushups == 0), isTrue);
    });
  });

  group('workoutStreaks', () {
    test('counts the days in a row up to today', () {
      final streaks = workoutStreaks(
        [
          _set(DateTime(2026, 10, 27, 8), 10),
          _set(DateTime(2026, 10, 26, 8), 10),
          _set(DateTime(2026, 10, 25, 8), 10),
          _set(DateTime(2026, 10, 20, 8), 10),
        ],
        now,
      );

      expect(streaks.current, 3);
      expect(streaks.longest, 3);
      expect(streaks.lastWorkout, DateTime(2026, 10, 27));
    });

    test('keeps the streak while today can still continue it', () {
      final streaks = workoutStreaks(
        [
          _set(DateTime(2026, 10, 26, 8), 10),
          _set(DateTime(2026, 10, 25, 8), 10),
        ],
        now,
      );

      expect(streaks.current, 2);
    });

    test('ends the streak after a day off, keeping the longest', () {
      final streaks = workoutStreaks(
        [
          for (var day = 10; day <= 14; day++)
            _set(DateTime(2026, 10, day, 8), 10),
          _set(DateTime(2026, 10, 25, 8), 10),
        ],
        now,
      );

      expect(streaks.current, 0);
      expect(streaks.longest, 5);
      expect(streaks.lastWorkout, DateTime(2026, 10, 25));
    });

    test('is empty without pushups', () {
      final streaks = workoutStreaks(const [], now);
      expect(streaks.current, 0);
      expect(streaks.longest, 0);
      expect(streaks.lastWorkout, isNull);
    });
  });

  group('WidgetSnapshot', () {
    WidgetSnapshot snapshot({
      ProState pro = const ProState(isPro: true, loaded: true),
      TrekProgress trek = const TrekProgress(),
    }) =>
        WidgetSnapshot.from(
          pushupSets: [
            _set(DateTime(2026, 10, 27, 7), 32),
            _set(DateTime(2026, 10, 26, 7), 40),
          ],
          user: User.empty(),
          inventory: GameInventory.empty().copyWith(bananas: 640, trek: trek),
          pro: pro,
          language: 'de',
          appearance: Appearance.dark,
          now: now,
          stageTitle: (stage) => 'Stage ${stage.id}',
        );

    test('writes the JSON the widget extension reads', () {
      final json = snapshot().toJson();
      final first = TrekStage.all.first;

      expect(json, {
        'version': 1,
        'hasAccess': true,
        'isPro': true,
        'accessUntilMs': null,
        'streak': 2,
        'longestStreak': 2,
        'todayPushups': 32,
        'dailyGoal': kDefaultDailyGoal,
        'lastWorkoutDate': '2026-10-27',
        'days': [
          {'date': '2026-10-21', 'pushups': 0},
          {'date': '2026-10-22', 'pushups': 0},
          {'date': '2026-10-23', 'pushups': 0},
          {'date': '2026-10-24', 'pushups': 0},
          {'date': '2026-10-25', 'pushups': 0},
          {'date': '2026-10-26', 'pushups': 40},
          {'date': '2026-10-27', 'pushups': 32},
        ],
        'trek': {
          'stageNumber': 1,
          'stageCount': TrekStage.all.length,
          'title': 'Stage ${first.id}',
          'waves': first.waves.length,
          'boss': false,
          'allCleared': false,
        },
        'bananas': 640,
        'language': 'de',
        'appearance': 'dark',
      });
      // Survives a round trip as plain JSON.
      expect(jsonDecode(jsonEncode(json)), json);
    });

    test('points at the first stage not cleared', () {
      final cleared = TrekStage.all.take(2).fold(
            const TrekProgress(),
            (trek, stage) => trek.clear(stage.id, 3),
          );
      final trek = snapshot(trek: cleared).trek!;

      expect(trek.stageNumber, 3);
      expect(trek.title, 'Stage ${TrekStage.all[2].id}');
      expect(trek.allCleared, isFalse);
    });

    test('marks the trek done once every stage is cleared', () {
      final cleared = TrekStage.all.fold(
        const TrekProgress(),
        (trek, stage) => trek.clear(stage.id, 1),
      );
      final trek = snapshot(trek: cleared).trek!;

      expect(trek.allCleared, isTrue);
      expect(trek.stageNumber, TrekStage.all.length);
    });

    test('sends when the free days end, while they are all there is', () {
      final freeSince = now.subtract(const Duration(days: 1));
      final json = snapshot(
        pro: ProState(
          freeSince: freeSince,
          plans: const [_plan],
          storeAvailable: true,
          loaded: true,
        ),
      ).toJson();

      expect(json['hasAccess'], isTrue);
      expect(json['isPro'], isFalse);
      expect(
        json['accessUntilMs'],
        freeSince.add(const Duration(days: 3)).millisecondsSinceEpoch,
      );
    });

    test('is locked once the free days are over', () {
      final json = snapshot(
        pro: ProState(
          freeSince: now.subtract(const Duration(days: 5)),
          plans: const [_plan],
          storeAvailable: true,
          loaded: true,
        ),
      ).toJson();

      expect(json['hasAccess'], isFalse);
      expect(json['accessUntilMs'], isNull);
    });
  });

  group('WidgetSync', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('pushup_bro/widgets');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final sent = <Object?>[];

    setUp(() {
      sent.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'update');
        sent.add(call.arguments);
        return null;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    WidgetSnapshot snapshot(int bananas) => WidgetSnapshot(
          hasAccess: true,
          isPro: true,
          streak: 1,
          longestStreak: 1,
          days: const [],
          bananas: bananas,
          language: 'en',
          appearance: Appearance.system,
        );

    test('sends JSON and skips a snapshot it already sent', () async {
      final sync = WidgetSync(enabled: true);

      expect(await sync.push(snapshot(1)), isTrue);
      expect(await sync.push(snapshot(1)), isFalse);
      expect(await sync.push(snapshot(2)), isTrue);
      expect(sent, hasLength(2));
      expect(
        (jsonDecode(sent.last! as String) as Map<String, dynamic>)['bananas'],
        2,
      );
    });

    test('does nothing off iOS', () async {
      final sync = WidgetSync(enabled: false);

      expect(await sync.push(snapshot(1)), isFalse);
      expect(sent, isEmpty);
    });
  });
}
