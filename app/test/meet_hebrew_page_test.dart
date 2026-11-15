// The Hebrew Meet page on the screen (docs/design/l7-meet-find.md section 5, L7-6): a new word of a Hebrew story is met on the story's picture
// with a ring on the part the word names (`focus`), and one short sentence that explains it (`explain`) in the place the Hebrew meaning has in
// English and Russian. The real Hebrew course: lesson `heb.words-1` after story 1.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';

import 'support/harness.dart';
import 'support/l7_rig.dart';

const Key _tile = Key('say-done');
const Key _ring = Key('meet-focus');

void main() {
  late PackContent heb;
  late PackContent eng;

  setUpAll(() async {
    await loadAppFonts();
    heb = await buildCourse('heb');
    eng = await buildEnglish();
  });

  List<SayItActivity> pages() => <SayItActivity>[
    for (final Activity a in heb.activities.values)
      if (a is SayItActivity && a.meetScreen) a,
  ];

  /// Waits until "I said it" has arrived (the child's turn) and touches it.
  Future<void> sayIt(WidgetTester t) async {
    final Finder tile = find.ancestor(of: find.byKey(_tile), matching: find.byType(AnimatedOpacity));
    for (int i = 0; i < 150 && t.widget<AnimatedOpacity>(tile.first).opacity < 1; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.byKey(_tile));
    await l7Wait(t, 2500);
  }

  /// Story 1, page by page to its tick, and the page that follows it.
  Future<L7Rig> toFirstPage(WidgetTester t, {int band = 1}) async {
    final L7Rig r = await openCourseLesson(t, 'heb', heb, lesson: 'heb.words-1', band: band);
    await l7Wait(t, 600);
    for (int i = 0; i < 5; i++) {
      await t.tap(find.byKey(const Key('story-turn')));
      await l7Wait(t, 300);
    }
    await l7Wait(t, 2500);
    return r;
  }

  group('the pages of the pack', () {
    test('every Hebrew Meet page has the sentence that explains its word, and says no gloss of its own', () {
      expect(pages(), isNotEmpty);
      for (final SayItActivity a in pages()) {
        final MeetData m = a.meet!;
        expect(m.explain, isNotNull, reason: a.id);
        expect(m.explain!.vo, isNotEmpty, reason: a.id);
        expect(
          m.explain!.caption,
          isNotEmpty,
          reason: '${a.id}: the sentence is in the bubble when captions are on',
        );
        expect(
          m.meaning,
          isNull,
          reason: '${a.id}: a Hebrew speaker needs no translation, the explanation stands in its place',
        );
      }
    });

    test('a story page names the part its word is about: a focus is a rectangle inside the picture', () {
      final List<SayItActivity> ringed = pages().where((SayItActivity a) => a.meet!.focus != null).toList();
      expect(ringed.length, greaterThanOrEqualTo(7), reason: 'the story words of stories 1 and 2');
      for (final SayItActivity a in ringed) {
        final Rect f = a.meet!.focus!;
        expect(f.left, inInclusiveRange(0, 1), reason: a.id);
        expect(f.top, inInclusiveRange(0, 1), reason: a.id);
        expect(f.right, lessThanOrEqualTo(1.0001), reason: '${a.id}: inside the picture on the right');
        expect(f.bottom, lessThanOrEqualTo(1.0001), reason: '${a.id}: inside the picture below');
        expect(f.width, greaterThan(0.1), reason: a.id);
        expect(f.height, greaterThan(0.1), reason: a.id);
      }
      // A verb is met on an object picture that is the word as a whole: no ring.
      expect(heb.activities['heb.a02.tc08'].runtimeType, SayItActivity);
      expect((heb.activities['heb.a02.tc08']! as SayItActivity).meet!.focus, isNull);
    });
  });

  group('on the screen', () {
    testWidgets(
      'the beats: the carrier and the word, the explaining sentence once, "together" and the word',
      (WidgetTester t) async {
        final L7Rig r = await toFirstPage(t);
        await l7Wait(t, 9000);
        final List<String> said = r.said.skip(r.said.indexOf('heb.meet_new')).toList();
        expect(
          said.take(6).toList(),
          <String>[
            'heb.meet_new',
            'heb.heb_a_w_siach',
            'heb.m_siach',
            'heb.heb_a_w_siach',
            'heb.say_together',
            'heb.heb_a_w_siach',
          ],
          reason:
              'H1 hear (the carrier and the word), H2 the sentence, the word again, H3 together and the word',
        );
        expect(
          said.where((String l) => l == 'heb.m_siach'),
          hasLength(1),
          reason: 'the sentence is said exactly once',
        );
      },
    );

    testWidgets(
      'the ring is on from the word being heard to the close of the page, and the sentence is in the bubble',
      (WidgetTester t) async {
        await toFirstPage(t);
        await l7Wait(t, 400);
        expect(find.byKey(_ring), findsOneWidget, reason: 'H1: the ring appears with the word being heard');
        for (
          int i = 0;
          i < 80 &&
              find.text('שִׂיחַ הוּא כְּמוֹ עֵץ קָטָן וְנָמוּךְ, עִם הַרְבֵּה עָלִים.').evaluate().isEmpty;
          i++
        ) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.text('שִׂיחַ הוּא כְּמוֹ עֵץ קָטָן וְנָמוּךְ, עִם הַרְבֵּה עָלִים.'),
          findsOneWidget,
          reason: 'H2: the sentence, captions on',
        );
        expect(find.byKey(_ring), findsOneWidget, reason: 'H2: the ring stays');
        await l7Wait(t, 2500);
        expect(find.byKey(_ring), findsOneWidget, reason: 'H3: the ring stays until the page is closed');
      },
    );

    testWidgets(
      'a touch on the picture never says the sentence again, and "I said it" goes on to the second page',
      (WidgetTester t) async {
        final L7Rig r = await toFirstPage(t);
        await l7Wait(t, 9000);
        final int before = r.said.where((String l) => l == 'heb.m_siach').length;
        await t.tap(find.byKey(const Key('say-picture')));
        await l7Wait(t, 400);
        expect(
          r.said.where((String l) => l == 'heb.m_siach').length,
          before,
          reason: 'the sentence is not part of the replay',
        );
        await sayIt(t);
        const String second = 'בּוֹעֲטִים בְּכַדּוּר בָּרֶגֶל, וְהוּא עָף רָחוֹק.';
        for (int i = 0; i < 120 && find.text(second).evaluate().isEmpty; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(second), findsOneWidget, reason: 'the second page of the set explains its own word');
        expect(
          find.byKey(_ring),
          findsOneWidget,
          reason: 'the second page rings the part its own word names',
        );
      },
    );

    testWidgets('an English screen has no focus and so no ring', (WidgetTester t) async {
      await openEnglishLesson(t, eng);
      await l7Wait(t, 6000);
      expect(find.byKey(_ring), findsNothing);
    });
  });
}
