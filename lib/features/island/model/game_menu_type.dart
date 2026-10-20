import 'package:flutter/material.dart';

enum GameMenuType {
  shop,
  quest,
  accessories,
  monkey;

  const GameMenuType();

  String getLocalizedTitle(BuildContext context) => switch (this) {
        GameMenuType.shop => 'Shop',
        GameMenuType.quest => 'Quest',
        GameMenuType.accessories => 'Accessories',
        GameMenuType.monkey => 'Monkey',
      };
}
