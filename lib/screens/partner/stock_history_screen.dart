import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';

class StockHistoryScreen extends StatefulWidget {
  static const routeName = '/StockHistory';
  final String partnerId;

  const StockHistoryScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<StockProvider>(context, listen: false)
          .fetchStockHistory(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final historyByYear = stockProvider.getStockHistoryByYear(widget.partnerId);
    final Color color = Utils(context).color;

    final years = historyByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Stock History',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: years.isEmpty
          ? Center(
              child: TextWidget(
                text: 'No stock history recorded',
                color: Colors.grey,
                textSize: 16,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final entries = historyByYear[year]!;
                final totalUnits =
                    entries.fold<int>(0, (sum, entry) => sum + entry.quantity);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ExpansionTile(
                    title: TextWidget(
                      text: '$year',
                      color: color,
                      textSize: 18,
                      isTitle: true,
                    ),
                    subtitle: TextWidget(
                      text: '$totalUnits units received',
                      color: color,
                      textSize: 14,
                    ),
                    children: entries.map((entry) {
                      return ListTile(
                        title: TextWidget(
                          text: entry.productType,
                          color: color,
                          textSize: 16,
                        ),
                        subtitle: TextWidget(
                          text: entry.allocatedDate
                              .toDate()
                              .toString()
                              .split(' ')[0],
                          color: color,
                          textSize: 14,
                        ),
                        trailing: TextWidget(
                          text: '${entry.quantity} units',
                          color: color,
                          textSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
