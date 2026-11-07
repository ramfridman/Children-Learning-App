// LS02 in the session (L5-2b QA fixes): a letter built another right way counts and writes no mistake; the item waits about a second after the last
// needed stroke and reads everything drawn (the stem of a t is not an l); a look-alike the item lists is named; the hand lies on the side where the
// letter is not; and a bad drawing path of a stroke set never throws in a paint.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart' show LetterWriteActivity;
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/letter_write_session.dart';
import 'package:nitznutz/play/stroke_geometry.dart';

import 'support/harness.dart';
import 'support/l4_rig.dart';
import 'support/ls02_content.dart';
import 'support/stroke_hands.dart';

typedef LetterRig = Rig<LetterWriteSession>;

const Size _se = Size(667, 375);

LetterRig _rig(Ls02Pack p) =>
    Rig<LetterWriteSession>(p.pack, 'item', (c, a) => LetterWriteSession(c, a as LetterWriteActivity));

Ls02Pack _pack(
  String course,
  String form, {
  String mode = 'memory',
  Map<String, String> partners = const <String, String>{},
}) {
  final Ls02Pack p = Ls02Pack(course);
  p.add(
    letterJson(
      course: course,
      id: 'item',
      skill: p.skills.write,
      mode: mode,
      forms: <String>[form],
      cue: mode == 'memory' ? 'sound' : null,
      cueClip: mode == 'memory' ? 'vo:$course.snd.x' : null,
      classify: p.classify(partners: partners),
    ),
  );
  return p;
}

/// One stroke written by the finger along [pts] (box units, as the model stores them).
Future<void> _draw(LetterWriteSession s, List<Offset> pts) async {
  final List<Offset> path = resampleStroke(pts, 24);
  s.begin(path.first);
  for (final Offset p in path.skip(1)) {
    s.extend(p);
  }
  await s.end();
}

Future<void> _drawModel(LetterWriteSession s, List<StrokeModel> build) async {
  for (final StrokeModel m in build) {
    if (m.kind == StrokeKind.dot) {
      await s.tap(m.start);
    } else {
      await _draw(s, m.points);
    }
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('another right build counts, and nothing is written against the child', () {
    for (final (String id, int build) in <(String, int)>[
      ('latin.a', 0),
      ('latin.a', 1),
      ('latin.d', 0),
      ('latin.n', 0),
      ('latin.b', 0),
      ('latin.p', 0),
    ]) {
      testWidgets('$id, build ${build + 1}: one correct row, ok, no tag', (WidgetTester t) async {
        final LetterRig r = _rig(_pack('eng', id));
        await r.pump(t, size: _se);
        await _drawModel(r.session, strokeForm(id).alternates[build]);
        await r.wait(t, 1200);
        expect(r.written, <String>['correct:ok']);
        expect(r.attempts.single.misconceptionTag, isEmpty);
        expect(r.attempts.single.hintLevel, 0);
        await r.wait(t, 4000);
        await r.done(t);
      });
    }

    testWidgets(
      'the help follows the build: after the ball of a ball and a stick, the start dot is the stick\'s',
      (WidgetTester t) async {
        final LetterRig r = _rig(_pack('eng', 'latin.a'));
        await r.pump(t, size: _se);
        final StrokeForm a = strokeForm('latin.a');
        await _draw(r.session, a.alternates[0][0].points);
        expect(r.session.box.checker.next, 1);
        expect(r.session.startPoint(t.getSize(find.byKey(const Key('letter-stage')))), isNotNull);
        await r.done(t);
      },
    );
  });

  group('the item waits for another stroke, and reads everything drawn', () {
    testWidgets('a plain l counts after about a second, and not before', (WidgetTester t) async {
      final LetterRig r = _rig(_pack('eng', 'latin.l'));
      await r.pump(t, size: _se);
      await _drawModel(r.session, strokeForm('latin.l').strokes);
      await r.wait(t, 800);
      expect(r.written, isEmpty);
      await r.wait(t, 400);
      expect(r.written, <String>['correct:ok']);
      await r.wait(t, 4000);
      await r.done(t);
    });

    testWidgets(
      'the stem of a t is not an l: the t is a retry that writes nothing, and the help moves a step',
      (WidgetTester t) async {
        final LetterRig r = _rig(_pack('eng', 'latin.l'));
        await r.pump(t, size: _se);
        final StrokeForm tee = strokeForm('latin.t');
        await _draw(r.session, tee.strokes[0].points);
        await r.wait(t, 900); // under a second: the wait is not over
        await _draw(r.session, tee.strokes[1].points);
        await r.wait(t, 500);
        expect(r.session.box.ink, hasLength(2), reason: 'the wait began again with the second stroke');
        expect(r.written, isEmpty);
        await r.wait(t, 700);
        expect(r.written, isEmpty, reason: 'a wrong letter is not a success, and it is no named error');
        expect(r.session.box.ink, isEmpty, reason: 'the box is clear for a new try');
        expect(r.controller.hintShown, 1);
        expect(r.session.box.checker.complete, isFalse);
        await r.wait(t, 2000);
        // The retry, an l, is right at help level 1: a hinted answer, never a full success.
        await _drawModel(r.session, strokeForm('latin.l').strokes);
        await r.wait(t, 1200);
        expect(r.written, <String>['correct:ok']);
        expect(r.attempts.single.hintLevel, 1);
        await r.wait(t, 4000);
        await r.done(t);
      },
    );

    testWidgets('a scribble that was missed does not hide a right letter that comes after it', (
      WidgetTester t,
    ) async {
      final LetterRig r = _rig(_pack('eng', 'latin.l'));
      await r.pump(t, size: _se);
      await _draw(r.session, <Offset>[
        for (int i = 0; i < 24; i++) Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60),
      ]);
      await r.wait(t, 1500);
      await _drawModel(r.session, strokeForm('latin.l').strokes);
      await r.wait(t, 1200);
      expect(r.written, <String>['correct:ok']);
      await r.wait(t, 4000);
      await r.done(t);
    });

    testWidgets(
      'a look-alike the item lists is named when the whole drawing is that letter: a bet for a resh',
      (WidgetTester t) async {
        final Ls02Pack p = _pack(
          'heb',
          'hebrew-print.resh',
          partners: <String, String>{'hebrew-print.bet': 'heb.wri.stroke'},
        );
        final LetterRig r = _rig(p);
        await r.pump(t, size: _se);
        await _drawModel(r.session, strokeForm('hebrew-print.bet').strokes);
        await r.wait(t, 1200);
        expect(r.written, <String>['incorrect:s1.partner']);
        expect(r.attempts.single.misconceptionTag, 'heb.wri.stroke');
        await r.wait(t, 3000);
        await r.done(t);
      },
    );

    testWidgets('a bet for a resh that is not listed is a retry with no row', (WidgetTester t) async {
      final LetterRig r = _rig(_pack('heb', 'hebrew-print.resh'));
      await r.pump(t, size: _se);
      await _drawModel(r.session, strokeForm('hebrew-print.bet').strokes);
      await r.wait(t, 1200);
      expect(r.written, isEmpty);
      expect(r.controller.hintShown, 1);
      await r.wait(t, 3000);
      await r.done(t);
    });

    testWidgets('trace mode does not wait: the traced path counts at once', (WidgetTester t) async {
      final Ls02Pack p = Ls02Pack('eng');
      p.add(
        letterJson(
          id: 'item',
          skill: p.skills.trace,
          mode: 'trace',
          guide: 'full',
          forms: <String>['latin.l'],
          classify: p.classify(),
        ),
      );
      final LetterRig r = _rig(p);
      await r.pump(t, size: _se);
      await _drawModel(r.session, strokeForm('latin.l').strokes);
      await t.pump();
      expect(r.written, hasLength(1));
      expect(r.written.single, startsWith('correct:'));
      await r.wait(t, 4000);
      await r.done(t);
    });
  });

  group('the hand lies on the side where the letter is not', () {
    Future<bool> fromBelow(WidgetTester t, String course, String form) async {
      final LetterRig r = _rig(_pack(course, form));
      await r.pump(t, size: _se);
      await _draw(r.session, <Offset>[
        for (int i = 0; i < 24; i++) Offset(30 + (i * 7) % 40, 20 + (i * 13) % 60),
      ]);
      await r.wait(t, 500);
      final bool hand = find.byKey(const Key('hint-p12')).evaluate().isNotEmpty;
      expect(hand, isTrue);
      final bool below = find
          .descendant(of: find.byKey(const Key('hint-p12')), matching: find.byType(RotatedBox))
          .evaluate()
          .isNotEmpty;
      await r.wait(t, 6000);
      await r.done(t);
      return below;
    }

    testWidgets('an e starts in the middle of its letter: the hand comes from below, where the bowl is not', (
      WidgetTester t,
    ) async {
      expect(await fromBelow(t, 'eng', 'latin.e'), isTrue);
    });

    testWidgets('a stroke that starts at the top of a letter that goes down keeps the guide\'s side', (
      WidgetTester t,
    ) async {
      expect(await fromBelow(t, 'eng', 'latin.s'), isFalse);
      expect(await fromBelow(t, 'eng', 'latin.i'), isFalse);
    });
  });

  group('a stroke path that is not whole never throws in a paint (SEC-L5-1)', () {
    for (final String d in <String>[
      'M 5 5 L',
      'M 50 ',
      'M 1  2',
      'M - 5 5',
      'M 5 5 L 900 5',
      'M 5 5 C 1 2 3',
      'X 1 2',
      'M 5 5 L a b',
    ]) {
      testWidgets('d = "$d"', (WidgetTester t) async {
        final Ls02Pack p = _pack('eng', 'latin.l', mode: 'copy');
        final Map<String, Object?> doc = p.pack.pack.doc('strokes.latin.json');
        final Map<String, Object?> form = (doc['forms']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .firstWhere((Map<String, Object?> f) => f['id'] == 'latin.l');
        ((form['strokes']! as List<Object?>).first! as Map<String, Object?>)['d'] = d;
        final LetterRig r = _rig(p);
        await r.pump(t, size: _se);
        expect(r.session.modelShown, isTrue);
        await r.wait(t, 300);
        expect(t.takeException(), isNull);
        await r.wait(t, 4000);
        await r.done(t);
      });
    }
  });
}
