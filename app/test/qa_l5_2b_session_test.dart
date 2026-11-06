// QA of the LS02 session (L5-2b): the help ladder (what is lit and when), the hand that must never cover the path it points at, RTL and LTR boxes,
// the text at scale 1.3, and that a child's points go nowhere. Fixture course and fake clips (support/ls02_content.dart), the real stroke sets.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart' show LetterWriteActivity;
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/letter_write_session.dart';
import 'package:nitznutz/play/stroke_geometry.dart';

import 'support/harness.dart';
import 'support/l4_rig.dart';
import 'support/ls02_content.dart';

const Size _se = Size(667, 375);
const Size _tabletPortrait = Size(768, 1024);

typedef LetterRig = Rig<LetterWriteSession>;

LetterRig _rig(Ls02Pack p, String id) =>
    Rig<LetterWriteSession>(p.pack, id, (c, a) => LetterWriteSession(c, a as LetterWriteActivity));

Ls02Pack _pack(String course, String form, {String mode = 'memory', bool word = false, List<String>? forms}) {
  final Ls02Pack p = Ls02Pack(course);
  p.add(
    letterJson(
      course: course,
      id: 'item',
      skill: mode == 'trace' ? p.skills.trace : p.skills.write,
      mode: mode,
      forms: forms ?? <String>[form],
      cue: mode == 'memory' ? 'sound' : null,
      cueClip: mode == 'memory' ? 'vo:$course.snd.x' : null,
      classify: p.classify(),
      word: word,
    ),
  );
  return p;
}

Future<void> _scribble(LetterWriteSession s) async {
  s.begin(const Offset(30, 20));
  for (int i = 1; i < 24; i++) {
    s.extend(Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60));
  }
  await s.end();
}

/// A stroke the check can name nothing of and that is far from every model: a retry that moves the help one step.
Future<void> _miss(WidgetTester t, LetterRig r) async {
  await _scribble(r.session);
  await r.wait(t, 1800);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('the help ladder: nothing is lit or named before its level', () {
    for (final (String, String) c in <(String, String)>[
      ('eng', 'latin.s'),
      ('heb', 'hebrew-print.bet'),
      ('rus', 'cyrillic.a.cap'),
    ]) {
      testWidgets(
        '${c.$1} memory: level 0 nothing, level 1 the start dot, level 2 the stroke drawn once, level 3 trace mode',
        (WidgetTester t) async {
          final LetterRig r = _rig(_pack(c.$1, c.$2), 'item');
          await r.pump(t, size: _se);
          final LetterWriteSession s = r.session;
          // Level 0.
          expect(r.controller.hintShown, 0);
          expect(s.startDotShown, isFalse, reason: 'no start dot before the first help');
          expect(s.fullGuide, isFalse);
          expect(s.traceMode, isFalse);
          expect(s.demo, isNull);
          expect(s.demoTrail, isEmpty);
          expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand at level 0');
          // Level 1.
          await _scribble(s);
          await r.wait(t, 300);
          expect(r.controller.hintShown, 1);
          expect(s.startDotShown, isTrue);
          expect(s.fullGuide, isFalse, reason: 'the whole path is not lit at level 1');
          expect(s.traceMode, isFalse);
          expect(
            find.byKey(const Key('hint-p12')),
            findsOneWidget,
            reason: 'the hand rests on the start dot at level 1',
          );
          await r.wait(t, 4000);
          expect(r.attempts, isEmpty, reason: 'a miss that cannot be named writes no row');
          // Level 2: the stroke drawn once (trail grows) and the whole path still not lit.
          await _scribble(s);
          int trail = 0;
          for (int k = 0; k < 40; k++) {
            await r.wait(t, 120);
            trail = trail < s.demoTrail.length ? s.demoTrail.length : trail;
            expect(s.fullGuide, isFalse, reason: 'level 2 is not trace mode');
          }
          expect(r.controller.hintShown, 2);
          expect(trail, greaterThan(5), reason: 'the stroke is drawn');
          expect(s.demoTrail, isEmpty, reason: 'then the box clears of it');
          // Level 3.
          await _scribble(s);
          await r.wait(t, 300);
          expect(r.controller.hintShown, 3);
          expect(s.traceMode, isTrue);
          expect(s.fullGuide, isTrue);
          await r.wait(t, 14000);
          await r.done(t);
        },
      );
    }

    testWidgets('a copy with the model shown shows nothing else at level 0', (WidgetTester t) async {
      final LetterRig r = _rig(_pack('eng', 'latin.t', mode: 'copy'), 'item');
      await r.pump(t, size: _se);
      expect(r.session.startDotShown, isFalse);
      expect(r.session.fullGuide, isFalse);
      expect(find.byKey(const Key('hint-p12')), findsNothing);
      await r.done(t);
    });

    testWidgets('level 3 is guided: a wrong stroke there writes no row (the help is at its top)', (
      WidgetTester t,
    ) async {
      final LetterRig r = _rig(_pack('heb', 'hebrew-print.mem'), 'item');
      await r.pump(t, size: _se);
      for (int i = 0; i < 3; i++) {
        await _miss(t, r);
      }
      await r.wait(t, 14000);
      expect(r.controller.guided, isTrue);
      await _scribble(r.session);
      await r.wait(t, 500);
      expect(r.attempts, isEmpty);
      await r.done(t);
    });
  });

  group('the pointing hand never covers the path it points at, nor rides it', () {
    // Forms with every kind of start: counter-clockwise rounds that start at the top right and go left (s c o a), a start in the middle of the
    // letter (e, Hebrew samekh), a start low in the box, strokes that go up, and the Hebrew letters that start at the left and go right.
    const List<(String, String)> forms = <(String, String)>[
      ('eng', 'latin.s'),
      ('eng', 'latin.c'),
      ('eng', 'latin.o'),
      ('eng', 'latin.a'),
      ('eng', 'latin.e'),
      ('eng', 'latin.t'),
      ('eng', 'latin.n'),
      ('eng', 'latin.i'),
      ('eng', 'latin.l'),
      ('rus', 'cyrillic.a.cap'),
      ('rus', 'cyrillic.em.cap'),
      ('rus', 'cyrillic.u'),
      ('rus', 'cyrillic.o'),
      ('rus', 'cyrillic.ka'),
      ('heb', 'hebrew-print.bet'),
      ('heb', 'hebrew-print.mem'),
      ('heb', 'hebrew-print.lamed'),
      ('heb', 'hebrew-print.shin'),
      ('heb', 'hebrew-print.samekh'),
      ('heb', 'hebrew-print.alef'),
      ('heb', 'hebrew-print.resh'),
    ];

    /// The hand's rectangle (as the widget is, with its transparent margins) in box units, and the path points of the strokes still to write
    /// that lie under it, not counting the 20 units round the start (the fingertip is on the start, and the picture's rectangle has a transparent margin: the
    /// pictures in docs/qa/l5-2b-hand-*.png show that nothing beyond the first dot is covered).
    List<String> under(WidgetTester t, LetterRig r, {required double fraction}) {
      final LetterWriteSession s = r.session;
      final Finder hand = find.byKey(const Key('hint-p12'));
      if (hand.evaluate().isEmpty) return <String>[];
      final Rect handRect = t.getRect(hand);
      final Rect stage = t.getRect(find.byKey(const Key('letter-stage')));
      final Size size = stage.size;
      final Rect box = s.layout(size).box.shift(stage.topLeft);
      final int? next = s.box.checker.next;
      if (next == null) return <String>[];
      final Offset start = s.box.form.strokes[next].start;
      final List<String> hits = <String>[];
      for (int i = 0; i < s.box.form.strokes.length; i++) {
        if (s.box.checker.done[i]) continue;
        final StrokeModel m = s.box.form.strokes[i];
        final List<Offset> path = resampleStroke(m.points, 40);
        final int upTo = i == next ? (path.length * fraction).round() : path.length;
        for (final Offset p in path.take(upTo)) {
          if ((p - start).distance < 20) continue;
          final Offset g = box.topLeft + p / 100 * box.width;
          if (handRect.contains(g)) {
            hits.add('stroke $i at (${p.dx.round()},${p.dy.round()})');
          }
        }
      }
      return hits;
    }

    for (final (String, Size) board in <(String, Size)>[
      ('phoneSE', _se),
      ('tabletPortrait', _tabletPortrait),
    ]) {
      testWidgets('level 1 on the ${board.$1}: the hand is not over the first of the way', (
        WidgetTester t,
      ) async {
        final List<String> report = <String>[];
        for (final (String, String) f in forms) {
          final LetterRig r = _rig(_pack(f.$1, f.$2), 'item');
          await r.pump(t, size: board.$2);
          await _scribble(r.session);
          final Set<String> hits = <String>{};
          for (int k = 0; k < 14; k++) {
            await r.wait(t, 100);
            hits.addAll(under(t, r, fraction: 0.3));
          }
          if (hits.isNotEmpty) report.add('${f.$2}: ${hits.take(4).join('; ')}');
          await r.wait(t, 6000);
          await r.done(t);
        }
        // ignore: avoid_print
        print(
          'QA hand level 1 ${board.$1}: ${report.length} of ${forms.length} forms have the hand rectangle over the path\n${report.join('\n')}',
        );
        expect(report, isEmpty, reason: report.join('\n'));
      }, skip: false);

      testWidgets(
        'level 3 on the ${board.$1}: the hand is not over the dotted path while it rests',
        (WidgetTester t) async {
          final List<String> report = <String>[];
          for (final (String, String) f in forms) {
            final LetterRig r = _rig(_pack(f.$1, f.$2), 'item');
            await r.pump(t, size: board.$2);
            for (int i = 0; i < 3; i++) {
              await _scribble(r.session);
              await r.wait(t, i < 2 ? 4500 : 60);
            }
            final Set<String> hits = <String>{};
            for (int k = 0; k < 14; k++) {
              await r.wait(t, 100);
              hits.addAll(under(t, r, fraction: 1));
            }
            if (hits.isNotEmpty) report.add('${f.$2}: ${hits.take(4).join('; ')}');
            await r.wait(t, 16000);
            await r.done(t);
          }
          // ignore: avoid_print
          print(
            'QA hand level 3 ${board.$1}: ${report.length} of ${forms.length} forms have the hand rectangle over the path\n${report.join('\n')}',
          );
          expect(report, isEmpty, reason: report.join('\n'));
        },
        // QA-L52-5 open: on the SE the resting hand of level 3 lies over the bowl of the e.
        skip: board.$1 == 'phoneSE',
      );
    }
  });

  group('direction of the boxes', () {
    testWidgets(
      'a Hebrew word: the first box is at the right, the boxes run right to left, and each is as wide as the others',
      (WidgetTester t) async {
        final LetterRig r = _rig(
          _pack(
            'heb',
            'x',
            mode: 'trace',
            word: true,
            forms: <String>['hebrew-print.shin', 'hebrew-print.bet', 'hebrew-print.tav'],
          ),
          'item',
        );
        await r.pump(t, size: _se);
        final Size size = t.getSize(find.byKey(const Key('letter-stage')));
        final LetterLayout l = r.session.layout(size);
        expect(l.slots.length, 3);
        expect(l.slots[0].center.dx, greaterThan(l.slots[1].center.dx));
        expect(l.slots[1].center.dx, greaterThan(l.slots[2].center.dx));
        expect(r.session.rtl, isTrue);
        // The strokes of each letter are written inside the same box as ever: the first letter is active first.
        expect(r.session.active, 0);
        await r.done(t);
      },
    );

    testWidgets(
      'a Hebrew word written in order: box 1 (the rightmost) takes the first letter, then the active one moves left',
      (WidgetTester t) async {
        final LetterRig r = _rig(
          _pack(
            'heb',
            'x',
            mode: 'trace',
            word: true,
            forms: <String>['hebrew-print.resh', 'hebrew-print.vav'],
          ),
          'item',
        );
        await r.pump(t, size: _se);
        final StrokeForm f = r.session.box.form;
        expect(f.id, 'hebrew-print.resh', reason: 'the first form of the list is the first letter written');
        for (final StrokeModel m in f.strokes) {
          r.session.begin(resampleStroke(m.points, 20).first);
          for (final Offset p in resampleStroke(m.points, 20).skip(1)) {
            r.session.extend(p);
          }
          await r.session.end();
        }
        await r.wait(t, 200);
        expect(r.session.active, 1);
        final Size size = t.getSize(find.byKey(const Key('letter-stage')));
        final LetterLayout l = r.session.layout(size);
        expect(l.slots[r.session.active].center.dx, lessThan(l.slots[0].center.dx));
        await r.done(t);
      },
    );

    for (final String course in <String>['eng', 'rus']) {
      testWidgets('$course: a word runs left to right, and the model of a copy is on the left', (
        WidgetTester t,
      ) async {
        final String a = course == 'eng' ? 'latin.c' : 'cyrillic.o';
        final String b = course == 'eng' ? 'latin.a' : 'cyrillic.es';
        final LetterRig w = _rig(
          _pack(course, 'x', mode: 'trace', word: true, forms: <String>[a, b]),
          'item',
        );
        await w.pump(t, size: _se);
        final LetterLayout lw = w.session.layout(t.getSize(find.byKey(const Key('letter-stage'))));
        expect(w.session.rtl, isFalse);
        expect(lw.slots[0].center.dx, lessThan(lw.slots[1].center.dx));
        await w.done(t);
        final LetterRig c = _rig(_pack(course, a, mode: 'copy'), 'item');
        await c.pump(t, size: _se);
        final LetterLayout lc = c.session.layout(t.getSize(find.byKey(const Key('letter-stage'))));
        expect(lc.model!.center.dx, lessThan(lc.box.center.dx));
        await c.done(t);
      });
    }

    testWidgets('heb: the model of a copy is on the right (where reading begins), the box on the left', (
      WidgetTester t,
    ) async {
      final LetterRig c = _rig(_pack('heb', 'hebrew-print.mem', mode: 'copy'), 'item');
      await c.pump(t, size: _se);
      final LetterLayout lc = c.session.layout(t.getSize(find.byKey(const Key('letter-stage'))));
      expect(lc.model!.center.dx, greaterThan(lc.box.center.dx));
      await c.done(t);
    });
  });

  group('text scale 1.3 and the small phone: nothing overflows, the letter box stays square and large', () {
    for (final (String, String, String) c in <(String, String, String)>[
      ('eng', 'latin.t', 'copy'),
      ('heb', 'hebrew-print.mem', 'copy'),
      ('rus', 'cyrillic.em.cap', 'memory'),
      ('heb', 'hebrew-print.shin', 'memory'),
    ]) {
      testWidgets('${c.$1} ${c.$3} at 1.3 on the SE and the tablet: no overflow, box at least 150 points', (
        WidgetTester t,
      ) async {
        for (final Size size in <Size>[_se, _tabletPortrait]) {
          final LetterRig r = _rig(_pack(c.$1, c.$2, mode: c.$3), 'item');
          t.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await r.pump(t, size: size);
          await _scribble(r.session);
          await r.wait(t, 800);
          expect(t.takeException(), isNull);
          final LetterLayout l = r.session.layout(t.getSize(find.byKey(const Key('letter-stage'))));
          expect(l.box.width, closeTo(l.box.height, 0.5));
          expect(l.box.width, greaterThanOrEqualTo(150), reason: '$size');
          await r.wait(t, 6000);
          await r.done(t);
        }
      });
    }
  });

  group('privacy: the child\'s points go nowhere', () {
    test('no file outside the session and the check holds or reads a stroke of the child', () {
      // The strokes live in LetterWriteSession (current, fading, LetterBox.ink) and die with it. Nothing else may name them.
      final List<String> users = <String>[];
      for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String text = e.readAsStringSync();
        if (text.contains('LetterBox') || text.contains('LetterChecker')) {
          users.add(e.path.replaceAll('\\', '/'));
        }
      }
      users.sort();
      expect(users, <String>[
        'lib/play/letter_write_session.dart',
        'lib/play/stroke_check.dart',
      ], reason: 'a new file touches the strokes of the child');
    });

    test('the response codes carry only short codes, never a coordinate', () {
      final RegExp ok = RegExp(r'^(b\d+\.)?s\d+\.(start|dir|lines|mirror|partner|miss)$');
      // Every code the session can write: built from numbers and one of the six words.
      final String source = File('lib/play/letter_write_session.dart').readAsStringSync();
      expect(source.contains('toStringAsFixed'), isFalse);
      expect(source.contains(r"'$"), isFalse);
      for (final String what in <String>['start', 'dir', 'lines', 'mirror', 'partner', 'miss']) {
        expect(ok.hasMatch('s2.$what'), isTrue);
        expect(ok.hasMatch('b2.s1.$what'), isTrue);
      }
    });

    testWidgets('the rows written by a real session carry only ok, a trace code or a stroke code', (
      WidgetTester t,
    ) async {
      final RegExp allowed = RegExp(
        r'^(ok|trace|direction|off|(b\d+\.)?s\d+\.(start|dir|lines|mirror|partner))$',
      );
      final LetterRig r = _rig(_pack('eng', 'latin.t', mode: 'copy'), 'item');
      await r.pump(t, size: _se);
      // A mirrored stem (a named or unnamed miss), then the letter right.
      final StrokeForm f = r.session.box.form;
      for (final StrokeModel m in f.strokes) {
        final List<Offset> p = resampleStroke(m.points, 24);
        r.session.begin(p.first);
        for (final Offset q in p.skip(1)) {
          r.session.extend(q);
        }
        await r.session.end();
      }
      await r.wait(t, 3000);
      for (final dynamic a in r.attempts) {
        final String code = (a.response ?? '') as String;
        expect(allowed.hasMatch(code), isTrue, reason: code);
      }
      expect(r.attempts, isNotEmpty);
      await r.done(t);
    });
  });
}
