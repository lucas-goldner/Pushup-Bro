import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/platform/key_value_store.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';

class _FakeKeyValueStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<void> initialize() async {}

  @override
  String? decodeString(String key) => values[key];

  @override
  void encodeString(String key, String value) => values[key] = value;
}

void main() {
  late DBProvider dbProvider;

  setUp(() => dbProvider = DBProvider()..store = _FakeKeyValueStore());

  test('createInventory keeps bananas earned before the first visit', () async {
    await dbProvider.updateInventory(
      GameInventory.empty().copyWith(bananas: 42),
    );

    final inventory = await dbProvider.createInventory();

    expect(inventory.bananas, 42);
    expect((await dbProvider.getInventory()).bananas, 42);
  });

  test('createInventory seeds an empty inventory when none is stored',
      () async {
    final inventory = await dbProvider.createInventory();

    expect(inventory.bananas, 0);
    expect((await dbProvider.getInventory()).monkeys.single.name, 'Carlos');
  });

  test('pushup sets can be added and deleted by id', () async {
    final first = PushupSet([Pushup(completedAt: DateTime(2026))], 1, id: 1);
    final second = PushupSet([Pushup(completedAt: DateTime(2026))], 2, id: 2);
    await dbProvider.addNewPushupSet(first);
    await dbProvider.addNewPushupSet(second);

    await dbProvider.deletePushupSet(1);

    final remaining = await dbProvider.getAllPushupSets();
    expect(remaining.map((set) => set.id), [2]);
  });
}
