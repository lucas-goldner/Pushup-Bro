import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks iOS to show its rating prompt through the `pushup_bro/review`
/// channel (`StoreReview` in ios/Runner/AppDelegate.swift). iOS decides
/// whether it really appears, at most a few times a year. Elsewhere it
/// does nothing.
class StoreReview {
  const StoreReview({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('pushup_bro/review');

  final MethodChannel _channel;

  Future<void> request() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<void>('request');
    } on MissingPluginException {
      // Not on a device with the native side.
    } on PlatformException catch (error) {
      debugPrint('Rating prompt failed: $error');
    }
  }
}
