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
const Map<String, ({String lesson, int items, String skill})> _first =
    <String, ({String lesson, int items, String skill})>{
      'eng': (lesson: 'eng.greet-1', items: 5, skill: 'ENG-A-01'),
      'heb': (lesson: 'heb.words-1', items: 4, skill: 'HEB-A-02'),
      'rus': (lesson: 'rus.greet-1', items: 3, skill: 'RUS-A-01'),
    };

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
        final ({String lesson, int items, String skill}) first = _first[course]!;
        final AppRig rig = await courseApp(tester, <String>[course], packs: packs);
        await openCourse(tester, course);
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(find.byKey(const Key('course-play')), findsOneWidget);
        await tester.tap(find.byKey(const Key('course-play')));
        await settle(tester);
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(tester.widget<LessonScreen>(find.byType(LessonScreen)).course, course);
        expect(find.byKey(const Key('lesson-celebration')), findsNothing);
        for (int i = 0; i < first.items; i++) {
          expect(find.byKey(const Key('option-o1')), findsOneWidget, reason: 'item ${i + 1} is on screen');
          await answer(tester);
        }
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
        await tester.tap(find.byKey(const Key('lesson-done')));
        await tester.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget, reason: 'back on the course home');

        final List<Attempt> rows = await rig.db.attemptsOf(courseKid);
        expect(rows, hasLength(first.items));
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
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          await answer(tester, right: false);
          final List<Attempt> rows = await rig.db.attemptsOf(courseKid);
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
