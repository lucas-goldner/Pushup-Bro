import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_log.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_reward.dart';

Map<String, dynamic> _roundTrip(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

DateTime _day(int day, [int hour = 18]) => DateTime(2026, 11, day, hour);

final _challenge = GymChallenge.build(
  GymChallengeKind.pyramid,
  const GymStrength(typical: 10, best: 15),
);

GymReward _win(GameInventory inventory, DateTime now, {int pushups = 25}) =>
    GymReward.settle(
      inventory: inventory,
      challenge: _challenge,
      pushups: pushups,
      won: true,
      replay: false,
      now: now,
    );

void main() {
  group('GymLog', () {
    test('a win counts for the day it was won on', () {
      final log = const GymLog().complete('pyramid', _day(5, 23));
      expect(log.completedOn(_day(5, 1)), isTrue);
      expect(log.completedOn(_day(6, 0)), isFalse);
      expect(log.completed, {'pyramid': 1});
    });

    test('the streak grows day by day and breaks after a missed day', () {
      var log = const GymLog();
      for (final day in [1, 2, 3]) {
        log = log.complete('tempo', _day(day));
      }
      expect(log.streak, 3);
      expect(log.streakOn(_day(4)), 3);
      expect(log.streakOn(_day(5)), 0);
      log = log.complete('emom', _day(6));
      expect(log.streak, 1);
      expect(log.bestStreak, 3);
      expect(log.total, 4);
    });

    test('two wins on one day are one day of streak', () {
      final log = const GymLog()
          .complete('tempo', _day(1, 8))
          .complete('tempo', _day(1, 20));
      expect(log.streak, 1);
    });

    test('survives a JSON round trip', () {
      final log =
          const GymLog().complete('pyramid', _day(1)).complete('emom', _day(2));
      expect(GymLog.fromJson(_roundTrip(log.toJson())), log);
    });
  });

  group('GameInventory', () {
    test('keeps the gym log through JSON', () {
      final inventory = GameInventory.empty().copyWith(
        gym: const GymLog().complete('burner', _day(3)),
      );
      // Monkeys compare by identity, so compare the parts that matter.
      final loaded = GameInventory.fromJson(_roundTrip(inventory.toJson()));
      expect(loaded.gym, inventory.gym);
      expect(loaded.toJson(), _roundTrip(inventory.toJson()));
    });

    test('loads an old save without one', () {
      final json = _roundTrip(GameInventory.empty().toJson())..remove('gym');
      expect(GameInventory.fromJson(json).gym, const GymLog());
    });
  });

  group('GymReward', () {
    test('a win pays double plus the bonus and grows the streak', () {
      final reward = _win(GameInventory.empty(), _day(5));
      expect(reward.bananas, 25 * 2 + GymChallenge.bonus);
      expect(reward.inventory.bananas, reward.bananas);
      expect(reward.streak, 1);
      expect(reward.inventory.gym.completedOn(_day(5)), isTrue);
      expect(reward.gift, isNull);
    });

    test('a loss or a replay pays a banana a pushup', () {
      final lost = GymReward.settle(
        inventory: GameInventory.empty(),
        challenge: _challenge,
        pushups: 12,
        won: false,
        replay: false,
        now: _day(5),
      );
      expect(lost.bananas, 12);
      expect(lost.inventory.gym, const GymLog());

      final won = _win(GameInventory.empty(), _day(5)).inventory;
      final replay = GymReward.settle(
        inventory: won,
        challenge: _challenge,
        pushups: 30,
        won: true,
        replay: true,
        now: _day(5, 21),
      );
      expect(replay.bananas, 30);
      expect(replay.inventory.gym, won.gym);
    });

    test('a week-long streak brings gym gear, then a banana crate', () {
      var inventory = GameInventory.empty();
      GymReward? reward;
      for (var day = 1; day <= 7; day++) {
        reward = _win(inventory, _day(day));
        inventory = reward.inventory;
        if (day < 7) expect(reward.gift, isNull);
      }
      expect(reward!.gift, kGymGear.first);
      expect(inventory.owns(kGymGear.first), isTrue);

      // With every piece owned, the crate instead.
      inventory = inventory.copyWith(ownedCosmetics: kGymGear);
      for (var day = 8; day <= 14; day++) {
        reward = _win(inventory, _day(day));
        inventory = reward.inventory;
      }
      expect(reward!.gift, isNull);
      expect(reward.crate, kGymGiftBananas);
      expect(reward.bananas, 25 * 2 + GymChallenge.bonus + kGymGiftBananas);
      expect(reward.streak, 14);
    });

    test('days to the next gift', () {
      expect(daysToGymGift(0), 7);
      expect(daysToGymGift(3), 4);
      expect(daysToGymGift(7), 7);
    });
  });
}
