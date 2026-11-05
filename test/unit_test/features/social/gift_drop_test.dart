import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/domain/gift_drops.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 29, 9);

  GiftDrop drop({
    GiftKind gift = GiftKind.big,
    String from = 'mia',
    DateTime? at,
  }) =>
      GiftDrop.create(
        gift: gift,
        fromUid: from,
        fromName: 'Mia',
        now: at ?? now,
      );

  group('GiftDrop', () {
    test('has one id per sender and day', () {
      expect(drop().id, 'drop_mia_2026-10-29');
      expect(drop(at: DateTime(2026, 10, 29, 23)).id, drop().id);
      expect(drop(at: DateTime(2026, 10, 30, 1)).id, isNot(drop().id));
      expect(drop().day, '2026-10-29');
    });

    test('goes to JSON and back', () {
      final original = drop(gift: GiftKind.golden);
      final json = original.toJson();
      expect(json['gift'], 'golden');
      expect(json['bananas'], 50);
      expect(json['opened'], isFalse);
      expect(GiftDrop.fromJson(original.id, json), original);
      expect(
        GiftDrop.fromJson(original.id, original.open().toJson()).opened,
        isTrue,
      );
    });

    test('reads unknown or missing fields safely', () {
      final read = GiftDrop.fromJson(
        'drop_x_2026-10-29',
        const {'gift': 'car'},
      );
      expect(read.gift, GiftKind.flowers);
      expect(read.bananas, 5);
      expect(read.fromName, '');
      expect(read.opened, isFalse);
    });

    test('gifts pass on what they cost, at most 50', () {
      for (final gift in GiftKind.values) {
        expect(gift.cost, gift.bananas);
        expect(gift.bananas, lessThanOrEqualTo(kMaxDropBananas));
      }
    });
  });

  group('limits', () {
    test('one drop per friend a day, paid from your bananas', () {
      expect(
        checkDrop(gift: GiftKind.big, bananas: 30, droppedToday: false),
        DropCheck.ok,
      );
      expect(
        checkDrop(gift: GiftKind.golden, bananas: 30, droppedToday: false),
        DropCheck.notEnoughBananas,
      );
      expect(
        checkDrop(gift: GiftKind.flowers, bananas: 30, droppedToday: true),
        DropCheck.alreadyDropped,
      );
    });

    test('a valid drop comes from its sender, under their id, near now', () {
      expect(isValidDrop(drop(), sender: 'mia', now: now), isTrue);
      expect(isValidDrop(drop(), sender: 'leo', now: now), isFalse);
      expect(isValidDrop(drop().open(), sender: 'mia', now: now), isFalse);
      expect(
        isValidDrop(
          drop(at: now.add(const Duration(days: 3))),
          sender: 'mia',
          now: now,
        ),
        isFalse,
      );
      final forged = GiftDrop(
        id: 'drop_mia_tomorrow',
        gift: GiftKind.small,
        fromUid: 'mia',
        fromName: 'Mia',
        sentAt: now,
      );
      expect(isValidDrop(forged, sender: 'mia', now: now), isFalse);
    });

    test('waiting drops are the unopened ones, oldest first', () {
      final early =
          drop(from: 'leo', at: now.subtract(const Duration(hours: 3)));
      final late = drop();
      final opened = drop(from: 'sam').open();
      expect(waitingDrops([late, opened, early]), [early, late]);
    });

    test('opened drops are cleared once their day is surely over', () {
      final fresh = drop().open();
      final old =
          drop(from: 'leo', at: now.subtract(const Duration(days: 3))).open();
      final unopened =
          drop(from: 'sam', at: now.subtract(const Duration(days: 3)));
      expect(staleDrops([fresh, old, unopened], now: now), [old]);
    });

    test('the phone remembers who got a gift today', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = SharedPreferencesProvider();
      expect(await droppedToday(prefs, now: now), isEmpty);
      await rememberDrop(prefs, friend: 'mia', now: now);
      await rememberDrop(prefs, friend: 'leo', now: now);
      expect(await droppedToday(prefs, now: now), {'mia', 'leo'});
      expect(
        await droppedToday(prefs, now: now.add(const Duration(days: 1))),
        isEmpty,
      );
    });
  });

  group('fake backend', () {
    late FakeSocialBackend backend;

    setUp(() async {
      backend = FakeSocialBackend(startUid: 'mia')
        ..clock = (() => now)
        ..friendEdges['me'] = {'mia'}
        ..friendEdges['mia'] = {'me'};
      await backend.ensureSignedIn();
    });

    test('takes one drop a day from a friend', () async {
      expect(await backend.dropGift('me', drop()), isTrue);
      expect(await backend.dropGift('me', drop(gift: GiftKind.small)), isFalse);
      expect(await backend.drops('me').first, [drop()]);
    });

    test('refuses strangers, blocked friends and forged drops', () async {
      expect(await backend.dropGift('leo', drop()), isFalse);
      expect(await backend.dropGift('me', drop(from: 'sam')), isFalse);
      backend.blocks['me'] = {'mia'};
      expect(await backend.dropGift('me', drop()), isFalse);
    });

    test('an opened drop stays, so the friend still cannot drop again',
        () async {
      await backend.dropGift('me', drop());
      await backend.openDrop('me', drop().id);
      final drops = await backend.drops('me').first;
      expect(drops.single.opened, isTrue);
      expect(waitingDrops(drops), isEmpty);
      expect(await backend.dropGift('me', drop()), isFalse);
      await backend.removeDrop('me', drop().id);
      expect(await backend.drops('me').first, isEmpty);
    });
  });
}
