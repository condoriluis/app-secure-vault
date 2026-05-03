import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DbService {
  static const _dbName = 'vault.db';
  static const _dbVersion = 2;

  static const tableEntries = 'entries';
  static const tableMeta = 'meta';

  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<void> init({String? dbPath}) async {
    if (_db != null) return;

    final String path;
    if (dbPath != null) {
      path = dbPath;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _dbName);
    }

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableEntries ADD COLUMN deleted_at INTEGER',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEntries (
        id TEXT PRIMARY KEY,
        iv BLOB NOT NULL,
        ciphertext BLOB NOT NULL,
        tag BLOB NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMeta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> insertEntry(Map<String, dynamic> entry) async {
    await _db!.insert(
      tableEntries,
      entry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllEntries() async {
    return await _db!.query(tableEntries, orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getEntry(String id) async {
    final results = await _db!.query(
      tableEntries,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateEntry(Map<String, dynamic> entry) async {
    await _db!.update(
      tableEntries,
      entry,
      where: 'id = ?',
      whereArgs: [entry['id']],
    );
  }

  Future<void> deleteEntry(String id) async {
    await _db!.delete(tableEntries, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEntries(List<String> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await _db!.delete(
      tableEntries,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> bulkRestoreEntries() async {
    await _db?.update(
      tableEntries,
      {'deleted_at': null},
      where: 'deleted_at IS NOT NULL',
    );
  }

  Future<void> bulkPermanentDeleteDeleted() async {
    await _db?.delete(
      tableEntries,
      where: 'deleted_at IS NOT NULL',
    );
  }

  Future<void> clearAllData() async {
    await _db?.delete(tableEntries);
    await _db?.delete(tableMeta);
  }

  Future<void> clearAllEntries() async {
    await _db?.delete(tableEntries);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
