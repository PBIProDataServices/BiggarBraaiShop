import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class Stock {
  final String stockName;
  final String state;
  final double amount;
  final double revenue;

  Stock({
    required this.stockName,
    required this.state,
    required this.amount,
    this.revenue = 0.0,
  });

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      stockName: map['stockName'] ?? '',
      state: map['state'] ?? 'New',
      amount: (map['amount'] ?? 0.0).toDouble(),
      revenue: (map['revenue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stockName': stockName,
      'state': state,
      'amount': amount,
      'revenue': revenue,
    };
  }
}

class PartnerModel with ChangeNotifier {
  final String partnerId;
  final String userId;
  final String partnerName;
  final String address1;
  final String address2;
  final String city;
  final String postcode;
  final String addresscode;
  final bool enabled;
  final List<Stock> stocks;
  final String defaultSalesChannel;
  final List<String> users;
  final String pin;

  PartnerModel({
    required this.partnerId,
    required this.userId,
    required this.partnerName,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.addresscode,
    required this.enabled,
    this.stocks = const [],
    this.defaultSalesChannel = 'Store',
    this.users = const [],
    this.pin = '0000',
  });

  factory PartnerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerModel(
      partnerId: data['partnerId'] ?? '',
      userId: data['userId'] ?? '',
      partnerName: data['partnerName'] ?? '',
      address1: data['address1'] ?? '',
      address2: data['address2'] ?? '',
      city: data['city'] ?? '',
      postcode: data['postCode'] ?? '',
      addresscode: data['addressCode'] ?? '',
      enabled: data['enabled'] ?? true,
      defaultSalesChannel: data['defaultSalesChannel'] ?? 'Store',
      users: List<String>.from(data['users'] ?? []),
      pin: data['pin'] ?? '0000',
      stocks: (data['stocks'] as List<dynamic>? ?? [])
          .map((stock) => Stock.fromMap(stock as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'userId': userId,
      'partnerName': partnerName,
      'address1': address1,
      'address2': address2,
      'city': city,
      'postCode': postcode,
      'addressCode': addresscode,
      'enabled': enabled,
      'defaultSalesChannel': defaultSalesChannel,
      'users': users,
      'pin': pin,
      'stocks': stocks.map((stock) => stock.toMap()).toList(),
    };
  }

  // Helper method to update stock
  PartnerModel updateStock(String stockName, double amount, {String state = 'New', double revenue = 0.0}) {
    final existingStockIndex = stocks.indexWhere((s) => s.stockName == stockName);
    final List<Stock> updatedStocks = List.from(stocks);

    if (existingStockIndex >= 0) {
      final existingStock = stocks[existingStockIndex];
      updatedStocks[existingStockIndex] = Stock(
        stockName: stockName,
        state: state,
        amount: existingStock.amount + amount,
        revenue: existingStock.revenue + revenue,
      );
    } else {
      updatedStocks.add(Stock(
        stockName: stockName,
        state: state,
        amount: amount,
        revenue: revenue,
      ));
    }

    return PartnerModel(
      partnerId: partnerId,
      userId: userId,
      partnerName: partnerName,
      address1: address1,
      address2: address2,
      city: city,
      postcode: postcode,
      addresscode: addresscode,
      enabled: enabled,
      defaultSalesChannel: defaultSalesChannel,
      users: users,
      pin: pin,
      stocks: updatedStocks,
    );
  }

  // Helper method to check if a user can access this partner
  bool canUserAccess(String userId) {
    return this.userId == userId || users.contains(userId);
  }

  // Helper method to check if a user is the admin/owner of this partner
  bool isUserAdmin(String userId) {
    return this.userId == userId;
  }

  // Helper method to get stock by name
  Stock? getStockByName(String stockName) {
    return stocks.firstWhere(
      (stock) => stock.stockName == stockName,
      orElse: () => Stock(stockName: stockName, state: 'New', amount: 0, revenue: 0),
    );
  }

  // Helper method to get total stock by state
  double getTotalStockByState(String state) {
    return stocks
        .where((stock) => stock.state == state)
        .fold(0.0, (sum, stock) => sum + stock.amount);
  }

  // Helper method to get unique stock names
  List<String> get uniqueStockNames => stocks.map((s) => s.stockName).toSet().toList();

  // Helper method to get unique states
  List<String> get uniqueStates => stocks.map((s) => s.state).toSet().toList();
}
