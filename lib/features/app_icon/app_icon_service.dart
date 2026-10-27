import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pushup_bro/features/app_icon/app_icon_choice.dart';

/// Switches the home screen icon through the `pushup_bro/app_icon` channel
/// (`AppIconSwitcher` in ios/Runner/AppDelegate.swift). Off iOS there is
/// nothing to switch: it reports Classic and ignores changes.
class AppIconService {
  AppIconService({MethodChannel? channel, bool? enabled})
      : _channel = channel ?? const MethodChannel('pushup_bro/app_icon'),
        enabled = enabled ?? isPlatformSupported;

  /// Whether this platform has alternate icons at all (iOS only).
  static bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  final MethodChannel _channel;
  final bool enabled;

  /// Whether the device can change the icon.
  Future<bool> isSupported() async {
    if (!enabled) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The icon on the home screen now.
  Future<AppIconChoice> current() async {
    if (!enabled) return AppIconChoice.classic;
    try {
      return AppIconChoice.fromIosName(
        await _channel.invokeMethod<String>('current'),
      );
    } on MissingPluginException {
      return AppIconChoice.classic;
    }
  }

  /// Puts [choice] on the home screen. Throws a [PlatformException] when
  /// iOS refuses.
  Future<void> set(AppIconChoice choice) async {
    if (!enabled) return;
    await _channel.invokeMethod<void>('set', choice.iosName);
  }
}
