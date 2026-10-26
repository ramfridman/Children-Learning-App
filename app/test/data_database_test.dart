import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/encrypted_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'support/fakes.dart';

const String secretName = 'שִׁירָה-בְּדִיקָה-9137';

bool _contains(Uint8List haystack, List<int> needle) {
  for (int i = 0; i + needle.length <= haystack.length; i++) {
    int j = 0;
    while (j < needle.length && haystack[i + j] == needle[j]) {
      j++;
    }
    if (j == needle.length) return true;
  }
  return false;
}

Future<void> _putProfile(AppDatabase db, {String name = secretName}) => db.addProfile(
  ProfilesCompanion.insert(
    id: 'p1',
    name: name,
    avatar: 'avatar-noa',
    addressForm: 'f',
    ageBand: 1,
    createdAt: DateTime.utc(2026, 10, 26),
  ),
);

void main() {
  late Directory dir;
  late MemoryStore store;
  late DatabaseKeyService keys;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nz_db_');
    store = MemoryStore();
    keys = DatabaseKeyService(store);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('the key', () {
    test('is 256 bits, made once, and reused', () async {
      final String a = await keys.keyHex();
      expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await keys.keyHex(), a);
      expect(await DatabaseKeyService(store).keyHex(), a);
    });

    test('differs between installs and is replaced after "forget this phone"', () async {
      final String a = await keys.keyHex();
      expect(await DatabaseKeyService(MemoryStore()).keyHex(), isNot(a));
      await keys.forget();
      expect(await keys.keyHex(), isNot(a));
    });

    test('a damaged stored key is not used', () async {
      await store.write(DatabaseKeyService.storeKey, 'not-a-key');
      expect(await keys.keyHex(), matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('the database', () {
    test('the SQLite build in use has a cipher', () {
      final sql.Database mem = sql.sqlite3.openInMemory();
      addTearDown(mem.close);
      expect(mem.select('PRAGMA cipher'), isNotEmpty);
    });

    test('stores and returns profiles, settings and events', () async {
      final AppDatabase db = openAppDatabase(folder: dir.path, keyHex: await keys.keyHex());
      addTearDown(db.close);
      await _putProfile(db);
      await db.putSetting('voice', 'off');
      await db.putSetting('voice', 'on');
      await db.recordEvent('pin_wrong', DateTime.utc(2026, 10, 26, 8), detail: 'n=1');

      final List<Profile> profiles = await db.allProfiles();
      expect(profiles.single.name, secretName);
      expect(profiles.single.ageBand, 1);
      expect(await db.setting('voice'), 'on');
      expect(await db.setting('missing'), isNull);
      expect((await db.recentEvents()).single.kind, 'pin_wrong');
    });

    test('rejects a profile with an age band outside 0 to 2', () async {
      final AppDatabase db = openAppDatabase(folder: dir.path, keyHex: await keys.keyHex());
      addTearDown(db.close);
      await expectLater(
        db.addProfile(
          ProfilesCompanion(
            id: const Value<String>('x'),
            name: const Value<String>('x'),
            avatar: const Value<String>('a'),
            addressForm: const Value<String>('n'),
            ageBand: const Value<int>(3),
            createdAt: Value<DateTime>(DateTime.utc(2026)),
          ),
        ),
        throwsA(anything),
      );
    });

    test('the schema version in the file matches the code', () async {
      final AppDatabase db = openAppDatabase(folder: dir.path, keyHex: await keys.keyHex());
      await db.allProfiles();
      final List<Map<String, Object?>> rows = (await db.customSelect('PRAGMA user_version').get())
          .map((r) => r.data)
          .toList();
      await db.close();
      expect(rows.single['user_version'], AppDatabase.currentSchemaVersion);
    });
  });

  group('the database file cannot be opened without the key', () {
    late String keyHex;
    late File file;

    setUp(() async {
      keyHex = await keys.keyHex();
      final AppDatabase db = openAppDatabase(folder: dir.path, keyHex: keyHex);
      await _putProfile(db);
      await db.close();
      file = databaseFile(dir.path);
    });

    test('the file does not start with the SQLite header and holds no readable name', () {
      final Uint8List bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
      expect(_contains(bytes, secretName.codeUnits), isFalse);
      expect(
        _contains(bytes, secretName.runes.expand((int r) => String.fromCharCode(r).codeUnits).toList()),
        isFalse,
      );
      expect(_contains(bytes, 'CREATE TABLE'.codeUnits), isFalse);
      expect(_contains(bytes, 'profiles'.codeUnits), isFalse);
    });

    test('plain SQLite, with no key, gets "not a database"', () {
      final sql.Database plain = sql.sqlite3.open(file.path);
      addTearDown(plain.close);
      expect(() => plain.select('SELECT count(*) FROM sqlite_master'), throwsA(isA<sql.SqliteException>()));
    });

    test('a wrong key gets the same refusal', () {
      final sql.Database wrong = sql.sqlite3.open(file.path);
      addTearDown(wrong.close);
      applyKey(wrong, '${'0' * 63}1');
      expect(() => wrong.select('SELECT count(*) FROM sqlite_master'), throwsA(isA<sql.SqliteException>()));
    });

    test('the right key reads the row', () {
      final sql.Database right = sql.sqlite3.open(file.path);
      addTearDown(right.close);
      applyKey(right, keyHex);
      expect(right.select('SELECT name FROM profiles').single['name'], secretName);
    });

    test('the key is not written anywhere on disk', () {
      final List<int> needle = keyHex.codeUnits;
      for (final FileSystemEntity f in dir.listSync(recursive: true).whereType<File>()) {
        expect(_contains((f as File).readAsBytesSync(), needle), isFalse, reason: f.path);
      }
    });
  });

  test('"forget this phone" removes the key and the files, and a new database starts empty', () async {
    final String oldKey = await keys.keyHex();
    final AppDatabase db = openAppDatabase(folder: dir.path, keyHex: oldKey);
    await _putProfile(db);
    await db.close();
    expect(databaseFile(dir.path).existsSync(), isTrue);

    await wipeLocalData(folder: dir.path, keys: keys);

    expect(databaseFile(dir.path).existsSync(), isFalse);
    expect(await store.read(DatabaseKeyService.storeKey), isNull);
    final AppDatabase fresh = openAppDatabase(folder: dir.path, keyHex: await keys.keyHex());
    addTearDown(fresh.close);
    expect(await fresh.allProfiles(), isEmpty);
    expect(await keys.keyHex(), isNot(oldKey));
  });
}
