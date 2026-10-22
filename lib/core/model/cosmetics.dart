import 'dart:math' as math;
import 'dart:ui' show Color;

/// What part of the monkey's look a cosmetic changes.
enum CosmeticSlot {
  fur,
  face,
  hat,
  eyewear,
  outfit,
  matColor,
  matPattern;

  /// Hats, eyewear and outfits are sold by the island's Accessories Shop;
  /// colours and mats are always on offer.
  bool get needsAccessoriesShop =>
      this == hat || this == eyewear || this == outfit;
}

/// One thing the monkey can wear (or lie on).
///
/// [color] is set for colours; [emoji] is the shop's picture for wearables.
class Cosmetic {
  const Cosmetic(
    this.id,
    this.slot,
    this.name, {
    this.price = 0,
    this.color,
    this.emoji = '',
  });

  final String id;
  final CosmeticSlot slot;
  final String name;
  final int price;
  final Color? color;
  final String emoji;

  bool get free => price == 0;

  static Cosmetic? byId(String id) => _byId[id];

  /// Every cosmetic in [slot], in shop order (the default first).
  static List<Cosmetic> inSlot(CosmeticSlot slot) =>
      all.where((cosmetic) => cosmetic.slot == slot).toList();

  static final Map<String, Cosmetic> _byId = {
    for (final cosmetic in all) cosmetic.id: cosmetic,
  };

  static const all = <Cosmetic>[
    // Fur.
    Cosmetic(
      'fur.charcoal',
      CosmeticSlot.fur,
      'Charcoal',
      color: Color(0xFF3B3A45),
    ),
    Cosmetic(
      'fur.cocoa',
      CosmeticSlot.fur,
      'Cocoa',
      price: 40,
      color: Color(0xFF6B4A3A),
    ),
    Cosmetic(
      'fur.golden',
      CosmeticSlot.fur,
      'Golden',
      price: 40,
      color: Color(0xFFC27A3A),
    ),
    Cosmetic(
      'fur.ginger',
      CosmeticSlot.fur,
      'Ginger',
      price: 40,
      color: Color(0xFFE07B39),
    ),
    Cosmetic(
      'fur.snow',
      CosmeticSlot.fur,
      'Snow',
      price: 60,
      color: Color(0xFFE6E4EE),
    ),
    Cosmetic(
      'fur.midnight',
      CosmeticSlot.fur,
      'Midnight',
      price: 60,
      color: Color(0xFF2B3A67),
    ),
    Cosmetic(
      'fur.slate',
      CosmeticSlot.fur,
      'Slate',
      price: 60,
      color: Color(0xFF56637F),
    ),
    Cosmetic(
      'fur.bubblegum',
      CosmeticSlot.fur,
      'Bubblegum',
      price: 80,
      color: Color(0xFFF28DB2),
    ),
    Cosmetic(
      'fur.mint',
      CosmeticSlot.fur,
      'Mint',
      price: 80,
      color: Color(0xFF6CCFAE),
    ),
    Cosmetic(
      'fur.lavender',
      CosmeticSlot.fur,
      'Lavender',
      price: 80,
      color: Color(0xFFA48BE0),
    ),
    Cosmetic(
      'fur.sky',
      CosmeticSlot.fur,
      'Sky',
      price: 80,
      color: Color(0xFF6FB7F2),
    ),
    Cosmetic(
      'fur.lava',
      CosmeticSlot.fur,
      'Lava',
      price: 120,
      color: Color(0xFFD9443A),
    ),
    // Face and paws.
    Cosmetic(
      'face.lilac',
      CosmeticSlot.face,
      'Lilac',
      color: Color(0xFFC9C4DD),
    ),
    Cosmetic(
      'face.peach',
      CosmeticSlot.face,
      'Peach',
      price: 30,
      color: Color(0xFFF6CDB4),
    ),
    Cosmetic(
      'face.sand',
      CosmeticSlot.face,
      'Sand',
      price: 30,
      color: Color(0xFFE8D2A8),
    ),
    Cosmetic(
      'face.blush',
      CosmeticSlot.face,
      'Blush',
      price: 30,
      color: Color(0xFFF7D9DE),
    ),
    Cosmetic(
      'face.cream',
      CosmeticSlot.face,
      'Cream',
      price: 30,
      color: Color(0xFFF4EDE1),
    ),
    Cosmetic(
      'face.mocha',
      CosmeticSlot.face,
      'Mocha',
      price: 30,
      color: Color(0xFFB48A6A),
    ),
    Cosmetic(
      'face.frost',
      CosmeticSlot.face,
      'Frost',
      price: 60,
      color: Color(0xFFC9E3F2),
    ),
    // Hats.
    Cosmetic('hat.none', CosmeticSlot.hat, 'No hat', emoji: '🚫'),
    Cosmetic(
      'hat.party',
      CosmeticSlot.hat,
      'Party Hat',
      price: 50,
      emoji: '🥳',
    ),
    Cosmetic(
      'hat.sweatband',
      CosmeticSlot.hat,
      'Sweatband',
      price: 60,
      emoji: '🏋️',
    ),
    Cosmetic('hat.cap', CosmeticSlot.hat, 'Gym Cap', price: 80, emoji: '🧢'),
    Cosmetic(
      'hat.beanie',
      CosmeticSlot.hat,
      'Beanie',
      price: 80,
      emoji: '🧶',
    ),
    Cosmetic(
      'hat.banana',
      CosmeticSlot.hat,
      'Banana Hat',
      price: 120,
      emoji: '🍌',
    ),
    Cosmetic(
      'hat.flowers',
      CosmeticSlot.hat,
      'Flower Crown',
      price: 150,
      emoji: '🌺',
    ),
    Cosmetic(
      'hat.chef',
      CosmeticSlot.hat,
      'Chef Hat',
      price: 150,
      emoji: '👨‍🍳',
    ),
    Cosmetic(
      'hat.propeller',
      CosmeticSlot.hat,
      'Propeller Cap',
      price: 180,
      emoji: '🚁',
    ),
    Cosmetic('hat.top', CosmeticSlot.hat, 'Top Hat', price: 200, emoji: '🎩'),
    Cosmetic(
      'hat.cowboy',
      CosmeticSlot.hat,
      'Cowboy Hat',
      price: 200,
      emoji: '🤠',
    ),
    Cosmetic(
      'hat.pirate',
      CosmeticSlot.hat,
      'Pirate Hat',
      price: 250,
      emoji: '🏴‍☠️',
    ),
    Cosmetic(
      'hat.wizard',
      CosmeticSlot.hat,
      'Wizard Hat',
      price: 300,
      emoji: '🧙',
    ),
    Cosmetic(
      'hat.viking',
      CosmeticSlot.hat,
      'Viking Helmet',
      price: 350,
      emoji: '⚔️',
    ),
    Cosmetic('hat.crown', CosmeticSlot.hat, 'Crown', price: 400, emoji: '👑'),
    Cosmetic('hat.halo', CosmeticSlot.hat, 'Halo', price: 500, emoji: '😇'),
    // Eyewear.
    Cosmetic('eyes.none', CosmeticSlot.eyewear, 'Nothing', emoji: '🚫'),
    Cosmetic(
      'eyes.shades',
      CosmeticSlot.eyewear,
      'Shades',
      price: 80,
      emoji: '🕶️',
    ),
    Cosmetic(
      'eyes.nerd',
      CosmeticSlot.eyewear,
      'Round Glasses',
      price: 80,
      emoji: '🤓',
    ),
    Cosmetic(
      'eyes.mustache',
      CosmeticSlot.eyewear,
      'Mustache',
      price: 100,
      emoji: '🥸',
    ),
    Cosmetic(
      'eyes.hearts',
      CosmeticSlot.eyewear,
      'Heart Glasses',
      price: 120,
      emoji: '😍',
    ),
    Cosmetic(
      'eyes.stars',
      CosmeticSlot.eyewear,
      'Star Glasses',
      price: 120,
      emoji: '🤩',
    ),
    Cosmetic(
      'eyes.monocle',
      CosmeticSlot.eyewear,
      'Monocle',
      price: 150,
      emoji: '🧐',
    ),
    Cosmetic(
      'eyes.visor',
      CosmeticSlot.eyewear,
      'Cyber Visor',
      price: 200,
      emoji: '🥽',
    ),
    // Outfits.
    Cosmetic('outfit.none', CosmeticSlot.outfit, 'Nothing', emoji: '🚫'),
    Cosmetic(
      'outfit.wristbands',
      CosmeticSlot.outfit,
      'Wristbands',
      price: 60,
      emoji: '💪',
    ),
    Cosmetic(
      'outfit.bowtie',
      CosmeticSlot.outfit,
      'Bow Tie',
      price: 60,
      emoji: '🎀',
    ),
    Cosmetic(
      'outfit.tank',
      CosmeticSlot.outfit,
      'Tank Top',
      price: 80,
      emoji: '🎽',
    ),
    Cosmetic(
      'outfit.scarf',
      CosmeticSlot.outfit,
      'Scarf',
      price: 100,
      emoji: '🧣',
    ),
    Cosmetic(
      'outfit.lei',
      CosmeticSlot.outfit,
      'Flower Lei',
      price: 120,
      emoji: '🌸',
    ),
    Cosmetic(
      'outfit.tutu',
      CosmeticSlot.outfit,
      'Tutu',
      price: 150,
      emoji: '🩰',
    ),
    Cosmetic(
      'outfit.cape',
      CosmeticSlot.outfit,
      'Hero Cape',
      price: 250,
      emoji: '🦸',
    ),
    Cosmetic(
      'outfit.chain',
      CosmeticSlot.outfit,
      'Gold Chain',
      price: 300,
      emoji: '📿',
    ),
    // Mat colours.
    Cosmetic(
      'mat.blue',
      CosmeticSlot.matColor,
      'Blue',
      color: Color(0xFF5E9EFF),
    ),
    Cosmetic(
      'mat.pink',
      CosmeticSlot.matColor,
      'Pink',
      price: 20,
      color: Color(0xFFF59AB0),
    ),
    Cosmetic(
      'mat.mint',
      CosmeticSlot.matColor,
      'Mint',
      price: 20,
      color: Color(0xFF7DD9B5),
    ),
    Cosmetic(
      'mat.sunny',
      CosmeticSlot.matColor,
      'Sunny',
      price: 20,
      color: Color(0xFFF6CF5C),
    ),
    Cosmetic(
      'mat.lilac',
      CosmeticSlot.matColor,
      'Lilac',
      price: 20,
      color: Color(0xFFB7A6F2),
    ),
    Cosmetic(
      'mat.coral',
      CosmeticSlot.matColor,
      'Coral',
      price: 20,
      color: Color(0xFFF26B5B),
    ),
    Cosmetic(
      'mat.lime',
      CosmeticSlot.matColor,
      'Lime',
      price: 30,
      color: Color(0xFFA6D94F),
    ),
    Cosmetic(
      'mat.navy',
      CosmeticSlot.matColor,
      'Navy',
      price: 40,
      color: Color(0xFF17203A),
    ),
    Cosmetic(
      'mat.charcoal',
      CosmeticSlot.matColor,
      'Charcoal',
      price: 40,
      color: Color(0xFF3A3D47),
    ),
    Cosmetic(
      'mat.cloud',
      CosmeticSlot.matColor,
      'Cloud',
      price: 40,
      color: Color(0xFFF2F4F8),
    ),
    // Mat patterns.
    Cosmetic('pattern.solid', CosmeticSlot.matPattern, 'Plain'),
    Cosmetic(
      'pattern.stripes',
      CosmeticSlot.matPattern,
      'Stripes',
      price: 40,
    ),
    Cosmetic(
      'pattern.dots',
      CosmeticSlot.matPattern,
      'Polka Dots',
      price: 40,
    ),
    Cosmetic(
      'pattern.checker',
      CosmeticSlot.matPattern,
      'Checkers',
      price: 60,
    ),
    Cosmetic(
      'pattern.zigzag',
      CosmeticSlot.matPattern,
      'Zigzag',
      price: 60,
    ),
    Cosmetic('pattern.stars', CosmeticSlot.matPattern, 'Stars', price: 80),
    Cosmetic(
      'pattern.hearts',
      CosmeticSlot.matPattern,
      'Hearts',
      price: 80,
    ),
    Cosmetic(
      'pattern.bananas',
      CosmeticSlot.matPattern,
      'Bananas',
      price: 100,
    ),
    Cosmetic('pattern.camo', CosmeticSlot.matPattern, 'Camo', price: 100),
    Cosmetic(
      'pattern.rainbow',
      CosmeticSlot.matPattern,
      'Rainbow',
      price: 150,
    ),
  ];
}

/// The colour of a mat in [base] colour with [pattern] at point ([x], [z])
/// of its surface, in metres from the middle (x across, z along). Null
/// where the plain base colour shows.
///
/// Shared by the 3D mats and the shop's swatches, so they match.
Color? matPatternColor(String pattern, Color base, double x, double z) {
  final light = base.computeLuminance() > 0.55;
  final ink = light ? const Color(0xFF17203A) : const Color(0xFFFFFFFF);

  switch (pattern) {
    case 'pattern.stripes':
      return (z / 0.12).floor().isEven ? null : ink;
    case 'pattern.dots':
      final row = (z / 0.16).floor();
      final dx = ((x / 0.16) + (row.isEven ? 0 : 0.5)) % 1 - 0.5;
      final dz = (z / 0.16) % 1 - 0.5;
      return dx * dx + dz * dz < 0.07 ? ink : null;
    case 'pattern.checker':
      return ((x / 0.14).floor() + (z / 0.14).floor()).isEven ? null : ink;
    case 'pattern.zigzag':
      final wave = ((x / 0.1) % 2 - 1).abs() * 0.08;
      return ((z + wave) / 0.14).floor().isEven ? null : ink;
    case 'pattern.stars':
      return _tiled(x, z, 0.24, _star) ? const Color(0xFFF5C343) : null;
    case 'pattern.hearts':
      return _tiled(x, z, 0.22, _heart) ? const Color(0xFFF26B8A) : null;
    case 'pattern.bananas':
      return _tiled(x, z, 0.26, _banana) ? const Color(0xFFF5C343) : null;
    case 'pattern.camo':
      final n = math.sin(x * 9.1 + math.sin(z * 4.3) * 2) +
          math.sin(z * 7.7 + math.sin(x * 5.9) * 1.6);
      if (n > 0.8) return _shade(base, 0.6);
      if (n < -0.9) return _shade(base, 1.35);
      return null;
    case 'pattern.rainbow':
      const bands = [
        Color(0xFFF26B5B),
        Color(0xFFFF9F43),
        Color(0xFFF5C343),
        Color(0xFF7DD9B5),
        Color(0xFF5E9EFF),
        Color(0xFFB98AF2),
      ];
      final band = ((z + 0.9) / 1.8 * bands.length).floor();
      return bands[band.clamp(0, bands.length - 1)];
    default:
      return null;
  }
}

/// Whether ([x], [z]) falls on [shape], repeated every [cell] metres with
/// alternate rows offset; [shape] gets coordinates from -1 to 1 in a cell.
bool _tiled(
  double x,
  double z,
  double cell,
  bool Function(double u, double v) shape,
) {
  final row = (z / cell).floor();
  final u = ((x / cell + (row.isEven ? 0 : 0.5)) % 1) * 2 - 1;
  final v = ((z / cell) % 1) * 2 - 1;

  return shape(u * 1.4, v * 1.4);
}

bool _star(double u, double v) {
  final r = math.sqrt(u * u + v * v);
  final a = math.atan2(v, u);
  final spike = 0.45 + 0.35 * math.cos(5 * a).abs();

  return r < spike * 0.95;
}

bool _heart(double u, double v) {
  // A classic implicit heart, pointing towards -v.
  final x = u * 1.2;
  final y = -v * 1.2 + 0.25;
  final q = x * x + y * y - 1;

  return q * q * q - x * x * y * y * y < 0;
}

bool _banana(double u, double v) {
  // A thick arc: between two offset circles.
  final outer = u * u + (v + 0.6) * (v + 0.6);
  final inner = u * u + (v + 0.95) * (v + 0.95);

  return outer < 1.0 && inner > 0.85 && v > -0.55;
}

Color _shade(Color color, double factor) => Color.from(
      alpha: 1,
      red: (color.r * factor).clamp(0, 1),
      green: (color.g * factor).clamp(0, 1),
      blue: (color.b * factor).clamp(0, 1),
    );
