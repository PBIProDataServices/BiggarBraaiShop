import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/shop_inventory_provider.dart';
import '../../services/utils.dart';
import '../../widgets/html_details_view.dart';
import '../../widgets/product_image.dart';
import '../../widgets/text_widget.dart';

class ListingDetailsScreen extends StatefulWidget {
  static const routeName = '/ListingDetails';
  const ListingDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final _qtyController = TextEditingController(text: '1');
  int _imageIndex = 0;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockId = ModalRoute.of(context)!.settings.arguments as String;
    final listing =
        Provider.of<ShopInventoryProvider>(context).findByStockId(stockId);
    final color = Utils(context).color;
    final cart = Provider.of<CartProvider>(context);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This delivery is no longer available.')),
      );
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;
    final gallery = listing.galleryUrls;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (gallery.isEmpty)
            ProductImage(
              imageUrl: listing.featureImageUrl,
              fallbackAsset: listing.imageAsset,
              height: 220,
              fit: BoxFit.contain,
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: gallery.length,
                    onPageChanged: (index) => setState(() => _imageIndex = index),
                    itemBuilder: (context, index) {
                      return ProductImage(
                        imageUrl: gallery[index],
                        fallbackAsset: listing.imageAsset,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                if (gallery.length > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < gallery.length; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _imageIndex
                                ? Theme.of(context).primaryColor
                                : color.withOpacity(0.25),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
          TextWidget(
            text: listing.productType,
            color: color,
            textSize: 26,
            isTitle: true,
          ),
          const SizedBox(height: 8),
          Text('From ${listing.partnerName}', style: TextStyle(color: color)),
          Text(listing.partnerAddress,
              style: TextStyle(color: color.withOpacity(0.85))),
          const SizedBox(height: 16),
          TextWidget(
            text: '£${listing.price.toStringAsFixed(2)} / ${listing.unitLabel}',
            color: Colors.green,
            textSize: 22,
            isTitle: true,
          ),
          Text(
            '${listing.quantity} available from this delivery',
            style: TextStyle(color: color),
          ),
          const SizedBox(height: 20),
          HtmlDetailsView(html: listing.displayHtml, color: color),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Quantity'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: listing.price <= 0
                ? null
                : () {
                    final safeQty = qty.clamp(1, listing.quantity);
                    cart.addListing(listing, quantity: safeQty);
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              'Add to basket  £${(listing.price * qty).toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    );
  }
}
