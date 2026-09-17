import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/payout_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';
import 'add_sale_screen.dart';
import 'partner_dashboard_screen.dart';
import 'edit_partner_screen.dart';
import 'stock_history_screen.dart';

class PartnerStockScreen extends StatefulWidget {
  static const routeName = '/PartnerStock';
  final String partnerId;
  
  const PartnerStockScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<PartnerStockScreen> createState() => _PartnerStockScreenState();
}

class _PartnerStockScreenState extends State<PartnerStockScreen> {
  String _selectedPartnerId = '';

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = widget.partnerId;
    Future.delayed(Duration.zero, () {
      _loadDataForPartner(_selectedPartnerId);
    });
  }

  void _loadDataForPartner(String partnerId) {
    Provider.of<StockProvider>(context, listen: false)
        .fetchPartnerStock(partnerId);
    Provider.of<SaleProvider>(context, listen: false)
        .fetchSales(partnerId);
    Provider.of<PayoutProvider>(context, listen: false)
        .fetchPayouts(partnerId);
  }

  // Helper method to check if current user can edit this partner
  bool _canUserEditPartner() {
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final currentPartner = partnerProvider.getPartners
        .where((partner) => partner.partnerId == _selectedPartnerId)
        .firstOrNull;
    
    if (currentPartner == null) return false;
    
    return currentPartner.canUserAccess(user.uid);
  }

  Map<int, double> _getPayoutsByYear() {
    final payoutProvider = Provider.of<PayoutProvider>(context);
    final payouts = payoutProvider.getPayouts;
    
    Map<int, double> payoutsByYear = {};
    
    for (var payout in payouts.values) {
      final year = payout.datetime.toDate().year;
      payoutsByYear[year] = (payoutsByYear[year] ?? 0.0) + payout.amount;
    }
    
    return payoutsByYear;
  }

  Map<int, double> _getStoreSalesByYear() {
    final saleProvider = Provider.of<SaleProvider>(context);
    final sales = saleProvider.getSalesForPartner(_selectedPartnerId);
    
    Map<int, double> storeSalesByYear = {};
    
    for (var sale in sales) {
      if (sale.salesChannel == 'Store') {
        final year = sale.saleDate.toDate().year;
        storeSalesByYear[year] = (storeSalesByYear[year] ?? 0.0) + (sale.price * sale.units);
      }
    }
    
    return storeSalesByYear;
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context);
    final payoutProvider = Provider.of<PayoutProvider>(context);
    
    final stock = stockProvider.getStock;
    final totalSales = saleProvider.getTotalRevenue(_selectedPartnerId);
    final payoutsByYear = _getPayoutsByYear();
    final totalPayout = payoutProvider.getTotalPayouts();
    // Compute sales by year
    final salesByYear = <int, double>{};
    for (var sale in saleProvider.getSalesForPartner(_selectedPartnerId)) {
      final year = sale.saleDate.toDate().year;
      salesByYear[year] = (salesByYear[year] ?? 0.0) + (sale.price * sale.units);
    }
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'My Stock',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSaleScreen(
                    partnerId: _selectedPartnerId,
                  ),
                ),
              );
            },
            tooltip: 'Add Sale',
          ),
          // Settings button (only for users who can edit this partner)
          if (_canUserEditPartner())
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPartnerScreen(
                      partnerId: _selectedPartnerId,
                    ),
                  ),
                );
                
                // If partner was successfully updated, refresh the data
                if (result == true && mounted) {
                  final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
                  await partnerProvider.fetchPartners(context);
                }
              },
              tooltip: 'Partner Settings',
            ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartnerDashboardScreen(
                    partnerId: _selectedPartnerId,
                  ),
                ),
              );
            },
            tooltip: 'Go to Dashboard',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Current Stock',
                      color: color,
                      textSize: 20,
                      isTitle: true,
                    ),
                    const SizedBox(height: 12),
                    if (stock.isEmpty)
                      TextWidget(
                        text: 'No stock available',
                        color: Colors.grey,
                        textSize: 16,
                      )
                    else
                      ...stock.values.map((stockItem) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            TextWidget(
                              text: '• ${stockItem.productType}: ',
                              color: color,
                              textSize: 16,
                            ),
                            TextWidget(
                              text: '${stockItem.quantity} units',
                              color: color,
                              textSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      )).toList(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StockHistoryScreen(
                                partnerId: _selectedPartnerId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('View Stock History'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Total Sales and Total Payouts (side by side)
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Total Sales',
                            color: color,
                            textSize: 20,
                            isTitle: true,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: '£${totalSales.toStringAsFixed(2)}',
                            color: Colors.green,
                            textSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Total Payout',
                            color: color,
                            textSize: 20,
                            isTitle: true,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: '£${totalPayout.toStringAsFixed(2)}',
                            color: Colors.blue,
                            textSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total Sales by Year Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Total Sales by Year',
                      color: color,
                      textSize: 20,
                      isTitle: true,
                    ),
                    const SizedBox(height: 12),
                    if (salesByYear.isEmpty)
                      TextWidget(
                        text: 'No sales recorded',
                        color: Colors.grey,
                        textSize: 16,
                      )
                    else
                      ...(() {
                        final sortedSales = salesByYear.entries.toList()
                          ..sort((a, b) => b.key.compareTo(a.key));
                        return sortedSales.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              TextWidget(
                                text: '• ${entry.key}: ',
                                color: color,
                                textSize: 16,
                              ),
                              TextWidget(
                                text: '£${entry.value.toStringAsFixed(2)}',
                                color: Colors.green,
                                textSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        )).toList();
                      })(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Store Sales by Year
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Store Sales by Year',
                      color: color,
                      textSize: 20,
                      isTitle: true,
                    ),
                    const SizedBox(height: 12),
                    Consumer<SaleProvider>(
                      builder: (context, saleProvider, child) {
                        final storeSalesByYear = _getStoreSalesByYear();
                        
                        if (storeSalesByYear.isEmpty) {
                          return TextWidget(
                            text: 'No store sales recorded',
                            color: Colors.grey,
                            textSize: 16,
                          );
                        }
                        
                        final sortedStoreSales = storeSalesByYear.entries.toList()
                          ..sort((a, b) => b.key.compareTo(a.key));
                        
                        return Column(
                          children: sortedStoreSales.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                TextWidget(
                                  text: '• ${entry.key}: ',
                                  color: color,
                                  textSize: 16,
                                ),
                                TextWidget(
                                  text: '£${entry.value.toStringAsFixed(2)}',
                                  color: Colors.green,
                                  textSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payouts by Year Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Total Payouts by Year',
                      color: color,
                      textSize: 20,
                      isTitle: true,
                    ),
                    const SizedBox(height: 12),
                    if (payoutsByYear.isEmpty)
                      TextWidget(
                        text: 'No payouts recorded',
                        color: Colors.grey,
                        textSize: 16,
                      )
                    else
                      ...(() {
                        final sortedPayouts = payoutsByYear.entries.toList()
                          ..sort((a, b) => b.key.compareTo(a.key));
                        return sortedPayouts.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              TextWidget(
                                text: '• ${entry.key}: ',
                                color: color,
                                textSize: 16,
                              ),
                              TextWidget(
                                text: '£${entry.value.toStringAsFixed(2)}',
                                color: Colors.blue,
                                textSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        )).toList();
                      })(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Partner Selection Dropdown
            Consumer<PartnerProvider>(
              builder: (context, partnerProvider, child) {
                final availablePartners = partnerProvider.getPartners
                    .where((partner) => partner.canUserAccess(FirebaseAuth.instance.currentUser?.uid ?? ''))
                    .toList();
                
                if (availablePartners.length <= 1) {
                  return const SizedBox.shrink(); // Don't show dropdown if only one partner
                }
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'Select Partner',
                          color: color,
                          textSize: 20,
                          isTitle: true,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedPartnerId,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedPartnerId = newValue;
                              });
                              _loadDataForPartner(newValue);
                            }
                          },
                          items: availablePartners.map((partner) {
                            return DropdownMenuItem<String>(
                              value: partner.partnerId,
                              child: Text(partner.partnerName),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 