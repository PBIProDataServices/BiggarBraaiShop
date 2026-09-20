import 'package:cloud_firestore/cloud_firestore.dart';

String plainTextFromHtml(String html) {
  if (html.trim().isEmpty) return '';
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n+'), '\n')
      .trim();
}

class StockTypeModel {
  final String id;
  final String name;
  final String description;
  final String detailsHtml;
  final bool weightRequired;
  final double price;
  final String featureImageUrl;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockTypeModel({
    required this.id,
    required this.name,
    required this.description,
    this.detailsHtml = '',
    required this.weightRequired,
    required this.price,
    this.featureImageUrl = '',
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayHtml {
    if (detailsHtml.trim().isNotEmpty) return detailsHtml;
    return description;
  }

  String get summaryText {
    final text = plainTextFromHtml(displayHtml);
    if (text.isNotEmpty) return text;
    return description;
  }

  List<String> get galleryUrls {
    final urls = <String>[];
    final feature = featureImageUrl.trim();
    if (feature.isNotEmpty) urls.add(feature);
    for (final url in imageUrls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !urls.contains(trimmed)) {
        urls.add(trimmed);
      }
    }
    return urls;
  }

  factory StockTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockTypeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      detailsHtml: data['detailsHtml'] ?? '',
      weightRequired: data['weightRequired'] ?? false,
      price: _toDouble(data['price']),
      featureImageUrl: data['featureImageUrl'] ?? '',
      imageUrls: _toStringList(data['imageUrls']),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'detailsHtml': detailsHtml,
      'weightRequired': weightRequired,
      'price': price,
      'featureImageUrl': featureImageUrl,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
