import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[Profiles, AppSettings, LocalEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump with every table change and add a step to [migration]; `test/data_database_test.dart`
  /// fails if this number and the migration code drift apart.
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      // Nothing to migrate yet: version 1 is the first schema.
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---- profiles ----

  Future<List<Profile>> allProfiles() => (select(
    profiles,
  )..orderBy(<OrderingTerm Function(Profiles)>[(Profiles t) => OrderingTerm.asc(t.createdAt)])).get();

  Future<void> addProfile(ProfilesCompanion profile) => into(profiles).insert(profile);

  Future<void> removeProfile(String id) => (delete(profiles)..where((Profiles t) => t.id.equals(id))).go();

  // ---- settings ----

  Future<String?> setting(String key) async {
    final AppSetting? row = await (select(
      appSettings,
    )..where((AppSettings t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> putSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  // ---- security events ----

  Future<void> recordEvent(String kind, DateTime at, {String detail = ''}) =>
      into(localEvents)
          .insert(LocalEventsCompanion.insert(at: at, kind: kind, detail: Value<String>(detail)));

  Future<List<LocalEvent>> recentEvents({int limit = 50}) =>
      (select(localEvents)
            ..orderBy(<OrderingTerm Function(LocalEvents)>[(LocalEvents t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .get();
}
