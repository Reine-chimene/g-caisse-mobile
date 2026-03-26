import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'authentification biométrique (empreinte / Face ID)
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si la biométrie est disponible sur l'appareil
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Retourne les types de biométrie disponibles
  static Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authentifier l'utilisateur avec la biométrie
  static Future<bool> authenticate({
    String reason = 'Confirmez votre identité pour accéder à G-Caisse',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      return false;
    }
  }

  /// Sauvegarder la préférence biométrie activée
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  /// Lire la préférence biométrie
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  /// Sauvegarder les credentials pour la reconnexion biométrique
  static Future<void> saveCredentials(String phone, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio_phone', phone);
    await prefs.setString('bio_pin', pin);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('bio_phone');
    final pin   = prefs.getString('bio_pin');
    if (phone == null || pin == null) return null;
    return {'phone': phone, 'pin': pin};
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bio_phone');
    await prefs.remove('bio_pin');
    await prefs.remove('biometric_enabled');
  }
}
