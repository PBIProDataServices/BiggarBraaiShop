import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_type_model.dart';

class StockTypeProvider with ChangeNotifier {
  final Map<String, StockTypeModel> _stockTypes = {};

  Map<String, StockTypeModel> get getStockTypes {
    return _stockTypes;
  }

  Future<void> fetchStockTypes() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('stock_types').get();

      _stockTypes.clear();

      for (var doc in querySnapshot.docs) {
        _stockTypes.putIfAbsent(
          doc.id,
          () => StockTypeModel.fromFirestore(doc),
        );
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching stock types: $error');
      rethrow;
    }
  }

  Future<void> addStockType({
    required String name,
    required String description,
    required bool weightRequired,
    required double price,
    String detailsHtml = '',
    String featureImageUrl = '',
    List<String> imageUrls = const [],
  }) async {
    try {
      final now = DateTime.now();
      final stockType = StockTypeModel(
        id: '',
        name: name,
        description: description,
        detailsHtml: detailsHtml,
        weightRequired: weightRequired,
        price: price,
        featureImageUrl: featureImageUrl,
        imageUrls: imageUrls,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('stock_types')
          .add(stockType.toMap());

      _stockTypes[docRef.id] = StockTypeModel(
        id: docRef.id,
        name: name,
        description: description,
        detailsHtml: detailsHtml,
        weightRequired: weightRequired,
        price: price,
        featureImageUrl: featureImageUrl,
        imageUrls: imageUrls,
        createdAt: now,
        updatedAt: now,
      );
      notifyListeners();
    } catch (error) {
      debugPrint('Error adding stock type: $error');
      rethrow;
    }
  }

  Future<void> deleteStockType(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('stock_types')
          .doc(id)
          .delete();

      _stockTypes.remove(id);
      notifyListeners();
    } catch (error) {
      debugPrint('Error deleting stock type: $error');
      rethrow;
    }
  }

  Future<void> updateStockType({
    required String id,
    required String name,
    required String description,
    required bool weightRequired,
    required double price,
    String? detailsHtml,
    String? featureImageUrl,
    List<String>? imageUrls,
  }) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final existing = _stockTypes[id];
      final nextDetails = detailsHtml ?? existing?.detailsHtml ?? '';
      final nextFeature = featureImageUrl ?? existing?.featureImageUrl ?? '';
      final nextImages = imageUrls ?? existing?.imageUrls ?? const [];
      await FirebaseFirestore.instance
          .collection('stock_types')
          .doc(id)
          .update({
            'name': name,
            'description': description,
            'detailsHtml': nextDetails,
            'weightRequired': weightRequired,
            'price': price,
            'featureImageUrl': nextFeature,
            'imageUrls': nextImages,
            'updatedAt': now,
          });

      _stockTypes[id] = StockTypeModel(
        id: id,
        name: name,
        description: description,
        detailsHtml: nextDetails,
        weightRequired: weightRequired,
        price: price,
        featureImageUrl: nextFeature,
        imageUrls: nextImages,
        createdAt: existing?.createdAt ?? now.toDate(),
        updatedAt: now.toDate(),
      );

      notifyListeners();
    } catch (error) {
      debugPrint('Error updating stock type: $error');
      rethrow;
    }
  }
}
