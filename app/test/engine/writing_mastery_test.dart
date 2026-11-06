// Rule E-1 (docs/languages/writing-mastery.md): how a writing skill is mastered, as the test vectors of its section 9. The
// fixture is the one of that section: the knowledge facets N and S and the trace node T of group S1 (one bundle), the pre-writing
// node A, the writing node W, and D, a skill that needs W.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'fixtures.dart';

const String _a = 'HEB-A-14';
const String _n = 'HEB-B-14.S1';
const String _s = 'HEB-B-15.S1';
const String _t = 'HEB-B-24.S1';
const String _w = 'HEB-B-26.S1';
const String _d = 'HEB-C-27';
const String _mirror = 'M-HEB-MIRROR';
const String _stroke = 'M-HEB-STROKE';

ItemMeta _item(
  String id,
  String skill, {
  WritingMode? mode,
  WritingCue? cue,
  String group = 'm',
  Purpose purpose = Purpose.practice,
  CheckType check = CheckType.practice,
  bool startGuide = false,
  Set<String> tags = const <String>{_mirror, _stroke},
}) => ItemMeta(
  id: id,
  course: Course.heb,
  skills: <String, double>{skill: 1},
  purpose: purpose,
  checkType: check,
  representation: Representation.embodied,
  variantGroup: group,
  tags: tags,
  writingMode: mode,
  cue: cue,
  startGuide: startGuide,
);

Catalog _catalog({bool coreW = false}) => Catalog(
  skills: <SkillNode>[
    const SkillNode(id: _a, course: Course.heb, writing: WritingRule.practised),
    const SkillNode(id: _n, course: Course.heb, bundle: 'heb.s1', letters: true),
    const SkillNode(id: _s, course: Course.heb, bundle: 'heb.s1', letters: true),
    const SkillNode(
      id: _t,
      course: Course.heb,
      bundle: 'heb.s1',
      writing: WritingRule.practised,
      prerequisites: <String, double>{_a: 1},
    ),
    SkillNode(
      id: _w,
      course: Course.heb,
      writing: WritingRule.memory,
      setCoverage: true,
      core: coreW,
      prerequisites: const <String, double>{_t: 1, _n: 1, _s: 1},
    ),
    const SkillNode(id: _d, course: Course.heb, prerequisites: <String, double>{_w: 1}),
  ],
  items: <ItemMeta>[
    _item('T.f.m', _t, mode: WritingMode.trace),
    _item('T.f.l', _t, mode: WritingMode.trace, group: 'l'),
    _item('T.s.m', _t, mode: WritingMode.trace, startGuide: true),
    _item('T.s.l', _t, mode: WritingMode.trace, startGuide: true, group: 'l'),
    _item('A.s.down', _a, mode: WritingMode.trace, startGuide: true, group: 'down'),
    _item('A.s.arch', _a, mode: WritingMode.trace, startGuide: true, group: 'arch'),
    _item('W.cm', _w, mode: WritingMode.copy),
    _item('W.cl', _w, mode: WritingMode.copy, group: 'l'),
    _item('W.ms', _w, mode: WritingMode.memory, cue: WritingCue.sound),
    _item('W.mn', _w, mode: WritingMode.memory, cue: WritingCue.name),
    _item('W.ls', _w, mode: WritingMode.memory, cue: WritingCue.sound, group: 'l'),
    _item('W.ln', _w, mode: WritingMode.memory, cue: WritingCue.name, group: 'l'),
    _item(
      'W.km',
      _w,
      mode: WritingMode.memory,
      cue: WritingCue.sound,
      check: CheckType.reverse,
      purpose: Purpose.check,
    ),
    _item(
      'W.kl',
      _w,
      mode: WritingMode.memory,
      cue: WritingCue.name,
      group: 'l',
      check: CheckType.transfer,
      purpose: Purpose.check,
    ),
    _item('W.pm', _w, mode: WritingMode.memory, cue: WritingCue.sound, purpose: Purpose.probe),
    // Knowledge items for N and S, so a search has something to probe.
    _item('N.1', _n, tags: const <String>{}),
    _item('S.1', _s, tags: const <String>{}),
  ],
  tags: const <TagInfo>[
    TagInfo(id: _mirror, course: Course.heb, skills: <String>[_w]),
    TagInfo(id: _stroke, course: Course.heb, skills: <String>[_w]),
  ],
);

/// A child of the fixture: answers are given on a day (1 is the first), a minute apart.
class _Child {
  _Child({Catalog? catalog}) : engine = engineOf(catalog ?? _catalog()) {
    story = Story(engine);
  }

  final Engine engine;
  late final Story story;
  int _clock = 0;

  void day(int n) => story.at = day0.add(Duration(days: n - 1, minutes: ++_clock));

  void ok(String item, [int hint = 0]) => story.right(item, hint: hint);

  void miss(String item, {String tag = _mirror, int hint = 0}) => story.wrong(item, tag: tag, hint: hint);

  SkillState get w => engine.state.skills[_w]!;
  SkillState get t => engine.state.skills[_t]!;

  bool get fresh => engine.state.skills[_w]?.freshAt != null;

  /// Plays `(day, item, hint)` rows and says after which row [_w] became fresh (1-based), or null.
  int? run(List<(int, String, int)> rows) {
    int? freshAt;
    int row = 0;
    for (final (int, String, int) r in rows) {
      row++;
      day(r.$1);
      ok(r.$2, r.$3);
      if (freshAt == null && fresh) freshAt = row;
    }
    return freshAt;
  }
}

void main() {
  group('A. fresh mastery of the writing node', () {
    test('A1 copying alone is never mastery, and takes no review', () {
      final _Child c = _Child();
      for (final (int, String) r in <(int, String)>[
        (1, 'W.cm'),
        (1, 'W.cl'),
        (2, 'W.cm'),
        (2, 'W.cl'),
        (3, 'W.cm'),
        (3, 'W.cl'),
      ]) {
        c.day(r.$1);
        c.ok(r.$2);
      }
      expect(c.w.p, closeTo(0.999, 0.001));
      expect(c.w.successes, 0);
      expect(c.fresh, isFalse);
      expect(c.w.memory, isNull, reason: 'a copy has the model in view: it never takes the day\'s review');
      expect(c.engine.statusOf(_w, c.story.at), SkillStatus.learning);
    });

    test('A1 the first copy is read at hint level 1: p 0.786', () {
      final _Child c = _Child();
      c.day(1);
      c.ok('W.cm');
      expect(c.w.p, closeTo(0.786, 0.001));
      expect(c.w.n, 1);
    });

    test('A2 memory by sound only is not enough: the name cue is missing', () {
      final _Child c = _Child();
      c.run(<(int, String, int)>[
        (1, 'W.ms', 0),
        (1, 'W.ls', 0),
        (2, 'W.ms', 0),
        (2, 'W.km', 0),
        (3, 'W.ls', 0),
      ]);
      expect(c.w.successes, 5);
      expect(c.w.memorySuccessDays.length, 3);
      expect(c.w.memoryCues, <WritingCue>{WritingCue.sound});
      expect(c.fresh, isFalse);
    });

    test('A3 both cues on one day is not enough: it needs two days', () {
      final _Child c = _Child();
      c.run(<(int, String, int)>[
        (1, 'W.ms', 0),
        (1, 'W.ln', 0),
        (1, 'W.mn', 0),
        (1, 'W.kl', 0),
        (1, 'W.ls', 0),
      ]);
      expect(c.w.successes, 5);
      expect(c.w.memoryCues, <WritingCue>{WritingCue.sound, WritingCue.name});
      expect(c.w.memorySuccessDays.length, 1);
      expect(c.fresh, isFalse);
    });

    test('A4 the normal path is fresh at the sixth answer', () {
      final _Child c = _Child();
      final int? at = c.run(<(int, String, int)>[
        (1, 'W.cm', 0),
        (1, 'W.cl', 0),
        (1, 'W.ms', 0),
        (1, 'W.ln', 0),
        (2, 'W.mn', 0),
        (2, 'W.kl', 0),
      ]);
      expect(at, 6);
      expect(c.w.successes, 4);
    });

    test('A5 memory with the start dot is a hinted answer, never a success', () {
      final _Child c = _Child();
      c.run(<(int, String, int)>[
        (1, 'W.ms', 1),
        (1, 'W.ln', 1),
        (2, 'W.mn', 1),
        (2, 'W.kl', 1),
        (3, 'W.ls', 1),
      ]);
      expect(c.w.successes, 0);
      expect(c.w.memorySuccessDays, isEmpty);
      expect(c.fresh, isFalse);
    });

    test('A6 one letter only is not set coverage', () {
      final _Child c = _Child();
      c.run(<(int, String, int)>[
        (1, 'W.ms', 0),
        (1, 'W.mn', 0),
        (2, 'W.ms', 0),
        (2, 'W.km', 0),
        (2, 'W.mn', 0),
      ]);
      expect(c.w.successes, 5);
      expect(c.w.memoryCues.length, 2);
      expect(c.w.memorySuccessDays.length, 2);
      expect(c.fresh, isFalse, reason: 'l was never written from memory');
      c.day(3);
      c.ok('W.ls');
      expect(c.fresh, isTrue);
    });

    test('A7 a probe is not a success', () {
      final _Child c = _Child();
      c.run(<(int, String, int)>[(1, 'W.ms', 0), (1, 'W.ln', 0), (2, 'W.pm', 0), (2, 'W.mn', 0)]);
      expect(c.w.successes, 3);
      expect(c.fresh, isFalse);
    });

    test('A8 a named miss, then the retry with the start dot: the retry is not a success', () {
      final _Child c = _Child();
      c.day(1);
      c.miss('W.ms');
      expect(c.w.p, closeTo(0.167, 0.001));
      c.ok('W.ms', 1);
      expect(c.w.p, closeTo(0.767, 0.001));
      expect(c.w.successes, 0);
      c.ok('W.ln');
      c.day(2);
      c.ok('W.mn');
      c.ok('W.ls');
      expect(c.fresh, isFalse);
      c.ok('W.kl');
      expect(c.fresh, isTrue);
      expect(c.engine.state.tags[_mirror]!.score, greaterThan(0), reason: 'the named miss is evidence');
    });

    test('A9 and A10 a copy with more help is worth less: level 2 is half, level 3 nothing', () {
      final _Child two = _Child()..day(1);
      two.ok('W.cm', 1);
      expect(two.w.p, closeTo(0.566, 0.001));
      final _Child three = _Child()..day(1);
      three.ok('W.cm', 2);
      expect(three.w.p, closeTo(0.200, 0.001));
      expect(three.w.n, 1);
    });

    test('A11 the cue condition is two days and both cues, however they fall', () {
      final _Child c = _Child();
      final int? at = c.run(<(int, String, int)>[
        (1, 'W.ms', 0),
        (1, 'W.ln', 0),
        (2, 'W.ls', 0),
        (2, 'W.km', 0),
      ]);
      expect(at, 4);
    });

    test('A12 a core writing node needs 6 successes and 2 checks', () {
      final _Child c = _Child(catalog: _catalog(coreW: true));
      final int? first = c.run(<(int, String, int)>[
        (1, 'W.cm', 0),
        (1, 'W.cl', 0),
        (1, 'W.ms', 0),
        (1, 'W.ln', 0),
        (2, 'W.mn', 0),
        (2, 'W.kl', 0),
      ]);
      expect(first, isNull);
      c.run(<(int, String, int)>[(2, 'W.ls', 0), (3, 'W.km', 0)]);
      expect(c.fresh, isTrue);
    });

    test('A13 trace mode as the last rung of the ladder is no evidence at all (credit 0)', () {
      final _Child c = _Child()..day(1);
      c.ok('W.ms', 3);
      expect(c.w.p, closeTo(0.200, 0.001));
      expect(c.w.n, 1);
      expect(c.w.successes, 0);
      expect(c.engine.state.skills[_t], isNull, reason: 'no practised letter for T');
    });
  });

  group('B. the trace node: practised, met, status', () {
    test('B1 full-guide traces are practice that starts the node and nothing else', () {
      final _Child c = _Child()..day(1);
      c.ok('T.f.m');
      c.ok('T.f.l');
      expect(c.t.practiceCount, 2);
      expect(c.t.p, closeTo(0.2, 1e-9));
      expect(c.t.n, 0);
      expect(c.t.started, isTrue);
      expect(c.engine.statusOf(_t, c.story.at), SkillStatus.learning);
      expect(c.engine.isMet(_t), isFalse);
      expect(c.engine.isUnlocked(_w), isFalse);
    });

    test('B2 each letter traced once with the start dot (level 0 or 1) makes the node practised', () {
      final _Child c = _Child()..day(1);
      c.ok('T.f.m');
      c.ok('T.f.l');
      c.ok('T.s.m');
      c.ok('T.s.l', 1);
      expect(c.engine.statusOf(_t, c.story.at), SkillStatus.practised);
      expect(c.engine.isMet(_t), isTrue);
      expect(c.engine.isUnlocked(_w), isFalse, reason: 'the facets N and S are still low');
      expect(c.t.freshAt, isNull, reason: 'a trace node is never mastered');
    });

    test('B3 a trace at level 2 does not count', () {
      final _Child c = _Child()..day(1);
      c.ok('T.s.m', 2);
      c.ok('T.s.l');
      expect(c.engine.statusOf(_t, c.story.at), SkillStatus.learning);
      expect(c.engine.isMet(_t), isFalse);
    });

    test('B4 a named miss in a trace is practice: no tag, no run, no search', () {
      final _Child c = _Child()..day(1);
      c.miss('T.s.m', tag: _stroke);
      c.ok('T.s.m', 1);
      c.ok('T.s.l');
      expect(c.engine.statusOf(_t, c.story.at), SkillStatus.practised);
      expect(c.engine.state.tags, isEmpty);
      expect(c.t.p, closeTo(0.2, 1e-9));
      expect(c.t.failRun, 0);
      expect(c.engine.state.search, isNull);
    });

    test('B5 the writing node unlocks when the trace is practised and the facets are met', () {
      final _Child c = _Child()..day(1);
      c.ok('T.s.m');
      c.ok('T.s.l');
      c.ok('N.1');
      c.ok('N.1');
      c.ok('S.1');
      c.ok('S.1');
      expect(c.engine.isUnlocked(_w), isTrue);
    });

    test('B6 the pre-writing node never holds the bundle back once practised', () {
      final _Child c = _Child()..day(1);
      expect(c.engine.isUnlocked(_t), isFalse);
      c.ok('A.s.down');
      expect(c.engine.isMet(_a), isFalse, reason: 'only one of its two letters was done (B7)');
      expect(c.engine.isUnlocked(_t), isFalse);
      c.ok('A.s.arch');
      expect(c.engine.isMet(_a), isTrue);
      expect(c.engine.isUnlocked(_t), isTrue);
      expect(c.engine.isUnlocked(_n), isTrue, reason: 'one bundle');
      expect(c.engine.state.skills[_a]!.p, closeTo(0.2, 1e-9));
      expect(c.engine.dueChecks(c.story.at.add(const Duration(days: 400))), isEmpty);
    });

    test('B9 a trace node the placement assumed is met with no answer at all', () {
      final Engine e = engineOf(_catalog())..assume(<String>[_t]);
      expect(e.isMet(_t), isTrue);
      expect(e.statusOf(_t, day0), SkillStatus.practised);
    });

    test('B10 three misses in a session still make the child stuck, and change nothing else', () {
      final _Child c = _Child()..day(1);
      for (int i = 0; i < 3; i++) {
        c.story.wrong('T.s.m', tag: _stroke, session: 7);
      }
      expect(c.engine.isStuck(7), isTrue);
      expect(c.engine.state.search, isNull);
      expect(c.engine.state.tags, isEmpty);
      expect(c.t.p, closeTo(0.2, 1e-9));
    });

    test('B11 a search from the writing node probes the facets, never the trace node', () {
      final _Child c = _Child()..day(1);
      c.miss('W.ms');
      c.miss('W.ls', tag: _stroke);
      final String? probe = c.engine.nextProbe();
      expect(c.engine.state.search?.origin, _w);
      expect(probe, anyOf(_n, _s));
      expect(probe, isNot(_t));
    });

    test('B12 copying makes the dependants of the writing node unlock at p 0.8 (intended)', () {
      final _Child c = _Child()..day(1);
      c.ok('W.cm');
      c.ok('W.cl');
      expect(c.w.p, greaterThan(0.8));
      expect(c.w.successes, 0);
      expect(c.engine.isUnlocked(_d), isTrue);
    });

    test('B8 a roll-up of trace nodes is practised when all its groups are', () {
      final Catalog cat = Catalog(
        skills: const <SkillNode>[
          SkillNode(id: 'HEB-B-24', course: Course.heb),
          SkillNode(id: 'HEB-B-24.S1', course: Course.heb, writing: WritingRule.practised),
          SkillNode(id: 'HEB-B-24.S2', course: Course.heb, writing: WritingRule.practised),
          SkillNode(id: _d, course: Course.heb, prerequisites: <String, double>{'HEB-B-24': 1}),
        ],
        items: <ItemMeta>[
          _item('S1.m', 'HEB-B-24.S1', mode: WritingMode.trace, startGuide: true),
          _item('S2.m', 'HEB-B-24.S2', mode: WritingMode.trace, startGuide: true),
        ],
      );
      final Engine e = engineOf(cat);
      final Story s = Story(e);
      s.right('S1.m');
      expect(e.statusOf('HEB-B-24', s.at), SkillStatus.learning);
      expect(e.isUnlocked(_d), isFalse);
      s.right('S2.m');
      expect(e.statusOf('HEB-B-24', s.at), SkillStatus.practised);
      expect(
        e.isUnlocked(_d),
        isTrue,
        reason: 'the roll-up as a prerequisite means every group, met by practice',
      );
    });
  });

  group('C. reviews, revisits, durable', () {
    _Child fresh() {
      final _Child c = _Child();
      c.run(<(int, String, int)>[
        (1, 'W.cm', 0),
        (1, 'W.cl', 0),
        (1, 'W.ms', 0),
        (1, 'W.ln', 0),
        (2, 'W.mn', 0),
        (2, 'W.kl', 0),
      ]);
      expect(c.fresh, isTrue);
      return c;
    }

    test('C1 a copy takes no review; a memory miss does', () {
      final _Child c = fresh();
      c.day(5);
      c.ok('W.cm');
      expect(c.w.lastReviewDay, isNot(Engine.dayKey(c.story.at)));
      c.miss('W.ms');
      expect(c.w.needsRevisit, isTrue);
    });

    test('C2 a copy alone on a later day leaves the review where it was', () {
      final _Child c = fresh();
      final int? before = c.w.lastReviewDay;
      c.day(5);
      c.ok('W.cm');
      expect(c.w.lastReviewDay, before);
    });

    test('C3 a memory answer 7 days after fresh, with an item not used before, is durable', () {
      final _Child c = fresh();
      c.day(9);
      c.ok('W.cl');
      c.ok('W.ls');
      expect(c.w.durableAt, isNotNull);
    });

    test('C4 an item used at fresh does not make it durable', () {
      final _Child c = fresh();
      c.day(9);
      c.ok('W.ms');
      expect(c.w.durableAt, isNull);
    });

    test('C5 a delayed check at level 1 is a good review and durable', () {
      final _Child c = fresh();
      c.day(9);
      c.ok('W.ls', 1);
      expect(c.w.durableAt, isNotNull);
    });
  });

  group('D. probes and the search', () {
    _Child searching() {
      final _Child c = _Child()..day(1);
      c.miss('W.ms');
      c.miss('W.ls', tag: _stroke);
      expect(c.engine.state.search?.origin, _w);
      return c;
    }

    test('D1 a probe of a writing node passes on one right answer', () {
      final _Child c = searching();
      c.engine.state.search!.target = _n;
      expect(c.engine.probeRightsToPass(0), 1);
    });

    test('D2 and D4 a writing probe fails only on its second wrong answer', () {
      final Engine e = engineOf(_catalog());
      final Story s = Story(e);
      s.wrong('W.ms', tag: _mirror);
      s.wrong('W.ls', tag: _stroke);
      expect(e.state.search?.origin, _w);
      final GapSearch search = e.state.search!;
      search.target = _w;
      s.wrong('W.pm', tag: _mirror);
      expect(search.wrongRun, 1);
      expect(e.state.search, same(search), reason: 'one wrong in a writing probe does not fail it');
    });
  });

  group('E. the classes as a whole', () {
    test('E1 a trace answer changes nothing but the practice count', () {
      final _Child c = _Child()..day(1);
      c.ok('W.ms');
      final double p = c.w.p;
      c.ok('T.s.m');
      expect(c.w.p, p);
      expect(c.engine.state.skills[_t]!.n, 0);
    });

    test('E2 a copy that is right counts, adds no success, and decays the tags it carries', () {
      final _Child c = _Child()..day(1);
      c.miss('W.cm');
      final double score = c.engine.state.tags[_mirror]!.score;
      c.ok('W.cm');
      expect(c.engine.state.tags[_mirror]!.score, lessThan(score));
      expect(c.w.n, 2);
      expect(c.w.successes, 0);
    });

    test('E3 a copy that is a named miss is full evidence against', () {
      final _Child c = _Child()..day(1);
      c.miss('W.cm');
      expect(c.w.p, closeTo(0.167, 0.001));
      expect(c.engine.state.tags[_mirror], isNotNull);
      expect(c.w.n, 1);
    });

    test('E4 a memory success is a success, a cue, a day and a letter', () {
      final _Child c = _Child()..day(1);
      c.ok('W.ms');
      expect(c.w.successes, 1);
      expect(c.w.memoryCues, <WritingCue>{WritingCue.sound});
      expect(c.w.memoryGroups, <String>{'m'});
      expect(c.w.memorySuccessDays.length, 1);
      expect(c.w.memory, isNotNull);
    });

    test('E5 a memory miss takes the day\'s review', () {
      final _Child c = _Child()..day(1);
      c.miss('W.ms');
      expect(c.w.memory, isNotNull);
    });

    test('E6 an item marked practice-only is practice whatever its skill', () {
      final Catalog cat = Catalog(
        skills: const <SkillNode>[SkillNode(id: 'ENG-C-16', course: Course.eng)],
        items: <ItemMeta>[
          const ItemMeta(
            id: 'x',
            course: Course.eng,
            skills: <String, double>{'ENG-C-16': 1},
            representation: Representation.embodied,
            practiceOnly: true,
            tags: <String>{'eng.wri.x'},
          ),
        ],
      );
      final Engine e = engineOf(cat);
      Story(e).right('x');
      expect(e.state.skills['ENG-C-16']!.p, closeTo(0.2, 1e-9));
      expect(e.state.skills['ENG-C-16']!.n, 0);
      expect(e.state.skills['ENG-C-16']!.practiceCount, 1);
    });

    test('E7 an item with no writing mode behaves as it always did', () {
      final Catalog cat = smallCatalog();
      final Engine e = engineOf(cat);
      final Story s = Story(e);
      s.right('A.1');
      expect(e.state.skills['SK-A-01']!.successes, 1);
      expect(e.state.skills['SK-A-01']!.practiceCount, 0);
    });
  });

  group('the hook that carries E-1 and the speaking rule', () {
    test('withPrerequisites keeps the writing rule and the speaking flag', () {
      final Catalog cat = Catalog(
        skills: const <SkillNode>[
          SkillNode(id: 'HEB-B-24', course: Course.heb),
          SkillNode(id: 'HEB-B-24.S1', course: Course.heb),
          SkillNode(
            id: _w,
            course: Course.heb,
            writing: WritingRule.memory,
            speaking: true,
            prerequisites: <String, double>{'HEB-B-24': 1},
          ),
        ],
        items: const <ItemMeta>[],
      );
      expect(cat.skills[_w]!.prerequisites.keys, <String>['HEB-B-24.S1']);
      expect(cat.skills[_w]!.writing, WritingRule.memory);
      expect(cat.skills[_w]!.speaking, isTrue);
    });

    Engine speakingFixture() => engineOf(
      Catalog(
        skills: const <SkillNode>[
          SkillNode(id: 'ENG-A-17', course: Course.eng, speaking: true),
          SkillNode(id: 'ENG-B-08', course: Course.eng, prerequisites: <String, double>{'ENG-A-17': 1}),
        ],
        items: const <ItemMeta>[
          ItemMeta(
            id: 'say.a',
            course: Course.eng,
            skills: <String, double>{'ENG-A-17': 1},
            variantGroup: 'cat',
          ),
          ItemMeta(
            id: 'say.b',
            course: Course.eng,
            skills: <String, double>{'ENG-A-17': 1},
            variantGroup: 'dog',
          ),
        ],
      ),
    );

    test('a speaking skill is met when every word of its practice set was met, whatever the evidence', () {
      final Engine e = speakingFixture();
      expect(e.isUnlocked('ENG-B-08'), isFalse);
      e.apply(AttemptEvent(at: day0, activityId: 'say.a', result: Result.unsure));
      expect(e.isMet('ENG-A-17'), isFalse, reason: 'the second word is still to be met');
      // A spoken answer that cannot count as evidence (it came after a hint) still means the word was met.
      e.apply(
        AttemptEvent(
          at: day0.add(const Duration(minutes: 1)),
          activityId: 'say.b',
          result: Result.correct,
          hintLevel: 1,
          viaSpeech: true,
        ),
      );
      expect(e.isMet('ENG-A-17'), isTrue);
      expect(e.isUnlocked('ENG-B-08'), isTrue);
      expect(e.state.skills['ENG-A-17']!.speechSuccesses, 0, reason: 'its own mastery is unchanged');
      expect(e.state.skills['ENG-A-17']!.p, lessThan(0.8));
    });

    test('any other skill is met at p 0.8, as it always was', () {
      final Engine e = engineOf(smallCatalog());
      final Story s = Story(e);
      expect(e.isMet('SK-A-01'), isFalse);
      s.right('A.1');
      s.right('A.2');
      s.right('A.1');
      expect(e.isMet('SK-A-01'), isTrue);
    });
  });
}
