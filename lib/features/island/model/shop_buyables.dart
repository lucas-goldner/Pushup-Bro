import 'package:flutter/material.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

enum ShopBuyables {
  accessories,
  airport,
  gym,
  monkeyAdoption,
  accessoryPartyHat,
  none;

  const ShopBuyables();

  static List<ShopBuyables> get buildingsShopBuyables => [
        ShopBuyables.accessories,
        ShopBuyables.airport,
        ShopBuyables.gym,
        ShopBuyables.monkeyAdoption,
      ];

  static List<ShopBuyables> get accessoriesShopBuyables => [
        ShopBuyables.accessoryPartyHat,
      ];

  String getLocalizedName(BuildContext context) => switch (this) {
        ShopBuyables.accessories => 'Accessories Shop',
        ShopBuyables.airport => 'Airport',
        ShopBuyables.gym => 'Gym',
        ShopBuyables.monkeyAdoption => 'Monkey Adoption',
        ShopBuyables.accessoryPartyHat => 'Party Hat',
        ShopBuyables.none => throw UnimplementedError(),
      };

  int get price => switch (this) {
        ShopBuyables.accessories => 50,
        ShopBuyables.airport => 500,
        ShopBuyables.gym => 1000,
        ShopBuyables.monkeyAdoption => 2000,
        ShopBuyables.accessoryPartyHat => 50,
        ShopBuyables.none => 0,
      };

  AssetGenImage get genImg => switch (this) {
        ShopBuyables.accessories => Assets.images.island.accessoriesShop,
        ShopBuyables.airport => Assets.images.island.airport,
        ShopBuyables.gym => Assets.images.island.gym,
        ShopBuyables.monkeyAdoption => Assets.images.island.monkeyAdoption,
        ShopBuyables.accessoryPartyHat =>
          Assets.images.island.accessories.partyHat,
        ShopBuyables.none => Assets.images.island.bush1,
      };
}
