import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  static const int _saltLength = 16;
  static const _keyLength = 32; // 256 bits
  static const _iterations = 100000; // PBKDF2 iterations

  final _algorithm = AesGcm.with256bits();
  final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: _keyLength * 8,
  );

  /// Generates a random salt of [_saltLength] bytes.
  Future<List<int>> generateSalt() async {
    final secretKey = SecretKeyData.random(length: _saltLength);
    return secretKey.bytes;
  }

  /// Derives a 256-bit key from [password] and [salt] using PBKDF2-HMAC-SHA256.
  Future<SecretKey> deriveKey(String password, List<int> salt) async {
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return secretKey;
  }

  /// Encrypts [plaintext] using [key].
  /// Returns a map containing 'iv', 'ciphertext', and 'tag'.
  Future<Map<String, List<int>>> encrypt(
    String plaintext,
    SecretKey key,
  ) async {
    final nonce = _algorithm.newNonce(); // Generates random IV
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    return {
      'iv': secretBox.nonce,
      'ciphertext': secretBox.cipherText,
      'tag': secretBox.mac.bytes,
    };
  }

  /// Decrypts [ciphertext] using [key], [iv], and [tag].
  /// Throws [SecretBoxAuthenticationError] if authentication fails.
  Future<String> decrypt({
    required List<int> ciphertext,
    required List<int> iv,
    required List<int> tag,
    required SecretKey key,
  }) async {
    final secretBox = SecretBox(ciphertext, nonce: iv, mac: Mac(tag));

    final clearTextBytes = await _algorithm.decrypt(secretBox, secretKey: key);

    return utf8.decode(clearTextBytes);
  }

  /// Helper to convert SecretKey to bytes (for storage if needed, though usually kept in memory)
  Future<List<int>> extractKeyBytes(SecretKey key) async {
    final data = await key.extract();
    return data.bytes;
  }

  /// Helper to restore SecretKey from bytes
  SecretKey importKey(List<int> bytes) {
    return SecretKey(bytes);
  }
}
