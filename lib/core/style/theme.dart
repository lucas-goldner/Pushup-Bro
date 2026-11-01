import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/extensions/game_colors_theme_extension.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/generated/fonts.gen.dart';

/// Navy brand on misty blue-white: buttons are navy, cards white.
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: PBPalette.navy800,
  onPrimary: PBPalette.white,
  primaryContainer: PBPalette.mist200,
  onPrimaryContainer: PBPalette.navy800,
  secondary: PBPalette.blue,
  onSecondary: PBPalette.white,
  secondaryContainer: Color(0xFFDDE9FF),
  onSecondaryContainer: Color(0xFF1C4A8F),
  tertiary: PBPalette.jungle,
  onTertiary: PBPalette.white,
  error: PBPalette.red,
  onError: PBPalette.white,
  surface: PBPalette.white,
  onSurface: PBPalette.navy800,
  onSurfaceVariant: PBPalette.slate500,
  surfaceDim: PBPalette.mist200,
  surfaceBright: PBPalette.white,
  surfaceContainerLowest: PBPalette.white,
  surfaceContainerLow: PBPalette.mist50,
  surfaceContainer: PBPalette.mist100,
  surfaceContainerHigh: PBPalette.mist200,
  surfaceContainerHighest: PBPalette.mist300,
  outline: PBPalette.mist300,
  outlineVariant: PBPalette.mist200,
  shadow: PBPalette.navy800,
  scrim: PBPalette.navy800,
  inverseSurface: PBPalette.navy800,
  onInverseSurface: PBPalette.white,
  inversePrimary: PBPalette.blue,
);

/// The same app at night: deep navy grounds, raised navy cards, and a
/// light primary so the main buttons still stand out.
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: PBPalette.mist50,
  onPrimary: PBPalette.navy800,
  primaryContainer: PBPalette.navy650,
  onPrimaryContainer: PBPalette.mist50,
  secondary: PBPalette.blueLight,
  onSecondary: PBPalette.navy900,
  secondaryContainer: Color(0xFF233A63),
  onSecondaryContainer: Color(0xFFCFE0FF),
  tertiary: PBPalette.jungleLight,
  onTertiary: PBPalette.navy900,
  error: PBPalette.redLight,
  onError: PBPalette.white,
  surface: PBPalette.navy750,
  onSurface: PBPalette.mist50,
  onSurfaceVariant: PBPalette.slate300,
  surfaceDim: PBPalette.navy950,
  surfaceBright: PBPalette.navy650,
  surfaceContainerLowest: PBPalette.navy950,
  surfaceContainerLow: PBPalette.navy900,
  surfaceContainer: PBPalette.navy700,
  surfaceContainerHigh: PBPalette.navy650,
  surfaceContainerHighest: PBPalette.navy600,
  outline: PBPalette.navy600,
  outlineVariant: PBPalette.navy650,
  shadow: PBPalette.black,
  scrim: PBPalette.black,
  inverseSurface: PBPalette.mist50,
  onInverseSurface: PBPalette.navy800,
  inversePrimary: PBPalette.blue,
);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? darkColorScheme : lightColorScheme;
  final text = pbTextTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLow,
    canvasColor: scheme.surfaceContainerLow,
    splashFactory: NoSplash.splashFactory,
    fontFamily: FontFamily.satoshi,
    textTheme: text.copyWith(
      bodySmall: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    ),
    iconTheme: IconThemeData(color: scheme.onSurface),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 0,
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(scheme.surface),
      elevation: const WidgetStatePropertyAll(0),
      hintStyle: WidgetStatePropertyAll(
        text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      textStyle: WidgetStatePropertyAll(text.bodyMedium),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.secondary,
      thumbColor: scheme.surface,
      inactiveTrackColor: scheme.surfaceContainerHigh,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.tertiary
            : scheme.surfaceContainerHigh,
      ),
      thumbColor: const WidgetStatePropertyAll(PBPalette.white),
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: scheme.secondary,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      barBackgroundColor: scheme.surface,
    ),
    extensions: [
      if (dark)
        GameColorsThemeExtension.dark()
      else
        GameColorsThemeExtension.light(),
    ],
  );
}

final ThemeData lightTheme = buildTheme(Brightness.light);
final ThemeData darkTheme = buildTheme(Brightness.dark);
