// QA, B-20 re-verification (SEC-12): a revisit mission (the bell flag) made from the real starter pack still plays,
// writes its answers through the app's own attempt sink, and reaches the family server and another phone under the
// lower-case lesson id; and an award the server refused under an older format is sent again after the engine version
// changes (the reward part of the once-per-version reset, which no other test reaches).
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/sync/sync_engine.dart';
import 'package:nitznutz/world/world_state.dart';

import 'support/fake_family_server.dart';
import 'support/fakes.dart';
import 'support/starter.dart';

const String kid = 'child-aaaa-0001';
const String dev1 = 'd1d1d1d1-0000-4000-8000-000000000001';
const String dev2 = 'd2d2d2d2-0000-4000-8000-000000000002';
final int noon = DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch;

SyncEngine engineFor(AppDatabase db, FakeFamilyServer server, String device, {int version = 1}) => SyncEngine(
  db: db,
  call: server.callFor(device),
  deviceId: device,
  isParent: true,
  nowMs: () => noon,
  engineVersion: version,
  pageSize: 4,
  batch: 4,
);

Future<void> addKid(AppDatabase db) => db.addProfile(
  ProfilesCompanion.insert(
    id: kid,
    name: 'נועה',
    avatar: 'avatar-noa',
    addressForm: 'f',
    ageBand: 1,
    createdAt: DateTime.utc(2026, 11, 1),
  ),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late PackContent content;
  setUpAll(() async => content = await loadStarter());

  test(
    'a revisit mission plays, its answers are written as mission-num-a-03, and they sync to another phone',
    () async {
      final WorldView view = WorldView(
        engine: Engine(catalog: engineCatalog(content)),
        now: DateTime.utc(2026, 11, 20),
        lands: const <TrophyLand, List<WorldObject>>{},
      );
      final Lesson mission = view.missionFor('NUM-A-03')!;
      expect(mission.id, 'mission-num-a-03');

      final AppDatabase phone1 = AppDatabase(NativeDatabase.memory());
      final AppDatabase phone2 = AppDatabase(NativeDatabase.memory());
      addTearDown(phone1.close);
      addTearDown(phone2.close);
      await addKid(phone1);
      // The app's own sink (attemptSinkProvider), over this phone's database.
      final ProviderContainer app = ProviderContainer(
        overrides: <Override>[databaseProvider.overrideWith((Ref ref) async => phone1)],
      );
      addTearDown(app.dispose);
      // The visit as the lesson screen names a mission (lesson_screen.dart).
      final int visit = await phone1.startSession(
        kid,
        DateTime.utc(2026, 11, 20, 10),
        plan: 'mission:${mission.skillIds.first.toLowerCase()}',
      );
      final LessonController c = LessonController(
        content: content,
        lesson: mission,
        profileId: kid,
        sessionId: visit,
        record: app.read(attemptSinkProvider),
        clock: FixedClock(DateTime.utc(2026, 11, 20, 10, 1).millisecondsSinceEpoch),
      );
      // One "not yet" on the first activity, then a right answer on every activity, to the celebration.
      expect((await c.submitPlacement(right: false)).correct, isFalse);
      for (int i = 0; i < mission.itemIds.length; i++) {
        expect((await c.submitPlacement(right: true)).correct, isTrue);
        c.next();
      }
      expect(c.finished, isTrue);
      await phone1.endSession(visit, DateTime.utc(2026, 11, 20, 10, 5), 'finished');

      final List<Attempt> written = await phone1.attemptsOf(kid);
      expect(written.length, mission.itemIds.length + 1);
      expect(written.map((Attempt a) => a.lessonId).toSet(), <String>{'mission-num-a-03'});
      expect(written.map((Attempt a) => a.sessionId).toSet(), <int>{visit});

      // A server that refuses whatever the real sync-push would.
      final FakeFamilyServer server = FakeFamilyServer(checksFormat: true);
      final SyncReport r = await engineFor(phone1, server, dev1).syncOnce();
      expect(r.refusedEvents, 0);
      expect(r.pushedEvents, written.length + 1, reason: 'every answer and the visit');
      expect(await phone1.unsyncedAttempts(), isEmpty);
      expect(await phone1.unsyncedSessions(), isEmpty);
      expect(
        <Object?>{
          for (final Map<String, Object?> e in server.log)
            if (e['type'] == 'attempt') (e['data']! as Map<String, Object?>)['lesson_id'],
        },
        <Object?>{'mission-num-a-03'},
      );
      expect(server.log.where((Map<String, Object?> e) => e['type'] == 'attempt').length, written.length);

      // The other phone gets the same answers, under the same lesson id and the same visit.
      await engineFor(phone2, server, dev2).syncOnce();
      final List<Attempt> there = await phone2.attemptsOf(kid);
      expect(there.length, written.length);
      expect(there.map((Attempt a) => a.lessonId).toSet(), <String>{'mission-num-a-03'});
      expect((await phone2.sessionsOf(kid)).single.plan, 'mission:num-a-03');
      expect(there.every((Attempt a) => a.sessionId == there.first.sessionId && a.sessionId != null), isTrue);
    },
  );

  test(
    'an award refused under an older format is sent again once, after the engine version changes',
    () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await addKid(db);
      final FakeFamilyServer server = FakeFamilyServer(checksFormat: true);
      await db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 11, 20, 10),
          profileId: kid,
          packId: 'starter',
          packVersion: '0.8.0',
          activityId: 'a.1',
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'NUM-A-03',
          result: 'correct',
          attemptNo: 1,
          hintLevel: 0,
        ),
      );
      await db.addReward(
        RewardsCompanion.insert(
          profileId: kid,
          awardKey: 'star:NUM-A-03',
          kind: 'star',
          at: DateTime.utc(2026, 11, 20, 11),
        ),
      );
      // A gateway that does not know the award's key: the answer gets in, the award alone is refused and marked.
      server.forgets = <String>{'key'};
      await engineFor(db, server, dev1).syncOnce();
      expect(AppDatabase.wasRefusedBySync((await db.rewardsOf(kid)).single.syncedAt), isTrue);
      expect(await db.unsyncedAttempts(), isEmpty);

      // The right gateway; the same version does not send it again.
      server.forgets = <String>{};
      await engineFor(db, server, dev1).syncOnce();
      expect(AppDatabase.wasRefusedBySync((await db.rewardsOf(kid)).single.syncedAt), isTrue);
      expect(server.log.where((Map<String, Object?> e) => e['type'] == 'reward'), isEmpty);

      // A new version sends it once more, and it gets in.
      final SyncReport r = await engineFor(db, server, dev1, version: 2).syncOnce();
      expect(r.pushedEvents, 1);
      expect(r.refusedEvents, 0);
      final Reward star = (await db.rewardsOf(kid)).single;
      expect(star.syncedAt, isNotNull);
      expect(AppDatabase.wasRefusedBySync(star.syncedAt), isFalse);
      expect(server.log.where((Map<String, Object?> e) => e['type'] == 'reward').length, 1);
    },
  );
}
