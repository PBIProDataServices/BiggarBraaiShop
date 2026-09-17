import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockAlertModel {
  final String id;
  final String partnerId;
  final Timestamp alertDate;
  final List<String> lowStockProducts;

  StockAlertModel({
    required this.id,
    required this.partnerId,
    required this.alertDate,
    required this.lowStockProducts,
  });

  factory StockAlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockAlertModel(
      id: doc.id,
      partnerId: data['partnerId'] ?? '',
      alertDate: data['alertDate'] as Timestamp,
      lowStockProducts: List<String>.from(data['lowStockProducts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'alertDate': alertDate,
      'lowStockProducts': lowStockProducts,
    };
  }
}

class StockAlertsProvider with ChangeNotifier {
  Future<void> createStockAlert({
    required String partnerId,
    required List<String> lowStockProducts,
  }) async {
    try {
      final now = Timestamp.now();
      final stockAlert = StockAlertModel(
        id: '',
        partnerId: partnerId,
        alertDate: now,
        lowStockProducts: lowStockProducts,
      );

      await FirebaseFirestore.instance
          .collection('stock_alerts')
          .add(stockAlert.toMap());

      notifyListeners();
    } catch (error) {
      debugPrint('Error creating stock alert: $error');
      rethrow;
    }
  }
} 