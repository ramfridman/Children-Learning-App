// Today's Adventure opening a language stop (L-course, part 7), in the real app: the bottle in the child's home chooses the course, the course
// home opens and starts the stop at once (the placement visit first when it is due, as a land's warm-up goes first), the guards of a visit
// apply, and when the visit is over the child is on the course home, with the way back to the home. The route stack is the bottle's.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/course_visit.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/world/adventure_land.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/app_harness.dart';
import 'support/bottle.dart';
import 'support/course_flow.dart';
import 'support/course_history.dart';
import 'support/course_home_model.dart';
import 'support/course_packs.dart';
import 'support/harness.dart';

final DateTime _placementDay = DateTime.utc(2026, 10, 24, 9);
final DateTime _lessonDay = DateTime.utc(2026, 10, 25, 9);

/// The placement over (two misses at the floor) and the first lesson of English finished: the bottle's next stop is English.
Future<void> _inEnglish(AppRig rig) async {
  await writePlacement(rig.db, courseContent('eng'), const <(String, bool)>[
    ('pr_hello_1', false),
    ('pr_hello_2', false),
  ], at: _placementDay);
  await writeFinishedLesson(rig.db, courseContent('eng'), 'eng.hello_1', at: _lessonDay);
}

/// English has been played, but the placement visit has not: the first stop the bottle opens there is the placement.
Future<void> _inEnglishUnplaced(AppRig rig) =>
    writeFinishedLesson(rig.db, courseContent('eng'), 'eng.hello_1', at: _lessonDay);

Future<void> _toBottle(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-pill')));
  await tester.pumpAndSettle();
  expect(find.byType(HomeIslandScreen), findsOneWidget);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'the bottle opens the course home and starts the next lesson of the course there; when it is over the child is on the home',
    (WidgetTester tester) async {
      final AppRig rig = await courseApp(tester, <String>['eng'], history: _inEnglish);
      await _toBottle(tester);
      await tapBottleAndWait(tester);
      final LessonScreen visit = tester.widget<LessonScreen>(find.byType(LessonScreen));
      expect(visit.course, 'eng');
      expect(visit.lessonId, 'eng.hello_2', reason: 'the next lesson after the one finished');
      expect(
        find.byType(CourseHomeScreen, skipOffstage: false),
        findsOneWidget,
        reason: 'the home is under the lesson',
      );
      for (int i = 0; i < 3; i++) {
        await answer(tester);
      }
      expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
      await tester.tap(find.byKey(const Key('lesson-done')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('stone-2')), matching: find.byIcon(Icons.star_rounded)),
        findsOneWidget,
        reason: 'the second lesson is done',
      );
      expect((await rig.db.sessionsOf(courseKid)).last.plan, 'lesson:eng.hello_2');
      await tester.tap(find.byKey(const Key('course-back')));
      await tester.pumpAndSettle();
      expect(
        find.byType(HomeIslandScreen),
        findsOneWidget,
        reason: 'back to the child\'s home, where the bottle is',
      );
    },
  );

  testWidgets('the bottle plays the stop only once, however the child comes back to the home', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await courseApp(tester, <String>['eng'], history: _inEnglish);
    await _toBottle(tester);
    await tapBottleAndWait(tester);
    await tester.tap(find.byKey(const Key('activity-home')));
    await tester.pumpAndSettle();
    expect(find.byType(CourseHomeScreen), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing, reason: 'leaving the lesson does not start another');
    expect(
      (await rig.db.sessionsOf(courseKid)).where((s) => s.plan.startsWith('lesson:eng.hello_2')),
      hasLength(1),
    );
  });

  testWidgets(
    'while the placement is due it goes first, as a land\'s warm-up does, and the host invites when the child comes back',
    (WidgetTester tester) async {
      await courseApp(tester, <String>['eng'], history: _inEnglishUnplaced);
      await _toBottle(tester);
      await tapBottleAndWait(tester);
      final LessonScreen visit = tester.widget<LessonScreen>(find.byType(LessonScreen));
      expect(visit.course, 'eng');
      expect(visit.mission!.id, 'placement-eng');
      expect(visit.flow, isNotNull);
      expect(find.byKey(const Key('lesson-hint')), findsNothing, reason: 'a probe has no lamp');
      await tester.tap(find.byKey(const Key('activity-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-invite')), findsOneWidget);
    },
  );

  testWidgets('in rest hours the bottle opens the home and the rest scene shows instead of the visit', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await courseApp(
      tester,
      <String>['eng'],
      history: _inEnglish,
      clockMs: DateTime(2026, 10, 28, 22).millisecondsSinceEpoch,
    );
    await _toBottle(tester);
    await tester.tap(find.byKey(const Key('home-island-bottle')));
    for (int i = 0; i < 80 && find.byKey(const Key('rest-scene')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-scene')), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);
    expect((await rig.db.sessionsOf(courseKid)).length, 2, reason: 'only the visits of the history');
  });

  group('the kinds of stop', () {
    /// Starts [stop] of English from a button on a screen of its own, over the real providers.
    Future<void> start(WidgetTester tester, TodaysAdventure stop) async {
      await courseApp(tester, <String>['eng'], history: _inEnglish);
      final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      final CourseHomeModel model = modelOf('eng');
      nav.push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => Consumer(
            builder: (BuildContext c, WidgetRef ref, Widget? _) => TextButton(
              key: const Key('go'),
              onPressed: () =>
                  startCourseVisit(c, ref, childId: courseKid, course: 'eng', model: model, stop: stop),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('go')));
      await settle(tester);
    }

    testWidgets('a call for help opens a revisit mission of the course\'s own items', (
      WidgetTester tester,
    ) async {
      await start(tester, const TodaysAdventure.revisit(LanguageLand('eng'), 'ENG-A-03'));
      final LessonScreen visit = tester.widget<LessonScreen>(find.byType(LessonScreen));
      expect(visit.course, 'eng');
      expect(visit.mission!.id, 'mission-eng-a-03');
      expect(visit.mission!.itemIds.every((String id) => id.startsWith('eng.')), isTrue);
    });

    testWidgets('a lesson to play again opens that lesson', (WidgetTester tester) async {
      await start(tester, const TodaysAdventure.replay(LanguageLand('eng'), 'eng.hello_1'));
      final LessonScreen visit = tester.widget<LessonScreen>(find.byType(LessonScreen));
      expect(visit.lessonId, 'eng.hello_1');
      expect(visit.mission, isNull);
    });
  });
}
