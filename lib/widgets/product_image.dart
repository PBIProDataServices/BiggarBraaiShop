import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    Key? key,
    required this.imageUrl,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  final String imageUrl;
  final String fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: fit,
        width: width,
        height: height,
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }
}
