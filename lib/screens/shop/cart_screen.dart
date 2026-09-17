import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/shop_inventory_provider.dart';
import '../../services/utils.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/text_widget.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final inventory = Provider.of<ShopInventoryProvider>(context);
    final color = Utils(context).color;
    final items = cart.items.values.toList();

    if (items.isEmpty) {
      return const EmptyScreen(
        imagePath: 'assets/images/cart.png',
        title: 'Your basket is empty',
        subtitle: 'Add biltong when a partner has a delivery in stock.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Basket (${cart.itemCount})',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        actions: [
          IconButton(
            onPressed: cart.clear,
            icon: Icon(IconlyBroken.delete, color: color),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextWidget(
                    text: 'Total  £${cart.total.toStringAsFixed(2)}',
                    color: color,
                    textSize: 20,
                    isTitle: true,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(CheckoutScreen.routeName);
                  },
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final listing = inventory.findByStockId(item.stockId);
                final maxQty = listing?.quantity ?? item.quantity;
                return ListTile(
                  leading: Image.asset(item.imageAsset, width: 48),
                  title: Text(item.productType),
                  subtitle: Text(
                    '${item.partnerName}\n£${item.unitPrice.toStringAsFixed(2)} each',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => cart.decrease(item.stockId),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        onPressed: () => cart.increase(item.stockId, maxQty),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
