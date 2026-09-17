import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? preferredPartnerId;
  final List<String> userRoles;
  final DateTime createdAt;
  final bool biometricsEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.preferredPartnerId,
    required this.userRoles,
    required this.createdAt,
    this.biometricsEnabled = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle userRoles that might be stored in different formats
    List<String> parseUserRoles(dynamic rolesData) {
      if (rolesData == null) return [];
      if (rolesData is List) {
        return rolesData.map((role) => role.toString()).toList();
      }
      if (rolesData is String) {
        return [rolesData];
      }
      return [];
    }

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      preferredPartnerId: data['preferredPartnerId'],
      userRoles: parseUserRoles(data['userRoles']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      biometricsEnabled: data['biometricsEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'preferredPartnerId': preferredPartnerId,
      'userRoles': userRoles,
      'createdAt': Timestamp.fromDate(createdAt),
      'biometricsEnabled': biometricsEnabled,
    };
  }

  bool get isAdmin => userRoles.contains('Admin');
  bool get isPartner => userRoles.contains('Partner');
} 