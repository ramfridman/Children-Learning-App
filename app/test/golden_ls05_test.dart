// Goldens of LS05 change one part (L5-4) on the four boards, on the lesson screen with the companion, the bubble and the trail: the Hebrew wheel in explore
// (the S1 wheel, seven letters and three signs) and in make (B-19.4), the Russian strip in explore (kot and kit with their pictures) and in make (B-21 li),
// a unit with no sound, and the hints of a make item. Fixture course, fake clips and the approved pictures; the Hebrew prompts are samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls05_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/l5_wheel.dart';
import 'support/language_content.dart';

LangPack _heb() {
  final LangPack p = LangPack('heb')..addPictures(<String>['cat', 'whale', 'fish']);
  p.addTag('dec.letter_mix', 'diagnostic');
  p.addTag('dec.vowel_skip', 'diagnostic');
  p.add(s1Explore());
  p.add(s1Make(p));
  return p;
}

LangPack _rus() {
  final LangPack p = LangPack('rus')..addPictures(<String>['cat', 'whale', 'fish']);
  p.addTag('dec.yi', 'diagnostic');
  p.addTag('dec.hard_soft', 'diagnostic');
  p.add(stripExplore());
  p.add(stripMake(p));
  return p;
}

Future<void> _tap(WidgetTester t, String key, {int wait = 500}) async {
  await t.tap(find.byKey(Key(key)));
  await waitFor(t, wait);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('the Hebrew wheel, explore: lamed with qamats', (WidgetTester t) async {
        await openLesson(t, _heb(), 'whl0', b.value);
        await _tap(t, 'wheel-bead-1');
        await shot(t, 'ls05_wheel_explore_heb', b.key, wait: 300);
      });

      testWidgets('the Hebrew wheel, explore: a bare lamed (no sign), the signs row', (WidgetTester t) async {
        await openLesson(t, _heb(), 'whl0', b.value);
        await _tap(t, 'wheel-bead-3');
        await _tap(t, 'wheel-sign-2');
        await shot(t, 'ls05_wheel_nosign_heb', b.key, wait: 300);
      });

      testWidgets('the Hebrew wheel, explore: an alef with no sign makes no sound and the hub swings', (
        WidgetTester t,
      ) async {
        await openLesson(t, _heb(), 'whl0', b.value);
        await _tap(t, 'wheel-bead-4');
        await t.tap(find.byKey(const Key('wheel-sign-2')));
        await shot(t, 'ls05_wheel_silent_heb', b.key, wait: 100);
      });

      testWidgets('the Hebrew wheel, make: the target and "that\'s it"', (WidgetTester t) async {
        await openLesson(t, _heb(), 'whl1', b.value);
        await shot(t, 'ls05_wheel_make_heb', b.key);
      });

      testWidgets('the Hebrew wheel, make: the target made, the hub lit', (WidgetTester t) async {
        await openLesson(t, _heb(), 'whl1', b.value);
        await _tap(t, 'wheel-bead-0');
        await _tap(t, 'wheel-sign-0');
        await t.tap(find.byKey(const Key('change-done')));
        await shot(t, 'ls05_wheel_made_heb', b.key, wait: 300);
      });

      testWidgets('the Hebrew wheel, make, hint 2: the key word in a card', (WidgetTester t) async {
        await openLesson(t, _heb(), 'whl1', b.value);
        for (int i = 0; i < 2; i++) {
          await t.tap(find.byKey(const Key('change-done')));
          await waitFor(t, 1300);
        }
        await shot(t, 'ls05_wheel_hint2_heb', b.key, wait: 200);
      });

      testWidgets('the Hebrew wheel, make, hint 3: the friend turns it', (WidgetTester t) async {
        await openLesson(t, _heb(), 'whl1', b.value);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('change-done')));
          await waitFor(t, i < 2 ? 1300 : 1500);
        }
        await shot(t, 'ls05_wheel_hint3_heb', b.key, wait: 500);
      });

      testWidgets('the Russian strip, explore: kit, with its picture', (WidgetTester t) async {
        await openLesson(t, _rus(), 'str0', b.value);
        await _tap(t, 'strip-tile-1');
        await shot(t, 'ls05_strip_explore_rus', b.key, wait: 300);
      });

      testWidgets('the Russian strip, make: the target and "that\'s it"', (WidgetTester t) async {
        await openLesson(t, _rus(), 'str1', b.value);
        await shot(t, 'ls05_strip_make_rus', b.key);
      });

      testWidgets('the Russian strip, make, hint 3: the friend slides to the right vowel', (
        WidgetTester t,
      ) async {
        await openLesson(t, _rus(), 'str1', b.value);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('change-done')));
          await waitFor(t, i < 2 ? 1300 : 1500);
        }
        await shot(t, 'ls05_strip_hint3_rus', b.key, wait: 400);
      });
    });
  }
}
