import 'package:pushup_bro/features/island/model/shop_buyables.dart';

class AdoptableMonkey {
  AdoptableMonkey({
    this.name = '',
    this.xp = 0,
    this.accessory = ShopBuyables.none,
  });

  factory AdoptableMonkey.carlos() => AdoptableMonkey(
        name: 'Carlos',
      );

  factory AdoptableMonkey.fromJson(Map<String, dynamic> json) =>
      AdoptableMonkey(
        name: json['name'] as String? ?? '',
        xp: json['xp'] as int? ?? 0,
        accessory: ShopBuyables.values.asNameMap()[json['accessory']] ??
            ShopBuyables.none,
      );

  AdoptableMonkey copyWith({
    String? name,
    int? xp,
    ShopBuyables? accessory,
  }) =>
      AdoptableMonkey(
        name: name ?? this.name,
        xp: xp ?? this.xp,
        accessory: accessory ?? this.accessory,
      );

  final String name;
  final int xp;
  final ShopBuyables accessory;

  Map<String, dynamic> toJson() => {
        'name': name,
        'xp': xp,
        'accessory': accessory.name,
      };
}
