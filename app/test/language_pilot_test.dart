// The playthrough of the language packs the pipeline makes (`content/languages/<course>/pack`, from the teachers' files by
// `tools/lang_pack.py`, built and signed by the pack builder): for each course the child opens the door, the course home offers its
// first lesson, the lesson is played to the celebration with the real lesson screen, and the answers are written as the rows the engine
// and the sync read. The packs are signed here with a throw-away key. Every clip is pending (no voice yet), as the packs say.
// Goldens of the first activity of each course on the phone and the tablet.
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

/// The first lesson of each course's pilot: its id, how many items it plays and the skill it teaches.
/// [teach] is how many teach screens a new learner is shown first (a child with no route set is one): the Russian lesson opens on the four new
/// words, each shown and said, and they write nothing.
const Map<String, ({String lesson, int items, String skill, int teach})> _first =
    <String, ({String lesson, int items, String skill, int teach})>{
      'eng': (lesson: 'eng.greet-1', items: 5, skill: 'ENG-A-01', teach: 0),
      'heb': (lesson: 'heb.words-1', items: 4, skill: 'HEB-A-02', teach: 0),
      'rus': (lesson: 'rus.greet-1', items: 3, skill: 'RUS-A-01', teach: 4),
    };

/// The teach screens of a lesson, one after the other: "I said it", then the picture. Nothing is asked and nothing is written.
Future<void> passTeachScreens(WidgetTester tester, int count) async {
  for (int i = 0; i < count; i++) {
    expect(
      find.byKey(const Key('say-picture')),
      findsOneWidget,
      reason: 'teach screen ${i + 1} is on screen',
    );
    await tester.tap(find.byKey(const Key('say-done')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('say-picture')));
    await settle(tester, ms: 3000);
  }
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
      testWidgets('from the door to the celebration, every answer written under the course', (
        WidgetTester tester,
      ) async {
        final ({String lesson, int items, String skill, int teach}) first = _first[course]!;
        final AppRig rig = await courseApp(tester, <String>[course], packs: packs);
        await openCourse(tester, course);
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(find.byKey(const Key('course-play')), findsOneWidget);
        await playPlacement(tester);
        await tester.tap(find.byKey(const Key('course-play')));
        await settle(tester);
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(tester.widget<LessonScreen>(find.byType(LessonScreen)).course, course);
        expect(find.byKey(const Key('lesson-celebration')), findsNothing);
        await passTeachScreens(tester, first.teach);
        for (int i = 0; i < first.items; i++) {
          expect(find.byKey(const Key('option-o1')), findsOneWidget, reason: 'item ${i + 1} is on screen');
          await answer(tester);
        }
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
        await tester.tap(find.byKey(const Key('lesson-done')));
        await tester.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget, reason: 'back on the course home');

        final List<Attempt> all = await rig.db.attemptsOf(courseKid);
        final List<Attempt> rows = <Attempt>[
          for (final Attempt a in all)
            if (a.lessonId == first.lesson) a,
        ];
        expect(rows, hasLength(first.items));
        expect(all.length, greaterThan(first.items), reason: 'the placement probes were answered first');
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
      });

      testWidgets(
        'a wrong touch is the diagnosed error of its distractor, never marked as a failure of the child',
        (WidgetTester tester) async {
          final AppRig rig = await courseApp(tester, <String>[course], packs: packs);
          await openCourse(tester, course);
          await playPlacement(tester);
          final int before = (await rig.db.attemptsOf(courseKid)).length;
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          await passTeachScreens(tester, _first[course]!.teach);
          await answer(tester, right: false);
          final List<Attempt> rows = (await rig.db.attemptsOf(courseKid)).skip(before).toList();
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
          await courseApp(tester, <String>[course], packs: packs, size: b.value);
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

      test('the pack plays text only: nothing is recorded, the lesson says so in its manifest', () {
        final String source = File('$_languages/$course/pack/pack.json').readAsStringSync();
        expect((jsonDecode(source) as Map<String, Object?>)['vo'], isEmpty);
        expect(packs[course]!.packVersion, '0.1.0');
      });
    });
  }
}
