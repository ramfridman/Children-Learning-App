// The playthrough of the language packs the pipeline makes (`content/languages/<course>/pack`, from the teachers' files by
// `tools/lang_pack.py`, built and signed by the pack builder): for each course the child opens the door, the course home offers its
// first lesson, the lesson is played to the celebration with the real lesson screen, and the answers are written as the rows the engine
// and the sync read. The packs are signed here with a throw-away key. Every clip is pending (no voice yet), as the packs say.
// Goldens of the first activity of each course on the phone and the tablet. A child whose parent says they know something starts with the
// placement visit; a beginner (no answers) goes straight to lesson 1 (L7-2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/course_flow.dart';
import 'support/course_history.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_golden.dart' show boards;
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

/// The first lesson of each course's pilot: its id, the skill of its choice items and how many choice items it plays (a picture to find, a
/// puppet's bubble to answer). A new learner meets the lesson's words first (L7): the choice items that ask a word just met write no evidence in
/// that visit (L7-3), so the visit leaves no row; the same lesson played again is scored.
const Map<String, ({String lesson, String skill, int choices})> _first =
    <String, ({String lesson, String skill, int choices})>{
      'eng': (lesson: 'eng.greet-1', skill: 'ENG-A-01', choices: 5),
      'heb': (lesson: 'heb.words-1', skill: 'HEB-A-02', choices: 6),
      'rus': (lesson: 'rus.greet-1', skill: 'RUS-A-01', choices: 4),
    };

bool _on(String key) => find.byKey(Key(key)).evaluate().isNotEmpty;

/// The screen of the lesson that is no choice, passed as a child passes it; false when the screen on show is a choice (or nothing known).
/// A story is turned page by page; a Meet screen is heard through (the beats are paced by the voice: a clip that is pending still has its pause of
/// 1.2 s, and "I said it" arrives with "let's say it together" and closes the screen by itself); a say step is "I said it" and then the picture;
/// a thing to do is "done". Nothing here is asked and nothing is written.
Future<bool> _passScreen(WidgetTester tester) async {
  if (_on('story-turn')) {
    await tester.tap(find.byKey(const Key('story-turn')));
    await settle(tester, ms: 600);
  } else if (_on('meet-card')) {
    await settle(tester, ms: 6500);
    await tester.tap(find.byKey(const Key('say-done')));
    await settle(tester, ms: 2500);
  } else if (_on('say-done')) {
    await settle(tester, ms: 500);
    await tester.tap(find.byKey(const Key('say-done')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('say-picture')));
    await settle(tester, ms: 3000);
  } else if (_on('do-done')) {
    await tester.tap(find.byKey(const Key('do-done')));
    await settle(tester, ms: 3000);
  } else {
    return false;
  }
  return true;
}

/// A choice is on screen: a picture to find, or a puppet's bubble.
bool _choiceOn() => _on('option-o1') || _on('tile-o1');

/// Plays the screens that are no choice until a choice (or the celebration) is on screen.
Future<void> passToChoice(WidgetTester tester) async {
  for (int step = 0; step < 60 && !_choiceOn() && !_on('lesson-celebration'); step++) {
    if (!await _passScreen(tester)) await settle(tester, ms: 1000);
  }
  expect(_choiceOn(), isTrue, reason: 'a choice is on screen');
}

/// Plays the lesson on screen to its celebration, every choice answered right; returns how many choices it asked.
Future<int> playLesson(WidgetTester tester) async {
  int choices = 0;
  for (int step = 0; step < 90 && !_on('lesson-celebration'); step++) {
    if (_choiceOn()) {
      await tester.tap(find.byKey(Key(_on('option-o1') ? 'option-o1' : 'tile-o1')));
      await settle(tester, ms: 3000);
      choices++;
    } else if (!await _passScreen(tester)) {
      await settle(tester, ms: 3000); // a chant plays by itself
    }
  }
  expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
  return choices;
}

/// The lesson played again from the course home (a later visit: its Meet screens come again, nothing is a first meeting any more).
Future<void> openLessonAgain(WidgetTester tester, String course) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) =>
              LessonScreen(profileId: courseKid, lessonId: _first[course]!.lesson, course: course),
        ),
      );
  await settle(tester);
  expect(find.byType(LessonScreen), findsOneWidget);
}

/// The course has a placement game, so its first visit is the placement (frame 3.2): the child plays the probes, touching a wrong
/// picture each time (so that the staircase stays on the floor and the first lesson is still the next one), until the visit ends with
/// its own celebration, and is back on the home.
Future<void> playPlacement(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('course-play')));
  await settle(tester);
  expect(find.byType(LessonScreen), findsOneWidget);
  // Any answer tile of the probe on screen (a picture or a sound, a letter): the second one, which is not the right one in the packs.
  final Finder tiles = find.byWidgetPredicate(
    (Widget w) =>
        w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(RegExp(r'option-|tile-o')),
  );
  int probes = 0;
  while (find.byKey(const Key('lesson-celebration')).evaluate().isEmpty && tiles.evaluate().length > 1) {
    expect(++probes, lessThan(16), reason: 'the placement visit ends after about eight probes');
    await tester.tap(tiles.at(1));
    await settle(tester, ms: 3000);
  }
  expect(probes, greaterThan(0), reason: 'the placement offered at least one probe');
  if (find.byKey(const Key('lesson-done')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('lesson-done')));
    await tester.pumpAndSettle();
  }
  expect(
    find.byType(CourseHomeScreen),
    findsOneWidget,
    reason: 'back on the course home after the placement',
  );
}

void main() {
  late Map<String, PackContent> packs;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    final PackKey key = await newTestKey();
    packs = <String, PackContent>{
      for (final String c in Course.languages)
        c: PackContent.fromPack(
          await verifyPack(
            (await buildPack(languageSource(c, _languages), key)).bytes,
            publicKey: key.publicKey,
          ),
        ),
    };
  });

  for (final String course in Course.languages) {
    group('$course: the first lesson of the pilot pack', () {
      testWidgets(
        'from the door to the celebration: a first visit writes no evidence, the visit played again writes every answer under the course',
        (WidgetTester tester) async {
          final ({String lesson, String skill, int choices}) first = _first[course]!;
          final AppRig rig = await courseApp(
            tester,
            <String>[course],
            packs: packs,
            switches: knowsALittle(course),
          );
          await openCourse(tester, course);
          expect(find.byType(CourseHomeScreen), findsOneWidget);
          expect(find.byKey(const Key('course-play')), findsOneWidget);
          await playPlacement(tester);
          final int placed = (await rig.db.attemptsOf(courseKid)).length;
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          expect(find.byType(LessonScreen), findsOneWidget);
          expect(tester.widget<LessonScreen>(find.byType(LessonScreen)).course, course);
          expect(tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId, first.lesson);
          expect(find.byKey(const Key('lesson-celebration')), findsNothing);
          expect(await playLesson(tester), first.choices);
          await tester.tap(find.byKey(const Key('lesson-done')));
          await tester.pumpAndSettle();
          expect(find.byType(CourseHomeScreen), findsOneWidget, reason: 'back on the course home');
          expect(
            (await rig.db.attemptsOf(courseKid)).where((Attempt a) => a.lessonId == first.lesson),
            isEmpty,
            reason: 'every choice asked a word just met: a first meeting is no evidence',
          );
          expect((await rig.db.attemptsOf(courseKid)).length, placed);

          await openLessonAgain(tester, course);
          expect(await playLesson(tester), first.choices);
          final List<Attempt> rows = <Attempt>[
            for (final Attempt a in await rig.db.attemptsOf(courseKid))
              if (a.lessonId == first.lesson) a,
          ];
          expect(rows, hasLength(first.choices));
          expect(placed, greaterThan(0), reason: 'the placement probes were answered first');
          for (final Attempt a in rows) {
            expect(a.packId, 'lang-$course');
            expect(a.lessonId, first.lesson);
            expect(a.skillId, first.skill);
            expect(Course.ofActivityId(a.activityId), course);
            expect(a.result, 'correct');
            expect(a.hintLevel, 0);
            expect(
              a.response,
              matches(RegExp(r'^[a-z0-9]{1,3}$')),
              reason: 'an option id, never a word (rule 2)',
            );
          }
        },
      );

      testWidgets(
        'a wrong touch is no evidence in the visit that introduces the word, and the diagnosed error of its distractor in a later one, never marked as a failure of the child',
        (WidgetTester tester) async {
          final AppRig rig = await courseApp(
            tester,
            <String>[course],
            packs: packs,
            switches: knowsALittle(course),
          );
          await openCourse(tester, course);
          await playPlacement(tester);
          final int before = (await rig.db.attemptsOf(courseKid)).length;
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          await passToChoice(tester);
          await answer(tester, right: false);
          expect(
            (await rig.db.attemptsOf(courseKid)).skip(before),
            isEmpty,
            reason: 'the word was just met on a Meet screen: a guess is no evidence',
          );
          expect(find.byKey(const Key('lesson-celebration')), findsNothing, reason: 'still being played');

          // The lesson finished and played again: the same touch is the diagnosed error of the distractor.
          await playLesson(tester);
          await tester.tap(find.byKey(const Key('lesson-done')));
          await tester.pumpAndSettle();
          await openLessonAgain(tester, course);
          await passToChoice(tester);
          final int again = (await rig.db.attemptsOf(courseKid)).length;
          await answer(tester, right: false);
          final List<Attempt> rows = (await rig.db.attemptsOf(courseKid)).skip(again).toList();
          expect(rows, hasLength(1));
          expect(rows.single.result, 'incorrect');
          expect(
            rows.single.misconceptionTag,
            startsWith('$course.'),
            reason: 'a tag of the course catalogue',
          );
          expect(packs[course]!.tags, contains(rows.single.misconceptionTag));
          expect(
            find.byKey(const Key('lesson-celebration')),
            findsNothing,
            reason: 'the item is still being played',
          );
        },
      );

      for (final MapEntry<String, Size> b in boards.entries.where(
        (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'tabletLandscape',
      )) {
        testWidgets('the first activity on the ${b.key} board', (WidgetTester tester) async {
          await courseApp(
            tester,
            <String>[course],
            packs: packs,
            size: b.value,
            switches: knowsALittle(course),
          );
          await openCourse(tester, course);
          await playPlacement(tester);
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          expect(find.byType(LessonScreen), findsOneWidget);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/pilot_${course}_first_${b.key}.png'),
          );
        });
      }

      testWidgets(
        'a beginner (no answers) is not asked to play: the first pebble opens lesson 1, no probe is written',
        (WidgetTester tester) async {
          final AppRig rig = await courseApp(tester, <String>[course], packs: packs);
          await openCourse(tester, course);
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          expect(find.byType(LessonScreen), findsOneWidget, reason: 'the lesson, not a placement visit');
          final Lesson lesson = packs[course]!.lessons[_first[course]!.lesson]!;
          expect(tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId, lesson.id);
          expect(await rig.db.attemptsOf(courseKid), isEmpty);
        },
      );

      test('the pack plays text only: nothing is recorded, the lesson says so in its manifest', () {
        final String source = File('$_languages/$course/pack/pack.json').readAsStringSync();
        expect((jsonDecode(source) as Map<String, Object?>)['vo'], isEmpty);
        expect(packs[course]!.packVersion, '0.1.0');
      });
    });
  }
}
