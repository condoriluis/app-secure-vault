import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/repositories/vault_repository.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/services/crypto_service.dart';

class BackupService {
  final VaultRepository _vaultRepository;
  final AuthService _authService;
  final CryptoService _cryptoService;

  BackupService(this._vaultRepository, this._authService, this._cryptoService);

  Future<String> exportVault() async {
    final masterKey = _authService.masterKey;
    if (masterKey == null) {
      throw Exception("No hay sesión activa para exportar.");
    }

    final entries = await _vaultRepository.getAllEntries();

    final List<Map<String, dynamic>> entriesJson = entries
        .map((e) => e.toJson())
        .toList();
    final String jsonString = jsonEncode(entriesJson);

    final encryptedMap = await _cryptoService.encrypt(jsonString, masterKey);
    final currentSalt = await _authService.getMasterSalt();

    final backupData = {...encryptedMap, 'salt': currentSalt, 'version': 2};

    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final formattedDate =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final backupFile = File('${tempDir.path}/backup_$formattedDate.vault');

    await backupFile.writeAsString(jsonEncode(backupData));

    return backupFile.path;
  }

  Future<int> importVault(String filePath, {String? password}) async {
    SecretKey? activeKey = _authService.masterKey;
    if (activeKey == null) {
      throw Exception("No hay sesión activa para importar.");
    }

    final backupFile = File(filePath);
    if (!await backupFile.exists()) {
      throw Exception("El archivo de respaldo no existe.");
    }

    if (!filePath.endsWith('.vault') && !filePath.endsWith('.json')) {
      throw Exception(
        "Formato de archivo no soportado. Debe ser .vault o .json",
      );
    }

    String encryptedString;
    Map<String, dynamic> encryptedMap;

    try {
      encryptedString = await backupFile.readAsString();
      encryptedMap = jsonDecode(encryptedString);
    } catch (e) {
      throw Exception(
        "El archivo no tiene un formato de backup válido de Vault.",
      );
    }

    List<VaultEntry> importedEntries = [];

    if (encryptedMap.containsKey('entries') &&
        encryptedMap['entries'] is List) {
      final List<dynamic> entriesData = encryptedMap['entries'];
      final backupSalt = encryptedMap['salt'] as String?;
      final currentSalt = await _authService.getMasterSalt();

      if (backupSalt != null && backupSalt != currentSalt) {
        if (password == null) {
          throw Exception("SALT_INCOMPATIBLE");
        }
        // Derivamos la llave usando el salt del respaldo y el password proporcionado
        activeKey = await _cryptoService.deriveKey(
          password,
          base64Decode(backupSalt),
        );
      }

      for (final item in entriesData) {
        final row = item as Map<String, dynamic>;
        try {
          final decryptedJson = await _cryptoService.decrypt(
            ciphertext: List<int>.from(row['ciphertext']),
            iv: List<int>.from(row['iv']),
            tag: List<int>.from(row['tag']),
            key: activeKey,
          );

          final data = jsonDecode(decryptedJson);
          importedEntries.add(
            VaultEntry(
              id: row['id'],
              type: VaultType.values.firstWhere(
                (e) => e.name == data['type'],
                orElse: () => VaultType.login,
              ),
              title: data['title'] ?? 'Sin título',
              username: data['username'],
              password: data['password'],
              notes: data['notes'],
              category: data['category'],
              data: (data['data'] as Map<String, dynamic>?) ?? {},
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                row['created_at'] ??
                    row['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(
                row['updated_at'] ??
                    row['updatedAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
        } catch (e) {
          continue;
        }
      }
    } else if (encryptedMap.containsKey('ciphertext') &&
        encryptedMap.containsKey('iv') &&
        encryptedMap.containsKey('tag')) {
      final backupSalt = encryptedMap['salt'] as String?;
      final currentSalt = await _authService.getMasterSalt();

      if (backupSalt != null && backupSalt != currentSalt) {
        if (password == null) {
          throw Exception("SALT_INCOMPATIBLE");
        }
        activeKey = await _cryptoService.deriveKey(
          password,
          base64Decode(backupSalt),
        );
      }

      try {
        final String decryptedString = await _cryptoService.decrypt(
          ciphertext: List<int>.from(encryptedMap['ciphertext']),
          iv: List<int>.from(encryptedMap['iv']),
          tag: List<int>.from(encryptedMap['tag']),
          key: activeKey,
        );

        final List<dynamic> decodedJson = jsonDecode(decryptedString);
        importedEntries = decodedJson
            .map((e) => VaultEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('MAC check failed')) {
          throw Exception(
            "Clave Maestra incorrecta para este respaldo o configuración de seguridad incompatible.",
          );
        }
        throw Exception("Error al descifrar el respaldo: ${e.toString()}");
      }
    } else {
      throw Exception(
        "El archivo seleccionado no es un formato de backup reconocido por Vault.",
      );
    }

    try {
      final existingEntries = await _vaultRepository.getAllEntries();
      final existingIds = existingEntries.map((e) => e.id).toSet();

      int addedCount = 0;
      for (final entry in importedEntries) {
        if (!existingIds.contains(entry.id)) {
          await _vaultRepository.addEntry(entry);
          addedCount++;
        }
      }

      return addedCount;
    } catch (e) {
      throw Exception(
        "Error al guardar las entradas importadas: ${e.toString()}",
      );
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.read(vaultRepositoryProvider),
    ref.read(authServiceProvider),
    CryptoService(),
  );
});
