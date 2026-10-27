import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[Profiles, AppSettings, LocalEvents, InstalledPacks, Attempts, Sessions, VoiceListens],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump with every table change and add a step to [migration]; `test/data_database_test.dart`
  /// fails if this number and the migration code drift apart.
  static const int currentSchemaVersion = 5;

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
      // 2 to 3 (M3): sessions, and the session of each answer.
      if (from < 3) {
        await m.createTable(sessions);
        // A version 1 file just got `attempts` with the column already; only a version 2 file needs it added.
        if (from >= 2) await m.addColumn(attempts, attempts.sessionId);
      }
      // 3 to 4 (M4): the companion each child chose.
      if (from < 4) await m.addColumn(profiles, profiles.companionId);
      // 4 to 5 (M5): how an answer was given, and the record of mic listens.
      if (from < 5) {
        await m.createTable(voiceListens);
        // A file older than version 2 got `attempts` just now, with the column already.
        if (from >= 2) await m.addColumn(attempts, attempts.input);
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

  /// The companion the child chose, or null for the house character.
  Future<String?> companionOf(String profileId) async {
    final Profile? row = await (select(
      profiles,
    )..where((Profiles t) => t.id.equals(profileId))).getSingleOrNull();
    return row?.companionId;
  }

  Future<void> setCompanion(String profileId, String? characterId) =>
      (update(profiles)..where((Profiles t) => t.id.equals(profileId))).write(
        ProfilesCompanion(companionId: Value<String?>(characterId)),
      );

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

  // ---- sessions ----

  Future<int> startSession(String profileId, DateTime at, {String plan = ''}) =>
      into(sessions)
          .insert(SessionsCompanion.insert(profileId: profileId, startedAt: at, plan: Value<String>(plan)));

  Future<void> endSession(int id, DateTime at, String reason) =>
      (update(sessions)..where((Sessions t) => t.id.equals(id))).write(
        SessionsCompanion(endedAt: Value<DateTime>(at), endReason: Value<String>(reason)),
      );

  Future<List<Session>> sessionsOf(String profileId) =>
      (select(sessions)
            ..where((Sessions t) => t.profileId.equals(profileId))
            ..orderBy(<OrderingTerm Function(Sessions)>[(Sessions t) => OrderingTerm.asc(t.id)]))
          .get();

  // ---- attempts ----

  Future<void> recordAttempt(AttemptsCompanion row) => into(attempts).insert(row);

  Future<List<Attempt>> attemptsOf(String profileId) =>
      (select(attempts)
            ..where((Attempts t) => t.profileId.equals(profileId))
            ..orderBy(<OrderingTerm Function(Attempts)>[(Attempts t) => OrderingTerm.asc(t.id)]))
          .get();

  // ---- voice listens ----

  Future<void> recordListen(String profileId, DateTime at, String answerType, String outcome) =>
      into(voiceListens).insert(
        VoiceListensCompanion.insert(profileId: profileId, at: at, answerType: answerType, outcome: outcome),
      );

  /// Every child's newest listens, newest first (for the dev page, to see why the mic is or is not offered).
  Future<List<VoiceListen>> allListens({int limit = 30}) =>
      (select(voiceListens)
            ..orderBy(<OrderingTerm Function(VoiceListens)>[(VoiceListens t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .get();

  /// Forgets every listen, so the mic is offered again (for the dev page).
  Future<int> forgetListens() => delete(voiceListens).go();

  /// The newest listens of a child for one kind of answer, newest first.
  Future<List<VoiceListen>> recentListens(String profileId, String answerType, {int limit = 12}) =>
      (select(voiceListens)
            ..where((VoiceListens t) => t.profileId.equals(profileId) & t.answerType.equals(answerType))
            ..orderBy(<OrderingTerm Function(VoiceListens)>[(VoiceListens t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
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
