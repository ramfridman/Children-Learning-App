// Goldens of LS04 blend slide (L5-5) on the four boards, on the lesson screen with the companion, the bubble and the trail: English graphemes at rest, mid-slide
// (the part that sounds in its column) and after the choice; a digraph with one bar under it; the Russian merge at rest, held mid-slide and joined after the
// choice; the Hebrew units at rest and the level-2 and level-3 hints. Fixture course, fake clips and the approved pictures; the Hebrew prompts are samples.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls04_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/l5_content.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

const List<String> _pictures = <String>['pot', 'top', 'pig', 'cat', 'sun'];

LangPack _eng(String text, List<String> parts) {
  final LangPack p = LangPack('eng')..addPictures(_pictures);
  p.addTag('rea.reversed', 'diagnostic');
  p.addTag('rea.first_guess', 'diagnostic');
  p.add(
    blendJson(
      course: 'eng',
      id: 'sl1',
      text: text,
      parts: <({String text, String? clip, bool stretch})>[
        for (final String s in parts)
          bpart(s, clip: 'vo:eng.snd.$s', stretch: !<String>{'p', 't'}.contains(s)),
      ],
      whole: 'vo:eng.$text',
      options: <Map<String, Object?>>[
        slideOption('o1', picture: 'pot'),
        slideOption('o2', picture: 'top', tag: p.tag('rea.reversed')),
        slideOption('o3', picture: 'pig', tag: p.tag('rea.first_guess')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

LangPack _rus() {
  final LangPack p = LangPack('rus')..addPictures(_pictures);
  p.addTag('rea.letter_name', 'diagnostic');
  p.addTag('rea.reversed', 'diagnostic');
  p.add(
    blendJson(
      course: 'rus',
      id: 'mg1',
      text: 'ма',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('м', clip: 'vo:rus.snd.m'),
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

/// A decoding item of the Hebrew course: a text stem whose level 2 opens the wheel and level 3 the slide (docs/milestones/L5.md section 5.9).
LangPack _hebStem() {
  final LangPack p = LangPack('heb')..addPictures(_pictures);
  p.addTag('dec.vowel_skip', 'diagnostic');
  p.addTag('dec.letter_mix', 'diagnostic');
  final Map<String, Object?> a = stemJson(
    course: 'heb',
    id: 'stm1',
    stem: 'אַבָּא',
    clip: 'vo:heb.stm1.stem',
    options: <Map<String, Object?>>[
      pictureOption('o1', 'cat'),
      pictureOption('o2', 'sun', tag: p.tag('dec.vowel_skip')),
      pictureOption('o3', 'pig', tag: p.tag('dec.letter_mix')),
    ],
    correct: 'o1',
  );
  borrow(a, 2, <String, Object?>{'template': 'change_part'});
  borrow(a, 3, <String, Object?>{'template': 'blend_slide'});
  p.add(a);
  return p;
}

Future<void> _slideTo(WidgetTester t, int mark) async {
  await waitFor(t, 2100);
  final Offset knob = t.getCenter(find.byKey(const Key('slide-knob')));
  final TestGesture g = await t.startGesture(knob);
  final Offset to = t.getCenter(find.byKey(Key('slide-mark-$mark')));
  for (int i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(knob, to, i / 10)!);
    await t.pump(const Duration(milliseconds: 40));
  }
  addTearDown(g.up);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('English graphemes at rest: pot, the knob at the start', (WidgetTester t) async {
        await openLesson(t, _eng('pot', <String>['p', 'o', 't']), 'sl1', b.value);
        await shot(t, 'ls04_graphemes_rest_eng', b.key);
      });

      testWidgets('English graphemes mid-slide: the o sounding in its column', (WidgetTester t) async {
        await openLesson(t, _eng('pot', <String>['p', 'o', 't']), 'sl1', b.value);
        await _slideTo(t, 1);
        await shot(t, 'ls04_graphemes_slide_eng', b.key, wait: 100);
      });

      testWidgets('a digraph has one bar under it: shop', (WidgetTester t) async {
        await openLesson(t, _eng('shop', <String>['sh', 'o', 'p']), 'sl1', b.value);
        await _slideTo(t, 0);
        await shot(t, 'ls04_digraph_eng', b.key, wait: 100);
      });

      testWidgets('after the choice: the whole word, the right picture kept', (WidgetTester t) async {
        await openLesson(t, _eng('pot', <String>['p', 'o', 't']), 'sl1', b.value);
        await t.tap(find.byKey(const Key('tile-o1')));
        await shot(t, 'ls04_graphemes_chosen_eng', b.key, wait: 200);
      });

      testWidgets('merge at rest: the consonant tile, the track, the vowel tile and three sound buttons', (
        WidgetTester t,
      ) async {
        await openLesson(t, _rus(), 'mg1', b.value);
        await shot(t, 'ls04_merge_rest_rus', b.key);
      });

      testWidgets('merge mid-slide: the held m with its line under it', (WidgetTester t) async {
        await openLesson(t, _rus(), 'mg1', b.value);
        await waitFor(t, 2100);
        final Offset first = t.getCenter(find.byKey(const Key('merge-first')));
        final Offset second = t.getCenter(find.byKey(const Key('merge-second')));
        final TestGesture g = await t.startGesture(first);
        for (int i = 1; i <= 6; i++) {
          await g.moveTo(Offset.lerp(first, second, i * 0.07)!);
          await t.pump(const Duration(milliseconds: 40));
        }
        addTearDown(g.up);
        await shot(t, 'ls04_merge_slide_rus', b.key, wait: 100);
      });

      testWidgets('merge after the choice: the two tiles joined', (WidgetTester t) async {
        await openLesson(t, _rus(), 'mg1', b.value);
        await t.tap(find.byKey(const Key('tile-o1')));
        await shot(t, 'ls04_merge_joined_rus', b.key, wait: 600);
      });

      testWidgets('Hebrew units: the knob at the right, a mark under each unit', (WidgetTester t) async {
        await openLesson(t, _heb(), 'un1', b.value);
        await _slideTo(t, 1);
        await shot(t, 'ls04_units_heb', b.key, wait: 100);
      });

      testWidgets('a decoding item, hint 2: the small wheel on the unit missed', (WidgetTester t) async {
        await openLesson(t, _hebStem(), 'stm1', b.value);
        await t.tap(find.byKey(const Key('tile-o2')));
        await waitFor(t, 1300);
        await t.tap(find.byKey(const Key('tile-o2')));
        await shot(t, 'ls04_stem_wheel_heb', b.key, wait: 1400);
      });

      testWidgets('a decoding item, hint 3: the friend slides the word, unit by unit', (
        WidgetTester t,
      ) async {
        await openLesson(t, _hebStem(), 'stm1', b.value);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('tile-o2')));
          await waitFor(t, 1300);
        }
        await shot(t, 'ls04_stem_slide_heb', b.key, wait: 900);
      });
    });
  }
}
