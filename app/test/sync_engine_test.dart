// The sync engine with two simulated phones and a fake family server: the same child everywhere, nothing sent twice,
// nothing lost when the network fails, and a deleted child gone from every device.
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'engine/fixtures.dart';
import 'support/fake_family_server.dart';

const String kid = 'child-aaaa-0001';
const String dev1 = 'd1d1d1d1-0000-4000-8000-000000000001';
const String dev2 = 'd2d2d2d2-0000-4000-8000-000000000002';
const String dev3 = 'd3d3d3d3-0000-4000-8000-000000000003';
final int noon = DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch;

class Phone {
  Phone(this.id, this.server, {bool parent = true})
    : db = AppDatabase(NativeDatabase.memory()),
      parent = parent {
    engine = SyncEngine(
      db: db,
      call: server.callFor(id, parent: parent),
      deviceId: id,
      isParent: parent,
      nowMs: () => noon,
      pageSize: 4,
      batch: 4,
    );
  }

  final String id;
  final FakeFamilyServer server;
  final bool parent;
  final AppDatabase db;
  late final SyncEngine engine;

  Future<void> addChild({String name = 'נועה', String avatar = 'avatar-noa', String? companion}) =>
      db.addProfile(
        ProfilesCompanion.insert(
          id: kid,
          name: name,
          avatar: avatar,
          addressForm: 'f',
          ageBand: 1,
          createdAt: DateTime.utc(2026, 11, 1),
          companionId: Value<String?>(companion),
        ),
      );

  Future<void> answer(String item, String result, {int? session, int minute = 0, int no = 1}) =>
      db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 11, 20, 10, minute),
          profileId: kid,
          packId: 'starter',
          packVersion: '0.2.0',
          activityId: item,
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'SK-A-01',
          result: result,
          attemptNo: no,
          hintLevel: 0,
          sessionId: Value<int?>(session),
        ),
      );

  Future<int> visit({String reason = 'finished'}) async {
    final int id = await db.startSession(kid, DateTime.utc(2026, 11, 20, 10), plan: 'lesson:butterflies');
    await db.endSession(id, DateTime.utc(2026, 11, 20, 10, 8), reason);
    return id;
  }
}

String fingerprintOf(List<Attempt> rows) {
  final Engine e = Engine(catalog: smallCatalog())..replay(rows.map(eventOf));
  return fingerprint(e);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeFamilyServer server;
  late Phone p1;
  late Phone p2;

  setUp(() {
    server = FakeFamilyServer();
    p1 = Phone(dev1, server);
    p2 = Phone(dev2, server);
  });

  tearDown(() async {
    await p1.db.close();
    await p2.db.close();
  });

  test('a child made on one phone appears on the other with the same nickname, answers and visit', () async {
    await p1.addChild(companion: 'hero-son');
    final int s = await p1.visit();
    for (int i = 0; i < 6; i++) {
      await p1.answer(i.isEven ? 'A.1' : 'A.2', i == 2 ? 'incorrect' : 'correct', session: s, minute: i);
    }
    final SyncReport sent = await p1.engine.syncOnce();
    expect(sent.pushedEvents, 7, reason: '6 answers and 1 visit');

    final SyncReport got = await p2.engine.syncOnce();
    expect(got.childrenAdded, 1);
    expect(got.appliedEvents, 7);
    final Profile child = (await p2.db.allProfiles()).single;
    expect(child.id, kid);
    expect(child.name, 'נועה');
    expect(child.avatar, 'avatar-noa');
    expect(child.companionId, 'hero-son');
    final List<Attempt> there = await p2.db.attemptsOf(kid);
    expect(there.length, 6);
    final Session visit = (await p2.db.sessionsOf(kid)).single;
    expect(visit.endReason, 'finished');
    expect(visit.endedAt, isNotNull);
    expect(
      there.every((Attempt a) => a.sessionId == visit.id),
      isTrue,
      reason: 'the answers joined their visit, although they arrived first',
    );
    expect(there.every((Attempt a) => a.remoteSession == null), isTrue);
    expect(
      fingerprintOf(there),
      fingerprintOf(await p1.db.attemptsOf(kid)),
      reason: 'the same learning state on both phones',
    );
  });

  test('syncing again changes nothing, and a phone never takes back what it made itself', () async {
    await p1.addChild();
    final int s = await p1.visit();
    await p1.answer('A.1', 'correct', session: s);
    await p1.engine.syncOnce();
    await p2.engine.syncOnce();
    final SyncReport again = await p1.engine.syncOnce();
    expect(again.pushedEvents, 0);
    expect(again.appliedEvents, 0, reason: 'its own events came back in the pull and were skipped');
    expect((await p1.db.attemptsOf(kid)).length, 1);
    final SyncReport p2again = await p2.engine.syncOnce();
    expect(p2again.pulledEvents, 0, reason: 'the cursor moved on');
    expect(p2again.appliedEvents, 0);
    expect((await p2.db.attemptsOf(kid)).length, 1);
    expect(server.log.length, 2);
  });

  test('a lost answer makes the phone send again, and nothing is doubled anywhere', () async {
    await p1.addChild();
    await p1.answer('A.1', 'correct');
    await p1.answer('A.2', 'correct', minute: 1);
    server.loseAnswerOf = 'sync-push';
    await p1.engine.syncOnce();
    expect(server.log.length, 2, reason: 'the server did take them');
    expect(
      (await p1.db.unsyncedAttempts()).length,
      2,
      reason: 'but the phone never heard, so they stay "not sent"',
    );
    await p1.engine.syncOnce();
    expect(server.log.length, 2, reason: 'sent again: the server saw the same ids');
    expect(await p1.db.unsyncedAttempts(), isEmpty);
    await p2.engine.syncOnce();
    expect((await p2.db.attemptsOf(kid)).length, 2);
  });

  test('offline loses nothing: it all goes when the phone is back, and a half-done pull resumes where it stopped', () async {
    await p1.addChild();
    for (int i = 0; i < 9; i++) {
      await p1.answer('A.1', 'correct', minute: i, no: i + 1);
    }
    server.offline = true;
    final SyncReport none = await p1.engine.syncOnce();
    expect(none.pushedEvents, 0);
    expect((await p1.db.unsyncedAttempts(limit: 100)).length, 9);
    server.offline = false;
    await p1.engine.syncOnce();
    expect(await p1.db.unsyncedAttempts(limit: 100), isEmpty);
    expect(server.log.length, 9);

    // The phone's pull is cut off on its second page (pages are 4 events).
    server.failPullNumber = server.calls.where((String c) => c.endsWith('sync-pull')).length + 2;
    await p2.engine.syncOnce();
    final int partial = (await p2.db.attemptsOf(kid)).length;
    expect(partial, 4, reason: 'the first page was applied, the second failed');
    expect(
      await p2.db.setting(SyncEngine.cursorKey),
      '4',
      reason: 'the cursor stopped after what was applied',
    );
    await p2.engine.syncOnce();
    expect((await p2.db.attemptsOf(kid)).length, 9, reason: 'it resumed and nothing was applied twice');
  });

  test('deleting a child: gone here at once, on the server, and on the other phone; unsent answers are never sent', () async {
    await p1.addChild();
    await p1.answer('A.1', 'correct');
    await p1.engine.syncOnce();
    await p2.engine.syncOnce();
    expect((await p2.db.allProfiles()).length, 1);
    await p2.answer('A.2', 'correct', minute: 3); // made on the second phone, not yet sent

    await p1.engine.deleteChild(kid);
    expect(await p1.db.allProfiles(), isEmpty);
    expect(await p1.db.attemptsOf(kid), isEmpty);
    expect(server.tombstones, <String>[kid]);
    expect(server.children, isEmpty);
    expect(server.log, isEmpty, reason: 'nothing of the child is left on the server');

    final SyncReport r = await p2.engine.syncOnce();
    expect(r.childrenDeleted, 1);
    expect(await p2.db.allProfiles(), isEmpty);
    expect(await p2.db.attemptsOf(kid), isEmpty);
    expect(await p2.db.sessionsOf(kid), isEmpty);
    expect(server.log, isEmpty, reason: 'the second phone never sent its unsent answer');
    // And it does not come back from either phone.
    await p1.engine.syncOnce();
    await p2.engine.syncOnce();
    expect(server.children, isEmpty);
    expect(await p1.db.allProfiles(), isEmpty);
  });

  test('a deletion made offline is kept and made on the server as soon as the phone can reach it', () async {
    await p1.addChild();
    await p1.engine.syncOnce();
    await p2.engine.syncOnce();
    server.offline = true;
    await p1.engine.deleteChild(kid);
    expect(await p1.db.allProfiles(), isEmpty, reason: 'gone from this phone at once');
    expect(server.tombstones, isEmpty);
    server.offline = false;
    await p1.engine.syncOnce();
    expect(server.tombstones, <String>[kid]);
    await p2.engine.syncOnce();
    expect(await p2.db.allProfiles(), isEmpty);
  });

  test('a child device pulls the family but never saves or deletes children', () async {
    await p1.addChild();
    await p1.engine.syncOnce();
    final Phone kidPhone = Phone(dev3, server, parent: false);
    addTearDown(kidPhone.db.close);
    await kidPhone.engine.syncOnce();
    expect((await kidPhone.db.allProfiles()).single.name, 'נועה');
    expect(server.calls.where((String c) => c.startsWith('$dev3:') && c.endsWith('child-put')), isEmpty);
    await kidPhone.answer('A.1', 'correct');
    await kidPhone.engine.syncOnce();
    expect(server.log.length, 1, reason: 'it does send what the child did');
    await p1.engine.syncOnce();
    expect((await p1.db.attemptsOf(kid)).length, 1);
  });

  test('both phones add answers and both end with all of them, in the same learning state', () async {
    await p1.addChild();
    await p1.engine.syncOnce();
    await p2.engine.syncOnce();
    await p1.answer('A.1', 'correct', minute: 1);
    await p2.answer('A.2', 'incorrect', minute: 2);
    await p1.answer('A.3', 'correct', minute: 3);
    await p1.engine.syncOnce();
    await p2.engine.syncOnce();
    await p1.engine.syncOnce();
    final List<Attempt> a = await p1.db.attemptsOf(kid);
    final List<Attempt> b = await p2.db.attemptsOf(kid);
    expect(a.length, 3);
    expect(b.length, 3);
    expect(fingerprintOf(a), fingerprintOf(b));
  });

  test('an event id is the same for the same row and different for another device, kind or row', () {
    final String a = SyncEngine.eventIdOf(dev1, 'attempt', 7);
    expect(SyncEngine.eventIdOf(dev1, 'attempt', 7), a);
    expect(SyncEngine.eventIdOf(dev2, 'attempt', 7), isNot(a));
    expect(SyncEngine.eventIdOf(dev1, 'session', 7), isNot(a));
    expect(SyncEngine.eventIdOf(dev1, 'attempt', 8), isNot(a));
    expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });

  test(
    'only ids, numbers and fixed words are sent: never a name beyond the nickname, never free text',
    () async {
      await p1.addChild();
      final int s = await p1.visit();
      await p1.answer('A.1', 'correct', session: s);
      await p1.engine.syncOnce();
      final String sent = server.log.map((Map<String, Object?> e) => e.toString()).join(' ');
      expect(sent.contains('נועה'), isFalse, reason: 'the nickname travels only in the child profile');
      for (final Map<String, Object?> e in server.log) {
        expect(<String>['attempt', 'session'], contains(e['type']));
        final Map<String, Object?> d = e['data']! as Map<String, Object?>;
        expect(d.keys, isNot(contains('name')));
        expect(d.keys, isNot(contains('nickname')));
        expect(d.keys, isNot(contains('transcript')));
      }
    },
  );
}
