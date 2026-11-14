// Goldens of the Meet screen and the Find (L7-4, docs/design/l7-meet-find.md section 12), on English lesson 1 and lesson act-1 of the real course.
// Pictures are the course's own; the voice is a fake recording.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_l7_meet_find_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l7_rig.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

Future<void> _shot(WidgetTester t, String name, String board) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/l7_${name}_$board.png'));

/// From the first Meet screen to the child's turn on the second (word 2 of 2): "I said it" is tapped at "together" on the first.
Future<void> _toSecondTurn(WidgetTester t) async {
  await l7Wait(t, 5400);
  await t.tap(find.byKey(const Key('say-done')));
  await l7Wait(t, 8000);
}

/// Through both Meet screens to the first Find.
Future<void> _toFind(WidgetTester t) async {
  await _toSecondTurn(t);
  await t.tap(find.byKey(const Key('say-done')));
  await l7Wait(t, 2500);
}

void main() {
  late PackContent eng;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    eng = await buildEnglish();
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets(
        'Meet, word 2 of 2, the child\'s turn: the strip, "I said it" with its glyph, the microphone',
        (WidgetTester t) async {
          await openEnglishLesson(t, eng, size: b.value, voice: true);
          await _toSecondTurn(t);
          await _shot(t, 'meet_eng_m5_lookA', b.key);
        },
      );
    });
  }

  for (final String board in <String>['phone', 'phoneSE']) {
    group(board, () {
      testWidgets('Meet, the first screen of a set: the strip column kept and empty, the speaking badge', (
        WidgetTester t,
      ) async {
        await openEnglishLesson(t, eng, size: boards[board]!);
        await l7Wait(t, 500);
        await _shot(t, 'meet_eng_first_m1_lookA', board);
      });

      testWidgets('Find with two choices: the lilac settle and "and where is" in the bubble', (
        WidgetTester t,
      ) async {
        await openEnglishLesson(t, eng, size: boards[board]!);
        await _toFind(t);
        await t.tap(find.byKey(const Key('option-o2')));
        await l7Wait(t, 1100);
        await _shot(t, 'find_wrong_ask_2', board);
      });

      testWidgets('Find with three choices: the pictures on the whole start column', (WidgetTester t) async {
        await openEnglishLesson(t, eng, size: boards[board]!, lesson: 'eng.act-1');
        await l7Wait(t, 600);
        await _shot(t, 'find_layout_3', board);
      });
    });
  }

  for (final String board in <String>['phone', 'tabletPortrait']) {
    testWidgets(
      'Meet, "together" for a look C child whose letters are open: the word in its chip under the line, the badge ($board)',
      (WidgetTester t) async {
        await openEnglishLesson(t, eng, size: boards[board]!, band: 2, lettersOpen: true);
        await l7Wait(t, 5300);
        await _shot(t, 'meet_eng_m4_lookC_letters', board);
      },
    );
  }

  testWidgets('Find with two choices: the tapped picture is speaking on the tall phone stage', (
    WidgetTester t,
  ) async {
    await openEnglishLesson(t, eng);
    await _toFind(t);
    await t.tap(find.byKey(const Key('option-o2')));
    await l7Wait(t, 150);
    await _shot(t, 'find_wrong_speaking_2', 'phone');
  });

  testWidgets('Find with two choices: a right tap says its word with the badge, in the gold ring', (
    WidgetTester t,
  ) async {
    await openEnglishLesson(t, eng);
    await _toFind(t);
    await t.tap(find.byKey(const Key('option-o1')));
    await l7Wait(t, 150);
    await _shot(t, 'find_right_2', 'phone');
  });

  testWidgets('text size 1.3 on the small phone: the bubble and the tile clear, a Meet screen and a Find', (
    WidgetTester t,
  ) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await openEnglishLesson(t, eng, size: boards['phoneSE']!);
    await _toSecondTurn(t);
    await _shot(t, 'meet_eng_m5_lookA_text13', 'phoneSE');
    await t.tap(find.byKey(const Key('say-done')));
    await l7Wait(t, 2500);
    await _shot(t, 'find_first_text13', 'phoneSE');
  });
}
