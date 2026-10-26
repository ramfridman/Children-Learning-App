import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'fixtures.dart';

/// The child has done well on skill A for a while (so the engine knows A is fine).
void practiceA(Story s) {
  for (final String item in <String>['A.1', 'A.2', 'A.1', 'A.2']) {
    s.right(item);
  }
}

/// A failed probe of skill X: two wrong answers (a single one could be a slip). A passed probe: four right answers
/// (three-option items are easy to guess, so guessing alone must not be able to pass).
void failProbe(Story s, String x) {
  s.wrong('$x.p1');
  s.wrong('$x.p2');
}

void passProbe(Story s, String x) {
  for (final String k in <String>['p1', 'p2', 'p1', 'p2']) {
    s.right('$x.$k');
  }
}

Catalog chain(int length) {
  final List<SkillNode> skills = <SkillNode>[];
  final List<ItemMeta> items = <ItemMeta>[];
  for (int i = 0; i < length; i++) {
    final String id = 'CH-A-0$i';
    skills.add(SkillNode(id: id, prerequisites: <String, double>{if (i > 0) 'CH-A-0${i - 1}': 1.0}));
    for (final String k in <String>['1', '2', 'p1', 'p2']) {
      items.add(
        ItemMeta(
          id: 'ch$i.$k',
          skills: <String, double>{id: 1},
          purpose: k.startsWith('p') ? Purpose.probe : Purpose.practice,
          representation: k == '2' || k == 'p2' ? Representation.pictorial : Representation.concrete,
          optionCount: 3,
        ),
      );
    }
  }
  return Catalog(skills: skills, items: items);
}

void main() {
  group('a gap search', () {
    test('two wrong answers with a tag start it, and the tag points at the prerequisite to probe first', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      expect(e.state.search, isNull, reason: 'one slip is not a pattern');
      s.wrong('C.2');
      expect(e.state.search, isNotNull);
      expect(e.state.search!.origin, 'SK-C-01');
      expect(e.state.search!.traceSkills, <String>['SK-B-01']);
      expect(e.nextProbe(), 'SK-B-01');
    });

    test('a failed probe whose own prerequisites are known ends the search: the gap is that skill', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      failProbe(s, 'B');
      expect(e.state.search, isNull);
      expect(e.state.gaps, hasLength(1));
      final Gap g = e.state.gaps.single;
      expect(g.origin, 'SK-C-01');
      expect(g.skill, 'SK-B-01');
      expect(g.probes, 1);
      expect(e.statusOf('SK-B-01', s.at), SkillStatus.gap);
      expect(e.nextProbe(), isNull);
    });

    test('a probe in a three-option item needs several right answers to pass (a guess must not pass it), and passing everything records no gap', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      s.right('B.p1');
      expect(e.probeNeedsConfirmation, isTrue);
      expect(e.nextProbe(), 'SK-B-01');
      expect(e.state.search!.probes, 0);
      s.right('B.p2');
      s.right('B.p1');
      expect(e.state.search!.probes, 0, reason: 'three of four is not yet enough');
      s.right('B.p2');
      // B is fine: nothing is missing below C, so no gap is recorded; C is simply still being learned.
      expect(e.state.gaps, isEmpty);
      expect(e.state.closedSearches, <String>['SK-C-01']);
      expect(e.state.search, isNull);
    });

    test('one slip in a probe does not fail it; two wrong answers do', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      s.wrong('B.p1');
      expect(e.state.gaps, isEmpty, reason: 'one wrong answer is a slip as often as not');
      expect(e.probeNeedsConfirmation, isTrue);
      s.right('B.p2');
      s.wrong('B.p1');
      expect(e.state.gaps.single.skill, 'SK-B-01');
    });

    test('when the prerequisite was never practised the search goes down another step', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      failProbe(s, 'B'); // B is missing; A has no evidence, so it is probed too
      expect(e.state.search, isNotNull);
      expect(e.nextProbe(), 'SK-A-01');
      passProbe(s, 'A');
      expect(e.state.gaps.single.skill, 'SK-B-01');
      expect(e.state.gaps.single.probes, 2);
    });

    test('the search can go all the way down when each step fails', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      failProbe(s, 'B');
      failProbe(s, 'A');
      expect(e.state.gaps.single.skill, 'SK-A-01');
      expect(e.state.gaps.single.probes, 2);
    });

    test('the budget of three probes ends a long search with the deepest failure found so far', () {
      final Engine e = engineOf(chain(8));
      final Story s = Story(e);
      s.wrong('ch7.1');
      s.wrong('ch7.2');
      final List<String> probed = <String>[];
      for (int i = 0; i < 3; i++) {
        final String? target = e.nextProbe();
        expect(target, isNotNull);
        probed.add(target!);
        failProbe(s, 'ch${int.parse(target.substring(target.length - 1))}');
      }
      expect(probed.toSet(), hasLength(3));
      expect(e.state.search, isNull);
      final Gap g = e.state.gaps.single;
      expect(g.skill, probed.last, reason: 'the deepest failure the three probes reached');
      expect(g.probes, 3);
      expect(g.via, 'budget');
    });

    test('three "not sure" answers on a skill start a search and make no misconception', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      for (int i = 0; i < 3; i++) {
        s.answer('C.1', Result.unsure);
      }
      expect(e.state.search, isNotNull);
      expect(e.state.tags, isEmpty);
    });

    test('a right answer between the wrong ones means no pattern, no search', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('C.1');
      s.right('C.2');
      s.wrong('C.1');
      expect(e.state.search, isNull);
    });

    test('a skill with no prerequisites never starts a search (there is nothing below it)', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      for (int i = 0; i < 4; i++) {
        s.wrong('A.1');
      }
      expect(e.state.search, isNull);
      expect(e.state.gaps, isEmpty);
    });

    test('a long run of low estimates steps back as well', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('B.1');
      s.right('B.2', hint: 3); // a worked example: not a right answer, not a wrong one
      s.right('B.2', hint: 3);
      s.right('B.2', hint: 3);
      s.wrong('B.2');
      expect(
        e.state.search,
        isNotNull,
        reason: 'two wrong in total are not in a row, but the estimate fell under 0.4 after 5 items',
      );
    });

    test('a probe of some other skill than the one asked for changes the estimate but not the search', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      failProbe(s, 'D');
      expect(e.state.search, isNotNull);
      expect(e.state.search!.probes, 0);
    });

    test('while a search is open, further wrong answers do not start another one; after a gap is found the origin does not retrigger', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      final GapSearch first = e.state.search!;
      s.wrong('C.1');
      expect(e.state.search, same(first));
      failProbe(s, 'B');
      expect(e.state.gaps, hasLength(1));
      s.wrong('C.1');
      s.wrong('C.2');
      s.wrong('C.1');
      expect(e.state.search, isNull);
      expect(e.state.gaps, hasLength(1));
    });

    test(
      'repair: two independent successes on the gap skill close it; a wrong answer starts the count again',
      () {
        final Engine e = engineOf(smallCatalog());
        final Story s = Story(e);
        practiceA(s);
        s.wrong('C.1', tag: 'M-C');
        s.wrong('C.2');
        failProbe(s, 'B');
        final Gap g = e.state.gaps.single;
        s.right('B.2');
        expect(g.repairSuccesses, 1);
        s.wrong('B.1');
        expect(g.repairSuccesses, 0);
        s.right('B.2');
        s.right('B.3');
        expect(g.repaired, isTrue);
        expect(e.statusOf('SK-B-01', s.at), isNot(SkillStatus.gap));
        expect(e.state.openGaps, isEmpty);
      },
    );

    test('after a repair the engine looks again when the child fails again, and sees that nothing below is missing', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.1', tag: 'M-C');
      s.wrong('C.2');
      failProbe(s, 'B');
      s.right('B.2');
      s.right('B.3');
      s.right('C.1');
      s.wrong('C.2');
      s.wrong('C.1');
      // The engine looked again; B was just shown, so nothing is missing below C.
      expect(e.state.closedSearches, <String>['SK-C-01']);
    });

    test('with no tag the walk ranks by weight and weakness and still finds the gap', () {
      final Engine e = engineOf(smallCatalog(traceToRoot: false));
      final Story s = Story(e);
      practiceA(s);
      s.wrong('C.2');
      s.wrong('C.2');
      expect(e.nextProbe(), 'SK-B-01');
    });
  });

  group('help that changes the way of explaining', () {
    test('after two wrong answers in a row the next item should not be in the same representation', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('B.1');
      expect(e.avoidRepresentation('SK-B-01'), isNull);
      s.wrong('B.1');
      expect(e.avoidRepresentation('SK-B-01'), Representation.concrete);
      s.right('B.2');
      expect(e.avoidRepresentation('SK-B-01'), isNull);
    });

    test('a worked example (hint 3) also asks for another way', () {
      final Engine e = engineOf(smallCatalog());
      Story(e).right('B.2', hint: 3);
      expect(e.avoidRepresentation('SK-B-01'), Representation.pictorial);
    });

    test('stuck: three wrong in a row on one skill, or two worked examples in a row', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.wrong('B.1', session: 1);
      s.wrong('B.2', session: 1);
      expect(e.isStuck(1), isFalse);
      s.wrong('B.1', session: 1);
      expect(e.isStuck(1), isTrue);

      final Engine f = engineOf(smallCatalog());
      final Story t = Story(f);
      t.right('B.1', hint: 3, session: 2);
      expect(f.isStuck(2), isFalse);
      t.right('C.1', hint: 3, session: 2);
      expect(f.isStuck(2), isTrue);
    });

    test('representation statistics count every try and every independent success per skill family', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      s.right('B.1');
      s.wrong('B.1');
      s.right('B.2', hint: 1);
      s.right('B.2', hint: 2);
      expect(e.state.representations['SK-B|concrete']!.tries, 2);
      expect(e.state.representations['SK-B|concrete']!.successes, 1);
      expect(e.state.representations['SK-B|pictorial']!.tries, 2);
      expect(e.state.representations['SK-B|pictorial']!.successes, 1);
    });
  });
}
