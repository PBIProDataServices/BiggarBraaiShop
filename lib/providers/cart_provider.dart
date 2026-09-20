import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/shop_listing.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get total =>
      _items.values.fold(0, (sum, item) => sum + item.lineTotal);

  void addListing(ShopListing listing, {int quantity = 1}) {
    if (_items.containsKey(listing.stockId)) {
      final current = _items[listing.stockId]!;
      final nextQty = current.quantity + quantity;
      current.quantity =
          nextQty > listing.quantity ? listing.quantity : nextQty;
    } else {
      _items[listing.stockId] = CartItem(
        stockId: listing.stockId,
        productType: listing.productType,
        partnerId: listing.partnerId,
        partnerName: listing.partnerName,
        unitPrice: listing.price,
        weightRequired: listing.weightRequired,
        imageAsset: listing.imageAsset,
        imageUrl: listing.featureImageUrl,
        quantity: quantity > listing.quantity ? listing.quantity : quantity,
      );
    }
    notifyListeners();
  }

  void increase(String stockId, int maxQuantity) {
    final item = _items[stockId];
    if (item == null) return;
    if (item.quantity < maxQuantity) {
      item.quantity += 1;
      notifyListeners();
    }
  }

  void decrease(String stockId) {
    final item = _items[stockId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(stockId);
    } else {
      item.quantity -= 1;
    }
    notifyListeners();
  }

  void remove(String stockId) {
    _items.remove(stockId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
