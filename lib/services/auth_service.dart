import 'package:firebase_auth/firebase_auth.dart';

import '../consts/firebase_consts.dart';

class AuthService {
  static bool isPigeonCastError(Object error) {
    final text = error.toString();
    return text.contains('PigeonUserDetails') ||
        text.contains('PigeonUserInfo');
  }

  static Future<User?> _waitForSignedInUser() async {
    for (var i = 0; i < 15; i++) {
      final user = authInstance.currentUser;
      if (user != null && !user.isAnonymous) return user;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return authInstance.currentUser;
  }

  static Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user ?? await _waitForSignedInUser();
      if (user == null || user.isAnonymous) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Sign in failed. Please check your email and password.',
        );
      }
      return user;
    } catch (error) {
      if (!isPigeonCastError(error)) rethrow;
      final user = await _waitForSignedInUser();
      if (user == null || user.isAnonymous) rethrow;
      return user;
    }
  }

  static Future<User> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user ?? await _waitForSignedInUser();
      if (user == null) {
        throw FirebaseAuthException(
          code: 'unknown',
          message: 'Could not create the account. Please try again.',
        );
      }
      return user;
    } catch (error) {
      if (!isPigeonCastError(error)) rethrow;
      final user = await _waitForSignedInUser();
      if (user == null) rethrow;
      return user;
    }
  }
}
