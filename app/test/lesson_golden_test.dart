// Golden screenshots of the butterflies lesson, step by step, on a phone and on both tablet shapes,
// in right to left with the real fonts (the same 3 percent tolerance as the other screens).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/lesson_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/hint_hand.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _tap(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)), warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 60));
}

Future<void> _shot(WidgetTester t, String name) async {
  await _wait(t, 900);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/lesson_$name.png'));
}

Future<void> _count(WidgetTester t, Iterable<int> indexes) async {
  for (final int i in indexes) {
    await _tap(t, 'butterfly-$i');
    await _wait(t, 700);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone', const Size(852, 393)),
    ('tablet_landscape', const Size(1180, 820)),
    ('tablet_portrait', const Size(820, 1180)),
  ]) {
    testWidgets('the butterflies lesson, step by step, ${device.$1}', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      await openCountingLesson(tester);
      await tester.pumpAndSettle();
      final String d = device.$1;

      // 1. Where is the red flower?
      await _shot(tester, '1_red_flower_$d');
      await _tap(tester, 'option-o1');
      await _wait(tester, 2200);

      // 2. Three in a line, all counted, the answers on offer.
      await _count(tester, <int>[0, 1, 2]);
      await _shot(tester, '2_count_three_answers_$d');
      await _tap(tester, 'tile-o2');
      await _wait(tester, 2200);

      // 3. Four scattered, two counted so far.
      await _count(tester, <int>[0, 1]);
      await _shot(tester, '3_scattered_midway_$d');
      await _count(tester, <int>[2, 3]);
      await _tap(tester, 'tile-o2');
      await _wait(tester, 2200);

      // 4. Five that stay and glow, three counted so far.
      await _count(tester, <int>[0, 1, 2]);
      await _shot(tester, '4_glow_midway_$d');
      await _count(tester, <int>[3, 4]);
      await _tap(tester, 'tile-o2');
      await _wait(tester, 2200);

      // 5. Give four of seven, two on the flower.
      await _shot(tester, '5_give_start_$d');
      for (int i = 0; i < 2; i++) {
        await _tap(tester, 'give-butterfly-$i');
        await tester.tapAt(tester.getCenter(find.byKey(const Key('give-flower'))));
        await _wait(tester, 400);
      }
      await _shot(tester, '5_give_two_$d');
      for (int i = 2; i < 4; i++) {
        await _tap(tester, 'give-butterfly-$i');
        await tester.tapAt(tester.getCenter(find.byKey(const Key('give-flower'))));
        await _wait(tester, 400);
      }
      await _tap(tester, 'give-done');
      await _wait(tester, 2200);

      // 6. The celebration.
      await _shot(tester, '6_celebration_$d');
      await tester.tap(find.byKey(const Key('lesson-done')));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('help on screen: a mistake with the fingers, phone', (WidgetTester tester) async {
    // The hands are art files; they come from the asset bundle, which needs the real clock.
    await tester.runAsync(warmHintHands);
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup(name: 'נֹעָה');
    await rig.pump(tester);
    await tester.tap(find.text('נֹעָה'));
    await tester.pumpAndSettle();
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    await _tap(tester, 'option-o1');
    await _wait(tester, 2200);
    await _count(tester, <int>[0, 1, 2]);
    await _tap(tester, 'tile-o3'); // a mistake
    await _shot(tester, 'mistake_double_phone');
    await _wait(tester, 2000);
    await _count(tester, <int>[0, 1, 2]);
    await _tap(tester, 'tile-o1'); // a second mistake: the hand counts on its fingers
    await _wait(tester, 3200);
    await _shot(tester, 'fingers_phone');
    await _tap(tester, 'activity-home');
    await tester.pumpAndSettle();
  });
}
