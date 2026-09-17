import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shop_inventory_provider.dart';
import '../../services/utils.dart';
import '../../widgets/empty_products_widget.dart';
import '../../widgets/shop_listing_card.dart';
import '../../widgets/text_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<ShopInventoryProvider>(context);
    final color = Utils(context).color;
    final listings = inventory.listings;
    final partners = inventory.partnersWithStock;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Biggar Braai Shop',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: inventory.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: inventory.start,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Biltong and braai stock as soon as a partner receives a delivery.',
                    style: TextStyle(color: color.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 16),
                  if (partners.isNotEmpty)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Collect from',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: inventory.selectedPartnerId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All partners'),
                            ),
                            ...partners.map(
                              (partner) => DropdownMenuItem<String?>(
                                value: partner.partnerId,
                                child: Text(partner.partnerName),
                              ),
                            ),
                          ],
                          onChanged: inventory.selectPartner,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (listings.isEmpty)
                    const EmptyProdWidget(
                      text: 'No delivered stock is available yet. Check back when a partner receives a delivery.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listings.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return ShopListingCard(listing: listings[index]);
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
