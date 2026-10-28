import 'package:flutter/widgets.dart';

/// Light or dark mode: follow the phone, or pick one.
enum Appearance {
  system,
  light,
  dark;

  static Appearance byName(String? name) => Appearance.values.firstWhere(
        (appearance) => appearance.name == name,
        orElse: () => Appearance.system,
      );

  /// The brightness to draw in, given the phone's.
  Brightness resolve(Brightness platform) => switch (this) {
        Appearance.system => platform,
        Appearance.light => Brightness.light,
        Appearance.dark => Brightness.dark,
      };
}
