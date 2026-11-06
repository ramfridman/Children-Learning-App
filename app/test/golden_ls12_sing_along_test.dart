// Goldens of LS12 on the four boards, on the lesson screen with the companion, the bubble and the trail: a chant with the pictures of a
// line lit, a Hebrew chant laid out from the right, the question at the gap of a rhyme on picture tiles, and the second hint (the end word
// before each option, the option lit). Fixture course, fake clips and the approved pictures; the Hebrew prompts are samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls12_sing_along_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>['cat', 'dog', 'duck', 'rabbit', 'cup'];

LangPack _chant(String course) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(
    singJson(
      course: course,
      id: 'chant',
      pictures: <Map<String, Object?>>[
        songPicture('cat', clip: 'vo:$course.w.cat'),
        songPicture('dog', clip: 'vo:$course.w.dog'),
        songPicture('duck', clip: 'vo:$course.w.duck'),
      ],
      lines: <Map<String, Object?>>[
        for (int i = 0; i < 6; i++)
          <String, Object?>{
            'clips': <String>['vo:$course.ch.$i'],
            'lights': <int>[i % 3],
          },
      ],
    ),
  );
  return p;
}

LangPack _rhyme(String course) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(
    singJson(
      course: course,
      id: 'rhyme',
      pictures: <Map<String, Object?>>[songPicture('rabbit'), songPicture('cat')],
      verse: <String, Object?>{
        'whole': <String>['vo:$course.v1.whole'],
        'open': <String>['vo:$course.v1.open'],
        'full': <String>['vo:$course.v1.full'],
        'cue': <String>['vo:$course.v1.e'],
      },
      options: <Map<String, Object?>>[
        pictureOption('o1', 'rabbit', clip: 'vo:$course.w.rabbit'),
        pictureOption('o2', 'cup', tag: p.tag('lis.guess'), clip: 'vo:$course.w.cup'),
        pictureOption('o3', 'cat', tag: p.tag('lis.sem'), clip: 'vo:$course.w.cat'),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('a chant, the pictures of a line lit', (WidgetTester t) async {
        await openLesson(t, _chant('eng'), 'chant', b.value, settle: 1200);
        await shot(t, 'ls12_chant', b.key, wait: 100);
      });

      testWidgets('a Hebrew chant is laid out from the right', (WidgetTester t) async {
        await openLesson(t, _chant('heb'), 'chant', b.value, settle: 1200);
        await shot(t, 'ls12_chant_heb', b.key, wait: 100);
      });

      testWidgets('the gap of a rhyme: the choices', (WidgetTester t) async {
        await openLesson(t, _rhyme('heb'), 'rhyme', b.value);
        await shot(t, 'ls12_rhyme', b.key);
      });

      testWidgets('hint 2: the end word before each option', (WidgetTester t) async {
        await openLesson(t, _rhyme('heb'), 'rhyme', b.value);
        await t.tap(find.byKey(const Key('tile-o2')));
        await waitFor(t, 1500);
        await t.tap(find.byKey(const Key('tile-o3')));
        await shot(t, 'ls12_ends', b.key, wait: 1250);
      });
    });
  }
}
