// Today's Adventure (B-26 step 5): every worked example of docs/curriculum/todays-adventure-rule.md section 10, and the
// properties of section 11 that belong to the pure function.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/lesson_path.dart';
import 'package:nitznutz/world/todays_adventure.dart';

const int today = 20400;

/// The fixture paths of section 10, in path order, with their levels (A = 0, B = 1).
final Map<TrophyLand, List<PathLesson>> fixturePaths = <TrophyLand, List<PathLesson>>{
  TrophyLand.counting: const <PathLesson>[
    PathLesson('n1', 0),
    PathLesson('n2', 0),
    PathLesson('n3', 0),
    PathLesson('n4', 1),
  ],
  TrophyLand.colors: const <PathLesson>[PathLesson('c1', 0), PathLesson('c2', 0), PathLesson('c3', 1)],
  TrophyLand.shapes: const <PathLesson>[PathLesson('s1', 0), PathLesson('s2', 1)],
  TrophyLand.logic: const <PathLesson>[PathLesson('g1', 0)],
  TrophyLand.robots: const <PathLesson>[PathLesson('r1', 0)],
  TrophyLand.market: const <PathLesson>[PathLesson('m1', 0), PathLesson('m2', 1)],
};

final Map<String, TrophyLand> landOfLesson = <String, TrophyLand>{
  for (final MapEntry<TrophyLand, List<PathLesson>> e in fixturePaths.entries)
    for (final PathLesson l in e.value) l.id: e.key,
};

const Map<String, TrophyLand> landOfSkillPrefix = <String, TrophyLand>{
  'NUM': TrophyLand.counting,
  'COL': TrophyLand.colors,
  'SHP': TrophyLand.shapes,
  'LOG': TrophyLand.logic,
  'CS': TrophyLand.robots,
  'MATH': TrophyLand.market,
};

/// `D`, `D-1`, ...
int day(String s) => today + (s == 'D' ? 0 : int.parse(s.substring(1)));

/// A visit in the notation of section 10: `L:n1 D-1 fin`, `L:n2 D home incorrect`, `W:counting D-1 home`,
/// `R:SHP-A-01 D fin`.
Visit visit(String text) {
  final List<String> t = text.split(' ');
  final String kind = t[0].substring(0, 1);
  final String id = t[0].substring(2);
  final VisitEnd end = switch (t[2]) {
    'fin' => VisitEnd.finished,
    'home' => VisitEnd.home,
    'limit' => VisitEnd.limit,
    _ => throw ArgumentError(text),
  };
  return Visit(
    kind: switch (kind) {
      'L' => VisitKind.lesson,
      'W' => VisitKind.warmUp,
      _ => VisitKind.revisit,
    },
    land: switch (kind) {
      'L' => landOfLesson[id]!,
      'W' => TrophyLand.values.byName(id),
      _ => landOfSkillPrefix[id.split('-').first]!,
    },
    id: id,
    day: day(t[1]),
    end: end,
    lastIncorrect: t.contains('incorrect'),
  );
}

/// `NUM-A-01@D-1 09:00` with an optional ` reviewedToday`.
DueSkill due(String text) {
  final List<String> t = text.split(' ');
  final List<String> head = t[0].split('@');
  final List<String> clock = t[1].split(':');
  return DueSkill(
    skillId: head[0],
    land: landOfSkillPrefix[head[0].split('-').first]!,
    dueAt: DateTime.utc(2000, 1, 100 + day(head[1]) - today, int.parse(clock[0]), int.parse(clock[1])),
    reviewedToday: t.contains('reviewedToday'),
  );
}

Map<String, int> fin(String ids, {Map<String, int> more = const <String, int>{}}) => <String, int>{
  if (ids.isNotEmpty)
    for (final String id in ids.split(',')) id: 1,
  ...more,
};

Map<String, int> everything({Map<String, int> more = const <String, int>{}}) => <String, int>{
  for (final String id in landOfLesson.keys) id: 1,
  ...more,
};

AdventureInput input({
  int band = 0,
  Set<TrophyLand>? enabled,
  Map<String, int> finished = const <String, int>{},
  List<String> visits = const <String>[],
  List<String> dues = const <String>[],
  Map<TrophyLand, List<PathLesson>>? paths,
}) => AdventureInput(
  today: today,
  band: band,
  enabledLands: enabled ?? TrophyLand.values.toSet(),
  paths: paths ?? fixturePaths,
  finished: finished,
  visits: <Visit>[for (final String v in visits) visit(v)],
  due: <DueSkill>[for (final String d in dues) due(d)],
);

TodaysAdventure lesson(TrophyLand land, String id, AdventureReason reason) =>
    TodaysAdventure.lesson(land, id, reason);

TodaysAdventure revisit(TrophyLand land, String skill) => TodaysAdventure.revisit(land, skill);

/// One row of section 10: the input and what the bottle opens.
typedef Row = (int, String, AdventureInput, TodaysAdventure);

const AdventureReason welcome = AdventureReason.welcome;
const AdventureReason same = AdventureReason.sameLand;
const AdventureReason other = AdventureReason.otherLand;

List<Row> rows() {
  final Map<String, int> row18 = everything(more: <String, int>{'m1': 2, 'r1': 3});
  const List<String> row18Visits = <String>[
    'L:m2 D-20 fin',
    'L:r1 D-12 fin',
    'L:g1 D-6 fin',
    'L:s2 D-5 fin',
    'L:c3 D-3 fin',
    'L:n4 D-1 fin',
  ];
  const List<String> row10Visits = <String>[
    'L:s1 D-9 fin',
    'L:n1 D-2 fin',
    'L:n2 D-1 fin',
    'R:SHP-A-01 D fin',
  ];
  return <Row>[
    (1, 'brand-new child', input(), lesson(TrophyLand.counting, 'n1', welcome)),
    (2, 'brand-new child, band B', input(band: 1), lesson(TrophyLand.counting, 'n1', welcome)),
    (
      3,
      'only the enabled lands, in map order',
      input(enabled: <TrophyLand>{TrophyLand.shapes, TrophyLand.colors}),
      lesson(TrophyLand.colors, 'c1', welcome),
    ),
    (
      4,
      'continue the land played last',
      input(finished: fin('n1'), visits: <String>['L:n1 D-1 fin']),
      lesson(TrophyLand.counting, 'n2', same),
    ),
    (
      5,
      'after 3 lessons in a row, another land',
      input(finished: fin('n1,n2,n3'), visits: <String>['L:n1 D-2 fin', 'L:n2 D-1 fin', 'L:n3 D-1 fin']),
      lesson(TrophyLand.colors, 'c1', other),
    ),
    (
      6,
      'another land breaks the run; a revisit neither counts nor breaks it',
      input(
        finished: fin('n1,c1,n2,n3'),
        visits: <String>[
          'L:n1 D-3 fin',
          'L:c1 D-2 fin',
          'L:n2 D-1 fin',
          'R:COL-A-01 D-1 fin',
          'L:n3 D-1 fin',
        ],
      ),
      lesson(TrophyLand.counting, 'n4', same),
    ),
    (
      7,
      'the current land is done: the land not played for the longest time',
      input(
        finished: fin('n1,n2,c1,n3,n4'),
        visits: <String>['L:n1 D-5 fin', 'L:n2 D-4 fin', 'L:c1 D-3 fin', 'L:n3 D-2 fin', 'L:n4 D-1 fin'],
      ),
      lesson(TrophyLand.shapes, 's1', other),
    ),
    (
      8,
      'revisit first on a new day',
      input(
        finished: fin('n1,n2'),
        visits: <String>['L:n1 D-2 fin', 'L:n2 D-1 fin'],
        dues: <String>['NUM-A-01@D-1 08:00'],
      ),
      revisit(TrophyLand.counting, 'NUM-A-01'),
    ),
    (
      9,
      'the revisit that fell due earliest',
      input(
        finished: fin('n1,n2,c1,s1'),
        visits: <String>['L:s1 D-9 fin', 'L:c1 D-8 fin', 'L:n1 D-2 fin', 'L:n2 D-1 fin'],
        dues: <String>['COL-A-01@D-1 07:00', 'NUM-A-01@D-1 09:00', 'SHP-A-01@D-2 18:00'],
      ),
      revisit(TrophyLand.shapes, 'SHP-A-01'),
    ),
    (
      10,
      'after a revisit today, new learning next',
      input(finished: fin('n1,n2,s1'), visits: row10Visits, dues: <String>['NUM-A-01@D-1 09:00']),
      lesson(TrophyLand.counting, 'n3', same),
    ),
    (
      11,
      'one lesson since the revisit; the run cap applies across the revisit',
      input(
        finished: fin('n1,n2,s1,n3'),
        visits: <String>[...row10Visits, 'L:n3 D fin'],
        dues: <String>['NUM-A-01@D-1 09:00'],
      ),
      lesson(TrophyLand.colors, 'c1', other),
    ),
    (
      12,
      'two lessons since the revisit, the next revisit',
      input(
        finished: fin('n1,n2,s1,n3,c1'),
        visits: <String>[...row10Visits, 'L:n3 D fin', 'L:c1 D fin'],
        dues: <String>['NUM-A-01@D-1 09:00'],
      ),
      revisit(TrophyLand.counting, 'NUM-A-01'),
    ),
    (
      13,
      'a skill already checked today rests',
      input(
        finished: fin('n1,n2'),
        visits: <String>['L:n1 D-2 fin', 'L:n2 D-1 fin', 'R:NUM-A-01 D home incorrect'],
        dues: <String>['NUM-A-01@D-1 09:00 reviewedToday'],
      ),
      lesson(TrophyLand.counting, 'n3', same),
    ),
    (
      14,
      'a lesson left today after an incorrect answer rests',
      input(finished: fin('n1'), visits: <String>['L:n1 D-1 fin', 'L:n2 D home incorrect']),
      lesson(TrophyLand.colors, 'c1', other),
    ),
    (
      15,
      'left after a correct answer: not resting',
      input(finished: fin('n1'), visits: <String>['L:n1 D-1 fin', 'L:n2 D home']),
      lesson(TrophyLand.counting, 'n2', same),
    ),
    (
      16,
      'left after an incorrect answer yesterday: the rest is over',
      input(finished: fin('n1'), visits: <String>['L:n1 D-1 fin', 'L:n2 D-1 home incorrect']),
      lesson(TrophyLand.counting, 'n2', same),
    ),
    (
      17,
      'only one land open: no rotation even after 3 in a row',
      input(
        enabled: <TrophyLand>{TrophyLand.counting},
        finished: fin('n1,n2,n3'),
        visits: <String>['L:n1 D-3 fin', 'L:n2 D-2 fin', 'L:n3 D-1 fin'],
      ),
      lesson(TrophyLand.counting, 'n4', same),
    ),
    (
      18,
      'everything finished, nothing due: play again',
      input(finished: row18, visits: row18Visits),
      TodaysAdventure.replay(TrophyLand.market, 'm2'),
    ),
    (
      19,
      'everything finished, a check due',
      input(finished: row18, visits: <String>['L:n4 D-1 fin'], dues: <String>['SHP-A-01@D-1 12:00']),
      revisit(TrophyLand.shapes, 'SHP-A-01'),
    ),
    (
      20,
      'one land, its only unfinished lesson resting, nothing finished: offered again',
      input(enabled: <TrophyLand>{TrophyLand.counting}, visits: <String>['L:n1 D home incorrect']),
      lesson(TrophyLand.counting, 'n1', same),
    ),
    (
      21,
      'a due skill in a land that is not open is ignored',
      input(
        enabled: <TrophyLand>{TrophyLand.counting, TrophyLand.colors},
        finished: fin('n1'),
        visits: <String>['L:n1 D-1 fin'],
        dues: <String>['SHP-A-01@D-1 12:00'],
      ),
      lesson(TrophyLand.counting, 'n2', same),
    ),
    (
      22,
      'equal due times: the current land first',
      input(
        finished: fin('n1,c1'),
        visits: <String>['L:n1 D-3 fin', 'L:c1 D-1 fin'],
        dues: <String>['NUM-A-01@D-1 12:00', 'COL-A-01@D-1 12:00'],
      ),
      revisit(TrophyLand.colors, 'COL-A-01'),
    ),
    (
      23,
      'a warm-up makes its land current and does not count in the run',
      input(finished: fin('n1'), visits: <String>['W:counting D-1 home', 'L:n1 D-1 fin']),
      lesson(TrophyLand.counting, 'n2', same),
    ),
    (
      24,
      'ended by the time limit: not resting, not counted in the run',
      input(
        finished: fin('n1,n2'),
        visits: <String>['L:n1 D-2 fin', 'L:n2 D-1 fin', 'L:n3 D limit incorrect'],
      ),
      lesson(TrophyLand.counting, 'n3', same),
    ),
    (
      25,
      'level before recency when moving on',
      input(
        enabled: <TrophyLand>{TrophyLand.counting, TrophyLand.colors, TrophyLand.shapes},
        finished: fin('n1,n2,n3,c1,s1,s2'),
        visits: <String>[
          'L:n1 D-10 fin',
          'L:n2 D-9 fin',
          'L:n3 D-8 fin',
          'L:c1 D-3 fin',
          'L:s1 D-2 fin',
          'L:s2 D-1 fin',
        ],
      ),
      lesson(TrophyLand.colors, 'c2', other),
    ),
    (
      26,
      'nothing new left: a due revisit comes even right after another revisit',
      input(
        finished: row18,
        visits: <String>['L:n4 D-1 fin', 'R:SHP-A-01 D fin'],
        dues: <String>['NUM-A-01@D-1 12:00'],
      ),
      revisit(TrophyLand.counting, 'NUM-A-01'),
    ),
    (27, 'nothing to play', input(paths: <TrophyLand, List<PathLesson>>{}), const TodaysAdventure.none()),
  ];
}

void main() {
  group('the worked examples of the rule (section 10)', () {
    for (final Row r in rows()) {
      test('row ${r.$1}: ${r.$2}', () {
        expect(todaysAdventure(r.$3), r.$4);
      });
    }

    test(
      'row 28: the school stage will choose a row of the parameters; every band has the same row today',
      () {
        final AdventureParams a = paramsFor(band: 0);
        for (final int band in <int>[1, 2]) {
          expect(paramsFor(band: band).newAfterRevisit, a.newAfterRevisit);
          expect(paramsFor(band: band).stayInLand, a.stayInLand);
        }
        expect(a.newAfterRevisit, 2);
        expect(a.stayInLand, 3);
        // Row 4 with each band gives the row 4 answer.
        for (final int band in <int>[0, 1, 2]) {
          expect(
            todaysAdventure(input(band: band, finished: fin('n1'), visits: <String>['L:n1 D-1 fin'])),
            lesson(TrophyLand.counting, 'n2', same),
          );
        }
      },
    );

    test(
      'the reasons: a call for help says callForHelp, the first adventure welcome, a replay playAgain',
      () {
        expect(todaysAdventure(rows()[7].$3).reason, AdventureReason.callForHelp);
        expect(todaysAdventure(rows()[0].$3).reason, AdventureReason.welcome);
        expect(todaysAdventure(rows()[17].$3).reason, AdventureReason.playAgain);
        expect(todaysAdventure(rows()[26].$3).reason, AdventureReason.nothing);
      },
    );
  });

  group('properties (section 11)', () {
    test('order-independent: shuffling the lands, the due list and the finished map changes nothing', () {
      final math.Random random = math.Random(7);
      for (final Row r in rows()) {
        final AdventureInput a = r.$3;
        for (int i = 0; i < 5; i++) {
          final List<TrophyLand> lands = a.enabledLands.toList()..shuffle(random);
          final List<DueSkill> dues = a.due.toList()..shuffle(random);
          final List<String> ids = a.finished.keys.toList()..shuffle(random);
          final AdventureInput b = AdventureInput(
            today: a.today,
            band: a.band,
            enabledLands: lands.toSet(),
            paths: a.paths,
            finished: <String, int>{for (final String id in ids) id: a.finished[id]!},
            visits: a.visits,
            due: dues,
          );
          expect(todaysAdventure(b), r.$4, reason: 'row ${r.$1}');
        }
      }
    });

    test('the same input gives the same stop again', () {
      for (final Row r in rows()) {
        expect(todaysAdventure(r.$3), todaysAdventure(r.$3));
      }
    });

    test('over random inputs: always inside the open lands, on the land\'s path, never none while a lesson exists', () {
      final math.Random random = math.Random(2026);
      final List<String> all = landOfLesson.keys.toList();
      final List<String> skills = landOfSkillPrefix.keys.map((String p) => '$p-A-01').toList();
      for (int n = 0; n < 600; n++) {
        final Set<TrophyLand> enabled = <TrophyLand>{
          for (final TrophyLand l in TrophyLand.values)
            if (random.nextInt(3) > 0) l,
        };
        final Map<String, int> finished = <String, int>{
          for (final String id in all)
            if (random.nextBool()) id: 1 + random.nextInt(3),
        };
        final List<Visit> visits = <Visit>[
          for (int i = random.nextInt(8); i > 0; i--) _randomVisit(random, all, skills),
        ];
        final List<DueSkill> dues = <DueSkill>[
          for (final String skill in (skills.toList()..shuffle(random)).take(random.nextInt(3)))
            _randomDue(random, skill),
        ];
        final AdventureInput a = AdventureInput(
          today: today,
          band: random.nextInt(3),
          enabledLands: enabled,
          paths: fixturePaths,
          finished: finished,
          visits: visits,
          due: dues,
        );
        final TodaysAdventure got = todaysAdventure(a);
        if (enabled.isEmpty) {
          expect(got.kind, AdventureKind.none);
          continue;
        }
        expect(got.kind, isNot(AdventureKind.none), reason: 'an open land has a lesson');
        expect(enabled, contains(got.land));
        if (got.kind == AdventureKind.revisit) {
          final DueSkill d = dues.firstWhere((DueSkill x) => x.skillId == got.skillId);
          expect(d.land, got.land);
          expect(d.reviewedToday, isFalse, reason: 'never a skill taken today');
        } else {
          expect(fixturePaths[got.land]!.map((PathLesson l) => l.id), contains(got.lessonId));
        }
      }
    });

    test('QA: over random inputs a resting lesson is offered only when nothing else can be', () {
      final math.Random random = math.Random(31);
      final List<String> all = landOfLesson.keys.toList();
      final List<String> skills = landOfSkillPrefix.keys.map((String p) => '$p-A-01').toList();
      for (int n = 0; n < 800; n++) {
        final Map<String, int> finished = <String, int>{
          for (final String id in all)
            if (random.nextBool()) id: 1 + random.nextInt(3),
        };
        final List<Visit> visits = <Visit>[
          for (int i = random.nextInt(8); i > 0; i--) _randomVisit(random, all, skills),
        ];
        final AdventureInput a = AdventureInput(
          today: today,
          band: 0,
          enabledLands: TrophyLand.values.toSet(),
          paths: fixturePaths,
          finished: finished,
          visits: visits,
        );
        final TodaysAdventure got = todaysAdventure(a);
        if (got.kind != AdventureKind.lesson && got.kind != AdventureKind.replay) continue;
        final Visit? last = _lastLessonVisit(visits, got.lessonId);
        final bool resting =
            last != null && last.day == today && last.end == VisitEnd.home && last.lastIncorrect;
        if (!resting) continue;
        // Offered although it rests: then every land has nothing else (the row-20 fallback), so a replay must not exist
        // and no other land may have new learning.
        expect(got.kind, AdventureKind.lesson, reason: 'a replay never offers a resting lesson');
        for (final TrophyLand l in TrophyLand.values) {
          if (l == got.land) continue;
          final String next = nextOnPath(<String>[
            for (final PathLesson p in fixturePaths[l]!) p.id,
          ], finished)!;
          final Visit? lv = _lastLessonVisit(visits, next);
          final bool nextRests = lv != null && lv.day == today && lv.end == VisitEnd.home && lv.lastIncorrect;
          expect((finished[next] ?? 0) > 0 || nextRests, isTrue, reason: 'run $n: $l still had new learning');
        }
      }
    });

    test('a lesson that rests is never offered unless it is the only choice', () {
      // Every lesson of counting played and finished before; n2 left today after an incorrect answer.
      final AdventureInput a = input(
        enabled: <TrophyLand>{TrophyLand.counting, TrophyLand.colors},
        finished: everything(),
        visits: <String>['L:n4 D-1 fin', 'L:n2 D home incorrect'],
      );
      final TodaysAdventure got = todaysAdventure(a);
      expect(got.kind, AdventureKind.replay);
      expect(got.lessonId, isNot('n2'));
    });

    test('the bottle never asks for a day count, a time or a random source: the file is pure', () {
      for (final String name in <String>['todays_adventure.dart', 'lesson_path.dart']) {
        final String text = File('lib/world/$name').readAsStringSync();
        expect(text.contains('DateTime.now'), isFalse, reason: name);
        expect(text.contains('Random'), isFalse, reason: name);
        expect(
          RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''', multiLine: true).allMatches(text).map((m) => m[1]),
          everyElement(anyOf(startsWith('../rewards/award'), equals('lesson_path.dart'))),
          reason: '$name imports only the pure award enum and the path function',
        );
      }
    });
  });
}

Visit? _lastLessonVisit(List<Visit> visits, String? id) {
  Visit? found;
  for (final Visit v in visits) {
    if (v.kind == VisitKind.lesson && v.id == id) found = v;
  }
  return found;
}

Visit _randomVisit(math.Random random, List<String> lessons, List<String> skills) {
  final int kind = random.nextInt(4);
  final int d = today - random.nextInt(3);
  final VisitEnd end = VisitEnd.values[random.nextInt(VisitEnd.values.length)];
  if (kind == 0) {
    final String skill = skills[random.nextInt(skills.length)];
    return Visit(
      kind: VisitKind.revisit,
      land: landOfSkillPrefix[skill.split('-').first]!,
      id: skill,
      day: d,
      end: end,
      lastIncorrect: random.nextBool(),
    );
  }
  final String id = lessons[random.nextInt(lessons.length)];
  return Visit(
    kind: kind == 1 ? VisitKind.warmUp : VisitKind.lesson,
    land: landOfLesson[id]!,
    id: id,
    day: d,
    end: end,
    lastIncorrect: random.nextBool(),
  );
}

DueSkill _randomDue(math.Random random, String skill) {
  return DueSkill(
    skillId: skill,
    land: landOfSkillPrefix[skill.split('-').first]!,
    dueAt: DateTime.utc(2026, 10, 1 + random.nextInt(20)),
    reviewedToday: random.nextInt(3) == 0,
  );
}
