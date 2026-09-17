import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // For web/simulator testing - enable reCAPTCHA verification
  static Future<void> enableWebRecaptcha() async {
    if (kIsWeb || kDebugMode) {
      // Enable reCAPTCHA for web and debug mode (including simulators)
      await _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: true,
      );
    }
  }

  // For testing on simulators - disable app verification
  static Future<void> enableTestMode() async {
    if (kDebugMode) {
      // Only for testing - allows phone auth without SMS on simulators
      await _auth.setSettings(
        appVerificationDisabledForTesting: true,
      );
    }
  }

  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    required Function(UserCredential) onVerificationCompleted,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      // Enable reCAPTCHA for better testing support
      if (kIsWeb || kDebugMode) {
        await enableWebRecaptcha();
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            // Auto-verification completed (Android only)
            final userCredential = await _auth.signInWithCredential(credential);
            onVerificationCompleted(userCredential);
          } catch (e) {
            onError('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'The phone number is invalid.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later.';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Phone authentication is not enabled.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }
          
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS code sent to $phoneNumber');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto-retrieval timeout for verification ID: $verificationId');
        },
        timeout: timeout,
      );
    } catch (e) {
      onError('Phone verification error: ${e.toString()}');
    }
  }

  static Future<UserCredential?> signInWithOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid OTP';
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The verification code is invalid.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'The verification ID is invalid.';
          break;
        case 'session-expired':
          errorMessage = 'The verification session has expired.';
          break;
        default:
          errorMessage = e.message ?? 'Invalid OTP';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Resend OTP with the resend token
  static Future<void> resendOTP({
    required String phoneNumber,
    required int resendToken,
    required BuildContext context,
    required Function(String verificationId, int? newResendToken) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Handle auto-verification if needed
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Resend failed');
        },
        codeSent: (String verificationId, int? newResendToken) {
          onCodeSent(verificationId, newResendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Resend error: ${e.toString()}');
    }
  }

  // For testing purposes - use predefined test phone numbers
  static bool isTestPhoneNumber(String phoneNumber) {
    final testNumbers = [
      '+1 650-555-3434',
      '+1 404-555-0111',
      '+1 404-555-0185',
    ];
    return testNumbers.contains(phoneNumber);
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
