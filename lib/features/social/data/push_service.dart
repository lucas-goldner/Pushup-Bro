import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push notifications for waves, bananas and nudges from bros. A Cloud
/// Function (`firebase/functions`) sends them to the tokens registered here.
abstract class PushService {
  /// Asks for permission (iOS only asks once) and returns this iPhone's
  /// token, or null when notifications are off or unavailable.
  Future<String?> enable();

  /// A new token for this iPhone (FCM rotates them now and then).
  Stream<String> get tokenRefresh;

  /// Where tapped notifications lead, the one that opened the app included.
  Stream<String> get opened;
}

/// No push (web, tests, no Firebase).
class NoPushService implements PushService {
  @override
  Future<String?> enable() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<String> get opened => const Stream.empty();
}

/// Firebase Cloud Messaging through APNs.
class FirebasePushService implements PushService {
  FirebasePushService() {
    unawaited(_listenForTaps());
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<String> _opened = StreamController.broadcast();
  String? _initialRoute;

  Future<void> _listenForTaps() async {
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _initialRoute = _routeOf(initial);
  }

  void _open(RemoteMessage message) {
    final route = _routeOf(message);
    if (route != null) _opened.add(route);
  }

  static String? _routeOf(RemoteMessage message) {
    final route = message.data['route'];
    return route is String && route.startsWith('/') ? route : null;
  }

  @override
  Future<String?> enable() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return null;
      }
      // FCM needs the APNs token first; it can take a moment to arrive.
      for (var tries = 0; tries < 10; tries++) {
        if (await _messaging.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      // The registration token, which the Admin SDK sends to. (The newer
      // register() gives an installation id that it can't target yet.)
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object catch (error) {
      debugPrint('Push unavailable: $error');
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use, the token getToken() returns.
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<String> get opened async* {
    final initial = _initialRoute;
    _initialRoute = null;
    if (initial != null) yield initial;
    yield* _opened.stream;
  }
}
