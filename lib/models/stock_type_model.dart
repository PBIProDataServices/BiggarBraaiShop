import 'package:cloud_firestore/cloud_firestore.dart';

class StockTypeModel {
  final String id;
  final String name;
  final String description;
  final bool weightRequired;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.weightRequired,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockTypeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      weightRequired: data['weightRequired'] ?? false,
      price: (data['price'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'weightRequired': weightRequired,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 