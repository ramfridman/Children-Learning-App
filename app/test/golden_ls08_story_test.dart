// Goldens of LS08 on the four boards, on the lesson screen with the companion, the bubble and the trail: a page of a story with a
// touched thing ringed, the question of a pause on picture tiles with their speakers, the hint that lays the pages so far in a row,
// and a Hebrew story, turned toward the left. Fixture course, fake clips and the approved pictures; the Hebrew prompts are samples
// (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls08_story_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>['ball_red', 'cat', 'duck', 'frog', 'dog'];

LangPack _pack(String course, {bool dialogic = true}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(
    storyJson(
      course: course,
      id: 'bounce',
      pages: <Map<String, Object?>>[
        for (final (int i, String pic) in _pictures.indexed)
          storyPage(
            pic,
            <String>['vo:$course.st.p${i + 1}'],
            words: <Map<String, Object?>>[hotWord('vo:$course.w.$pic', x: 0.2, y: 0.2, w: 0.6, h: 0.6)],
          ),
      ],
      pauseAfter: dialogic ? 1 : null,
      options: dialogic
          ? <Map<String, Object?>>[
              pictureOption('o1', 'duck', clip: 'vo:$course.w.duck'),
              pictureOption('o2', 'cat', tag: p.tag('lis.sem'), clip: 'vo:$course.w.cat'),
              pictureOption('o3', 'frog', tag: p.tag('lis.guess'), clip: 'vo:$course.w.frog'),
            ]
          : null,
      correct: dialogic ? 'o1' : null,
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
      testWidgets('a page of a story, a thing in the picture touched', (WidgetTester t) async {
        await openLesson(t, _pack('eng', dialogic: false), 'bounce', b.value);
        await t.tap(find.byKey(const Key('story-turn')));
        await waitFor(t, 400);
        await t.tap(find.byKey(const Key('story-word-0')));
        await shot(t, 'ls08_page', b.key, wait: 100);
      });

      testWidgets('the question of the pause, on picture tiles', (WidgetTester t) async {
        await openLesson(t, _pack('eng'), 'bounce', b.value);
        await t.tap(find.byKey(const Key('story-turn')));
        await waitFor(t, 400);
        await t.tap(find.byKey(const Key('story-turn')));
        await shot(t, 'ls08_question', b.key, wait: 1500);
      });

      testWidgets('hint 2: the pages so far in a row', (WidgetTester t) async {
        await openLesson(t, _pack('eng'), 'bounce', b.value);
        await t.tap(find.byKey(const Key('story-turn')));
        await waitFor(t, 400);
        await t.tap(find.byKey(const Key('story-turn')));
        await waitFor(t, 1500);
        await t.tap(find.byKey(const Key('tile-o2')));
        await waitFor(t, 1500);
        await t.tap(find.byKey(const Key('tile-o3')));
        await shot(t, 'ls08_row', b.key, wait: 2200);
      });

      testWidgets('a Hebrew story is turned toward the left', (WidgetTester t) async {
        await openLesson(t, _pack('heb', dialogic: false), 'bounce', b.value);
        await shot(t, 'ls08_heb_page', b.key, wait: 600);
      });
    });
  }
}
