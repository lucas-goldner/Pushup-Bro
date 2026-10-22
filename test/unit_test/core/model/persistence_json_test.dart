import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/friend.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// Round-trips through a JSON string, exactly like `DBProvider` does when it
/// writes to and reads from MMKV.
Map<String, dynamic> roundTrip(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  group('GameInventory', () {
    test('survives a JSON round trip', () {
      final inventory = GameInventory(
        bananas: 1234,
        boughtItems: const [
          ShopBuyables.accessories,
          ShopBuyables.accessoryPartyHat,
        ],
        monkeys: [
          AdoptableMonkey(
            name: 'Carlos',
            xp: 42,
            look: const MonkeyLook(
              fur: 'fur.mint',
              hat: 'hat.crown',
              matPattern: 'pattern.stars',
            ),
          ),
        ],
        ownedCosmetics: const ['fur.mint', 'hat.crown', 'pattern.stars'],
        quests: const QuestLog().complete('volcano', DateTime(2026, 10, 22)),
      );

      final decoded = GameInventory.fromJson(roundTrip(inventory));

      expect(decoded.bananas, 1234);
      expect(decoded.boughtItems, inventory.boughtItems);
      expect(decoded.monkeys.single.name, 'Carlos');
      expect(decoded.monkeys.single.xp, 42);
      expect(decoded.monkeys.single.look, inventory.monkeys.single.look);
      expect(decoded.ownedCosmetics, containsAll(inventory.ownedCosmetics));
      expect(decoded.quests, inventory.quests);
      expect(decoded.quests.completedOn(DateTime(2026, 10, 22, 23)), isTrue);
    });

    test('carries a party hat from before the wardrobe over', () {
      final decoded = GameInventory.fromJson(const {
        'bananas': 3,
        'boughtItems': ['accessories', 'accessoryPartyHat'],
        'monkeys': [
          {'name': 'Carlos', 'xp': 0, 'accessory': 'accessoryPartyHat'},
        ],
      });

      expect(decoded.monkeys.single.look.hat, 'hat.party');
      // Saving and loading again doesn't pile up copies.
      final again = GameInventory.fromJson(roundTrip(decoded));
      expect(
        again.ownedCosmetics.where((id) => id == 'hat.party'),
        hasLength(1),
      );
      expect(decoded.owns('hat.party'), isTrue);
      expect(decoded.owns('hat.crown'), isFalse);
      // The starting look is always owned.
      expect(decoded.owns('fur.charcoal'), isTrue);
    });

    test('ignores cosmetics it no longer knows', () {
      final look = MonkeyLook.fromJson(const {'hat': 'hat.gone', 'fur': 'x'});

      expect(look, const MonkeyLook());
    });

    test('drops bought items it no longer knows', () {
      final decoded = GameInventory.fromJson(const {
        'bananas': 3,
        'boughtItems': ['gym', 'removedBuilding'],
        'monkeys': <Map<String, dynamic>>[],
      });

      expect(decoded.boughtItems, [ShopBuyables.gym]);
    });

    test('falls back to Carlos when no monkeys were stored', () {
      final decoded = GameInventory.fromJson(const {'bananas': 3});

      expect(decoded.monkeys.single.name, 'Carlos');
    });
  });

  test('User survives a JSON round trip', () {
    final user = User(
      level: 7,
      xp: 120,
      name: 'Bro',
      image: 'bro.png',
      streak: 3,
      longestStreak: 9,
      friends: [
        Friend(id: 'f1', name: 'Pal', streak: 2, sharedStreak: 1),
      ],
    );

    final decoded = User.fromJson(roundTrip(user));

    expect(decoded.toJson(), user.toJson());
    expect(decoded.friends.single.hasSharedStreakGoing, isTrue);
  });

  test('PushupSet keeps the format written by 1.x', () {
    // The exact shape `pushup_sets` entries have on devices running 1.x, so
    // existing workout history keeps loading after the 2.0 update.
    final legacy = {
      'id': 1728000000000000,
      'pushups': [
        {'completedAt': '2026-10-04T12:00:00.000'},
        {'completedAt': null},
      ],
      'effort': 3,
    };

    final decoded = PushupSet.fromJson(legacy);

    expect(decoded.id, 1728000000000000);
    expect(decoded.effort, 3);
    expect(decoded.pushups.first.completedAt, DateTime(2026, 10, 4, 12));
    expect(decoded.toJson(), legacy);
  });

  test('PushupSet.copyWith keeps the id so deletes still match', () {
    final set = PushupSet([Pushup(completedAt: DateTime(2026))], 0);

    expect(set.copyWith(effort: 4).id, set.id);
  });
}
