import 'package:flutter/painting.dart';

/// The raw colours behind the app's two colour schemes and its game
/// colours. Only the theme reads these: widgets use `context.colorScheme`
/// and `context.gameColors`, so both light and dark mode stay right.
abstract final class PBPalette {
  // Navy, the brand colour, from ink to mist.
  static const navy950 = Color(0xFF0B1020);
  static const navy900 = Color(0xFF111729);
  static const navy850 = Color(0xFF161D33);
  static const navy800 = Color(0xFF17203A);
  static const navy750 = Color(0xFF1D2640);
  static const navy700 = Color(0xFF252E4A);
  static const navy650 = Color(0xFF2E3856);
  static const navy600 = Color(0xFF3A4566);
  static const slate500 = Color(0xFF6B7489);
  static const slate400 = Color(0xFF8E96A9);
  static const slate300 = Color(0xFFA9AFC0);
  static const mist300 = Color(0xFFD5DCEB);
  static const mist200 = Color(0xFFE4E9F4);
  static const mist100 = Color(0xFFECF0F9);
  static const mist50 = Color(0xFFF2F6FF);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // The theme blue.
  static const blue = Color(0xFF5E9EFF);
  static const blueLight = Color(0xFF7FB2FF);

  // Game colours, as on the cards and in the Jungle Trek.
  static const red = Color(0xFFE5534B);
  static const redLight = Color(0xFFFF6E66);
  static const coral = Color(0xFFF26B5B);
  static const jungle = Color(0xFF2FA37A);
  static const jungleLight = Color(0xFF3CC08F);
  static const jungleDeep = Color(0xFF1F5A3C);
  static const leaf = Color(0xFF4FB35A);
  static const leafLight = Color(0xFF63C96E);
  static const banana = Color(0xFFF5C343);
  static const orange = Color(0xFFF5A623);
  static const purple = Color(0xFF8B5FD9);
  static const purpleLight = Color(0xFFA27CEB);
  static const ice = Color(0xFF4F9BE0);
  static const iceLight = Color(0xFF6CB2F2);
  static const held = Color(0xFF4A90E2);
  static const pink = Color(0xFFF07AA8);
  static const cream = Color(0xFFFFF4D6);
  static const creamDark = Color(0xFF3A3320);
  static const sand = Color(0xFFE1CFAE);
  static const grass = Color(0xFFABC090);
  static const map = Color(0xFFC0AB86);
}

@Deprecated('Use context.colorScheme.onSurface')
const Color primaryColor = Color(0xFF302f36);
@Deprecated('Use context.colorScheme.onSurfaceVariant')
const Color secondaryColor = Color(0xFFa9a8be);
@Deprecated('Use context.colorScheme.onSurface')
const Color ternaryColor = Color(0xFF1e1113);
@Deprecated('Use context.colorScheme.secondary')
const Color accentColor = Color(0xFF5E9EFF);
@Deprecated('Use context.colorScheme.shadow')
const Color shadow = Color(0xFF4A5367);
@Deprecated('Use context.colorScheme.shadow')
const Color shadowDark = Color(0xFF000000);
@Deprecated('Use context.colorScheme.surfaceContainerLow')
const Color background = Color(0xFFF2F6FF);
@Deprecated('Use context.colorScheme.primary (fills) or onSurface (text)')
const Color background2 = Color(0xFF17203A);
@Deprecated('Use context.colorScheme.outlineVariant')
const Color background3 = Color(0xFF25254B);
