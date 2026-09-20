class ShopListing {
  final String stockId;
  final String productType;
  final int quantity;
  final String partnerId;
  final String partnerName;
  final String partnerAddress;
  final double price;
  final String description;
  final String detailsHtml;
  final bool weightRequired;
  final String imageAsset;
  final String featureImageUrl;
  final List<String> imageUrls;

  const ShopListing({
    required this.stockId,
    required this.productType,
    required this.quantity,
    required this.partnerId,
    required this.partnerName,
    required this.partnerAddress,
    required this.price,
    required this.description,
    this.detailsHtml = '',
    required this.weightRequired,
    required this.imageAsset,
    this.featureImageUrl = '',
    this.imageUrls = const [],
  });

  bool get isAvailable => quantity > 0;

  String get unitLabel => weightRequired ? 'kg' : 'pack';

  String get displayHtml {
    if (detailsHtml.trim().isNotEmpty) return detailsHtml;
    return description;
  }

  List<String> get galleryUrls {
    final urls = <String>[];
    final feature = featureImageUrl.trim();
    if (feature.isNotEmpty) urls.add(feature);
    for (final url in imageUrls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !urls.contains(trimmed)) {
        urls.add(trimmed);
      }
    }
    return urls;
  }
}
