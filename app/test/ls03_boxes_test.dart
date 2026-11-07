// LS03 in `boxes` mode (docs/milestones/L5.md section 5.3, layout docs/design/l5-templates.md section 3), played on the frame of the lesson screen:
// the boxes grow with the child's counters, a laid counter plays only a "tok", the count step classifies one more and one fewer (a count off by two or
// more is a retry with no tag), the colour step checks itself when every chip has a colour and the first complete colouring is the answer (both tags
// when both kinds of mistake), the stress step makes only the vowels targets, the which step names the end for the start, the response is numbers and
// colour letters only, and every step has its three-level ladder. Fixture course, every clip pending.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/boxes_session.dart';
import 'package:nitznutz/play/l5_art.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/response_code.dart';

import 'support/l4_rig.dart';
import 'support/l5_content.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>[
  'sun',
  'whale',
  'fish',
  'banana',
  'mouth_teeth',
  'mouth_round',
  'mouth_tongue',
];

LangPack _pack(String course) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  for (final String slug in <String>[
    'pa.seg_syll',
    'pa.add_vowel',
    'pa.mirror',
    'pa.syll',
    'pa.vowel_cons',
    'pa.hard_soft',
    'pa.stress_last',
    'pa.not_first',
  ]) {
    p.addTag(slug, 'diagnostic');
  }
  return p;
}

/// English "sun": count three, then the box of /n/ (the last one).
LangPack _sun({String purpose = 'learn', List<String> steps = const <String>['count', 'which']}) {
  final LangPack p = _pack('eng');
  p.add(
    boxesJson(
      course: 'eng',
      id: 'box1',
      purpose: purpose,
      kinds: <String>['c', 'vowel', 'c'],
      steps: steps,
      which: steps.contains('which') ? 3 : null,
      classify: <String, String>{
        'count=1': p.tag('pa.seg_syll'),
        'count=more': p.tag('pa.add_vowel'),
        if (steps.contains('which')) 'which=1': p.tag('pa.mirror'),
      },
      mouths: <String?>['mouth_teeth', 'mouth_round', 'mouth_tongue'],
    ),
  );
  return p;
}

/// Russian "рыба": hard, vowel, hard, vowel; the colours (brbr) and then the stress on the first vowel.
LangPack _rus({List<String> steps = const <String>['count', 'colour', 'stress']}) {
  final LangPack p = _pack('rus');
  p.pack.doc('skill.RUS-A-02.json')['stress'] = true;
  p.add(
    boxesJson(
      course: 'rus',
      id: 'box1',
      picture: 'fish',
      kinds: <String>['hard', 'vowel', 'hard', 'vowel'],
      steps: steps,
      colours: steps.contains('colour') ? 'brbr' : null,
      stress: steps.contains('stress') ? 2 : null,
      which: steps.contains('which') ? 4 : null,
      classify: <String, String>{
        if (steps.contains('colour')) ...<String, String>{
          'colour=vowel_cons': p.tag('pa.vowel_cons'),
          'colour=hard_soft': p.tag('pa.hard_soft'),
        },
        if (steps.contains('stress')) 'stress=4': p.tag('pa.stress_last'),
        if (steps.contains('which')) 'which=1': p.tag('pa.not_first'),
      },
    ),
  );
  return p;
}

Rig<BoxesSession> _rig(LangPack p, {Band band = Band.b}) => Rig<BoxesSession>(
  p,
  'box1',
  (LessonController c, Activity a) => BoxesSession(c, a as BoxesActivity, band: band),
);

Future<void> _lay(WidgetTester t, Rig<BoxesSession> r, int n) async {
  for (int i = 0; i < n; i++) {
    await t.tap(find.byKey(const Key('box-bowl')));
    await r.wait(t, 100);
  }
}

Future<void> _done(WidgetTester t, Rig<BoxesSession> r) async {
  await t.tap(find.byKey(const Key('box-done')));
  await r.wait(t, 100);
}

Future<void> _stamp(WidgetTester t, Rig<BoxesSession> r, String stamp, List<int> chips) async {
  await t.tap(find.byKey(Key('stamp-$stamp')));
  await r.wait(t, 100);
  for (final int i in chips) {
    await t.tap(find.byKey(Key('box-place-$i')));
    await r.wait(t, 100);
  }
}

/// The counters laid and counted right: the places light one by one and the next step comes in.
Future<void> _countRight(WidgetTester t, Rig<BoxesSession> r, int n) async {
  await _lay(t, r, n);
  await _done(t, r);
  await r.wait(t, 700 * n);
}

void main() {
  group('the count step', () {
    testWidgets(
      'the rail has a place for each counter laid and one dashed place next, and never shows how many there are',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_sun());
        await r.pump(t);
        expect(find.byKey(const Key('box-place-0')), findsNothing, reason: 'no empty box is drawn');
        expect(find.byKey(const Key('box-next')), findsOneWidget);
        await _lay(t, r, 2);
        expect(find.byKey(const Key('box-place-0')), findsOneWidget);
        expect(find.byKey(const Key('box-place-1')), findsOneWidget);
        expect(find.byKey(const Key('box-place-2')), findsNothing);
        expect(find.byKey(const Key('box-next')), findsOneWidget);
        await r.done(t);
      },
    );

    testWidgets(
      'laying a counter plays only the tok, never a unit\'s clip; the picture says the word again',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_sun());
        await r.pump(t);
        await r.wait(t, 200);
        r.heard.clear();
        await _lay(t, r, 3);
        expect(r.heard.clips, <String>['vo:eng.tok', 'vo:eng.tok', 'vo:eng.tok']);
        r.heard.clear();
        await t.tap(find.byKey(const Key('box-picture')));
        expect(r.heard.clips, <String>['vo:eng.box1.word']);
        await r.done(t);
      },
    );

    testWidgets(
      'a tap on a laid counter takes one back; the rail holds six and then the bowl does nothing more',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_sun());
        await r.pump(t);
        await _lay(t, r, 8);
        expect(r.session.laid, 6, reason: 'the rail of Band B holds six');
        expect(find.byKey(const Key('box-next')), findsNothing, reason: 'a full rail has no next place');
        await t.tap(find.byKey(const Key('box-place-5')));
        await r.wait(t, 100);
        expect(r.session.laid, 5);
        await r.done(t);
      },
    );

    testWidgets('a drag from the bowl onto the rail lands a counter; a drop elsewhere sends it home', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      final Offset bowl = t.getCenter(find.byKey(const Key('box-bowl')));
      await t.dragFrom(bowl, t.getCenter(find.byKey(const Key('box-rail'))) - bowl);
      await r.wait(t, 100);
      expect(r.session.laid, 1);
      await t.dragFrom(bowl, const Offset(-60, -40));
      await r.wait(t, 100);
      expect(r.session.laid, 1, reason: 'dropped in the air');
      await r.done(t);
    });

    testWidgets('"that\'s all" does nothing with no counter laid', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _done(t, r);
      expect(r.written, isEmpty);
      await r.done(t);
    });

    testWidgets('the right count writes nothing yet: the places light and the next step comes in', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _lay(t, r, 3);
      r.heard.clear();
      await _done(t, r);
      await r.wait(t, 2000);
      expect(r.written, isEmpty, reason: 'the answer is the whole item');
      expect(r.heard.clips, <String>[
        'vo:eng.box1.u0',
        'vo:eng.box1.u1',
        'vo:eng.box1.u2',
      ], reason: 'each unit in turn');
      expect(
        find.byKey(const Key('box-bowl')),
        findsNothing,
        reason: 'the bowl and "that\'s all" give way to the next step',
      );
      expect(find.byKey(const Key('box-sound')), findsOneWidget);
      await r.done(t);
    });

    testWidgets('one more is named by its tag, the rail wobbles and the counters go home', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _lay(t, r, 4);
      await _done(t, r);
      expect(r.written, <String>['incorrect:n=4']);
      expect(r.attempts.single.misconceptionTag, 'eng.pa.add_vowel');
      expect(r.session.state, AnswerState.notYet);
      await r.wait(t, 1200);
      expect(r.session.laid, 0, reason: 'the counters went home');
      expect(r.session.state, AnswerState.idle);
      await r.done(t);
    });

    testWidgets(
      'a count named exactly in classify is named even when it is off by two (one counter for the whole word)',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_sun());
        await r.pump(t);
        await _lay(t, r, 1);
        await _done(t, r);
        expect(r.written, <String>['incorrect:n=1']);
        expect(r.attempts.single.misconceptionTag, 'eng.pa.seg_syll');
        await r.done(t);
      },
    );

    testWidgets('a count off by two or more with no name is a retry with no tag and no evidence', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _lay(t, r, 5);
      await _done(t, r);
      expect(r.written, isEmpty, reason: 'nothing is written');
      expect(r.controller.errors, 0, reason: 'no help is escalated');
      await r.wait(t, 1200);
      expect(r.session.laid, 0);
      expect(r.session.state, AnswerState.idle);
      await r.done(t);
    });

    testWidgets('a count one fewer with no line of its own is a plain mistake with no tag', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _lay(t, r, 2);
      await _done(t, r);
      expect(r.written, <String>['incorrect:n=2']);
      expect(r.attempts.single.misconceptionTag, isEmpty, reason: 'the item names no "one fewer"');
      await r.done(t);
    });

    testWidgets('a probe has one answer: a count off by two is written, and nothing "not yet" is shown', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun(purpose: 'probe', steps: <String>['count']));
      await r.pump(t);
      await _lay(t, r, 5);
      await _done(t, r);
      expect(r.written, <String>['incorrect:n=5']);
      expect(r.session.state, AnswerState.selected);
      await r.done(t);
    });

    testWidgets('a count that is right in a count-only item is the answer: n=3', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_sun(steps: <String>['count']));
      await r.pump(t);
      await _lay(t, r, 3);
      await _done(t, r);
      await r.wait(t, 2200);
      expect(r.written, <String>['correct:n=3']);
      expect(r.session.state, AnswerState.correct);
      await r.done(t);
    });
  });

  group('the which step', () {
    testWidgets('the sound to find plays again from its pebble; a tap on the right place answers n=3.w=3', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _countRight(t, r, 3);
      r.heard.clear();
      await t.tap(find.byKey(const Key('box-sound')));
      expect(r.heard.clips, <String>['vo:eng.box1.u2'], reason: 'the clip of the unit that is asked for');
      await t.tap(find.byKey(const Key('box-place-2')));
      await r.wait(t, 200);
      expect(r.written, <String>['correct:n=3.w=3']);
      await r.done(t);
    });

    testWidgets('the end for the start is named (which=1), and the child goes on from where she is', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _countRight(t, r, 3);
      await t.tap(find.byKey(const Key('box-place-0')));
      await r.wait(t, 200);
      expect(r.written, <String>['incorrect:n=3.w=1']);
      expect(r.attempts.single.misconceptionTag, 'eng.pa.mirror');
      await r.wait(t, 1200);
      expect(r.session.state, AnswerState.idle);
      expect(r.session.laid, 3, reason: 'the counters stay: only the count step sends them home');
      await t.tap(find.byKey(const Key('box-place-2')));
      await r.wait(t, 200);
      expect(r.written.last, 'correct:n=3.w=3');
      await r.done(t);
    });

    testWidgets('another wrong place with no name is a mistake with no tag', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _countRight(t, r, 3);
      await t.tap(find.byKey(const Key('box-place-1')));
      await r.wait(t, 200);
      expect(r.attempts.single.misconceptionTag, isEmpty);
      expect(r.written, <String>['incorrect:n=3.w=2']);
      await r.done(t);
    });

    testWidgets('an item with no count step opens with the scheme laid, and no bowl', (WidgetTester t) async {
      final LangPack p = _sun(steps: <String>['which']);
      final Rig<BoxesSession> r = _rig(p);
      await r.pump(t);
      expect(r.session.laid, 3);
      expect(find.byKey(const Key('box-bowl')), findsNothing);
      expect(find.byKey(const Key('box-place-2')), findsOneWidget);
      await t.tap(find.byKey(const Key('box-place-2')));
      await r.wait(t, 200);
      expect(r.written, <String>['correct:w=3']);
      await r.done(t);
    });
  });

  group('the colour step (Russian)', () {
    testWidgets('three stamps with shapes, in the order vowel, hard, soft; the chips are tan until stamped', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_rus());
      await r.pump(t, size: const Size(667, 375));
      await _countRight(t, r, 4);
      expect(find.byKey(const Key('stamp-r')), findsOneWidget);
      expect(find.byKey(const Key('stamp-b')), findsOneWidget);
      expect(find.byKey(const Key('stamp-g')), findsOneWidget);
      expect(find.byType(SchemeMark), findsNWidgets(3), reason: 'every colour has its shape mark');
      expect(
        t.getTopLeft(find.byKey(const Key('stamp-r'))).dx,
        lessThan(t.getTopLeft(find.byKey(const Key('stamp-b'))).dx),
      );
      expect(
        t.getTopLeft(find.byKey(const Key('stamp-b'))).dx,
        lessThan(t.getTopLeft(find.byKey(const Key('stamp-g'))).dx),
      );
      expect(r.session.chips.every((SchemeKind? c) => c == null), isTrue);
      await r.done(t);
    });

    testWidgets('a stamp, then chips; or a chip, then a stamp: both ways', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_rus());
      await r.pump(t);
      await _countRight(t, r, 4);
      await _stamp(t, r, 'b', <int>[0, 2]);
      expect(r.session.chips[0], SchemeKind.hard);
      expect(r.session.chips[2], SchemeKind.hard);
      await t.tap(find.byKey(const Key('stamp-b')));
      await r.wait(t, 100);
      await t.tap(find.byKey(const Key('box-place-1')));
      await r.wait(t, 100);
      expect(r.session.chips[1], isNull, reason: 'no stamp is chosen: the chip is only chosen');
      await t.tap(find.byKey(const Key('stamp-r')));
      await r.wait(t, 100);
      expect(r.session.chips[1], SchemeKind.vowel, reason: 'chip first, then the stamp');
      await r.done(t);
    });

    testWidgets(
      'the step checks itself when every chip has a colour: brbr is right and goes on to the stress step',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_rus());
        await r.pump(t);
        await _countRight(t, r, 4);
        await _stamp(t, r, 'b', <int>[0, 2]);
        await _stamp(t, r, 'r', <int>[1, 3]);
        expect(r.written, isEmpty, reason: 'a colouring that is right writes nothing until the last step');
        expect(r.session.step, BoxStep.stress);
        await r.done(t);
      },
    );

    testWidgets(
      'a vowel coloured as a consonant is VOWEL-CONS; the wrong chips go back to tan, the right ones keep their colour',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_rus());
        await r.pump(t);
        await _countRight(t, r, 4);
        await _stamp(t, r, 'b', <int>[0, 1, 2]);
        await _stamp(t, r, 'r', <int>[3]);
        expect(r.written, <String>['incorrect:n=4.c=bbbr']);
        expect(r.attempts.single.misconceptionTag, 'rus.pa.vowel_cons');
        expect(r.session.notYet, <int>{1});
        await r.wait(t, 1200);
        expect(r.session.chips, <SchemeKind?>[SchemeKind.hard, null, SchemeKind.hard, SchemeKind.vowel]);
        await r.done(t);
      },
    );

    testWidgets('a hard consonant coloured soft is HARD-SOFT', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_rus());
      await r.pump(t);
      await _countRight(t, r, 4);
      await _stamp(t, r, 'g', <int>[0]);
      await _stamp(t, r, 'r', <int>[1, 3]);
      await _stamp(t, r, 'b', <int>[2]);
      expect(r.attempts.single.misconceptionTag, 'rus.pa.hard_soft');
      await r.done(t);
    });

    testWidgets('both kinds of mistake in one colouring record both tags, the vowel one first', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_rus());
      await r.pump(t);
      await _countRight(t, r, 4);
      await _stamp(t, r, 'b', <int>[1]);
      await _stamp(t, r, 'g', <int>[2]);
      await _stamp(t, r, 'b', <int>[0]);
      await _stamp(t, r, 'r', <int>[3]);
      expect(
        <String>[for (final AttemptRecord a in r.attempts) a.misconceptionTag],
        <String>['rus.pa.vowel_cons', 'rus.pa.hard_soft'],
      );
      expect(r.controller.errors, 1, reason: 'one move, one step up the help');
      await r.done(t);
    });

    testWidgets(
      'the first complete colouring is the answer: the retry is credited by the hint level and is not a second scored answer',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_rus(steps: <String>['count', 'colour']));
        await r.pump(t);
        await _countRight(t, r, 4);
        await _stamp(t, r, 'b', <int>[0, 1, 2]);
        await _stamp(t, r, 'r', <int>[3]);
        await r.wait(t, 1300);
        // The red stamp is still chosen: the chip that went back to tan is stamped again.
        await t.tap(find.byKey(const Key('box-place-1')));
        await r.wait(t, 2200);
        expect(r.written, <String>['incorrect:n=4.c=bbbr', 'correct:n=4.c=brbr']);
        expect(r.attempts.first.hintLevel, 0, reason: 'the first colouring is written before any help');
        expect(
          r.attempts.last.hintLevel,
          greaterThanOrEqualTo(1),
          reason: 'the retry carries the hint level the ladder reached',
        );
        await r.done(t);
      },
    );

    testWidgets('a scheme given tan opens with the counters laid (no count step), and colours them', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_rus(steps: <String>['colour']));
      await r.pump(t);
      expect(r.session.laid, 4);
      await _stamp(t, r, 'b', <int>[0, 2]);
      await _stamp(t, r, 'r', <int>[1, 3]);
      await r.wait(t, 2200);
      expect(r.written, <String>['correct:c=brbr']);
      await r.done(t);
    });
  });

  group('the stress step (Russian)', () {
    testWidgets('only the vowel chips are targets: a tap on a consonant is nothing', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_rus(steps: <String>['stress']));
      await r.pump(t);
      await t.tap(find.byKey(const Key('box-place-0')));
      await r.wait(t, 200);
      expect(r.written, isEmpty);
      expect(r.session.stressAt, isNull);
      expect(find.byKey(const Key('box-stress')), findsNothing);
      await r.done(t);
    });

    testWidgets(
      'the right vowel puts the sign over its place and answers s=2; the scheme was given coloured',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_rus(steps: <String>['stress']));
        await r.pump(t);
        expect(r.session.chipColour(1), SchemeKind.vowel);
        expect(r.session.chipColour(0), SchemeKind.hard);
        await t.tap(find.byKey(const Key('box-place-1')));
        await r.wait(t, 200);
        expect(find.byKey(const Key('box-stress')), findsOneWidget);
        expect(r.written, <String>['correct:s=2']);
        await r.done(t);
      },
    );

    testWidgets('the last syllable as the stressed one is STRESS-LAST, and the sign is let go', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_rus(steps: <String>['stress']));
      await r.pump(t);
      await t.tap(find.byKey(const Key('box-place-3')));
      await r.wait(t, 200);
      expect(r.written, <String>['incorrect:s=4']);
      expect(r.attempts.single.misconceptionTag, 'rus.pa.stress_last');
      await r.wait(t, 1200);
      expect(r.session.stressAt, isNull);
      await r.done(t);
    });

    testWidgets(
      'a word with two vowels is a two-choice item: one retry, and the second wrong choice shows the worked example',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_rus(steps: <String>['stress']));
        await r.pump(t);
        expect(r.activity.optionCount, 2);
        await t.tap(find.byKey(const Key('box-place-3')));
        await r.wait(t, 1300);
        await t.tap(find.byKey(const Key('box-place-3')));
        await r.wait(t, 300);
        expect(r.controller.guided, isTrue, reason: 'one retry, then the worked example (frame 2.3)');
        await r.done(t);
      },
    );

    testWidgets('after the whole item the response is numbers and colour letters only: n=4.c=brbr.s=2', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_rus());
      await r.pump(t);
      await _countRight(t, r, 4);
      await _stamp(t, r, 'b', <int>[0, 2]);
      await _stamp(t, r, 'r', <int>[1, 3]);
      await t.tap(find.byKey(const Key('box-place-1')));
      await r.wait(t, 300);
      expect(r.written, <String>['correct:n=4.c=brbr.s=2']);
      expect(ResponseCode.fits(r.attempts.single.response), isTrue);
      expect(ResponseCode.boxes(n: 3, colours: 'brb', stress: 1, which: 2), 'n=3.c=brb.s=1.w=2');
      expect(ResponseCode.boxes(n: 3), 'n=3');
      await r.done(t);
    });
  });

  group('the hints', () {
    testWidgets('count, level 1: the picture is lit and the word is said slowly', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_sun());
      await r.pump(t);
      await _lay(t, r, 4);
      await _done(t, r);
      await r.wait(t, 1300);
      expect(r.controller.hintShown, 1);
      expect(r.session.pictureLit, isTrue);
      expect(r.heard.clips, contains('vo:eng.box1.slow'));
      await r.done(t);
    });

    testWidgets(
      'count, level 2: a card of mouths for the phonemes of a word, claps for syllables; the rail is never touched',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_sun());
        await r.pump(t);
        for (int i = 0; i < 2; i++) {
          await _lay(t, r, 4);
          await _done(t, r);
          await r.wait(t, 1300);
        }
        expect(r.controller.hintShown, 2);
        await r.wait(t, 200);
        expect(find.byKey(const Key('box-card-mouths')), findsOneWidget);
        expect(find.byKey(const Key('box-unit-card-2')), findsOneWidget);
        await r.wait(t, 2600);
        expect(
          find.byKey(const Key('box-card-mouths')),
          findsNothing,
          reason: 'the card covers the stage only while it plays',
        );
        await r.done(t);

        final LangPack syl = _pack('eng');
        syl.add(
          boxesJson(
            course: 'eng',
            id: 'box1',
            unit: 'syllable',
            picture: 'banana',
            kinds: <String>['c', 'c', 'c'],
            steps: <String>['count'],
          ),
        );
        final Rig<BoxesSession> s = _rig(syl);
        await s.pump(t);
        for (int i = 0; i < 2; i++) {
          await _lay(t, s, 4);
          await _done(t, s);
          await s.wait(t, 1300);
        }
        await s.wait(t, 200);
        expect(find.byKey(const Key('box-card-claps')), findsOneWidget);
        await s.done(t);
      },
    );

    testWidgets(
      'count, level 3: the friend lays the counters, then they go home and the child does it; only the right count is then taken',
      (WidgetTester t) async {
        final Rig<BoxesSession> r = _rig(_sun());
        await r.pump(t);
        for (int i = 0; i < 3; i++) {
          await _lay(t, r, 4);
          await _done(t, r);
          await r.wait(t, 1300);
        }
        expect(r.controller.hintShown, 3);
        expect(r.controller.guided, isTrue);
        await r.wait(t, 9000);
        expect(r.session.laid, 0, reason: 'the counters went home after the demonstration');
        expect(r.controller.answerShown, isTrue);
        // Only the right count is taken: a wrong count goes home with no check.
        final int before = r.attempts.length;
        await _lay(t, r, 2);
        await _done(t, r);
        expect(r.attempts.length, before);
        expect(r.session.laid, 0);
        await r.done(t);
      },
    );

    testWidgets('colour, level 1: the chips light in turn with their sounds; nothing is marked', (
      WidgetTester t,
    ) async {
      final Rig<BoxesSession> r = _rig(_rus(steps: <String>['colour']));
      await r.pump(t);
      await _stamp(t, r, 'b', <int>[0, 1, 2]);
      r.heard.clear();
      await _stamp(t, r, 'r', <int>[3]);
      await r.wait(t, 4600);
      expect(r.controller.hintShown, 1);
      expect(r.heard.clips, containsAll(<String>['vo:rus.box1.u0', 'vo:rus.box1.u3']));
      await r.done(t);
    });

    testWidgets('which, level 1 lights the sound pebble and plays it again', (WidgetTester t) async {
      final Rig<BoxesSession> r = _rig(_sun(steps: <String>['which']));
      await r.pump(t);
      await r.wait(t, 200);
      r.heard.clear();
      await t.tap(find.byKey(const Key('box-place-0')));
      await r.wait(t, 1300);
      expect(r.controller.hintShown, 1);
      expect(r.session.soundLit, isTrue);
      expect(find.byKey(const Key('box-sound-glow')), findsOneWidget);
      expect(r.heard.clips, contains('vo:eng.box1.u2'));
      await r.done(t);
    });
  });

  group('direction and bands', () {
    testWidgets(
      'the Hebrew course lays its first place at the right and grows to the left; English at the left',
      (WidgetTester t) async {
        final LangPack h = _pack('heb');
        h.add(
          boxesJson(
            course: 'heb',
            id: 'box1',
            unit: 'cv',
            picture: 'banana',
            kinds: <String>['cv', 'cv', 'cv'],
            steps: <String>['count'],
          ),
        );
        final Rig<BoxesSession> hr = _rig(h);
        await hr.pump(t);
        await _lay(t, hr, 2);
        expect(
          t.getCenter(find.byKey(const Key('box-place-0'))).dx,
          greaterThan(t.getCenter(find.byKey(const Key('box-place-1'))).dx),
        );
        await hr.done(t);
        final Rig<BoxesSession> er = _rig(_sun());
        await er.pump(t);
        await _lay(t, er, 2);
        expect(
          t.getCenter(find.byKey(const Key('box-place-0'))).dx,
          lessThan(t.getCenter(find.byKey(const Key('box-place-1'))).dx),
        );
        await er.done(t);
      },
    );

    testWidgets(
      'Band A has a rail of five, Band C of seven; a word that fills the rail makes it one place longer',
      (WidgetTester t) async {
        final Rig<BoxesSession> a = _rig(_sun(), band: Band.a);
        await a.pump(t, size: const Size(667, 375));
        expect(a.session.railPlaces, 5);
        await _lay(t, a, 7);
        expect(a.session.laid, 5);
        await a.done(t);
        final Rig<BoxesSession> c = _rig(_sun(), band: Band.c);
        await c.pump(t, size: const Size(667, 375));
        expect(c.session.railPlaces, 7);
        await c.done(t);
      },
    );

    testWidgets('nothing in the new files is a timer, a countdown or a streak (the child space has none)', (
      WidgetTester t,
    ) async {
      final RegExp banned = RegExp('timer|countdown|streak|stopwatch', caseSensitive: false);
      for (final String f in <String>[
        'lib/play/boxes_session.dart',
        'lib/play/boxes_layer.dart',
        'lib/play/l5_art.dart',
        'lib/play/change_part_session.dart',
        'lib/play/ls05_widgets.dart',
        'lib/play/blend_slide_session.dart',
        'lib/play/blend_layer.dart',
        'lib/play/borrowed_screens.dart',
        'lib/play/slide_geometry.dart',
      ]) {
        expect(banned.hasMatch(File(f).readAsStringSync()), isFalse, reason: f);
      }
    });
  });
}
