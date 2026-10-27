import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';

/// The game's own colours, beside the colour scheme: what fights, quests,
/// bananas and rewards are drawn in. Each has a light and a dark mode
/// value, so use `context.gameColors` and never a hex in a widget.
@immutable
class GameColorsThemeExtension
    extends ThemeExtension<GameColorsThemeExtension> {
  const GameColorsThemeExtension({
    required this.red,
    required this.coral,
    required this.jungle,
    required this.jungleDeep,
    required this.leaf,
    required this.banana,
    required this.orange,
    required this.purple,
    required this.ice,
    required this.held,
    required this.pink,
    required this.cream,
    required this.onGame,
    required this.sand,
    required this.grass,
    required this.map,
  });

  factory GameColorsThemeExtension.light() => const GameColorsThemeExtension(
        red: PBPalette.red,
        coral: PBPalette.coral,
        jungle: PBPalette.jungle,
        jungleDeep: PBPalette.jungleDeep,
        leaf: PBPalette.leaf,
        banana: PBPalette.banana,
        orange: PBPalette.orange,
        purple: PBPalette.purple,
        ice: PBPalette.ice,
        held: PBPalette.held,
        pink: PBPalette.pink,
        cream: PBPalette.cream,
        onGame: PBPalette.white,
        sand: PBPalette.sand,
        grass: PBPalette.grass,
        map: PBPalette.map,
      );

  factory GameColorsThemeExtension.dark() => const GameColorsThemeExtension(
        red: PBPalette.redLight,
        coral: PBPalette.coral,
        jungle: PBPalette.jungleLight,
        jungleDeep: PBPalette.jungleDeep,
        leaf: PBPalette.leafLight,
        banana: PBPalette.banana,
        orange: PBPalette.orange,
        purple: PBPalette.purpleLight,
        ice: PBPalette.iceLight,
        held: PBPalette.blueLight,
        pink: PBPalette.pink,
        cream: PBPalette.creamDark,
        onGame: PBPalette.white,
        sand: PBPalette.sand,
        grass: PBPalette.grass,
        map: PBPalette.map,
      );

  /// Fight, damage, health, "too expensive".
  final Color red;
  final Color coral;

  /// Quests and the jungle.
  final Color jungle;
  final Color jungleDeep;

  /// Success, a normal pushup.
  final Color leaf;

  /// Bananas, stars, a quick pushup, combos.
  final Color banana;
  final Color orange;
  final Color purple;
  final Color ice;

  /// A pushup held at the bottom.
  final Color held;
  final Color pink;

  /// Warm card fill behind banana rewards.
  final Color cream;

  /// Text and icons on any of the colours above.
  final Color onGame;

  final Color sand;
  final Color grass;
  final Color map;

  @override
  GameColorsThemeExtension copyWith({
    Color? red,
    Color? coral,
    Color? jungle,
    Color? jungleDeep,
    Color? leaf,
    Color? banana,
    Color? orange,
    Color? purple,
    Color? ice,
    Color? held,
    Color? pink,
    Color? cream,
    Color? onGame,
    Color? sand,
    Color? grass,
    Color? map,
  }) =>
      GameColorsThemeExtension(
        red: red ?? this.red,
        coral: coral ?? this.coral,
        jungle: jungle ?? this.jungle,
        jungleDeep: jungleDeep ?? this.jungleDeep,
        leaf: leaf ?? this.leaf,
        banana: banana ?? this.banana,
        orange: orange ?? this.orange,
        purple: purple ?? this.purple,
        ice: ice ?? this.ice,
        held: held ?? this.held,
        pink: pink ?? this.pink,
        cream: cream ?? this.cream,
        onGame: onGame ?? this.onGame,
        sand: sand ?? this.sand,
        grass: grass ?? this.grass,
        map: map ?? this.map,
      );

  @override
  GameColorsThemeExtension lerp(
    covariant ThemeExtension<GameColorsThemeExtension>? other,
    double t,
  ) {
    if (other is! GameColorsThemeExtension) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;

    return GameColorsThemeExtension(
      red: l(red, other.red),
      coral: l(coral, other.coral),
      jungle: l(jungle, other.jungle),
      jungleDeep: l(jungleDeep, other.jungleDeep),
      leaf: l(leaf, other.leaf),
      banana: l(banana, other.banana),
      orange: l(orange, other.orange),
      purple: l(purple, other.purple),
      ice: l(ice, other.ice),
      held: l(held, other.held),
      pink: l(pink, other.pink),
      cream: l(cream, other.cream),
      onGame: l(onGame, other.onGame),
      sand: l(sand, other.sand),
      grass: l(grass, other.grass),
      map: l(map, other.map),
    );
  }
}
