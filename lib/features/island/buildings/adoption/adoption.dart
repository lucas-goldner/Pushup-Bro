import 'dart:math' as math;

import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';

/// The adoption centre's rules: room for four monkeys besides the player's
/// own, each adoption much dearer than the last.
abstract final class Adoption {
  /// What the first, second, third and fourth adoption cost. A keen player
  /// earns about 150 bananas a day (a pushup each, quests, the Trek and the
  /// daily bananas), so the first takes about ten days and the last months.
  static const prices = [1500, 4000, 9000, 20000];

  /// Monkeys on the island besides the player's own, King Komo included:
  /// more than five gorillas would make the island too slow to draw.
  static const maxExtras = 4;

  /// How long a name may be: it has to fit under a monkey in a tile.
  static const maxNameLength = 12;

  /// How many personality lines there are (see `adoptionPersona`).
  static const personalities = 8;

  /// Names that read well in every language the game speaks.
  static const names = [
    'Mango',
    'Kiwi',
    'Coco',
    'Momo',
    'Lulu',
    'Pipo',
    'Bongo',
    'Tiki',
    'Nala',
    'Bubu',
    'Suki',
    'Pepe',
    'Mimi',
    'Taro',
    'Zuzu',
    'Kiki',
    'Bobo',
    'Nori',
    'Lola',
    'Yuki',
    'Rico',
    'Pina',
    'Toto',
    'Gigi',
  ];

  /// The fur, faces, hats and mats a monkey can arrive in: anything that
  /// isn't a Trek trophy, and only the cheaper hats.
  static List<String> _choices(CosmeticSlot slot, {int maxPrice = 1 << 30}) => [
        for (final cosmetic in Cosmetic.inSlot(slot))
          if (!cosmetic.exclusive && cosmetic.price <= maxPrice) cosmetic.id,
      ];

  /// [count] monkeys hoping to be adopted, each with their own look, name
  /// and personality. The same [seed] meets the same monkeys; names in
  /// [taken] are skipped and personalities in [takenPersonalities] come
  /// last, so the island's monkeys stay different.
  static List<AdoptableMonkey> candidates(
    int seed, {
    int count = 3,
    Iterable<String> taken = const [],
    Iterable<int> takenPersonalities = const [],
  }) {
    final random = math.Random(seed);
    final names = [
      for (final name in Adoption.names)
        if (!taken.contains(name)) name,
    ]..shuffle(random);
    final furs = _choices(CosmeticSlot.fur)..shuffle(random);
    final faces = _choices(CosmeticSlot.face);
    final hats = _choices(CosmeticSlot.hat, maxPrice: 120)..remove('hat.none');
    final mats = _choices(CosmeticSlot.matColor);
    final shuffled = List.generate(Adoption.personalities, (i) => i)
      ..shuffle(random);
    final personalities = [
      ...shuffled.where((p) => !takenPersonalities.contains(p)),
      ...shuffled.where(takenPersonalities.contains),
    ];

    return [
      for (var i = 0; i < count; i++)
        AdoptableMonkey(
          name: names[i % names.length],
          personality: personalities[i % personalities.length],
          trainsInGym: true,
          look: MonkeyLook(
            // Every one a different colour, so they're easy to tell apart.
            fur: furs[i % furs.length],
            face: faces[random.nextInt(faces.length)],
            // About half arrive in a hat.
            hat: random.nextBool()
                ? hats[random.nextInt(hats.length)]
                : const MonkeyLook().hat,
            matColor: mats[random.nextInt(mats.length)],
          ),
        ),
    ];
  }

  /// A name as typed: trimmed and cut to [maxNameLength]; null if empty.
  static String? cleanName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final letters = trimmed.runes.toList();

    return letters.length <= maxNameLength
        ? trimmed
        : String.fromCharCodes(letters.take(maxNameLength)).trim();
  }
}

/// The adoption centre's view of the inventory. The first monkey is the
/// one the player plays as (usually Carlos); the rest are the extras.
extension AdoptionInventory on GameInventory {
  /// The monkeys besides the player's own, in the order they joined.
  List<AdoptableMonkey> get extras => monkeys.skip(1).toList();

  /// How many monkeys came from the adoption centre.
  int get adoptedCount => monkeys.where((monkey) => monkey.adopted).length;

  /// Whether another monkey can move in.
  bool get hasRoomForMonkey =>
      extras.length < Adoption.maxExtras &&
      adoptedCount < Adoption.prices.length;

  /// What the next adoption costs; null once the island is full.
  int? get nextAdoptionPrice =>
      hasRoomForMonkey ? Adoption.prices[adoptedCount] : null;

  /// The prices of the free spots, the next one first.
  List<int> get freeSpotPrices => [
        for (var i = 0; i < Adoption.maxExtras - extras.length; i++)
          if (adoptedCount + i < Adoption.prices.length)
            Adoption.prices[adoptedCount + i],
      ];

  /// Whether King Komo, beaten in the Trek, can still join.
  bool get komoToCome =>
      !monkeys.any((monkey) => monkey.look.species == MonkeyLook.lizard);

  /// With [monkey] adopted: paid for, living on the island and owning the
  /// fur and hat it arrived in. Null without room or enough bananas.
  GameInventory? adopt(AdoptableMonkey monkey) {
    final price = nextAdoptionPrice;
    if (price == null || bananas < price) return null;
    final name = Adoption.cleanName(monkey.name) ?? monkey.name;

    return copyWith(
      bananas: bananas - price,
      monkeys: [
        ...monkeys,
        AdoptableMonkey(
          name: name,
          look: monkey.look,
          adopted: true,
          trainsInGym: monkey.trainsInGym,
          personality: monkey.personality,
        ),
      ],
      ownedCosmetics: {...ownedCosmetics, ...monkey.look.ids}
          .where((id) => !MonkeyLook.defaults.contains(id))
          .toList(),
    );
  }

  /// With the monkey at [index] renamed; unchanged for an empty name.
  GameInventory renameMonkey(int index, String name) {
    final clean = Adoption.cleanName(name);
    if (clean == null || index < 0 || index >= monkeys.length) return this;

    return _replace(index, monkeys[index].copyWith(name: clean));
  }

  /// With the monkey at [index] wearing [look].
  GameInventory dressMonkey(int index, MonkeyLook look) {
    if (index < 0 || index >= monkeys.length) return this;

    return _replace(index, monkeys[index].copyWith(look: look));
  }

  /// With the monkey at [index] training in the home gym, or not.
  GameInventory trainInGym(int index, {required bool train}) {
    if (index < 1 || index >= monkeys.length) return this;

    return _replace(index, monkeys[index].copyWith(trainsInGym: train));
  }

  /// Plays as the monkey at [index]: it moves to the front, the one played
  /// before takes its spot among the extras.
  GameInventory playAs(int index) {
    if (index < 1 || index >= monkeys.length) return this;

    return copyWith(
      monkeys: [
        monkeys[index],
        for (final (i, monkey) in monkeys.indexed)
          if (i != index) monkey,
      ],
    );
  }

  /// The extras on the island, at most [Adoption.maxExtras].
  List<MonkeyLook> get islandFriends => [
        for (final monkey in extras.take(Adoption.maxExtras)) monkey.look,
      ];

  /// The extras who train with the player in the home gym.
  List<MonkeyLook> get gymMates => [
        for (final monkey in extras.take(Adoption.maxExtras))
          if (monkey.trainsInGym) monkey.look,
      ];

  GameInventory _replace(int index, AdoptableMonkey monkey) =>
      copyWith(monkeys: [...monkeys]..[index] = monkey);
}

/// Who works out in the home gym, nearest station first: the [mates] the
/// player picked, then strangers until there are [buddies] (the gym's own
/// count); never more than [stations]. A null look is a stranger.
List<MonkeyLook?> gymLineup(
  List<MonkeyLook> mates, {
  required int buddies,
  int stations = Adoption.maxExtras,
}) {
  final count = math.min(stations, math.max(mates.length, buddies));

  return List.generate(count, (i) => i < mates.length ? mates[i] : null);
}
