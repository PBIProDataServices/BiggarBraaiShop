import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payout_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';

class PayoutHistoryScreen extends StatefulWidget {
  final String partnerId;

  const PayoutHistoryScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<PayoutProvider>(context, listen: false)
          .fetchPayouts(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final payoutProvider = Provider.of<PayoutProvider>(context);
    final payouts = payoutProvider.getPayouts;
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Payout History',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: ListView.builder(
        itemCount: payouts.length,
        itemBuilder: (context, index) {
          final payout = payouts.values.elementAt(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: TextWidget(
                text: 'Payout #${payout.id}',
                color: color,
                textSize: 18,
              ),
              subtitle: TextWidget(
                text: 'Date: ${payout.datetime.toDate().toString().split(' ')[0]}',
                color: color,
                textSize: 16,
              ),
              trailing: TextWidget(
                text: '£${payout.amount.toStringAsFixed(2)}',
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