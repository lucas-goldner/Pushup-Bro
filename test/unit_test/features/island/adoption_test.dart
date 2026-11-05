import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/island_snapshot.dart';

Map<String, dynamic> _roundTrip(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

GameInventory _rich([int bananas = 100000]) =>
    GameInventory.empty().copyWith(bananas: bananas);

/// Adopts [count] candidates in a row.
GameInventory _adoptMany(int count, [GameInventory? from]) {
  var inventory = from ?? _rich();
  for (var i = 0; i < count; i++) {
    final candidate = Adoption.candidates(i).first;
    inventory = inventory.adopt(candidate)!;
  }
  return inventory;
}

void main() {
  group('prices', () {
    test('rise steeply, each well over double the last', () {
      for (var i = 1; i < Adoption.prices.length; i++) {
        expect(Adoption.prices[i], greaterThan(Adoption.prices[i - 1] * 2));
      }
    });

    test('follow the adoptions and stop at four', () {
      var inventory = _rich();
      final paid = <int>[];
      for (var i = 0; i < Adoption.maxExtras; i++) {
        final price = inventory.nextAdoptionPrice!;
        final before = inventory.bananas;
        inventory = inventory.adopt(Adoption.candidates(i).first)!;
        paid.add(before - inventory.bananas);
        expect(price, paid.last);
      }
      expect(paid, Adoption.prices);
      expect(inventory.monkeys, hasLength(5));
      expect(inventory.hasRoomForMonkey, isFalse);
      expect(inventory.nextAdoptionPrice, isNull);
      expect(inventory.adopt(Adoption.candidates(9).first), isNull);
    });

    test('free spots list what each will cost', () {
      expect(_rich().freeSpotPrices, Adoption.prices);
      expect(_adoptMany(2).freeSpotPrices, Adoption.prices.sublist(2));
    });

    test('need the bananas', () {
      final poor = _rich(Adoption.prices.first - 1);
      expect(poor.adopt(Adoption.candidates(1).first), isNull);
    });

    test('King Komo takes a spot but costs nothing', () {
      final withKomo = _rich().copyWith(
        monkeys: [
          AdoptableMonkey.carlos(),
          AdoptableMonkey(name: 'King Komo', look: MonkeyLook.kingKomo),
        ],
      );
      expect(withKomo.komoToCome, isFalse);
      expect(withKomo.nextAdoptionPrice, Adoption.prices.first);
      expect(withKomo.freeSpotPrices, Adoption.prices.sublist(0, 3));
      final full = _adoptMany(3, withKomo);
      expect(full.extras, hasLength(Adoption.maxExtras));
      expect(full.hasRoomForMonkey, isFalse);
    });
  });

  group('adopting', () {
    test('pays, moves in and brings their own clothes', () {
      final candidate = Adoption.candidates(3).first;
      final inventory = _rich().adopt(candidate)!;
      final adopted = inventory.monkeys.last;
      expect(inventory.bananas, 100000 - Adoption.prices.first);
      expect(adopted.adopted, isTrue);
      expect(adopted.trainsInGym, isTrue);
      expect(adopted.name, candidate.name);
      expect(adopted.look, candidate.look);
      for (final id in candidate.look.ids) {
        expect(inventory.owns(id), isTrue);
      }
    });

    test('candidates are cute, varied and never Trek trophies', () {
      for (var seed = 0; seed < 50; seed++) {
        final candidates = Adoption.candidates(seed, taken: const ['Mango']);
        expect(candidates, hasLength(3));
        expect({for (final c in candidates) c.name}, hasLength(3));
        expect({for (final c in candidates) c.look.fur}, hasLength(3));
        for (final candidate in candidates) {
          expect(candidate.name, isNot('Mango'));
          expect(candidate.personality, inInclusiveRange(0, 7));
          for (final id in candidate.look.ids) {
            expect(Cosmetic.byId(id)!.exclusive, isFalse);
          }
        }
      }
    });

    test('personalities already on the island come last', () {
      for (var seed = 0; seed < 20; seed++) {
        final candidates = Adoption.candidates(
          seed,
          takenPersonalities: const [0, 1, 2, 3, 4],
        );
        for (final candidate in candidates) {
          expect(candidate.personality, greaterThan(4));
        }
      }
    });

    test('the same seed meets the same monkeys', () {
      expect(
        Adoption.candidates(7).map((c) => c.toJson()).toList(),
        Adoption.candidates(7).map((c) => c.toJson()).toList(),
      );
    });
  });

  group('looking after them', () {
    test('rename, trimmed and capped; empty names are ignored', () {
      final inventory = _adoptMany(1);
      expect(
        inventory.renameMonkey(1, '  Banana Joe ').monkeys[1].name,
        'Banana Joe',
      );
      expect(
        inventory.renameMonkey(1, 'Supercalifragilistic').monkeys[1].name,
        hasLength(Adoption.maxNameLength),
      );
      expect(
        inventory.renameMonkey(1, '   ').monkeys[1].name,
        inventory.monkeys[1].name,
      );
    });

    test('dress one monkey without touching the others', () {
      final inventory = _adoptMany(2);
      const look = MonkeyLook(fur: 'fur.lava', hat: 'hat.top');
      final dressed = inventory.dressMonkey(2, look);
      expect(dressed.monkeys[2].look, look);
      expect(dressed.monkeys[0].look, inventory.monkeys[0].look);
      expect(dressed.monkeys[1].look, inventory.monkeys[1].look);
    });

    test('toggle the home gym, never for the player', () {
      final inventory = _adoptMany(2);
      expect(inventory.gymMates, hasLength(2));
      final resting = inventory.trainInGym(1, train: false);
      expect(resting.gymMates, [inventory.monkeys[2].look]);
      expect(resting.islandFriends, hasLength(2));
      expect(inventory.trainInGym(0, train: false), same(inventory));
    });

    test('playing as another keeps everyone', () {
      final inventory = _adoptMany(2);
      final swapped = inventory.playAs(2);
      expect(swapped.monkeys.first.name, inventory.monkeys[2].name);
      expect(
        swapped.monkeys.map((m) => m.name).toSet(),
        inventory.monkeys.map((m) => m.name).toSet(),
      );
      // Still two adoptions: the next price doesn't change.
      expect(swapped.nextAdoptionPrice, inventory.nextAdoptionPrice);
    });
  });

  group('saves', () {
    test('survive a JSON round trip', () {
      final inventory = _adoptMany(2).trainInGym(1, train: false);
      final again = GameInventory.fromJson(_roundTrip(inventory));
      expect(
        again.monkeys.map((m) => m.toJson()).toList(),
        inventory.monkeys.map((m) => m.toJson()).toList(),
      );
      expect(again.adoptedCount, 2);
      expect(again.gymMates, hasLength(1));
    });

    test('from before the adoption centre still load', () {
      final old = GameInventory.fromJson(const {
        'bananas': 50,
        'monkeys': [
          {'name': 'Carlos', 'xp': 3, 'accessory': 'none'},
          {
            'name': 'King Komo',
            'xp': 0,
            'look': {'fur': 'fur.jade', 'species': 'lizard'},
          },
        ],
      });
      expect(old.adoptedCount, 0);
      expect(old.monkeys[1].trainsInGym, isFalse);
      expect(old.monkeys[1].personality, -1);
      expect(old.nextAdoptionPrice, Adoption.prices.first);
      expect(old.komoToCome, isFalse);
    });
  });

  group('home gym', () {
    const a = MonkeyLook(fur: 'fur.mint');
    const b = MonkeyLook(fur: 'fur.lava');

    test('mates take the nearest stations, strangers fill the rest', () {
      expect(gymLineup(const [], buddies: 2), [null, null]);
      expect(gymLineup(const [a], buddies: 3), [a, null, null]);
      expect(gymLineup(const [a, b], buddies: 1), [a, b]);
    });

    test('never more than the stations', () {
      expect(gymLineup(const [a, b, a, b, a], buddies: 1), hasLength(4));
      expect(gymLineup(const [], buddies: 9), hasLength(4));
      expect(gymLineup(const [a, b], buddies: 4, stations: 2), [a, b]);
    });
  });

  group('island snapshot', () {
    test('carries the friends to visitors', () {
      final inventory = _adoptMany(3);
      final snapshot = IslandSnapshot.of(inventory);
      expect(snapshot.friends, hasLength(3));
      expect(IslandSnapshot.fromJson(_roundTrip(snapshot.toJson())), snapshot);
    });

    test('from before friends still loads', () {
      final snapshot = IslandSnapshot.fromJson(const {'bought': <String>[]});
      expect(snapshot.friends, isEmpty);
    });
  });
}
