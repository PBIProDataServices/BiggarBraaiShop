import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../consts/firebase_consts.dart';
import '../models/cart_item.dart';

class ShopOrder {
  final String orderId;
  final String userId;
  final String customerName;
  final String email;
  final String totalPrice;
  final String stage;
  final Timestamp orderDate;
  final List<dynamic> items;

  ShopOrder({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.email,
    required this.totalPrice,
    required this.stage,
    required this.orderDate,
    required this.items,
  });
}

class OrdersProvider with ChangeNotifier {
  List<ShopOrder> _orders = [];

  List<ShopOrder> get orders => _orders;

  Future<void> fetchMyOrders() async {
    final User? user = authInstance.currentUser;
    if (user == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();

    _orders = snapshot.docs.map((doc) {
      final data = doc.data();
      return ShopOrder(
        orderId: data['orderId']?.toString() ?? doc.id,
        userId: data['userId']?.toString() ?? '',
        customerName: data['userName']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        totalPrice: data['totalPrice']?.toString() ?? '0',
        stage: data['stage']?.toString() ?? 'Awaiting Confirmation',
        orderDate: data['orderDate'] as Timestamp? ?? Timestamp.now(),
        items: data['items'] as List<dynamic>? ?? const [],
      );
    }).toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    notifyListeners();
  }

  Future<String> placeOrder({
    required List<CartItem> items,
    required double total,
    required String name,
    required String email,
    required String phone,
    required String address,
    required bool isGuest,
  }) async {
    final user = authInstance.currentUser;
    if (user == null) {
      throw Exception('Please complete checkout again.');
    }
    if (items.isEmpty) {
      throw Exception('Your basket is empty.');
    }

    final orderId = const Uuid().v4();
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((transaction) async {
      final stockSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in items) {
        final ref = firestore.collection('stock').doc(item.stockId);
        final snap = await transaction.get(ref);
        if (!snap.exists) {
          throw Exception('${item.productType} is no longer available.');
        }
        final available = (snap.data()?['quantity'] ?? 0) as int;
        if (available < item.quantity) {
          throw Exception(
            'Only $available of ${item.productType} left at ${item.partnerName}.',
          );
        }
        stockSnaps.add(snap);
      }

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final snap = stockSnaps[i];
        final available = (snap.data()?['quantity'] ?? 0) as int;
        transaction.update(snap.reference, {
          'quantity': available - item.quantity,
          'updatedAt': Timestamp.now(),
        });
      }

      transaction.set(firestore.collection('orders').doc(orderId), {
        'orderId': orderId,
        'userId': user.uid,
        'userName': name,
        'email': email,
        'phone': phone,
        'address': address,
        'isGuest': isGuest,
        'channel': 'Shop',
        'totalPrice': total,
        'quantity': items.fold<int>(0, (sum, item) => sum + item.quantity),
        'awaiting': items.fold<int>(0, (sum, item) => sum + item.quantity),
        'delivered': 0,
        'canceled': 0,
        'refunded': 0,
        'stage': 'Awaiting Confirmation',
        'partnerId': items.first.partnerId,
        'productId': items.first.stockId,
        'imageUrl': items.first.imageUrl,
        'orderDate': Timestamp.now(),
        'items': items
            .map((item) => {
                  'stockId': item.stockId,
                  'productType': item.productType,
                  'partnerId': item.partnerId,
                  'partnerName': item.partnerName,
                  'quantity': item.quantity,
                  'price': item.unitPrice,
                })
            .toList(),
      });
    });

    for (final item in items) {
      await firestore.collection('sales').add({
        'username': name,
        'stockType': item.productType,
        'weight': 0,
        'units': item.quantity,
        'price': item.unitPrice,
        'partnerId': item.partnerId,
        'salesChannel': 'Shop',
        'saleDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'orderId': orderId,
      });
    }

    await fetchMyOrders();
    return orderId;
  }
}
