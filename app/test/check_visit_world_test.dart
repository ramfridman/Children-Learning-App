// The check visit of a language course, in the course home and in Today's Adventure (docs/languages/band-a-build.md section 7.4, C-2; the
// owner's OK of 2026-11-07 for the revisit slot): which skill is ready, where the visit stands among the placement, a revisit of a fresh
// skill and the next lesson, at most one a day for a course, what follows two failed visits, and the visit's short lesson.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/adventure_land.dart';
import 'package:nitznutz/world/check_visits.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/placement.dart' show landPath;
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/course_history.dart';
import 'support/course_packs.dart';
import 'support/starter.dart';

const LanguageLand eng = LanguageLand('eng');
final DateTime _now = DateTime.utc(2026, 11, 4, 9);
final DateTime _yesterday = DateTime.utc(2026, 11, 3, 9);

/// The fixture English pack's ENG-A-01 (two lessons of three learn items) with two checks added: a transfer and a reverse.
Catalog _catalog(PackContent pack) {
  final Catalog base = engineCatalog(pack);
  ItemMeta check(String id, CheckType type, Representation rep) => ItemMeta(
    id: 'eng.$id',
    course: 'eng',
    skills: const <String, double>{'ENG-A-01': 1},
    purpose: Purpose.check,
    checkType: type,
    representation: rep,
    variantGroup: id,
    difficulty: 0.5,
    optionCount: 3,
  );
  return Catalog(
    skills: base.skills.values,
    items: <ItemMeta>[
      ...base.items.values,
      check('chk_transfer', CheckType.transfer, Representation.pictorial),
      check('chk_reverse', CheckType.reverse, Representation.pictorial),
    ],
    tags: base.tags.values,
  );
}

const List<String> _hello1 = <String>['hi_mika_arrive', 'hi_mika_hello', 'hi_pip_hello'];
const List<String> _hello2 = <String>['hi_pip_leave', 'hi_mika_bye', 'hi_pip_bye'];

/// The rows of a child's visits in the fixture pack, for the record of the visits (the engine is made apart, from plain events).
class _Story {
  _Story() : pack = courseContent('eng') {
    catalog = _catalog(pack);
  }

  final PackContent pack;
  late final Catalog catalog;
  final List<Attempt> attempts = <Attempt>[];
  final List<Session> sessions = <Session>[];
  int _id = 0;

  /// A visit at [at] of lesson [lessonId] with the answers [ids]; a name ending with `!` is answered wrongly.
  void visit(String lessonId, DateTime at, List<String> ids) {
    final int session = sessions.length + 1;
    sessions.add(
      sessionRow(session, lessonId.startsWith('mission-') ? 'mission:$lessonId' : 'lesson:$lessonId', at: at),
    );
    for (final String id in ids) {
      final bool wrong = id.endsWith('!');
      final String name = wrong ? id.substring(0, id.length - 1) : id;
      attempts.add(
        attemptRow(
          pack,
          // The activities the visit asks that are not in the fixture pack are answered as an item that is, for the visit's record.
          pack.activities.containsKey('eng.$name') ? name : 'hi_mika_arrive',
          result: wrong ? 'incorrect' : 'correct',
          at: at.add(Duration(minutes: ++_id)),
          lessonId: lessonId,
          id: _id,
          sessionId: session,
        ),
      );
    }
  }
}

/// Replays plain events into an engine made on the story's catalogue.
Engine _engineWith(
  Catalog catalog,
  List<(String, DateTime, bool, int)> answers, {
  Set<String> assumed = const <String>{},
}) {
  final Engine e = Engine(catalog: catalog)..assume(assumed);
  int n = 0;
  for (final (String, DateTime, bool, int) a in answers) {
    e.apply(
      AttemptEvent(
        id: ++n,
        at: a.$2.add(Duration(minutes: n)),
        activityId: 'eng.${a.$1}',
        result: a.$3 ? Result.correct : Result.incorrect,
        sessionId: a.$4,
        course: 'eng',
      ),
    );
  }
  return e;
}

List<(String, DateTime, bool, int)> _day(DateTime at, int session, List<String> ids) =>
    <(String, DateTime, bool, int)>[
      for (final String id in ids) (id.replaceAll('!', ''), at, !id.endsWith('!'), session),
    ];

TodaysAdventure _stop(
  PackContent pack,
  Engine engine, {
  Map<String, int> finished = const <String, int>{},
  Set<String> assumed = const <String>{},
  List<Attempt> attempts = const <Attempt>[],
  List<Session> sessions = const <Session>[],
  int band = 0,
}) => courseStopFor(
  course: LanguageCourse(content: pack, engine: engine, assumed: assumed),
  attempts: attempts,
  sessions: sessions,
  finished: finished,
  now: _now,
  band: band,
);

const Map<String, int> _bothLessons = <String, int>{'eng.hello_1': 1, 'eng.hello_2': 1};

void main() {
  final PackContent pack = courseContent('eng');
  final Catalog catalog = _catalog(pack);

  group('C-2: where the check visit stands in the course', () {
    test('a skill whose lessons are all finished, answered on an earlier day, gets the visit before the next lesson', () {
      final Engine e = _engineWith(catalog, <(String, DateTime, bool, int)>[
        ..._day(_yesterday, 1, _hello1),
        ..._day(_yesterday, 2, _hello2),
      ]);
      final TodaysAdventure stop = _stop(pack, e, finished: _bothLessons);
      expect(stop, TodaysAdventure.checkVisit(eng, 'ENG-A-01'));
      expect(stop.kind, AdventureKind.revisit, reason: 'a revisit by kind: it takes the revisit\'s slot');
    });

    test('while a lesson of the skill is not finished, it is not ready: the next lesson comes', () {
      final Engine e = _engineWith(catalog, _day(_yesterday, 1, _hello1));
      final TodaysAdventure stop = _stop(pack, e, finished: <String, int>{'eng.hello_1': 1});
      expect(stop.kind, AdventureKind.lesson);
      expect(stop.lessonId, 'eng.hello_2');
    });

    test('answered today it is not ready: the visit is on a later day than the last lesson', () {
      final Engine e = _engineWith(catalog, <(String, DateTime, bool, int)>[
        ..._day(_yesterday, 1, _hello1),
        ..._day(_now, 2, _hello2),
      ]);
      expect(_stop(pack, e, finished: _bothLessons).kind, isNot(AdventureKind.revisit));
    });

    test('at most one a day for a course: after a check visit today, another skill that is ready waits for another day', () {
      const Map<String, int> all = <String, int>{
        'eng.hello_1': 1,
        'eng.hello_2': 1,
        'eng.colours_1': 1,
        'eng.colours_2': 1,
      };
      final List<(String, DateTime, bool, int)> answers = <(String, DateTime, bool, int)>[
        ..._day(_yesterday, 1, _hello1),
        ..._day(_yesterday, 2, _hello2),
        ..._day(_yesterday, 3, <String>['col_red', 'col_blue', 'col_yellow', 'col_green']),
        ..._day(_yesterday, 4, <String>['boat_red', 'boat_blue']),
      ];
      expect(
        _stop(pack, _engineWith(catalog, answers), finished: all),
        TodaysAdventure.checkVisit(eng, 'ENG-A-01'),
        reason: 'without a visit today the skill whose last answer is oldest is offered',
      );
      // ENG-A-01 is visited this morning: it is answered today, and the visit is on record.
      final _Story s = _Story()
        ..visit('mission-eng-a-01-check', _now.subtract(const Duration(hours: 1)), <String>[
          'hi_mika_arrive',
        ]);
      final Engine e = _engineWith(catalog, <(String, DateTime, bool, int)>[
        ...answers,
        ..._day(_now.subtract(const Duration(hours: 1)), 5, <String>['chk_transfer']),
      ]);
      final TodaysAdventure stop = _stop(pack, e, finished: all, attempts: s.attempts, sessions: s.sessions);
      expect(
        stop.kind,
        AdventureKind.lesson,
        reason: 'ENG-A-03 is ready too, but a course has one visit a day',
      );
      expect(
        _stop(pack, e, finished: all).skillId,
        'ENG-A-03',
        reason: 'and without the record of the visit it would have had one',
      );
    });

    test('the visit is told from the revisit of a fresh skill in the record, and counts as a revisit for the rule of the day', () {
      final _Story s = _Story()..visit('mission-eng-a-01-check', _now, <String>['hi_mika_arrive']);
      final List<Visit> visits = visitsFrom(null, s.attempts, s.sessions, languages: <PackContent>[pack]);
      expect(visits.single.kind, VisitKind.revisit);
      expect(visits.single.check, isTrue);
      final _Story plain = _Story()..visit('mission-eng-a-01', _now, <String>['hi_mika_arrive']);
      expect(
        visitsFrom(null, plain.attempts, plain.sessions, languages: <PackContent>[pack]).single.check,
        isFalse,
      );
      expect(isCheckVisitId('mission-eng-a-01-check'), isTrue);
      expect(isCheckVisitId('mission-eng-a-01'), isFalse);
      expect(checkVisitIdOf('ENG-A-01'), 'mission-eng-a-01-check');
    });

    test('a skill placement took as known is verified by a visit, though nothing of it was answered', () {
      final Engine e = _engineWith(
        catalog,
        const <(String, DateTime, bool, int)>[],
        assumed: <String>{'ENG-A-01'},
      );
      final TodaysAdventure stop = _stop(pack, e, finished: _bothLessons, assumed: <String>{'ENG-A-01'});
      expect(stop, TodaysAdventure.checkVisit(eng, 'ENG-A-01'));
    });

    test('the skill whose last answer is oldest comes first', () {
      final Engine e = _engineWith(catalog, <(String, DateTime, bool, int)>[
        ..._day(_yesterday.subtract(const Duration(days: 2)), 1, <String>['hi_mika_arrive']),
        ..._day(_yesterday, 2, <String>['hi_pip_leave']),
      ]);
      final DueSkill? due = checkVisitDue(
        content: pack,
        engine: e,
        assumed: const <String>{},
        seen: const <String, int>{'eng.hello_1': 1, 'eng.hello_2': 1, 'eng.colours_1': 1, 'eng.colours_2': 1},
        visits: const <Visit>[],
        now: _now,
        band: 0,
      );
      expect(due!.skillId, 'ENG-A-01');
      expect(due.check, isTrue);
      expect(due.dueAt, isNotNull);
    });
  });

  group(
    'Today\'s Adventure offers the course\'s check visit in its revisit slot (owner\'s OK 2026-11-07)',
    () {
      late PackContent starter;
      setUpAll(() async => starter = await loadStarter());

      AdventureInput input(Engine e, {Map<String, int> finished = const <String, int>{}}) => adventureInput(
        content: starter,
        engine: Engine(catalog: engineCatalog(starter)),
        attempts: const <Attempt>[],
        sessions: const <Session>[],
        finished: finished,
        now: _now,
        band: 0,
        languages: <LanguageCourse>[LanguageCourse(content: pack, engine: e)],
        enabledCourses: const <String>{'eng'},
      );

      Engine ready() => _engineWith(catalog, <(String, DateTime, bool, int)>[
        ..._day(_yesterday, 1, _hello1),
        ..._day(_yesterday, 2, _hello2),
      ]);

      test('the course\'s due list carries its check visit, marked, with no reteach lesson', () {
        final AdventureInput a = input(ready(), finished: _bothLessons);
        final DueSkill d = a.due.singleWhere((DueSkill d) => d.check);
        expect((d.skillId, d.land, d.reteachLessonId), ('ENG-A-01', eng, null));
        expect(todaysAdventure(a), TodaysAdventure.checkVisit(eng, 'ENG-A-01'));
      });

      test('a course whose lessons are not finished has none', () {
        expect(input(ready()).due.where((DueSkill d) => d.check), isEmpty);
      });

      test('a due revisit of a fresh skill comes first, and the check visit stays for another time', () {
        final DueSkill revisit = DueSkill(skillId: 'ENG-A-03', land: eng, dueAt: DateTime.utc(2026, 11, 3));
        final DueSkill check = DueSkill(
          skillId: 'ENG-A-01',
          land: eng,
          dueAt: DateTime.utc(2026, 10, 1),
          check: true,
        );
        for (final List<DueSkill> order in <List<DueSkill>>[
          <DueSkill>[revisit, check],
          <DueSkill>[check, revisit],
        ]) {
          final TodaysAdventure stop = todaysAdventure(_ruleInput(order));
          expect(
            stop,
            TodaysAdventure.revisit(eng, 'ENG-A-03'),
            reason: 'never ahead of a due revisit of a skill that is mastered',
          );
        }
        expect(todaysAdventure(_ruleInput(<DueSkill>[check])), TodaysAdventure.checkVisit(eng, 'ENG-A-01'));
      });

      test('after a revisit or a check visit today, two lessons come before another one', () {
        final DueSkill check = DueSkill(
          skillId: 'ENG-A-01',
          land: eng,
          dueAt: DateTime.utc(2026, 10, 1),
          check: true,
        );
        final TodaysAdventure stop = todaysAdventure(
          _ruleInput(
            <DueSkill>[check],
            visits: <Visit>[
              Visit(
                kind: VisitKind.revisit,
                land: eng,
                id: 'ENG-A-02',
                day: Engine.dayKey(_now),
                check: true,
              ),
            ],
          ),
        );
        expect(stop.kind, AdventureKind.lesson);
      });

      test(
        'a check visit whose skill failed twice sends the child to the skill\'s last lesson, played again',
        () {
          final DueSkill reteach = DueSkill(
            skillId: 'ENG-A-01',
            land: eng,
            dueAt: DateTime.utc(2026, 10, 1),
            check: true,
            reteachLessonId: 'eng.hello_2',
          );
          expect(
            todaysAdventure(_ruleInput(<DueSkill>[reteach])),
            TodaysAdventure.replay(eng, 'eng.hello_2'),
          );
        },
      );

      test('the reason has the line of its language: no word of a check, a test or help', () {
        expect(TodaysAdventure.checkVisit(eng, 'ENG-A-01').reason, AdventureReason.checkVisit);
      });
    },
  );

  group('C-4: two visits in a row with a failed check', () {
    test('the course offers the skill\'s last lesson again, and the visit only after it was taught', () {
      final DateTime d1 = DateTime.utc(2026, 11, 1, 9);
      final DateTime d2 = DateTime.utc(2026, 11, 2, 9);
      final DateTime d3 = DateTime.utc(2026, 11, 3, 9);
      final Engine e = _engineWith(catalog, <(String, DateTime, bool, int)>[
        ..._day(d1, 1, _hello1),
        ..._day(d1, 2, _hello2),
        ..._day(d2, 3, <String>['hi_mika_arrive', 'chk_transfer!']),
        ..._day(d3, 4, <String>['hi_pip_leave', 'chk_reverse!']),
      ]);
      expect(e.state.skills['ENG-A-01']!.trail.needsReteach, isTrue);
      final TodaysAdventure stop = _stop(pack, e, finished: _bothLessons);
      expect(stop, TodaysAdventure.replay(eng, 'eng.hello_2'));
      // The lesson is played (on the day of the check visit's turn): the skill is taught again.
      final Engine after = _engineWith(catalog, <(String, DateTime, bool, int)>[
        ..._day(d1, 1, _hello1),
        ..._day(d1, 2, _hello2),
        ..._day(d2, 3, <String>['hi_mika_arrive', 'chk_transfer!']),
        ..._day(d3, 4, <String>['hi_pip_leave', 'chk_reverse!']),
        ..._day(_yesterday, 5, <String>['hi_pip_bye']),
      ]);
      expect(_stop(pack, after, finished: _bothLessons), TodaysAdventure.checkVisit(eng, 'ENG-A-01'));
    });
  });

  group('the visit\'s short lesson', () {
    test(
      'it is a mission of the skill with the visit\'s items, ended by a lesson\'s celebration of the course',
      () {
        final Engine e = _engineWith(catalog, <(String, DateTime, bool, int)>[
          ..._day(_yesterday, 1, _hello1),
          ..._day(_yesterday, 2, _hello2),
        ]);
        final Lesson lesson = courseCheckVisit(
          LanguageCourse(content: pack, engine: e),
          'ENG-A-01',
          band: 0,
        )!;
        expect(lesson.id, 'mission-eng-a-01-check');
        expect(lesson.skillIds, <String>['ENG-A-01']);
        expect(lesson.itemIds.length, inInclusiveRange(3, 5));
        expect(lesson.itemIds, contains('eng.chk_transfer'));
        expect(lesson.itemIds.first, startsWith('eng.hi_'), reason: 'it opens with a learn item');
        expect(lesson.celebration.vo, pack.lessons['eng.hello_1']!.celebration.vo);
      },
    );

    test('a skill with nothing to ask has none', () {
      final Engine e = Engine(
        catalog: Catalog(skills: catalog.skills.values, items: const <ItemMeta>[]),
      );
      expect(courseCheckVisit(LanguageCourse(content: pack, engine: e), 'ENG-A-01', band: 0), isNull);
    });
  });

  group('taught skills and the checks that stand in a lesson', () {
    test(
      'a skill is taught when every lesson that names it is finished or placed, or placement assumed it',
      () {
        final List<Lesson> path = landPath(pack, Course.languagesDomain);
        expect(
          taughtSkills(path, const <String, int>{'eng.hello_1': 1}, const <String>{}),
          isNot(contains('ENG-A-01')),
        );
        expect(taughtSkills(path, _bothLessons, const <String>{}), contains('ENG-A-01'));
        expect(taughtSkills(path, const <String, int>{}, const <String>{'ENG-A-05'}), contains('ENG-A-05'));
      },
    );

    test('a check that is in a lesson is not one the visit serves', () {
      final List<Lesson> path = landPath(pack, Course.languagesDomain);
      expect(checksInLessons(path, catalog), isEmpty, reason: 'the fixture lessons hold learn items only');
    });
  });
}

AdventureInput _ruleInput(List<DueSkill> due, {List<Visit> visits = const <Visit>[]}) => AdventureInput(
  today: Engine.dayKey(_now),
  band: 0,
  enabledLands: <AdventureLand>{eng},
  paths: <AdventureLand, List<PathLesson>>{
    eng: const <PathLesson>[
      PathLesson('eng.hello_1', 0),
      PathLesson('eng.hello_2', 0),
      PathLesson('eng.colours_1', 0),
    ],
  },
  finished: const <String, int>{'eng.hello_1': 1, 'eng.hello_2': 1},
  visits: visits,
  due: due,
);
