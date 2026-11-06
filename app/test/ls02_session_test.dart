// LS02 write a letter on its frame (L5 section 5.2): the four modes, the free-stroke feedback at the end of a stroke, what each answer writes,
// the three-step help (the last is trace mode), the word canvas, and the things a child's strokes never do.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/play/letter_write_session.dart';
import 'package:nitznutz/play/response_code.dart';
import 'package:nitznutz/play/stroke_geometry.dart';

import 'support/l4_rig.dart';
import 'support/ls02_content.dart';

/// A pack of the fixture group of [course] with the items the tests play: the letter [x] (a form of its script).
Ls02Pack pack(String course, {String x = 's', bool cap = false}) {
  final Ls02Pack p = Ls02Pack(course);
  final GroupSkills g = p.skills;
  final String f = p.form(x, cap: cap);
  final Map<String, Object?> classify = p.classify();
  p.add(
    letterJson(
      course: course,
      id: 'n01',
      skill: g.trace,
      mode: 'intro',
      forms: <String>[f],
      intro: introData(course, x),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 't_full',
      skill: g.trace,
      mode: 'trace',
      guide: 'full',
      forms: <String>[f],
      classify: classify,
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 't_start',
      skill: g.trace,
      mode: 'trace',
      guide: 'start',
      forms: <String>[f],
      classify: classify,
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'c_beside',
      skill: g.write,
      mode: 'copy',
      forms: <String>[f],
      classify: classify,
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'c_hide',
      skill: g.write,
      mode: 'copy',
      model: 'hide',
      forms: <String>[f],
      classify: classify,
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'm_sound',
      skill: g.write,
      mode: 'memory',
      cue: 'sound',
      cueClip: 'vo:$course.snd.$x',
      forms: <String>[f],
      classify: classify,
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'm_probe',
      skill: g.write,
      mode: 'memory',
      cue: 'name',
      cueClip: 'vo:$course.name.$x',
      forms: <String>[f],
      classify: classify,
      purpose: 'probe',
    ),
  );
  return p;
}

typedef LetterRig = Rig<LetterWriteSession>;

LetterRig rig(Ls02Pack p, String id) =>
    Rig<LetterWriteSession>(p.pack, id, (c, a) => LetterWriteSession(c, a as LetterWriteActivity));

/// The strokes of the letter the rig's session is on, as points along each model stroke (the box's units).
List<Offset> along(StrokeForm f, int stroke, {int n = 24}) => resampleStroke(f.strokes[stroke].points, n);

Future<void> draw(LetterWriteSession s, List<Offset> pts) async {
  s.begin(pts.first);
  for (final Offset p in pts.skip(1)) {
    s.extend(p);
  }
  await s.end();
}

Future<void> writeLetter(LetterWriteSession s, {int? only}) async {
  final StrokeForm f = s.box.form;
  for (int i = 0; i < f.strokes.length; i++) {
    if (s.box.checker.done[i]) continue;
    if (f.strokes[i].kind == StrokeKind.dot) {
      await s.tap(f.strokes[i].start);
    } else {
      await draw(s, along(f, i));
    }
  }
}

Offset mirror(Offset p) => Offset(100 - p.dx, p.dy);

void main() {
  group('copy, memory and trace: what each answer writes', () {
    testWidgets('memory: the right letter writes one correct row, ok, at hint level 0', (
      WidgetTester t,
    ) async {
      final LetterRig r = rig(pack('eng'), 'm_sound');
      await r.pump(t);
      await writeLetter(r.session);
      await t.pump();
      expect(r.written, <String>['correct:ok']);
      expect(r.attempts.single.hintLevel, 0);
      expect(r.session.ring, AnswerState.correct);
      await r.wait(t, 4000);
      await r.done(t);
    });

    testWidgets('memory: the cue is the prompt\'s clip, and replaying it is not a hint', (
      WidgetTester t,
    ) async {
      final LetterRig r = rig(pack('eng'), 'm_sound');
      await r.pump(t);
      expect(r.controller.voiceTarget, 'vo:eng.snd.s');
      r.controller.replayPrompt();
      expect(r.controller.hintShown, 0);
      await r.done(t);
    });

    testWidgets('a stroke is read at its end, never during it', (WidgetTester t) async {
      final LetterRig r = rig(pack('eng'), 'm_sound');
      await r.pump(t);
      final LetterWriteSession s = r.session;
      final List<Offset> stroke = along(s.box.form, 0);
      s.begin(stroke.first);
      for (final Offset p in stroke.skip(1)) {
        s.extend(Offset(100 - p.dx, p.dy)); // the mirror, wrong all the way
        expect(r.attempts, isEmpty, reason: 'nothing is said while the finger is down');
        expect(s.ring, AnswerState.idle);
      }
      await s.end();
      expect(r.attempts, isNotEmpty);
      await r.done(t);
    });

    testWidgets('a named error writes its row with the tag and the stroke and what: s1.mirror', (
      WidgetTester t,
    ) async {
      final Ls02Pack p = pack('eng', x: 'p');
      final LetterRig r = rig(p, 'm_sound');
      await r.pump(t);
      final LetterWriteSession s = r.session;
      await draw(s, <Offset>[for (final Offset q in along(s.box.form, 0)) mirror(q)]);
      expect(r.written, <String>['incorrect:${ResponseCode.strokeFault(1, 'mirror')}']);
      expect(r.attempts.single.misconceptionTag, p.tag('mirror'));
      expect(r.controller.hintShown, 1, reason: 'the first miss brings the start dot back');
      expect(s.startDotShown, isTrue);
      await r.wait(t, 3000);
      await r.done(t);
    });

    testWidgets('a miss it cannot name writes nothing, and moves the help one step', (WidgetTester t) async {
      final LetterRig r = rig(pack('eng'), 'm_sound');
      await r.pump(t);
      final LetterWriteSession s = r.session;
      final List<Offset> scribble = <Offset>[
        for (int i = 0; i < 24; i++) Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60),
      ];
      await draw(s, scribble);
      expect(r.attempts, isEmpty, reason: 'a retry with no tag and no evidence');
      expect(r.controller.hintShown, 1);
      expect(s.box.ink, isEmpty);
      await r.wait(t, 1500);
      // The retry, now with the start dot, is right: one row, at level 1 (a hinted answer, never a full success).
      await writeLetter(s);
      expect(r.written, <String>['correct:ok']);
      expect(r.attempts.single.hintLevel, 1);
      await r.wait(t, 4000);
      await r.done(t);
    });

    testWidgets(
      'three misses: the help is at its top, the item is trace mode with the whole path, and the right stroke ends it',
      (WidgetTester t) async {
        final LetterRig r = rig(pack('eng'), 'm_sound');
        await r.pump(t);
        final LetterWriteSession s = r.session;
        final List<Offset> scribble = <Offset>[
          for (int i = 0; i < 24; i++) Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60),
        ];
        for (int i = 0; i < 3; i++) {
          await draw(s, scribble);
          await r.wait(t, 1800);
        }
        expect(r.controller.hintShown, 3);
        expect(r.controller.guided, isTrue);
        expect(s.traceMode, isTrue);
        expect(s.fullGuide, isTrue);
        expect(r.attempts, isEmpty, reason: 'every miss was one it could not name');
        await r.wait(t, 12000);
        await writeLetter(s);
        expect(r.written, <String>['correct:ok']);
        expect(r.attempts.single.hintLevel, 3, reason: 'trace mode counts as level 3: no credit');
        await r.wait(t, 4000);
        await r.done(t);
      },
    );

    testWidgets(
      'copy: the model stands beside the box; hidden, it is covered after a while and a tap that shows it again is level 1',
      (WidgetTester t) async {
        final LetterRig r = rig(pack('eng'), 'c_hide');
        await r.pump(t);
        final LetterWriteSession s = r.session;
        expect(s.modelShown, isTrue);
        await r.wait(t, 4000);
        expect(s.modelShown, isFalse);
        await t.tap(find.byKey(const Key('peek')));
        await t.pump();
        expect(s.modelShown, isTrue);
        expect(r.controller.hintShown, 1);
        expect(r.attempts, isEmpty, reason: 'looking again writes no row, it only costs a level');
        await r.wait(t, 4000);
        await r.done(t);
      },
    );

    testWidgets('copy that is right writes ok at level 0 (the engine reads it one level higher)', (
      WidgetTester t,
    ) async {
      final LetterRig r = rig(pack('eng'), 'c_beside');
      await r.pump(t);
      expect(r.session.modelShown, isTrue);
      await writeLetter(r.session);
      expect(r.written, <String>['correct:ok']);
      expect(r.attempts.single.hintLevel, 0);
      await r.wait(t, 4000);
      await r.done(t);
    });

    testWidgets(
      'trace with the start dot: the right path is trace, the path from the other end is direction, off the path is off',
      (WidgetTester t) async {
        final Ls02Pack p = pack('eng', x: 't');
        final LetterRig r = rig(p, 't_start');
        await r.pump(t);
        final LetterWriteSession s = r.session;
        expect(s.fullGuide, isFalse);
        expect(s.startDotShown, isTrue, reason: 'a trace with the start dot shows the dot');
        await draw(s, along(s.box.form, 0).reversed.toList());
        await r.wait(t, 1500);
        await draw(s, <Offset>[for (int i = 0; i < 12; i++) Offset(80.0 + i, 20.0 + i * 5)]);
        await r.wait(t, 1500);
        expect(r.written, <String>[
          'incorrect:${ResponseCode.tracedBackwards}',
          'incorrect:${ResponseCode.tracedOff}',
        ]);
        expect(r.attempts.first.misconceptionTag, p.tag('stroke'));
        await r.wait(t, 5000);
        await writeLetter(s);
        expect(r.written.last, 'correct:${ResponseCode.written}');
        await r.wait(t, 4000);
        await r.done(t);
      },
    );

    testWidgets('a probe of a writing node: two misses that cannot be named end it with no row', (
      WidgetTester t,
    ) async {
      final LetterRig r = rig(pack('eng'), 'm_probe');
      await r.pump(t);
      final LetterWriteSession s = r.session;
      final List<Offset> scribble = <Offset>[
        for (int i = 0; i < 24; i++) Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60),
      ];
      await draw(s, scribble);
      await r.wait(t, 1000);
      expect(r.controller.finished, isFalse);
      await draw(s, scribble);
      await r.wait(t, 2500);
      expect(r.attempts, isEmpty);
      expect(r.controller.hintShown, 0, reason: 'a probe has no help');
      expect(r.controller.solved, isTrue);
      await r.wait(t, 3000);
      await r.done(t);
    });
  });

  group('look-alikes', () {
    testWidgets('a look-alike with a SHAPE tag is a named error; a homophone on the way writes nothing', (
      WidgetTester t,
    ) async {
      final Ls02Pack p = Ls02Pack('eng');
      final GroupSkills g = p.skills;
      final Map<String, Object?> classify = p.classify(
        partners: <String, String>{'latin.q': p.tag('shape'), 'latin.b': p.tag('homophone')},
      );
      p.add(
        letterJson(
          id: 'm_p',
          skill: g.write,
          mode: 'memory',
          cue: 'sound',
          cueClip: 'vo:eng.snd.p',
          forms: <String>['latin.p'],
          classify: classify,
        ),
      );
      final StrokeForm q = StrokeSet.fromJson(strokeSetDoc('latin')).forms['latin.q']!;
      final StrokeForm b = StrokeSet.fromJson(strokeSetDoc('latin')).forms['latin.b']!;

      final LetterRig r = rig(p, 'm_p');
      await r.pump(t);
      for (int i = 0; i < q.strokes.length; i++) {
        await draw(r.session, resampleStroke(q.strokes[i].points, 24));
        await r.wait(t, 1500);
      }
      expect(r.attempts, isNotEmpty);
      expect(r.attempts.first.misconceptionTag, p.tag('shape'));
      expect(r.attempts.first.response, 's1.partner');
      await r.done(t);

      final LetterRig r2 = rig(p, 'm_p');
      await r2.pump(t);
      for (int i = 0; i < b.strokes.length; i++) {
        await draw(r2.session, resampleStroke(b.strokes[i].points, 24));
        await r2.wait(t, 1500);
      }
      expect(
        r2.attempts,
        isEmpty,
        reason: 'a real letter for that sound is no misconception: nothing is written',
      );
      expect(r2.controller.hintShown, greaterThanOrEqualTo(1));
      await r2.done(t);
    });
  });

  group('the worked example', () {
    testWidgets('an intro is not scored: no row, no lamp, and it ends when its one trace is done', (
      WidgetTester t,
    ) async {
      final LetterRig r = rig(pack('eng'), 'n01');
      await r.pump(t);
      final LetterWriteSession s = r.session;
      expect(r.controller.noHelp, isTrue);
      expect(r.activity.unscored, isTrue);
      // The child cannot write over the walk: the letter is shown, said and drawn first.
      await draw(s, along(s.box.form, 0));
      expect(s.box.ink, isEmpty);
      await r.wait(t, 9500);
      expect(s.introStep, 2);
      await writeLetter(s);
      expect(r.controller.solved, isTrue);
      expect(r.attempts, isEmpty);
      await r.done(t);
    });

    testWidgets('the sound with its key word, then the name, and a tap on a speaker says it again', (
      WidgetTester t,
    ) async {
      final LetterRig r = rig(pack('eng'), 'n01');
      await r.pump(t);
      await r.wait(t, 6000);
      expect(r.heard.clips, containsAllInOrder(<String>['vo:eng.snd.s', 'vo:eng.kw.s', 'vo:eng.name.s']));
      r.heard.clear();
      await t.tap(find.byKey(const Key('intro-name')));
      await t.pump();
      expect(r.heard.clips, <String>['vo:eng.name.s']);
      await r.done(t);
    });
  });

  group('a word', () {
    testWidgets('letter by letter, the first at the right in Hebrew, then ok', (WidgetTester t) async {
      final Ls02Pack p = Ls02Pack('heb');
      final GroupSkills g = p.skills;
      final List<String> forms = <String>['hebrew-print.shin', 'hebrew-print.bet', 'hebrew-print.tav'];
      p.add(
        letterJson(
          course: 'heb',
          id: 'w_word',
          skill: g.trace,
          mode: 'trace',
          guide: 'start',
          word: true,
          forms: forms,
          classify: p.classify(),
        ),
      );
      final LetterRig r = rig(p, 'w_word');
      await r.pump(t, size: const Size(667, 375));
      final LetterWriteSession s = r.session;
      expect(s.rtl, isTrue);
      final Size stage = const Size(270, 244);
      final List<Rect> slots = s.layout(stage).slots;
      expect(slots.first.left, greaterThan(slots.last.left), reason: 'the first letter stands at the right');
      for (int i = 0; i < 3; i++) {
        expect(s.active, i);
        await writeLetter(s);
        await r.wait(t, 200);
      }
      expect(r.written, <String>['correct:ok']);
      await r.wait(t, 4000);
      await r.done(t);
    });

    testWidgets('a named miss in the second box writes b2.s1.start', (WidgetTester t) async {
      final Ls02Pack p = Ls02Pack('eng');
      final GroupSkills g = p.skills;
      p.add(
        letterJson(
          id: 'w_word',
          skill: g.write,
          mode: 'memory',
          cue: 'sound',
          cueClip: 'vo:eng.snd.s',
          word: true,
          forms: <String>['latin.s', 'latin.t'],
          classify: p.classify(),
          variantGroup: 'sat-word',
        ),
      );
      final LetterRig r = rig(p, 'w_word');
      await r.pump(t);
      final LetterWriteSession s = r.session;
      await writeLetter(s);
      expect(s.active, 1);
      await draw(s, along(s.box.form, 0).reversed.toList());
      expect(r.written, <String>['incorrect:b2.s1.start']);
      await r.wait(t, 3000);
      await r.done(t);
    });
  });

  group('what a child\'s strokes never do', () {
    testWidgets(
      'no code carries a point: every response is ok, a word and numbers, or one of the old trace codes',
      (WidgetTester t) async {
        final RegExp fits = RegExp(r'^(ok|trace|direction|off|s\d+\.[a-z]+|b\d+\.s\d+\.[a-z]+)$');
        final LetterRig r = rig(pack('eng', x: 'p'), 'm_sound');
        await r.pump(t);
        final LetterWriteSession s = r.session;
        await draw(s, <Offset>[for (final Offset q in along(s.box.form, 0)) mirror(q)]);
        await r.wait(t, 2000);
        await writeLetter(s);
        for (final String code in <String>[for (final a in r.attempts) a.response]) {
          expect(fits.hasMatch(code), isTrue, reason: code);
          expect(ResponseCode.fits(code), isTrue, reason: code);
        }
        await r.wait(t, 4000);
        await r.done(t);
      },
    );

    test('the session holds no database, log or network: its imports say so', () {
      final String source = File('lib/play/letter_write_session.dart').readAsStringSync();
      for (final String banned in <String>[
        'data/',
        'log.dart',
        'sync/',
        'net/',
        'dart:io',
        'speech/',
        'voice/',
      ]) {
        expect(source.contains("import '../$banned") || source.contains("'$banned"), isFalse, reason: banned);
      }
    });
  });

  group('the engine reads LS02 as E-1 says', () {
    test(
      'each mode, cue and start-dot trace becomes what the engine reads, and a skill keeps its writing rule',
      () {
        final Ls02Pack p = pack('eng');
        final PackContent content = p.pack.content;
        final Catalog catalog = engineCatalog(content);
        ItemMeta item(String id) => catalog.items['eng.$id']!;
        expect(item('t_full').writingMode, WritingMode.trace);
        expect(item('t_full').startGuide, isFalse, reason: 'a full-guide trace is not the start dot only');
        expect(item('t_start').startGuide, isTrue);
        expect(item('c_beside').writingMode, WritingMode.copy);
        expect(item('m_sound').writingMode, WritingMode.memory);
        expect(item('m_sound').cue, WritingCue.sound);
        expect(item('m_probe').cue, WritingCue.name);
        expect(item('n01').writingMode, isNull, reason: 'an intro is never answered');
        expect(catalog.skills[p.skills.trace]!.writing, WritingRule.practised);
        expect(catalog.skills[p.skills.write]!.writing, WritingRule.memory);
        expect(catalog.skills[p.skills.write]!.setCoverage, isTrue);
        expect(item('m_sound').representation, Representation.embodied);
      },
    );
  });
}
