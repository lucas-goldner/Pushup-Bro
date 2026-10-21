import 'package:mmkv/mmkv.dart';
import 'package:pushup_bro/core/platform/key_value_store.dart';

KeyValueStore createKeyValueStore() => _MMKVKeyValueStore();

class _MMKVKeyValueStore implements KeyValueStore {
  MMKV? _mmkv;

  @override
  Future<void> initialize() async {
    await MMKV.initialize();
    _mmkv = MMKV.defaultMMKV();
  }

  @override
  String? decodeString(String key) => _mmkv?.decodeString(key);

  @override
  void encodeString(String key, String value) =>
      _mmkv?.encodeString(key, value);
}
