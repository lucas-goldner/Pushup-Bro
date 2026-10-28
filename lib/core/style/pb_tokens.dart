import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

/// Corner radii: few and consistent, like the 3D era cards.
abstract final class PBRadius {
  /// Chips, tags, small tiles.
  static const double sm = 12;

  /// Rows, list cards, inputs.
  static const double md = 18;

  /// Cards and panels.
  static const double lg = 26;

  /// Bottom sheets (top corners).
  static const double sheet = 36;

  /// Fully rounded pills and buttons.
  static const double pill = 999;
}

/// Spacing steps.
abstract final class PBSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

extension PBShadows on BuildContext {
  /// The soft lift under white cards floating over the scene.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: colorScheme.shadow.withValues(
            alpha: colorScheme.brightness == Brightness.dark ? 0.4 : 0.1,
          ),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// A coloured glow under a solid button or badge.
  List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// A tinted fill for chips and badges in [color] (stronger in dark mode).
  Color tint(Color color) => color.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.22 : 0.14,
      );
}
