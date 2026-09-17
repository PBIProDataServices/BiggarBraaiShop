import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../consts/firebase_consts.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _disposed = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isPartner => _currentUser?.isPartner ?? false;
  
  // Get current user's email address
  String? get currentUserEmail => _currentUser?.email;

  Future<void> fetchUserData() async {
    final User? user = authInstance.currentUser;
    if (user == null) {
      _currentUser = null;
      if (!_disposed) notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      if (!_disposed) notifyListeners();

      final DocumentSnapshot userDoc = 
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Auto-create user profile if it doesn't exist
        await _createUserProfile(user);
        // Fetch the newly created profile
        final newUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        _currentUser = UserModel.fromFirestore(newUserDoc);
      } else {
        _currentUser = UserModel.fromFirestore(userDoc);
      }
    } catch (error) {
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  // Private method to create a new user profile
  Future<void> _createUserProfile(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': user.displayName ?? 'User', // Use display name if available, otherwise default
        'email': user.email ?? '',
        'userRoles': ['user'], // Default role
        'createdAt': Timestamp.now(),
        'biometricsEnabled': false,
      });
      
      debugPrint('Created new user profile for ${user.email}');
    } catch (error) {
      debugPrint('Error creating user profile: $error');
      rethrow;
    }
  }

    // Public method to create user profile (for use after phone auth or other auth methods)
  Future<void> createUserProfileIfNeeded({
    String? name,
  }) async {
    final User? user = authInstance.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in');
    }

    try {
      // Check if user profile already exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user profile with provided data or defaults
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': name ?? user.displayName ?? 'User',
          'email': user.email ?? '',
          'userRoles': ['user'], // Default role
          'createdAt': Timestamp.now(),
          'biometricsEnabled': false,
        });
        
        debugPrint('Created new user profile for ${user.email}');
      } else {
        debugPrint('User profile already exists for ${user.email}');
      }
      
      // Refresh user data
      await fetchUserData();
    } catch (error) {
      debugPrint('Error in createUserProfileIfNeeded: $error');
      rethrow;
    }
  }

  Future<void> updateUserData({
    String? name,
    String? preferredPartnerId,
    bool? biometricsEnabled,
  }) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      if (!_disposed) notifyListeners();

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (preferredPartnerId != null) updates['preferredPartnerId'] = preferredPartnerId;
      if (biometricsEnabled != null) updates['biometricsEnabled'] = biometricsEnabled;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .update(updates);

      await fetchUserData(); // Refresh user data
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authInstance.signOut();
    _currentUser = null;
    if (!_disposed) notifyListeners();
  }

  /// Permanently deletes the user's account and all associated data
  /// This action cannot be undone
  Future<void> deleteUserAccount() async {
    final User? user = authInstance.currentUser;
    if (user == null || _currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    try {
      _isLoading = true;
      if (!_disposed) notifyListeners();

      // Step 1: Delete user document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Step 2: Delete any other user-related data (orders, preferences, etc.)
      // Add batch operations here if you have related collections
      final batch = FirebaseFirestore.instance.batch();
      
      // Example: Delete user orders if they exist
      // final ordersQuery = await FirebaseFirestore.instance
      //     .collection('orders')
      //     .where('userId', isEqualTo: user.uid)
      //     .get();
      // for (var doc in ordersQuery.docs) {
      //   batch.delete(doc.reference);
      // }
      
      // Commit any batch operations
      await batch.commit();

      // Step 3: Delete the Firebase Auth user account
      // This must be done LAST because once deleted, we lose access
      await user.delete();

      // Step 4: Clear local state
      _currentUser = null;
      if (!_disposed) notifyListeners();

    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (!_disposed) notifyListeners();
      
      if (e.code == 'requires-recent-login') {
        throw Exception('For security reasons, please log out and log back in before deleting your account.');
      } else {
        throw Exception('Failed to delete account: ${e.message}');
      }
    } catch (error) {
      _isLoading = false;
      if (!_disposed) notifyListeners();
      throw Exception('Failed to delete account: $error');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  // Get current user's email address asynchronously
  Future<String?> getCurrentUserEmail() async {
    // If we already have the user data, return it
    if (_currentUser != null) {
      return _currentUser!.email;
    }

    // Otherwise, fetch the user data first
    final User? user = authInstance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot userDoc = 
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['email'] as String?;
      }
      
      return null;
    } catch (error) {
      debugPrint('Error fetching user email: $error');
      return null;
    }
  }

  // Get user names by their IDs
  Future<Map<String, String>> getUserNamesByIds(List<String> userIds) async {
    final Map<String, String> userNames = {};
    
    if (userIds.isEmpty) return userNames;

    try {
      // Fetch user documents for all the user IDs
      for (String userId in userIds) {
        try {
          final DocumentSnapshot userDoc = 
              await FirebaseFirestore.instance.collection('users').doc(userId).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final name = (userData['name'] as String?)?.trim();
            final email = (userData['email'] as String?)?.trim();
            final resolved = (name != null && name.isNotEmpty)
                ? name
                : (email != null && email.isNotEmpty)
                    ? email
                    : 'Unknown User';
            userNames[userId] = resolved;
          } else {
            userNames[userId] = 'Deleted user';
          }
        } catch (error) {
          debugPrint('Error fetching user $userId: $error');
          userNames[userId] = 'Error loading user';
        }
      }
    } catch (error) {
      debugPrint('Error fetching user names: $error');
    }

    return userNames;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
} 