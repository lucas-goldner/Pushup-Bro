import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/extensions/game_colors_theme_extension.dart';
import 'package:pushup_bro/core/style/extensions/item_colors_theme_extensions.dart';
import 'package:pushup_bro/core/style/extensions/progress_theme_extensions.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/generated/fonts.gen.dart';

final theme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    onPrimary: background,
    secondary: secondaryColor,
    onSecondary: background2,
    tertiary: ternaryColor,
    onTertiary: background3,
    surface: background,
    surfaceDim: CupertinoColors.black,
    surfaceBright: CupertinoColors.white,
    inversePrimary: accentColor,
    shadow: shadowDark,
    error: CupertinoColors.destructiveRed,
  ),
  splashFactory: NoSplash.splashFactory,
  textTheme: const TextTheme(
    titleLarge: pageTitleTextStyle,
    titleMedium: secondaryPageTitleTextStyle,
    titleSmall: headerTextStyle,
    labelLarge: buttonTextStyle,
    bodyLarge: pushupTextStyle,
    bodyMedium: defaultTextStyle,
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(background2),
    ),
  ),
  fontFamily: FontFamily.satoshi,
  dividerTheme: const DividerThemeData(
    color: background3,
    thickness: 1,
    space: 0,
  ),
  searchBarTheme: SearchBarThemeData(
    hintStyle: WidgetStateProperty.all<TextStyle>(defaultTextStyle),
  ),
  extensions: [
    ProgressThemeExtension.build(),
    ItemColorsThemeExtensions.build(),
    GameColorsThemeExtension.build(),
  ],
);
