import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/services/crypto_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:secure_vault/services/secure_storage_service.dart';
import 'package:secure_vault/services/db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final CryptoService _cryptoService;
  final SecureStorageService _storageService;

  SecretKey? _masterKey;
  bool get isAuthenticated => _masterKey != null;
  bool wasAutoLocked = false;

  AuthService(this._cryptoService, this._storageService);

  Future<bool> hasAccount() async {
    return await _storageService.hasMasterSalt();
  }

  Future<void> createMasterPassword(String password) async {
    final salt = await _cryptoService.generateSalt();
    final key = await _cryptoService.deriveKey(password, salt);

    final verifyHash = await _calculateVerifyHash(key);

    await _storageService.saveMasterSalt(base64Encode(salt));
    await _storageService.write('verify_hash', verifyHash);

    _masterKey = key;
  }

  Future<bool> login(String password) async {
    final saltStr = await _storageService.getMasterSalt();
    if (saltStr == null) return false;

    final salt = base64Decode(saltStr);
    final key = await _cryptoService.deriveKey(password, salt);

    if (await _checkVerifyHash(key)) {
      _masterKey = key;
      return true;
    }
    return false;
  }

  Future<String> _calculateVerifyHash(SecretKey key) async {
    final encrypted = await _cryptoService.encrypt('VALID', key);
    return jsonEncode({
      'iv': encrypted['iv'],
      'ciphertext': encrypted['ciphertext'],
      'tag': encrypted['tag'],
    });
  }

  Future<bool> _checkVerifyHash(SecretKey key) async {
    final storedHash = await _storageService.read('verify_hash');
    if (storedHash == null) return false;

    try {
      final map = jsonDecode(storedHash);
      final decrypted = await _cryptoService.decrypt(
        ciphertext: List<int>.from(map['ciphertext']),
        iv: List<int>.from(map['iv']),
        tag: List<int>.from(map['tag']),
        key: key,
      );
      return decrypted == 'VALID';
    } catch (e) {
      return false;
    }
  }

  Future<void> enablePin(String pin) async {
    if (_masterKey == null) throw Exception('Not authenticated');

    final pinSalt = await _cryptoService.generateSalt();
    final pinKey = await _cryptoService.deriveKey(pin, pinSalt);

    final masterKeyBytes = await _cryptoService.extractKeyBytes(_masterKey!);

    final masterKeyBase64 = base64Encode(masterKeyBytes);

    final encryptedMasterKey = await _cryptoService.encrypt(
      masterKeyBase64,
      pinKey,
    );

    await _storageService.write('pin_salt', base64Encode(pinSalt));
    await _storageService.write(
      'pin_wrapped_key',
      jsonEncode(encryptedMasterKey),
    );
  }

  Future<bool> loginWithPin(String pin) async {
    final pinSaltStr = await _storageService.read('pin_salt');
    final wrappedKeyStr = await _storageService.read('pin_wrapped_key');

    if (pinSaltStr == null || wrappedKeyStr == null) return false;

    final pinSalt = base64Decode(pinSaltStr);
    final pinKey = await _cryptoService.deriveKey(pin, pinSalt);

    try {
      final map = jsonDecode(wrappedKeyStr);
      final masterKeyBase64 = await _cryptoService.decrypt(
        ciphertext: List<int>.from(map['ciphertext']),
        iv: List<int>.from(map['iv']),
        tag: List<int>.from(map['tag']),
        key: pinKey,
      );

      final masterKeyBytes = base64Decode(masterKeyBase64);
      _masterKey = _cryptoService.importKey(masterKeyBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> enableBiometrics() async {
    if (_masterKey == null) throw Exception('Not authenticated');

    final masterKeyBytes = await _cryptoService.extractKeyBytes(_masterKey!);
    final masterKeyBase64 = base64Encode(masterKeyBytes);

    await _storageService.write('biometric_master_key', masterKeyBase64);
  }

  Future<bool> loginWithBiometrics() async {
    final localAuth = LocalAuthentication();
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) return false;

    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Por favor autentícate para acceder a la bóveda',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) return false;

      final masterKeyBase64 = await _storageService.read(
        'biometric_master_key',
      );
      if (masterKeyBase64 == null) return false;

      final masterKeyBytes = base64Decode(masterKeyBase64);
      _masterKey = _cryptoService.importKey(masterKeyBytes);
      return true;
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  Future<String?> getMasterSalt() async {
    return await _storageService.getMasterSalt();
  }

  SecretKey? get masterKey => _masterKey;

  Future<bool> hasPin() async {
    final salt = await _storageService.read('pin_salt');
    final key = await _storageService.read('pin_wrapped_key');
    return salt != null && key != null;
  }

  Future<void> disablePin() async {
    await _storageService.delete('pin_salt');
    await _storageService.delete('pin_wrapped_key');
  }

  Future<bool> hasBiometrics() async {
    final key = await _storageService.read('biometric_master_key');
    return key != null;
  }

  Future<void> disableBiometrics() async {
    await _storageService.delete('biometric_master_key');
  }

  void logout() {
    _masterKey = null;
  }

  Future<void> resetAllData() async {
    await _storageService.deleteAll();
    final dbService = DbService();
    await dbService.clearAllData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    logout();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(CryptoService(), SecureStorageService());
});
