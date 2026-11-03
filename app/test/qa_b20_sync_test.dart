// QA, B-20 (sync robustness). Edges of the acceptance that the developer's tests leave open: the exact boundaries of the
// time the server takes with a right clock, a re-timed row that goes again after a lost answer (never doubled), the wire
// format reset ending a wait, the pushes of alerts going on during a wait, a stall of one kind with the others sent in the
// same round, and a visit refused alone while the answers around it are taken.
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/fake_family_server.dart';

const String kid = 'child-aaaa-0001';
const String dev = 'd1d1d1d1-0000-4000-8000-000000000001';
final int noon = DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch;
const int minute = 60000;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeFamilyServer strict;
  late AppDatabase db;
  int clock = noon;

  SyncEngine engine({int Function()? now, int Function()? server}) => SyncEngine(
    db: db,
    call: strict.callFor(dev),
    deviceId: dev,
    isParent: true,
    nowMs: now ?? () => clock,
    serverNowMs: server,
    pageSize: 4,
    batch: 4,
  );

  Future<void> answer(String item, {DateTime? at, int minuteOfHour = 0}) => db.recordAttempt(
    AttemptsCompanion.insert(
      at: at ?? DateTime.utc(2026, 11, 20, 10, minuteOfHour),
      profileId: kid,
      packId: 'starter',
      packVersion: '0.2.0',
      activityId: item,
      activityRevision: 1,
      template: 'count_tap',
      templateVersion: '1.0',
      skillId: 'SK-A-01',
      result: 'correct',
      attemptNo: 1,
      hintLevel: 0,
    ),
  );

  int pushes() => strict.calls.where((String c) => c == '$dev:sync-push').length;

  setUp(() async {
    strict = FakeFamilyServer(checksFormat: true);
    db = AppDatabase(NativeDatabase.memory());
    clock = noon;
    await db.addProfile(
      ProfilesCompanion.insert(
        id: kid,
        name: 'נועה',
        avatar: 'avatar-noa',
        addressForm: 'f',
        ageBand: 1,
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    );
    await engine().syncOnce();
  });
  tearDown(() => db.close());

  test('the exact edges of the range with a right clock: one second before the floor and after the server (the database keeps whole seconds) are held in', () async {
    final int floor = SyncEngine.minClientMs;
    DateTime ms(int v) => DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    await answer('e.1', at: ms(floor - 1000));
    await answer('e.2', at: ms(floor));
    await answer('e.3', at: ms(floor + 1000));
    await answer('e.4', at: ms(noon - 1000));
    await answer('e.5', at: ms(noon));
    await answer('e.6', at: ms(noon + 1000));
    final SyncReport r = await engine().syncOnce();
    expect(r.pushedEvents, 6);
    expect(r.refusedEvents, 0);
    final Map<Object?, int> at = <Object?, int>{
      for (final Map<String, Object?> e in strict.log)
        (e['data']! as Map<String, Object?>)['activity_id']: e['at']! as int,
    };
    expect(at['e.1'], floor, reason: 'one second before the floor is held at it');
    expect(at['e.2'], floor);
    expect(at['e.3'], floor + 1000);
    expect(at['e.4'], noon - 1000);
    expect(at['e.5'], noon);
    expect(at['e.6'], noon, reason: 'one second after the server is held at the server');
  });

  test('a row that was re-timed and whose answer was lost goes again with another offset, and the server has it once', () async {
    await answer('x.1', at: DateTime.utc(2010, 1, 1, 10));
    int wrongNow = DateTime.utc(2010, 1, 1, 12).millisecondsSinceEpoch;
    int serverNow = noon;
    final SyncEngine e = engine(now: () => wrongNow, server: () => serverNow);
    strict.loseAnswerOf = 'sync-push';
    await e.syncOnce();
    expect(strict.log, hasLength(1), reason: 'the server took it');
    expect(
      (await db.unsyncedAttempts()),
      hasLength(1),
      reason: 'the phone did not hear, so it is still to send',
    );
    final int first = strict.log.single['at']! as int;
    // The phone's clock is corrected a day later (the offset changes), and the same row goes again.
    wrongNow = DateTime.utc(2010, 1, 2, 12).millisecondsSinceEpoch;
    serverNow = noon + 3 * 3600000;
    final SyncReport r = await e.syncOnce();
    expect(strict.log, hasLength(1), reason: 'the id has no time in it: the server has it once');
    expect(strict.log.single['at'], first, reason: 'and keeps the time it had');
    expect(r.refusedEvents, 0);
    expect(await db.unsyncedAttempts(), isEmpty);
  });

  test('a new wire format ends a wait at once: the rows of a stalled kind are tried again in the first round of the new build', () async {
    strict.forgets = <String>{'duration_ms'};
    await answer('a.1');
    expect(await engine().syncOnce().then((SyncReport r) => r.pushedEvents), 0);
    final int before = pushes();
    await engine().syncOnce();
    expect(pushes(), before, reason: 'in the wait: no sync-push call');
    expect((await db.setting('sync_stall')), isNotEmpty);
    strict.forgets = <String>{};
    // The next build brings a new wire format: the setting of the old one is not what the new build reads.
    await db.putSetting('sync_refused_reset_format', '0');
    final SyncReport r = await engine().syncOnce();
    expect(r.pushedEvents, 1, reason: 'the reset forgets the wait');
    expect(await db.setting('sync_stall'), isEmpty);
  });

  test('during the wait after a stall the alerts of the device still go', () async {
    strict.forgets = <String>{'duration_ms'};
    await answer('a.1');
    await engine().syncOnce();
    clock += minute;
    await db.addAlert(
      AlertsCompanion.insert(
        at: DateTime.fromMillisecondsSinceEpoch(clock, isUtc: true),
        profileId: const Value<String?>(kid),
        category: 'disclosure',
        severity: 'info',
        dedupeKey: 'words:wait',
      ),
    );
    final int before = pushes();
    final SyncReport r = await engine().syncOnce();
    expect(pushes(), before, reason: 'the events wait');
    expect(r.pushedAlerts, 1, reason: 'the alert does not');
    expect(strict.alerts.map((Map<String, Object?> a) => a['key']), contains('words:wait'));
  });

  test('a stalled kind does not hold back the others in the same round: a visit goes, the answers wait, then they go', () async {
    strict.forgets = <String>{'duration_ms'};
    final int v = await db.startSession(kid, DateTime.utc(2026, 11, 20, 10), plan: 'lesson:butterflies');
    await db.endSession(v, DateTime.utc(2026, 11, 20, 10, 8), 'finished');
    for (int i = 1; i <= 6; i++) {
      await answer('a.$i', minuteOfHour: i);
    }
    final SyncReport r = await engine().syncOnce();
    expect(r.pushedEvents, 1, reason: 'the visit');
    expect(
      (await db.unsyncedAttempts(limit: 100)).length,
      6,
      reason: 'nothing of the answers was lost or marked',
    );
    expect(await db.setting('sync_stall'), '1,$clock,attempt');
    strict.forgets = <String>{};
    clock += SyncEngine.stallBase.inMilliseconds;
    final SyncReport next = await engine().syncOnce();
    expect(next.pushedEvents, 6);
    expect(await db.setting('sync_stall'), isEmpty, reason: 'a round that does not stall ends it');
  });

  test('a stall setting of the old form (two parts, from the first B-20 commit) is not a stall and costs the child nothing', () async {
    await db.putSetting('sync_stall', '3,$clock');
    await answer('a.1');
    expect((await engine().syncOnce()).pushedEvents, 1);
  });

  test('the setting of a stall is not written by anything but a stalled round (counts only)', () async {
    strict.forgets = <String>{'duration_ms'};
    await answer('a.1');
    await engine().syncOnce();
    final String stall = (await db.setting('sync_stall'))!;
    expect(stall, matches(RegExp(r'^\d+,\d+,(attempt|session|reward)(\+(attempt|session|reward))*$')));
    expect(stall, isNot(contains('a.1')), reason: 'no id or text of a row in a setting');
  });
}
