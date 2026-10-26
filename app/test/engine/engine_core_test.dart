import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/graph.dart';
import 'package:nitznutz/engine/mastery.dart';
import 'package:nitznutz/engine/params.dart';
import 'package:nitznutz/engine/retention.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'fixtures.dart';

void main() {
  const EngineParams p = EngineParams();

  group('the skill graph', () {
    test('depth, ancestors and dependants', () {
      final SkillGraph g = SkillGraph(smallCatalog());
      expect(g.depth('SK-A-01'), 0);
      expect(g.depth('SK-C-01'), 2);
      expect(g.ancestors('SK-C-01'), <String>{'SK-B-01', 'SK-A-01'});
      expect(g.dependantsOf('SK-A-01'), <String>{'SK-B-01', 'SK-D-01'});
    });

    test('a cycle is refused', () {
      expect(
        () => SkillGraph(
          Catalog(
            skills: const <SkillNode>[
              SkillNode(id: 'X-A-01', prerequisites: <String, double>{'X-B-01': 1}),
              SkillNode(id: 'X-B-01', prerequisites: <String, double>{'X-A-01': 1}),
            ],
            items: const <ItemMeta>[],
          ),
        ),
        throwsStateError,
      );
    });

    test('a prerequisite that does not exist is refused', () {
      expect(
        () => SkillGraph(
          Catalog(
            skills: const <SkillNode>[
              SkillNode(id: 'X-A-01', prerequisites: <String, double>{'X-Z-01': 1}),
            ],
            items: const <ItemMeta>[],
          ),
        ),
        throwsStateError,
      );
    });

    test('the report names skills with no item or one way of being explained', () {
      final Catalog c = Catalog(
        skills: const <SkillNode>[
          SkillNode(id: 'X-A-01'),
          SkillNode(id: 'X-B-01', prerequisites: <String, double>{'X-A-01': 1}),
        ],
        items: const <ItemMeta>[
          ItemMeta(id: 'a', skills: <String, double>{'X-A-01': 1}),
        ],
      );
      expect(
        SkillGraph(c).report(),
        containsAll(<String>['X-A-01 has items in only one representation', 'X-B-01 has no item']),
      );
      expect(SkillGraph(smallCatalog()).report(), isEmpty);
    });

    test('a skill with three dependants is core', () {
      final Catalog c = Catalog(
        skills: const <SkillNode>[
          SkillNode(id: 'X-A-01'),
          SkillNode(id: 'X-B-01', prerequisites: <String, double>{'X-A-01': 1}),
          SkillNode(id: 'X-C-01', prerequisites: <String, double>{'X-A-01': 1}),
          SkillNode(id: 'X-D-01', prerequisites: <String, double>{'X-A-01': 1}),
        ],
        items: const <ItemMeta>[],
      );
      final SkillGraph g = SkillGraph(c);
      expect(g.isCore('X-A-01'), isTrue);
      expect(g.isCore('X-B-01'), isFalse);
    });
  });

  group('mastery estimate (BKT with soft evidence)', () {
    test('a right answer raises it, a wrong one lowers it', () {
      final double up = Bkt.update(0.5, correct: true, weight: 1, optionCount: 3, params: p);
      final double down = Bkt.update(0.5, correct: false, weight: 1, optionCount: 3, params: p);
      expect(up, greaterThan(0.5));
      expect(down, lessThan(0.5));
    });

    test('a worked example (hint 3) changes nothing; hints give less credit', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.right('A.1', hint: 3);
      expect(e.state.skills['SK-A-01']!.p, p.priorNew);
      final Engine f = engineOf(smallCatalog());
      Story(f).right('A.1', hint: 1);
      final Engine g = engineOf(smallCatalog());
      Story(g).right('A.1');
      expect(f.state.skills['SK-A-01']!.p, lessThan(g.state.skills['SK-A-01']!.p));
      expect(f.state.skills['SK-A-01']!.p, greaterThan(p.priorNew));
    });

    test('"not sure" counts for 0.3 of a wrong answer, and a wrong answer lowers more', () {
      final double unsure = Bkt.update(
        0.6,
        correct: false,
        weight: p.unsureWeight,
        optionCount: 3,
        params: p,
      );
      final double wrong = Bkt.update(0.6, correct: false, weight: 1, optionCount: 3, params: p);
      expect(unsure, lessThan(0.6));
      expect(wrong, lessThan(unsure));
      expect((0.6 - unsure) / (0.6 - wrong), closeTo(0.3, 0.2));
    });

    test('a two-option item gives at most half of the evidence of a right answer', () {
      expect(
        Bkt.weightOf(result: Result.correct, hintLevel: 0, skillWeight: 1, optionCount: 2, params: p),
        0.5,
      );
      expect(
        Bkt.weightOf(result: Result.correct, hintLevel: 0, skillWeight: 1, optionCount: 4, params: p),
        1.0,
      );
      expect(
        Bkt.weightOf(result: Result.correct, hintLevel: 1, skillWeight: 1, optionCount: 0, params: p),
        0.8,
      );
      expect(Bkt.guess(2, p), 0.5);
      expect(Bkt.guess(0, p), p.pGuessOpen);
    });

    test('the estimate stays inside 0 to 1 whatever happens', () {
      double x = 0.5;
      for (int i = 0; i < 200; i++) {
        x = Bkt.update(x, correct: true, weight: 1, optionCount: 0, params: p);
      }
      expect(x, lessThanOrEqualTo(0.999));
      for (int i = 0; i < 200; i++) {
        x = Bkt.update(x, correct: false, weight: 1, optionCount: 3, params: p);
      }
      expect(x, greaterThanOrEqualTo(0.001));
    });
  });

  group('memory (FSRS style)', () {
    test('the chance of remembering is 0.9 after one stability', () {
      for (final double s in <double>[0.5, 1, 7, 30]) {
        expect(Retention.retrievability(s, s), closeTo(0.9, 1e-9));
      }
      expect(Retention.retrievability(0, 5), 1);
    });

    test('the check falls due when the chance reaches the target, within 1 to 90 days', () {
      expect(Retention.intervalDays(10, 0.9, p), closeTo(10, 1e-6));
      expect(Retention.intervalDays(0.2, 0.9, p), 1);
      expect(Retention.intervalDays(500, 0.9, p), 90);
      expect(Retention.intervalDays(10, 0.8, p), greaterThan(10));
    });

    test('a pass raises stability (more when the memory had faded), a failure lowers it', () {
      final MemoryState m = Retention.first(at: day0, initialStability: 3, good: true);
      final MemoryState soon = Retention.review(m, at: day0.add(const Duration(days: 1)), good: true);
      final MemoryState late = Retention.review(m, at: day0.add(const Duration(days: 12)), good: true);
      final MemoryState failed = Retention.review(m, at: day0.add(const Duration(days: 3)), good: false);
      expect(soon.stability, greaterThan(m.stability));
      expect(late.stability, greaterThan(soon.stability));
      expect(failed.stability, lessThan(m.stability));
      expect(failed.stability, greaterThan(0));
    });

    test('a second look in the same sitting changes nothing', () {
      final MemoryState m = Retention.first(at: day0, initialStability: 3, good: true);
      expect(Retention.review(m, at: day0.add(const Duration(hours: 2)), good: false), same(m));
    });

    test('stability keeps growing over a run of passed checks, and the gaps grow with it', () {
      MemoryState m = Retention.first(at: day0, initialStability: 1, good: true);
      DateTime at = day0;
      final List<double> gaps = <double>[];
      for (int i = 0; i < 6; i++) {
        final double gap = Retention.intervalDays(m.stability, 0.9, p);
        gaps.add(gap);
        at = at.add(Duration(minutes: (gap * 1440).round()));
        m = Retention.review(m, at: at, good: true);
      }
      for (int i = 1; i < gaps.length; i++) {
        expect(gaps[i], greaterThanOrEqualTo(gaps[i - 1]));
      }
      expect(gaps.last, greaterThan(gaps.first * 3));
    });
  });

  group('the status of a skill', () {
    Engine fresh() => engineOf(smallCatalog());

    test('ready, learning, fresh mastery, durable mastery', () {
      final Engine e = fresh();
      expect(e.statusOf('SK-A-01', day0), SkillStatus.ready);
      expect(e.statusOf('SK-B-01', day0), SkillStatus.notStarted);
      final Story s = Story(e);
      s.right('A.1');
      expect(e.statusOf('SK-A-01', s.at), SkillStatus.learning);
      // Day 1: more right answers without a hint, in two representations, including the reverse check.
      for (final String item in <String>['A.1', 'A.2', 'A.1', 'A.2']) {
        s.right(item);
      }
      expect(e.statusOf('SK-A-01', s.at), SkillStatus.learning, reason: 'one day only');
      s.days(1);
      s.right('A.3');
      s.right('A.2');
      expect(e.state.skills['SK-A-01']!.freshAt, isNotNull);
      expect(e.statusOf('SK-A-01', s.at), SkillStatus.freshMastery);
      expect(e.statusOf('SK-B-01', s.at), SkillStatus.ready, reason: 'B unlocks once A passes 0.8');

      // A delayed check on a different item, a week later: durable.
      s.days(8);
      s.right('A.1'); // already used before fresh mastery: not a different item
      expect(e.state.skills['SK-A-01']!.durableAt, isNull);
      s.days(1);
      s.right('A.3');
      expect(e.state.skills['SK-A-01']!.durableAt, isNull, reason: 'A.3 was also used before');
    });

    test('a delayed check on a new item makes the mastery durable; a failed one makes it need a revisit, never removing it', () {
      // A spare item the child has never seen, for the delayed check.
      final Catalog c = smallCatalog();
      final Engine e2 = engineOf(
        Catalog(
          skills: c.skills.values,
          items: <ItemMeta>[
            ...c.items.values,
            const ItemMeta(
              id: 'A.4',
              skills: <String, double>{'SK-A-01': 1},
              representation: Representation.story,
              variantGroup: 'A-g4',
              optionCount: 3,
            ),
          ],
          tags: c.tags.values,
        ),
      );
      final Story t = Story(e2);
      for (final String item in <String>['A.1', 'A.2', 'A.1', 'A.2']) {
        t.right(item);
      }
      t.days(1);
      t.right('A.3');
      t.right('A.1');
      t.days(8);
      t.right('A.4');
      expect(e2.state.skills['SK-A-01']!.durableAt, isNotNull);
      expect(e2.statusOf('SK-A-01', t.at), SkillStatus.durableMastery);
      final DateTime durable = e2.state.skills['SK-A-01']!.durableAt!;
      // A later check is failed.
      t.days(20);
      t.wrong('A.2');
      expect(e2.state.skills['SK-A-01']!.needsRevisit, isTrue);
      expect(e2.statusOf('SK-A-01', t.at), SkillStatus.needsRevisit);
      expect(e2.state.skills['SK-A-01']!.durableAt, durable, reason: 'nothing the child earned is removed');
      expect(e2.state.skills['SK-A-01']!.freshAt, isNotNull);
      // Passing again clears it.
      t.days(2);
      t.right('A.4');
      expect(e2.state.skills['SK-A-01']!.needsRevisit, isFalse);
      expect(e2.statusOf('SK-A-01', t.at), SkillStatus.durableMastery);
    });

    test('a core skill needs more: six successes and two representations and two checks', () {
      final Catalog base = smallCatalog();
      final Engine e = Engine(
        catalog: Catalog(
          skills: <SkillNode>[
            const SkillNode(id: 'SK-A-01', core: true),
            ...base.skills.values.where((SkillNode s) => s.id != 'SK-A-01'),
          ],
          items: base.items.values,
          tags: base.tags.values,
        ),
      );
      final Story s = Story(e);
      for (final String item in <String>['A.1', 'A.2', 'A.1', 'A.2']) {
        s.right(item);
      }
      s.days(1);
      s.right('A.3');
      s.right('A.1');
      expect(e.state.skills['SK-A-01']!.successes, 6);
      expect(e.state.skills['SK-A-01']!.freshAt, isNull, reason: 'only one kind of check passed');
    });

    test('an item with a hint is not an independent success', () {
      final Engine e = fresh();
      final Story s = Story(e);
      for (int i = 0; i < 10; i++) {
        s.right('A.1', hint: 1);
      }
      expect(e.state.skills['SK-A-01']!.successes, 0);
      expect(e.state.skills['SK-A-01']!.freshAt, isNull);
    });

    test('assumed skills start at 0.85 and unlock what depends on them', () {
      final Engine e = fresh()..assume(<String>['SK-A-01']);
      expect(e.isUnlocked('SK-B-01'), isTrue);
      expect(e.skill('SK-A-01').p, p.priorAssumed);
      Story(e).wrong('A.1');
      expect(e.state.skills['SK-A-01']!.p, lessThan(p.priorAssumed));
    });

    test('a skill is unlocked only when all its prerequisites pass 0.8', () {
      final Engine e = fresh();
      expect(e.isUnlocked('SK-B-01'), isFalse);
      final Story s = Story(e);
      for (int i = 0; i < 6; i++) {
        s.right('A.3');
      }
      expect(e.isUnlocked('SK-B-01'), isTrue);
    });
  });

  group('misconceptions need a pattern', () {
    test('one wrong answer with a tag is only suspected; unsure creates nothing', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('B.1', tag: 'M-B');
      expect(e.state.tags['M-B']!.status, TagStatus.suspected);
      s.answer('B.2', Result.unsure);
      expect(e.state.tags.length, 1);
    });

    test('two tagged answers on two different items make it active; on the same item they do not', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('B.1', tag: 'M-B');
      s.wrong('B.1', tag: 'M-B');
      expect(e.state.tags['M-B']!.score, closeTo(1.8, 1e-9));
      expect(e.state.tags['M-B']!.status, TagStatus.suspected);

      final Engine f = engineOf(smallCatalog());
      final Story t = Story(f);
      t.wrong('B.1', tag: 'M-B');
      t.wrong('B.p1', tag: 'M-B');
      expect(f.state.tags['M-B']!.status, TagStatus.active);
    });

    test('a slip followed by right answers fades away: the score decays', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('B.1', tag: 'M-B');
      s.right('B.1');
      s.right('B.1');
      expect(e.state.tags['M-B']!.score, closeTo(0.64, 1e-9));
      expect(e.state.tags['M-B']!.status, TagStatus.suspected);
    });

    test(
      'three diagnostic items that could have shown it, answered right, resolve it; a new error reopens it',
      () {
        final Engine e = engineOf(smallCatalog());
        final Story s = Story(e);
        s.wrong('B.1', tag: 'M-B');
        s.wrong('B.p1', tag: 'M-B');
        expect(e.state.tags['M-B']!.status, TagStatus.active);
        s.right('B.1'); // not diagnostic
        expect(e.state.tags['M-B']!.cleanRuns, 0);
        s.right('B.p1');
        s.right('B.p1');
        expect(e.state.tags['M-B']!.status, TagStatus.active);
        s.right('B.p1');
        expect(e.state.tags['M-B']!.status, TagStatus.resolved);
        s.wrong('B.1', tag: 'M-B');
        expect(e.state.tags['M-B']!.status, TagStatus.suspected);
      },
    );

    test('an item built to contradict the tag counts as a diagnostic item', () {
      final Catalog c = smallCatalog();
      final Engine e = engineOf(
        Catalog(
          skills: c.skills.values,
          items: <ItemMeta>[
            ...c.items.values,
            const ItemMeta(
              id: 'B.c',
              skills: <String, double>{'SK-B-01': 1},
              representation: Representation.concrete,
              optionCount: 3,
              tags: <String>{'M-B'},
              contradicts: 'M-B',
            ),
          ],
          tags: c.tags.values,
        ),
      );
      final Story s = Story(e);
      s.wrong('B.1', tag: 'M-B');
      s.wrong('B.p1', tag: 'M-B');
      s.right('B.c');
      s.right('B.c');
      s.right('B.c');
      expect(e.state.tags['M-B']!.status, TagStatus.resolved);
    });
  });

  group('the engine is a function of the log', () {
    List<AttemptEvent> events() {
      final List<AttemptEvent> out = <AttemptEvent>[];
      DateTime at = day0;
      int id = 0;
      void add(String item, Result r, {String tag = '', int hint = 0, int days = 0}) {
        at = at.add(Duration(days: days, seconds: 30));
        out.add(AttemptEvent(id: ++id, at: at, activityId: item, result: r, tag: tag, hintLevel: hint));
      }

      add('A.1', Result.correct);
      add('A.2', Result.correct);
      add('B.1', Result.incorrect, tag: 'M-B');
      add('B.p1', Result.incorrect, tag: 'M-B');
      add('A.3', Result.correct, days: 1);
      add('B.2', Result.unsure);
      add('C.1', Result.correct, hint: 2, days: 3);
      add('A.1', Result.correct, days: 9);
      return out;
    }

    test('replaying twice gives the same state', () {
      final Engine a = engineOf(smallCatalog())..replay(events());
      final String first = fingerprint(a);
      a.replay(events());
      expect(fingerprint(a), first);
      expect(fingerprint(engineOf(smallCatalog())..replay(events())), first);
    });

    test('the order the events arrive in does not matter, their times do', () {
      final List<AttemptEvent> shuffled = events()..shuffle(math.Random(3));
      expect(
        fingerprint(engineOf(smallCatalog())..replay(shuffled)),
        fingerprint(engineOf(smallCatalog())..replay(events())),
      );
    });

    test('feeding events one by one equals replaying them', () {
      final Engine live = engineOf(smallCatalog());
      for (final AttemptEvent e in events()) {
        live.apply(e);
      }
      expect(fingerprint(live), fingerprint(engineOf(smallCatalog())..replay(events())));
    });

    test('an answer to an item the engine has never heard of is ignored, not a crash', () {
      final Engine e = engineOf(smallCatalog());
      e.apply(AttemptEvent(at: day0, activityId: 'gone.forever', result: Result.correct));
      expect(e.state.skills, isEmpty);
    });
  });
}
