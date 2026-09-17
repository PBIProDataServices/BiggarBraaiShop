import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_model.dart';

class SaleProvider with ChangeNotifier {
  final Map<String, SaleModel> _sales = {};

  Map<String, SaleModel> get getSales => _sales;

  Map<String, double> getSalesByTypeAndPartner(String stockType, String partnerId) {
    double totalUnits = 0;
    double totalRevenue = 0;

    _sales.values.where((sale) => 
      sale.stockType == stockType && 
      sale.partnerId == partnerId
    ).forEach((sale) {
      totalUnits += sale.units.toDouble();
      totalRevenue += sale.price * sale.units;
    });

    return {
      'units': totalUnits,
      'revenue': totalRevenue,
    };
  }

  Future<void> fetchSales(String partnerId) async {
    try {
      // No orderBy here: avoids requiring a composite Firestore index (sorting is done client-side).
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('sales')
              .where('partnerId', isEqualTo: partnerId)
              .get();

      // Only replace this partner's entries so fetching one partner doesn't wipe out others already cached.
      _sales.removeWhere((_, sale) => sale.partnerId == partnerId);
      for (var doc in querySnapshot.docs) {
        _sales[doc.id] = SaleModel.fromFirestore(doc);
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching sales: $error');
      rethrow;
    }
  }

  Future<void> addSale({
    required String username,
    required String stockType,
    required double weight,
    required int units,
    required double price,
    required String partnerId,
    required String salesChannel,
  }) async {
    try {
      final now = Timestamp.now();
      final sale = SaleModel(
        id: '',
        username: username,
        stockType: stockType,
        weight: weight,
        units: units,
        price: price,
        partnerId: partnerId,
        salesChannel: salesChannel,
        saleDate: now,
        createdAt: now,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('sales')
          .add(sale.toMap());

      _sales[docRef.id] = sale;
      notifyListeners();
    } catch (error) {
      debugPrint('Error adding sale: $error');
      rethrow;
    }
  }

  List<SaleModel> getSalesForType(String stockType, String partnerId) {
    return _sales.values
        .where((sale) => 
          sale.stockType == stockType && 
          sale.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
  }

  List<SaleModel> getSalesForPartner(String partnerId) {
    return _sales.values
        .where((sale) => sale.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
  }

  double getTotalRevenue(String partnerId) {
    return _sales.values
        .where((sale) => sale.partnerId == partnerId)
        .fold(0.0, (sum, sale) => sum + (sale.price * sale.units));
  }

  double getStoreSalesRevenue(String partnerId) {
    return _sales.values
        .where((sale) => sale.partnerId == partnerId && sale.salesChannel == 'Store')
        .fold(0.0, (sum, sale) => sum + (sale.price * sale.units));
  }

  Stream<List<SaleModel>> getSalesForPartnerAndStock(String partnerId, String stockType) {
    // No orderBy here: avoids requiring a composite Firestore index (sorting is done client-side).
    return FirebaseFirestore.instance
        .collection('sales')
        .where('partnerId', isEqualTo: partnerId)
        .where('stockType', isEqualTo: stockType)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SaleModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.saleDate.compareTo(a.saleDate)));
  }
} 