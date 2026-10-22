import 'package:pushup_bro/core/model/monkey_look.dart';

class AdoptableMonkey {
  AdoptableMonkey({
    this.name = '',
    this.xp = 0,
    this.look = const MonkeyLook(),
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
    );
  }

  AdoptableMonkey copyWith({
    String? name,
    int? xp,
    MonkeyLook? look,
  }) =>
      AdoptableMonkey(
        name: name ?? this.name,
        xp: xp ?? this.xp,
        look: look ?? this.look,
      );

  final String name;
  final int xp;
  final MonkeyLook look;

  Map<String, dynamic> toJson() => {
        'name': name,
        'xp': xp,
        'look': look.toJson(),
      };
}
