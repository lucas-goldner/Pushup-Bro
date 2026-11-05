import 'package:flutter/material.dart';
import 'package:pushup_bro/features/island/buildings/adoption_page.dart';
import 'package:pushup_bro/features/island/buildings/airport_page.dart';
import 'package:pushup_bro/features/island/buildings/decor_page.dart';
import 'package:pushup_bro/features/island/buildings/gym_page.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';

/// Opens what [building] offers once it's built: decorations at the
/// accessory shop, bros' islands at the airport, the gym's own daily
/// challenge, and more monkeys at the adoption centre. The food truck
/// (the shop itself) is opened by the island.
Future<void> openBuilding(BuildContext context, ShopBuyables building) {
  final page = switch (building) {
    ShopBuyables.accessories => const DecorPage(),
    ShopBuyables.airport => const AirportPage(),
    ShopBuyables.gym => const GymPage(),
    ShopBuyables.monkeyAdoption => const AdoptionPage(),
    ShopBuyables.accessoryPartyHat || ShopBuyables.none => null,
  };
  if (page == null) return Future.value();

  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (context) => page),
  );
}
