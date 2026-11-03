// Goldens of LS11 on the four boards, on the lesson screen with the companion, the bubble and the trail: the glowing parts of a picture,
// an action button with the friend doing it, a thing chosen to be taken to the target, a Hebrew command whose thing goes to a place,
// and the close-up card of the second hint. Fixture course, fake clips and the approved pictures; the Hebrew prompts are samples
// (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls11_listen_do_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>[
  'teddy',
  'table',
  'plate',
  'apple',
  'banana',
  'bread',
  'ball',
  'drum',
  'kite',
];

LangPack _pack(String course, String mode) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  switch (mode) {
    case 'hotspots':
      p.add(
        listenDoJson(
          course: course,
          id: 'doit',
          mode: mode,
          options: <Map<String, Object?>>[
            partOption('o1', at(0.30, 0.05, 0.4, 0.3), label: 'head'),
            partOption('o2', at(0.30, 0.45, 0.4, 0.25), tag: p.tag('lis.sem'), label: 'tummy'),
            partOption('o3', at(0.25, 0.78, 0.5, 0.18), tag: p.tag('lis.guess'), label: 'feet'),
          ],
          correct: 'o1',
        ),
      );
    case 'buttons':
      p.add(
        listenDoJson(
          course: course,
          id: 'doit',
          mode: mode,
          options: <Map<String, Object?>>[
            pictureOption('o1', 'ball'),
            pictureOption('o2', 'drum', tag: p.tag('lis.sem')),
            pictureOption('o3', 'kite', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
    case 'drag':
      p.add(
        listenDoJson(
          course: course,
          id: 'doit',
          mode: mode,
          picture: 'table',
          target: <String, Object?>{'at': at(0.58, 0.3, 0.38, 0.38), 'sprite': 'asset:plate'},
          options: <Map<String, Object?>>[
            thingOption('o1', 'apple', at(0.02, 0.05, 0.26, 0.26)),
            thingOption('o2', 'banana', at(0.02, 0.37, 0.26, 0.26), tag: p.tag('lis.sem')),
            thingOption('o3', 'bread', at(0.02, 0.69, 0.26, 0.26), tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
    default:
      p.add(
        listenDoJson(
          course: course,
          id: 'doit',
          mode: 'place',
          picture: 'table',
          thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.22, 0.22)},
          options: <Map<String, Object?>>[
            partOption('o1', at(0.4, 0.04, 0.5, 0.26), label: 'on'),
            partOption('o2', at(0.4, 0.7, 0.5, 0.26), tag: p.tag('lis.sem'), label: 'under'),
            partOption('o3', at(0.72, 0.36, 0.25, 0.26), tag: p.tag('lis.guess'), label: 'next to'),
          ],
          correct: 'o1',
        ),
      );
  }
  return p;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('the glowing parts of a picture', (WidgetTester t) async {
        await openLesson(t, _pack('eng', 'hotspots'), 'doit', b.value);
        await shot(t, 'ls11_hotspots', b.key);
      });

      testWidgets('an action button, and the friend does it', (WidgetTester t) async {
        await openLesson(t, _pack('eng', 'buttons'), 'doit', b.value);
        await t.tap(find.byKey(const Key('tile-o2')));
        await shot(t, 'ls11_buttons', b.key, wait: 150);
      });

      testWidgets('a thing chosen to be taken to the target', (WidgetTester t) async {
        await openLesson(t, _pack('eng', 'drag'), 'doit', b.value);
        await t.tap(find.byKey(const Key('do-piece-o1')));
        await shot(t, 'ls11_drag', b.key, wait: 200);
      });

      testWidgets('a Hebrew command: the thing goes to a place', (WidgetTester t) async {
        await openLesson(t, _pack('heb', 'place'), 'doit', b.value);
        await shot(t, 'ls11_place_heb', b.key);
      });

      testWidgets('hint 2: what the command names, close up', (WidgetTester t) async {
        await openLesson(t, _pack('eng', 'hotspots'), 'doit', b.value);
        await t.tap(find.byKey(const Key('do-hot-o2')));
        await waitFor(t, 1500);
        await t.tap(find.byKey(const Key('do-hot-o3')));
        await shot(t, 'ls11_closeup', b.key, wait: 1600);
      });
    });
  }
}
