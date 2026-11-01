// Board B-32: the follow-ups of the B-28 security review. One `safeChildName` for the form, what goes to the server,
// what comes back from it and the home island's words; the sync guard that keeps a child's rows unsent until the server
// has the child; `Str.fill` in one pass. (The shared vectors are in child_name_test.dart; QA-B28-1 to 3 in
// qa_b28_test.dart.)
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart' show Key, Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/child_name.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/parent/progress_screen.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/app_harness.dart';
import 'support/fake_family_server.dart';
import 'support/harness.dart';
import 'sync_engine_test.dart' show Phone, dev1, dev2, kid;

const String _otherKid = 'child-bbbb-0002';

Future<void> _addOther(Phone p, String name) => p.db.addProfile(
  ProfilesCompanion.insert(
    id: _otherKid,
    name: name,
    avatar: 'avatar-noa',
    addressForm: 'f',
    ageBand: 1,
    createdAt: DateTime.utc(2026, 11, 1),
  ),
);

Future<void> _raise(Phone p, String key, {String? child = kid, String category = 'frustration'}) =>
    p.db.addAlert(
      AlertsCompanion.insert(
        at: DateTime.utc(2026, 11, 20, 11),
        profileId: Value<String?>(child),
        category: category,
        severity: 'attention',
        dedupeKey: key,
      ),
    );

Future<void> _answerOf(Phone p, String child, {int minute = 0}) => p.db.recordAttempt(
  AttemptsCompanion.insert(
    at: DateTime.utc(2026, 11, 20, 10, minute),
    profileId: child,
    packId: 'starter',
    packVersion: '0.2.0',
    activityId: 'A.1',
    activityRevision: 1,
    template: 'count_tap',
    templateVersion: '1.0',
    skillId: 'SK-A-01',
    result: 'correct',
    attemptNo: minute + 1,
    hintLevel: 0,
  ),
);

Future<void> _award(Phone p, String child, String key) => p.db.addReward(
  RewardsCompanion.insert(
    profileId: child,
    awardKey: key,
    kind: 'trophy',
    at: DateTime.utc(2026, 11, 20, 10),
  ),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('safeChildName', () {
    test('a clean name comes back unchanged, Hebrew with nikud, dagesh and a three-mark stack too', () {
      for (final String name in <String>[
        'נועה',
        'נֹעָה',
        'בִּנְיָמִין',
        'כֹּהֵן',
        'נועה כהן',
        'Noa',
        'ש\u05bc\u05c1\u05b8', // shin, dagesh, shin dot, qamats
      ]) {
        expect(safeChildName(name), name);
        expect(validateChildName(name), ChildNameProblem.ok, reason: name);
      }
    });

    test('zero-width and format characters go, the Arabic letter mark among them', () {
      expect(safeChildName('נו\u200bע\u200dה\u200c'), 'נועה');
      expect(safeChildName('נו\u061cעה'), 'נועה');
      expect(safeChildName('נו\u00adעה\u2060\ufeff'), 'נועה');
      expect(safeChildName('\u202eנועה\u2069'), 'נועה');
    });

    test('tag characters go whole, both halves of the pair', () {
      expect(safeChildName('נועה\u{E0041}\u{E0042}'), 'נועה');
    });

    test('a lone surrogate goes, a pair stays', () {
      expect(safeChildName('ab\ud800'), 'ab');
      expect(safeChildName('ab\udc00cd'), 'abcd');
      expect(safeChildName('a\u{1F338}b'), 'a\u{1F338}b');
      expect(safeChildName('\u{1F338}\ud83c'), '\u{1F338}');
    });

    test('four or more combining marks in a row: only the first three stay, per base letter', () {
      expect(safeChildName('נ\u05b0\u05b1\u05b2\u05b3\u05b4'), 'נ\u05b0\u05b1\u05b2');
      // Three marks on each of two letters are fine: the count starts again at each letter.
      const String two = 'ש\u05bc\u05c1\u05b8ש\u05bc\u05c1\u05b8';
      expect(safeChildName(two), two);
      expect(validateChildName('נ\u05b0\u05b1\u05b2\u05b3'), ChildNameProblem.badChars);
    });

    test('private-use characters, noncharacters and the grapheme joiner go (SEC-B32-1)', () {
      expect(safeChildName('נו\u{E000}עה\u{F8FF}'), 'נועה');
      expect(safeChildName('נו\u{FFFF}\u{FFFE}עה\u{FDD0}\u{FDEF}'), 'נועה');
      expect(safeChildName('נו\u{1FFFE}\u{10FFFF}עה'), 'נועה');
      expect(safeChildName('נו\u{F0000}עה'), 'נועה');
      expect(safeChildName('נו\u{34F}עה'), 'נועה');
      expect(
        safeChildName('נו\u{FFFD}עה'),
        'נו\u{FFFD}עה',
        reason: 'the replacement character is an ordinary symbol',
      );
    });

    test('a combining mark with no character before it goes: at the start, or after a space', () {
      expect(safeChildName('\u{5B0}נועה'), 'נועה');
      expect(safeChildName('נועה \u{5B0}\u{5B1}כהן'), 'נועה כהן');
      expect(safeChildName('\u{5B0}\u{5B1}'), '');
      expect(safeChildName('נֹעָה כֹּהֵן'), 'נֹעָה כֹּהֵן');
      expect(validateChildName('\u{5B0}נועה'), ChildNameProblem.badChars);
    });

    test('a name with no visible character is empty', () {
      for (final String blank in <String>[
        '\u200b',
        '\u200b\u200b\u2060',
        '\u2800',
        '\u3164',
        '\u00ad',
        ' \u00a0 ',
        '\u05b0\u05b1',
        '\u{E0041}',
        '\ud800',
        '<>',
      ]) {
        expect(safeChildName(blank), '', reason: blank.codeUnits.toString());
        expect(fitChildNameForServer(blank), '');
      }
    });

    test('a name that is not clean is told apart from an empty one and a long one', () {
      expect(validateChildName('\u200b'), ChildNameProblem.badChars);
      expect(validateChildName('${'a' * 30}\u200b'), ChildNameProblem.badChars);
      expect(validateChildName('נו\ud800עה'), ChildNameProblem.badChars);
      expect(validateChildName(' \u00a0\u3000 '), ChildNameProblem.empty);
    });

    test('what goes to the server is clean, short enough and is what the form would accept', () {
      expect(fitChildNameForServer('נו\u200bעה\ud800'), 'נועה');
      final String sent = fitChildNameForServer('${'a' * 23}\u200b\u{1F338}');
      expect(sent, 'a' * 23);
      expect(validateChildName(sent), ChildNameProblem.ok);
    });
  });

  group('the home island\'s name uses the same rule', () {
    test(
      'invisible characters, a lone surrogate and a stack of marks are cleaned, white space stays a space',
      () {
        expect(homeIslandName('נו\u200bעה\ud800').name, 'נועה');
        expect(homeIslandName('נועה\u061c').name, 'נועה');
        expect(homeIslandName('נועה\nכהן').name, 'נועה כהן');
        expect(homeIslandName('נ\u05b0\u05b1\u05b2\u05b3').name, 'נ\u05b0\u05b1\u05b2');
        expect(homeIslandName('\u200b\u2800').isNamed, isFalse);
      },
    );
  });

  group('a name that comes back from the server (the pull)', () {
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

    test('is cleaned like a typed one, for a child this phone meets for the first time', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      server.children[kid]!['nickname'] = 'נו\u200bע\u061cה\ud800';
      await p2.engine.syncOnce();
      expect((await p2.db.allProfiles()).single.name, 'נועה');
    });

    test('with nothing visible left: a new child is not taken on, a known one keeps its name', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      server.children[kid]!['nickname'] = '\u200b\u200b';
      final SyncReport first = await p2.engine.syncOnce();
      expect(first.childrenAdded, 0);
      expect(await p2.db.allProfiles(), isEmpty);
      server.children[kid]!['nickname'] = 'נועה';
      await p2.engine.syncOnce();
      expect((await p2.db.allProfiles()).single.name, 'נועה');
      server.children[kid]!['nickname'] = '\u2800';
      await p2.engine.syncOnce();
      expect((await p2.db.allProfiles()).single.name, 'נועה');
    });
  });

  group('the sync guard: a child\'s rows wait until the server has the child', () {
    late FakeFamilyServer server;
    late Phone p1;

    setUp(() {
      server = FakeFamilyServer();
      p1 = Phone(dev1, server);
    });

    tearDown(() => p1.db.close());

    Future<void> makeRows() async {
      final int visit = await p1.visit();
      await p1.answer('A.1', 'correct', session: visit);
      await p1.answer('A.2', 'incorrect', session: visit, minute: 1, no: 2);
      await _award(p1, kid, 'trophy:1');
      await _raise(p1, 'upset:1');
    }

    test(
      'a failed child-put loses nothing: answers, visits, awards and alerts go after the first good one',
      () async {
        await p1.addChild();
        await makeRows();
        server.failing.add('child-put');
        await p1.engine.syncOnce();
        await p1.engine.syncOnce();
        expect(
          server.calls.where((String c) => c.endsWith(':sync-push')),
          isEmpty,
          reason: 'nothing was sent',
        );
        expect(server.calls.where((String c) => c.endsWith(':alert-create')), isEmpty);
        expect(await p1.db.unsyncedAttempts(), hasLength(2));
        expect(await p1.db.unsyncedSessions(), hasLength(1));
        expect(await p1.db.unsyncedRewards(), hasLength(1));
        expect(await p1.db.unsyncedAlerts(), hasLength(1));

        server.failing.clear();
        final SyncReport report = await p1.engine.syncOnce();
        expect(report.pushedEvents, 4, reason: '2 answers, 1 visit, 1 award');
        expect(report.pushedAlerts, 1);
        expect(server.log, hasLength(4));
        expect(server.alerts, hasLength(1));
        expect(await p1.db.unsyncedAttempts(), isEmpty);
        expect(await p1.db.unsyncedSessions(), isEmpty);
        expect(await p1.db.unsyncedRewards(), isEmpty);
        expect(await p1.db.unsyncedAlerts(), isEmpty);
      },
    );

    test('the child is saved in the same round, before its rows go (nothing waits a second round)', () async {
      await p1.addChild();
      await makeRows();
      final SyncReport report = await p1.engine.syncOnce();
      expect(report.pushedEvents, 4);
      expect(report.pushedAlerts, 1);
      expect(server.calls.indexOf('$dev1:child-put'), lessThan(server.calls.indexOf('$dev1:sync-push')));
    });

    test(
      'a child with no nickname to send stays held, the other child goes on, and a gate alert is not held',
      () async {
        await p1.addChild();
        await _addOther(p1, '\u200b\u2800'); // nothing visible: never sent, so never known to the server
        await p1.answer('A.1', 'correct');
        await p1.db.recordAttempt(
          AttemptsCompanion.insert(
            at: DateTime.utc(2026, 11, 20, 10, 5),
            profileId: _otherKid,
            packId: 'starter',
            packVersion: '0.2.0',
            activityId: 'A.1',
            activityRevision: 1,
            template: 'count_tap',
            templateVersion: '1.0',
            skillId: 'SK-A-01',
            result: 'correct',
            attemptNo: 1,
            hintLevel: 0,
          ),
        );
        await _raise(p1, 'upset:2', child: _otherKid);
        await _raise(p1, 'gate:1', child: null, category: 'gateAttempts');
        final SyncReport report = await p1.engine.syncOnce();
        expect(report.pushedEvents, 1, reason: 'the answer of the child the server has');
        expect(report.pushedAlerts, 1, reason: 'the gate alert; the other child\'s alert waits');
        final List<Attempt> waiting = await p1.db.unsyncedAttempts();
        expect(waiting.single.profileId, _otherKid);
        expect((await p1.db.unsyncedAlerts()).single.profileId, _otherKid);
        await p1.engine.syncOnce();
        expect(
          (await p1.db.unsyncedAttempts()).single.profileId,
          _otherKid,
          reason: 'held, never marked refused',
        );
      },
    );

    test(
      'a child made while a long round is still sending is held from the next batch on (SEC-B32-2)',
      () async {
        await p1.addChild();
        for (int i = 0; i < 9; i++) {
          await p1.answer('A.1', 'correct', minute: i, no: i + 1);
        }
        bool made = false;
        server.afterCall = (String name) async {
          if (name != 'sync-push' || made) return;
          made = true;
          await _addOther(p1, 'דנה');
          await _answerOf(p1, _otherKid);
          await _answerOf(p1, _otherKid, minute: 1);
        };
        final SyncReport report = await p1.engine.syncOnce();
        expect(made, isTrue);
        expect(report.pushedEvents, 9, reason: 'the first child only; batches are 4');
        expect(report.refusedEvents, 0, reason: 'nothing of the new child was sent to be refused');
        expect(await p1.db.unsyncedAttempts(limit: 100), hasLength(2));
        server.afterCall = null;
        await p1.engine.syncOnce();
        expect(await p1.db.unsyncedAttempts(limit: 100), isEmpty);
        expect(server.log, hasLength(11));
      },
    );

    test('a device that is not a parent holds nothing: its children came from the server', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      final Phone kidPhone = Phone('d3d3d3d3-0000-4000-8000-000000000003', server, parent: false);
      addTearDown(kidPhone.db.close);
      await kidPhone.engine.syncOnce();
      await kidPhone.answer('A.1', 'correct');
      final SyncReport report = await kidPhone.engine.syncOnce();
      expect(report.pushedEvents, 1);
    });
  });

  group('a name saved before the rule is shown cleaned, and stays as it is stored (SEC-B28-3)', () {
    setUpAll(loadAppFonts);

    // A zero-width space inside a name of an older version.
    const String stored = 'נו\u200bעה';
    const String shown = 'נועה';

    testWidgets('the picker, the parent list and the progress title show the clean name', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: stored);
      await rig.pump(tester);
      expect(find.text(stored), findsNothing);
      expect(find.text(shown), findsOneWidget, reason: 'the picker');
      await tester.tap(find.text(shown));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.homeParents.text));
      await tester.pumpAndSettle();
      await tapDigits(tester, '${rig.gateQuestion.answer}');
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      await tapDigits(tester, testPin);
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(find.byType(ParentArea), findsOneWidget);
      final Finder inList = find.descendant(of: find.byType(ParentArea), matching: find.text(shown));
      await tester.scrollUntilVisible(inList, 100, scrollable: find.byType(Scrollable).first);
      expect(inList, findsOneWidget);
      expect(find.text(stored), findsNothing);

      final String id = (await rig.db.allProfiles()).single.id;
      await tester.tap(find.byKey(Key('progress-$id')));
      await tester.pumpAndSettle();
      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(find.text(He.progressTitle.fill(<String, String>{'child': shown})), findsOneWidget);

      expect((await rig.db.allProfiles()).single.name, stored, reason: 'only what is shown is cleaned');
    });
  });

  group('Str.fill', () {
    test('puts the values in one pass: a value with braces in it is never filled again', () {
      const Str pattern = Str('{a} / {b}');
      expect(pattern.fill(<String, String>{'a': '{b}', 'b': 'x'}), '{b} / x');
      expect(pattern.fill(<String, String>{'a': '{a}', 'b': '{a}{b}'}), '{a} / {a}{b}');
    });

    test('a placeholder with no value stays as it is', () {
      const Str pattern = Str('{a} {b}');
      expect(pattern.fill(<String, String>{'a': '1'}), '1 {b}');
    });
  });
}
