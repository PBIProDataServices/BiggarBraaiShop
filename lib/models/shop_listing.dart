class ShopListing {
  final String stockId;
  final String productType;
  final int quantity;
  final String partnerId;
  final String partnerName;
  final String partnerAddress;
  final double price;
  final String description;
  final bool weightRequired;
  final String imageAsset;

  const ShopListing({
    required this.stockId,
    required this.productType,
    required this.quantity,
    required this.partnerId,
    required this.partnerName,
    required this.partnerAddress,
    required this.price,
    required this.description,
    required this.weightRequired,
    required this.imageAsset,
  });

  bool get isAvailable => quantity > 0;

  String get unitLabel => weightRequired ? 'kg' : 'pack';
}
