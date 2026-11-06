// Goldens of LS03 in drum mode on the four boards, on the lesson screen with the companion, the bubble and the trail: the drum with the
// word's picture before the first tap, three beats tapped (three dots, no number), the second hint (one pair of hands for each beat),
// and a Hebrew word (the check mark at the other end). Fixture course, fake clips and the approved pictures; the Hebrew prompts are
// samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls03_drum_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';

LangPack _pack(String course) {
  final LangPack p = LangPack(course)..addPictures(<String>['banana']);
  p.addTag('pa.syll', 'diagnostic');
  p.add(
    drumJson(
      course: course,
      id: 'drum1',
      beats: 3,
      picture: 'banana',
      more: p.tag('pa.syll'),
      fewer: p.tag('pa.syll'),
    ),
  );
  return p;
}

Future<void> _taps(WidgetTester t, int n) async {
  for (int i = 0; i < n; i++) {
    await t.tap(find.byKey(const Key('drum')));
    await waitFor(t, 300);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('the drum and the word\'s picture', (WidgetTester t) async {
        await openLesson(t, _pack('eng'), 'drum1', b.value);
        await shot(t, 'ls03_drum', b.key);
      });

      testWidgets('three beats tapped: three dots', (WidgetTester t) async {
        await openLesson(t, _pack('eng'), 'drum1', b.value);
        await _taps(t, 3);
        await shot(t, 'ls03_taps', b.key, wait: 400);
      });

      testWidgets('hint 2: one pair of hands for each beat', (WidgetTester t) async {
        await openLesson(t, _pack('eng'), 'drum1', b.value);
        await _taps(t, 4);
        await t.tap(find.byKey(const Key('drum-done')));
        await waitFor(t, 1500);
        await _taps(t, 2);
        await t.tap(find.byKey(const Key('drum-done')));
        await shot(t, 'ls03_hands', b.key, wait: 3600);
      });

      testWidgets('a Hebrew word: the check mark at the other end', (WidgetTester t) async {
        await openLesson(t, _pack('heb'), 'drum1', b.value);
        await _taps(t, 2);
        await shot(t, 'ls03_drum_heb', b.key, wait: 400);
      });
    });
  }
}
