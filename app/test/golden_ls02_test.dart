// Goldens of LS02, write a letter, on the four boards, in the three scripts: the worked example, a trace with the start dot, a copy with the
// model beside the box, a memory item at the three steps of the help (the start dot with the hand, the stroke drawn once, trace mode with the
// whole path), and a Hebrew word. The real stroke sets of the teacher-checked files; fixture clips (all pending) and the approved pictures;
// the Hebrew lines are samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls02_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart' show LetterWriteActivity;
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/letter_write_session.dart';
import 'package:nitznutz/play/stroke_geometry.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_rig.dart';
import 'support/ls02_content.dart';

/// The letter each script is drawn with: one that has more than one stroke or a curve, so that the start dot, the guide lines and the model
/// all show something.
const Map<String, (String, bool)> _letters = <String, (String, bool)>{
  'eng': ('t', false),
  'heb': ('mem', false),
  'rus': ('em', true),
};

Ls02Pack _pack(String course) {
  final Ls02Pack p = Ls02Pack(course);
  final GroupSkills g = p.skills;
  final (String x, bool cap) = _letters[course]!;
  final String f = p.form(x, cap: cap);
  final Map<String, Object?> classify = p.classify();
  p.add(
    letterJson(
      course: course,
      id: 'intro',
      skill: g.trace,
      mode: 'intro',
      forms: <String>[f],
      intro: introData(course, x),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'trace_start',
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
      id: 'copy',
      skill: g.write,
      mode: 'copy',
      forms: <String>[f],
      classify: classify,
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'memory',
      skill: g.write,
      mode: 'memory',
      cue: 'sound',
      cueClip: 'vo:$course.snd.$x',
      forms: <String>[f],
      classify: classify,
    ),
  );
  if (course == 'heb') {
    p.add(
      letterJson(
        course: course,
        id: 'word',
        skill: g.trace,
        mode: 'trace',
        guide: 'start',
        word: true,
        forms: <String>['hebrew-print.shin', 'hebrew-print.bet', 'hebrew-print.tav'],
        classify: classify,
      ),
    );
  }
  return p;
}

typedef LetterRig = Rig<LetterWriteSession>;

LetterRig _rig(Ls02Pack p, String id) =>
    Rig<LetterWriteSession>(p.pack, id, (c, a) => LetterWriteSession(c, a as LetterWriteActivity));

Future<void> _draw(LetterWriteSession s, List<Offset> pts) async {
  s.begin(pts.first);
  for (final Offset p in pts.skip(1)) {
    s.extend(p);
  }
  await s.end();
}

Future<void> _write(LetterWriteSession s, {int strokes = 99}) async {
  final StrokeForm f = s.box.form;
  for (int i = 0; i < f.strokes.length && i < strokes; i++) {
    if (f.strokes[i].kind == StrokeKind.dot) {
      await s.tap(f.strokes[i].start);
    } else {
      await _draw(s, resampleStroke(f.strokes[i].points, 24));
    }
  }
}

/// A scribble that names nothing: a retry that moves the help one step.
Future<void> _scribble(LetterWriteSession s) =>
    _draw(s, <Offset>[for (int i = 0; i < 24; i++) Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60)]);

/// A copy item of the Hebrew bet, the letter the owner asked to see written (2026-11-06): the model on the right where reading begins, the
/// box on the left, both strokes written.
Ls02Pack _betPack() {
  final Ls02Pack p = Ls02Pack('heb');
  p.add(
    letterJson(
      course: 'heb',
      id: 'bet',
      skill: p.skills.write,
      mode: 'copy',
      forms: <String>['hebrew-print.bet'],
      classify: p.classify(),
    ),
  );
  return p;
}

Future<void> _shot(WidgetTester t, String name, String board) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_$board.png'));

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      for (final String course in <String>['eng', 'heb', 'rus']) {
        testWidgets('$course: the worked example, ready for its one trace', (WidgetTester t) async {
          final LetterRig r = _rig(_pack(course), 'intro');
          await r.pump(t, size: b.value);
          await r.wait(t, 9600);
          await _shot(t, 'ls02_intro_$course', b.key);
          await r.done(t);
        });

        testWidgets('$course: a trace with the start dot, one stroke done', (WidgetTester t) async {
          final LetterRig r = _rig(_pack(course), 'trace_start');
          await r.pump(t, size: b.value);
          await _write(r.session, strokes: 1);
          await r.wait(t, 200);
          await _shot(t, 'ls02_trace_$course', b.key);
          await r.done(t);
        });

        testWidgets('$course: a copy, the model beside the box, one stroke done', (WidgetTester t) async {
          final LetterRig r = _rig(_pack(course), 'copy');
          await r.pump(t, size: b.value);
          await _write(r.session, strokes: 1);
          await r.wait(t, 200);
          await _shot(t, 'ls02_copy_$course', b.key);
          await r.done(t);
        });

        testWidgets('$course: from memory, level 1 of the help (the start dot and the hand)', (
          WidgetTester t,
        ) async {
          final LetterRig r = _rig(_pack(course), 'memory');
          await r.pump(t, size: b.value);
          await _scribble(r.session);
          await r.wait(t, 500);
          await _shot(t, 'ls02_memory1_$course', b.key);
          await r.done(t);
        });

        testWidgets('$course: from memory, level 3 of the help (trace mode, the whole path)', (
          WidgetTester t,
        ) async {
          final LetterRig r = _rig(_pack(course), 'memory');
          await r.pump(t, size: b.value);
          for (int i = 0; i < 3; i++) {
            await _scribble(r.session);
            await r.wait(t, 1800);
          }
          await r.wait(t, 14000);
          await _shot(t, 'ls02_memory3_$course', b.key);
          await r.done(t);
        });
      }

      if (b.key == 'phoneSE' || b.key == 'tabletPortrait') {
        testWidgets('heb: a bet written in the box, its model beside it (ב written)', (WidgetTester t) async {
          final LetterRig r = _rig(_betPack(), 'bet');
          await r.pump(t, size: b.value);
          await _write(r.session);
          await r.wait(t, 500);
          await _shot(t, 'ls02_written_bet', b.key);
          await r.done(t);
        });
      }

      testWidgets('heb: a word, the first letter written', (WidgetTester t) async {
        final LetterRig r = _rig(_pack('heb'), 'word');
        await r.pump(t, size: b.value);
        await _write(r.session);
        await r.wait(t, 200);
        await _shot(t, 'ls02_word_heb', b.key);
        await r.done(t);
      });
    });
  }
}
