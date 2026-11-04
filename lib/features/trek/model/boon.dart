import 'package:pushup_bro/generated/l10n.dart';

/// A power-up picked between waves; it lasts for the rest of the stage.
enum Boon {
  /// Quick pushups also hit the next enemy for 40%.
  chain('⚡'),

  /// 25% more damage below half health.
  berserk('😤'),

  /// A blocked heavy attack heals 8%.
  ironPlank('🛡️'),

  /// 15% less damage taken.
  thickSkin('🦏'),

  /// Heals 30% right away; can be picked again.
  secondWind('💨'),

  /// Critical hits two and a half times as often.
  sharpEye('🎯'),

  /// Every quick pushup in a row hits 6% harder, up to 60%.
  comboKing('🔥'),

  /// Heals 5% of the damage dealt.
  vampire('🦇');

  const Boon(this.emoji);

  final String emoji;

  bool get repeatable => this == secondWind;

  String title(S l) => switch (this) {
        chain => l.boonChain,
        berserk => l.boonBerserk,
        ironPlank => l.boonIronPlank,
        thickSkin => l.boonThickSkin,
        secondWind => l.boonSecondWind,
        sharpEye => l.boonSharpEye,
        comboKing => l.boonComboKing,
        vampire => l.boonVampire,
      };

  String info(S l) => switch (this) {
        chain => l.boonChainInfo,
        berserk => l.boonBerserkInfo,
        ironPlank => l.boonIronPlankInfo,
        thickSkin => l.boonThickSkinInfo,
        secondWind => l.boonSecondWindInfo,
        sharpEye => l.boonSharpEyeInfo,
        comboKing => l.boonComboKingInfo,
        vampire => l.boonVampireInfo,
      };
}
