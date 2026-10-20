import 'package:pushup_bro/features/island/model/shop_buyables.dart';

extension ListShopBuyablesExtension on List<ShopBuyables> {
  bool get hasAccessories => contains(ShopBuyables.accessories);
}
