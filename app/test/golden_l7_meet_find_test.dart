// Goldens of the Meet screen and the Find (L7-4, docs/design/l7-meet-find.md section 12), on English lesson 1 and lesson act-1 of the real course,
// the Russian family lesson (golden 3: the Hebrew meaning in the bubble) and the Hebrew words lesson (golden 5: the page with its focus ring and
// its explaining sentence). Pictures are the course's own; the voice is a fake recording.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_l7_meet_find_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/course_text.dart' show TargetChip;

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

/// Waits (at most 12 s) until [text] is in the bubble, then a little more for what comes with it.
Future<void> _untilBubble(WidgetTester t, String text) async {
  for (int i = 0; i < 120 && find.text(text).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(find.text(text), findsOneWidget, reason: 'the bubble says: $text');
  await t.pump(const Duration(milliseconds: 400));
}

/// A Meet screen heard through: "I said it" is tapped as soon as it arrives, and the next screen is on.
Future<void> _passMeet(WidgetTester t) async {
  for (int i = 0; i < 120; i++) {
    final Finder tile = find.ancestor(
      of: find.byKey(const Key('say-done')),
      matching: find.byType(AnimatedOpacity),
    );
    if (tile.evaluate().isNotEmpty && t.widget<AnimatedOpacity>(tile.first).opacity == 1) break;
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.tap(find.byKey(const Key('say-done')));
  await l7Wait(t, 1500);
}

/// The story of the Hebrew lesson, heard page by page to its tick (the page is turned as soon as it is there).
Future<void> _passStory(WidgetTester t) async {
  await l7Wait(t, 600);
  for (int i = 0; i < 5; i++) {
    await t.tap(find.byKey(const Key('story-turn')));
    await l7Wait(t, 300);
  }
  await l7Wait(t, 2500);
}

void main() {
  late PackContent eng;
  late PackContent rus;
  late PackContent heb;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    eng = await buildEnglish();
    rus = await buildCourse('rus');
    heb = await buildCourse('heb');
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
    // The word is said first (the lilac ring and the badge, about 700 ms); the picture is then in the gold ring and the guide cheers, which
    // is the settled moment of a right tap (QA-L7-4: at 150 ms the shot showed neither), before the next line begins.
    await l7Wait(t, 1150);
    await _shot(t, 'find_right_2', 'phone');
  });

  // QA-L7-4: a Russian word in its chip (left to right, Cyrillic, Nitznutz Letters) on the phone, look C with the letters gate open, at "let's say it
  // together". The Russian Find authors no chip (the pack's `show` steps are only on the Meet beats), so this is the chip's golden.
  testWidgets(
    'Russian Meet, "together" for a look C child whose letters are open: the Cyrillic word in its chip (phone)',
    (WidgetTester t) async {
      await openCourseLesson(
        t,
        'rus',
        rus,
        lesson: 'rus.family-1',
        size: boards['phone']!,
        band: 2,
        lettersOpen: true,
      );
      for (int i = 0; i < 120 && find.byType(TargetChip).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(TargetChip), findsOneWidget, reason: 'the word is in its chip');
      await t.pump(const Duration(milliseconds: 400));
      await _shot(t, 'meet_rus_chip_lookC_letters', 'phone');
    },
  );

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

  // Golden 3: the third word of a Russian set, look B: the Hebrew meaning in the bubble, two words in the strip, no chip, no tile.
  for (final String board in <String>['phone', 'phoneSE', 'tabletPortrait']) {
    testWidgets(
      'Russian Meet, word 3 of 3, look B: the meaning in the bubble, two thumbnails, no chip, no tile ($board)',
      (WidgetTester t) async {
        await openCourseLesson(t, 'rus', rus, lesson: 'rus.family-1', size: boards[board]!, band: 1);
        await _passMeet(t);
        await _passMeet(t);
        await _untilBubble(t, 'בְּעִבְרִית: אַבָּא');
        expect(find.byKey(const Key('meet-thumb-0')), findsOneWidget);
        expect(find.byKey(const Key('meet-thumb-1')), findsOneWidget);
        expect(find.byType(TargetChip), findsNothing, reason: 'no chip at the meaning');
        await _shot(t, 'meet_rus_m2_lookB', board);
      },
    );
  }

  // Golden 5: the first page of the Hebrew words lesson, after story 1: the word's part of the picture ringed, the explaining sentence in the bubble.
  for (final String board in <String>['phone', 'phoneSE']) {
    testWidgets(
      'Hebrew Meet page, word 1 of 3, at its explaining sentence: the focus ring on the story page ($board)',
      (WidgetTester t) async {
        await openCourseLesson(t, 'heb', heb, lesson: 'heb.words-1', size: boards[board]!, band: 1);
        await _passStory(t);
        await _untilBubble(t, 'שִׂיחַ הוּא כְּמוֹ עֵץ קָטָן וְנָמוּךְ, עִם הַרְבֵּה עָלִים.');
        expect(find.byKey(const Key('meet-focus')), findsOneWidget);
        await _shot(t, 'meet_heb_page_h2', board);
      },
    );
  }
}
