import 'package:pushup_bro/core/platform/key_value_store_mmkv.dart'
    if (dart.library.js_interop) 'package:pushup_bro/core/platform/key_value_store_web.dart';

/// String key-value storage backing `DBProvider`.
///
/// MMKV on device; an in-memory mock on the web, where MMKV's FFI bindings
/// are unavailable.
abstract class KeyValueStore {
  factory KeyValueStore() => createKeyValueStore();

  Future<void> initialize();
  String? decodeString(String key);
  void encodeString(String key, String value);
}
