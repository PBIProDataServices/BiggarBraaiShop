import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_alerts_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';

class StockAlertScreen extends StatefulWidget {
  final String partnerId;

  const StockAlertScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<StockAlertScreen> createState() => _StockAlertScreenState();
}

class _StockAlertScreenState extends State<StockAlertScreen> {
  final List<String> _selectedProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<StockProvider>(context, listen: false)
          .fetchPartnerStock(widget.partnerId);
    });
  }

  Future<void> _createStockAlert() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final stockAlertsProvider = Provider.of<StockAlertsProvider>(context, listen: false);
      
      await stockAlertsProvider.createStockAlert(
        partnerId: widget.partnerId,
        lowStockProducts: _selectedProducts,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock alert created successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating stock alert: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final stock = stockProvider.getStock;
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Create Stock Alert',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextWidget(
                    text: 'Select products that are running low on stock:',
                    color: color,
                    textSize: 16,
                  ),
                ),
                Expanded(
                  child: stock.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              TextWidget(
                                text: 'No stock available',
                                color: Colors.grey,
                                textSize: 18,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: stock.length,
                          itemBuilder: (context, index) {
                            final stockItem = stock.values.elementAt(index);
                            final isSelected = _selectedProducts.contains(stockItem.productType);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: CheckboxListTile(
                                title: TextWidget(
                                  text: stockItem.productType,
                                  color: color,
                                  textSize: 16,
                                ),
                                subtitle: TextWidget(
                                  text: 'Current stock: ${stockItem.quantity} units',
                                  color: color,
                                  textSize: 14,
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedProducts.add(stockItem.productType);
                                    } else {
                                      _selectedProducts.remove(stockItem.productType);
                                    }
                                  });
                                },
                                activeColor: Colors.red,
                              ),
                            );
                          },
                        ),
                ),
                if (stock.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedProducts.isEmpty ? null : _createStockAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const TextWidget(
                          text: 'Create Stock Alert',
                          color: Colors.white,
                          textSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
} 