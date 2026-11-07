// LS05 change one part (docs/milestones/L5.md section 5.4, layout docs/design/l5-templates.md section 4): the Hebrew wheel and the Russian strip, `explore`
// (the unscored teaching screen: every change plays what it makes, nothing is written) and `make` (scored: the tag of the distractor part, the parts as the
// response). Fixture course, every clip pending.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/design/board.dart' show BoardClass;
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/play/change_part_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/ls05_widgets.dart';
import 'package:nitznutz/play/response_code.dart';

import 'support/l4_rig.dart';
import 'support/l5_wheel.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>['cat', 'whale', 'fish'];

LangPack _heb() {
  final LangPack p = LangPack('heb')..addPictures(_pictures);
  p.addTag('dec.letter_mix', 'diagnostic');
  p.addTag('dec.vowel_skip', 'diagnostic');
  return p;
}

LangPack _rus() {
  final LangPack p = LangPack('rus')..addPictures(_pictures);
  p.addTag('dec.yi', 'diagnostic');
  p.addTag('dec.hard_soft', 'diagnostic');
  return p;
}

Rig<ChangePartSession> _rig(LangPack p, String id) => Rig<ChangePartSession>(
  p,
  id,
  (LessonController c, Activity a) => ChangePartSession(c, a as ChangePartActivity),
);

Future<void> _tap(WidgetTester t, Rig<ChangePartSession> r, String key) async {
  await t.tap(find.byKey(Key(key)));
  await r.wait(t, 400);
}

void main() {
  group('the documents', () {
    test('the S1 wheel and the strip pass the validator', () {
      final LangPack h = _heb();
      h.add(s1Explore());
      h.add(s1Make(h));
      final LangPack r = _rus();
      r.add(stripExplore());
      r.add(stripMake(r));
      for (final LangPack p in <LangPack>[h, r]) {
        expect(<String>[
          for (final x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
            '${x.path}: ${x.message}',
        ], isEmpty);
      }
    });
  });

  group('the Hebrew wheel, explore', () {
    testWidgets('a turn plays what it makes; the hub shows it; nothing is written', (WidgetTester t) async {
      final LangPack p = _heb()..add(s1Explore());
      final Rig<ChangePartSession> r = _rig(p, 'whl0');
      await r.pump(t);
      expect(r.session.madeText, 'מ$qamats', reason: 'the first letter with the first sign');
      r.heard.clear();
      await _tap(t, r, 'wheel-bead-1');
      expect(r.session.current[0], 'p2');
      expect(r.session.madeText, 'ל$qamats');
      expect(r.heard.clips, <String>['vo:heb.u.la']);
      r.heard.clear();
      await _tap(t, r, 'wheel-sign-2');
      expect(r.session.madeText, 'ל', reason: 'no sign: the bare letter');
      expect(r.heard.clips, <String>['vo:heb.s.la']);
      expect(r.written, isEmpty, reason: 'explore writes nothing');
      expect(r.attempts, isEmpty);
      await r.done(t);
    });

    testWidgets(
      'two signs that sound the same share one pale pill, as in the classroom\'s "two signs, one sound"',
      (WidgetTester t) async {
        final LangPack p = _heb()..add(s1Explore());
        final Rig<ChangePartSession> r = _rig(p, 'whl0');
        await r.pump(t);
        expect(find.byKey(const Key('sign-pill-0')), findsOneWidget, reason: 'qamats and patah');
        expect(find.byKey(const Key('sign-pill-1')), findsNothing);
        await r.done(t);
      },
    );

    testWidgets(
      'a unit with no sound (a letter that is never voiced alone) shakes the hub and plays nothing',
      (WidgetTester t) async {
        final LangPack p = _heb()..add(s1Explore());
        final Rig<ChangePartSession> r = _rig(p, 'whl0');
        await r.pump(t);
        await _tap(t, r, 'wheel-bead-4');
        await _tap(t, r, 'wheel-sign-2');
        r.heard.clear();
        await _tap(t, r, 'wheel-sign-2');
        expect(r.session.madeText, 'א');
        expect(r.heard.clips, isEmpty, reason: 'nothing is played for a unit with no sound');
        expect(r.written, isEmpty);
        await r.done(t);
      },
    );

    testWidgets('the dial turns the short way round, and a drag settles on the nearest bead and says it', (
      WidgetTester t,
    ) async {
      final LangPack p = _heb()..add(s1Explore());
      final Rig<ChangePartSession> r = _rig(p, 'whl0');
      await r.pump(t);
      await _tap(t, r, 'wheel-bead-6');
      expect(
        r.session.turn,
        closeTo(-1, 0.001),
        reason: 'from the first to the seventh is one step back, not six forward',
      );
      r.heard.clear();
      await t.drag(find.byKey(const Key('wheel-dial')), const Offset(-120, 0));
      await r.wait(t, 400);
      expect(r.session.turn, closeTo(r.session.turn.roundToDouble(), 0.001));
      expect(r.heard.clips, isNotEmpty);
      await r.done(t);
    });

    testWidgets(
      'the next letter in reading order stands towards the left: the dial turns the way a Hebrew row reads',
      (WidgetTester t) async {
        final LangPack p = _heb()..add(s1Explore());
        final Rig<ChangePartSession> r = _rig(p, 'whl0');
        await r.pump(t);
        expect(
          t.getCenter(find.byKey(const Key('wheel-bead-1'))).dx,
          lessThan(t.getCenter(find.byKey(const Key('wheel-bead-0'))).dx),
        );
        expect(
          t.getCenter(find.byKey(const Key('wheel-bead-6'))).dx,
          greaterThan(t.getCenter(find.byKey(const Key('wheel-bead-0'))).dx),
        );
        expect(
          t.getCenter(find.byKey(const Key('wheel-sign-0'))).dx,
          greaterThan(t.getCenter(find.byKey(const Key('wheel-sign-1'))).dx),
          reason: 'the first sign is at the right',
        );
        await r.done(t);
      },
    );

    testWidgets('she goes on once she has heard a few results; the guide waits, no lamp', (
      WidgetTester t,
    ) async {
      final LangPack p = _heb()..add(s1Explore());
      final Rig<ChangePartSession> r = _rig(p, 'whl0');
      await r.pump(t);
      expect(r.controller.noHelp, isTrue);
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.controller.solved, isFalse, reason: 'one result is not enough');
      await _tap(t, r, 'wheel-bead-1');
      await _tap(t, r, 'wheel-bead-2');
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 2000);
      expect(r.controller.finished, isTrue);
      expect(r.attempts, isEmpty, reason: 'a teaching screen leaves no attempt');
      await r.done(t);
    });
  });

  group('the Hebrew wheel, make', () {
    testWidgets('the right parts are the answer: p1.p3', (WidgetTester t) async {
      final LangPack p = _heb();
      p.add(s1Make(p));
      final Rig<ChangePartSession> r = _rig(p, 'whl1');
      await r.pump(t);
      expect(r.session.current, <String>[
        'p2',
        'p4',
      ], reason: 'the wheel opens on a combination that is not the answer');
      await _tap(t, r, 'wheel-bead-0');
      await _tap(t, r, 'wheel-sign-0');
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.written, <String>['correct:p1.p3']);
      expect(r.session.hubLit, isTrue);
      expect(ResponseCode.fits(r.attempts.single.response), isTrue);
      await r.done(t);
    });

    testWidgets('a wrong letter is LETTER-MIX, a skipped sign VOWEL-SKIP, and the wheel stays where it is', (
      WidgetTester t,
    ) async {
      final LangPack p = _heb();
      p.add(s1Make(p));
      final Rig<ChangePartSession> r = _rig(p, 'whl1');
      await r.pump(t);
      await _tap(t, r, 'wheel-sign-0');
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.written, <String>['incorrect:p2.p3']);
      expect(r.attempts.last.misconceptionTag, 'heb.dec.letter_mix');
      await r.wait(t, 1200);
      expect(r.session.current, <String>['p2', 'p3'], reason: 'she goes on from there');
      expect(r.session.state, AnswerState.idle);
      await _tap(t, r, 'wheel-bead-0');
      await _tap(t, r, 'wheel-sign-1');
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.attempts.last.misconceptionTag, 'heb.dec.vowel_skip');
      expect(r.written.last, 'incorrect:p1.p4');
      await r.done(t);
    });

    testWidgets('when both are wrong the tag is the first part\'s, the letter', (WidgetTester t) async {
      final LangPack p = _heb();
      p.add(s1Make(p));
      final Rig<ChangePartSession> r = _rig(p, 'whl1');
      await r.pump(t);
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.attempts.single.misconceptionTag, 'heb.dec.letter_mix');
      await r.done(t);
    });

    testWidgets('the target pebble plays the target; the hub plays what is made now', (WidgetTester t) async {
      final LangPack p = _heb();
      p.add(s1Make(p));
      final Rig<ChangePartSession> r = _rig(p, 'whl1');
      await r.pump(t);
      r.heard.clear();
      await t.tap(find.byKey(const Key('change-target')));
      expect(r.heard.clips, <String>['vo:heb.u.la']);
      r.heard.clear();
      await t.tap(find.byKey(const Key('wheel-hub')));
      expect(r.heard.clips, <String>['vo:heb.s.resh']);
      await r.done(t);
    });

    testWidgets('level 1: the target again, then the child\'s result, the hub lit', (WidgetTester t) async {
      final LangPack p = _heb();
      p.add(s1Make(p));
      final Rig<ChangePartSession> r = _rig(p, 'whl1');
      await r.pump(t);
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      r.heard.clear();
      await r.wait(t, 2800);
      expect(r.controller.hintShown, 1);
      expect(r.heard.clips, <String>['vo:heb.u.la', 'vo:heb.s.resh']);
      await r.done(t);
    });

    testWidgets(
      'level 3: the friend turns to the right letter and taps the right sign; then everything goes back and only the right parts are taken',
      (WidgetTester t) async {
        final LangPack p = _heb();
        p.add(s1Make(p));
        final Rig<ChangePartSession> r = _rig(p, 'whl1');
        await r.pump(t);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('change-done')));
          await r.wait(t, 1300);
        }
        expect(r.controller.guided, isTrue);
        await r.wait(t, 6000);
        expect(r.session.current, <String>['p2', 'p4'], reason: 'back to where she was');
        expect(r.controller.answerShown, isTrue);
        await _tap(t, r, 'wheel-bead-1');
        expect(r.session.current[0], 'p2', reason: 'a wrong part is not taken at the top of the help');
        await _tap(t, r, 'wheel-bead-0');
        expect(r.session.current[0], 'p1');
        await r.done(t);
      },
    );
  });

  group('the Russian strip', () {
    testWidgets(
      'explore: the vowel in the window changes with the tile, the result plays and its picture changes with it',
      (WidgetTester t) async {
        final LangPack p = _rus()..add(stripExplore());
        final Rig<ChangePartSession> r = _rig(p, 'str0');
        await r.pump(t);
        expect(r.session.windowText, 'о');
        expect(find.byKey(const Key('strip-picture')), findsOneWidget, reason: 'the word has a picture');
        r.heard.clear();
        await _tap(t, r, 'strip-tile-1');
        expect(r.session.windowText, 'и');
        expect(r.heard.clips, <String>['vo:rus.w.kit']);
        expect(r.session.madeText, 'кит');
        expect(r.attempts, isEmpty);
        await r.done(t);
      },
    );

    testWidgets('the strip runs left to right, a pair on one pill', (WidgetTester t) async {
      final LangPack p = _rus();
      p.add(stripMake(p));
      final Rig<ChangePartSession> r = _rig(p, 'str1');
      await r.pump(t);
      // The tiles stand in the order of the pairs (a-ya, o-yo, u-yu, y-i, e-ye): u and yu, then y and i.
      expect(r.session.stripParts.map((ChangePart x) => x.text).toList(), <String>['у', 'ю', 'ы', 'и']);
      double x(int i) => t.getCenter(find.byKey(Key('strip-tile-$i'))).dx;
      expect(x(0), lessThan(x(1)));
      expect(x(1) - x(0), lessThan(x(2) - x(1)), reason: 'a pair is closer than two pairs');
      await r.done(t);
    });

    testWidgets('a finger slid along the strip makes each tile current and plays only the one it rests on', (
      WidgetTester t,
    ) async {
      final LangPack p = _rus();
      p.add(stripMake(p));
      final Rig<ChangePartSession> r = _rig(p, 'str1');
      await r.pump(t);
      r.heard.clear();
      final Offset from = t.getCenter(find.byKey(const Key('strip-tile-0')));
      final Offset to = t.getCenter(find.byKey(const Key('strip-tile-3')));
      final TestGesture g = await t.startGesture(from);
      for (int i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 10)!);
        await t.pump(const Duration(milliseconds: 20));
      }
      await g.up();
      await r.wait(t, 400);
      expect(r.session.currentTile, 3);
      expect(r.heard.clips.length, lessThanOrEqualTo(2), reason: 'a fast slide does not stack clips');
      expect(r.heard.clips.last, r.session.result!.clip);
      await r.done(t);
    });

    testWidgets('make: the right vowel is the answer, a wrong one carries its part\'s tag', (
      WidgetTester t,
    ) async {
      final LangPack p = _rus();
      p.add(stripMake(p));
      final Rig<ChangePartSession> r = _rig(p, 'str1');
      await r.pump(t);
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.attempts.single.misconceptionTag, 'rus.dec.yi', reason: 'the first part she has is ы');
      expect(r.written.single, 'incorrect:p1');
      await r.wait(t, 1200);
      final int li = r.session.stripParts.indexWhere((ChangePart x) => x.text == 'и');
      await _tap(t, r, 'strip-tile-$li');
      await t.tap(find.byKey(const Key('change-done')));
      await r.wait(t, 200);
      expect(r.written.last, 'correct:p2');
      await r.done(t);
    });
  });

  group('geometry', () {
    test('a wheel with seven or more parts is a loop; a shorter one only shifts its parts', () {
      expect(
        ringOffset(6, 0, 7, 7),
        -1,
        reason: 'the seventh bead stands just before the top, on the other side',
      );
      expect(ringOffset(1, 0, 7, 7), 1);
      expect(ringOffset(3, 0, 7, 7), 3);
      expect(ringOffset(4, 0, 7, 7), -3);
      expect(ringOffset(1, 0, 3, 7), 1, reason: 'a short wheel does not loop');
      expect(ringOffset(2, 1.5, 7, 7), closeTo(0.5, 1e-9));
    });

    test('signs with one sound share a pill', () {
      final List<List<int>> g = signGroups(<String>['a', 'b', 'c'], (int x, int y) => x == 0 && y == 1);
      expect(g, <List<int>>[
        <int>[0, 1],
        <int>[2],
      ]);
    });

    test('the wheel of every board stands inside its board: the dial, the hub in the dial, the signs on the panel above the bottom band', () {
      for (final BoardClass b in BoardClass.values) {
        final WheelSpec w = WheelSpec.of(b);
        final double radius = w.ring + w.bead / 2 + 8;
        expect(w.centre.dx - radius, greaterThanOrEqualTo(0), reason: '${b.name}: the left of the dial');
        expect(
          w.centre.dx + radius,
          lessThanOrEqualTo(b.size.width),
          reason: '${b.name}: the right of the dial',
        );
        expect(w.centre.dy - radius, greaterThanOrEqualTo(0), reason: '${b.name}: the top of the dial');
        expect(w.hub.width, lessThan(radius * 2), reason: '${b.name}: the hub in the dial');
        expect(
          w.centre.dy - w.hub.height - 2,
          greaterThan(w.centre.dy - w.ring + w.bead / 2),
          reason: '${b.name}: the hub under the part at the top',
        );
        final double panelBottom = b.size.height - 24 - 8;
        // The spec's own numbers put the phone SE's signs one point under the line (288 + 56 against 343): within two points is on the panel.
        expect(
          w.signY + w.signBead,
          lessThanOrEqualTo(panelBottom + 2),
          reason: '${b.name}: the signs are on the panel',
        );
        final double signsWide = 4 * w.signBead + 3 * w.signGap;
        expect(
          signsWide,
          lessThanOrEqualTo(2 * radius),
          reason: '${b.name}: four signs fit in the width of the dial',
        );
        // Seven beads fit round the half dial: 30 degrees apart, the beads do not overlap along the ring.
        expect(
          2 * w.ring * math.sin(w.step * math.pi / 360),
          greaterThan(w.bead * 0.85),
          reason: '${b.name}: neighbouring beads',
        );
      }
    });
  });
}
