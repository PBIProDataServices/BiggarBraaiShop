import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';

class SalesHistoryScreen extends StatefulWidget {
  final String partnerId;

  const SalesHistoryScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<SaleProvider>(context, listen: false)
          .fetchSales(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = Provider.of<SaleProvider>(context);
    final sales = saleProvider.getSalesForPartner(widget.partnerId);
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Sales History',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: ListView.builder(
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final sale = sales[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: TextWidget(
                text: sale.stockType,
                color: color,
                textSize: 18,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Units: ${sale.units}',
                    color: color,
                    textSize: 16,
                  ),
                  TextWidget(
                    text: 'Date: ${sale.saleDate.toDate().toString().split(' ')[0]} • ${sale.salesChannel} - ${sale.username}',
                    color: color,
                    textSize: 14,
                  ),
                ],
              ),
              trailing: TextWidget(
                text: '£${(sale.price * sale.units).toStringAsFixed(2)}',
                color: color,
                textSize: 18,
                isTitle: true,
              ),
            ),
          );
        },
      ),
    );
  }
} 