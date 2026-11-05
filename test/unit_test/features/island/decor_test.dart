import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_editor.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_inventory.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_placement.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/island_snapshot.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart';
import 'package:pushup_bro/generated/l10n.dart';

Map<String, dynamic> _roundTrip(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

GameInventory _inventory({
  int bananas = 1000,
  List<DecorPiece> decor = const [],
  List<ShopBuyables> bought = const [ShopBuyables.accessories],
}) =>
    GameInventory(
      bananas: bananas,
      boughtItems: bought,
      monkeys: [AdoptableMonkey.carlos()],
      decor: decor,
    );

void main() {
  group('catalog', () {
    test('has a dozen or more decorations, cheap to showpiece', () {
      expect(DecorItem.values.length, inInclusiveRange(12, 16));
      final prices = [for (final item in DecorItem.values) item.price];
      expect(prices.first, inInclusiveRange(20, 60));
      expect(prices.last, inInclusiveRange(300, 500));
      // Listed from cheapest to dearest.
      expect(prices, [...prices]..sort());
    });

    test('ids are unique and read back', () {
      final ids = {for (final item in DecorItem.values) item.id};
      expect(ids.length, DecorItem.values.length);
      for (final item in DecorItem.values) {
        expect(DecorItem.byId(item.id), item);
      }
      expect(DecorItem.byId('rocketShip'), isNull);
    });

    test('only lights glow', () {
      expect(
        [
          for (final item in DecorItem.values)
            if (item.glow != null) item,
        ],
        [DecorItem.lanternPost, DecorItem.bonfire],
      );
    });

    test('every decoration has a name in every language', () async {
      for (final locale in S.delegate.supportedLocales) {
        final l = await S.load(locale);
        for (final item in DecorItem.values) {
          expect(item.label(l), isNotEmpty);
        }
      }
    });
  });

  group('placement', () {
    final plan = IslandPlan(1);
    final placement = DecorPlacement(plan);

    test('keeps decorations on the grass', () {
      expect(placement.onLand(DecorItem.flamingo, 0, plan.radius * 0.8), true);
      expect(placement.onLand(DecorItem.flamingo, 0, plan.radius), false);
      expect(placement.onLand(DecorItem.flamingo, plan.radius + 2, 0), false);
    });

    test('keeps clear of buildings, the jungle and Carlos', () {
      for (final spot in plan.buildingSpots) {
        expect(placement.onLand(DecorItem.rubberDucky, spot.x, spot.y), false);
      }
      expect(
        placement.onLand(DecorItem.rubberDucky, plan.jungle.x, plan.jungle.y),
        false,
      );
      expect(
        placement.onLand(
          DecorItem.rubberDucky,
          plan.jungleGate.x,
          plan.jungleGate.y,
        ),
        false,
      );
      expect(
        placement.onLand(
          DecorItem.rubberDucky,
          plan.carlosLap.x,
          plan.carlosLap.y,
        ),
        false,
      );
    });

    test('stops decorations overlapping', () {
      final duck = DecorPiece(
        item: DecorItem.rubberDucky,
        z: plan.radius * 0.7,
        placed: true,
      );
      final pieces = [duck];
      expect(placement.fits(duck.copyWith(x: 0.2), pieces), false);
      expect(placement.fits(duck.copyWith(x: 0.2), pieces, ignore: 0), true);
      expect(placement.fits(duck.copyWith(x: 0.6), pieces), true);
      // Put away, it's out of the way.
      expect(
        placement.fits(duck.copyWith(x: 0.2), [duck.copyWith(placed: false)]),
        true,
      );
    });

    test('finds free spots until the island is full', () {
      final pieces = <DecorPiece>[];
      for (var i = 0; i < 60; i++) {
        final spot = placement.freeSpot(DecorItem.tikiBar, pieces);
        if (spot == null) break;
        final piece = DecorPiece(
          item: DecorItem.tikiBar,
          x: spot.x,
          z: spot.y,
          placed: true,
        );
        expect(placement.fits(piece, pieces), true);
        pieces.add(piece);
      }
      expect(pieces.length, greaterThan(3));
      expect(placement.freeSpot(DecorItem.tikiBar, pieces), isNull);
    });

    test('a bigger island has room in new places', () {
      final small = DecorPlacement(IslandPlan(1));
      final big = DecorPlacement(IslandPlan(4));
      expect(big.plan.radius, greaterThan(small.plan.radius));
      final edge = small.plan.radius + 0.6;
      expect(small.onLand(DecorItem.rubberDucky, edge, -1), false);
      expect(big.onLand(DecorItem.rubberDucky, edge, -1), true);
    });

    test('settles pieces a new building stands on', () {
      final spot = IslandPlan(2).buildingSpots[2];
      final pieces = [
        DecorPiece(
          item: DecorItem.flamingo,
          x: spot.x,
          z: spot.y,
          placed: true,
        ),
        const DecorPiece(item: DecorItem.bonfire),
      ];
      final settled = DecorPlacement(IslandPlan(2)).settle(pieces);
      expect(settled.length, 2);
      expect(settled[0].placed, true);
      expect(
        DecorPlacement(IslandPlan(2)).fits(settled[0], settled, ignore: 0),
        true,
      );
      expect(settled[1], pieces[1]);
    });

    test('the plan counts each building once', () {
      expect(
        IslandPlan.of(const [
          ShopBuyables.accessories,
          ShopBuyables.accessories,
          ShopBuyables.accessoryPartyHat,
          ShopBuyables.gym,
        ]).buildings,
        2,
      );
    });
  });

  group('saving', () {
    const piece = DecorPiece(
      item: DecorItem.hammock,
      x: 1.234,
      z: -0.5,
      turn: 3,
      placed: true,
    );

    test('a piece survives a JSON round trip', () {
      final back = DecorPiece.fromJson(_roundTrip(piece.toJson()));
      expect(back, piece.copyWith(x: 1.23));
    });

    test('unknown or broken pieces are skipped', () {
      expect(
        DecorPiece.listFromJson([
          {'id': 'spaceship', 'x': 1},
          'nonsense',
          piece.toJson(),
          {'id': 'flamingo'},
        ]),
        [
          piece.copyWith(x: 1.23),
          const DecorPiece(item: DecorItem.flamingo),
        ],
      );
      expect(DecorPiece.listFromJson(null), isEmpty);
    });

    test('the inventory keeps its decorations', () {
      final inventory = _inventory(decor: [piece.copyWith(x: 1)]);
      final loaded = GameInventory.fromJson(_roundTrip(inventory));
      expect(loaded.decor, inventory.decor);
      expect(loaded.bananas, inventory.bananas);
    });

    test('an old save without decorations still loads', () {
      final old = _roundTrip(_inventory())..remove('decor');
      final loaded = GameInventory.fromJson(old);
      expect(loaded.decor, isEmpty);
      expect(loaded.bananas, 1000);
    });

    test('snapshots carry the placed pieces only', () {
      final inventory = _inventory(
        decor: [
          piece.copyWith(x: 1),
          const DecorPiece(item: DecorItem.flamingo),
        ],
      );
      final snapshot = IslandSnapshot.of(inventory);
      expect(snapshot.decor, [piece.copyWith(x: 1)]);
      expect(IslandSnapshot.fromJson(_roundTrip(snapshot.toJson())), snapshot);
    });

    test('an old snapshot without decorations still loads', () {
      final old = _roundTrip(const IslandSnapshot(bought: [ShopBuyables.gym]))
        ..remove('decor');
      expect(IslandSnapshot.fromJson(old).decor, isEmpty);
      expect(IslandSnapshot.fromJson(old).bought, [ShopBuyables.gym]);
    });
  });

  group('inventory', () {
    test('buying pays and stands it on a free spot', () {
      final bought = _inventory(bananas: 100).buyDecor(DecorItem.flamingo)!;
      expect(bought.bananas, 100 - DecorItem.flamingo.price);
      expect(bought.ownedDecor(DecorItem.flamingo), 1);
      final piece = bought.decor.single;
      expect(piece.placed, true);
      expect(bought.decorPlacement.fits(piece, bought.decor, ignore: 0), true);
    });

    test('several of the same can be owned', () {
      var inventory = _inventory();
      for (var i = 0; i < 3; i++) {
        inventory = inventory.buyDecor(DecorItem.rubberDucky)!;
      }
      expect(inventory.ownedDecor(DecorItem.rubberDucky), 3);
      expect(inventory.decor.every((piece) => piece.placed), true);
      expect(inventory.bananas, 1000 - 3 * DecorItem.rubberDucky.price);
    });

    test("can't buy without the bananas", () {
      expect(_inventory(bananas: 10).buyDecor(DecorItem.flamingo), isNull);
    });

    test('moves, turns, puts away and places again', () {
      var inventory = _inventory().buyDecor(DecorItem.flamingo)!;
      final radius = inventory.decorPlacement.plan.radius;
      inventory = inventory.moveDecor(0, 0.4, radius * 0.75);
      expect(inventory.decor[0].x, 0.4);
      // Onto the jungle: refused.
      final jungle = inventory.decorPlacement.plan.jungle;
      expect(inventory.moveDecor(0, jungle.x, jungle.y), inventory);
      inventory = inventory.turnDecor(0, -1);
      expect(inventory.decor[0].turn, 7);
      inventory = inventory.putAwayDecor(0);
      expect(inventory.decor[0].placed, false);
      expect(IslandSnapshot.of(inventory).decor, isEmpty);
      inventory = inventory.placeDecor(0);
      expect(inventory.decor[0].placed, true);
    });

    test('a full island puts new ones in the bag', () {
      var inventory = _inventory(bananas: 100000);
      for (var i = 0; i < kMaxPlacedDecor + 2; i++) {
        inventory = inventory.buyDecor(DecorItem.rubberDucky)!;
      }
      expect(
        inventory.decor.where((piece) => piece.placed).length,
        kMaxPlacedDecor,
      );
      expect(inventory.decor.last.placed, false);
    });
  });

  group('editor', () {
    test('drags freely and jumps back from a blocked spot', () {
      final inventory = _inventory().buyDecor(DecorItem.flamingo)!;
      final placement = inventory.decorPlacement;
      final editor = DecorEditor()
        ..start(inventory.decor, placement, select: 0);
      final start = editor.pieces[0];
      final jungle = placement.plan.jungle;
      editor.dragTo(jungle.x, jungle.y);
      expect(editor.blocked, true);
      editor.endDrag();
      expect(editor.blocked, false);
      expect(editor.pieces[0].x, start.x);
      expect(editor.pieces[0].z, start.z);

      editor
        ..dragTo(start.x + 0.3, start.z)
        ..endDrag();
      expect(editor.pieces[0].x, closeTo(start.x + 0.3, 1e-5));
    });

    test('never drags out to sea', () {
      final inventory = _inventory().buyDecor(DecorItem.flamingo)!;
      final editor = DecorEditor()
        ..start(inventory.decor, inventory.decorPlacement, select: 0)
        ..dragTo(0, 100);
      expect(editor.pieces[0].z, lessThan(10));
    });

    test('turns, puts away and places from the bag', () {
      final inventory = _inventory().buyDecor(DecorItem.flamingo)!;
      final editor = DecorEditor()
        ..start(inventory.decor, inventory.decorPlacement, select: 0)
        ..turn(1);
      expect(editor.pieces[0].turn, 1);
      editor.putAway();
      expect(editor.selected, isNull);
      expect(editor.bag, [0]);
      expect(editor.place(0), true);
      expect(editor.selected, 0);
      expect(editor.bag, isEmpty);
      editor.stop();
      expect(editor.active, false);
    });
  });
}
