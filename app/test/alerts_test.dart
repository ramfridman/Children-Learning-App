// The alert detectors: each one fires on its pattern and stays quiet on the near misses; a word alert is saved once per
// child, subcategory and half hour (or week, for a note) with a count, and the combination rules raise it
// (docs/child-safety/alert-test-list.md, E4 and E6). The lists themselves are in alert_words_test.dart.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/alert_scan.dart';
import 'package:nitznutz/parent/alerts.dart';
import 'package:nitznutz/speech/alert_words.dart';
import 'package:nitznutz/parent/parent_rules.dart';

final DateTime now = DateTime(2026, 11, 20, 12);

Session session(int id, DateTime from, int minutes, {String reason = 'home'}) => Session(
  id: id,
  profileId: 'p-1',
  startedAt: from,
  endedAt: from.add(Duration(minutes: minutes)),
  plan: 'lesson:butterflies',
  endReason: reason,
);

Attempt attempt(int id, DateTime at, String result, {int ms = 4000, int? sessionId = 1}) => Attempt(
  id: id,
  at: at,
  profileId: 'p-1',
  packId: 'starter',
  packVersion: '0.2.0',
  lessonId: 'butterflies',
  activityId: 'count.butterflies.3',
  activityRevision: 1,
  template: 'count_tap',
  templateVersion: '1.0',
  skillId: 'NUM-A-03',
  result: result,
  attemptNo: 1,
  hintLevel: 0,
  misconceptionTag: '',
  response: 'o1',
  durationMs: ms,
  sessionId: sessionId,
  input: 'tap',
);

ChildHistory child({
  List<Session> sessions = const <Session>[],
  List<Attempt> attempts = const <Attempt>[],
}) => ChildHistory(profileId: 'p-1', ageBand: 1, sessions: sessions, attempts: attempts);

void main() {
  group('time', () {
    test('a day more than five minutes over the limit is one alert, with the minutes over', () {
      final List<AlertDraft> a = timeAlerts(
        now,
        const ParentRules(),
        child(
          sessions: <Session>[
            session(1, DateTime(2026, 11, 19, 15), 25),
            session(2, DateTime(2026, 11, 19, 16), 20),
          ],
        ),
      );
      final AlertDraft over = a.singleWhere((AlertDraft d) => d.category == AlertCategory.pastLimit);
      expect(over.count, 15, reason: '45 minutes against a limit of 30');
      expect(over.severity, AlertSeverity.info);
      expect(over.key, 'limit:p-1:2026-11-19');
    });

    test('five minutes over or less is not an alert', () {
      final List<AlertDraft> a = timeAlerts(
        now,
        const ParentRules(),
        child(sessions: <Session>[session(1, DateTime(2026, 11, 19, 15), 35)]),
      );
      expect(a.where((AlertDraft d) => d.category == AlertCategory.pastLimit), isEmpty);
    });

    test('a session that began in rest hours is an alert, one a day; with rest hours off it is not', () {
      final List<Session> late = <Session>[
        session(1, DateTime(2026, 11, 19, 21), 8),
        session(2, DateTime(2026, 11, 19, 21, 30), 5),
      ];
      final List<AlertDraft> on = timeAlerts(now, const ParentRules(), child(sessions: late));
      expect(on.where((AlertDraft d) => d.category == AlertCategory.restHours).length, 1);
      final List<AlertDraft> off = timeAlerts(now, const ParentRules(restOn: false), child(sessions: late));
      expect(off.where((AlertDraft d) => d.category == AlertCategory.restHours), isEmpty);
    });

    test('play in the afternoon within the limit raises nothing', () {
      expect(
        timeAlerts(
          now,
          const ParentRules(),
          child(sessions: <Session>[session(1, DateTime(2026, 11, 19, 16), 20)]),
        ),
        isEmpty,
      );
    });
  });

  group('the parent area', () {
    test('three wrong gate answers or three wrong pins each give one alert; a single wrong pin does not', () {
      final List<AlertDraft> a = gateAlerts(<LocalEvent>[
        LocalEvent(id: 1, at: now, kind: 'gate_alert', detail: 'n=3'),
        LocalEvent(id: 2, at: now, kind: 'pin_wrong', detail: 'n=1'),
        LocalEvent(id: 3, at: now, kind: 'pin_alert', detail: 'n=3'),
        LocalEvent(id: 4, at: now, kind: 'pin_lockout', detail: 's=30'),
      ]);
      expect(a.map((AlertDraft d) => d.key), <String>['gate:1', 'gate:3']);
      expect(a.every((AlertDraft d) => d.profileId == null), isTrue, reason: 'not about one child');
    });
  });

  group('behaviour', () {
    test('six fast answers, four of them wrong, is guessing', () {
      final List<Attempt> fast = <Attempt>[
        for (int i = 0; i < 6; i++)
          attempt(i, DateTime(2026, 11, 20, 10, 0, i * 2), i < 4 ? 'incorrect' : 'correct', ms: 700),
      ];
      final List<AlertDraft> a = behaviourAlerts(
        child(sessions: <Session>[session(1, DateTime(2026, 11, 20, 10), 3)], attempts: fast),
      );
      expect(a.any((AlertDraft d) => d.category == AlertCategory.guessing), isTrue);
    });

    test('slow answers, or fast ones that are right, are not guessing', () {
      final List<Attempt> slow = <Attempt>[
        for (int i = 0; i < 6; i++) attempt(i, DateTime(2026, 11, 20, 10, i), 'incorrect', ms: 6000),
      ];
      final List<Attempt> rightFast = <Attempt>[
        for (int i = 0; i < 6; i++) attempt(i, DateTime(2026, 11, 20, 10, i), 'correct', ms: 600),
      ];
      for (final List<Attempt> history in <List<Attempt>>[slow, rightFast]) {
        final List<AlertDraft> a = behaviourAlerts(
          child(sessions: <Session>[session(1, DateTime(2026, 11, 20, 10), 8)], attempts: history),
        );
        expect(a.where((AlertDraft d) => d.category == AlertCategory.guessing), isEmpty);
      }
    });

    test('three wrong in a row and then leaving is frustration; three wrong and staying is not', () {
      final List<Attempt> three = <Attempt>[
        for (int i = 0; i < 3; i++) attempt(i, DateTime(2026, 11, 20, 10, i), 'incorrect'),
      ];
      final Session left = session(1, DateTime(2026, 11, 20, 9, 58), 4);
      expect(
        behaviourAlerts(child(sessions: <Session>[left], attempts: three))
            .any((AlertDraft d) => d.category == AlertCategory.frustration),
        isTrue,
      );
      final Session stayed = session(1, DateTime(2026, 11, 20, 9, 58), 20, reason: 'finished');
      expect(behaviourAlerts(child(sessions: <Session>[stayed], attempts: three)), isEmpty);
    });

    test('eight answers inside half a minute is rapid tapping', () {
      final List<Attempt> tap = <Attempt>[
        for (int i = 0; i < 8; i++) attempt(i, DateTime(2026, 11, 20, 10, 0, i * 3), 'correct', ms: 3000),
      ];
      final List<AlertDraft> a = behaviourAlerts(
        child(
          sessions: <Session>[session(1, DateTime(2026, 11, 20, 10), 5, reason: 'finished')],
          attempts: tap,
        ),
      );
      expect(a.single.category, AlertCategory.frustration);
    });

    test('scanning twice finds the same keys, so nothing is repeated', () {
      final List<Attempt> three = <Attempt>[
        for (int i = 0; i < 3; i++) attempt(i, DateTime(2026, 11, 20, 10, i), 'incorrect'),
      ];
      final ChildHistory c = child(
        sessions: <Session>[session(1, DateTime(2026, 11, 20, 9, 58), 4)],
        attempts: three,
      );
      expect(
        behaviourAlerts(c).map((AlertDraft d) => d.key),
        behaviourAlerts(c).map((AlertDraft d) => d.key),
      );
    });
  });

  group('absence', () {
    List<Session> regular(DateTime until) => <Session>[
      for (int i = 0; i < 6; i++) session(i + 1, until.subtract(Duration(days: i * 2)), 20),
    ];

    test('no play for a week after regular play is one note', () {
      final List<AlertDraft> a = absenceAlerts(now, child(sessions: regular(DateTime(2026, 11, 10, 16))));
      expect(a.single.category, AlertCategory.absence);
      expect(a.single.count, greaterThanOrEqualTo(9));
    });

    test('a child who has hardly played is not "absent"', () {
      expect(
        absenceAlerts(now, child(sessions: <Session>[session(1, DateTime(2026, 11, 1, 16), 10)])),
        isEmpty,
      );
    });

    test('a sudden drop from a busy week is a note; a normal week is not', () {
      final List<Session> busy = <Session>[
        for (int i = 8; i <= 13; i++) session(i, DateTime(2026, 11, 20 - i, 16), 15),
        session(99, DateTime(2026, 11, 19, 16), 5),
      ];
      expect(absenceAlerts(now, child(sessions: busy)).single.category, AlertCategory.absence);
      final List<Session> steady = <Session>[
        for (int i = 0; i <= 13; i += 2) session(i + 1, DateTime(2026, 11, 20 - i, 16), 15),
      ];
      expect(absenceAlerts(now, child(sessions: steady)), isEmpty);
    });
  });

  group('words', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    /// One spoken answer at [at] (minutes after [now]), as the lesson hands it on.
    Future<bool> say(String text, {int minutes = 0, int age = 1, List<String>? texts}) => recordWordAlert(
      db,
      now: now.add(Duration(minutes: minutes)),
      profileId: 'p-1',
      texts: texts ?? <String>[text],
      ageBand: age,
    );

    Future<List<Alert>> saved() async => (await db.allAlerts()).reversed.toList();

    test('E4.1, E4.9: one swear word said again and again is one note with a count, never more', () async {
      for (int i = 0; i < 5; i++) {
        await say('חרא', minutes: i ~/ 2);
      }
      expect((await saved()).single.count, 5);
      for (int i = 5; i < 30; i++) {
        await say('חרא', minutes: 60 + i);
      }
      final Alert note = (await saved()).single;
      expect(note.count, 30, reason: 'one note for the week');
      expect(note.category, 'inappropriateWords');
      expect(note.severity, 'info', reason: 'a note is never pushed');
      expect(WordDetail.parse(note.detail)!.sub, 'SWEAR');
    });

    test('a new week starts a new note; the adult world has its own note', () async {
      await say('חרא');
      await say('חרא', minutes: 8 * 24 * 60);
      await say('פורנו', minutes: 1);
      final List<Alert> a = await saved();
      expect(a.length, 3);
      expect(a.map((Alert x) => WordDetail.parse(x.detail)!.sub), <String>['SWEAR', 'EXPOSE', 'SWEAR']);
    });

    test('E4.2, C-4: a swear and then a worrying phrase are an act and a note', () async {
      await say('חרא');
      await say('מרביצים לי', minutes: 1);
      final List<Alert> a = await saved();
      expect(a.map((Alert x) => x.category), <String>['inappropriateWords', 'disclosure']);
      await say('חרא אני רוצה למות', minutes: 2);
      final List<Alert> b = await saved();
      expect(b.length, 3, reason: 'the death wish is a new act (another subcategory)');
      final Alert note = b.singleWhere((Alert x) => x.category == 'inappropriateWords');
      expect(note.count, 2, reason: 'the swear in the same answer is counted in the note');
      expect(note.at, now.add(const Duration(minutes: 2)), reason: 'a note is dated when it was last heard');
    });

    test('E4.3, E4.4: the same act within half an hour is one alert with a count; after 40 quiet minutes it is new', () async {
      for (int i = 0; i < 4; i++) {
        await say('מכים אותי', minutes: i);
      }
      final Alert act = (await saved()).single;
      expect(act.count, 4);
      expect(act.severity, 'important');
      await say('מכים אותי', minutes: 45);
      expect((await saved()).length, 2);
    });

    test('E4.5: two subcategories close together are two alerts', () async {
      await say('מכים אותי');
      await say('אני רוצה למות', minutes: 3);
      expect((await saved()).map((Alert x) => WordDetail.parse(x.detail)!.sub), <String>['PHYS', 'SELF']);
    });

    test('a stronger tier starts a new alert; a weaker one is counted in the stronger', () async {
      await say('הוא מרביץ לי');
      await say('מכים אותי', minutes: 2);
      await say('הוא מרביץ לי', minutes: 4);
      final List<Alert> a = await saved();
      expect(a.map((Alert x) => x.category), <String>['concern', 'disclosure']);
      expect(a.last.count, 2);
    });

    test(
      'E4.6, E4.7: a second check within a week is one act, "repeated"; nine days apart they stay checks',
      () async {
        await say('הוא מרביץ לי');
        await say('מפחידים אותי', minutes: 2 * 24 * 60);
        final List<Alert> week = await saved();
        expect(week.map((Alert x) => x.category), <String>['concern', 'disclosure']);
        expect(WordDetail.parse(week.last.detail)!.flags, contains('repeat'));
        await say('קוראים לי שמות', minutes: 3 * 24 * 60);
        expect((await saved()).last.category, 'concern', reason: 'one "repeated" act a week');

        await db.delete(db.alerts).go();
        await say('הוא מרביץ לי');
        await say('מפחידים אותי', minutes: 8 * 24 * 60);
        expect((await saved()).map((Alert x) => x.category), <String>['concern', 'concern']);
      },
    );

    test('E4.8, C-2: a secret and then a harm within a day are an act', () async {
      await say('אסור לי לספר לאמא');
      await say('הוא מרביץ לי', minutes: 5 * 60);
      final Alert act = (await saved()).last;
      expect(act.category, 'disclosure');
      expect(WordDetail.parse(act.detail)!.flags, contains('secret'));
    });

    test('E5: the band reaches the rules: alone at home is an act in band A, a check in band C', () async {
      await say('אני לבד בבית', age: 0);
      expect((await saved()).single.category, 'disclosure');
      await db.delete(db.alerts).go();
      await say('אני לבד בבית', age: 2);
      expect((await saved()).single.category, 'concern');
    });

    test('asking the helper to keep a secret, and a young child hitting themselves, are weekly notes (owner, 2026-10-30)', () async {
      expect(await say('אל תספר לאמא'), isTrue);
      expect(await say('אל תספרי לאבא', minutes: 5), isTrue);
      expect(await say('אני מכה את עצמי', age: 0, minutes: 10), isTrue);
      final List<Alert> a = await saved();
      expect(a.map((Alert x) => '${x.category}/${WordDetail.parse(x.detail)!.sub}/${x.count}'), <String>[
        'inappropriateWords/SECRET/2',
        'inappropriateWords/SELF/1',
      ]);
      expect(a.every((Alert x) => x.severity == 'info'), isTrue, reason: 'notes are never pushed');
    });

    test(
      'SEC-32: a note counted again keeps the words of its latest hearing, so none outlives 30 days',
      () async {
        await say('חרא');
        await say('fuck', minutes: 24 * 60); // the Saturday of the same week
        final Alert note = (await saved()).single;
        expect(note.count, 2);
        expect(note.words, 'fuck', reason: 'the first hearing\'s words went with it');
        expect(note.at, now.add(const Duration(days: 1)));
        await db.putSetting(keepWordsKey, 'off');
        await say('חרא', minutes: 26 * 60);
        expect((await saved()).single.words, isEmpty);
      },
    );

    test('QA-37, C-2 both ways: a request to keep a secret and then a harm within a day is an act', () async {
      await say('אל תספר לאמא');
      await say('הוא מרביץ לי', minutes: 2 * 60);
      final Alert act = (await saved()).last;
      expect(act.category, 'disclosure');
      expect(WordDetail.parse(act.detail)!.flags, contains('secret'));
      await db.delete(db.alerts).go();
      await say('אל תספר לאמא');
      await say('הוא מרביץ לי', minutes: 25 * 60);
      expect((await saved()).last.category, 'concern', reason: 'more than a day later');
    });

    test('the words kept fit what the family takes: odd characters become spaces, at most 200', () async {
      await say('מכים אותי ב-3:30 😀 ${List<String>.filled(80, 'ואז').join(' ')}');
      final String w = (await saved()).single.words;
      expect(w.startsWith('מכים אותי ב-3 30 ואז'), isTrue, reason: w);
      expect(w.length, lessThanOrEqualTo(200));
    });

    test('E6: tier, category, severity, the words that matched and the list version', () async {
      await say('', texts: <String>['ארבע', 'מכים אותי']);
      await say('', minutes: 1, texts: <String>['מפחידים אותי']);
      await say('', minutes: 2, texts: <String>['חרא']);
      final List<Alert> a = await saved();
      expect(a.map((Alert x) => '${x.category}/${x.severity}'), <String>[
        'disclosure/important',
        'concern/attention',
        'inappropriateWords/info',
      ]);
      expect(a.first.words, 'מכים אותי', reason: 'the hypothesis that matched, not the first one');
      for (final Alert x in a) {
        expect(WordDetail.parse(x.detail)!.listVersion, AlertLists.bundled.listVersion);
        expect(
          RegExp(r'^[A-Za-z0-9._:=-]{1,80}$').hasMatch(x.detail),
          isTrue,
          reason: 'fixed characters only',
        );
      }
    });

    test('E6.4: the words are kept only when the parent allows it', () async {
      await db.putSetting(keepWordsKey, 'off');
      await say('חרא');
      await say('מכים אותי');
      final List<Alert> a = await saved();
      expect(a.length, 2);
      expect(a.every((Alert x) => x.words.isEmpty), isTrue);
      expect(await say('ארבע'), isFalse);
    });

    test('counting an alert again sends it to the family again', () async {
      await say('מכים אותי');
      await db.markAlertsSynced(<int>[(await saved()).single.id], now);
      expect(await db.unsyncedAlerts(), isEmpty);
      await say('מכים אותי', minutes: 1);
      expect((await db.unsyncedAlerts()).single.count, 2);
    });

    test('the detail reads back as written, and an old alert without one has none', () {
      const WordDetail d = WordDetail(
        tier: 1,
        sub: 'SECRET',
        rule: 'W-45',
        listVersion: '2026-10-29.1',
        flags: <String>{'often', 'secret'},
      );
      final WordDetail back = WordDetail.parse(d.encode())!;
      expect(
        <Object>[back.tier, back.sub, back.rule, back.listVersion, back.flags],
        <Object>[
          1,
          'SECRET',
          'W-45',
          '2026-10-29.1',
          <String>{'often', 'secret'},
        ],
      );
      expect(WordDetail.parse(''), isNull);
      expect(WordDetail.parse('trophy:counting:silver'), isNull);
    });

    test('the week of a note starts on Sunday', () {
      expect(weekOf(DateTime(2026, 11, 20)), '2026-11-15'); // a Friday
      expect(weekOf(DateTime(2026, 11, 15, 23)), '2026-11-15'); // the Sunday itself
    });
  });

  test(
    'a worrying disclosure is the only important alert, and the two other word alerts are never pushed',
    () {
      expect(
        AlertCategory.values.where((AlertCategory c) => severityOf(c) == AlertSeverity.important),
        <AlertCategory>[AlertCategory.disclosure],
      );
      expect(severityOf(AlertCategory.concern), AlertSeverity.attention);
      expect(severityOf(AlertCategory.inappropriateWords), AlertSeverity.info);
    },
  );
}
