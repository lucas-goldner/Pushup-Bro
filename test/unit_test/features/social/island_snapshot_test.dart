import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/island/model/island_snapshot.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

void main() {
  test('survives a JSON round trip', () {
    const snapshot = IslandSnapshot(
      bought: [ShopBuyables.gym, ShopBuyables.airport],
      look: MonkeyLook(fur: 'fur.golden', hat: 'hat.crown'),
    );
    expect(IslandSnapshot.fromJson(snapshot.toJson()), snapshot);
  });

  test('skips buildings it no longer knows', () {
    final snapshot = IslandSnapshot.fromJson(const {
      'bought': ['gym', 'spaceport'],
    });
    expect(snapshot.bought, [ShopBuyables.gym]);
  });

  test('is an empty island without data', () {
    expect(IslandSnapshot.fromJson(null), const IslandSnapshot());
  });
}
