import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Scans a QR code with the iPhone camera (`QrScanner` in
/// `ios/Runner/AppDelegate.swift`, AVFoundation's metadata output; no ML
/// Kit). Returns what the code says, or null when cancelled or there's no
/// camera.
abstract final class QrScanner {
  static const _channel = MethodChannel('pushup_bro/qr_scanner');

  static bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<String?> scan({
    required String title,
    required String cancel,
  }) async {
    if (!available) return null;
    try {
      return await _channel.invokeMethod<String>('scan', {
        'title': title,
        'cancel': cancel,
      });
    } on PlatformException catch (error) {
      debugPrint('QR scan failed: $error');
      return null;
    }
  }
}
