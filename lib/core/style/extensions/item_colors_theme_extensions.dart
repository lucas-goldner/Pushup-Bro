import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';

class ItemColorsThemeExtensions
    extends ThemeExtension<ItemColorsThemeExtensions> {
  const ItemColorsThemeExtensions({
    required this.doubleBoost,
    required this.friendBoost,
  });

  factory ItemColorsThemeExtensions.light() => const ItemColorsThemeExtensions(
        doubleBoost: PBPalette.white,
        friendBoost: PBPalette.cream,
      );

  factory ItemColorsThemeExtensions.dark() => const ItemColorsThemeExtensions(
        doubleBoost: PBPalette.navy700,
        friendBoost: PBPalette.creamDark,
      );

  final Color doubleBoost;
  final Color friendBoost;

  @override
  ThemeExtension<ItemColorsThemeExtensions> copyWith() =>
      ItemColorsThemeExtensions(
        doubleBoost: doubleBoost,
        friendBoost: friendBoost,
      );

  @override
  ThemeExtension<ItemColorsThemeExtensions> lerp(
    covariant ThemeExtension<ItemColorsThemeExtensions>? other,
    double t,
  ) {
    if (other is! ItemColorsThemeExtensions) {
      return this;
    }

    return ItemColorsThemeExtensions(
      doubleBoost: Color.lerp(doubleBoost, other.doubleBoost, t) ?? doubleBoost,
      friendBoost: Color.lerp(friendBoost, other.friendBoost, t) ?? friendBoost,
    );
  }
}
