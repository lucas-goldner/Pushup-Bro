import 'package:flutter/material.dart';

class GameColorsThemeExtension
    extends ThemeExtension<GameColorsThemeExtension> {
  const GameColorsThemeExtension({
    required this.sand,
    required this.grass,
    required this.map,
  });

  factory GameColorsThemeExtension.build() => const GameColorsThemeExtension(
        sand: Color(0xFFe1cfae),
        grass: Color(0xFFabc090),
        map: Color(0xFFc0ab86),
      );

  final Color sand;
  final Color grass;
  final Color map;

  @override
  ThemeExtension<GameColorsThemeExtension> copyWith({
    Color? sand,
    Color? grass,
    Color? map,
  }) =>
      GameColorsThemeExtension(
        sand: sand ?? this.sand,
        grass: grass ?? this.grass,
        map: map ?? this.map,
      );

  @override
  ThemeExtension<GameColorsThemeExtension> lerp(
    covariant ThemeExtension<GameColorsThemeExtension>? other,
    double t,
  ) {
    if (other is! GameColorsThemeExtension) {
      return this;
    }

    return GameColorsThemeExtension(
      sand: Color.lerp(sand, other.sand, t) ?? sand,
      grass: Color.lerp(grass, other.grass, t) ?? grass,
      map: Color.lerp(map, other.map, t) ?? map,
    );
  }
}
