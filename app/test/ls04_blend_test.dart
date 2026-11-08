// LS04 blend slide (docs/milestones/L5.md section 5.5, layout docs/design/l5-templates.md section 5): the slide is practice and writes nothing; only the choice
// is scored, and in a scored item the whole word plays after the choice, never before it. A part with no clip lights in silence; a stop never sounds alone
// in a merge; Hebrew slides from the right to the left. The ladder: the slow slide, the parts another way, the friend slides and points. Fixture course,
// every clip pending.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/blend_slide_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import 'support/l4_rig.dart';
import 'support/l5_content.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>['cat', 'sun', 'fish', 'banana'];

LangPack _eng({bool clips = true}) {
  final LangPack p = LangPack('eng')..addPictures(_pictures);
  p.addTag('rea.reversed', 'diagnostic');
  p.addTag('rea.first_guess', 'diagnostic');
  p.add(
    blendJson(
      course: 'eng',
      id: 'sl1',
      text: 'pan',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('p', clip: clips ? 'vo:eng.snd.p' : null, stretch: false),
        bpart('a', clip: clips ? 'vo:eng.snd.a' : null),
        bpart('n', clip: clips ? 'vo:eng.snd.n' : null),
      ],
      whole: 'vo:eng.pan',
      stretched: 'vo:eng.blend.pan',
      options: <Map<String, Object?>>[
        slideOption('o1', picture: 'cat'),
        slideOption('o2', picture: 'sun', tag: p.tag('rea.reversed')),
        slideOption('o3', picture: 'fish', tag: p.tag('rea.first_guess')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

LangPack _engDigraph() {
  final LangPack p = LangPack('eng')..addPictures(_pictures);
  p.addTag('rea.reversed', 'diagnostic');
  p.add(
    blendJson(
      course: 'eng',
      id: 'sl1',
      text: 'shop',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('sh', clip: 'vo:eng.snd.sh'),
        bpart('o', clip: 'vo:eng.snd.o'),
        bpart('p', clip: 'vo:eng.snd.p', stretch: false),
      ],
      whole: 'vo:eng.shop',
      options: <Map<String, Object?>>[
        slideOption('o1', picture: 'cat'),
        slideOption('o2', picture: 'sun', tag: p.tag('rea.reversed')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

/// Russian ma: the merge of a held consonant and a vowel; the options are sound buttons.
LangPack _rus({bool stop = false}) {
  final LangPack p = LangPack('rus')..addPictures(_pictures);
  p.addTag('rea.letter_name', 'diagnostic');
  p.addTag('rea.reversed', 'diagnostic');
  p.add(
    blendJson(
      course: 'rus',
      id: 'mg1',
      text: stop ? 'ка' : 'ма',
      parts: <({String text, String? clip, bool stretch})>[
        stop ? bpart('к', stretch: false) : bpart('м', clip: 'vo:rus.snd.m'),
        bpart('а', clip: 'vo:rus.snd.a'),
      ],
      whole: 'vo:rus.mg.ma',
      options: <Map<String, Object?>>[
        slideOption('o1', clip: 'vo:rus.mg.ma'),
        slideOption('o2', clip: 'vo:rus.snd.m', tag: p.tag('rea.letter_name')),
        slideOption('o3', clip: 'vo:rus.mg.am', tag: p.tag('rea.reversed')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

/// Hebrew aba as units: a CV unit, a CV unit, and the last letter.
LangPack _heb() {
  final LangPack p = LangPack('heb')..addPictures(_pictures);
  p.addTag('rea.reversed', 'diagnostic');
  p.add(
    blendJson(
      course: 'heb',
      id: 'un1',
      text: 'אַבָּא',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('אַ', clip: 'vo:heb.u.a'),
        bpart('בָּ', clip: 'vo:heb.u.ba'),
        bpart('א', clip: 'vo:heb.u.alef'),
      ],
      whole: 'vo:heb.aba',
      options: <Map<String, Object?>>[
        slideOption('o1', picture: 'cat'),
        slideOption('o2', picture: 'sun', tag: p.tag('rea.reversed')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

Rig<BlendSlideSession> _rig(LangPack p, String id, {Band band = Band.b}) => Rig<BlendSlideSession>(
  p,
  id,
  (LessonController c, Activity a) => BlendSlideSession(c, a as BlendSlideActivity, band: band),
);

Offset _centre(WidgetTester t, String key) => t.getCenter(find.byKey(Key(key)));

/// A finger down on the knob, slid to the mark of part [last] (and a little beyond it), and up.
Future<void> _slide(WidgetTester t, Rig<BlendSlideSession> r, {required int last, bool lift = true}) async {
  await r.wait(t, 2100);
  final Offset knob = _centre(t, 'slide-knob');
  final TestGesture g = await t.startGesture(knob);
  final Offset to = _centre(t, 'slide-mark-$last');
  for (int i = 1; i <= 12; i++) {
    await g.moveTo(Offset.lerp(knob, to, i / 12)!);
    await t.pump(const Duration(milliseconds: 60));
  }
  if (lift) {
    await g.up();
    await r.wait(t, 500);
  }
}

void main() {
  group('the slide (English)', () {
    testWidgets(
      'each part sounds and lights as the knob passes it; nothing is written and the whole is not played',
      (WidgetTester t) async {
        final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
        await r.pump(t);
        await r.wait(t, 200);
        r.heard.clear();
        await _slide(t, r, last: 2);
        expect(r.heard.clips, <String>[
          'vo:eng.snd.p',
          'vo:eng.snd.a',
          'vo:eng.snd.n',
        ], reason: 'the parts only, in the order of the word, never the whole');
        expect(r.written, isEmpty, reason: 'the slide is practice');
        expect(r.attempts, isEmpty);
        await r.done(t);
      },
    );

    testWidgets('the knob glides home on release, and the marks passed are kept until the next slide', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await _slide(t, r, last: 1);
      expect(r.session.knobT, 0);
      expect(r.session.passed, <int>{0, 1});
      expect(
        find.byKey(const Key('slide-column-1')),
        findsNothing,
        reason: 'the column is only there while the part sounds',
      );
      await r.done(t);
    });

    testWidgets('going back plays nothing', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 2100);
      final Offset knob = _centre(t, 'slide-knob');
      final TestGesture g = await t.startGesture(knob);
      await g.moveTo(_centre(t, 'slide-mark-1'));
      await t.pump(const Duration(milliseconds: 100));
      r.heard.clear();
      await g.moveTo(_centre(t, 'slide-mark-0'));
      await t.pump(const Duration(milliseconds: 100));
      await g.moveTo(_centre(t, 'slide-mark-1'));
      await t.pump(const Duration(milliseconds: 100));
      await g.up();
      expect(r.heard.clips, isEmpty);
      await r.done(t);
    });

    testWidgets('a finger that starts at the arrow end plays nothing; the knob gives two pulses', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 2100);
      r.heard.clear();
      final Offset end = _centre(t, 'slide-mark-2') + const Offset(60, 0);
      final TestGesture g = await t.startGesture(end);
      await g.moveBy(const Offset(-150, 0));
      await t.pump(const Duration(milliseconds: 100));
      await g.up();
      expect(r.heard.clips, isEmpty);
      expect(r.session.pulse, isTrue);
      await r.wait(t, 1500);
      expect(r.session.pulse, isFalse);
      await r.done(t);
    });

    testWidgets('a tap on the knob slides it by itself, slowly: each part for its clip, the parts only', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 2100);
      r.heard.clear();
      await t.tap(find.byKey(const Key('slide-knob')));
      await r.wait(t, 3500);
      expect(r.heard.clips, <String>['vo:eng.snd.p', 'vo:eng.snd.a', 'vo:eng.snd.n']);
      expect(r.session.auto, isFalse);
      expect(r.session.knobT, 0, reason: 'the knob is home again');
      await r.done(t);
    });

    testWidgets('a part with no clip lights in silence', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_eng(clips: false), 'sl1');
      await r.pump(t);
      await r.wait(t, 2100);
      r.heard.clear();
      await _slide(t, r, last: 2, lift: false);
      expect(r.heard.clips, isEmpty);
      expect(r.session.passed, <int>{0, 1, 2}, reason: 'the parts light all the same');
      await r.done(t);
    });

    testWidgets('a mark under each part: a dot under a letter, a bar under a digraph', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_engDigraph(), 'sl1');
      await r.pump(t);
      final Size sh = t.getSize(find.byKey(const Key('slide-mark-0')));
      final Size o = t.getSize(find.byKey(const Key('slide-mark-1')));
      expect(o.width, o.height, reason: 'a dot under one letter');
      expect(sh.width, greaterThan(sh.height * 2), reason: 'a bar under sh');
      await r.done(t);
    });
  });

  group('the choice', () {
    testWidgets('the right picture is the answer, and the whole plays only after it', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 200);
      r.heard.clear();
      expect(r.heard.clips, isEmpty);
      await t.tap(r.tile('o1'));
      await r.wait(t, 300);
      expect(r.written, <String>['correct:o1']);
      expect(r.heard.clips, contains('vo:eng.pan'), reason: 'after the choice the whole word plays');
      await r.done(t);
    });

    testWidgets('a reversed-word distractor carries its tag; the whole plays after a wrong choice too', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 200);
      r.heard.clear();
      await t.tap(r.tile('o2'));
      await r.wait(t, 300);
      expect(r.attempts.single.misconceptionTag, 'eng.rea.reversed');
      expect(r.written, <String>['incorrect:o2']);
      expect(r.heard.clips, contains('vo:eng.pan'));
      await r.done(t);
    });

    testWidgets('the choice is live from the start: the tap path always works without a slide', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await t.tap(r.tile('o3'));
      await r.wait(t, 300);
      expect(r.attempts.single.misconceptionTag, 'eng.rea.first_guess');
      await r.done(t);
    });
  });

  group('merge (Russian)', () {
    testWidgets(
      'the consonant tile slides to the vowel: the held sound while it moves, the vowel on meeting, the syllable only after the choice',
      (WidgetTester t) async {
        final Rig<BlendSlideSession> r = _rig(_rus(), 'mg1');
        await r.pump(t);
        await r.wait(t, 200);
        r.heard.clear();
        final Offset first = _centre(t, 'merge-first');
        final Offset second = _centre(t, 'merge-second');
        final TestGesture g = await t.startGesture(first);
        await g.moveTo(Offset.lerp(first, second, 0.4)!);
        await t.pump(const Duration(milliseconds: 100));
        expect(r.heard.clips, <String>['vo:rus.snd.m'], reason: 'the held consonant sounds as it moves');
        expect(
          find.byKey(const Key('merge-stretch')),
          findsOneWidget,
          reason: 'the line under a tile that is held',
        );
        await g.moveTo(second);
        await t.pump(const Duration(milliseconds: 100));
        await g.up();
        await r.wait(t, 300);
        expect(r.heard.clips, <String>['vo:rus.snd.m', 'vo:rus.snd.a']);
        expect(r.session.met, isTrue);
        expect(
          r.heard.clips,
          isNot(contains('vo:rus.mg.ma')),
          reason: 'the merged syllable is not played before the choice',
        );
        expect(r.written, isEmpty);
        await t.tap(r.tile('o1'));
        await r.wait(t, 400);
        expect(r.written, <String>['correct:o1']);
        expect(find.byKey(const Key('merge-joined')), findsOneWidget, reason: 'the two tiles join');
        expect(r.heard.clips, contains('vo:rus.mg.ma'));
        await r.done(t);
      },
    );

    testWidgets('a release before the tiles meet sends the tile home', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_rus(), 'mg1');
      await r.pump(t);
      final Offset first = _centre(t, 'merge-first');
      final TestGesture g = await t.startGesture(first);
      await g.moveBy(const Offset(40, 0));
      await t.pump(const Duration(milliseconds: 100));
      await g.up();
      await r.wait(t, 500);
      expect(r.session.mergeT, 0);
      expect(r.session.met, isFalse);
      await r.done(t);
    });

    testWidgets(
      'a stop moves in silence: no sound while it slides, no line under it, and only the vowel sounds on meeting',
      (WidgetTester t) async {
        final Rig<BlendSlideSession> r = _rig(_rus(stop: true), 'mg1');
        await r.pump(t);
        await r.wait(t, 200);
        r.heard.clear();
        await t.tap(find.byKey(const Key('merge-first')));
        await r.wait(t, 200);
        expect(find.byKey(const Key('merge-stretch')), findsNothing, reason: 'this sound cannot be held');
        await r.wait(t, 1800);
        expect(r.heard.clips, <String>['vo:rus.snd.a'], reason: 'only the vowel');
        expect(r.session.met, isTrue);
        await r.done(t);
      },
    );

    testWidgets('a tap on the first tile slides it by itself', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_rus(), 'mg1');
      await r.pump(t);
      await r.wait(t, 200);
      r.heard.clear();
      await t.tap(find.byKey(const Key('merge-first')));
      await r.wait(t, 1800);
      expect(r.session.met, isTrue);
      expect(r.heard.clips, <String>['vo:rus.snd.m', 'vo:rus.snd.a']);
      await r.done(t);
    });
  });

  group('units (Hebrew)', () {
    testWidgets('the knob rests at the right and slides to the left; the parts light right to left', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_heb(), 'un1');
      await r.pump(t);
      await r.wait(t, 200);
      final double knob = _centre(t, 'slide-knob').dx;
      expect(
        knob,
        greaterThan(_centre(t, 'slide-mark-0').dx),
        reason: 'the knob is at the start of the word, the right',
      );
      expect(_centre(t, 'slide-mark-0').dx, greaterThan(_centre(t, 'slide-mark-1').dx));
      expect(_centre(t, 'slide-mark-1').dx, greaterThan(_centre(t, 'slide-mark-2').dx));
      r.heard.clear();
      await _slide(t, r, last: 2);
      expect(r.heard.clips, <String>['vo:heb.u.a', 'vo:heb.u.ba', 'vo:heb.u.alef']);
      await r.done(t);
    });

    testWidgets('a unit of a letter and its marks has a bar under it, a bare letter a dot', (
      WidgetTester t,
    ) async {
      final Rig<BlendSlideSession> r = _rig(_heb(), 'un1');
      await r.pump(t);
      expect(
        t.getSize(find.byKey(const Key('slide-mark-0'))).width,
        greaterThan(t.getSize(find.byKey(const Key('slide-mark-2'))).width),
      );
      await r.done(t);
    });
  });

  group('the hints', () {
    testWidgets(
      'level 1 of a word whose parts have no clip of their own: they light in silence and the stretched whole is the replay',
      (WidgetTester t) async {
        final Rig<BlendSlideSession> r = _rig(_eng(clips: false), 'sl1');
        await r.pump(t);
        await r.wait(t, 2100);
        await t.tap(r.tile('o2'));
        await r.wait(t, 300);
        r.heard.clear();
        await r.wait(t, 5200);
        expect(r.controller.hintShown, 1);
        expect(r.session.passed, <int>{0, 1, 2});
        expect(r.heard.clips, <String>['vo:eng.blend.pan'], reason: 'only the stretched whole is heard');
        await r.done(t);
      },
    );

    testWidgets('level 1: the slide runs by itself, slowly, the parts only', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 2100);
      await t.tap(r.tile('o2'));
      await r.wait(t, 300);
      r.heard.clear();
      await r.wait(t, 4800);
      expect(r.controller.hintShown, 1);
      expect(r.heard.clips.where((String c) => c.startsWith('vo:eng.snd')), <String>[
        'vo:eng.snd.p',
        'vo:eng.snd.a',
        'vo:eng.snd.n',
      ]);
      expect(r.heard.clips, isNot(contains('vo:eng.blend.pan')), reason: 'never the whole at level 1');
      await r.done(t);
    });

    testWidgets('level 2: each part as a token, lit in turn with its sound', (WidgetTester t) async {
      final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
      await r.pump(t);
      await r.wait(t, 2100);
      for (int i = 0; i < 2; i++) {
        await t.tap(r.tile('o2'));
        await r.wait(t, i == 0 ? 6500 : 1300);
      }
      expect(r.controller.hintShown, 2);
      await r.wait(t, 200);
      expect(find.byKey(const Key('slide-card-tokens')), findsOneWidget);
      expect(find.byKey(const Key('slide-token-2')), findsOneWidget);
      await r.done(t);
    });

    testWidgets(
      'level 3: the friend slides, the whole plays and the friend points to the right picture, which keeps its halo',
      (WidgetTester t) async {
        final Rig<BlendSlideSession> r = _rig(_eng(), 'sl1');
        await r.pump(t);
        await r.wait(t, 2100);
        for (int i = 0; i < 3; i++) {
          await t.tap(r.tile(i == 0 ? 'o2' : 'o3'));
          await r.wait(t, i < 2 ? 6500 : 1300);
        }
        expect(r.controller.hintShown, 3);
        expect(r.controller.guided, isTrue);
        r.heard.clear();
        await r.wait(t, 9000);
        expect(r.heard.clips, contains('vo:eng.blend.pan'), reason: 'the whole follows the parts at level 3');
        expect(r.controller.answerShown, isTrue, reason: 'the halo is the last step');
        // Only the right picture is taken.
        final int before = r.attempts.length;
        await t.tap(r.tile('o2'));
        await r.wait(t, 200);
        expect(r.attempts.length, before);
        await t.tap(r.tile('o1'));
        await r.wait(t, 300);
        expect(r.written.last, 'correct:o1');
        await r.done(t);
      },
    );
  });
}
