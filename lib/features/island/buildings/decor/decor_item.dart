import 'package:pushup_bro/generated/l10n.dart';

/// A decoration from the accessory shop, to stand anywhere on the island.
///
/// [radius] is how much ground (m) it takes up, for keeping it clear of
/// the buildings, the jungle and other decorations. [glow] is where its
/// flame or lamp sits, for the ones that light up at night.
enum DecorItem {
  rubberDucky(price: 20, emoji: '🦆', radius: 0.24),
  flowerBed(price: 30, emoji: '🌷', radius: 0.38),
  sandcastle(price: 40, emoji: '🏰', radius: 0.34),
  woodenSign(price: 50, emoji: '🪧', radius: 0.26),
  flamingo(price: 60, emoji: '🦩', radius: 0.26),
  lanternPost(price: 90, emoji: '🏮', radius: 0.24, glow: 0.86),
  beachUmbrella(price: 120, emoji: '⛱️', radius: 0.52),
  surfboardRack(price: 150, emoji: '🏄', radius: 0.46),
  bonfire(price: 170, emoji: '🔥', radius: 0.42, glow: 0.16),
  picnicTable(price: 200, emoji: '🧺', radius: 0.56),
  tikiTotem(price: 240, emoji: '🗿', radius: 0.26),
  lilyPond(price: 280, emoji: '🪷', radius: 0.66),
  hammock(price: 320, emoji: '🌴', radius: 0.78),
  bananaStatue(price: 380, emoji: '🍌', radius: 0.38),
  tikiBar(price: 450, emoji: '🛖', radius: 0.7),
  goldGorilla(price: 500, emoji: '🦍', radius: 0.46);

  const DecorItem({
    required this.price,
    required this.emoji,
    required this.radius,
    this.glow,
  });

  /// What it costs, in bananas.
  final int price;

  /// For its tile in the shop.
  final String emoji;
  final double radius;

  /// The height (m) of its flame, or null when it doesn't light up.
  final double? glow;

  /// The decoration saved as [id], or null for one this version doesn't
  /// know (saved by a newer app).
  static DecorItem? byId(Object? id) => _byId[id];
  static final Map<String, DecorItem> _byId = values.asNameMap();

  /// Saved in inventories and snapshots: never rename.
  String get id => name;

  String label(S l) => switch (this) {
        rubberDucky => l.decorRubberDucky,
        flowerBed => l.decorFlowerBed,
        sandcastle => l.decorSandcastle,
        woodenSign => l.decorWoodenSign,
        flamingo => l.decorFlamingo,
        lanternPost => l.decorLanternPost,
        beachUmbrella => l.decorBeachUmbrella,
        surfboardRack => l.decorSurfboardRack,
        bonfire => l.decorBonfire,
        picnicTable => l.decorPicnicTable,
        tikiTotem => l.decorTikiTotem,
        lilyPond => l.decorLilyPond,
        hammock => l.decorHammock,
        bananaStatue => l.decorBananaStatue,
        tikiBar => l.decorTikiBar,
        goldGorilla => l.decorGoldGorilla,
      };
}
