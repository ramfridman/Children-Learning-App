// QA of rule E-1 (docs/languages/writing-mastery.md) in the engine: the qa-engineer's attempts to break it, beyond the vectors the developer
// wrote (test/engine/writing_mastery_test.dart). One day only, one cue only, copies only, traces only, help on every answer, a probe or a check
// standing in for a memory success, and the same history replayed from the log. A positive control comes first so that "never fresh" means
// something.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'engine/fixtures.dart';

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
}) => ItemMeta(
  id: id,
  course: Course.heb,
  skills: <String, double>{skill: 1},
  purpose: purpose,
  checkType: check,
  representation: Representation.embodied,
  variantGroup: group,
  tags: const <String>{_mirror, _stroke},
  writingMode: mode,
  cue: cue,
  startGuide: startGuide,
);

Catalog _catalog() => Catalog(
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
    const SkillNode(
      id: _w,
      course: Course.heb,
      writing: WritingRule.memory,
      setCoverage: true,
      prerequisites: <String, double>{_t: 1, _n: 1, _s: 1},
    ),
    const SkillNode(id: _d, course: Course.heb, prerequisites: <String, double>{_w: 1}),
  ],
  items: <ItemMeta>[
    _item('T.f.m', _t, mode: WritingMode.trace),
    _item('T.f.l', _t, mode: WritingMode.trace, group: 'l'),
    _item('T.s.m', _t, mode: WritingMode.trace, startGuide: true),
    _item('T.s.l', _t, mode: WritingMode.trace, startGuide: true, group: 'l'),
    _item('A.s.down', _a, mode: WritingMode.trace, startGuide: true, group: 'down'),
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
    _item('W.pm', _w, mode: WritingMode.memory, cue: WritingCue.name, purpose: Purpose.probe),
    _item('W.pl', _w, mode: WritingMode.memory, cue: WritingCue.name, group: 'l', purpose: Purpose.probe),
    _item('N.1', _n),
    _item('S.1', _s),
  ],
  tags: const <TagInfo>[
    TagInfo(id: _mirror, course: Course.heb, skills: <String>[_w]),
    TagInfo(id: _stroke, course: Course.heb, skills: <String>[_w]),
  ],
);

class _Child {
  _Child() : engine = engineOf(_catalog()) {
    story = Story(engine);
  }

  final Engine engine;
  late final Story story;
  int _clock = 0;

  void day(int n) => story.at = day0.add(Duration(days: n - 1, minutes: ++_clock));

  void ok(int day, String item, [int hint = 0]) {
    this.day(day);
    story.right(item, hint: hint);
  }

  SkillState get w => engine.state.skills[_w]!;
  bool get fresh => engine.state.skills[_w]?.freshAt != null;
}

void main() {
  test('control: sound on day 1, name on day 2, every letter once, a check: fresh at the last answer', () {
    final _Child c = _Child();
    c.ok(1, 'W.ms');
    c.ok(1, 'W.ln');
    c.ok(2, 'W.mn');
    expect(c.fresh, isFalse, reason: '3 successes, no check yet');
    c.ok(2, 'W.kl');
    expect(c.fresh, isTrue);
  });

  test(
    'ONE DAY ONLY: twenty memory successes, both cues, every letter, both checks, all on day 1: never fresh',
    () {
      final _Child c = _Child();
      for (int i = 0; i < 5; i++) {
        for (final String id in <String>['W.ms', 'W.mn', 'W.ls', 'W.ln', 'W.km', 'W.kl']) {
          c.ok(1, id);
        }
      }
      expect(c.w.successes, greaterThanOrEqualTo(20));
      expect(c.fresh, isFalse);
      c.ok(2, 'W.ms');
      expect(c.fresh, isTrue, reason: 'one memory success on the second day completes it');
    },
  );

  test('ONE CUE ONLY: sound on six days, then name on six days, never both: never fresh while one cue is missing', () {
    final _Child sound = _Child();
    final _Child name = _Child();
    for (int d = 1; d <= 6; d++) {
      for (final String id in <String>['W.ms', 'W.ls', 'W.km']) {
        sound.ok(d, id);
      }
      for (final String id in <String>['W.mn', 'W.ln', 'W.kl']) {
        name.ok(d, id);
      }
    }
    expect(sound.w.successes, greaterThan(10));
    expect(sound.fresh, isFalse);
    expect(name.fresh, isFalse);
    expect(sound.w.memoryCues, <WritingCue>{WritingCue.sound});
    expect(name.w.memoryCues, <WritingCue>{WritingCue.name});
  });

  test('COPIES ONLY: sixty copies on ten days, at hint 0: p is high, no success, no review, never fresh, no check due', () {
    final _Child c = _Child();
    for (int d = 1; d <= 10; d++) {
      for (final String id in <String>['W.cm', 'W.cl', 'W.cm', 'W.cl', 'W.cm', 'W.cl']) {
        c.ok(d, id);
      }
    }
    expect(c.w.p, greaterThan(0.99));
    expect(c.w.successes, 0);
    expect(c.w.successDays, isEmpty);
    expect(c.w.memorySuccessDays, isEmpty);
    expect(c.w.memory, isNull);
    expect(c.fresh, isFalse);
    expect(c.engine.dueChecks(c.story.at), isEmpty);
    expect(c.engine.statusOf(_w, c.story.at), SkillStatus.learning);
  });

  test('COPIES ONLY then one memory success on one day: still not fresh', () {
    final _Child c = _Child();
    for (int d = 1; d <= 3; d++) {
      c.ok(d, 'W.cm');
      c.ok(d, 'W.cl');
    }
    c.ok(4, 'W.ms');
    c.ok(4, 'W.ln');
    c.ok(4, 'W.kl');
    c.ok(4, 'W.ls');
    expect(c.w.memorySuccessDays.length, 1);
    expect(c.fresh, isFalse, reason: 'the copy days are not memory days');
  });

  test('TRACES ONLY: practised, never mastered, never a success, never blocks the writing node nor changes its p', () {
    final _Child c = _Child();
    for (int d = 1; d <= 8; d++) {
      c.ok(d, 'T.f.m');
      c.ok(d, 'T.f.l');
      c.ok(d, 'T.s.m');
      c.ok(d, 'T.s.l');
    }
    final SkillState t = c.engine.state.skills[_t]!;
    expect(t.successes, 0);
    expect(t.freshAt, isNull);
    expect(t.memory, isNull, reason: 'a trace takes no review');
    expect(t.p, closeTo(0.2, 0.001), reason: 'no estimate is moved by a trace');
    expect(c.engine.statusOf(_t, c.story.at), SkillStatus.practised);
    expect(c.engine.state.skills[_w], isNull, reason: 'the writing node has no evidence at all');
    expect(c.fresh, isFalse);
  });

  test('a wrong trace never counts against the child: no tag, no search, no gap, p unchanged', () {
    final _Child c = _Child();
    c.day(1);
    for (int i = 0; i < 6; i++) {
      c.story.wrong('T.s.m', tag: _stroke, hint: 1);
    }
    expect(c.engine.state.tags.containsKey(_stroke), isFalse);
    expect(c.engine.state.search, isNull);
    expect(c.engine.state.gaps, isEmpty);
    expect(c.engine.state.skills[_t]!.p, closeTo(0.2, 0.001));
    expect(c.engine.state.skills[_t]!.failRun, 0);
  });

  test('a trace done only with the stroke shown (hint 2 or 3) never marks the letter practised', () {
    final _Child c = _Child();
    c.ok(1, 'T.s.m', 2);
    c.ok(1, 'T.s.l', 3);
    expect(c.engine.state.skills[_t]!.practisedGroups, isEmpty);
    expect(c.engine.isMet(_t), isFalse);
    c.ok(2, 'T.s.m', 1);
    c.ok(2, 'T.s.l', 0);
    expect(c.engine.isMet(_t), isTrue);
  });

  test('a full-guide trace (guide: full) never marks a letter practised, however many', () {
    final _Child c = _Child();
    for (int d = 1; d <= 5; d++) {
      c.ok(d, 'T.f.m');
      c.ok(d, 'T.f.l');
    }
    expect(c.engine.state.skills[_t]!.practisedGroups, isEmpty);
    expect(c.engine.isMet(_t), isFalse);
  });

  test('HELP ON EVERY ANSWER: memory at hint 1, 2 and 3 on five days: never a success, never fresh', () {
    final _Child c = _Child();
    for (int d = 1; d <= 5; d++) {
      for (final String id in <String>['W.ms', 'W.mn', 'W.ls', 'W.ln', 'W.km', 'W.kl']) {
        c.ok(d, id, 1 + d % 3);
      }
    }
    expect(c.w.successes, 0);
    expect(c.fresh, isFalse);
  });

  test('a CHECK and a PROBE are not a way round the days: checks on day 1, a probe on day 2 and day 3 do not make a second day', () {
    final _Child c = _Child();
    c.ok(1, 'W.ms');
    c.ok(1, 'W.ln');
    c.ok(1, 'W.mn');
    c.ok(1, 'W.ls');
    c.ok(1, 'W.kl');
    expect(c.fresh, isFalse);
    c.ok(2, 'W.pm'); // a probe, name cue, day 2: not a success
    c.ok(3, 'W.pl');
    expect(c.w.memorySuccessDays.length, 1, reason: 'a probe adds no day');
    expect(c.fresh, isFalse);
  });

  test('a copy at hint 0 on day 2 is no day-2 memory success even after memory on day 1 with both cues', () {
    final _Child c = _Child();
    c.ok(1, 'W.ms');
    c.ok(1, 'W.ln');
    c.ok(1, 'W.mn');
    c.ok(1, 'W.ls');
    c.ok(1, 'W.kl');
    c.ok(2, 'W.cm');
    c.ok(2, 'W.cl');
    expect(c.fresh, isFalse);
    c.ok(3, 'W.ms');
    expect(c.fresh, isTrue);
  });

  test('a letter never written from memory blocks it however well the others went (set coverage)', () {
    final _Child c = _Child();
    for (int d = 1; d <= 4; d++) {
      c.ok(d, 'W.ms');
      c.ok(d, 'W.mn');
      c.ok(d, 'W.km');
    }
    expect(c.w.memoryGroups, <String>{'m'});
    expect(c.fresh, isFalse);
    c.ok(5, 'W.ln');
    expect(c.fresh, isTrue);
  });

  test('replaying the same answers in a fresh engine gives the same E-1 state (the state is rebuilt from the log)', () {
    final _Child a = _Child();
    for (final (int, String, int) r in <(int, String, int)>[
      (1, 'T.s.m', 0),
      (1, 'T.s.l', 1),
      (1, 'W.cm', 0),
      (1, 'W.ms', 0),
      (1, 'W.ln', 1),
      (2, 'W.mn', 0),
      (2, 'W.ls', 0),
      (3, 'W.kl', 0),
    ]) {
      a.ok(r.$1, r.$2, r.$3);
    }
    final _Child b = _Child();
    for (final (int, String, int) r in <(int, String, int)>[
      (1, 'T.s.m', 0),
      (1, 'T.s.l', 1),
      (1, 'W.cm', 0),
      (1, 'W.ms', 0),
      (1, 'W.ln', 1),
      (2, 'W.mn', 0),
      (2, 'W.ls', 0),
      (3, 'W.kl', 0),
    ]) {
      b.ok(r.$1, r.$2, r.$3);
    }
    String key(_Child c) {
      final SkillState w = c.w;
      return '${w.p.toStringAsFixed(6)} ${w.successes} ${w.memorySuccessDays.toList()..sort()} ${(w.memoryCues.map((WritingCue e) => e.name).toList()..sort())} ${(w.memoryGroups.toList()..sort())} ${w.freshAt}';
    }

    expect(key(a), key(b));
  });

  test('the next skill after W (D) opens at the unlock bar of W, as the spec intends (copies are enough to open it, mastery is not implied)', () {
    final _Child c = _Child();
    // N and S known, T practised, then two copies.
    for (final String id in <String>['N.1', 'S.1']) {
      c.ok(1, id);
      c.ok(1, id);
    }
    c.ok(1, 'T.s.m');
    c.ok(1, 'T.s.l');
    c.ok(1, 'W.cm');
    c.ok(1, 'W.cl');
    expect(c.engine.isMet(_w), isTrue);
    expect(c.fresh, isFalse);
  });

  test('ENGINE REPLAY of a day boundary: two memory successes a minute apart across 00:00 UTC are two days (as every skill)', () {
    final _Child c = _Child();
    c.story.at = DateTime.utc(2026, 11, 3, 23, 59);
    c.story.right('W.ms');
    c.story.at = DateTime.utc(2026, 11, 4, 0, 1);
    c.story.right('W.ln');
    expect(c.w.memorySuccessDays.length, 2);
  });
}
