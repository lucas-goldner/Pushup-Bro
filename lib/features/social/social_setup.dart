import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pushup_bro/core/app_config.dart';
import 'package:pushup_bro/features/social/data/demo_social_backend.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/data/firestore_social_backend.dart';
import 'package:pushup_bro/features/social/data/push_service.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';

/// Firebase on iOS, from the flavor's `GoogleService-Info.plist`. Without
/// it (web, tests, a build missing the plist) the social features say
/// they're unavailable instead of crashing.
Future<SocialBackend> createSocialBackend({required bool dev}) async {
  if (AppConfig.socialDemo) return demoSocialBackend();
  if (kIsWeb) return UnavailableSocialBackend();
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      providerApple: dev
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    return FirestoreSocialBackend();
  } on Object catch (error) {
    debugPrint('Firebase unavailable: $error');
    return UnavailableSocialBackend();
  }
}

/// Push notifications where Firebase is set up.
PushService pushServiceFor(SocialBackend backend) =>
    backend is FirestoreSocialBackend ? FirebasePushService() : NoPushService();

/// No Firebase: signing in fails, so the account stays offline.
class UnavailableSocialBackend extends FakeSocialBackend {
  @override
  Future<String> ensureSignedIn() =>
      Future.error(StateError('Firebase is not configured'));
}
