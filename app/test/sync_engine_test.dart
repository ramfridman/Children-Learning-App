// The sync engine with two simulated phones and a fake family server: the same child everywhere, nothing sent twice,
// nothing lost when the network fails, and a deleted child gone from every device.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/reward_rules.dart';
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
      nowMs: () => clock,
      pageSize: 4,
      batch: 4,
    );
  }

  /// The phone's clock: tests move it to get past the wait after a stalled round.
  int clock = noon;

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

  Future<void> answer(
    String item,
    String result, {
    int? session,
    int minute = 0,
    int no = 1,
    String response = '',
    DateTime? at,
  }) => db.recordAttempt(
    AttemptsCompanion.insert(
      at: at ?? DateTime.utc(2026, 11, 20, 10, minute),
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
      response: Value<String>(response),
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

  group('B-28: names saved before the limit was 24', () {
    const String long = 'abcdefghijklmnopqrstuvwxyzabcd';

    test(
      'a 30-letter name goes as its first 24 units, stays whole on this phone and is not sent again',
      () async {
        await p1.addChild(name: long);
        await p1.engine.syncOnce();
        expect(server.children[kid]?['nickname'], long.substring(0, 24));
        expect(
          (await p1.db.allProfiles()).single.name,
          long,
          reason: 'the pull did not shorten the name here',
        );

        server.calls.clear();
        await p1.engine.syncOnce();
        expect(
          server.calls,
          isNot(contains('$dev1:child-put')),
          reason: 'nothing changed, so nothing goes again',
        );

        await p2.engine.syncOnce();
        expect(
          (await p2.db.allProfiles()).single.name,
          long.substring(0, 24),
          reason: 'what the family account has',
        );
      },
    );

    test('the characters the server refuses are left out of the nickname', () async {
      await p1.addChild(name: 'נועה <3>');
      await p1.engine.syncOnce();
      expect(server.children[kid]?['nickname'], 'נועה 3');
      expect((await p1.db.allProfiles()).single.name, 'נועה <3>');
    });

    test(
      'a name with nothing the server can take is not sent, and the answers wait (B-32), not refused',
      () async {
        await p1.addChild(name: '<<>>');
        await p1.answer('A.1', 'correct');
        final SyncReport r = await p1.engine.syncOnce();
        expect(server.calls, isNot(contains('$dev1:child-put')));
        expect(server.children, isEmpty);
        expect(
          r.refusedEvents,
          0,
          reason: 'the server never saw the row: it stays "not sent" for when it has the child',
        );
        expect(server.calls, isNot(contains('$dev1:sync-push')));
        expect(await p1.db.unsyncedAttempts(), hasLength(1));
      },
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

  Future<void> raise(
    Phone p,
    String key, {
    String category = 'frustration',
    String? child = kid,
    String words = '',
  }) => p.db.addAlert(
    AlertsCompanion.insert(
      at: DateTime.utc(2026, 11, 20, 11),
      profileId: Value<String?>(child),
      category: category,
      severity: 'attention',
      dedupeKey: key,
      words: Value<String>(words),
    ),
  );

  group('alerts', () {
    test('an alert raised on a child device reaches the parent phone once, and is never sent back', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
      await kidPhone.engine.syncOnce();
      await raise(kidPhone, 'upset:1');
      final SyncReport out = await kidPhone.engine.syncOnce();
      expect(out.pushedAlerts, 1);
      expect(await kidPhone.db.unsyncedAlerts(), isEmpty);
      final SyncReport got = await p1.engine.syncOnce();
      expect(got.pulledAlerts, 1);
      final Alert a = (await p1.db.allAlerts()).single;
      expect(a.dedupeKey, 'upset:1');
      expect(a.profileId, kid);
      expect(a.syncedAt, isNotNull, reason: 'it came from elsewhere, so it is not sent back');
      final SyncReport again = await p1.engine.syncOnce();
      expect(again.pulledAlerts, 0);
      expect(again.pushedAlerts, 0);
      expect(server.alerts.length, 1);
    });

    test('a word alert said again is sent again, and the parent phone takes the higher count', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
      await kidPhone.engine.syncOnce();
      await raise(kidPhone, 'words:1', category: 'disclosure');
      await kidPhone.engine.syncOnce();
      await p1.engine.syncOnce();
      expect((await p1.db.allAlerts()).single.count, 0);
      final Alert mine = (await kidPhone.db.allAlerts()).single;
      await kidPhone.db.countAlertAgain(mine);
      await kidPhone.db.countAlertAgain((await kidPhone.db.allAlerts()).single);
      expect((await kidPhone.db.unsyncedAlerts()).single.count, 3, reason: 'counted again, so not sent yet');
      final SyncReport again = await kidPhone.engine.syncOnce();
      expect(again.pushedAlerts, 0, reason: 'the same alert: a duplicate for the server, so no second push');
      expect(server.alerts.single['count'], 3);
      final SyncReport got = await p1.engine.syncOnce();
      expect(got.pulledAlerts, 0, reason: 'not a new alert');
      expect((await p1.db.allAlerts()).single.count, 3);
    });

    test('the same alert found on two phones is one alert for the family', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await raise(p1, 'limit:day1', category: 'pastLimit');
      await raise(p2, 'limit:day1', category: 'pastLimit');
      await p1.engine.syncOnce();
      final SyncReport second = await p2.engine.syncOnce();
      expect(server.alerts.length, 1);
      expect(second.pushedAlerts, 0, reason: 'the server called it a duplicate');
      expect((await p2.db.allAlerts()).length, 1);
    });

    test('an alert of a deleted child is never sent, an alert about the gate has no child, and words travel only when kept', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      await raise(p1, 'gate:1', category: 'gateAttempts', child: null);
      await raise(p1, 'words:1', category: 'inappropriateWords', words: 'חרא');
      await raise(p1, 'words:2', category: 'inappropriateWords');
      await p1.engine.syncOnce();
      final Map<String, Object?> gate = server.alerts.firstWhere(
        (Map<String, Object?> a) => a['key'] == 'gate:1',
      );
      expect(gate['child_id'], isNull);
      expect(server.alerts.firstWhere((Map<String, Object?> a) => a['key'] == 'words:1')['words'], 'חרא');
      expect(
        server.alerts.firstWhere((Map<String, Object?> a) => a['key'] == 'words:2').containsKey('words'),
        isFalse,
      );
      await raise(p1, 'upset:9');
      await p1.engine.deleteChild(kid);
      expect(server.alerts.where((Map<String, Object?> a) => a['key'] == 'upset:9'), isEmpty);
      expect(
        await p1.db.allAlerts(),
        isNotEmpty,
        reason: 'the gate alert is about the device, not the child',
      );
    });
  });

  group('an alert the server keeps refusing', () {
    // A gateway that answers bad_request to every alert, with one alert that has words and one that has none. Returns
    // the alert-create calls of one round and of the round after it.
    Future<({List<Map<String, Object?>> first, int second})> refusedRounds(int Function() serverNow) async {
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
      await kidPhone.addChild();
      await kidPhone.engine.syncOnce();
      final real = server.callFor(dev3, parent: false);
      final List<Map<String, Object?>> creates = <Map<String, Object?>>[];
      final SyncEngine engine = SyncEngine(
        db: kidPhone.db,
        call: (String name, Map<String, Object?> body) {
          if (name != 'alert-create') return real(name, body);
          creates.add(body);
          if (creates.length > 50) throw StateError('more than 50 alert-create calls');
          throw const GatewayException('bad_request', status: 400);
        },
        deviceId: dev3,
        isParent: false,
        nowMs: () => noon,
        serverNowMs: serverNow,
      );
      await kidPhone.db.addAlert(
        AlertsCompanion.insert(
          at: DateTime.utc(2026, 11, 20, 11),
          profileId: const Value<String?>(kid),
          category: 'disclosure',
          severity: 'important',
          dedupeKey: 'words:sec30',
          words: const Value<String>('הוא מכה אותי'),
        ),
      );
      await raise(kidPhone, 'upset:sec30');
      await engine.syncOnce();
      final List<Map<String, Object?>> first = List<Map<String, Object?>>.of(creates);
      expect(await kidPhone.db.unsyncedAlerts(), isEmpty, reason: 'kept aside, not retried in a loop');
      await engine.syncOnce();
      return (first: first, second: creates.length - first.length);
    }

    List<Map<String, Object?>> of(List<Map<String, Object?>> calls, String key) =>
        calls.where((Map<String, Object?> b) => b['key'] == key).toList();

    test('SEC-30: a clock that changes on every look costs at most two calls an alert', () async {
      // The time the phone believes the server has is behind the alert's own time and changes each time it is worked
      // out, so the time sent changes each time. The earlier loop called again for as long as it changed (1,001 calls).
      int tick = 0;
      final ({List<Map<String, Object?>> first, int second}) r = await refusedRounds(
        () => noon - 3 * 3600000 + 1000 * tick++,
      );
      expect(of(r.first, 'words:sec30'), hasLength(2));
      expect(of(r.first, 'upset:sec30'), hasLength(2));
      expect(of(r.first, 'words:sec30').every((Map<String, Object?> b) => b.containsKey('words')), isTrue);
      expect(r.second, 0, reason: 'a refused alert is not sent again by the next round');
    });

    test(
      'SEC-30: with the same time both times, an alert with words is sent once more without them',
      () async {
        final ({List<Map<String, Object?>> first, int second}) r = await refusedRounds(
          () => noon - 3 * 3600000,
        );
        final List<Map<String, Object?>> words = of(r.first, 'words:sec30');
        expect(words, hasLength(2));
        expect(words.first.containsKey('words'), isTrue);
        expect(words.last.containsKey('words'), isFalse);
        expect(
          of(r.first, 'upset:sec30'),
          hasLength(1),
          reason: 'no words and the same time: nothing new to try',
        );
        expect(r.second, 0);
      },
    );
  });

  group('the language settings of each child are a rule of the family', () {
    late Phone kidPhone;
    final Map<String, Object?> vector =
        jsonDecode(File('../testvectors/language-settings.json').readAsStringSync()) as Map<String, Object?>;

    setUp(() {
      kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
    });

    Future<FamilyLanguages> languagesOf(Phone p) async =>
        FamilyLanguages.decode(await p.db.setting(languagesSettingKey));

    Future<void> set(Phone p, FamilyLanguages f) => p.db.putSetting(languagesSettingKey, f.encode());

    test('a family that never touches a language syncs exactly the document it did before', () async {
      await p1.engine.syncOnce();
      expect(server.rules, isNotNull);
      expect(server.rules!.containsKey('languages'), isFalse);
      expect(server.rulesVersion, 1);
      await p1.engine.syncOnce();
      expect(server.rulesVersion, 1, reason: 'nothing changed, nothing was sent');
    });

    test('a language turned on in one parent phone reaches the other and a child device, and nothing is sent back', () async {
      await p1.engine.syncOnce();
      final FamilyLanguages f = const FamilyLanguages()
          .withSwitches(kid, 'eng', const LanguageSwitches(on: true, oralOnly: true))!
          .withSwitches(kid, 'rus', const LanguageSwitches(on: true, route: 'heritage', band: 1))!;
      await set(p1, f);
      await p1.engine.syncOnce();
      expect(server.rulesVersion, 2);
      expect(server.rules!['languages'], f.toJson());

      final SyncReport got = await p2.engine.syncOnce();
      expect(got.rulesApplied, isTrue);
      expect((await languagesOf(p2)).enabledFor(kid), <String>['eng', 'rus']);
      expect((await languagesOf(p2)).of(kid, 'rus').route, 'heritage');
      expect(
        server.rulesVersion,
        2,
        reason: 'the new phone did not send its (empty) settings over the family\'s',
      );

      await kidPhone.engine.syncOnce();
      expect((await languagesOf(kidPhone)).of(kid, 'eng').oralOnly, isTrue);
      await set(kidPhone, const FamilyLanguages());
      await kidPhone.engine.syncOnce();
      expect(
        server.rules!['languages'],
        f.toJson(),
        reason: 'a child device cannot change the settings of the family',
      );
    });

    test('the last change wins by the count of the server, as for every other rule', () async {
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await set(p1, const FamilyLanguages().withSwitches(kid, 'eng', const LanguageSwitches(on: true))!);
      await set(p2, const FamilyLanguages().withSwitches(kid, 'heb', const LanguageSwitches(on: true))!);
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await p1.engine.syncOnce();
      expect((await languagesOf(p1)).enabledFor(kid), <String>['heb']);
      expect((await languagesOf(p2)).enabledFor(kid), <String>['heb']);
    });

    test('turning every language off again takes them off the other phones too', () async {
      await p1.engine.syncOnce();
      await set(p1, const FamilyLanguages().withSwitches(kid, 'eng', const LanguageSwitches(on: true))!);
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      expect((await languagesOf(p2)).enabledFor(kid), <String>['eng']);
      await set(p1, const FamilyLanguages());
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      expect((await languagesOf(p2)).isEmpty, isTrue);
      expect(server.rules!.containsKey('languages'), isFalse);
    });

    test('the other rules are untouched by the languages, and the document stays small', () async {
      await p1.db.putSetting('parent_rules', const ParentRules(restOn: false).encode());
      FamilyLanguages f = const FamilyLanguages();
      for (final Object? example in (vector['examples']! as List<Object?>).take(1)) {
        f = FamilyLanguages.fromJson(example);
      }
      await set(p1, f);
      await p1.engine.syncOnce();
      expect(server.rules!['restOn'], isFalse);
      expect(server.rules!['languages'], f.toJson());
      expect(jsonEncode(server.rules).length, lessThan(4000));
    });
  });

  group('the family rules', () {
    Future<void> setRules(Phone p, ParentRules r, {bool keepWords = true, bool ai = false}) async {
      await p.db.putSetting('parent_rules', r.encode());
      await p.db.putSetting('keep_words', keepWords ? 'on' : 'off');
      await p.db.putSetting('ai_helper', ai ? 'on' : 'off');
    }

    Future<ParentRules> rulesOf(Phone p) async => ParentRules.decode(await p.db.setting('parent_rules'));

    test('rules set on one parent phone reach the other, and a new phone takes them instead of sending its defaults', () async {
      await p1.engine.syncOnce(); // first rules of the family: its defaults
      await setRules(
        p1,
        const ParentRules(limitByBand: <String, int>{'A': 10, 'B': 25, 'C': 35}, restOn: false),
        keepWords: false,
        ai: true,
      );
      await p1.engine.syncOnce();
      expect(server.rulesVersion, 2);

      final SyncReport got = await p2.engine.syncOnce();
      expect(got.rulesApplied, isTrue);
      expect(
        server.rulesVersion,
        2,
        reason: 'the new phone did not send its defaults over the rules of the family',
      );
      final ParentRules r = await rulesOf(p2);
      expect(r.limitFor('x', 1), 25);
      expect(r.restOn, isFalse);
      expect(await p2.db.setting('keep_words'), 'off');
      expect(await p2.db.setting('ai_helper'), 'on');
    });

    test('the last change wins by the count of the server, and a phone that changed nothing takes the newer rules', () async {
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await setRules(p1, const ParentRules(restOn: false));
      await setRules(p2, const ParentRules(lockWhenDone: false));
      await p1.engine.syncOnce();
      await p2.engine.syncOnce(); // the later write
      expect(server.rules!['lockWhenDone'], isFalse);
      expect(server.rules!['restOn'], isTrue, reason: 'the second write replaced the first as a whole');
      await p1.engine.syncOnce();
      final ParentRules r = await rulesOf(p1);
      expect(r.lockWhenDone, isFalse);
      expect(r.restOn, isTrue);
      final int version = server.rulesVersion;
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      expect(server.rulesVersion, version, reason: 'nothing changed, nothing was sent');
    });

    test('a child device takes the rules and never sends any', () async {
      await p1.engine.syncOnce();
      await setRules(p1, const ParentRules(restOn: false));
      await p1.engine.syncOnce();
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
      final SyncReport r = await kidPhone.engine.syncOnce();
      expect(r.rulesApplied, isTrue);
      expect((await rulesOf(kidPhone)).restOn, isFalse);
      await kidPhone.db.putSetting('parent_rules', const ParentRules(restOn: true).encode());
      await kidPhone.engine.syncOnce();
      expect(
        server.rules!['restOn'],
        isFalse,
        reason: 'a child device cannot change the rules of the family',
      );
    });
  });
  group('rewards', () {
    Future<void> give(Phone p, String key, {String kind = 'star', bool seen = false}) => p.db.addReward(
      RewardsCompanion.insert(
        profileId: kid,
        awardKey: key,
        kind: kind,
        at: DateTime.utc(2026, 11, 20, 11),
        seenAt: Value<DateTime?>(seen ? DateTime.utc(2026, 11, 20, 11) : null),
      ),
    );

    test('what one phone gave arrives on the other, already seen there, and is not sent back', () async {
      await p1.addChild();
      await give(p1, 'trophy:counting:silver', kind: 'trophy');
      await give(p1, 'star:NUM-A-01');
      final SyncReport sent = await p1.engine.syncOnce();
      expect(sent.pushedEvents, 2);
      expect(server.log.where((Map<String, Object?> e) => e['type'] == 'reward').length, 2);
      expect(
        server.log.firstWhere((Map<String, Object?> e) => e['type'] == 'reward')['data'],
        <String, Object?>{'kind': 'trophy', 'key': 'trophy:counting:silver'},
        reason: 'only a kind and a key',
      );
      await p2.engine.syncOnce();
      final List<Reward> there = await p2.db.rewardsOf(kid);
      expect(there.map((Reward r) => r.awardKey).toSet(), <String>{
        'trophy:counting:silver',
        'star:NUM-A-01',
      });
      expect(there.every((Reward r) => r.seenAt != null), isTrue, reason: 'already seen: no second ceremony');
      expect(there.every((Reward r) => r.syncedAt != null), isTrue, reason: 'never sent back');
      final int before = server.log.length;
      await p2.engine.syncOnce();
      expect(server.log.length, before);
    });

    test('two phones that each worked out the same award end with it once', () async {
      await p1.addChild();
      await give(p1, 'star:NUM-A-01');
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      // The second phone had also worked it out by itself, before it heard.
      final int sameKey = (await p2.db.rewardsOf(kid))
          .where((Reward r) => r.awardKey == 'star:NUM-A-01')
          .length;
      expect(sameKey, 1);
      await give(p2, 'star:NUM-A-01');
      await p2.engine.syncOnce();
      await p1.engine.syncOnce();
      expect((await p1.db.rewardsOf(kid)).length, 1);
      expect((await p2.db.rewardsOf(kid)).length, 1);
    });

    test(
      'an award is never taken away by anything that arrives later, and goes only with the child',
      () async {
        await p1.addChild();
        await give(p1, 'sticker:butterflies:1', kind: 'sticker');
        await p1.engine.syncOnce();
        await p2.engine.syncOnce();
        expect((await p2.db.rewardsOf(kid)).single.awardKey, 'sticker:butterflies:1');
        await p1.engine.deleteChild(kid);
        await p2.engine.syncOnce();
        expect(await p2.db.rewardsOf(kid), isEmpty);
        expect(await p1.db.rewardsOf(kid), isEmpty);
      },
    );
  });

  // SEC-1: the real sync-push refuses a whole batch when one event has a field it will not take. SEC-12: a server that
  // refuses every event does not know this app's format; that is not a bad row.
  group('a row the server will not take', () {
    late FakeFamilyServer strict;
    late Phone s1;
    late Phone s2;

    setUp(() async {
      strict = FakeFamilyServer(checksFormat: true);
      s1 = Phone(dev1, strict);
      s2 = Phone(dev2, strict);
      await s1.addChild();
      await s1.engine.syncOnce();
    });

    tearDown(() async {
      await s1.db.close();
      await s2.db.close();
    });

    int pushes() => strict.calls.where((String c) => c == '$dev1:sync-push').length;

    test('is sent once more on its own, then never again; the good rows of its batch and after it arrive', () async {
      // The oldest row is the bad one, so it is in the first batch of every round (batches are 4 rows here).
      await s1.answer('Not An Id', 'correct');
      for (int i = 1; i <= 5; i++) {
        await s1.answer('a.$i', 'correct', minute: i);
      }
      final int before = pushes();
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.pushedEvents, 5);
      expect(r.refusedEvents, 1);
      expect(
        pushes() - before,
        1 + 4 + 1,
        reason: 'the refused batch, its four rows one by one, then the last two',
      );
      expect(
        strict.log.map((Map<String, Object?> e) => (e['data']! as Map<String, Object?>)['activity_id']),
        <String>['a.1', 'a.2', 'a.3', 'a.4', 'a.5'],
      );
      expect(await s1.db.unsyncedAttempts(limit: 100), isEmpty, reason: 'nothing is left to send');
      final Attempt bad = (await s1.db.attemptsOf(kid))
          .firstWhere((Attempt a) => a.activityId == 'Not An Id');
      expect(AppDatabase.wasRefusedBySync(bad.syncedAt), isTrue, reason: 'marked as refused, not as sent');
      expect(
        (await s1.db.attemptsOf(kid))
            .where((Attempt a) => a.syncedAt != null && !AppDatabase.wasRefusedBySync(a.syncedAt))
            .length,
        5,
        reason: 'the good ones are marked as sent',
      );

      final int again = pushes();
      await s1.answer('a.6', 'correct', minute: 9);
      await s1.engine.syncOnce();
      await s1.engine.syncOnce();
      expect(pushes() - again, 1, reason: 'only the new row goes, once: the refused one never comes back');
      expect(strict.log.length, 6);
      await s2.engine.syncOnce();
      expect((await s2.db.attemptsOf(kid)).length, 6, reason: 'the other phone has every good answer');
    });

    test(
      'a failure during the one-by-one retry marks nothing as refused and leaves the rest for the next round',
      () async {
        await s1.answer('Not An Id', 'correct');
        await s1.answer('a.1', 'correct', minute: 1);
        await s1.answer('a.2', 'correct', minute: 2);
        // The batch and the bad row are refused before anything is done, so the answer lost is that of the first good row.
        strict.loseAnswerOf = 'sync-push';
        final SyncReport first = await s1.engine.syncOnce();
        expect(first.refusedEvents, 0);
        expect(
          (await s1.db.unsyncedAttempts()).length,
          3,
          reason: 'the round stopped: everything is still to send',
        );
        final SyncReport second = await s1.engine.syncOnce();
        expect(second.refusedEvents, 1);
        expect(await s1.db.unsyncedAttempts(), isEmpty);
        expect(strict.log.length, 2, reason: 'the row taken before the lost answer is not doubled');
      },
    );

    test(
      'an answer written by an older version with a code outside the pattern goes without its code',
      () async {
        await s1.answer('x.mathb15.1', 'incorrect', response: '3:30');
        await s1.answer('b.logb08.1', 'incorrect', response: 'i1>b2', minute: 1);
        await s1.answer('a.1', 'correct', response: 'o2', minute: 2);
        final SyncReport r = await s1.engine.syncOnce();
        expect(r.pushedEvents, 3);
        expect(r.refusedEvents, 0);
        expect(
          strict.log.map((Map<String, Object?> e) => (e['data']! as Map<String, Object?>)['response']),
          <String>['', '', 'o2'],
        );
      },
    );

    List<Attempt> refused(List<Attempt> rows) =>
        rows.where((Attempt a) => AppDatabase.wasRefusedBySync(a.syncedAt)).toList();

    test('a server that refuses every event of a batch does not know the format of this app: nothing is marked refused, the round gives up', () async {
      // A gateway that does not know a key every answer carries (deployed too early, or with the field removed).
      strict.forgets = <String>{'duration_ms'};
      for (int i = 1; i <= 6; i++) {
        await s1.answer('a.$i', 'correct', minute: i);
      }
      final int before = pushes();
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.refusedEvents, 0);
      expect(r.pushedEvents, 0);
      expect(
        pushes() - before,
        (1 + 4) + (1 + 2),
        reason: 'the first batch and its four events one by one, then the last two looked at the same way, and no more',
      );
      expect(refused(await s1.db.attemptsOf(kid)), isEmpty, reason: 'no row is marked refused');
      expect((await s1.db.unsyncedAttempts(limit: 100)).length, 6, reason: 'all six wait for the next round');

      // The gateway that knows the key is deployed: once the wait is over everything goes, nothing was lost.
      strict.forgets = <String>{};
      s1.clock += SyncEngine.stallBase.inMilliseconds;
      final SyncReport next = await s1.engine.syncOnce();
      expect(next.pushedEvents, 6);
      expect(await s1.db.unsyncedAttempts(limit: 100), isEmpty);
    });

    test(
      'a lone event refused before the server took anything this round is not marked refused either',
      () async {
        strict.forgets = <String>{'duration_ms'};
        await s1.answer('a.1', 'correct');
        await s1.engine.syncOnce();
        expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
        expect((await s1.db.unsyncedAttempts()).length, 1);
      },
    );

    test(
      'a lone event refused after the server took a batch of the same round is a bad row, and is marked',
      () async {
        for (int i = 1; i <= 4; i++) {
          await s1.answer('a.$i', 'correct', minute: i);
        }
        await s1.answer('Not An Id', 'correct', minute: 9);
        final SyncReport r = await s1.engine.syncOnce();
        expect(r.pushedEvents, 4);
        expect(r.refusedEvents, 1);
        expect(refused(await s1.db.attemptsOf(kid)).single.activityId, 'Not An Id');
        expect(await s1.db.unsyncedAttempts(), isEmpty);
      },
    );

    test('rows refused under an older format are sent again once, after the wire format changes (not the engine version)', () async {
      // A visit that is not over is not sent: its answer carries its number, which this gateway does not know.
      final int open = await s1.db.startSession(
        kid,
        DateTime.utc(2026, 11, 20, 10),
        plan: 'lesson:butterflies',
      );
      await s1.answer('a.1', 'correct', session: open);
      await s1.answer('a.2', 'correct', minute: 1);
      await s1.answer('Not An Id', 'correct', minute: 2);
      strict.forgets = <String>{'session_local'};
      await s1.engine.syncOnce();
      expect(refused(await s1.db.attemptsOf(kid)).map((Attempt a) => a.activityId), <String>[
        'a.1',
        'Not An Id',
      ]);
      expect(strict.log.length, 1);

      // The right gateway is deployed; the same wire format does not send them again, whatever the engine version.
      strict.forgets = <String>{};
      final int before = pushes();
      await s1.engine.syncOnce();
      SyncEngine of({int engineVersion = 1, int wireFormat = SyncEngine.currentWireFormat}) => SyncEngine(
        db: s1.db,
        call: strict.callFor(dev1),
        deviceId: dev1,
        isParent: true,
        nowMs: () => noon,
        engineVersion: engineVersion,
        wireFormat: wireFormat,
        pageSize: 4,
        batch: 4,
      );
      await of(engineVersion: 7).syncOnce();
      expect(pushes(), before, reason: 'a new engine version alone resets nothing');

      // A new wire format: the refused rows are sent once more. The answer of the visit gets in; the bad row is refused again.
      final SyncEngine upgraded = of(wireFormat: SyncEngine.currentWireFormat + 1);
      final SyncReport r = await upgraded.syncOnce();
      expect(r.pushedEvents, 1);
      expect(r.refusedEvents, 1);
      expect(strict.log.length, 2);
      expect(refused(await s1.db.attemptsOf(kid)).single.activityId, 'Not An Id');
      final int after = pushes();
      await upgraded.syncOnce();
      expect(pushes(), after, reason: 'reset once per wire format, not every round');
    });

    // QA-18: rows that are bad on their own, a whole batch of them, head the queue (here an activity id that sync-push
    // refuses; a clock before 2017 is no longer such a cause, the time is set right at the boundary: SEC-B20-1).
    Future<void> badAnswers(int n) async {
      for (int i = 1; i <= n; i++) {
        await s1.answer('Not An Id $i', 'correct', minute: i);
      }
    }

    Future<void> oldClockAnswers(int n) async {
      for (int i = 1; i <= n; i++) {
        await s1.answer('old.$i', 'correct', at: DateTime.utc(2010, 1, 1, 10, i));
      }
    }

    Iterable<Object?> sentIds() =>
        strict.log.map((Map<String, Object?> e) => (e['data']! as Map<String, Object?>)['activity_id']);

    test(
      'QA-18 a whole batch of bad rows is set aside and the answers after it go in the same round',
      () async {
        await badAnswers(4);
        for (int i = 1; i <= 3; i++) {
          await s1.answer('a.$i', 'correct', minute: 10 + i);
        }
        final SyncReport r = await s1.engine.syncOnce();
        expect(r.pushedEvents, 3);
        expect(r.refusedEvents, 4);
        expect(sentIds(), <String>['a.1', 'a.2', 'a.3']);
        expect(refused(await s1.db.attemptsOf(kid)).map((Attempt a) => a.activityId), <String>[
          'Not An Id 1',
          'Not An Id 2',
          'Not An Id 3',
          'Not An Id 4',
        ]);
        expect(await s1.db.unsyncedAttempts(limit: 100), isEmpty);
        final int before = pushes();
        await s1.engine.syncOnce();
        expect(pushes(), before, reason: 'the bad rows are not looked at again');
      },
    );

    test('QA-18 a visit and an award that are bad on their own are set aside too', () async {
      // A visit with a plan the server refuses, and an award with a key it refuses, ahead of a good answer, a good visit and
      // award.
      final int old = await s1.db.startSession(kid, DateTime.utc(2026, 11, 20, 9), plan: 'Not A Plan');
      await s1.db.endSession(old, DateTime.utc(2026, 11, 20, 9, 5), 'finished');
      await s1.db.addReward(
        RewardsCompanion.insert(
          profileId: kid,
          awardKey: 'star:bad key',
          kind: 'star',
          at: DateTime.utc(2026, 11, 20, 9, 6),
        ),
      );
      await s1.answer('a.1', 'correct');
      final int visit = await s1.visit();
      await s1.db.addReward(
        RewardsCompanion.insert(
          profileId: kid,
          awardKey: 'star:NUM-A-04',
          kind: 'star',
          at: DateTime.utc(2026, 11, 20, 11),
        ),
      );
      // Nothing of the kinds visit or award has been taken yet in this round, so each bad one waits for its verdict: the
      // good visit and the good award of the same round give it.
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.pushedEvents, 3, reason: 'the answer, the good visit and the good award');
      expect(r.refusedEvents, 2);
      expect(strict.log.map((Map<String, Object?> e) => e['type']).toSet(), <String>{
        'attempt',
        'session',
        'reward',
      });
      expect(visit, greaterThan(old));
      expect(
        AppDatabase.wasRefusedBySync(
          (await s1.db.sessionsOf(kid)).firstWhere((Session x) => x.id == old).syncedAt,
        ),
        isTrue,
      );
      expect(
        AppDatabase.wasRefusedBySync(
          (await s1.db.rewardsOf(kid)).firstWhere((Reward x) => x.awardKey == 'star:bad key').syncedAt,
        ),
        isTrue,
      );
    });

    test('QA-18 a round gives up on a kind when even its newest row is refused, and it costs a bounded number of calls', () async {
      await badAnswers(9);
      final int before = pushes();
      final SyncReport r = await s1.engine.syncOnce();
      expect(
        pushes() - before,
        2 * (1 + 4) + 2,
        reason: 'two batches, each looked at event by event, then the newest row alone (refused as a batch of one, and again)',
      );
      expect(r.pushedEvents, 0);
      expect(r.refusedEvents, 0, reason: 'no verdict: nothing is marked');
      expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
      expect((await s1.db.unsyncedAttempts(limit: 100)).length, 9);
    });

    test('SEC-B20-1 a good answer behind more bad rows than a round looks at is sent, and the bad rows are set aside', () async {
      await badAnswers(8);
      await s1.answer('a.1', 'correct', minute: 20);
      final int before = pushes();
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.pushedEvents, 1);
      expect(r.refusedEvents, 8);
      expect(sentIds(), <String>['a.1']);
      expect(
        pushes() - before,
        2 * (1 + 4) + 1,
        reason: 'two batches looked at one by one, then the probe is taken',
      );
      expect(refused(await s1.db.attemptsOf(kid)).length, 8);
      expect(await s1.db.unsyncedAttempts(limit: 100), isEmpty);
    });

    test('SEC-B20-1 more bad rows than a round looks at, ahead of a good answer, never stop the good answer for good', () async {
      for (int i = 1; i <= 9; i++) {
        await s1.answer('Not An Id $i', 'correct', minute: i); // an activity id sync-push refuses
      }
      await s1.answer('a.1', 'correct', minute: 20);
      for (int r = 0; r < 3; r++) {
        await s1.engine.syncOnce();
        s1.clock += SyncEngine.stallCap.inMilliseconds;
      }
      expect(sentIds(), contains('a.1'));
      expect(refused(await s1.db.attemptsOf(kid)).length, 9);
    });

    test('SEC-B20-1 answers timed before 2017 are re-timed, not refused: all go in the first round, in the server\'s range', () async {
      await oldClockAnswers(9);
      await s1.answer('a.1', 'correct', minute: 20);
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.pushedEvents, 10);
      expect(r.refusedEvents, 0);
      expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
      for (final Map<String, Object?> e in strict.log) {
        expect(e['at']! as int, inInclusiveRange(SyncEngine.minClientMs, noon));
      }
      // The phone keeps the time it had.
      expect(
        (await s1.db.attemptsOf(kid)).where((Attempt a) => a.activityId == 'old.1').single.at.toUtc(),
        DateTime.utc(2010, 1, 1, 10, 1),
      );
    });

    test('SEC-B20-1 a time before 2017 keeps its place by the phone\'s offset from the server\'s time; the future is held at the server\'s time', () async {
      const int hour = 3600000;
      final int floor = SyncEngine.minClientMs;
      // The phone's clock reads 2010 while the server's reads 2026: times before 2017 are shifted by the difference.
      final int wrongNow = DateTime.utc(2010, 1, 1, 12).millisecondsSinceEpoch;
      final SyncEngine engine = SyncEngine(
        db: s1.db,
        call: strict.callFor(dev1),
        deviceId: dev1,
        isParent: true,
        nowMs: () => wrongNow,
        serverNowMs: () => noon,
        pageSize: 4,
        batch: 4,
      );
      await s1.answer('x.1', 'correct', at: DateTime.utc(2010, 1, 1, 10));
      await s1.answer('x.2', 'correct', at: DateTime.utc(2010, 1, 1, 11));
      await s1.answer('x.3', 'correct', at: DateTime.utc(1970));
      await s1.answer('x.4', 'correct', at: DateTime.utc(2099));
      await s1.answer('x.5', 'correct', at: DateTime.fromMillisecondsSinceEpoch(floor, isUtc: true));
      final int visit = await s1.db.startSession(
        kid,
        DateTime.utc(2010, 1, 1, 10),
        plan: 'lesson:butterflies',
      );
      await s1.db.endSession(visit, DateTime.utc(2010, 1, 1, 10, 8), 'finished');
      await engine.syncOnce();
      final Map<Object?, int> times = <Object?, int>{
        for (final Map<String, Object?> e in strict.log)
          if (e['type'] == 'attempt') (e['data']! as Map<String, Object?>)['activity_id']: e['at']! as int,
      };
      final int offset = noon - wrongNow;
      expect(times['x.1'], DateTime.utc(2010, 1, 1, 10).millisecondsSinceEpoch + offset);
      expect(times['x.2']! - times['x.1']!, hour, reason: 'the spacing is kept');
      expect(times['x.3'], floor, reason: '1970 plus the offset is still before 2017: held at the floor');
      expect(times['x.4'], noon, reason: 'a time ahead of the server is held at its time');
      expect(times['x.5'], floor, reason: 'the floor itself is not moved');
      final Map<String, Object?> session = strict.log.singleWhere(
        (Map<String, Object?> e) => e['type'] == 'session',
      );
      final Map<String, Object?> data = session['data']! as Map<String, Object?>;
      expect(data['started_at'], DateTime.utc(2010, 1, 1, 10).millisecondsSinceEpoch + offset);
      expect(session['at'], data['started_at']);
      expect(
        (data['ended_at']! as int) - (data['started_at']! as int),
        8 * 60000,
        reason: 'start and end move together',
      );
    });

    test('SEC-B20-1 a visit whose end is held by the server\'s time never ends before it starts', () async {
      final int visit = await s1.db.startSession(
        kid,
        DateTime.utc(2026, 11, 20, 11, 59),
        plan: 'lesson:butterflies',
      );
      await s1.db.endSession(visit, DateTime.utc(2026, 11, 20, 12, 40), 'finished');
      await s1.engine.syncOnce();
      final Map<String, Object?> data = strict.log.single['data']! as Map<String, Object?>;
      expect(data['started_at'], DateTime.utc(2026, 11, 20, 11, 59).millisecondsSinceEpoch);
      expect(data['ended_at'], noon, reason: 'held at the server\'s time');
      expect((data['ended_at']! as int) >= (data['started_at']! as int), isTrue);
    });

    test('R1 the brake is held per kind of event: a visit the server takes does not make the answers of its batch bad rows', () async {
      // A gateway that does not know a key every answer carries but takes the visit that comes with them.
      final int visit = await s1.visit();
      for (int i = 1; i <= 3; i++) {
        await s1.answer('a.$i', 'correct', session: visit, minute: i);
      }
      strict.forgets = <String>{'duration_ms'};
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.pushedEvents, 1, reason: 'the visit');
      expect(r.refusedEvents, 0);
      expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
      expect((await s1.db.unsyncedAttempts()).length, 3);
      expect(await s1.db.unsyncedSessions(), isEmpty, reason: 'the visit went');
    });

    test(
      'R1 and the other way: answers the server takes do not make the visit it will not take a bad row',
      () async {
        final int visit = await s1.visit();
        for (int i = 1; i <= 3; i++) {
          await s1.answer('a.$i', 'correct', session: visit, minute: i);
        }
        // This gateway does not know a key of a visit.
        strict.forgets = <String>{'end_reason'};
        final SyncReport r = await s1.engine.syncOnce();
        expect(r.pushedEvents, 3);
        expect(r.refusedEvents, 0);
        expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
        expect((await s1.db.sessionsOf(kid)).single.syncedAt, isNull, reason: 'the visit waits');
        strict.forgets = <String>{};
        s1.clock += SyncEngine.stallBase.inMilliseconds;
        final SyncReport next = await s1.engine.syncOnce();
        expect(next.pushedEvents, 1);
        expect((await s1.db.sessionsOf(kid)).single.syncedAt, isNotNull);
      },
    );

    Future<int> round() async {
      final int before = pushes();
      await s1.engine.syncOnce();
      return pushes() - before;
    }

    const int minute = 60000;

    test(
      'the wait after a stalled round: no sync-push call until it is over; it doubles up to an hour',
      () async {
        expect(
          <Duration>[
            for (final int n in <int>[1, 2, 3, 4, 5, 6, 50]) SyncEngine.stallWait(n),
          ],
          <Duration>[
            const Duration(minutes: 5),
            const Duration(minutes: 10),
            const Duration(minutes: 20),
            const Duration(minutes: 40),
            const Duration(hours: 1),
            const Duration(hours: 1),
            const Duration(hours: 1),
          ],
        );
        strict.forgets = <String>{'duration_ms'};
        await s1.answer('a.1', 'correct');
        expect(await round(), 2, reason: 'the event, and the same event alone');
        for (final int wait in <int>[5, 10, 20, 40, 60, 60]) {
          s1.clock += (wait - 1) * minute;
          expect(await round(), 0, reason: 'a minute before the end of a wait of $wait minutes');
          s1.clock += minute;
          expect(
            await round(),
            2,
            reason: 'the wait of $wait minutes is over: one more look, which stalls again',
          );
        }
        expect((await s1.db.unsyncedAttempts()).length, 1, reason: 'nothing was lost or marked');
        expect(refused(await s1.db.attemptsOf(kid)), isEmpty);

        // The gateway is right at last: the next look after the wait sends it, and the wait is forgotten.
        strict.forgets = <String>{};
        s1.clock += 60 * minute;
        expect((await s1.engine.syncOnce()).pushedEvents, 1);
        strict.forgets = <String>{'duration_ms'};
        await s1.answer('a.2', 'correct', minute: 2);
        expect(await round(), 2);
        s1.clock += 4 * minute;
        expect(await round(), 0, reason: 'a new stall waits five minutes again, not an hour');
        s1.clock += minute;
        expect(await round(), 2);
      },
    );

    test('a stalled round does not stop the family from coming in, and a clock that went back does not hold the sync', () async {
      strict.forgets = <String>{'duration_ms'};
      await s1.answer('a.1', 'correct');
      expect(await round(), 2);
      expect(await round(), 0);

      // Another phone of the family sends an answer (this gateway takes it now).
      strict.forgets = <String>{};
      await s2.engine.syncOnce();
      await s2.answer('b.1', 'correct');
      await s2.engine.syncOnce();
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.pulledEvents, 1);
      expect(r.appliedEvents, 1);
      expect(r.pushedEvents, 0);

      // The phone's clock was set back by a day: the wait is not kept for a day.
      s1.clock -= 24 * 60 * minute;
      expect((await s1.engine.syncOnce()).pushedEvents, 1);
    });

    test('R2 the engine version of the events is never what resets the markers; a build that had the old key resets once under the new one', () async {
      await s1.answer('Not An Id', 'correct');
      await s1.answer('a.1', 'correct', minute: 1);
      await s1.engine.syncOnce();
      expect(refused(await s1.db.attemptsOf(kid)).single.activityId, 'Not An Id');
      expect(strict.log.single['engine'], 1);
      // What a build before the wire format left behind: its key, at the engine version.
      await s1.db.putSetting('sync_refused_reset_version', '1');
      await s1.db.putSetting('sync_refused_reset_format', '');
      // The row is sent once more, under the new key, with a new answer that the server takes: refused again.
      await s1.answer('a.2', 'correct', minute: 2);
      final int before = pushes();
      final SyncReport r = await s1.engine.syncOnce();
      expect(pushes() - before, 1 + 2, reason: 'the two rows, then each alone');
      expect(r.refusedEvents, 1);
      expect(refused(await s1.db.attemptsOf(kid)).single.activityId, 'Not An Id');
      await s1.engine.syncOnce();
      expect(pushes() - before, 1 + 2, reason: 'and once only');
    });

    test(
      'SEC-B20-3 in the wait after a stall only the kind that stalled waits: the others go on as usual',
      () async {
        await s1.db.addReward(
          RewardsCompanion.insert(
            profileId: kid,
            awardKey: 'star:bad key',
            kind: 'star',
            at: DateTime.utc(2026, 11, 20, 10),
          ),
        );
        await s1.answer('a.1', 'correct');
        final SyncReport first = await s1.engine.syncOnce();
        expect(first.pushedEvents, 1, reason: 'the answer; the award has no award to give it a verdict');
        expect((await s1.db.unsyncedRewards()).length, 1);

        s1.clock += minute;
        await s1.answer('a.2', 'correct', minute: 2);
        final int before = pushes();
        final SyncReport second = await s1.engine.syncOnce();
        expect(second.pushedEvents, 1, reason: 'today 0: every push waited');
        expect(pushes() - before, 1, reason: 'the award is not asked about during the wait');

        s1.clock += 4 * minute;
        expect(
          await round(),
          2,
          reason: 'five minutes after the stall: the award is looked at again, and stalls again',
        );
        s1.clock += 9 * minute;
        expect(await round(), 0, reason: 'the wait after the second stall is ten minutes');
      },
    );

    test(
      'SEC-B20-4 the suspect batches are one budget for the whole round, and the probes are bounded',
      () async {
        strict.forgets = <String>{'duration_ms', 'end_reason', 'kind'};
        for (int i = 1; i <= 8; i++) {
          await s1.answer('a.$i', 'correct', minute: i);
          final int v = await s1.db.startSession(
            kid,
            DateTime.utc(2026, 11, 20, 10, i),
            plan: 'lesson:butterflies',
          );
          await s1.db.endSession(v, DateTime.utc(2026, 11, 20, 10, i, 30), 'finished');
          await s1.db.addReward(
            RewardsCompanion.insert(
              profileId: kid,
              awardKey: 'star:NUM-A-0$i',
              kind: 'star',
              at: DateTime.utc(2026, 11, 20, 10, i),
            ),
          );
        }
        final int before = pushes();
        final SyncReport r = await s1.engine.syncOnce();
        expect(r.pushedEvents, 0);
        expect(r.refusedEvents, 0);
        expect(
          pushes() - before,
          lessThanOrEqualTo(2 * (1 + 4) + 3 * 2),
          reason: 'two suspect batches in all, then at most one probe (two calls) for each kind',
        );
        expect(await s1.db.setting('sync_stall'), '1,${s1.clock},attempt+reward+session');
        expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
        expect((await s1.db.unsyncedSessions(limit: 100)).length, 8);
        expect((await s1.db.unsyncedRewards(limit: 100)).length, 8);
      },
    );

    test('SEC-B20-5 a stall setting with a count of 0 or less, or one that is not understood, does not stop the pushes', () async {
      expect(SyncEngine.stallWait(0), SyncEngine.stallBase);
      expect(SyncEngine.stallWait(-7), SyncEngine.stallBase);
      for (final String bad in <String>[
        '0,${s1.clock},attempt',
        '-3,${s1.clock},attempt',
        '1,x,attempt',
        '1,${s1.clock},nothing',
        '1,${s1.clock}',
      ]) {
        await s1.db.putSetting('sync_stall', bad);
        await s1.answer('a.${bad.hashCode}', 'correct');
        expect((await s1.engine.syncOnce()).pushedEvents, 1, reason: bad);
      }
    });

    test(
      'SEC-B20-7 a bad_request that is not a 400 is a failure, not a bad row: nothing is marked',
      () async {
        await s1.answer('a.1', 'correct');
        final SyncEngine odd = SyncEngine(
          db: s1.db,
          call: (String name, Map<String, Object?> body) async {
            if (name == 'sync-push') throw const GatewayException('bad_request', status: 502);
            return strict.callFor(dev1)(name, body);
          },
          deviceId: dev1,
          isParent: true,
          nowMs: () => noon,
          pageSize: 4,
          batch: 4,
        );
        final int before = pushes();
        final SyncReport r = await odd.syncOnce();
        expect(r.refusedEvents, 0);
        expect(refused(await s1.db.attemptsOf(kid)), isEmpty);
        expect((await s1.db.unsyncedAttempts()).length, 1);
        expect(
          pushes(),
          before,
          reason: 'the fake server saw no sync-push; the one-by-one retry was not tried either',
        );
      },
    );

    test('every kind of event the app makes fits every key, value and range that sync-push takes', () async {
      final String longest = 'l' * 40;
      final int visit = await s1.visit();
      final int mission = await s1.db.startSession(
        kid,
        DateTime.utc(2026, 11, 20, 11),
        plan: 'mission:num-a-03',
      );
      await s1.db.endSession(mission, DateTime.utc(2026, 11, 20, 11, 5), 'home');
      final int rest = await s1.db.startSession(kid, DateTime.utc(2026, 11, 20, 12), plan: 'lesson:$longest');
      await s1.db.endSession(rest, DateTime.utc(2026, 11, 20, 12, 30), 'limit');
      await s1.db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 11, 20, 10, 1),
          profileId: kid,
          packId: 'starter',
          packVersion: '0.8.0',
          lessonId: Value<String>(longest),
          activityId: 'a${'.' * 80}',
          activityRevision: 9999,
          template: 'shape_builder',
          templateVersion: '1.0',
          skillId: 'NUM-A-03',
          result: 'unsure',
          attemptNo: 5,
          hintLevel: 3,
          misconceptionTag: const Value<String>('M-CNT-DOUBLE'),
          response: const Value<String>('t0-b4.t1-b3.t2-b2.t3-b1.t4-b0'),
          // A question left open for two hours: the server takes at most one.
          durationMs: const Value<int>(2 * 3600000),
          sessionId: Value<int?>(visit),
          input: const Value<String>('voice'),
        ),
      );
      // An answer of a revisit mission written by an older version, whose lesson id had the skill's capitals.
      await s1.db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 11, 20, 11, 1),
          profileId: kid,
          packId: 'starter',
          packVersion: '0.8.0',
          lessonId: const Value<String>('mission-NUM-A-03'),
          activityId: 'a.1',
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'NUM-A-03',
          result: 'incorrect',
          attemptNo: 1,
          hintLevel: 0,
          sessionId: Value<int?>(mission),
        ),
      );
      final List<(AwardKind, String)> awards = <(AwardKind, String)>[
        (AwardKind.sticker, Awards.sticker(longest, 9999)),
        (AwardKind.star, Awards.star('NUM-A-03')),
        for (final TrophyLand land in TrophyLand.values)
          for (final TrophyTier tier in TrophyTier.values) (AwardKind.trophy, Awards.trophy(land, tier)),
        for (final MedalDef m in medalDefs) (AwardKind.medal, Awards.medal(m.id)),
        for (final int n in decorationSteps) (AwardKind.decoration, Awards.decoration(n)),
      ];
      for (final (AwardKind kind, String key) in awards) {
        await s1.db.addReward(
          RewardsCompanion.insert(
            profileId: kid,
            awardKey: key,
            kind: kind.name,
            at: DateTime.utc(2026, 11, 20, 13),
          ),
        );
      }
      final SyncReport r = await s1.engine.syncOnce();
      expect(r.refusedEvents, 0);
      expect(r.pushedEvents, 3 + 2 + awards.length);
      final Map<String, Object?> lessons = <String, Object?>{
        for (final Map<String, Object?> e in strict.log)
          if (e['type'] == 'attempt')
            (e['data']! as Map<String, Object?>)['activity_id']! as String:
                (e['data']! as Map<String, Object?>)['lesson_id'],
      };
      expect(lessons['a.1'], 'mission-num-a-03', reason: 'the same id a mission is given now');
    });
  });
}
