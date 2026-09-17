import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutModel {
  final String id;
  final String partnerId;
  final double amount;
  final Timestamp datetime;
  final String? note;

  PayoutModel({
    required this.id,
    required this.partnerId,
    required this.amount,
    required this.datetime,
    this.note,
  });

  factory PayoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutModel(
      id: doc.id,
      partnerId: data['partnerId'] as String,
      amount: (data['amount'] as num).toDouble(),
      datetime: data['datetime'] as Timestamp,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'amount': amount,
      'datetime': datetime,
      'note': note,
    };
  }
} 