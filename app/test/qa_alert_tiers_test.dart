// QA's own checks of the word alerts in three tiers (docs/qa/alert-tiers-verification.md), separate from the
// developer's tests (alert_words_test.dart, alerts_test.dart, word_alert_text_test.dart, sync_engine_test.dart). Every
// row of docs/child-safety/alert-test-list.md is already a case there (the map is in the QA record); this file adds
// what they do not try:
// - the matcher against other spellings, orders, prefixes, gender forms, the geresh, Latin, odd characters, many
//   hypotheses, ages A against C, the guards, and a hostile 1,000-token answer for speed;
// - the cool-down across a restart, two children, two answers at once, the 30-minute and week edges;
// - two phones: one episode across devices, a count that only goes up, a replay, and exactly what is sent;
// - the parent texts as rendered (a Latin name, counts, every kind) and odd `detail` strings;
// - the wiring: the band of the child and the answers on screen reach the matcher from the real lesson.
// QA's defects QA-34 to QA-42, QA-45 and QA-47 were fixed on 2026-10-30 and their tests run as normal tests (they ran
// only with --dart-define=QA_OPEN=true while open).
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/net/gateway_client.dart';
import 'package:nitznutz/net/net_gate.dart';
import 'package:nitznutz/parent/alert_scan.dart';
import 'package:nitznutz/parent/alerts.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/parent/word_alert_text.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/speech/alert_lists.dart';
import 'package:nitznutz/speech/alert_words.dart';
import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/hebrew_text.dart';
import 'package:nitznutz/speech/voice_answer.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/app_harness.dart';
import 'support/fake_family_server.dart';
import 'support/fake_speech.dart';
import 'support/fakes.dart';
import 'support/harness.dart';

/// Left-to-right isolate, pop directional isolate, right-to-left mark (written as code points: the analyzer refuses
/// direction marks inside literals).
final String _lri = String.fromCharCode(0x2066);
final String _pdi = String.fromCharCode(0x2069);
final String _rlm = String.fromCharCode(0x200F);

const String kid = 'child-aaaa-0001';
const String dev1 = 'd1d1d1d1-0000-4000-8000-000000000001';
const String dev3 = 'd3d3d3d3-0000-4000-8000-000000000003';
final DateTime t0 = DateTime.utc(2026, 11, 20, 12);

WordMatch? at(String text, {int band = 1, Set<String> answers = const <String>{}}) =>
    checkWords(<String>[text], ageBand: band, answerWords: answers);

void expectTier(
  String text,
  int? tier, {
  String? rule,
  int band = 1,
  Set<String> answers = const <String>{},
}) {
  final WordMatch? m = at(text, band: band, answers: answers);
  expect(m?.tier, tier, reason: '"$text" in band $band (matched ${m?.rule})');
  if (rule != null) expect(m?.rule, rule, reason: '"$text"');
}

/// The server's shape of `alert-create` (supabase/functions/alert-create/handler.ts).
final RegExp serverDetail = RegExp(r'^[A-Za-z0-9._:=-]*$');
final RegExp serverWords = RegExp('^[֐-׿A-Za-z0-9 .,?!\'"-]*\$');
final RegExp serverKey = RegExp(r'^[A-Za-z0-9._:=-]{1,120}$');
const Set<String> alertFields = <String>{
  'child_id',
  'category',
  'severity',
  'count',
  'detail',
  'words',
  'key',
  'at',
};

/// One simulated phone with its own database.
class Phone {
  Phone(this.id, FakeFamilyServer server, {this.parent = true, SyncCall? call})
    : db = AppDatabase(NativeDatabase.memory()) {
    engine = SyncEngine(
      db: db,
      call: call ?? server.callFor(id, parent: parent),
      deviceId: id,
      isParent: parent,
      nowMs: () => t0.millisecondsSinceEpoch,
      pageSize: 4,
      batch: 4,
    );
  }

  final String id;
  final bool parent;
  final AppDatabase db;
  late final SyncEngine engine;

  Future<void> addChild() => db.addProfile(
    ProfilesCompanion.insert(
      id: kid,
      name: 'נועה',
      avatar: 'avatar-noa',
      addressForm: 'f',
      ageBand: 1,
      createdAt: DateTime.utc(2026, 11, 1),
    ),
  );

  Future<bool> say(String text, {Duration after = Duration.zero, int band = 1}) =>
      recordWordAlert(db, now: t0.add(after), profileId: kid, texts: <String>[text], ageBand: band);
}

Future<void> _wait(WidgetTester t, [int ms = 1500]) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

/// A child of [band] answers the spoken question of the starter pack by voice with [said], in the real app.
Future<List<Alert>> _spokenInLesson(WidgetTester tester, String said, int band) async {
  final AppRig rig = AppRig(voice: true, speech: FakeSpeechEngine(<Scripted>[Scripted.says(said)]));
  await rig.seedFinishedSetup(ageBand: band);
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await openActivities(tester, <String>['col.world.apple.red']);
  await tester.pumpAndSettle();
  expect(find.byType(ActivityFrame), findsOneWidget);
  await _wait(tester, 300);
  await tester.tap(find.byKey(const Key('lesson-mic')));
  await _wait(tester, 3000);
  return rig.db.allAlerts();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadAppFonts);

  group('the matcher: spellings, orders, prefixes and forms the developer did not try', () {
    final List<(String, int, String)> acts = <(String, int, String)>[
      ('לי ממש מרביצים', 1, 'W-01'), // "me" first, a filler, then the verb
      ('אותי כל יום מכים בגן', 1, 'W-01'), // three tokens apart, the far edge of the window
      ('ושמרביצים לי', 1, 'W-01'), // the prefix וש
      ('ומכים אותי', 1, 'W-01'), // the prefix ו
      ('הן מרביצות לי', 1, 'W-01'), // feminine plural
      ('ואבא מרביץ לי', 1, 'W-02'), // ו on the adult
      ('שהמורה מכה אותי', 1, 'W-02'), // שה on the adult
      ('הגנן מרביץ לי', 1, 'W-02'),
      ('אמא שלי סוטרת לי', 1, 'W-02'), // feminine singular, the possessive pair
      ('נגע לי בטוסיק', 1, 'W-11'),
      ('נגעה לי לפיפי', 1, 'W-11'), // the body prefix ל
      ('הוא שם לי אצבע בפיפי', 1, 'W-11'), // `שם אצבע` split by `לי`
      ('מכים$_rlmאותי', 1, 'W-01'), // a right-to-left mark instead of a space
      ('  מכים \n\t אותי  ', 1, 'W-01'), // white space of every kind
      ('ok מרביצים לי', 1, 'W-01'), // a Latin word around it
      ('מאיימים עלייי', 2, 'W-16'), // three yods
      ('אני פוחדת מהגננת', 2, 'W-18'), // the prefix מה on the adult, feminine
      ('אני שונאת את עצמי', 2, 'W-36'),
      ('מזויין', 3, 'S-04'), // the doubled yod of the editor's note
      ('מזוין', 3, 'S-04'),
      ("ביץ'", 3, 'S-11'), // ASCII apostrophe for a geresh
      ('ביץ׳', 3, 'S-11'), // the Hebrew geresh U+05F3
      ('FUCK you', 3, 'S-11'),
      ('Shit!', 3, 'S-11'),
      ('fucking', 3, 'S-11'),
    ];
    for (final (String text, int tier, String rule) in acts) {
      test('"$text" is tier $tier ($rule)', () => expectTier(text, tier, rule: rule));
    }
    test('the Hebrew geresh in צ׳אט is a geresh like the ASCII one (online bullying, band C)', () {
      expectTier('כותבים עלי בצ׳אט', 2, rule: 'W-42', band: 2);
    });

    final List<String> nothing = <String>[
      'זה לא נכון שמרביצים לי', // the negation guard reaches over one word
      'כלי זין', // the weapons, in the defective spelling
      'מכים', 'אותי', 'לי', 'בי', // one half of a phrase
      'אני מכה אותו', 'אני לא מרביץ לאף אחד', 'אני ואחי מרביצים לשכן', // the child as the hitter
      'אני מתה מצחוק', 'אני רוצה למות מרעב', 'אני רוצה למות מהבושה', 'אני לא רוצה למות', //
      'לא רוצה לחיות בבית הזה', // a place follows
      'אסור לי לספר לאמא על ההפתעה', 'אסור לי לספר לאבא כי זה מתנה', // surprises
      '😀😀', _rlm, '\t\n', '...', '״׳', // nothing to read
      'שבע', 'זיבי', 'שיט', 'שיט!', // the Hebrew `שיט` (boating) is left out on purpose
    ];
    for (final String text in nothing) {
      test('"$text" is nothing', () => expectTier(text, null));
    }

    test('the child as the hitter: "me" further on does not make it a check (kills mutation M9)', () {
      expectTier('אני מכה אותו וגם לי כואב', null);
      expectTier('אני מרביץ לו ואז לי עונש', null);
      expectTier('אחי אומר שאני מרביץ לו אבל הוא מרביץ לי', 2, rule: 'W-03');
    });

    test('a person after "I do not want to live" is a check, a place is nothing', () {
      expectTier('אני לא רוצה לחיות עם אבא', 2, rule: 'W-31');
      expectTier('לא רוצה לחיות בבית הזה', null);
    });

    test('the letter ז: an answer on screen with niqqud, or of two words, is still the answer', () {
      expectTier('זין', null, answers: <String>{'זַיִן'});
      expectTier('זין', null, answers: <String>{'האות זין'});
      expectTier('זין', 3, answers: <String>{'ז'}); // the letter itself is not the name
      expectTier('זין זין', null, answers: <String>{'זין'});
      // Spec D2.14: where the activity does not expect the letter, the name of the letter is a note. QA observation
      // for the curriculum-expert: `האות זין` ("the letter zayin") is then a note too.
      expectTier('האות זין', 3);
    });

    test('very long answers: a phrase at the start or the end of 2,000 tokens is found', () {
      final String filler = List<String>.filled(2000, 'פרפר').join(' ');
      expectTier('מכים אותי $filler', 1, rule: 'W-01');
      expectTier('$filler אני רוצה למות', 1, rule: 'W-30');
      expectTier('$filler חרא', 3, rule: 'S-01');
    });

    test('an age band outside 0 to 2 is read as the nearest band, never an error', () {
      expectTier('אני לבד בבית', 1, band: -1);
      expectTier('אני לבד בבית', 2, band: 9);
    });
  });

  group('hypotheses', () {
    test('an act in a lower hypothesis beats a check in the best one, and its own text is kept', () {
      final WordMatch m = checkWords(<String>['הוא מרביץ לי', 'מכים אותי'])!;
      expect(<Object>[m.tier, m.rule, m.text], <Object>[1, 'W-01', 'מכים אותי']);
      final WordMatch d = checkWords(<String>['ארבע', 'שבע', 'שש', 'חמש', 'אני רוצה למות'])!;
      expect(<Object>[d.tier, d.sub, d.text], <Object>[1, 'SELF', 'אני רוצה למות']);
    });

    test('a note or a check only in one lower hypothesis is nothing; in two it counts', () {
      expect(checkWords(<String>['שבע', 'פורנו']), isNull);
      expect(checkWords(<String>['שבע', 'אסור לי לספר לאמא', 'הוא מרביץ לי']), isNull);
      final WordMatch n = checkWords(<String>['שבע', 'חרא', 'חרא'])!;
      expect(<Object>[n.tier, n.text], <Object>[3, 'חרא']);
    });

    test('a swear only in a lower hypothesis is not passed on with an act (C-4 needs it counted)', () {
      expect(checkWords(<String>['מכים אותי', 'חרא'])!.swear, isNull);
      expect(checkWords(<String>['חרא מכים אותי'])!.swear?.rule, 'S-01');
    });

    test('the same swear five times in one answer is one match, and one count', () async {
      final WordMatch m = checkWords(<String>['חרא חרא חרא חרא חרא'])!;
      expect(<Object>[m.tier, m.rule], <Object>[3, 'S-01']);
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(
        db,
        now: t0,
        profileId: 'p-1',
        texts: <String>['חרא חרא חרא חרא חרא'],
        ageBand: 1,
      );
      expect((await db.allAlerts()).single.count, 1);
    });
  });

  group('ages: band A (3–4) against band C (7–8), row by row (proposal, section 6)', () {
    const List<(String, int?, int?)> rows = <(String, int?, int?)>[
      ('אני לבד בבית', 1, 2), // W-25
      ('השאירו אותי לבד', 1, 2), // W-25, without "at home"
      ('אני פוגע בעצמי', 3, 2), // W-37
      ('אני מרביץ לעצמי', 3, 2), // W-37
      ('אני רוצה למות', 1, 1), // W-30
      ('הלוואי שלא נולדתי', 1, 1), // W-32
      ('אני רוצה להתאבד', 1, 1), // W-33
      ('הוא הוריד לי את המכנסיים', null, 2), // W-14
      ('אני שונא את עצמי', null, 2), // W-36
      ('צוחקים עלי בקבוצה', null, 2), // W-42
      ('הוא הראה לי את הפיפי שלו', 2, 2), // W-12
      ('חרא', 3, 3), // swearing at every age (owner)
      ('מכים אותי', 1, 1),
      ('הוא מרביץ לי', 2, 2),
    ];
    for (final (String text, int? a, int? c) in rows) {
      test('"$text": band A $a, band C $c', () {
        expectTier(text, a, band: 0);
        expectTier(text, c, band: 2);
      });
    }
  });

  group('speed (alert-test-list E7.2: 1,000 tokens under 10 ms on a phone)', () {
    // Hostile mixes: every token starts some rule, prefixes everywhere, near misses that make the windows search.
    const List<List<String>> mixes = <List<String>>[
      <String>['איש', 'זר', 'כתב', 'גבר', 'בטלפון', 'שלח', 'ביקש', 'לגעת', 'בפיפי', 'והגננת', 'שמרביצים'],
      <String>['לא', 'אני', 'רוצה', 'לחיות', 'ממש', 'כל', 'כך', 'מרביצים', 'אותי', 'לא', 'מכים'],
      <String>['אבא', 'אמא', 'הגננת', 'מהמורה', 'שהדוד', 'ושמרביצים', 'וכשנגעו', 'בתחת', 'משחק', 'סודי'],
    ];
    for (int k = 0; k < mixes.length; k++) {
      test('hostile mix ${k + 1}: one hypothesis of 1,000 tokens, and five of them', () {
        final String long = <String>[for (int i = 0; i < 1000; i++) mixes[k][i % mixes[k].length]].join(' ');
        checkWords(<String>[long]); // warm up
        final Stopwatch one = Stopwatch()..start();
        checkWords(<String>[long]);
        one.stop();
        final Stopwatch five = Stopwatch()..start();
        checkWords(List<String>.filled(5, long));
        five.stop();
        // ignore: avoid_print
        print(
          'QA speed mix ${k + 1}: 1 x 1,000 tokens ${one.elapsedMicroseconds} µs, 5 x 1,000 ${five.elapsedMicroseconds} µs',
        );
        expect(one.elapsedMilliseconds, lessThan(50), reason: 'the developer\'s budget for a test machine');
        expect(five.elapsedMilliseconds, lessThan(250));
      });
    }
  });

  group('cool-down and what is stored', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<bool> say(String text, {Duration after = Duration.zero, String child = 'p-1', int band = 1}) =>
        recordWordAlert(db, now: t0.add(after), profileId: child, texts: <String>[text], ageBand: band);

    test('the 30-minute edge: 29 and 30 minutes are the same alert, 31 is a new one', () async {
      await say('מכים אותי');
      await say('מכים אותי', after: const Duration(minutes: 29));
      await say('מכים אותי', after: const Duration(minutes: 30));
      expect((await db.allAlerts()).single.count, 3);
      await say('מכים אותי', after: const Duration(minutes: 61));
      expect((await db.allAlerts()).length, 2, reason: '30 minutes after the first one, not after the last');
    });

    test(
      'C-2 across answers raises a check to an act on its own, after C-1 was used this week (kills M11)',
      () async {
        await say('הוא מרביץ לי');
        await say('מפחידים אותי', after: const Duration(days: 1)); // C-1: the week's "repeated" act
        await say('אסור לי לספר לאמא', after: const Duration(days: 3));
        await say('הוא מרביץ לי', after: const Duration(days: 3, hours: 2));
        final List<Alert> a = (await db.allAlerts()).reversed.toList();
        expect(a.map((Alert x) => x.category), <String>['concern', 'disclosure', 'concern', 'disclosure']);
        expect(WordDetail.parse(a.last.detail)!.flags, contains('secret'));
        expect(WordDetail.parse(a.last.detail)!.flags, isNot(contains('repeat')));
      },
    );

    test('two children are two alerts, and one child\'s check never makes the other\'s "repeated"', () async {
      await say('מכים אותי', child: 'p-1');
      await say('מכים אותי', child: 'p-2');
      await say('הוא מרביץ לי', child: 'p-1', after: const Duration(hours: 1));
      await say('הוא מרביץ לי', child: 'p-2', after: const Duration(days: 1));
      final List<Alert> a = await db.allAlerts();
      expect(a.length, 4);
      expect(a.where((Alert x) => x.category == 'concern').length, 2);
    });

    test('two answers at the same moment are one alert with a count of two', () async {
      await Future.wait(<Future<bool>>[
        say('מכים אותי'),
        say('מכים אותי', after: const Duration(seconds: 1)),
      ]);
      final Alert a = (await db.allAlerts()).single;
      expect(a.count, 2);
    });

    test(
      'the week of a note ends on Saturday night: a swear just after midnight starts a new note',
      () async {
        final DateTime saturday = DateTime(2026, 11, 21, 23, 59);
        await recordWordAlert(db, now: saturday, profileId: 'p-1', texts: <String>['חרא'], ageBand: 1);
        await recordWordAlert(
          db,
          now: saturday.add(const Duration(minutes: 2)),
          profileId: 'p-1',
          texts: <String>['חרא'],
          ageBand: 1,
        );
        expect((await db.allAlerts()).length, 2);
      },
    );

    test(
      // Changed 2026-10-30 by the app-developer: the owner approved a weekly note for hitting oneself in band A (it
      // was matched and not saved when QA wrote this).
      'band A: a swear is saved as a note (owner: every age), and so is hitting oneself (owner, 2026-10-30)',
      () async {
        expect(await say('חרא', band: 0), isTrue);
        expect(await say('אני פוגע בעצמי', band: 0), isTrue);
        expect(
          (await db.allAlerts()).map((Alert a) => '${a.category}/${WordDetail.parse(a.detail)!.sub}').toSet(),
          <String>{'inappropriateWords/SWEAR', 'inappropriateWords/SELF'},
        );
      },
    );

    test(
      'what is kept: the matching hypothesis, fixed characters in detail and key, and nothing else',
      () async {
        await recordWordAlert(
          db,
          now: t0,
          profileId: 'p-1',
          texts: <String>['ארבע', 'מכים אותי כל יום', 'חרא'],
          ageBand: 1,
        );
        final Alert a = (await db.allAlerts()).single;
        expect(a.words, 'מכים אותי כל יום', reason: 'only the hypothesis that matched');
        expect(a.detail, matches(RegExp(r'^1:PHYS:W-01:[0-9.-]+:often$')));
        expect(a.dedupeKey, matches(RegExp(r'^words:p-1:\d+$')));
        expect(serverKey.hasMatch(a.dedupeKey), isTrue);
        expect(
          await db.recentEvents(limit: 50),
          isEmpty,
          reason: 'nothing about the answer in the event log',
        );
      },
    );

    test('with "keep the words" off, no Hebrew is kept anywhere in the alert', () async {
      await db.putSetting(keepWordsKey, 'off');
      await say('מכים אותי');
      await say('חרא');
      for (final Alert a in await db.allAlerts()) {
        expect(a.words, isEmpty);
        expect(RegExp('[֐-׿]').hasMatch('${a.detail}${a.dedupeKey}'), isFalse);
      }
    });

    test('the cool-down holds across a restart of the app (the same database file opened again)', () async {
      final Directory dir = Directory.systemTemp.createTempSync('qa_alerts_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final File file = File('${dir.path}${Platform.pathSeparator}app.sqlite');
      final AppDatabase first = AppDatabase(NativeDatabase(file));
      await recordWordAlert(first, now: t0, profileId: 'p-1', texts: <String>['מכים אותי'], ageBand: 1);
      await recordWordAlert(first, now: t0, profileId: 'p-1', texts: <String>['חרא'], ageBand: 1);
      await first.close();
      final AppDatabase again = AppDatabase(NativeDatabase(file));
      await recordWordAlert(
        again,
        now: t0.add(const Duration(minutes: 5)),
        profileId: 'p-1',
        texts: <String>['מכים אותי'],
        ageBand: 1,
      );
      await recordWordAlert(
        again,
        now: t0.add(const Duration(days: 1)),
        profileId: 'p-1',
        texts: <String>['חרא'],
        ageBand: 1,
      );
      final List<Alert> a = await again.allAlerts();
      await again.close();
      expect(a.length, 2);
      expect(a.map((Alert x) => x.count).toList()..sort(), <int>[2, 2]);
    });
  });

  group('two phones', () {
    late FakeFamilyServer server;
    late Phone parent;
    late Phone child;
    late List<Map<String, Object?>> sent;

    setUp(() async {
      server = FakeFamilyServer();
      sent = <Map<String, Object?>>[];
      final SyncCall real = server.callFor(dev3, parent: false);
      parent = Phone(dev1, server);
      child = Phone(
        dev3,
        server,
        parent: false,
        call: (String name, Map<String, Object?> body) {
          if (name == 'alert-create') sent.add(body);
          return real(name, body);
        },
      );
      await parent.addChild();
      await parent.engine.syncOnce();
      await child.engine.syncOnce();
    });
    tearDown(() async {
      await parent.db.close();
      await child.db.close();
    });

    test(
      'one episode across two phones: the parent phone counts the child phone\'s alert, no second alert',
      () async {
        await child.say('מכים אותי');
        await child.engine.syncOnce();
        await parent.engine.syncOnce();
        expect((await parent.db.allAlerts()).single.count, 1);
        // Ten minutes later the child plays on the parent's phone and says it again.
        await parent.say('מכים אותי', after: const Duration(minutes: 10));
        final List<Alert> here = await parent.db.allAlerts();
        expect(here.length, 1, reason: 'the same episode, not a new alert (and no new push)');
        expect(here.single.count, 2);
        final SyncReport r = await parent.engine.syncOnce();
        expect(r.pushedAlerts, 0, reason: 'a duplicate for the server');
        expect(server.alerts.single['count'], 2);
      },
    );

    test('the count only goes up on a phone: a lower count from the family never lowers it', () async {
      await child.say('חרא');
      await child.engine.syncOnce();
      await parent.engine.syncOnce();
      final Alert a = (await parent.db.allAlerts()).single;
      AlertsCompanion remote(int count) => AlertsCompanion.insert(
        at: a.at,
        profileId: Value<String?>(a.profileId),
        category: a.category,
        severity: a.severity,
        count: Value<int>(count),
        detail: Value<String>(a.detail),
        words: Value<String>(a.words),
        dedupeKey: a.dedupeKey,
      );
      expect(await parent.db.takeRemoteAlert(remote(7)), isFalse);
      expect((await parent.db.allAlerts()).single.count, 7);
      expect(await parent.db.takeRemoteAlert(remote(2)), isFalse);
      expect((await parent.db.allAlerts()).single.count, 7, reason: 'never lower');
    });

    test(
      'a replay: the answer to alert-create is lost, the phone sends it again, the family has one alert',
      () async {
        await child.say('מכים אותי');
        server.loseAnswerOf = 'alert-create';
        await child.engine.syncOnce();
        expect(await child.db.unsyncedAlerts(), isNotEmpty, reason: 'not marked sent without an answer');
        final SyncReport again = await child.engine.syncOnce();
        expect(again.pushedAlerts, 0, reason: 'the server already had it: a duplicate, no second push');
        expect(server.alerts.length, 1);
        expect(await child.db.unsyncedAlerts(), isEmpty);
      },
    );

    test(
      'what a phone sends: the described fields only, words only when kept, server-valid detail and key',
      () async {
        await child.say('מכים אותי');
        await child.say('חרא', after: const Duration(minutes: 1));
        await child.engine.syncOnce();
        await child.db.putSetting(keepWordsKey, 'off');
        await child.say('אני רוצה למות', after: const Duration(minutes: 2));
        await child.engine.syncOnce();
        expect(sent.length, 3);
        for (final Map<String, Object?> b in sent) {
          expect(alertFields.containsAll(b.keys), isTrue, reason: '${b.keys}');
          expect(serverDetail.hasMatch(b['detail']! as String), isTrue);
          expect((b['detail']! as String).length, lessThanOrEqualTo(80));
          expect(serverKey.hasMatch(b['key']! as String), isTrue);
        }
        expect(sent[0]['words'], 'מכים אותי');
        expect(sent[2].containsKey('words'), isFalse, reason: 'not kept, not sent');
      },
    );

    test('QA-36: one alert the server refuses (words too long) must not stop the alerts after it from reaching the family', () async {
      // The real server refuses words over 200 characters or with other characters (handler.ts), and the phone
      // then never marks the alert sent: it stays first in line and every later alert waits behind it.
      final FakeFamilyServer strict = FakeFamilyServer();
      final SyncCall real = strict.callFor(dev3, parent: false);
      final Phone p = Phone(dev1, strict);
      addTearDown(p.db.close);
      await p.addChild();
      await p.engine.syncOnce();
      final Phone c = Phone(
        dev3,
        strict,
        parent: false,
        call: (String name, Map<String, Object?> body) {
          final String w = body['words'] as String? ?? '';
          if (name == 'alert-create' && (w.length > 200 || !serverWords.hasMatch(w))) {
            throw const GatewayException('bad_request', status: 400);
          }
          return real(name, body);
        },
      );
      addTearDown(c.db.close);
      final String long = 'מכים אותי ${List<String>.filled(60, 'ואז').join(' ')}';
      expect(long.length, greaterThan(200));
      await c.say(long);
      await c.say('אני רוצה למות', after: const Duration(minutes: 1));
      await c.engine.syncOnce();
      await c.engine.syncOnce();
      expect(
        strict.alerts.map((Map<String, Object?> a) => a['category']),
        contains('disclosure'),
        reason: 'the death wish must reach the parents',
      );
    });
  });

  group('the parent texts as rendered', () {
    late AppDatabase db;
    int serial = 0;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Alert> alert(String category, String detail, {String words = 'מכים אותי', int count = 1}) async {
      final String key = 'qa:${serial++}';
      await db.addAlert(
        AlertsCompanion.insert(
          at: t0,
          profileId: const Value<String?>('p-1'),
          category: category,
          severity: severityOf(AlertCategory.values.byName(category)).name,
          count: Value<int>(count),
          detail: Value<String>(detail),
          words: Value<String>(words),
          dedupeKey: key,
        ),
      );
      return (await db.allAlerts()).singleWhere((Alert a) => a.dedupeKey == key);
    }

    String all(({String title, List<AlertLine> lines}) t) =>
        <String>[t.title, for (final AlertLine l in t.lines) l.text].join('\n');

    final List<(String, String)> kinds = <(String, String)>[
      for (final String sub in <String>['PHYS', 'SEX', 'FEAR', 'NEGL', 'EMERG', 'SELF', 'ONLINE', 'SECRET'])
        ('disclosure', '1:$sub:W-01:2026-10-29.1'),
      ('disclosure', '1:PHYS:W-03:2026-10-29.1:repeat'),
      ('disclosure', '1:PHYS:W-03:2026-10-29.1:secret:often'),
      ('concern', '2:FEAR:W-21:2026-10-29.1'),
      ('inappropriateWords', '3:SWEAR:S-01:2026-10-29.1'),
      ('inappropriateWords', '3:EXPOSE:S-12:2026-10-29.1'),
      ('disclosure', ''), // an alert saved before the tiers
    ];

    test(
      'every kind, with a Latin name and a Hebrew one, kept words or not: the editor\'s rules hold',
      () async {
        for (final (String category, String detail) in kinds) {
          for (final String words in <String>['מכים אותי', '']) {
            for (final int count in <int>[0, 1, 2, 31]) {
              final Alert a = await alert(category, detail, words: words, count: count);
              for (final String name in <String>['Dana', 'נועה']) {
                final String text = all(wordAlertText(a, name)!);
                final String where = '$category $detail "$words" $count $name';
                expect(text, isNot(contains('{')), reason: 'a placeholder left: $where');
                expect(RegExp('[א-ת]$name').hasMatch(text), isFalse, reason: 'a prefix on the name: $where');
                expect(
                  RegExp('(?<![0-9$_lri-])10[01](?![0-9])').hasMatch(text),
                  isFalse,
                  reason: '100 or 101: $where',
                );
                for (final RegExpMatch m in RegExp(r'\d[\d-]{2,}').allMatches(text)) {
                  final bool isolated =
                      m.start > 0 && text[m.start - 1] == _lri && m.end < text.length && text[m.end] == _pdi;
                  expect(isolated, isTrue, reason: 'number ${m[0]} not isolated left to right: $where');
                }
                for (final String claim in <String>[
                  'רשת ביטחון',
                  'מגינה',
                  'מגנה על',
                  'שומרת על הילדים',
                  'מזהה פגיעה',
                ]) {
                  expect(text, isNot(contains(claim)), reason: 'the app presented as protection: $where');
                }
                if (words.isEmpty) expect(text, isNot(contains('""')), reason: 'empty quotes: $where');
              }
            }
          }
        }
      },
    );

    test('the note counts: none or one says "once", more says how many', () async {
      final String zero = all(
        wordAlertText(await alert('inappropriateWords', '3:SWEAR:S-01:v', count: 0), 'נועה')!,
      );
      final String two = all(
        wordAlertText(await alert('inappropriateWords', '3:SWEAR:S-01:v', count: 2), 'נועה')!,
      );
      expect(zero, contains('פעם אחת'));
      expect(two, contains('2 פעמים'));
    });

    test(
      'odd or hostile details never break the screen: the category decides when the detail cannot',
      () async {
        for (final String detail in <String>[
          ':',
          '1',
          '1:::',
          '9:PHYS:W-01:v',
          '0:PHYS:W-01:v',
          '1:PHYS:W-01:v:repeat:secret:often:x:y',
          '2:NOPE:X:Y',
          'trophy:counting:gold',
          List<String>.filled(80, ':').join(),
          '1:SECRET:W-45:v:secret',
        ]) {
          for (final String category in <String>['disclosure', 'concern', 'inappropriateWords']) {
            final ({String title, List<AlertLine> lines})? t = wordAlertText(
              await alert(category, detail),
              'נועה',
            );
            expect(t, isNotNull, reason: '$category $detail');
            expect(t!.title, isNotEmpty);
            expect(t.lines, isNotEmpty);
          }
        }
        // A secret act does not repeat the secrets add-on.
        final String secret = all(
          wordAlertText(await alert('disclosure', '1:SECRET:W-45:v:secret'), 'נועה')!,
        );
        expect(RegExp('הפתעה אפשר לשמור בסוד').allMatches(secret).length, 1);
      },
    );

    test('QA-41: the child\'s words are shown as said, never filled as a placeholder', () async {
      final String text = all(
        wordAlertText(await alert('concern', '2:FEAR:W-21:v', words: 'אמר {n} {child}', count: 5), 'נועה')!,
      );
      expect(text, contains('אמר {n} {child}'));
    });

    test('QA-42: a detail that contradicts the category does not turn a quiet note into an act', () async {
      final ({String title, List<AlertLine> lines}) t = wordAlertText(
        await alert('inappropriateWords', '1:PHYS:W-01:v', words: 'חרא'),
        'נועה',
      )!;
      expect(
        t.title,
        isNot(He.alertActTitle.text),
        reason: 'the note was never pushed; its card must not read as an act',
      );
    });
  });

  group('wiring: the band and the answers on screen reach the matcher', () {
    test(
      'the voice controller hands on the answers of the question on screen with the words heard',
      () async {
        final FakeSpeechEngine engine = FakeSpeechEngine(<Scripted>[Scripted.says('זין')]);
        List<String>? heard;
        Set<String>? answers;
        final VoiceAnswerController c = VoiceAnswerController(
          engine: engine,
          expected: () => <Expected>[
            Expected.words('o1', <String>['זין'], correct: true),
            Expected.words('o2', <String>['שין'], correct: false),
          ],
          onAnswer: (String id) async {},
          silence: const Duration(milliseconds: 1500),
          beat: Duration.zero,
          onWords: (List<String> t, Set<String> a) {
            heard = t;
            answers = a;
          },
        );
        await c.tap();
        expect(heard, <String>['זין']);
        expect(answers, containsAll(<String>[normalizeHebrew('זין'), normalizeHebrew('שין')]));
        expect(
          checkWords(heard!, answerWords: answers!),
          isNull,
          reason: 'the letter name is the answer here',
        );
      },
    );

    testWidgets('band A in the real lesson: "he took my trousers off" is care, nothing is saved', (
      WidgetTester tester,
    ) async {
      expect(await _spokenInLesson(tester, 'הוא הוריד לי את המכנסיים', 0), isEmpty);
    });

    testWidgets('band B in the real lesson: the same words are a check', (WidgetTester tester) async {
      final List<Alert> a = await _spokenInLesson(tester, 'הוא הוריד לי את המכנסיים', 1);
      expect(a.single.category, 'concern');
    });

    testWidgets('band C in the real lesson: alone at home is a check, not an act', (
      WidgetTester tester,
    ) async {
      final List<Alert> a = await _spokenInLesson(tester, 'אני לבד בבית', 2);
      expect(a.single.category, 'concern');
      expect(WordDetail.parse(a.single.detail)!.rule, 'W-25');
    });
  });

  group('QA defects, fixed', () {
    test(
      'QA-34: "I do not want to live because of it" is an act; only a place or a person after it is not',
      () {
        expectTier('אני לא רוצה לחיות בגלל זה', 1, rule: 'W-31');
        expectTier('לא רוצה לחיות בגלל שכולם צוחקים עלי', 1, rule: 'W-31');
      },
    );

    test('QA-35: the maqaf is a space, as normalizeHebrew says ("turns the maqaf into a space")', () {
      expect(normalizeHebrew('בן־זונה'), 'בנ זונה');
      expectTier('בן־זונה', 3, rule: 'S-05');
      expectTier('מכים־אותי', 1, rule: 'W-01');
    });

    test('QA-37: C-2 both ways: "do not tell mum" and then a harm within a day is an act', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(db, now: t0, profileId: 'p-1', texts: <String>['אל תספר לאמא'], ageBand: 1);
      await recordWordAlert(
        db,
        now: t0.add(const Duration(hours: 2)),
        profileId: 'p-1',
        texts: <String>['הוא מרביץ לי'],
        ageBand: 1,
      );
      expect((await db.allAlerts()).map((Alert a) => a.category), contains('disclosure'));
    });

    test(
      'QA-38: online bullying (B31) is the online row, so a "repeated" act gets the online add-on (105)',
      () {
        final WordMatch m = at('מקללים אותי בקבוצה בוואטסאפ', band: 2)!;
        expect(<Object>[m.rule, m.sub], <Object>['W-42', 'ONLINE']);
      },
    );

    test('QA-39: a bruise the child "has" or "had" is not someone hitting (the guard of `יש לי`)', () {
      expectTier('נפלתי ויש לי מכה ברגל', null);
      expectTier('הייתה לי מכה ברגל', null);
      expectTier('היה לי מכה בראש', null);
    });

    test('QA-40: the idiom "בא לי למות מרוב בושה" is an idiom', () {
      expectTier('בא לי למות מרוב בושה', null);
      expectTier('אני רוצה למות מרוב צחוק', null);
    });
  });

  group('re-verification of 2026-10-30 (after the fixes)', () {
    test(
      'QA-36 in full: the long answer arrives cut to the gateway, and the death wish after it arrives too',
      () async {
        final FakeFamilyServer strict = FakeFamilyServer();
        final SyncCall real = strict.callFor(dev3, parent: false);
        final Phone p = Phone(dev1, strict);
        addTearDown(p.db.close);
        await p.addChild();
        await p.engine.syncOnce();
        final Phone c = Phone(
          dev3,
          strict,
          parent: false,
          call: (String name, Map<String, Object?> body) {
            final String w = body['words'] as String? ?? '';
            if (name == 'alert-create' && (w.length > 200 || !serverWords.hasMatch(w))) {
              throw const GatewayException('bad_request', status: 400);
            }
            return real(name, body);
          },
        );
        addTearDown(c.db.close);
        await c.say('מכים אותי בשעה 3:30, 50% (כל יום) ${List<String>.filled(60, 'ואז').join(' ')}');
        await c.say('אני רוצה למות', after: const Duration(minutes: 1));
        await c.engine.syncOnce();
        final List<Map<String, Object?>> acts = <Map<String, Object?>>[
          for (final Map<String, Object?> a in strict.alerts)
            if (a['category'] == 'disclosure') a,
        ];
        expect(acts.length, 2, reason: 'both acts, in one round');
        final String w = acts.first['words']! as String;
        expect(w.length, lessThanOrEqualTo(200));
        expect(serverWords.hasMatch(w), isTrue);
        expect(w, startsWith('מכים אותי בשעה 3 30, 50 כל יום'));
      },
    );

    test('QA-37 the other order still works, and the secret note itself is a note (never pushed)', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(db, now: t0, profileId: 'p-1', texts: <String>['אל תספר לאמא'], ageBand: 1);
      final Alert note = (await db.allAlerts()).single;
      expect(<Object>[note.category, note.severity], <Object>['inappropriateWords', 'info']);
      expect(WordDetail.parse(note.detail)!.sub, 'SECRET');
      // 25 hours later the secret is too old to pair.
      await recordWordAlert(
        db,
        now: t0.add(const Duration(hours: 25)),
        profileId: 'p-1',
        texts: <String>['הוא מרביץ לי'],
        ageBand: 1,
      );
      expect((await db.allAlerts()).map((Alert a) => a.category), isNot(contains('disclosure')));
    });

    test('W-37 in band A is a note of its own kind; in band B it is a check', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(db, now: t0, profileId: 'p-1', texts: <String>['אני מרביץ לעצמי'], ageBand: 0);
      await recordWordAlert(db, now: t0, profileId: 'p-1', texts: <String>['אני מרביץ לעצמי'], ageBand: 0);
      final Alert n = (await db.allAlerts()).single;
      expect(
        <Object>[n.category, n.count, WordDetail.parse(n.detail)!.sub],
        <Object>['inappropriateWords', 2, 'SELF'],
      );
      final String text = wordAlertText(n, 'נועה')!.title;
      expect(text, He.alertSelfHitTitle.text);
      await recordWordAlert(db, now: t0, profileId: 'p-2', texts: <String>['אני מרביץ לעצמי'], ageBand: 1);
      expect((await db.allAlerts()).where((Alert a) => a.profileId == 'p-2').single.category, 'concern');
    });

    test(
      'a detail of another tier lends no flags: an act whose detail says "repeated" at tier 3 is a plain act',
      () async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await db.addAlert(
          AlertsCompanion.insert(
            at: t0,
            profileId: const Value<String?>('p-1'),
            category: 'disclosure',
            severity: 'important',
            detail: const Value<String>('3:SELF:W-37:2026-10-29.1:repeat:often'),
            dedupeKey: 'qa:odd',
          ),
        );
        final ({String title, List<AlertLine> lines}) t = wordAlertText(
          (await db.allAlerts()).single,
          'נועה',
        )!;
        expect(t.title, He.alertActTitle.text);
        expect(t.lines.map((AlertLine l) => l.text), isNot(contains(He.alertOften.text)));
      },
    );

    test('the parent area scan also empties the words when they are not kept (kills N14)', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(db, now: t0, profileId: 'p-1', texts: <String>['מכים אותי'], ageBand: 1);
      await db.putSetting(keepWordsKey, 'off');
      await runAlertScan(db, now: t0.add(const Duration(minutes: 1)), rules: const ParentRules());
      expect((await db.allAlerts()).single.words, isEmpty);
    });

    test('E4.6 (open, as briefed): the "repeated" act says no dates', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(db, now: t0, profileId: 'p-1', texts: <String>['הוא מרביץ לי'], ageBand: 1);
      await recordWordAlert(
        db,
        now: t0.add(const Duration(days: 2)),
        profileId: 'p-1',
        texts: <String>['מפחידים אותי'],
        ageBand: 1,
      );
      final Alert rep = (await db.allAlerts()).first;
      final String text = wordAlertText(rep, 'נועה')!.lines.map((AlertLine l) => l.text).join('\n');
      expect(text, isNot(contains('20.11')), reason: 'records today\'s behaviour; E4.6 asks for the dates');
    });

    test(
      'the step budget never costs an act: hostile noise before a death wish, in one or another hypothesis',
      () {
        const List<List<String>> mixes = <List<String>>[
          <String>['איש', 'זר', 'כתב', 'גבר', 'בטלפון', 'שלח', 'ביקש', 'לגעת', 'בפיפי', 'והגננת', 'שמרביצים'],
          <String>['לא', 'אני', 'רוצה', 'לחיות', 'ממש', 'כל', 'כך', 'מרביצים', 'אותי', 'לא', 'מכים'],
          <String>['אבא', 'אמא', 'הגננת', 'מהמורה', 'שהדוד', 'ושמרביצים', 'וכשנגעו', 'בתחת', 'משחק', 'סודי'],
        ];
        for (final List<String> mix in mixes) {
          final String noise = <String>[for (int i = 0; i < 400; i++) mix[i % mix.length]].join(' ');
          final WordMatch? m = checkWords(<String>['שבע', noise, noise, noise, 'אני רוצה למות']);
          expect(m?.tier, 1, reason: 'the act in the fifth hypothesis, after three hostile ones');
        }
      },
    );

    test('QA-47: the floor of acts holds even when a newer list could spend the whole step budget first', () {
      final Map<String, Object?> heavy = <String, Object?>{
        ...bundledAlertLists,
        'listVersion': '2027-01-01.1',
        'rules': <Object?>[
          for (int i = 100; i < 400; i++)
            <String, Object?>{
              'id': 'X-$i',
              'sub': 'PHYS',
              'tier': 2,
              'seq': <String>['מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'אאאא'],
              'gap': 2,
            },
        ],
        'words': const <Object?>[],
      };
      final AlertLists l = AlertLists.load(heavy);
      final String text = '${List<String>.filled(200, 'מילה').join(' ')} מכים אותי';
      final Stopwatch w = Stopwatch()..start();
      final WordMatch? m = checkWords(<String>[text], lists: l);
      w.stop();
      // ignore: avoid_print
      print('QA heavy list + floor: ${w.elapsedMilliseconds} ms, list ${l.listVersion}, match ${m?.rule}');
      expect(m?.tier, 1, reason: 'the bundled acts are a floor (SEC-26)');
    });

    test('SEC-26: the floor has its own step budget: a heavy list spending its budget on one hypothesis costs no act in the next', () {
      final Map<String, Object?> heavy = <String, Object?>{
        ...bundledAlertLists,
        'listVersion': '2027-01-01.1',
        'rules': <Object?>[
          for (int i = 100; i < 400; i++)
            <String, Object?>{
              'id': 'X-$i',
              'sub': 'PHYS',
              'tier': 2,
              'seq': <String>['מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'אאאא'],
              'gap': 2,
            },
        ],
        'words': const <Object?>[],
      };
      final AlertLists l = AlertLists.load(heavy);
      final String noise = List<String>.filled(200, 'מילה').join(' ');
      final WordMatch? m = checkWords(<String>[noise, 'מכים אותי'], lists: l);
      expect(
        m?.tier,
        1,
        reason: 'the act in the second hypothesis, after a hypothesis that burned the list budget',
      );
    });

    test('QA-45: a phone whose clock runs 10 minutes fast, with nothing learned yet, still delivers its act', () async {
      // The real gateway client (signing, clock_skew retry) over a fake server that checks the signed time (±60 s)
      // and refuses an `at` more than 2 minutes ahead, as the gateway did before SEC-30 (it now stores the server's
      // time instead): the phone must deliver the act even to that gateway.
      final int serverNow = t0.millisecondsSinceEpoch;
      final FixedClock phone = FixedClock(serverNow + 10 * 60000);
      final List<Map<String, Object?>> stored = <Map<String, Object?>>[];
      final Recorder rec = Recorder((http.Request r) {
        final int ts = int.parse(r.headers['x-timestamp'] ?? '0');
        if ((ts - serverNow).abs() > 60000) {
          return jsonReply(<String, Object?>{'error': 'clock_skew', 'server_time': serverNow}, status: 401);
        }
        if (r.url.path.endsWith('/alert-create')) {
          final Map<String, Object?> b = jsonDecode(r.body) as Map<String, Object?>;
          if ((b['at']! as int) > serverNow + 120000) {
            return jsonReply(<String, Object?>{'error': 'bad_request'}, status: 400);
          }
          stored.add(b);
          return jsonReply(<String, Object?>{'status': 'new'});
        }
        return jsonReply(<String, Object?>{});
      });
      final GatewayClient client = GatewayClient(
        baseUrl: Uri.parse('https://$testHost'),
        publishableKey: testKey,
        gate: NetGate(client: rec.client, hosts: testHosts()),
        keys: FakeKeys(),
        clock: phone,
      );
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await recordWordAlert(
        db,
        now: DateTime.fromMillisecondsSinceEpoch(phone.nowMs(), isUtc: true),
        profileId: kid,
        texts: <String>['מכים אותי'],
        ageBand: 1,
      );
      final SyncEngine engine = SyncEngine(
        db: db,
        call: (String name, Map<String, Object?> body) => client.call(name, body, deviceId: dev3),
        deviceId: dev3,
        isParent: false,
        nowMs: phone.nowMs,
        serverNowMs: client.serverNowMs,
      );
      await engine.syncOnce();
      await engine.syncOnce();
      expect(
        stored.map((Map<String, Object?> b) => b['category']),
        contains('disclosure'),
        reason:
            'calls: ${rec.requests.map((http.Request r) => '${r.url.pathSegments.last}@${r.headers['x-timestamp']}').join(', ')}; '
            'kept aside: ${AppDatabase.wasRefusedBySync((await db.allAlerts()).single.syncedAt)}',
      );
    });

    group('SEC-30: a gateway that always refuses is called at most twice per alert, never in a loop', () {
      // One per kind: with words, without words, and a third with words. Each is refused with bad_request every time.
      Future<(int, List<Map<String, Object?>>, AppDatabase)> run({
        required int Function(int calls) skewAfter,
        int rounds = 3,
      }) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final int server = t0.millisecondsSinceEpoch;
        final int phone = server + 10 * 60000; // 10 minutes fast
        for (int i = 0; i < 3; i++) {
          await db.addAlert(
            AlertsCompanion.insert(
              at: DateTime.fromMillisecondsSinceEpoch(phone, isUtc: true),
              profileId: const Value<String?>(kid),
              category: 'disclosure',
              severity: 'important',
              dedupeKey: 'words:$i',
              words: Value<String>(i == 1 ? '' : 'מכים אותי'),
            ),
          );
        }
        int calls = 0;
        final List<Map<String, Object?>> seen = <Map<String, Object?>>[];
        final SyncEngine e = SyncEngine(
          db: db,
          call: (String name, Map<String, Object?> body) async {
            if (name != 'alert-create') return <String, Object?>{};
            calls++;
            seen.add(body);
            throw const GatewayException('bad_request', status: 400);
          },
          deviceId: dev3,
          isParent: false,
          nowMs: () => phone,
          serverNowMs: () => phone + skewAfter(calls),
        );
        for (int r = 0; r < rounds; r++) {
          await e.syncOnce();
        }
        return (calls, seen, db);
      }

      List<Map<String, Object?>> of(List<Map<String, Object?>> seen, String key) =>
          seen.where((Map<String, Object?> b) => b['key'] == key).toList();

      test(
        'a clock that never changes: 2 calls for an alert with words (the second without), 1 without',
        () async {
          final (int calls, List<Map<String, Object?>> seen, AppDatabase db) = await run(
            skewAfter: (int c) => 0,
          );
          expect(calls, 5, reason: 'alert 0: 2, alert 1 (no words): 1, alert 2: 2; three rounds add nothing');
          expect(of(seen, 'words:0').map((Map<String, Object?> b) => b.containsKey('words')), <bool>[
            true,
            false,
          ]);
          expect(of(seen, 'words:1').length, 1);
          expect(of(seen, 'words:2').map((Map<String, Object?> b) => b.containsKey('words')), <bool>[
            true,
            false,
          ]);
          expect(await db.unsyncedAlerts(), isEmpty, reason: 'all three are kept aside, none is held up');
        },
      );

      test(
        'a skew learned by the first call: 2 calls with the words and the corrected time, no third',
        () async {
          final int server = t0.millisecondsSinceEpoch;
          final (int calls, List<Map<String, Object?>> seen, AppDatabase db) = await run(
            skewAfter: (int c) => c == 0 ? 0 : -10 * 60000,
          );
          expect(of(seen, 'words:0').length, 2);
          expect(of(seen, 'words:0').map((Map<String, Object?> b) => b.containsKey('words')), <bool>[
            true,
            true,
          ]);
          expect(of(seen, 'words:0').map((Map<String, Object?> b) => b['at']), <int>[
            server + 10 * 60000,
            server,
          ]);
          expect(calls, 5, reason: 'no third call without the words, and no call in the later rounds');
          expect(await db.unsyncedAlerts(), isEmpty);
          // The trade-off, pinned: such an alert is kept aside (for the next version), not delivered.
          final Alert first = (await db.allAlerts()).firstWhere((Alert a) => a.dedupeKey == 'words:0');
          expect(AppDatabase.wasRefusedBySync(first.syncedAt), isTrue);
        },
      );

      test(
        'a clock that changes on every call (a gateway client that keeps learning): still 2 per alert',
        () async {
          final (int calls, List<Map<String, Object?>> seen, _) = await run(skewAfter: (int c) => -c * 1000);
          expect(of(seen, 'words:0').length, 2);
          expect(of(seen, 'words:1').length, 2);
          expect(of(seen, 'words:2').length, 2);
          expect(calls, 6, reason: '2 for each of the three alerts, however often the clock moves');
        },
      );
    });
  });
}
