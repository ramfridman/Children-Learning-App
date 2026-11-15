// The Meet screen and the Find on the screen (L7-4, docs/design/l7-meet-find.md sections 3, 6 and 10), on English lesson 1 of the real course:
// the beats in their order and the Hebrew meaning said exactly once, a touch on the picture that is silent during the first beats and then says
// the word and never moves on, "I said it" and the microphone that arrive with "let's say it together" and close the screen, and the Find: the
// tapped picture says its word, then "and where is ...?" and the target, and the stage takes no touch while the tapped word plays.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/course_text.dart' show TargetChip;
import 'package:nitznutz/play/speaking_badge.dart';

import 'support/harness.dart';
import 'support/l7_rig.dart';
import 'support/meet_opener.dart';

const Key _picture = Key('say-picture');
const Key _tile = Key('say-done');

void main() {
  late PackContent eng;

  setUpAll(() async {
    await loadAppFonts();
    eng = await buildEnglish();
  });

  int count(List<String> said, String line) => said.where((String l) => l == line).length;

  double tileOpacity(WidgetTester t) => t
      .widget<AnimatedOpacity>(
        find.ancestor(of: find.byKey(_tile), matching: find.byType(AnimatedOpacity)).first,
      )
      .opacity;

  testWidgets(
    'the beats of the first Meet screen: the word, its meaning once, the word, "together" and the word, the word again',
    (WidgetTester t) async {
      final L7Rig r = await openEnglishLesson(t, eng);
      await l7Wait(t, 9500);
      expect(
        r.said.skip(1).take(7).toList(),
        <String>[
          'eng.en_hello',
          'eng.he_hint_hebrew',
          'eng.he_gl_hello',
          'eng.en_hello',
          'eng.he_fb_together',
          'eng.en_hello',
          'eng.en_hello',
        ],
        reason: 'M1, M2 (the carrier and the gloss), M3, M4 (together and the word), then M5 after the child\'s pause',
      );
      expect(
        count(r.said, 'eng.he_gl_hello'),
        1,
        reason: 'the Hebrew meaning is said exactly once on its screen',
      );
    },
  );

  testWidgets(
    'the opener is said once, before the first new word of the lesson, and not again before the next word of the set',
    (WidgetTester t) async {
      final L7Rig r = await openEnglishLesson(t, eng, pastOpener: false);
      await l7Wait(t, 400);
      expect(badgeLit, findsNothing, reason: 'the opener lights no badge: no word is being said yet');
      await untilWordBeat(t);
      expect(r.said, <String>[
        'eng.he_meet_open',
        'eng.en_hello',
      ], reason: 'the opener comes first, then the first word');
      await l7Wait(t, 5400);
      await t.tap(find.byKey(_tile));
      await l7Wait(t, 7000);
      expect(
        find.byKey(const Key('meet-thumb-0')),
        findsOneWidget,
        reason: 'the second word of the set is on screen',
      );
      expect(
        count(r.said, 'eng.he_meet_open'),
        1,
        reason: 'the second screen of the set does not say the opener again',
      );
      expect(count(r.said, 'eng.en_goodbye'), greaterThan(0), reason: 'and its own word was said');
    },
  );

  testWidgets(
    'a touch on the picture is silent during the first beats, then says the word, and never moves on',
    (WidgetTester t) async {
      final L7Rig r = await openEnglishLesson(t, eng);
      await l7Wait(t, 300);
      final int before = r.said.length;
      await t.tap(find.byKey(_picture));
      await l7Wait(t, 200);
      expect(
        r.said.length,
        before,
        reason: 'no sound during M0 to M4: no beat is cut and the meaning is never lost',
      );
      await l7Wait(t, 6500);
      final int heard = r.said.length;
      await t.tap(find.byKey(_picture));
      await l7Wait(t, 400);
      expect(r.said.length, greaterThan(heard), reason: 'from the child\'s turn a touch says the word again');
      expect(r.said.last, 'eng.en_hello');
      expect(
        find.byKey(_tile),
        findsOneWidget,
        reason: 'the touch never moves on: the same screen, the same tile',
      );
      expect(count(r.said, 'eng.he_gl_hello'), 1, reason: 'a touch never says the meaning again');
    },
  );

  testWidgets('"I said it" arrives with "let\'s say it together" and closes the screen by itself', (
    WidgetTester t,
  ) async {
    final L7Rig r = await openEnglishLesson(t, eng);
    await l7Wait(t, 300);
    expect(tileOpacity(t), 0, reason: 'not before the fourth beat');
    await l7Wait(t, 4800);
    expect(tileOpacity(t), 1);
    final int words = count(r.said, 'eng.en_hello');
    await t.tap(find.byKey(_tile));
    await l7Wait(t, 2500);
    expect(
      find.byKey(const Key('meet-thumb-0')),
      findsOneWidget,
      reason: 'the second screen of the set: the first word stands in the strip',
    );
    expect(count(r.said, 'eng.en_hello'), greaterThanOrEqualTo(words));
  });

  testWidgets('the written word: never in look A, whatever the letters gate says', (WidgetTester t) async {
    await openEnglishLesson(t, eng, band: 0, lettersOpen: true);
    await l7Wait(t, 5400);
    expect(
      find.byType(TargetChip),
      findsNothing,
      reason: 'look A shows no text, whatever the letters gate says',
    );
  });

  testWidgets(
    'the written word: a look C child whose letters are open sees the word in its chip under the line',
    (WidgetTester t) async {
      await openEnglishLesson(t, eng, band: 2, lettersOpen: true);
      await l7Wait(t, 400);
      expect(
        find.byType(TargetChip),
        findsNothing,
        reason: 'not on the first beats: the word is heard first',
      );
      await l7Wait(t, 5400);
      expect(
        find.byType(TargetChip),
        findsOneWidget,
        reason: 'under the together line (M4): English has no carrier, so M3 has no line to stand under',
      );
    },
  );

  testWidgets('the written word: a look C child whose letters are closed sees none', (WidgetTester t) async {
    await openEnglishLesson(t, eng, band: 2);
    await l7Wait(t, 5000);
    expect(find.byType(TargetChip), findsNothing);
  });

  testWidgets('the strip names a met word when it is touched, from the child\'s turn on', (
    WidgetTester t,
  ) async {
    final L7Rig r = await openEnglishLesson(t, eng);
    await l7Wait(t, 5400);
    await t.tap(find.byKey(_tile));
    await l7Wait(t, 1500);
    await t.tap(find.byKey(const Key('meet-thumb-0')));
    await l7Wait(t, 300);
    final int before = r.said.length;
    await l7Wait(t, 9000);
    await t.tap(find.byKey(const Key('meet-thumb-0')));
    await l7Wait(t, 400);
    expect(r.said.sublist(before).contains('eng.en_hello'), isTrue);
  });

  testWidgets(
    'the Find: the tapped picture says its word, then "and where is" and the target, with no hint picture',
    (WidgetTester t) async {
      final L7Rig r = await openEnglishLesson(t, eng);
      await l7Wait(t, 5400);
      await t.tap(find.byKey(_tile));
      await l7Wait(t, 1500);
      await l7Wait(t, 5400);
      await t.tap(find.byKey(_tile));
      await l7Wait(t, 2500);
      // The first Find asks "hello": o1 is Pip arriving (right), o2 Pip leaving (goodbye).
      final int mark = r.said.length;
      await t.tap(find.byKey(const Key('option-o2')));
      await l7Wait(t, 150);
      expect(
        find.byWidgetPredicate((Widget w) => w is SpeakingBadge && w.on),
        findsOneWidget,
        reason: 'the tapped picture is speaking',
      );
      await l7Wait(t, 3200);
      final List<String> after = r.said.sublist(mark);
      expect(after.take(3).toList(), <String>[
        'eng.en_goodbye',
        'eng.he_fb_where',
        'eng.en_hello',
      ], reason: 'the tapped word first, then the question and the target; never mixed');
    },
  );

  testWidgets('the stage takes no touch while the tapped word plays, and a right tap afterwards is taken', (
    WidgetTester t,
  ) async {
    final L7Rig r = await openEnglishLesson(t, eng);
    await l7Wait(t, 5400);
    await t.tap(find.byKey(_tile));
    await l7Wait(t, 1500);
    await l7Wait(t, 5400);
    await t.tap(find.byKey(_tile));
    await l7Wait(t, 2500);
    await t.tap(find.byKey(const Key('option-o2')));
    await l7Wait(t, 100);
    await t.tap(find.byKey(const Key('option-o1')), warnIfMissed: false);
    await l7Wait(t, 200);
    expect(
      r.said.where((String l) => l.startsWith('eng.he_fb_right_')),
      isEmpty,
      reason: 'the right tap was held: no praise yet',
    );
    await l7Wait(t, 3000);
    await t.tap(find.byKey(const Key('option-o1')));
    await l7Wait(t, 300);
    expect(
      find.byWidgetPredicate((Widget w) => w is SpeakingBadge && w.on),
      findsOneWidget,
      reason: 'a right tap says its word with the badge too',
    );
  });
}
