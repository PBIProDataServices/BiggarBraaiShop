import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  static Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Get biometric types as readable strings
  static String getBiometricTypeString(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      default:
        return 'Biometric';
    }
  }

  /// Get all available biometric types as strings
  static Future<List<String>> getAvailableBiometricTypes() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.map((type) => getBiometricTypeString(type)).toList();
  }

  /// Check if biometric authentication is available and return a user-friendly message
  static Future<String> getBiometricStatusMessage() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return 'Biometric authentication is not available on this device';
      }
      
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return 'No biometric authentication methods are set up on this device';
      }
      
      final types = biometrics.map((type) => getBiometricTypeString(type)).join(', ');
      return 'Available: $types';
    } catch (e) {
      return 'Error checking biometric availability: $e';
    }
  }
} 