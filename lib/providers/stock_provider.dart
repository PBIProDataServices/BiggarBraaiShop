import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_model.dart';
import '../models/stock_history_model.dart';
import '../consts/firebase_consts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'partner_provider.dart';

class StockProvider with ChangeNotifier {
  final Map<String, StockModel> _stock = {};
  final Map<String, StockHistoryModel> _stockHistory = {};
  final User? user = authInstance.currentUser;

  Map<String, StockModel> get getStock {
    return _stock;
  }

  // Get total stock by type and partner
  Map<String, double> getStockByTypeAndPartner(String stockType, String partnerId) {
    double totalQuantity = 0;

    final matchingStock = _stock.values.where((stock) => 
      stock.productType == stockType && 
      stock.partnerId == partnerId
    ).toList();

    for (var stock in matchingStock) {
      totalQuantity += stock.quantity.toDouble();
    }

    return {
      'quantity': totalQuantity,
    };
  }

  // Get all unique product types from current stock
  Set<String> get getAllStockTypes {
    return _stock.values.map((stock) => stock.productType).toSet();
  }

  // Get all partner IDs that have stock allocated
  Set<String> get getAllPartnerIds {
    return _stock.values.map((stock) => stock.partnerId).toSet();
  }

  Future<void> fetchAllStock() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('stock').get();

      _stock.clear();

      for (var doc in querySnapshot.docs) {
        _stock.putIfAbsent(
          doc.id,
          () => StockModel.fromFirestore(doc),
        );
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching all stock: $error');
      rethrow;
    }
  }

  Future<void> fetchPartnerStock(String partnerId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('stock')
              .where('partnerId', isEqualTo: partnerId)
              .get();

      // Clear all stock and only keep the current partner's stock
      _stock.clear();

      for (var doc in querySnapshot.docs) {
        _stock[doc.id] = StockModel.fromFirestore(doc);
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching partner stock: $error');
      rethrow;
    }
  }

  Future<void> allocateStock({
    required BuildContext context,
    required String batchId,
    required String productType,
    required int quantity,
    required String partnerId,
    required Timestamp allocatedDate,
    required Timestamp createdAt,
    required Timestamp updatedAt,
  }) async {
    try {
      if (user == null || !user!.emailVerified) {
        throw Exception('User must be authenticated and verified to allocate stock');
      }

      // Check for existing stock with the same product type and partner
      final existingStockQuery = await FirebaseFirestore.instance
          .collection('stock')
          .where('productType', isEqualTo: productType)
          .where('partnerId', isEqualTo: partnerId)
          .get();

      if (existingStockQuery.docs.isNotEmpty) {
        // Update existing stock
        final existingDoc = existingStockQuery.docs.first;
        final existingStock = StockModel.fromFirestore(existingDoc);
        
        final updatedStock = StockModel(
          id: existingDoc.id,
          batchId: batchId,
          productType: productType,
          quantity: existingStock.quantity + quantity,
          partnerId: partnerId,
          allocatedDate: allocatedDate,
          createdAt: existingStock.createdAt,
          updatedAt: updatedAt,
        );

        await existingDoc.reference.update(updatedStock.toMap());
        _stock[existingDoc.id] = updatedStock;
      } else {
        // Create new stock record
        final stockData = StockModel(
          id: '',
          batchId: batchId,
          productType: productType,
          quantity: quantity,
          partnerId: partnerId,
          allocatedDate: allocatedDate,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final docRef = await FirebaseFirestore.instance
            .collection('stock')
            .add(stockData.toMap());

        _stock[docRef.id] = stockData;
      }

      // Record this individual allocation event, since 'stock' only holds merged current totals.
      final historyData = StockHistoryModel(
        id: '',
        batchId: batchId,
        productType: productType,
        quantity: quantity,
        partnerId: partnerId,
        allocatedDate: allocatedDate,
        createdAt: createdAt,
      );
      final historyDocRef = await FirebaseFirestore.instance
          .collection('stock_history')
          .add(historyData.toMap());
      _stockHistory[historyDocRef.id] = historyData;

      // Update partner stock using PartnerProvider
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      await partnerProvider.updatePartnerStock(
        partnerId,
        productType,
        quantity.toDouble(),
        state: 'New',
      );
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error allocating stock: $error');
      rethrow;
    }
  }

  Future<void> fetchStockHistory(String partnerId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('stock_history')
              .where('partnerId', isEqualTo: partnerId)
              .get();

      _stockHistory.clear();

      for (var doc in querySnapshot.docs) {
        _stockHistory[doc.id] = StockHistoryModel.fromFirestore(doc);
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching stock history: $error');
      rethrow;
    }
  }

  List<StockHistoryModel> getHistoryForPartner(String partnerId) {
    return _stockHistory.values
        .where((entry) => entry.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.allocatedDate.compareTo(a.allocatedDate));
  }

  // Groups the partner's allocation history by year, each year's entries sorted newest-first.
  Map<int, List<StockHistoryModel>> getStockHistoryByYear(String partnerId) {
    final Map<int, List<StockHistoryModel>> historyByYear = {};

    for (var entry in getHistoryForPartner(partnerId)) {
      final year = entry.allocatedDate.toDate().year;
      historyByYear.putIfAbsent(year, () => []).add(entry);
    }

    return historyByYear;
  }

  List<StockModel> getStockAllocationsForType(String stockType, String partnerId) {
    return _stock.values
        .where((stock) => 
          stock.productType == stockType && 
          stock.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.allocatedDate.compareTo(a.allocatedDate));
  }

  List<StockModel> getStockAllocationsForPartner(String partnerId) {
    return _stock.values
        .where((stock) => stock.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.allocatedDate.compareTo(a.allocatedDate));
  }

  List<StockModel> getPartnerStock(String partnerId) {
    return _stock.values
        .where((stock) => stock.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.allocatedDate.compareTo(a.allocatedDate));
  }
} 