import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[Profiles, AppSettings, LocalEvents, InstalledPacks, Attempts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump with every table change and add a step to [migration]; `test/data_database_test.dart`
  /// fails if this number and the migration code drift apart.
  static const int currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      // 1 to 2 (M2): installed packs and the answers children gave.
      if (from < 2) {
        await m.createTable(installedPacks);
        await m.createTable(attempts);
      }
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

  // ---- installed content packs ----

  Future<InstalledPack?> installedPack(String id) =>
      (select(installedPacks)..where((InstalledPacks t) => t.id.equals(id))).getSingleOrNull();

  Future<List<InstalledPack>> allInstalledPacks() => select(installedPacks).get();

  Future<void> saveInstalledPack(InstalledPacksCompanion row) =>
      into(installedPacks).insertOnConflictUpdate(row);

  // ---- attempts ----

  Future<void> recordAttempt(AttemptsCompanion row) => into(attempts).insert(row);

  Future<List<Attempt>> attemptsOf(String profileId) =>
      (select(attempts)
            ..where((Attempts t) => t.profileId.equals(profileId))
            ..orderBy(<OrderingTerm Function(Attempts)>[(Attempts t) => OrderingTerm.asc(t.id)]))
          .get();

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
