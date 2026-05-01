import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/services/crypto_service.dart';
import 'package:secure_vault/services/db_service.dart';

class VaultRepository {
  final DbService _dbService;
  final CryptoService _cryptoService;
  final AuthService _authService;

  VaultRepository(this._dbService, this._cryptoService, this._authService);

  Future<void> addEntry(VaultEntry entry) async {
    final key = _authService.masterKey;
    if (key == null) throw Exception('Locked');

    final payload = jsonEncode({
      'type': entry.type.name,
      'title': entry.title,
      'username': entry.username,
      'password': entry.password,
      'notes': entry.notes,
      'category': entry.category,
      'data': entry.data,
    });

    final encrypted = await _cryptoService.encrypt(payload, key);

    await _dbService.insertEntry({
      'id': entry.id,
      'iv': encrypted['iv'],
      'ciphertext': encrypted['ciphertext'],
      'tag': encrypted['tag'],
      'created_at': entry.createdAt.millisecondsSinceEpoch,
      'updated_at': entry.updatedAt.millisecondsSinceEpoch,
    });
  }

  Future<List<VaultEntry>> getAllEntries() async {
    final key = _authService.masterKey;
    if (key == null) throw Exception('Locked');

    final rows = await _dbService.getAllEntries();
    final entries = <VaultEntry>[];

    for (final row in rows) {
      try {
        final decryptedJson = await _cryptoService.decrypt(
          ciphertext: row['ciphertext'],
          iv: row['iv'],
          tag: row['tag'],
          key: key,
        );

        final data = jsonDecode(decryptedJson);

        entries.add(
          VaultEntry(
            id: row['id'],
            type: VaultType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => VaultType.login,
            ),
            title: data['title'] ?? 'Untitled',
            username: data['username'],
            password: data['password'],
            notes: data['notes'],
            category: data['category'],
            data: (data['data'] as Map<String, dynamic>?) ?? {},
            createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']),
          ),
        );
      } catch (e) {
        print('Failed to decrypt entry ${row['id']}: $e');
      }
    }
    return entries;
  }

  Future<void> updateEntry(VaultEntry entry) async {
    final key = _authService.masterKey;
    if (key == null) throw Exception('Locked');

    final payload = jsonEncode({
      'type': entry.type.name,
      'title': entry.title,
      'username': entry.username,
      'password': entry.password,
      'notes': entry.notes,
      'category': entry.category,
      'data': entry.data,
    });

    final encrypted = await _cryptoService.encrypt(payload, key);

    await _dbService.updateEntry({
      'id': entry.id,
      'iv': encrypted['iv'],
      'ciphertext': encrypted['ciphertext'],
      'tag': encrypted['tag'],
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteEntry(String id) async {
    await _dbService.deleteEntry(id);
  }

  Future<void> deleteEntries(List<String> ids) async {
    await _dbService.deleteEntries(ids);
  }

  Future<void> deleteAllEntries() async {
    await _dbService.clearAllEntries();
  }
}

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final db = DbService();
  final crypto = CryptoService();
  final auth = ref.watch(authServiceProvider);
  return VaultRepository(db, crypto, auth);
});
