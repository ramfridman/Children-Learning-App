import 'package:drift/drift.dart';

import '../rewards/ribbons.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Profiles,
    AppSettings,
    LocalEvents,
    InstalledPacks,
    Attempts,
    Sessions,
    VoiceListens,
    Alerts,
    Rewards,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump with every table change and add a step to [migration]; `test/data_database_test.dart`
  /// fails if this number and the migration code drift apart.
  static const int currentSchemaVersion = 9;

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
      // 5 to 6 (M7): the alerts the parent is told about.
      if (from < 6) await m.createTable(alerts);
      // 6 to 7 (M7b): what has been sent to the family's other devices, and where an event came from.
      if (from < 7) {
        // A table made in this very upgrade (a file older than the table) already has the columns.
        if (from >= 2) {
          await m.addColumn(attempts, attempts.eventId);
          await m.addColumn(attempts, attempts.syncedAt);
          await m.addColumn(attempts, attempts.remoteSession);
        }
        if (from >= 3) {
          await m.addColumn(sessions, sessions.eventId);
          await m.addColumn(sessions, sessions.syncedAt);
          await m.addColumn(sessions, sessions.remoteKey);
        }
        if (from >= 6) await m.addColumn(alerts, alerts.syncedAt);
      }
      // 7 to 8 (M8): the stickers, golden stars and trophies a child has been given.
      if (from < 8) await m.createTable(rewards);
      // 8 to 9 (M8b): the prize the companion wears.
      if (from < 9) await m.addColumn(profiles, profiles.outfitId);
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

  /// The prize the companion wears (an outfit id), or null for none.
  Future<String?> outfitOf(String profileId) async {
    final Profile? row = await (select(
      profiles,
    )..where((Profiles t) => t.id.equals(profileId))).getSingleOrNull();
    return row?.outfitId;
  }

  Future<void> setOutfit(String profileId, String? outfitId) =>
      (update(profiles)..where((Profiles t) => t.id.equals(profileId))).write(
        ProfilesCompanion(outfitId: Value<String?>(outfitId)),
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

  // ---- alerts (M7) ----

  /// Saves an alert unless the same one (same key) is already there. True if it was new.
  Future<bool> addAlert(AlertsCompanion row) => transaction(() async {
    final String key = row.dedupeKey.value;
    final Alert? have = await (select(
      alerts,
    )..where(($AlertsTable t) => t.dedupeKey.equals(key))).getSingleOrNull();
    if (have != null) return false;
    await into(alerts).insert(row);
    return true;
  });

  /// Newest first.
  Future<List<Alert>> allAlerts() =>
      (select(alerts)..orderBy(<OrderClauseGenerator<$AlertsTable>>[(t) => OrderingTerm.desc(t.at)])).get();

  Future<int> unreadAlertCount() async {
    final Expression<int> n = alerts.id.count();
    final TypedResult r =
        await (selectOnly(alerts)
              ..addColumns(<Expression<Object>>[n])
              ..where(alerts.readAt.isNull()))
            .getSingle();
    return r.read(n) ?? 0;
  }

  Future<void> markAlertsRead(DateTime at) => (update(
    alerts,
  )..where(($AlertsTable t) => t.readAt.isNull())).write(AlertsCompanion(readAt: Value<DateTime>(at)));

  /// Alerts older than [before] go; so do the words of the ones that stay when [clearWords] is true.
  Future<void> pruneAlerts(DateTime before) =>
      (delete(alerts)..where(($AlertsTable t) => t.at.isSmallerThanValue(before))).go();

  Future<void> clearAlertWords() => update(alerts).write(const AlertsCompanion(words: Value<String>('')));

  // ---- sync (M7b) ----

  /// Written as `synced_at` of a row that the server refused on its own (SEC-1): the row is never sent again and never holds
  /// up the rows after it, and it can still be told apart from a row that was sent (whose time is when it went), so that a
  /// later version can send it again.
  static final DateTime refusedBySync = DateTime.utc(1970);

  /// The database gives times back in local time: compare the moment, not the value.
  static bool wasRefusedBySync(DateTime? syncedAt) => syncedAt?.isAtSameMomentAs(refusedBySync) ?? false;

  /// Answers made on this device that have not been sent yet, oldest first.
  Future<List<Attempt>> unsyncedAttempts({int limit = 40}) =>
      (select(attempts)
            ..where(($AttemptsTable t) => t.syncedAt.isNull() & t.eventId.isNull())
            ..orderBy(<OrderClauseGenerator<$AttemptsTable>>[(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  /// Visits made on this device that have ended and have not been sent yet, oldest first.
  Future<List<Session>> unsyncedSessions({int limit = 40}) =>
      (select(sessions)
            ..where(($SessionsTable t) => t.syncedAt.isNull() & t.eventId.isNull() & t.endedAt.isNotNull())
            ..orderBy(<OrderClauseGenerator<$SessionsTable>>[(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  Future<void> markAttemptsSynced(Iterable<int> ids, DateTime at) => (update(
    attempts,
  )..where(($AttemptsTable t) => t.id.isIn(ids))).write(AttemptsCompanion(syncedAt: Value<DateTime>(at)));

  Future<void> markSessionsSynced(Iterable<int> ids, DateTime at) => (update(
    sessions,
  )..where(($SessionsTable t) => t.id.isIn(ids))).write(SessionsCompanion(syncedAt: Value<DateTime>(at)));

  /// Adds an answer that came from another device. False if that event is already here.
  Future<bool> addRemoteAttempt(AttemptsCompanion row, {required String eventId, required DateTime at}) =>
      transaction(() async {
        final Attempt? have = await (select(
          attempts,
        )..where(($AttemptsTable t) => t.eventId.equals(eventId))).getSingleOrNull();
        if (have != null) return false;
        await into(attempts)
            .insert(row.copyWith(eventId: Value<String?>(eventId), syncedAt: Value<DateTime?>(at)));
        return true;
      });

  /// Adds a visit that came from another device and joins the answers that were waiting for it. Returns the local id,
  /// or null if that event is already here.
  Future<int?> addRemoteSession(
    SessionsCompanion row, {
    required String eventId,
    required String remoteKey,
    required DateTime at,
  }) => transaction(() async {
    final Session? have = await (select(
      sessions,
    )..where(($SessionsTable t) => t.eventId.equals(eventId))).getSingleOrNull();
    if (have != null) return null;
    final int id = await into(sessions).insert(
      row.copyWith(
        eventId: Value<String?>(eventId),
        remoteKey: Value<String?>(remoteKey),
        syncedAt: Value<DateTime?>(at),
      ),
    );
    await (update(attempts)..where(($AttemptsTable t) => t.remoteSession.equals(remoteKey))).write(
      AttemptsCompanion(sessionId: Value<int?>(id), remoteSession: const Value<String?>(null)),
    );
    return id;
  });

  /// The local id of a visit that came from another device (`deviceId:number`), if it has arrived.
  Future<int?> sessionIdForRemoteKey(String remoteKey) async => (await (select(
    sessions,
  )..where(($SessionsTable t) => t.remoteKey.equals(remoteKey))).getSingleOrNull())?.id;

  Future<List<Alert>> unsyncedAlerts({int limit = 40}) =>
      (select(alerts)
            ..where(($AlertsTable t) => t.syncedAt.isNull())
            ..orderBy(<OrderClauseGenerator<$AlertsTable>>[(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  Future<void> markAlertsSynced(Iterable<int> ids, DateTime at) => (update(
    alerts,
  )..where(($AlertsTable t) => t.id.isIn(ids))).write(AlertsCompanion(syncedAt: Value<DateTime>(at)));

  /// A child as the family has them: a new one is added, one this device already has is brought up to date (the
  /// companion too). The device's own creation time of an existing child is kept.
  Future<void> upsertProfileFromFamily(ProfilesCompanion row, {required bool isNew}) async {
    if (isNew) {
      await into(profiles).insert(row);
      return;
    }
    await (update(profiles)..where(($ProfilesTable t) => t.id.equals(row.id.value))).write(
      ProfilesCompanion(
        name: row.name,
        avatar: row.avatar,
        addressForm: row.addressForm,
        ageBand: row.ageBand,
        companionId: row.companionId,
        outfitId: row.outfitId,
      ),
    );
  }

  /// Visits that were never closed (the app was killed or the phone died) and are older than [olderThan] are closed at
  /// their last answer, or at their start if there was none, as "home". Without this an old visit would count as playing
  /// until now. Returns how many were closed.
  Future<int> closeStaleSessions(DateTime olderThan) => transaction(() async {
    final List<Session> open = await (select(
      sessions,
    )..where(($SessionsTable t) => t.endedAt.isNull() & t.startedAt.isSmallerThanValue(olderThan))).get();
    for (final Session s in open) {
      final Attempt? last =
          await (select(attempts)
                ..where(($AttemptsTable t) => t.sessionId.equals(s.id))
                ..orderBy(<OrderClauseGenerator<$AttemptsTable>>[(t) => OrderingTerm.desc(t.at)])
                ..limit(1))
              .getSingleOrNull();
      final DateTime end = last != null && last.at.isAfter(s.startedAt) ? last.at : s.startedAt;
      await (update(sessions)..where(($SessionsTable t) => t.id.equals(s.id))).write(
        SessionsCompanion(endedAt: Value<DateTime?>(end), endReason: const Value<String>('home')),
      );
    }
    return open.length;
  });

  /// Everything this device holds about a child: the profile, answers, visits, listens and alerts.
  Future<void> deleteChildData(String profileId) => transaction(() async {
    await (delete(attempts)..where(($AttemptsTable t) => t.profileId.equals(profileId))).go();
    await (delete(sessions)..where(($SessionsTable t) => t.profileId.equals(profileId))).go();
    await (delete(voiceListens)..where(($VoiceListensTable t) => t.profileId.equals(profileId))).go();
    await (delete(alerts)..where(($AlertsTable t) => t.profileId.equals(profileId))).go();
    await (delete(rewards)..where(($RewardsTable t) => t.profileId.equals(profileId))).go();
    await (delete(profiles)..where(($ProfilesTable t) => t.id.equals(profileId))).go();
    // The parents' promises for this child go with the child.
    final String? promises = await setting('ribbons');
    if (promises != null) {
      await putSetting('ribbons', encodeRibbons(withoutChild(decodeRibbons(promises), profileId)));
    }
  });

  // ---- rewards (M8) ----

  Future<Set<String>> awardKeys(String profileId) async => <String>{
    for (final Reward r in await (select(
      rewards,
    )..where(($RewardsTable t) => t.profileId.equals(profileId))).get())
      r.awardKey,
  };

  Future<List<Reward>> rewardsOf(String profileId) =>
      (select(rewards)
            ..where(($RewardsTable t) => t.profileId.equals(profileId))
            ..orderBy(<OrderingTerm Function($RewardsTable)>[($RewardsTable t) => OrderingTerm.asc(t.at)]))
          .get();

  /// Gives an award once. Returns false if the child already has it.
  Future<bool> addReward(RewardsCompanion row) async {
    final List<Reward> have =
        await (select(rewards)..where(
              ($RewardsTable t) =>
                  t.profileId.equals(row.profileId.value) & t.awardKey.equals(row.awardKey.value),
            ))
            .get();
    if (have.isNotEmpty) return false;
    await into(rewards).insert(row);
    return true;
  }

  Future<List<Reward>> unseenRewards(String profileId) =>
      (select(rewards)
            ..where(($RewardsTable t) => t.profileId.equals(profileId) & t.seenAt.isNull())
            ..orderBy(<OrderingTerm Function($RewardsTable)>[($RewardsTable t) => OrderingTerm.asc(t.at)]))
          .get();

  Future<void> markRewardsSeen(List<int> ids, DateTime at) => (update(
    rewards,
  )..where(($RewardsTable t) => t.id.isIn(ids))).write(RewardsCompanion(seenAt: Value<DateTime?>(at)));

  Future<List<Reward>> unsyncedRewards({int limit = 40}) =>
      (select(rewards)
            ..where(($RewardsTable t) => t.syncedAt.isNull())
            ..orderBy(<OrderingTerm Function($RewardsTable)>[($RewardsTable t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  Future<void> markRewardsSynced(List<int> ids, DateTime at) => (update(
    rewards,
  )..where(($RewardsTable t) => t.id.isIn(ids))).write(RewardsCompanion(syncedAt: Value<DateTime?>(at)));

  /// An award another phone gave: kept as it is, already seen here, and never sent back. False if it was here already.
  Future<bool> addRemoteReward(RewardsCompanion row, {required String eventId, required DateTime at}) =>
      addReward(
        row.copyWith(
          eventId: Value<String?>(eventId),
          seenAt: Value<DateTime?>(at),
          syncedAt: Value<DateTime?>(at),
        ),
      );
}
