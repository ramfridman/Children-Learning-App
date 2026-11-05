// Starting a visit from the course home (L-course, part 3): the placement visit while the host invites, then a lesson of the course on the
// lesson screen, the celebration, and the child back on the home with the path moved on. A revisit mission is the course's own. The real
// app over the fixture packs and a real in-memory database.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/app/language_providers.dart' show languageCourseOf;
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/language_placement.dart';

import 'support/app_harness.dart';
import 'support/course_flow.dart';
import 'support/course_history.dart';
import 'support/course_packs.dart';
import 'support/fake_tutor.dart';
import 'support/harness.dart';
import 'support/sample_pack.dart';

/// A child who missed the first two probes: the placement is over, the path starts at the beginning.
Future<void> _placedAtTheStart(AppRig rig) => writePlacement(rig.db, courseContent('eng'), <(String, bool)>[
  ('pr_hello_1', false),
  ('pr_hello_2', false),
], at: DateTime.utc(2026, 11, 3, 9));

void main() {
  setUpAll(loadAppFonts);

  group('the placement visit', () {
    testWidgets(
      'the pebble starts it while the host invites: probes without help, from the staircase, under the placement lesson',
      (WidgetTester tester) async {
        final AppRig rig = await courseApp(tester, <String>['eng']);
        await openCourse(tester, 'eng');
        expect(find.byKey(const Key('course-invite')), findsOneWidget);
        await tester.tap(find.byKey(const Key('course-play')));
        await settle(tester);
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(tester.widget<LessonScreen>(find.byType(LessonScreen)).course, 'eng');
        expect(find.byKey(const Key('lesson-hint')), findsNothing, reason: 'a probe has no lamp');
        expect(find.byKey(const Key('lesson-show-me')), findsNothing);
        await answer(tester, right: false);
        await answer(tester, right: false);
        // two misses at the floor end the strand, so the visit ends on its own line
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
        final List<Attempt> rows = await rig.db.attemptsOf(courseKid);
        expect(rows.map((Attempt a) => a.activityId), <String>['eng.pr_hello_1', 'eng.pr_hello_2']);
        expect(rows.every((Attempt a) => a.lessonId == 'placement-eng' && a.packId == 'lang-eng'), isTrue);
        await tester.tap(find.byKey(const Key('lesson-done')));
        await tester.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget, reason: 'back on the home');
        expect(
          find.byKey(const Key('course-invite')),
          findsNothing,
          reason: 'the placement is over: no more invitation',
        );
        expect(
          find.byKey(const Key('course-next-title')),
          findsOneWidget,
          reason: 'the pebble now opens the first lesson',
        );
        final List<Session> visits = await rig.db.sessionsOf(courseKid);
        expect(visits.single.plan, startsWith('mission:'));
        expect(visits.single.endReason, 'finished');
      },
    );

    testWidgets(
      'a visit left in the middle leaves the host inviting, and the next visit goes on from the answers given',
      (WidgetTester tester) async {
        final AppRig rig = await courseApp(tester, <String>['eng']);
        await openCourse(tester, 'eng');
        await tester.tap(find.byKey(const Key('course-play')));
        await settle(tester);
        await answer(tester);
        await tester.tap(find.byKey(const Key('activity-home')));
        await tester.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(
          find.byKey(const Key('course-invite')),
          findsOneWidget,
          reason: 'one probe is not a placement',
        );
        await tester.tap(find.byKey(const Key('course-play')));
        await settle(tester);
        expect(find.byType(LessonScreen), findsOneWidget);
        final LessonScreen screen = tester.widget<LessonScreen>(find.byType(LessonScreen));
        expect(
          screen.mission!.itemIds.single,
          'eng.pr_hello_2',
          reason: 'the second probe: the first was answered',
        );
        expect((await rig.db.attemptsOf(courseKid)), hasLength(1));
      },
    );
  });

  group('a lesson of the course', () {
    testWidgets(
      'is played on the lesson screen from the course\'s own pack, ends on its celebration, and the home has moved on',
      (WidgetTester tester) async {
        final AppRig rig = await courseApp(tester, <String>['eng'], history: _placedAtTheStart);
        await openCourse(tester, 'eng');
        expect(find.byKey(const Key('course-invite')), findsNothing);
        expect(find.text('בְּרָכוֹת'), findsOneWidget, reason: 'the next lesson\'s title, from the pack');
        await tester.tap(find.byKey(const Key('course-play')));
        await settle(tester);
        final LessonScreen screen = tester.widget<LessonScreen>(find.byType(LessonScreen));
        expect(screen.course, 'eng');
        expect(screen.lessonId, 'eng.hello_1');
        for (int i = 0; i < 3; i++) {
          expect(find.byKey(const Key('lesson-celebration')), findsNothing);
          await answer(tester);
        }
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
        expect(
          find.text('לְהִתְרָאוֹת! הָיָה כֵּיף לְשַׂחֵק בְּאַנְגְּלִית.'),
          findsOneWidget,
          reason: 'the course\'s own celebration',
        );
        await tester.tap(find.byKey(const Key('lesson-done')));
        await tester.pumpAndSettle();
        expect(find.byType(LessonScreen), findsNothing);
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(const Key('stone-1')), matching: find.byIcon(Icons.star_rounded)),
          findsOneWidget,
          reason: 'the lesson is done',
        );
        expect(find.text('בְּרָכוֹת שׁוּב'), findsOneWidget, reason: 'the next stone is the next lesson');
        final List<Session> visits = await rig.db.sessionsOf(courseKid);
        expect(visits.last.plan, 'lesson:eng.hello_1');
        expect(visits.last.endReason, 'finished');
        final Iterable<Attempt> played = (await rig.db.attemptsOf(courseKid))
            .where((Attempt a) => a.lessonId == 'eng.hello_1');
        expect(played, hasLength(3));
        expect(played.every((Attempt a) => a.packId == 'lang-eng' && a.result == 'correct'), isTrue);
      },
    );

    testWidgets('leaving it half way is no debt: the lesson is still next, and nothing says so', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await courseApp(tester, <String>['eng'], history: _placedAtTheStart);
      await openCourse(tester, 'eng');
      await tester.tap(find.byKey(const Key('course-play')));
      await settle(tester);
      await answer(tester);
      await tester.tap(find.byKey(const Key('activity-home')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('בְּרָכוֹת'), findsOneWidget);
      expect((await rig.db.sessionsOf(courseKid)).last.endReason, 'home');
    });

    testWidgets('a second touch of the pebble while a visit is on screen starts nothing', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await courseApp(tester, <String>['eng'], history: _placedAtTheStart);
      await openCourse(tester, 'eng');
      final Finder play = find.byKey(const Key('course-play'));
      await tester.tap(play);
      await tester.tap(play, warnIfMissed: false);
      await settle(tester);
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(
        (await rig.db.sessionsOf(courseKid)).where((Session s) => s.plan.startsWith('lesson:')),
        hasLength(1),
      );
    });

    testWidgets('no tutor line is ever asked in a course visit, even after mistakes', (
      WidgetTester tester,
    ) async {
      final FakeTutorClient tutor = FakeTutorClient();
      await courseApp(tester, <String>['eng'], history: _placedAtTheStart, tutor: tutor);
      await openCourse(tester, 'eng');
      await tester.tap(find.byKey(const Key('course-play')));
      await settle(tester);
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('option-o2')));
        await settle(tester, ms: 2500);
      }
      expect(tutor.asked, isEmpty, reason: 'RuleTutor only: a language item never reaches the model');
    });
  });

  group('the pack of the lesson', () {
    testWidgets(
      'a lesson screen of a course reads that course\'s pack, and one whose pack is missing says the lesson is not ready',
      (WidgetTester tester) async {
        final AppRig rig = await courseApp(tester, <String>['eng']);
        final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) =>
                const LessonScreen(profileId: courseKid, course: 'rus', lessonId: 'rus.animals_1'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('lesson-unavailable')), findsOneWidget);
        expect(await rig.db.attemptsOf(courseKid), isEmpty);
      },
    );
  });

  group('a revisit mission of the course', () {
    test('is built from the course\'s own items and engine, and ends on a line of the course', () {
      final PackContent pack = courseContent('eng');
      final LanguageCourse c = languageCourseOf(pack, const <Attempt>[], const LanguageSwitches(on: true), 0);
      final Lesson? m = courseMission(c, 'ENG-A-03');
      expect(m, isNotNull);
      expect(m!.id, 'mission-eng-a-03');
      expect(m.course, 'eng');
      expect(m.itemIds, isNotEmpty);
      expect(
        m.itemIds.every((String id) => id.startsWith('eng.') && pack.activities[id]!.skillId == 'ENG-A-03'),
        isTrue,
      );
      expect(m.itemIds.any((String id) => id.contains('pr_')), isFalse, reason: 'a probe is never a check');
      expect(m.celebration.vo, 'vo:eng.colours_1.done');
      expect(courseMission(c, 'ENG-X-99'), isNull);
    });

    test('the next placement visit is null when the placement is over, and starts from the first probe otherwise', () {
      final PackContent pack = courseContent('eng');
      final v = placementVisitFor(pack, const <Attempt>[]);
      expect(v, isNotNull);
      expect(v!.lesson.id, 'placement-eng');
      expect(v.lesson.itemIds.single, 'eng.pr_hello_1');
      expect(v.flow.first(), 'eng.pr_hello_1');
      final PackContent plain = PackContent.fromPack(SamplePack.language('eng').verified());
      expect(placementVisitFor(plain, const <Attempt>[]), isNull);
    });
  });
}
