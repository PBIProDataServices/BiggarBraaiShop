import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:biggar_braai_shop/models/partners_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class PartnerProvider with ChangeNotifier {
  static List<PartnerModel> _partners = [];
  PartnerModel? _currentPartner;
  bool _isLoading = false;

  List<PartnerModel> get getPartners => _partners;
  PartnerModel? get currentPartner => _currentPartner;
  bool get isLoading => _isLoading;

  Future<void> fetchPartners([BuildContext? context]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _partners = [];
        _currentPartner = null;
        return;
      }

      final query = FirebaseFirestore.instance.collection('partners');
      final snapshot = await query.get();
      
      _partners = snapshot.docs
          .map((doc) => PartnerModel.fromFirestore(doc))
          .where((partner) => partner.enabled)
          .toList();

      // If user is not admin, filter partners by userId or users array
      if (!_isUserAdmin(context)) {
        _partners = _partners.where((partner) => partner.canUserAccess(user.uid)).toList();
        
        // If there's only one partner, automatically select it
        if (_partners.length == 1) {
          _currentPartner = _partners.first;
        }
      }
    } catch (error) {
      debugPrint('Error fetching partners: $error');
      _partners = [];
      _currentPartner = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentPartner(PartnerModel partner) {
    _currentPartner = partner;
    notifyListeners();
  }

  bool _isUserAdmin([BuildContext? context]) {
    if (context != null) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        return userProvider.isAdmin;
      } catch (e) {
        // Fallback if context is not available or provider not found
        debugPrint('Error checking admin status: $e');
      }
    }
    
    // Fallback method - check user roles directly from Firestore
    // This is less efficient but works when context is not available
    return false;
  }

  void clearLocalPartnerslist() {
    _partners.clear();
    _currentPartner = null;
    notifyListeners();
  }
  
  Future<void> addPartner({
    required String partnerName,
    required String address1,
    required String address2,
    required String city,
    required String postcode,
    BuildContext? context,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String partnerId = DateTime.now().millisecondsSinceEpoch.toString();
      final partnerData = {
        'partnerId': partnerId,
        'userId': user.uid,
        'partnerName': partnerName,
        'address1': address1,
        'address2': address2,
        'city': city,
        'postCode': postcode,
        'addressCode': '$address1, $address2, $city, $postcode',
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'users': <String>[], // Initialize as empty list
        'pin': '0000', // Default pin
        'stocks': [],
      };

      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .set(partnerData);

      final newPartner = PartnerModel(
        partnerId: partnerId,
        userId: user.uid,
        partnerName: partnerName,
        address1: address1,
        address2: address2,
        city: city,
        postcode: postcode,
        addresscode: '$address1, $address2, $city, $postcode',
        enabled: true,
        users: [], // Initialize as empty list
        pin: '0000', // Default pin
        stocks: [],
      );

      _partners.insert(0, newPartner);
      
      // If this is the first partner for a non-admin user, set it as current
      if (context == null || !_isUserAdmin(context)) {
        if (_partners.length == 1) {
          _currentPartner = _partners.first;
        }
      }
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error adding partner: $error');
      rethrow;
    }
  }

  Future<void> updatePartner({
    required String partnerId,
    required String partnerName,
    required String address1,
    required String address2,
    required String city,
    required String postcode,
    required String pin,
    required List<String> users,
  }) async {
    try {
      final addressCode = '$address1, $address2, $city, $postcode';
      final partnerData = {
        'partnerName': partnerName,
        'address1': address1,
        'address2': address2,
        'city': city,
        'postCode': postcode,
        'addressCode': addressCode,
        'pin': pin,
        'users': users,
      };

      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .update(partnerData);

      // Update local partner list
      final partnerIndex = _partners.indexWhere((p) => p.partnerId == partnerId);
      if (partnerIndex != -1) {
        final existingPartner = _partners[partnerIndex];
        _partners[partnerIndex] = PartnerModel(
          partnerId: existingPartner.partnerId,
          userId: existingPartner.userId,
          partnerName: partnerName,
          address1: address1,
          address2: address2,
          city: city,
          postcode: postcode,
          addresscode: addressCode,
          enabled: existingPartner.enabled,
          defaultSalesChannel: existingPartner.defaultSalesChannel,
          users: users,
          pin: pin,
          stocks: existingPartner.stocks,
        );

        // Update current partner if it's the one being edited
        if (_currentPartner?.partnerId == partnerId) {
          _currentPartner = _partners[partnerIndex];
        }
      }
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error updating partner: $error');
      rethrow;
    }
  }

  Future<void> updatePartnerStock(
    String partnerId,
    String stockName,
    double amount, {
    String state = 'New',
    double? revenue,
  }) async {
    try {
      final partner = _partners.firstWhere((p) => p.partnerId == partnerId);
      final stockIndex = partner.stocks.indexWhere(
        (s) => s.stockName == stockName && s.state == state,
      );

      if (stockIndex == -1) {
        // If stock doesn't exist, create new entry
        partner.stocks.add(Stock(
          stockName: stockName,
          state: state,
          amount: amount,
          revenue: revenue ?? 0,
        ));
      } else {
        // Update existing stock
        partner.stocks[stockIndex] = Stock(
          stockName: stockName,
          state: state,
          amount: partner.stocks[stockIndex].amount + amount,
          revenue: partner.stocks[stockIndex].revenue + (revenue ?? 0),
        );
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .update({
        'stocks': partner.stocks.map((s) => s.toMap()).toList(),
      });

      notifyListeners();
    } catch (error) {
      debugPrint('Error updating partner stock: $error');
      rethrow;
    }
  }

  Future<void> updatePartnerStockState(String partnerId, String stockName, String newState) async {
    try {
      final partnerIndex = _partners.indexWhere((p) => p.partnerId == partnerId);
      if (partnerIndex == -1) throw Exception('Partner not found');

      final partner = _partners[partnerIndex];
      final stock = partner.getStockByName(stockName);
      if (stock == null) throw Exception('Stock not found');

      final updatedPartner = partner.updateStock(stockName, 0, state: newState);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .update({
        'stocks': updatedPartner.stocks.map((s) => s.toMap()).toList(),
      });

      // Update local state
      _partners[partnerIndex] = updatedPartner;
      if (_currentPartner?.partnerId == partnerId) {
        _currentPartner = updatedPartner;
      }

      notifyListeners();
    } catch (error) {
      debugPrint('Error updating partner stock state: $error');
      rethrow;
    }
  }

  // Add user to partner
  Future<void> addUserToPartner(String partnerId, String userId) async {
    try {
      final partnerIndex = _partners.indexWhere((p) => p.partnerId == partnerId);
      if (partnerIndex == -1) {
        throw Exception('Partner not found');
      }

      final partner = _partners[partnerIndex];
      
      // Check if user is already in the partner
      if (partner.users.contains(userId)) {
        throw Exception('User is already a member of this partner');
      }

      // Add user to the list
      final updatedUsers = [...partner.users, userId];

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .update({
        'users': updatedUsers,
      });

      // Update local state
      final updatedPartner = PartnerModel(
        partnerId: partner.partnerId,
        userId: partner.userId,
        partnerName: partner.partnerName,
        address1: partner.address1,
        address2: partner.address2,
        city: partner.city,
        postcode: partner.postcode,
        addresscode: partner.addresscode,
        enabled: partner.enabled,
        defaultSalesChannel: partner.defaultSalesChannel,
        users: updatedUsers,
        pin: partner.pin,
        stocks: partner.stocks,
      );

      _partners[partnerIndex] = updatedPartner;
      
      if (_currentPartner?.partnerId == partnerId) {
        _currentPartner = updatedPartner;
      }

      notifyListeners();
    } catch (error) {
      debugPrint('Error adding user to partner: $error');
      rethrow;
    }
  }
}
