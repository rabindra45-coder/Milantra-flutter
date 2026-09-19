import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool isLocked = false;
  bool isPinConfigured = false;
  bool isBiometricEnabled = false;

  static const String _pinKey = 'milantra_app_pin';
  static const String _bioKey = 'milantra_biometric_enabled';

  Future<void> init() async {
    final pin = await _storage.read(key: _pinKey);
    isPinConfigured = pin != null && pin.isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    isBiometricEnabled = prefs.getBool(_bioKey) ?? false;

    if (isPinConfigured) {
      isLocked = true;
    }
    notifyListeners();
  }

  Future<bool> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    isPinConfigured = true;
    isLocked = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    if (storedPin == enteredPin) {
      isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> authenticateBiometrics() async {
    if (!isBiometricEnabled) return false;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Milantra',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (authenticated) {
        isLocked = false;
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  Future<void> setBiometrics(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bioKey, enabled);
    isBiometricEnabled = enabled;
    notifyListeners();
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    isPinConfigured = false;
    isLocked = false;
    notifyListeners();
  }
}
