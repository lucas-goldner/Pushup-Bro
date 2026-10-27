import 'package:flutter/material.dart';
import 'package:pushup_bro/generated/fonts.gen.dart';

/// Cabinet Grotesk for big numbers and titles, Satoshi for everything you
/// read and tap. Colours come from the colour scheme (the theme applies
/// them), so use `context.textTheme` in widgets.
///
/// - display: counters and score numbers (Cabinet Grotesk, extra bold)
/// - headline: page and sheet titles (Cabinet Grotesk, bold)
/// - title: card titles and row labels (Satoshi, bold)
/// - body: text (Satoshi); bodySmall is the muted secondary text
/// - label: buttons, chips and tags (Satoshi, bold)
const pbTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: FontFamily.cabinetGrotesk,
    fontWeight: FontWeight.w800,
    fontSize: 72,
    height: 1,
    letterSpacing: -1.5,
  ),
  displayMedium: TextStyle(
    fontFamily: FontFamily.cabinetGrotesk,
    fontWeight: FontWeight.w800,
    fontSize: 48,
    height: 1,
    letterSpacing: -1,
  ),
  displaySmall: TextStyle(
    fontFamily: FontFamily.cabinetGrotesk,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    height: 1.05,
    letterSpacing: -0.5,
  ),
  headlineLarge: TextStyle(
    fontFamily: FontFamily.cabinetGrotesk,
    fontWeight: FontWeight.w800,
    fontSize: 30,
    height: 1.1,
    letterSpacing: -0.4,
  ),
  headlineMedium: TextStyle(
    fontFamily: FontFamily.cabinetGrotesk,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 1.15,
    letterSpacing: -0.3,
  ),
  headlineSmall: TextStyle(
    fontFamily: FontFamily.cabinetGrotesk,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.15,
    letterSpacing: -0.2,
  ),
  titleLarge: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.25,
  ),
  titleMedium: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    height: 1.3,
  ),
  titleSmall: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 1.3,
  ),
  bodyLarge: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    height: 1.4,
  ),
  bodyMedium: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.4,
  ),
  bodySmall: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.4,
  ),
  labelLarge: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: 0.1,
  ),
  labelMedium: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w700,
    fontSize: 13,
  ),
  labelSmall: TextStyle(
    fontFamily: FontFamily.satoshi,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 0.8,
  ),
);

@Deprecated('Use context.textTheme.displaySmall')
const pushupTextStyle = TextStyle(
  fontFamily: FontFamily.satoshi,
  fontWeight: FontWeight.w700,
  fontSize: 32,
);

@Deprecated('Use context.textTheme.headlineLarge')
const pageTitleTextStyle = TextStyle(
  fontFamily: FontFamily.satoshi,
  fontWeight: FontWeight.w700,
  fontSize: 28,
);

@Deprecated('Use context.textTheme.headlineSmall')
const secondaryPageTitleTextStyle = TextStyle(
  fontFamily: FontFamily.satoshi,
  fontWeight: FontWeight.w700,
  fontSize: 22,
  decoration: TextDecoration.underline,
);

@Deprecated('Use context.textTheme.titleLarge')
const headerTextStyle = TextStyle(
  fontFamily: FontFamily.satoshi,
  fontWeight: FontWeight.w500,
  fontSize: 20,
);

@Deprecated('Use context.textTheme.labelLarge')
const buttonTextStyle = TextStyle(
  fontFamily: FontFamily.satoshi,
  fontWeight: FontWeight.w500,
  fontSize: 16,
  color: Colors.white,
);

@Deprecated('Use context.textTheme.bodyMedium')
const defaultTextStyle = TextStyle(
  fontFamily: FontFamily.satoshi,
  fontWeight: FontWeight.w400,
  fontSize: 16,
  color: Color(0xFF302f36),
);
