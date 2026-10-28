import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// The home screen icons. Classic is the app's own icon and free; the
/// others are alternate icon sets `AppIcon-<Name>.appiconset` in
/// ios/Runner/Assets.xcassets, listed in
/// ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES, and come with Pro.
enum AppIconChoice {
  classic(null),
  golden('AppIcon-Golden'),
  party('AppIcon-Party'),
  kingKomo('AppIcon-KingKomo'),
  midnight('AppIcon-Midnight'),
  bubblegum('AppIcon-Bubblegum'),
  snow('AppIcon-Snow'),
  lava('AppIcon-Lava'),
  bigBoss('AppIcon-BigBoss');

  const AppIconChoice(this.iosName);

  /// The alternate icon's name on iOS, null for the primary icon.
  final String? iosName;

  bool get needsPro => this != classic;

  /// The icon iOS reports by [name] (null or unknown is Classic).
  static AppIconChoice fromIosName(String? name) => values.firstWhere(
        (choice) => choice.iosName == name,
        orElse: () => classic,
      );

  AssetGenImage get preview => switch (this) {
        classic => Assets.images.appIcons.classic,
        golden => Assets.images.appIcons.golden,
        party => Assets.images.appIcons.party,
        kingKomo => Assets.images.appIcons.komo,
        midnight => Assets.images.appIcons.midnight,
        bubblegum => Assets.images.appIcons.bubblegum,
        snow => Assets.images.appIcons.snow,
        lava => Assets.images.appIcons.lava,
        bigBoss => Assets.images.appIcons.gold,
      };

  String label(S l) => switch (this) {
        classic => l.appIconClassic,
        golden => l.appIconGolden,
        party => l.appIconParty,
        kingKomo => l.appIconKingKomo,
        midnight => l.appIconMidnight,
        bubblegum => l.appIconBubblegum,
        snow => l.appIconSnow,
        lava => l.appIconLava,
        bigBoss => l.appIconBigBoss,
      };
}
