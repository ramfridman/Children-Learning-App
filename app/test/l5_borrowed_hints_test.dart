// The hints that borrow another template's screen (docs/milestones/L5.md section 5.9, layout docs/design/l5-templates.md sections 4.2 and 5.3): a Hebrew
// decoding item's level 2 is the small wheel on the unit the child missed and its level 3 the slide of the word; a Russian one's level 2 is the compact strip;
// an English one's level 2 the slide with each sound lit. The options stay live while a screen is borrowed, and nothing is lit or named before level 3.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/borrowed_screens.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/ls01_tap_session.dart';

import 'support/l4_rig.dart';
import 'support/l5_content.dart';
import 'support/l5_wheel.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

const List<String> _pictures = <String>['cat', 'sun', 'fish'];

const String _ma = 'מָ';
const String _la = 'לָ';

LangPack _heb({bool textOptions = false, bool screens = true}) {
  final LangPack p = LangPack('heb')..addPictures(_pictures);
  p.addTag('dec.vowel_skip', 'diagnostic');
  p.addTag('dec.letter_mix', 'diagnostic');
  final Map<String, Object?> a = stemJson(
    course: 'heb',
    id: 'stm1',
    stem: _ma,
    clip: 'vo:heb.stm1.stem',
    options: textOptions
        ? <Map<String, Object?>>[
            textOption('o1', _ma, clip: 'vo:heb.u.ma'),
            textOption('o2', _la, tag: p.tag('dec.letter_mix'), clip: 'vo:heb.u.la'),
            textOption('o3', 'מ', tag: p.tag('dec.vowel_skip'), clip: 'vo:heb.s.mem'),
          ]
        : <Map<String, Object?>>[
            pictureOption('o1', 'cat'),
            pictureOption('o2', 'sun', tag: p.tag('dec.vowel_skip')),
            pictureOption('o3', 'fish', tag: p.tag('dec.letter_mix')),
          ],
    correct: 'o1',
  );
  if (screens) {
    borrow(a, 2, <String, Object?>{'template': 'change_part'});
    borrow(a, 3, <String, Object?>{'template': 'blend_slide'});
  }
  p.add(a);
  return p;
}

Rig<Ls01TapSession> _rig(LangPack p, {String id = 'stm1'}) =>
    Rig<Ls01TapSession>(p, id, (LessonController c, Activity a) => Ls01TapSession(c, a as TapAnswerActivity));

Future<void> _wrongTwice(WidgetTester t, Rig<Ls01TapSession> r, String id) async {
  for (int i = 0; i < 2; i++) {
    await t.tap(r.tile(id));
    await r.wait(t, 1300);
  }
}

void main() {
  group('Hebrew level 2: the small wheel on the unit missed', () {
    testWidgets(
      'a unit read with no sign (VOWEL-SKIP): the signs turn, from none to qamats, under the target\'s letter',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_heb(textOptions: true));
        await r.pump(t);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1300);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 2);
        expect(find.byKey(const Key('stem-borrowed')), findsOneWidget);
        expect(find.byKey(const Key('mini-wheel')), findsOneWidget);
        final WheelPlan plan = r.session.borrowed! as WheelPlan;
        expect(plan.ringIsSigns, isTrue);
        expect(plan.ring, <String>['', qamats]);
        expect(plan.units, <String>['מ', _ma]);
        expect(plan.path, <int>[0, 1], reason: 'from the unit she chose to the target');
        await r.done(t);
      },
    );

    testWidgets(
      'a unit with another letter (LETTER-MIX): the letters turn, from hers to the target\'s, under the target\'s sign',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_heb(textOptions: true));
        await r.pump(t);
        await _wrongTwice(t, r, 'o2');
        final WheelPlan plan = r.session.borrowed! as WheelPlan;
        expect(plan.ringIsSigns, isFalse);
        expect(plan.ring, <String>['ל', 'מ']);
        expect(plan.units, <String>[_la, _ma]);
        await r.done(t);
      },
    );

    testWidgets(
      'the friend turns it: each position is heard, the stem is read at the target, and the stage comes back',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_heb(textOptions: true));
        await r.pump(t);
        await _wrongTwice(t, r, 'o2');
        expect(r.session.borrowedStep, 0);
        await r.wait(t, 1400);
        expect(r.session.borrowedStep, 1);
        await r.wait(t, 2500);
        expect(find.byKey(const Key('stem-borrowed')), findsNothing, reason: 'the stem is back');
        await r.done(t);
      },
    );

    testWidgets('the options stay live: a touch on a picture answers, and nothing is lit before level 3', (
      WidgetTester t,
    ) async {
      final Rig<Ls01TapSession> r = _rig(_heb());
      await r.pump(t);
      await _wrongTwice(t, r, 'o2');
      expect(find.byKey(const Key('stem-borrowed')), findsOneWidget);
      expect(r.controller.answerShown, isFalse);
      await t.tap(r.tile('o1'));
      await r.wait(t, 300);
      expect(r.written.last, 'correct:o1');
      await r.done(t);
    });

    testWidgets('a hint with no screen is as it was: the stem in pieces', (WidgetTester t) async {
      final Rig<Ls01TapSession> r = _rig(_heb(screens: false));
      await r.pump(t);
      await _wrongTwice(t, r, 'o2');
      expect(find.byKey(const Key('stem-borrowed')), findsNothing);
      expect(r.session.splitStem, isTrue);
      await r.done(t);
    });
  });

  group('Hebrew level 3: the slide', () {
    testWidgets(
      'the page becomes the slide page, the friend slides, the whole is read and the bars join; then the hand points to the right picture',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_heb(textOptions: true));
        await r.pump(t);
        for (int i = 0; i < 3; i++) {
          await t.tap(r.tile('o2'));
          await r.wait(t, 1300);
        }
        expect(r.controller.hintShown, 3);
        await r.wait(t, 500);
        expect(find.byKey(const Key('stem-slide')), findsOneWidget);
        r.heard.clear();
        await r.wait(t, 3000);
        expect(
          find.byKey(const Key('slide-joined-bar')),
          findsOneWidget,
          reason: 'the bars joined into one under the word',
        );
        expect(r.heard.clips, contains('vo:heb.stm1.stem'), reason: 'the whole is the stem\'s own clip');
        await r.wait(t, 3000);
        expect(r.controller.answerShown, isTrue, reason: 'the halo is the last step');
        await r.done(t);
      },
    );
  });

  group('Russian level 2: the compact strip', () {
    testWidgets('the friend slides along the vowels under the consonant and each is heard', (
      WidgetTester t,
    ) async {
      final LangPack p = LangPack('rus')..addPictures(_pictures);
      p.addTag('dec.hard_soft', 'diagnostic');
      p.addTag('dec.yi', 'diagnostic');
      final Map<String, Object?> a = stemJson(
        course: 'rus',
        id: 'stm1',
        stem: 'ма',
        clip: 'vo:rus.stm1.stem',
        options: <Map<String, Object?>>[
          pictureOption('o1', 'cat'),
          pictureOption('o2', 'sun', tag: p.tag('dec.hard_soft')),
          pictureOption('o3', 'fish', tag: p.tag('dec.yi')),
        ],
        correct: 'o1',
      );
      borrow(a, 2, <String, Object?>{
        'template': 'change_part',
        'frame': <String, Object?>{'text': 'м_', 'slots': 1},
        'parts': <Object?>[
          <String, Object?>{'id': 'p1', 'slot': 0, 'text': 'а'},
          <String, Object?>{'id': 'p2', 'slot': 0, 'text': 'о'},
          <String, Object?>{'id': 'p3', 'slot': 0, 'text': 'у'},
        ],
        'results': <Object?>[
          <String, Object?>{
            'parts': <String>['p1'],
            'text': 'ма',
            'clip': 'vo:rus.sy.ma',
          },
          <String, Object?>{
            'parts': <String>['p2'],
            'text': 'мо',
            'clip': 'vo:rus.sy.mo',
          },
          <String, Object?>{
            'parts': <String>['p3'],
            'text': 'му',
            'clip': 'vo:rus.sy.mu',
          },
        ],
      });
      p.add(a);
      final Rig<Ls01TapSession> r = _rig(p);
      await r.pump(t);
      await t.tap(r.tile('o2'));
      await r.wait(t, 1300);
      r.heard.clear();
      await t.tap(r.tile('o2'));
      await r.wait(t, 1200);
      expect(find.byKey(const Key('mini-strip')), findsOneWidget);
      await r.wait(t, 3600);
      expect(r.heard.clips.where((String c) => c.startsWith('vo:rus.sy')), <String>['vo:rus.sy.ma']);
      await r.done(t);
    });
  });

  group('English level 2: the slide with each sound lit', () {
    testWidgets(
      'a stem whose level 2 names the slide lights its letters in turn and then the stem comes back',
      (WidgetTester t) async {
        final LangPack p = LangPack('eng')..addPictures(_pictures);
        p.addTag('rea.reversed', 'diagnostic');
        p.addTag('rea.first_guess', 'diagnostic');
        final Map<String, Object?> a = stemJson(
          course: 'eng',
          id: 'stm1',
          stem: 'pan',
          clip: 'vo:eng.stm1.stem',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'cat'),
            pictureOption('o2', 'sun', tag: p.tag('rea.reversed')),
            pictureOption('o3', 'fish', tag: p.tag('rea.first_guess')),
          ],
          correct: 'o1',
        );
        borrow(a, 2, <String, Object?>{'template': 'blend_slide'});
        p.add(a);
        final Rig<Ls01TapSession> r = _rig(p);
        await r.pump(t);
        await _wrongTwice(t, r, 'o2');
        await r.wait(t, 200);
        expect(find.byKey(const Key('stem-slide')), findsOneWidget);
        expect(r.session.slidePlan!.parts.map((BlendPart x) => x.text).toList(), <String>['p', 'a', 'n']);
        expect(r.session.slideLit, isNotNull);
        await r.wait(t, 4000);
        expect(find.byKey(const Key('stem-slide')), findsNothing, reason: 'the stem is back');
        await r.done(t);
      },
    );
  });

  group('the plans', () {
    test('a Hebrew unit splits into its letter, with its dagesh or shin dot, and its sign', () {
      final ({String letter, String sign})? ba = splitUnit('בָּ');
      expect(ba!.letter, 'בּ');
      expect(ba.sign, qamats);
      final ({String letter, String sign})? sha = splitUnit('שָׁ');
      expect(sha!.letter, 'שׁ');
      expect(sha.sign, qamats);
      expect(splitUnit('מ')!.sign, isEmpty);
      expect(splitUnit('a'), isNull);
      expect(firstUnit('מָלָה'), 'מָ');
    });

    test('a word is split into the units a child reads: a final he after a qamats is one unit with its letter; English digraphs are one part', () {
      List<String> units(String text, String course) => <String>[
        for (final BlendPart p in splitUnits(text, course)) p.text,
      ];
      expect(units('אַבָּא', 'heb'), <String>['אַ', 'בָּ', 'א']);
      expect(units('בָּמָה', 'heb'), <String>['בָּ', 'מָה']);
      expect(units('shop', 'eng'), <String>['sh', 'o', 'p']);
      expect(units('pan', 'eng'), <String>['p', 'a', 'n']);
      expect(units('ма', 'rus'), <String>['м', 'а']);
    });
  });
}
