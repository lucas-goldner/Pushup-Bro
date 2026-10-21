import 'dart:convert';

import 'package:pushup_bro/core/platform/key_value_store.dart';

KeyValueStore createKeyValueStore() => _InMemoryKeyValueStore();

/// Mock storage for the web build. Nothing survives a page reload; it starts
/// from a week of demo workouts and enough bananas to try the island shop.
class _InMemoryKeyValueStore implements KeyValueStore {
  final _values = <String, String>{};

  @override
  Future<void> initialize() async {
    if (_values.isNotEmpty) return;
    _values
      ..['pushup_sets'] = jsonEncode(_demoPushupSets())
      ..['game_inventory'] = jsonEncode({
        'bananas': 600,
        'boughtItems': <String>[],
        'monkeys': [
          {'name': 'Carlos', 'xp': 0, 'accessory': 'none'},
        ],
      });
  }

  @override
  String? decodeString(String key) => _values[key];

  @override
  void encodeString(String key, String value) => _values[key] = value;
}

List<Map<String, dynamic>> _demoPushupSets() {
  final today = DateTime.now();
  const repsPerDay = [12, 0, 20, 15, 0, 25, 18];

  return [
    for (var daysAgo = 1; daysAgo <= repsPerDay.length; daysAgo++)
      if (repsPerDay[daysAgo - 1] > 0)
        {
          'id': daysAgo,
          'effort': 3,
          'pushups': [
            for (var rep = 0; rep < repsPerDay[daysAgo - 1]; rep++)
              {
                'completedAt': DateTime(
                  today.year,
                  today.month,
                  today.day - daysAgo,
                  18,
                  0,
                  rep * 3,
                ).toIso8601String(),
              },
          ],
        },
  ];
}
