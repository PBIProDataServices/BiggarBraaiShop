import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/orders_provider.dart';
import '../../services/utils.dart';
import '../../widgets/empty_screen.dart';
import '../../widgets/text_widget.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/Orders';
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrdersProvider>(context, listen: false).fetchMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final color = Utils(context).color;
    final orders = ordersProvider.orders;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Your orders',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: orders.isEmpty
          ? const EmptyScreen(
              imagePath: 'assets/images/history.png',
              title: 'No orders yet',
              subtitle: 'Guest and account orders show here after checkout.',
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final date = DateFormat.yMMMd().format(order.orderDate.toDate());
                return ListTile(
                  title: Text('Order ${order.orderId.substring(0, 8)}'),
                  subtitle: Text('$date  •  ${order.stage}'),
                  trailing: Text('£${order.totalPrice}'),
                );
              },
            ),
    );
  }
}
