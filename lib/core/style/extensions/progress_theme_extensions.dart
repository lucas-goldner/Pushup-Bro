import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';

class ProgressThemeExtension extends ThemeExtension<ProgressThemeExtension> {
  ProgressThemeExtension({
    required this.streakStarGradient,
  });

  factory ProgressThemeExtension.build() {
    return ProgressThemeExtension(
      streakStarGradient: const LinearGradient(
        begin: Alignment.center,
        end: Alignment.bottomCenter,
        colors: [PBPalette.banana, PBPalette.coral],
      ),
    );
  }

  final Gradient streakStarGradient;

  @override
  ThemeExtension<ProgressThemeExtension> copyWith({
    Gradient? streakStarGradient,
  }) =>
      ProgressThemeExtension(
        streakStarGradient: streakStarGradient ?? this.streakStarGradient,
      );

  @override
  ThemeExtension<ProgressThemeExtension> lerp(
    covariant ThemeExtension<ProgressThemeExtension>? other,
    double t,
  ) {
    if (other is! ProgressThemeExtension) {
      return this;
    }
    return ProgressThemeExtension(
      streakStarGradient: Gradient.lerp(
            streakStarGradient,
            other.streakStarGradient,
            t,
          ) ??
          streakStarGradient,
    );
  }
}
