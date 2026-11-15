// SEC-L7-1: an answer to an item that asks a word the child has just met writes no `attempt` (L7-3: first meeting is not evidence), but the
// parent's guessing and frustration alerts still see the child's taps and their pace, through a note kept on this phone and read by nothing else.
// A beginner in their first visit is the child most likely to be upset, and in lesson 1 of a unit most scored items ask that lesson's own words.
// The regression test is the one the review describes: eight wrong taps on first-meeting items inside half a minute, then home, give one
// frustration alert, and no row of evidence exists anywhere.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/behaviour_notes.dart';
import 'package:nitznutz/parent/alert_scan.dart';
import 'package:nitznutz/parent/alerts.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/security_fakes.dart' show ControlledClock;

const String _languages = '../content/languages';
const String _kid = 'p-1';

void main() {
  late PackContent rus;
  late AppDatabase db;
  late ControlledClock clock;
  late List<AttemptRecord> written;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    final Uint8List bytes = (await buildPack(languageSource('rus', _languages), key)).bytes;
    rus = PackContent.fromPack(await verifyPack(bytes, publicKey: key.publicKey));
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    clock = ControlledClock(DateTime.utc(2026, 11, 14, 10).millisecondsSinceEpoch);
    written = <AttemptRecord>[];
    await db.addProfile(
      ProfilesCompanion.insert(
        id: _kid,
        name: 'נועה',
        avatar: 'avatar-noa',
        addressForm: 'f',
        ageBand: 0,
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    );
  });
  tearDown(() => db.close());

  DateTime now() => DateTime.fromMillisecondsSinceEpoch(clock.nowMs(), isUtc: true);

  /// The lesson of the introduction visit with its answers going where the app sends them: evidence to the attempts, a note to the notes.
  Future<(LessonController, int)> open({String route = 'new'}) async {
    final int visit = await db.startSession(_kid, now(), plan: 'lesson:rus.family-1');
    final LessonController c = LessonController(
      content: rus,
      lesson: rus.lessons['rus.family-1']!,
      profileId: _kid,
      sessionId: visit,
      record: (AttemptRecord r) async => written.add(r),
      recordNote: (BehaviourNote n) => db.addBehaviourNote(_kid, n),
      clock: clock,
      route: route,
    );
    return (c, visit);
  }

  Future<void> pastScreens(LessonController c) async {
    while (c.current.teachScreen) {
      await c.sayItDone();
      c.next();
    }
  }

  String wrongOf(Activity a) {
    final ChoiceActivity choice = a as ChoiceActivity;
    return choice.options.firstWhere((ChoiceOption o) => o.id != choice.correctId).id;
  }

  Future<ChildHistory> history() async => ChildHistory(
    profileId: _kid,
    ageBand: 0,
    sessions: await db.sessionsOf(_kid),
    attempts: await db.attemptsOf(_kid),
    notes: await db.behaviourNotesOf(_kid),
  );

  /// Eight wrong taps, a third of a second apart (the child is tapping fast), on items that ask the words just met.
  Future<void> tapFast(LessonController c, {int taps = 8, int everyMs = 300}) async {
    for (int i = 0; i < taps; i++) {
      clock.advance(Duration(milliseconds: everyMs));
      await c.chooseOption(wrongOf(c.current));
    }
  }

  test('eight fast wrong taps on first-meeting items and then home are one frustration alert, and nothing is written as evidence', () async {
    final (LessonController c, int visit) = await open();
    await pastScreens(c);
    await tapFast(c);
    clock.advance(const Duration(seconds: 5));
    await db.endSession(visit, now(), 'home');
    c.dispose();

    expect(written, isEmpty, reason: 'the first meeting is no evidence: no attempt row');
    expect(await db.attemptsOf(_kid), isEmpty);
    expect(
      await runAlertScan(db, now: now().add(const Duration(minutes: 1)), rules: const ParentRules()),
      greaterThan(0),
    );
    final List<Alert> alerts = await db.allAlerts();
    expect(
      alerts.map((Alert a) => a.category),
      contains(AlertCategory.frustration.name),
      reason: 'the parent is told, as before L7-3',
    );
    expect(alerts.every((Alert a) => a.profileId == _kid), isTrue);
  });

  test('the same taps are one guessing alert too when four of six fast answers are wrong', () async {
    final (LessonController c, int visit) = await open();
    await pastScreens(c);
    for (int i = 0; i < 6; i++) {
      clock.advance(const Duration(milliseconds: 600));
      final ChoiceActivity item = c.current as ChoiceActivity;
      await c.chooseOption(i < 4 ? wrongOf(c.current) : item.correctId);
      if (c.solved) c.next();
    }
    await db.endSession(visit, now(), 'finished');
    c.dispose();
    final List<AlertDraft> drafts = behaviourAlerts(await history());
    expect(drafts.map((AlertDraft d) => d.category), contains(AlertCategory.guessing));
  });

  test('slow wrong taps are no alert: the notes carry the pace, not only the count', () async {
    final (LessonController c, int visit) = await open();
    await pastScreens(c);
    await tapFast(c, taps: 4, everyMs: 6000);
    await db.endSession(visit, now(), 'finished');
    c.dispose();
    expect(await db.behaviourNotesOf(_kid), hasLength(4));
    expect(behaviourAlerts(await history()), isEmpty);
  });

  test('the note holds the time, the result, the pace, the visit and the item, and the notes are the newest sixty', () async {
    final (LessonController c, int visit) = await open();
    await pastScreens(c);
    clock.advance(const Duration(milliseconds: 1200));
    final String itemId = c.current.id;
    await c.chooseOption(wrongOf(c.current));
    final BehaviourNote note = (await db.behaviourNotesOf(_kid)).single;
    expect(note.activityId, itemId);
    expect(note.result, 'incorrect');
    expect(note.sessionId, visit);
    expect(note.durationMs, 1200, reason: 'the time since the item came on screen');
    expect(note.at, now());
    c.dispose();
    for (int i = 0; i < behaviourNotesKept + 10; i++) {
      await db.addBehaviourNote(
        _kid,
        BehaviourNote(at: now(), activityId: 'a', result: 'correct', durationMs: i, sessionId: visit),
      );
    }
    final List<BehaviourNote> kept = await db.behaviourNotesOf(_kid);
    expect(kept, hasLength(behaviourNotesKept));
    expect(kept.last.durationMs, behaviourNotesKept + 9, reason: 'the oldest go');
  });

  test('the second tag of one move is not a second answer: a note is written once for it', () async {
    final (LessonController c, int visit) = await open();
    await pastScreens(c);
    clock.advance(const Duration(seconds: 1));
    await c.chooseOption(wrongOf(c.current));
    expect(await db.behaviourNotesOf(_kid), hasLength(1));
    await db.endSession(visit, now(), 'finished');
    c.dispose();
  });

  test('a later visit is scored as before and leaves no note: the evidence is the attempts', () async {
    final int visit = await db.startSession(_kid, now(), plan: 'lesson:rus.family-1');
    final LessonController c = LessonController(
      content: rus,
      lesson: rus.lessons['rus.family-1']!,
      profileId: _kid,
      sessionId: visit,
      record: (AttemptRecord r) async => written.add(r),
      recordNote: (BehaviourNote n) => db.addBehaviourNote(_kid, n),
      clock: clock,
      route: 'new',
      introVisit: false,
    );
    await pastScreens(c);
    await c.chooseOption(wrongOf(c.current));
    expect(written, hasLength(1), reason: 'scored as usual');
    expect(await db.behaviourNotesOf(_kid), isEmpty);
    c.dispose();
  });

  test('a heritage speaker is shown no Meet screen, so scored as ever, and no note', () async {
    final (LessonController c, _) = await open(route: 'heritage');
    await c.chooseOption(wrongOf(c.current));
    expect(written, hasLength(1));
    expect(await db.behaviourNotesOf(_kid), isEmpty);
    c.dispose();
  });

  test(
    'the notes are a setting of this phone, never a row of evidence, and they go with the child',
    () async {
      final (LessonController c, int visit) = await open();
      await pastScreens(c);
      await c.chooseOption(wrongOf(c.current));
      await db.endSession(visit, now(), 'finished');
      c.dispose();
      expect(await db.setting(behaviourNotesKey(_kid)), isNotNull);
      expect(
        await db.attemptsOf(_kid),
        isEmpty,
        reason: 'nothing reaches the engine, the progress or the outbox',
      );
      await db.deleteChildData(_kid);
      expect(await db.setting(behaviourNotesKey(_kid)), isNull);
    },
  );

  test('a damaged setting gives no notes and does not stop the alerts', () async {
    await db.putSetting(behaviourNotesKey(_kid), 'not json');
    expect(await db.behaviourNotesOf(_kid), isEmpty);
    await db.putSetting(behaviourNotesKey(_kid), '[[1,2,3],[4]]');
    expect(await db.behaviourNotesOf(_kid), isEmpty);
    expect(await runAlertScan(db, now: now(), rules: const ParentRules()), 0);
  });

  test('the notes never reach the family server: no file of the sync or the net mentions them', () {
    for (final String dir in <String>['lib/sync', 'lib/net']) {
      for (final FileSystemEntity e in Directory(dir).listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String source = e.readAsStringSync();
        expect(source.contains('behaviour_notes'), isFalse, reason: e.path);
        expect(source.contains('BehaviourNote'), isFalse, reason: e.path);
      }
    }
  });
}
