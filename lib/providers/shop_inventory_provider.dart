import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/partners_model.dart';
import '../models/shop_listing.dart';
import '../models/stock_model.dart';
import '../models/stock_type_model.dart';

/// Live shop catalogue driven by partner deliveries (`stock`),
/// not a separate product catalogue.
class ShopInventoryProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ShopListing> _listings = [];
  List<PartnerModel> _partners = [];
  Map<String, StockTypeModel> _stockTypesByName = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _stockSub;
  String? _selectedPartnerId;
  bool _isLoading = false;
  String? _error;

  List<ShopListing> get listings {
    if (_selectedPartnerId == null) {
      return _listings.where((item) => item.isAvailable).toList();
    }
    return _listings
        .where((item) =>
            item.isAvailable && item.partnerId == _selectedPartnerId)
        .toList();
  }

  List<PartnerModel> get partnersWithStock {
    final ids = listings.map((item) => item.partnerId).toSet();
    return _partners.where((partner) => ids.contains(partner.partnerId)).toList();
  }

  String? get selectedPartnerId => _selectedPartnerId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> start() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadLookups();
      await _stockSub?.cancel();
      _stockSub = _db.collection('stock').snapshots().listen(
        _onStockSnapshot,
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLookups() async {
    final partnersSnap = await _db.collection('partners').get();
    _partners = partnersSnap.docs
        .map(PartnerModel.fromFirestore)
        .where((partner) => partner.enabled)
        .toList();

    final typesSnap = await _db.collection('stock_types').get();
    _stockTypesByName = {};
    for (final doc in typesSnap.docs) {
      final type = StockTypeModel.fromFirestore(doc);
      _stockTypesByName[type.name.trim().toLowerCase()] = type;
      _stockTypesByName[doc.id.trim().toLowerCase()] = type;
    }
  }

  void _onStockSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final next = <ShopListing>[];
    for (final doc in snapshot.docs) {
      try {
        final stock = StockModel.fromFirestore(doc);
        if (stock.quantity <= 0) continue;

        PartnerModel? partner;
        for (final item in _partners) {
          if (item.partnerId == stock.partnerId) {
            partner = item;
            break;
          }
        }
        if (partner == null) continue;

        final typeKey = stock.productType.trim().toLowerCase();
        final stockType = _stockTypesByName[typeKey];
        next.add(
          ShopListing(
            stockId: stock.id,
            productType: stock.productType,
            quantity: stock.quantity,
            partnerId: stock.partnerId,
            partnerName: partner.partnerName,
            partnerAddress: _formatAddress(partner),
            price: stockType?.price ?? 0,
            description: stockType?.description ??
                'Fresh ${stock.productType} delivered to ${partner.partnerName}.',
            weightRequired: stockType?.weightRequired ?? false,
            imageAsset: _imageForProduct(stock.productType),
          ),
        );
      } catch (error) {
        debugPrint('Skipping stock ${doc.id}: $error');
      }
    }
    next.sort((a, b) => a.productType.compareTo(b.productType));
    _listings = next;
    _error = null;
    notifyListeners();
  }

  void selectPartner(String? partnerId) {
    _selectedPartnerId = partnerId;
    notifyListeners();
  }

  ShopListing? findByStockId(String stockId) {
    try {
      return _listings.firstWhere((item) => item.stockId == stockId);
    } catch (_) {
      return null;
    }
  }

  String _formatAddress(PartnerModel partner) {
    final parts = [
      partner.address1,
      partner.city,
      partner.postcode,
    ].where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty) return partner.addresscode;
    return parts.join(', ');
  }

  String _imageForProduct(String productType) {
    final name = productType.toLowerCase();
    if (name.contains('biltong')) return 'assets/images/cat/biltong.png';
    if (name.contains('meat') || name.contains('steak') || name.contains('braai')) {
      return 'assets/images/cat/meat.png';
    }
    return 'assets/images/cat/accessories.png';
  }

  @override
  void dispose() {
    _stockSub?.cancel();
    super.dispose();
  }
}
