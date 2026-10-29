import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Turns the screen up while a QR code is shown, so it scans from further
/// away (`ScreenBrightness` in ios/Runner/AppDelegate.swift).
abstract final class ScreenBrightness {
  static const _channel = MethodChannel('pushup_bro/brightness');

  static bool get _available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Sets full brightness; returns the previous level to restore.
  static Future<double?> raise() async {
    if (!_available) return null;
    try {
      return await _channel.invokeMethod<double>('raise');
    } on PlatformException {
      return null;
    }
  }

  static Future<void> restore(double? level) async {
    if (!_available || level == null) return;
    try {
      await _channel.invokeMethod<void>('restore', level);
    } on PlatformException {
      // Nothing to put back.
    }
  }
}
