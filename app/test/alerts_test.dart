// The alert detectors: each one fires on its pattern and stays quiet on the near misses, and the word lists recognise
// what they should without raising an alert for everyday words.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/alert_words.dart';
import 'package:nitznutz/parent/alerts.dart';
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
    test('swearing is recognised however it is written with niqqud, final letters or punctuation', () {
      expect(checkWords(<String>['חרא!']), WordAlert.inappropriate);
      expect(checkWords(<String>['לך תזדיין']), WordAlert.inappropriate);
      expect(checkWords(<String>['ארבע', 'מניאק']), WordAlert.inappropriate, reason: 'any hypothesis counts');
    });

    test('a worrying phrase is a disclosure, and wins over swearing in the same answer', () {
      expect(checkWords(<String>['הוא מכה אותי']), WordAlert.disclosure);
      expect(checkWords(<String>['אני רוצה למות חרא']), WordAlert.disclosure);
    });

    test('everyday words and the answers of the lessons set nothing off', () {
      for (final String text in <String>[
        'ארבע',
        'כוס מים',
        'מתחת לעץ',
        'שלוש פרפרים',
        'אדום',
        'הפרפר נחת עלי',
      ]) {
        expect(checkWords(<String>[text]), isNull, reason: text);
      }
      expect(checkWords(const <String>[]), isNull);
    });

    test('the words are kept only when the parent allows it', () {
      final AlertDraft? kept = wordAlert(
        at: now,
        profileId: 'p-1',
        texts: <String>['חרא'],
        keepWords: true,
        key: 'w:1',
      );
      final AlertDraft? hidden = wordAlert(
        at: now,
        profileId: 'p-1',
        texts: <String>['חרא'],
        keepWords: false,
        key: 'w:1',
      );
      expect(kept!.words, 'חרא');
      expect(hidden!.words, isEmpty);
      expect(hidden.category, AlertCategory.inappropriateWords);
      expect(
        wordAlert(at: now, profileId: 'p-1', texts: <String>['ארבע'], keepWords: true, key: 'w:2'),
        isNull,
      );
    });
  });

  test('a worrying disclosure is the only important alert', () {
    expect(
      AlertCategory.values.where((AlertCategory c) => severityOf(c) == AlertSeverity.important),
      <AlertCategory>[AlertCategory.disclosure],
    );
  });
}
