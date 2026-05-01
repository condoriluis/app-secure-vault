import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyMasterSalt = 'master_salt';

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveMasterSalt(String saltBase64) async {
    await write(_keyMasterSalt, saltBase64);
  }

  Future<String?> getMasterSalt() async {
    return await read(_keyMasterSalt);
  }

  Future<bool> hasMasterSalt() async {
    final salt = await getMasterSalt();
    return salt != null;
  }
}
