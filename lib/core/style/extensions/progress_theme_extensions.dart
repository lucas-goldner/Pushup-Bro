import 'package:flutter/material.dart';

class ProgressThemeExtension extends ThemeExtension<ProgressThemeExtension> {
  ProgressThemeExtension({
    required this.streakStarGradient,
  });

  factory ProgressThemeExtension.build() {
    return ProgressThemeExtension(
      streakStarGradient: const LinearGradient(
        begin: Alignment.center,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(204, 255, 191, 0),
          Color.fromARGB(204, 224, 62, 76),
        ],
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
