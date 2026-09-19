import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_listing.dart';
import '../providers/cart_provider.dart';
import '../screens/shop/listing_details_screen.dart';
import '../services/utils.dart';
import 'text_widget.dart';

class ShopListingCard extends StatelessWidget {
  const ShopListingCard({Key? key, required this.listing}) : super(key: key);

  final ShopListing listing;

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final cart = Provider.of<CartProvider>(context);
    final inCart = cart.items.containsKey(listing.stockId);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pushNamed(
            ListingDetailsScreen.routeName,
            arguments: listing.stockId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(listing.imageAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: listing.productType,
                color: color,
                textSize: 16,
                isTitle: true,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.storefront, size: 14, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      listing.partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color.withOpacity(0.85), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${listing.quantity} ${listing.unitLabel} in stock',
                style: TextStyle(color: Colors.green[700], fontSize: 12),
              ),
              const Spacer(),
              Row(
                children: [
                  TextWidget(
                    text: '£${listing.price.toStringAsFixed(2)}',
                    color: Colors.green,
                    textSize: 16,
                    isTitle: true,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: listing.price <= 0
                        ? null
                        : () {
                            cart.addListing(listing);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  inCart
                                      ? 'Updated basket'
                                      : 'Added ${listing.productType}',
                                ),
                              ),
                            );
                          },
                    icon: Icon(
                      inCart ? Icons.check_circle : Icons.add_shopping_cart,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
