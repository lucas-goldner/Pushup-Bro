import 'package:pushup_bro/core/model/monkey_look.dart';

class AdoptableMonkey {
  AdoptableMonkey({
    this.name = '',
    this.xp = 0,
    this.look = const MonkeyLook(),
    this.adopted = false,
    this.trainsInGym = false,
    this.personality = -1,
  });

  factory AdoptableMonkey.carlos() => AdoptableMonkey(
        name: 'Carlos',
      );

  factory AdoptableMonkey.fromJson(Map<String, dynamic> json) {
    final look = json['look'];

    return AdoptableMonkey(
      name: json['name'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      look: look is Map<String, dynamic>
          ? MonkeyLook.fromJson(look)
          // Saves from before the wardrobe only had the party hat.
          : json['accessory'] == 'accessoryPartyHat'
              ? const MonkeyLook(hat: 'hat.party')
              : const MonkeyLook(),
      adopted: json['adopted'] as bool? ?? false,
      trainsInGym: json['gym'] as bool? ?? false,
      personality: json['personality'] as int? ?? -1,
    );
  }

  AdoptableMonkey copyWith({
    String? name,
    int? xp,
    MonkeyLook? look,
    bool? trainsInGym,
  }) =>
      AdoptableMonkey(
        name: name ?? this.name,
        xp: xp ?? this.xp,
        look: look ?? this.look,
        adopted: adopted,
        trainsInGym: trainsInGym ?? this.trainsInGym,
        personality: personality,
      );

  final String name;
  final int xp;
  final MonkeyLook look;

  /// Adopted at the adoption centre (Carlos and King Komo weren't): sets
  /// the price of the next one.
  final bool adopted;

  /// Works out next to the player's monkey in the home gym.
  final bool trainsInGym;

  /// Which personality line the adoption centre gave them; -1 for none.
  final int personality;

  Map<String, dynamic> toJson() => {
        'name': name,
        'xp': xp,
        'look': look.toJson(),
        'adopted': adopted,
        'gym': trainsInGym,
        'personality': personality,
      };
}
