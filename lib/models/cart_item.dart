import 'package:flutter/foundation.dart';

class CartItem with ChangeNotifier {
  final String stockId;
  final String productType;
  final String partnerId;
  final String partnerName;
  final double unitPrice;
  final bool weightRequired;
  final String imageAsset;
  int quantity;

  CartItem({
    required this.stockId,
    required this.productType,
    required this.partnerId,
    required this.partnerName,
    required this.unitPrice,
    required this.weightRequired,
    required this.imageAsset,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;
}
