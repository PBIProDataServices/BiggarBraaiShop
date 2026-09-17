import 'package:cloud_firestore/cloud_firestore.dart';

// One immutable record per allocation transaction (unlike StockModel, which merges quantities).
class StockHistoryModel {
  final String id;
  final String batchId;
  final String productType;
  final int quantity;
  final String partnerId;
  final Timestamp allocatedDate;
  final Timestamp createdAt;

  StockHistoryModel({
    required this.id,
    required this.batchId,
    required this.productType,
    required this.quantity,
    required this.partnerId,
    required this.allocatedDate,
    required this.createdAt,
  });

  factory StockHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockHistoryModel(
      id: doc.id,
      batchId: data['batchId'] ?? '',
      productType: data['productType'] ?? '',
      quantity: data['quantity'] ?? 0,
      partnerId: data['partnerId'] ?? '',
      allocatedDate: (data['allocatedDate'] as Timestamp),
      createdAt: (data['createdAt'] as Timestamp),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'productType': productType,
      'quantity': quantity,
      'partnerId': partnerId,
      'allocatedDate': allocatedDate,
      'createdAt': createdAt,
    };
  }
}
