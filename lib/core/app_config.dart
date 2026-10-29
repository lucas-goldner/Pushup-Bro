// Store keys come in at build time through --dart-define.
// ignore_for_file: do_not_use_environment
/// Store settings, passed at build time:
/// `--dart-define=REVENUECAT_APPLE_API_KEY=...`. Without a key the store is
/// unavailable and nobody is locked out.
abstract final class AppConfig {
  static const revenueCatAppleApiKey =
      String.fromEnvironment('REVENUECAT_APPLE_API_KEY');
  static const revenueCatGoogleApiKey =
      String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');

  /// Fills the social screens with sample bros instead of Firebase, for
  /// previews and screenshots: `--dart-define=SOCIAL_DEMO=true`.
  static const socialDemo = bool.fromEnvironment('SOCIAL_DEMO');

  /// The RevenueCat offering with the weekly, yearly and lifetime plans,
  /// and the entitlement they unlock.
  static const proOffering = 'pro';
  static const proEntitlement = 'pro';

  /// How long everything is open after the first launch.
  static const freeDays = Duration(days: 3);

  /// The App Group the iOS widgets read their data from.
  static const appGroup = 'group.com.lucas-goldner.pushup-bro';
}
