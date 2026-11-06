// The guards of the child space on a course visit (L-course, part 5): the parent's time rules (rest hours, the daily limit, the lock), a
// language that was switched off while the home was open, and the microphone, which a language course opens only when the parent turned
// voice on for that language. The doors and the home stay open in rest hours, as the lands' map and islands do; the visit does not start.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/course_flow.dart';
import 'support/course_history.dart';
import 'support/course_packs.dart';
import 'support/harness.dart';

int _at(int hour, [int minute = 0]) => DateTime(2026, 10, 28, hour, minute).millisecondsSinceEpoch;

/// A placement visit already played (two misses at the floor): the placement is over and the pebble opens the first lesson.
Future<void> _placed(AppRig rig) => writePlacement(rig.db, courseContent('eng'), const <(String, bool)>[
  ('pr_hello_1', false),
  ('pr_hello_2', false),
], at: DateTime.utc(2026, 10, 27, 9));

/// No visit was started beyond the [before] that the history wrote.
Future<void> _noVisit(AppRig rig, {int before = 0}) async {
  expect(find.byType(LessonScreen), findsNothing);
  expect((await rig.db.sessionsOf(courseKid)).length, before, reason: 'no visit was started');
}

void main() {
  setUpAll(loadAppFonts);

  group('rest hours', () {
    testWidgets(
      'the home opens, the pebble shows the rest scene instead of the placement visit, and back comes to the home',
      (WidgetTester tester) async {
        final AppRig rig = await courseApp(tester, <String>['eng'], clockMs: _at(22));
        await openCourse(tester, 'eng');
        expect(
          find.byKey(const Key('course-invite')),
          findsOneWidget,
          reason: 'the home itself is open, as a land island is',
        );
        await tester.tap(find.byKey(const Key('course-play')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('rest-scene')), findsOneWidget);
        expect(find.text(He.restScene.text), findsOneWidget);
        await _noVisit(rig);
        expect(await rig.db.attemptsOf(courseKid), isEmpty);
        await tester.tap(find.bySemanticsLabel(He.restBackSemantics.text));
        await tester.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        await tester.tap(find.byKey(const Key('course-play')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('rest-scene')),
          findsOneWidget,
          reason: 'and again, as often as the child asks',
        );
      },
    );

    testWidgets('the same for a lesson, and through the doors', (WidgetTester tester) async {
      final AppRig rig = await courseApp(tester, <String>['eng', 'rus'], clockMs: _at(22), history: _placed);
      await openCourse(tester, 'eng', doors: true);
      await tester.tap(find.byKey(const Key('course-play')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rest-scene')), findsOneWidget);
      await _noVisit(rig, before: 1); // the placement visit that the history wrote
    });

    testWidgets('with the lock off, rest hours do not stop the child', (WidgetTester tester) async {
      await courseApp(
        tester,
        <String>['eng'],
        clockMs: _at(22),
        history: _placed,
        rules: const ParentRules(lockWhenDone: false),
      );
      await openCourse(tester, 'eng');
      await tester.tap(find.byKey(const Key('course-play')));
      await settle(tester);
      expect(find.byKey(const Key('rest-scene')), findsNothing);
      expect(find.byType(LessonScreen), findsOneWidget);
    });

    testWidgets('at noon with time left, the visit starts as usual', (WidgetTester tester) async {
      await courseApp(tester, <String>['eng'], clockMs: _at(12), history: _placed);
      await openCourse(tester, 'eng');
      await tester.tap(find.byKey(const Key('course-play')));
      await settle(tester);
      expect(find.byType(LessonScreen), findsOneWidget);
    });
  });

  group('the daily limit', () {
    testWidgets(
      'time played today in any course or land counts: with it used up, a course visit does not start',
      (WidgetTester tester) async {
        final AppRig rig = await courseApp(
          tester,
          <String>['eng'],
          clockMs: _at(12),
          history: (AppRig rig) async {
            await _placed(rig);
            final int s = await rig.db.startSession(
              courseKid,
              DateTime(2026, 10, 28, 9),
              plan: 'lesson:butterflies',
            );
            await rig.db.endSession(s, DateTime(2026, 10, 28, 9, 50), 'finished');
          },
          rules: const ParentRules(limitByChild: <String, int>{courseKid: 20}),
        );
        await openCourse(tester, 'eng');
        await tester.tap(find.byKey(const Key('course-play')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('rest-scene')), findsOneWidget);
        await _noVisit(rig, before: 2);
      },
    );
  });

  group('a language that is switched off', () {
    testWidgets('while its home is open, nothing starts and nothing is written', (WidgetTester tester) async {
      final AppRig rig = await courseApp(tester, <String>['eng'], history: _placed);
      await openCourse(tester, 'eng');
      final ProviderContainer c = ProviderScope.containerOf(tester.element(find.byType(CourseHomeScreen)));
      await c.read(languagesProvider.notifier).setSwitches(courseKid, 'eng', const LanguageSwitches());
      await tester.tap(find.byKey(const Key('course-play')));
      await settle(tester);
      expect(find.byKey(const Key('rest-scene')), findsNothing);
      await _noVisit(rig, before: 1);
    });
  });

  group('the microphone in a course', () {
    /// The English pack with its first lesson's first item answered by voice (the flag a pack may carry; set here, not validated).
    Map<String, PackContent> voiced() {
      final p = courseFixture('eng');
      p.activity('hi_mika_arrive')['voiceAnswer'] = true;
      return <String, PackContent>{'eng': p.content};
    }

    for (final (bool languageVoice, bool mic) in <(bool, bool)>[(false, false), (true, true)]) {
      testWidgets(
        'voice on for the app and ${languageVoice ? 'on' : 'off'} for English: the mic ${mic ? 'is' : 'is not'} there',
        (WidgetTester tester) async {
          await courseApp(
            tester,
            <String>['eng'],
            voice: true,
            packs: voiced(),
            history: _placed,
            switches: <String, LanguageSwitches>{'eng': LanguageSwitches(on: true, voice: languageVoice)},
          );
          await openCourse(tester, 'eng');
          await tester.tap(find.byKey(const Key('course-play')));
          await settle(tester);
          expect(find.byType(LessonScreen), findsOneWidget);
          expect(find.byKey(const Key('lesson-mic')), mic ? findsOneWidget : findsNothing);
        },
      );
    }
  });
}
