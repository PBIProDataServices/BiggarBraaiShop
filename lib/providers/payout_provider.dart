import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payout_model.dart';

class PayoutProvider with ChangeNotifier {
  final Map<String, PayoutModel> _payouts = {};
  bool _isLoading = false;

  Map<String, PayoutModel> get getPayouts => _payouts;
  bool get isLoading => _isLoading;

  Future<void> fetchPayouts(String partnerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('payouts')
              .where('partnerId', isEqualTo: partnerId)
              .get();

      _payouts.clear();
      for (var doc in querySnapshot.docs) {
        _payouts[doc.id] = PayoutModel.fromFirestore(doc);
      }
    } catch (error) {
      debugPrint('Error fetching payouts: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPayout({
    required String partnerId,
    required double amount,
    String? note,
  }) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection('payouts').add({
        'partnerId': partnerId,
        'amount': amount,
        'datetime': Timestamp.now(),
        'note': note,
      });

      // Refresh the payouts list
      await fetchPayouts(partnerId);
    } catch (error) {
      debugPrint('Error adding payout: $error');
      rethrow;
    }
  }

  double getTotalPayouts() {
    return _payouts.values.fold(0.0, (sum, payout) => sum + payout.amount);
  }
} 