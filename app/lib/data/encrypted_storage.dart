import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../device/secure_store.dart';
import 'app_database.dart';

/// The 256-bit key of the local database. It is made once, on first run, from the system's secure
/// random generator, and kept only in secure storage (Android Keystore). It is never written to a
/// file, a log or a backup.
class DatabaseKeyService {
  DatabaseKeyService(this._store, {Random? random}) : _random = random ?? Random.secure();

  static const String storeKey = 'local_db_key_v1';

  final SecureStore _store;
  final Random _random;

  /// The key as 64 hex characters, made on the first call.
  Future<String> keyHex() async {
    final String? existing = await _store.read(storeKey);
    if (existing != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(existing)) return existing;
    final String made = <String>[
      for (int i = 0; i < 32; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    await _store.write(storeKey, made);
    return made;
  }

  Future<void> forget() => _store.delete(storeKey);
}

class EncryptionUnavailable implements Exception {
  const EncryptionUnavailable();

  @override
  String toString() => 'EncryptionUnavailable: the SQLite build has no cipher; refusing to store data';
}

/// Applies the key to a raw connection. Fails closed: if the SQLite build in use has no cipher
/// (a plain SQLite would silently ignore `PRAGMA key`), nothing is stored.
void applyKey(sql.Database db, String keyHex) {
  final sql.ResultSet cipher = db.select('PRAGMA cipher');
  if (cipher.isEmpty) throw const EncryptionUnavailable();
  db.execute("PRAGMA key = \"x'$keyHex'\"");
}

const String databaseFileName = 'nitznutz_local.db';

File databaseFile(String folder) => File('$folder${Platform.pathSeparator}$databaseFileName');

/// Opens (or creates) the encrypted database in [folder].
AppDatabase openAppDatabase({required String folder, required String keyHex}) {
  return AppDatabase(NativeDatabase(databaseFile(folder), setup: (sql.Database db) => applyKey(db, keyHex)));
}

/// "Forget this phone": removes the key and every database file.
Future<void> wipeLocalData({required String folder, required DatabaseKeyService keys}) async {
  await keys.forget();
  final File main = databaseFile(folder);
  for (final String suffix in <String>['', '-wal', '-shm', '-journal']) {
    final File f = File('${main.path}$suffix');
    if (f.existsSync()) await f.delete();
  }
}
