import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String username;
  final String stockType;
  final double weight;
  final int units;
  final double price;
  final String partnerId;
  final String salesChannel;
  final Timestamp saleDate;
  final Timestamp createdAt;

  SaleModel({
    required this.id,
    required this.username,
    required this.stockType,
    required this.weight,
    required this.units,
    required this.price,
    required this.partnerId,
    required this.salesChannel,
    required this.saleDate,
    required this.createdAt,
  });

  factory SaleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleModel(
      id: doc.id,
      username: data['username'] ?? '',
      stockType: data['stockType'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      units: data['units'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      partnerId: data['partnerId'] ?? '',
      salesChannel: data['salesChannel'] ?? 'Store',
      saleDate: data['saleDate'] as Timestamp,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'stockType': stockType,
      'weight': weight,
      'units': units,
      'price': price,
      'partnerId': partnerId,
      'salesChannel': salesChannel,
      'saleDate': saleDate,
      'createdAt': createdAt,
    };
  }
} 