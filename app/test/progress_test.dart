// The parent's progress view is built from the engine's replay, never from numbers of its own: these tests give it
// scripted histories and check each part (this week, understanding, growth, misunderstandings, what helped, habits).
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/parent/progress.dart';

import 'engine/fixtures.dart';

final DateTime now = DateTime(2026, 11, 20, 12);

AttemptEvent ev(
  DateTime at,
  String item,
  Result result, {
  int hint = 0,
  String tag = '',
  int attemptNo = 1,
  int id = 0,
}) => AttemptEvent(
  id: id,
  at: at.toUtc(),
  activityId: item,
  result: result,
  hintLevel: hint,
  tag: tag,
  attemptNo: attemptNo,
);

Session session(DateTime from, int minutes, {String reason = 'home'}) => Session(
  id: 1,
  profileId: 'p-1',
  startedAt: from,
  endedAt: from.add(Duration(minutes: minutes)),
  plan: 'lesson:butterflies',
  endReason: reason,
);

Map<String, SkillInfo> info() => <String, SkillInfo>{
  'SK-A-01': const SkillInfo(title: 'סופרים עד חמש', domain: 'numbers'),
  'SK-B-01': const SkillInfo(title: 'נוגעים בכל עצם פעם אחת', domain: 'numbers'),
  'SK-C-01': const SkillInfo(title: 'מצביעים על צבעים', domain: 'colors'),
  'SK-D-01': const SkillInfo(title: 'שמות של צבעים', domain: 'colors'),
};

Progress build({
  List<AttemptEvent> attempts = const <AttemptEvent>[],
  List<Session> sessions = const <Session>[],
}) => buildProgress(
  ProgressSource(
    catalog: smallCatalog(),
    skillInfo: info(),
    tagText: <String, String>{'M-A': 'הילד מדלג על עצם', 'M-B': 'הילד סופר עצם פעמיים'},
    attempts: attempts,
    sessions: sessions,
    now: now,
  ),
);

/// Right answers on skill A over a few days, so the engine takes it as learnt.
List<AttemptEvent> learntA(DateTime from) => <AttemptEvent>[
  for (int d = 0; d < 4; d++)
    for (final String item in <String>['A.1', 'A.2', 'A.3'])
      ev(from.add(Duration(days: d, minutes: item.hashCode % 7)), item, Result.correct),
];

void main() {
  group('a child who has not played', () {
    test('everything is empty, and the view can say so instead of drawing flat charts', () {
      final Progress p = build();
      expect(p.empty, isTrue);
      expect(p.sessionsThisWeek, 0);
      expect(p.totalMinutes, 0);
      expect(p.minutesPerDay.length, 7);
      expect(p.growth.length, 8);
      for (final WeekPoint w in p.growth) {
        expect(w.byDomain.values.every((double? v) => v == null), isTrue);
      }
      for (final DomainBlock d in p.domains) {
        expect(d.skills.every((SkillRow s) => s.status == ParentStatus.notStartedYet), isTrue);
      }
      expect(p.misconceptions, isEmpty);
      expect(p.habits.any, isFalse);
    });
  });

  group('this week', () {
    test('minutes per day, oldest first, today last; days outside the week are left out', () {
      final Progress p = build(
        sessions: <Session>[
          session(DateTime(2026, 11, 20, 9), 12),
          session(DateTime(2026, 11, 20, 10), 8),
          session(DateTime(2026, 11, 18, 17), 15),
          session(DateTime(2026, 11, 10, 17), 30),
        ],
      );
      expect(p.minutesPerDay.first.day, DateTime(2026, 11, 14));
      expect(p.minutesPerDay.last.day, DateTime(2026, 11, 20));
      expect(p.minutesPerDay.last.minutes, 20);
      expect(p.minutesPerDay[4].minutes, 15, reason: 'the 18th');
      expect(p.totalMinutes, 35);
      expect(p.sessionsThisWeek, 3, reason: 'the session of the 10th is not this week');
    });

    test('adventures completed are the sessions that ended as finished, not the ones that ended at the time limit', () {
      final Progress p = build(
        sessions: <Session>[
          session(DateTime(2026, 11, 20, 9), 10, reason: 'finished'),
          session(DateTime(2026, 11, 19, 9), 10, reason: 'limit'),
          session(DateTime(2026, 11, 18, 9), 10, reason: 'home'),
          session(DateTime(2026, 11, 17, 9), 10, reason: 'finished'),
        ],
      );
      expect(p.adventuresCompleted, 2);
      expect(p.sessionsThisWeek, 4);
    });
  });

  group('understanding by domain', () {
    test('skills are grouped by domain with their plain sentence and a status a parent can read', () {
      final Progress p = build(attempts: learntA(DateTime(2026, 11, 14, 9)));
      expect(p.empty, isFalse);
      final DomainBlock numbers = p.domains.firstWhere((DomainBlock d) => d.domain == 'numbers');
      final DomainBlock colors = p.domains.firstWhere((DomainBlock d) => d.domain == 'colors');
      expect(numbers.skills.map((SkillRow s) => s.title), contains('סופרים עד חמש'));
      final SkillRow a = numbers.skills.firstWhere((SkillRow s) => s.id == 'SK-A-01');
      expect(a.started, isTrue);
      expect(<ParentStatus>[ParentStatus.practising, ParentStatus.understood], contains(a.status));
      expect(colors.skills.every((SkillRow s) => !s.started), isTrue);
    });

    test('a skill the child keeps failing is a revisit or a gap, never "understood"', () {
      final List<AttemptEvent> failing = <AttemptEvent>[
        for (int i = 0; i < 6; i++) ev(DateTime(2026, 11, 15, 9, i), 'A.1', Result.incorrect, tag: 'M-A'),
      ];
      final SkillRow a = build(attempts: failing).domains
          .firstWhere((DomainBlock d) => d.domain == 'numbers')
          .skills
          .firstWhere((SkillRow s) => s.id == 'SK-A-01');
      expect(a.status, isNot(ParentStatus.understood));
    });
  });

  group('growth over time', () {
    test('a week before the child started has no point, later weeks show understanding that rises', () {
      final Progress p = build(attempts: learntA(DateTime(2026, 11, 3, 9)));
      expect(p.growth.length, 8);
      expect(p.growth.first.byDomain['numbers'], isNull, reason: 'eight weeks ago nothing was started');
      final double? last = p.growth.last.byDomain['numbers'];
      expect(last, isNotNull);
      expect(last!, greaterThan(0.5));
      final List<double> seen = <double>[
        for (final WeekPoint w in p.growth)
          if (w.byDomain['numbers'] != null) w.byDomain['numbers']!,
      ];
      expect(seen.length, greaterThanOrEqualTo(2));
      for (int i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1] - 1e-9), reason: 'only right answers: never falls');
      }
      expect(p.growth.last.byDomain['colors'], isNull, reason: 'colours were never started');
    });

    test('the last point is now, so what the engine knows today is what the line ends at', () {
      final Progress p = build(attempts: learntA(DateTime(2026, 11, 18, 9)));
      expect(p.growth.last.weekEnd, now);
      expect(p.growth.last.byDomain['numbers'], isNotNull);
      expect(
        p.growth[p.growth.length - 2].byDomain['numbers'],
        isNull,
        reason: 'a week ago: not started yet',
      );
    });
  });

  group('misunderstandings, what helped, habits', () {
    test('a misunderstanding with evidence on two items is shown with its sentence for the parent', () {
      final Progress p = build(
        attempts: <AttemptEvent>[
          ev(DateTime(2026, 11, 15, 9), 'A.1', Result.incorrect, tag: 'M-A'),
          ev(DateTime(2026, 11, 15, 9, 5), 'A.2', Result.incorrect, tag: 'M-A'),
          ev(DateTime(2026, 11, 16, 9), 'A.1', Result.incorrect, tag: 'M-A'),
        ],
      );
      expect(p.misconceptions.map((MisconceptionRow m) => m.text), contains('הילד מדלג על עצם'));
      expect(p.misconceptions.every((MisconceptionRow m) => !m.resolved), isTrue);
    });

    test('one slip is not shown as a misunderstanding', () {
      final Progress p = build(
        attempts: <AttemptEvent>[ev(DateTime(2026, 11, 15, 9), 'A.1', Result.incorrect, tag: 'M-A')],
      );
      expect(p.misconceptions, isEmpty);
    });

    test('the ways of explaining that worked are listed only with three tries and a 60 percent success', () {
      final Progress few = build(
        attempts: <AttemptEvent>[ev(DateTime(2026, 11, 15, 9), 'A.1', Result.correct)],
      );
      expect(few.helped, isEmpty);
      final Progress many = build(attempts: learntA(DateTime(2026, 11, 14, 9)));
      for (final HelpedRow h in many.helped) {
        expect(h.tries, greaterThanOrEqualTo(3));
        expect(h.successes / h.tries, greaterThanOrEqualTo(0.6));
      }
    });

    test('habits count asking for help when unsure, using a hint and getting it right on a later try', () {
      final Progress p = build(
        attempts: <AttemptEvent>[
          ev(DateTime(2026, 11, 15, 9), 'A.1', Result.unsure),
          ev(DateTime(2026, 11, 15, 9, 1), 'A.1', Result.correct, hint: 1, attemptNo: 2),
          ev(DateTime(2026, 11, 16, 9), 'A.2', Result.incorrect),
          ev(DateTime(2026, 11, 16, 9, 1), 'A.2', Result.correct, attemptNo: 2),
          ev(DateTime(2026, 9, 1, 9), 'A.2', Result.unsure),
        ],
      );
      expect(p.habits.askedWhenUnsure, 1, reason: 'the one from September is older than four weeks');
      expect(p.habits.usedHints, 1);
      expect(p.habits.keptTrying, 2);
      expect(p.habits.any, isTrue);
    });
  });

  test('the same history always gives the same view', () {
    final List<AttemptEvent> history = learntA(DateTime(2026, 11, 10, 9));
    final Progress a = build(attempts: history);
    final Progress b = build(attempts: history.reversed.toList());
    expect(
      a.growth.map((WeekPoint w) => w.byDomain['numbers']),
      b.growth.map((WeekPoint w) => w.byDomain['numbers']),
    );
    expect(
      a.domains.map((DomainBlock d) => d.skills.map((SkillRow s) => s.status).toList()),
      b.domains.map((DomainBlock d) => d.skills.map((SkillRow s) => s.status).toList()),
    );
  });
}
