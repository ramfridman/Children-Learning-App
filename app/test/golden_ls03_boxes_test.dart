// Goldens of LS03 in boxes mode (L5-3) on the four boards, on the lesson screen with the companion, the bubble and the trail: the count step in English
// (phonemes) and Hebrew (CV units, right to left), the colour step and the stress step in Russian, the which step, a "not yet", the three hints of the count
// step, and the rail of Band A and Band C on the phone SE. Fixture course, fake clips and the approved pictures; the Hebrew prompts are samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls03_boxes_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
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
  ]) {
    p.addTag(slug, 'diagnostic');
  }
  return p;
}

LangPack _eng(List<String> steps) {
  final LangPack p = _pack('eng');
  p.add(
    boxesJson(
      course: 'eng',
      id: 'box1',
      kinds: <String>['c', 'vowel', 'c'],
      steps: steps,
      which: steps.contains('which') ? 3 : null,
      classify: <String, String>{
        'count=more': p.tag('pa.add_vowel'),
        if (steps.contains('which')) 'which=1': p.tag('pa.mirror'),
      },
      mouths: <String?>['mouth_teeth', 'mouth_round', 'mouth_tongue'],
    ),
  );
  return p;
}

LangPack _heb() {
  final LangPack p = _pack('heb');
  p.add(
    boxesJson(
      course: 'heb',
      id: 'box1',
      unit: 'cv',
      picture: 'banana',
      kinds: <String>['cv', 'cv', 'cv'],
      steps: <String>['count'],
    ),
  );
  return p;
}

LangPack _rus({
  required String picture,
  required List<String> kinds,
  required String colours,
  required List<String> steps,
  int? stress,
}) {
  final LangPack p = _pack('rus');
  p.pack.doc('skill.RUS-A-02.json')['stress'] = true;
  p.add(
    boxesJson(
      course: 'rus',
      id: 'box1',
      picture: picture,
      kinds: kinds,
      steps: steps,
      colours: steps.contains('colour') ? colours : null,
      stress: stress,
      classify: <String, String>{
        if (steps.contains('colour')) ...<String, String>{
          'colour=vowel_cons': p.tag('pa.vowel_cons'),
          'colour=hard_soft': p.tag('pa.hard_soft'),
        },
        if (stress != null) 'stress=4': p.tag('pa.stress_last'),
      },
    ),
  );
  return p;
}

Future<void> _lay(WidgetTester t, int n) async {
  for (int i = 0; i < n; i++) {
    await t.tap(find.byKey(const Key('box-bowl')));
    await waitFor(t, 200);
  }
}

Future<void> _countRight(WidgetTester t, int n) async {
  await _lay(t, n);
  await t.tap(find.byKey(const Key('box-done')));
  await waitFor(t, 700 * n + 600);
}

Future<void> _stamp(WidgetTester t, String stamp, List<int> chips) async {
  await t.tap(find.byKey(Key('stamp-$stamp')));
  await waitFor(t, 200);
  for (final int i in chips) {
    await t.tap(find.byKey(Key('box-place-$i')));
    await waitFor(t, 200);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('count, English phonemes: two counters and the dashed next place', (WidgetTester t) async {
        await openLesson(t, _eng(<String>['count', 'which']), 'box1', b.value);
        await _lay(t, 2);
        await shot(t, 'ls03b_count_eng', b.key, wait: 400);
      });

      testWidgets('count, Hebrew CV units: the rail runs from the right', (WidgetTester t) async {
        await openLesson(t, _heb(), 'box1', b.value);
        await _lay(t, 2);
        await shot(t, 'ls03b_count_heb', b.key, wait: 400);
      });

      testWidgets('count, before the first counter: the bowl, "that\'s all" and an empty rail', (
        WidgetTester t,
      ) async {
        await openLesson(t, _eng(<String>['count', 'which']), 'box1', b.value);
        await shot(t, 'ls03b_rest_eng', b.key);
      });

      testWidgets('colour, Russian: a stamp chosen, one chip coloured', (WidgetTester t) async {
        final LangPack p = _rus(
          picture: 'whale',
          kinds: <String>['hard', 'vowel', 'hard'],
          colours: 'brb',
          steps: <String>['count', 'colour'],
        );
        await openLesson(t, p, 'box1', b.value);
        await _countRight(t, 3);
        await _stamp(t, 'b', <int>[0]);
        await shot(t, 'ls03b_colour_rus', b.key, wait: 400);
      });

      testWidgets(
        'stress, Russian: the vowels raised, the consonants at rest, the sign over the stressed one',
        (WidgetTester t) async {
          final LangPack p = _rus(
            picture: 'fish',
            kinds: <String>['hard', 'vowel', 'hard', 'vowel'],
            colours: 'brbr',
            steps: <String>['stress'],
            stress: 2,
          );
          await openLesson(t, p, 'box1', b.value);
          await shot(t, 'ls03b_stress_rus', b.key);
          await t.tap(find.byKey(const Key('box-place-3')));
          await shot(t, 'ls03b_stress_sign_rus', b.key, wait: 300);
        },
      );

      testWidgets('which, English: the sound to find and three counters', (WidgetTester t) async {
        await openLesson(t, _eng(<String>['count', 'which']), 'box1', b.value);
        await _countRight(t, 3);
        await shot(t, 'ls03b_which_eng', b.key, wait: 400);
      });

      testWidgets('not yet: one counter too many, the rail wobbles and the counters go home', (
        WidgetTester t,
      ) async {
        await openLesson(t, _eng(<String>['count']), 'box1', b.value);
        await _lay(t, 4);
        await t.tap(find.byKey(const Key('box-done')));
        await shot(t, 'ls03b_notyet_eng', b.key, wait: 200);
      });

      testWidgets('hint 2: the mouth of each sound as its card lights', (WidgetTester t) async {
        await openLesson(t, _eng(<String>['count']), 'box1', b.value);
        for (int i = 0; i < 2; i++) {
          await _lay(t, 4);
          await t.tap(find.byKey(const Key('box-done')));
          await waitFor(t, i == 0 ? 1500 : 1150);
        }
        await shot(t, 'ls03b_hint2_eng', b.key, wait: 100);
      });

      testWidgets('hint 3: the friend\'s hand lays a counter', (WidgetTester t) async {
        await openLesson(t, _eng(<String>['count']), 'box1', b.value);
        for (int i = 0; i < 3; i++) {
          await _lay(t, 4);
          await t.tap(find.byKey(const Key('box-done')));
          await waitFor(t, i < 2 ? 1500 : 1150);
        }
        await shot(t, 'ls03b_hint3_eng', b.key, wait: 700);
      });
    });
  }

  // The rail of the other two bands, on the smallest phone.
  testWidgets('Band A on the phone SE: a rail of five, bigger places', (WidgetTester t) async {
    await openLesson(t, _eng(<String>['count']), 'box1', boards['phoneSE']!, band: 0);
    await _lay(t, 3);
    await shot(t, 'ls03b_banda_eng', 'phoneSE', wait: 400);
  });

  testWidgets('Band C on the phone SE: a rail of seven', (WidgetTester t) async {
    await openLesson(t, _eng(<String>['count']), 'box1', boards['phoneSE']!, band: 2);
    await _lay(t, 4);
    await shot(t, 'ls03b_bandc_eng', 'phoneSE', wait: 400);
  });
}
