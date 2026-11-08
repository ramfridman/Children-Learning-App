// M10 E0b, the lands' warm-up as a staircase (audit F7): two right answers go up a unit, one wrong goes down, it stops after two
// reversals or eight items, and a child is placed at the highest unit with two thirds right, minus one unit. The start is the school
// stage's prior (the profile's band). One lucky answer places nobody; the old warm-up marked a lesson as known by one right first
// answer.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/bundled_packs.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/staircase.dart';
import 'package:nitznutz/play/lesson_controller.dart' show ItemFlow;
import 'package:nitznutz/world/land_placement.dart';
import 'package:nitznutz/world/next_lesson.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/land_pack.dart';
import 'support/starter.dart';

int _row = 0;

/// One recorded answer of the warm-up. A probe the child needed help with is two rows, as the lesson writes it: the miss, then the right
/// answer at the second try.
List<Attempt> _answer(String activity, {required bool right, String lesson = placementId}) {
  Attempt row(String result, int no, int hint) {
    _row++;
    return Attempt(
      id: _row,
      at: DateTime.utc(2026, 11, 6, 9).add(Duration(seconds: _row)),
      profileId: 'p-1',
      packId: 'starter',
      packVersion: bundledStarterVersion,
      lessonId: lesson,
      activityId: activity,
      activityRevision: 1,
      template: 'tap_answer',
      templateVersion: '1.0',
      skillId: 'NUM-A-01',
      result: result,
      attemptNo: no,
      hintLevel: hint,
      misconceptionTag: '',
      response: 'o1',
      durationMs: 1000,
      sessionId: null,
      input: 'tap',
    );
  }

  return right ? <Attempt>[row('correct', 1, 0)] : <Attempt>[row('incorrect', 1, 0), row('correct', 2, 1)];
}

/// Plays the warm-up of [domain] against a child who answers right exactly when [knows] says so for the probe. Returns every row written.
List<Attempt> _play(
  PackContent content,
  String domain,
  bool Function(String probe, int level) knows, {
  SchoolStage stage = SchoolStage.gan5,
  List<Attempt> before = const <Attempt>[],
}) {
  final ({Lesson lesson, ItemFlow flow})? visit = placementVisit(content, domain, before, stage: stage);
  expect(visit, isNotNull);
  final LandPlacement shape = landPlacementOf(content, domain, before, stage: stage)!;
  final List<Attempt> rows = <Attempt>[...before];
  String? probe = visit!.flow.first();
  int guard = 0;
  while (probe != null && guard++ < 20) {
    final bool right = knows(probe, shape.levelOfProbe(probe)!);
    rows.addAll(_answer(probe, right: right));
    probe = visit.flow.after(probe, right: right);
  }
  return rows;
}

void main() {
  late PackContent starter;
  late PackContent land;
  setUpAll(() async {
    starter = await loadStarter();
    land = landPack();
  });

  group('the levels of a land', () {
    test('Counting Hills of the starter pack: four units of Band A, then four of Band B, named A1 to B4', () {
      final List<PlacementLevel> levels = placementLevels(starter, 'numbers');
      expect(
        <String>[for (final PlacementLevel l in levels) l.label],
        <String>['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'B3', 'B4'],
      );
    });

    test('the units cut the path into pieces: no lesson twice, none left out, each unit in path order', () {
      for (final String domain in <String>['numbers', 'math', 'shapes', 'logic', 'colors', 'cs']) {
        final List<PlacementLevel> levels = placementLevels(starter, domain);
        final List<String> path = <String>[for (final Lesson l in landPath(starter, domain)) l.id];
        final List<String> all = <String>[for (final PlacementLevel l in levels) ...l.lessons];
        expect(all.toSet(), path.toSet(), reason: domain);
        expect(all.length, path.length, reason: '$domain: no lesson in two units');
        for (final PlacementLevel l in levels) {
          final List<int> places = <int>[for (final String id in l.lessons) path.indexOf(id)];
          expect(<int>[...places]..sort(), places, reason: '$domain ${l.label}');
        }
        // The bands go up the ladder.
        expect(<int>[for (final PlacementLevel l in levels) l.band], isNotEmpty);
        final List<int> bands = <int>[for (final PlacementLevel l in levels) l.band];
        expect(<int>[...bands]..sort(), bands, reason: domain);
      }
    });

    test('every unit has two to four probes: activities of its own lessons, each wholly of this land', () {
      for (final String domain in <String>['numbers', 'math', 'shapes', 'logic', 'colors', 'cs']) {
        for (final PlacementLevel l in placementLevels(starter, domain)) {
          expect(l.probes.length, inInclusiveRange(2, 4), reason: '$domain ${l.label}');
          expect(l.probes.toSet().length, l.probes.length);
          for (final String id in l.probes) {
            final Activity a = starter.activities[id]!;
            expect(
              a.skills.every((Skill s) => starter.skills[s.id]!.domain == domain),
              isTrue,
              reason: '$domain ${l.label} $id',
            );
            expect(
              l.lessons.any((String lesson) => starter.lessons[lesson]!.itemIds.contains(id)),
              isTrue,
              reason: '$id is in a lesson of ${l.label}',
            );
          }
        }
      }
    });

    test('no probe belongs to two lands, so an answer says which land it was given in', () {
      final Map<String, String> owner = <String, String>{};
      for (final String domain in <String>['numbers', 'math', 'shapes', 'logic', 'colors', 'cs']) {
        for (final PlacementLevel l in placementLevels(starter, domain)) {
          for (final String id in l.probes) {
            expect(owner.putIfAbsent(id, () => domain), domain, reason: id);
          }
        }
      }
    });

    test('a land with fewer than three lessons has no warm-up', () {
      expect(placementLevels(starter, 'none'), isEmpty);
      expect(landPlacementOf(starter, 'none', const <Attempt>[]), isNull);
      expect(placementVisit(starter, 'none', const <Attempt>[]), isNull);
    });
  });

  group('where the staircase starts: the school stage\'s prior', () {
    test('the middle unit of the child\'s band, minus one unit', () {
      final List<PlacementLevel> levels = placementLevels(land, 'numbers');
      expect(levels.map((PlacementLevel l) => l.label), <String>[
        'A1',
        'A2',
        'A3',
        'B1',
        'B2',
        'B3',
        'C1',
        'C2',
        'C3',
      ]);
      expect(levels[startLevelFor(levels, SchoolStage.gan4)].label, 'A1');
      expect(levels[startLevelFor(levels, SchoolStage.gan5)].label, 'B1');
      expect(levels[startLevelFor(levels, SchoolStage.grade2)].label, 'C1');
    });

    test(
      'the stage decides through its band: gan 3 and gan 4 start alike, gan 5 and grade 1, grades 2 and 3',
      () {
        final List<PlacementLevel> levels = placementLevels(land, 'numbers');
        String at(SchoolStage s) => levels[startLevelFor(levels, s)].label;
        expect(
          <String>[for (final SchoolStage s in SchoolStage.values) at(s)],
          <String>['A1', 'A1', 'B1', 'B1', 'C1', 'C1'],
        );
      },
    );

    test('a band the pack does not have yet starts in the highest band it has', () {
      final List<PlacementLevel> levels = placementLevels(starter, 'numbers');
      expect(levels[startLevelFor(levels, SchoolStage.grade2)].label, 'B2');
      expect(levels[startLevelFor(levels, SchoolStage.gan4)].label, 'A2');
    });

    test('the first probe the child is given is in the start unit', () {
      final List<PlacementLevel> levels = placementLevels(land, 'numbers');
      final ({Lesson lesson, ItemFlow flow}) visit = placementVisit(
        land,
        'numbers',
        const <Attempt>[],
        stage: SchoolStage.grade2,
      )!;
      expect(levels[startLevelFor(levels, SchoolStage.grade2)].probes, contains(visit.flow.first()));
      expect(visit.lesson.id, placementId);
      expect(visit.lesson.itemIds, <String>[visit.flow.first()]);
    });
  });

  group('the staircase places by what was answered', () {
    test(
      'a child who knows Band B and not Band C is placed at the top of Band B and starts Band B\'s last unit',
      () {
        final List<PlacementLevel> levels = placementLevels(land, 'numbers');
        final List<Attempt> rows = _play(
          land,
          'numbers',
          (String probe, int level) => level <= 5,
          stage: SchoolStage.grade2,
        );
        final LandPlacement p = landPlacementOf(land, 'numbers', rows, stage: SchoolStage.grade2)!;
        expect(p.stopped, isTrue);
        expect(levels[p.best!].label, 'B3');
        expect(
          levels[p.entry!].label,
          'B2',
          reason: 'the highest unit with two thirds right, minus one unit',
        );
        expect(p.placedLessons, <String>{
          'a1',
          'a2',
          'a3',
          'a4',
          'a5',
          'a6',
          'a7',
          'a8',
          'a9',
          'b1',
          'b2',
          'b3',
        });
        expect(rows.length, lessThanOrEqualTo(Staircase.mostItems * 2), reason: 'at most eight probes');
      },
    );

    test('a child who knows all of Band B climbs into Band C within the warm-up', () {
      final List<PlacementLevel> levels = placementLevels(land, 'numbers');
      final List<Attempt> rows = _play(
        land,
        'numbers',
        (String probe, int level) => level <= 6,
        stage: SchoolStage.gan5,
      );
      final LandPlacement p = landPlacementOf(land, 'numbers', rows, stage: SchoolStage.gan5)!;
      expect(p.stopped, isTrue);
      expect(levels[p.best!].band, 2, reason: 'the best unit is in Band C');
      expect(levels[p.entry!].label, 'B3', reason: 'and the child starts one unit below it');
    });

    test('a child who knows nothing is placed nowhere: the path starts at its beginning', () {
      final List<Attempt> rows = _play(land, 'numbers', (String probe, int level) => false);
      final LandPlacement p = landPlacementOf(land, 'numbers', rows)!;
      expect(p.stopped, isTrue);
      expect(p.entry, 0);
      expect(p.placedLessons, isEmpty);
      expect(p.assumedSkills(land), isEmpty);
    });

    test('ONE lucky answer places nobody (the old warm-up put a lesson behind the child for it)', () {
      bool lucky = true;
      final List<Attempt> rows = _play(land, 'numbers', (String probe, int level) {
        final bool right = lucky;
        lucky = false;
        return right;
      });
      final LandPlacement p = landPlacementOf(land, 'numbers', rows)!;
      expect(p.placedLessons, isEmpty);
      // The same single right answer, replayed through the old rule, would have finished a lesson.
      expect(
        rows.where((Attempt a) => a.result == 'correct' && a.attemptNo == 1 && a.hintLevel == 0).length,
        1,
      );
    });

    test('a right answer that needed a hint or a second try is not a right answer here', () {
      final List<PlacementLevel> levels = placementLevels(land, 'numbers');
      final String probe = levels[startLevelFor(levels, SchoolStage.gan5)].probes.first;
      final List<Attempt> asked = <Attempt>[..._answer(probe, right: false)];
      final LandPlacement p = landPlacementOf(land, 'numbers', asked)!;
      expect(p.answered, 1);
      expect(p.stairs.result.best, isNull, reason: 'help, then right, counts as a miss');
    });

    test('the answers of other lessons and of other lands are not part of this land\'s warm-up', () {
      final PlacementLevel first = placementLevels(starter, 'numbers').first;
      final String mine = first.probes.first;
      final String theirs = placementLevels(starter, 'shapes').first.probes.first;
      final List<Attempt> rows = <Attempt>[
        ..._answer(mine, right: true, lesson: 'butterflies'),
        ..._answer(theirs, right: true),
      ];
      expect(landPlacementOf(starter, 'numbers', rows)!.answered, 0);
      expect(landPlacementOf(starter, 'shapes', rows)!.answered, 1);
    });

    test('replaying the recorded answers gives the same placement as playing did', () {
      final List<Attempt> rows = _play(
        land,
        'numbers',
        (String probe, int level) => level <= 4,
        stage: SchoolStage.grade2,
      );
      final LandPlacement once = landPlacementOf(land, 'numbers', rows, stage: SchoolStage.grade2)!;
      // The child\'s band changed after the warm-up: the placement does not move, it was read from the answers.
      final LandPlacement later = landPlacementOf(land, 'numbers', rows, stage: SchoolStage.gan4)!;
      expect(later.entry, once.entry);
      expect(later.placedLessons, once.placedLessons);
      expect(
        landPlacementOf(land, 'numbers', rows.reversed.toList(), stage: SchoolStage.grade2)!.entry,
        once.entry,
      );
    });

    test('a warm-up that was left before it stopped places nobody', () {
      final List<PlacementLevel> levels = placementLevels(land, 'numbers');
      final List<Attempt> rows = <Attempt>[
        for (final String id in levels[startLevelFor(levels, SchoolStage.gan5)].probes.take(2))
          ..._answer(id, right: true),
      ];
      final LandPlacement p = landPlacementOf(land, 'numbers', rows)!;
      expect(p.stopped, isFalse);
      expect(p.entry, isNull);
      expect(p.placedLessons, isEmpty);
    });
  });

  group('what the placement does to the path and to the engine', () {
    test('the lessons below the entry unit count as finished once, and their skills are assumed known', () {
      final List<Attempt> rows = _play(
        land,
        'numbers',
        (String probe, int level) => level <= 5,
        stage: SchoolStage.grade2,
      );
      final Map<String, int> finished = finishedLessons(land, rows, const <String>[]);
      expect(finished['a1'], 1);
      expect(finished['b3'], 1);
      expect(finished.containsKey('b4'), isFalse);
      final ({Set<String> lessons, Set<String> skills}) placed = placedByWarmUp(land, rows);
      expect(placed.skills, containsAll(<String>['NUM-A-01', 'NUM-A-09', 'NUM-B-03']));
      expect(placed.skills, isNot(contains('NUM-B-04')));
    });

    test('the first lesson offered after the warm-up is the entry unit\'s, and Band C waits until the unit is learned', () {
      final List<Attempt> rows = _play(
        land,
        'numbers',
        (String probe, int level) => level <= 5,
        stage: SchoolStage.grade2,
      );
      final ({Set<String> lessons, Set<String> skills}) placed = placedByWarmUp(land, rows);
      final Engine engine = Engine(catalog: engineCatalog(land))..assume(placed.skills);
      final Map<String, int> finished = finishedLessons(land, rows, const <String>[]);
      expect(
        nextLessonId(content: land, domain: 'numbers', finished: finished, unlocked: engine.isUnlocked),
        'b4',
      );
      // The unit was played but not learned: Band C stays shut, and so does the rest of Band B; the path goes round what is open.
      finished['b4'] = 1;
      final String? again = nextLessonId(
        content: land,
        domain: 'numbers',
        finished: finished,
        unlocked: engine.isUnlocked,
      );
      expect(again, isNot(startsWith('c')));
      expect(again, isNot('b5'));
    });

    test(
      'the warm-up is due once: not after it was played, and not for a child who already played in the land',
      () {
        expect(placementDue(starter, 'numbers', const <Attempt>[]), isTrue);
        final List<Attempt> played = _play(starter, 'numbers', (String probe, int level) => true);
        expect(placementDue(starter, 'numbers', played), isFalse);
        expect(
          placementDue(
            starter,
            'numbers',
            _answer(starter.lessons['butterflies']!.itemIds.first, right: true, lesson: 'butterflies'),
          ),
          isFalse,
        );
        expect(placementDue(starter, 'none', const <Attempt>[]), isFalse);
      },
    );

    test(
      'the warm-up is per land: the Counting Hills warm-up played leaves Shapes and Colour Bay theirs',
      () {
        final List<Attempt> numbers = _play(starter, 'numbers', (String probe, int level) => true);
        expect(placementDue(starter, 'numbers', numbers), isFalse);
        for (final String land in <String>['colors', 'shapes', 'logic', 'cs', 'math']) {
          expect(placementDue(starter, land, numbers), isTrue, reason: land);
        }
      },
    );
  });

  group('the visit: a flow of the staircase', () {
    test('it hands out one probe after another, at most eight, and ends when the staircase stops', () {
      final ({Lesson lesson, ItemFlow flow}) visit = placementVisit(land, 'numbers', const <Attempt>[])!;
      final List<String> given = <String>[];
      String? probe = visit.flow.first();
      while (probe != null && given.length < 20) {
        given.add(probe);
        probe = visit.flow.after(probe, right: true);
      }
      expect(given.length, lessThanOrEqualTo(Staircase.mostItems));
      expect(given.toSet().length, given.length, reason: 'a probe is never asked twice');
      expect(visit.flow.length, Staircase.mostItems);
    });

    test('it ends kindly after two activities that needed all the help, as the old warm-up did', () {
      final ({Lesson lesson, ItemFlow flow}) visit = placementVisit(land, 'numbers', const <Attempt>[])!;
      expect(visit.lesson.stopAfterStruggles, placementStruggles);
    });
  });
}
