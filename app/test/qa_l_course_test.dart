// ignore_for_file: curly_braces_in_flow_control_structures
// QA's own checks of the course screens (docs/milestones/L-course.md, docs/qa/l-course-verification.md): the course home measured on the four
// boards in each course's reading direction, what it shows and never shows, the way back, the microphone matrix, the merge of
// `placementVisitFor` with `placementLessonFor`, and the pieces the developer's tests do not reach. No open defect: every test runs in every build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/staircase.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/language_placement.dart';
import 'package:nitznutz/world/placement.dart' show placementIdFor;

import 'support/app_harness.dart';
import 'support/course_flow.dart';
import 'support/course_history.dart';
import 'support/course_home_model.dart';
import 'support/course_packs.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show boards;

Future<void> _view(
  WidgetTester t,
  String course,
  CourseHomeModel? model,
  Size size, {
  bool play = true,
}) async {
  t.view.devicePixelRatio = 1;
  await pumpScreen(
    t,
    CourseHomeView(course: course, model: model, onPlay: play ? () {} : null),
    size: size,
  );
  await t.pumpAndSettle();
}

CourseHomeModel _withTitle(CourseHomeModel m, String title) => CourseHomeModel(
  course: m.course,
  stones: <PathStone>[
    for (final PathStone s in m.stones)
      PathStone(
        lessonId: s.lessonId,
        title: s.number == m.nextIndex + 1 ? title : s.title,
        number: s.number,
        state: s.state,
      ),
  ],
  nextIndex: m.nextIndex,
  stop: m.stop,
  placementDue: m.placementDue,
);

void main() {
  setUpAll(loadAppFonts);

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the course home measured on the four boards, in each course\'s direction', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      for (final String course in <String>['eng', 'heb', 'rus']) {
        testWidgets(
          '${b.key} $course: touches are at least 64 pt, everything is on the board, the path runs the course\'s way',
          (WidgetTester t) async {
            final Rect board = Offset.zero & b.value;
            // a path with a done stone, a placed stone, the next and later ones
            await _view(t, course, modelOf(course, done: <int>{0}, placed: <int>{1}), b.value);
            final Size play = t.getSize(find.byKey(const Key('course-play')));
            expect(play.width, greaterThanOrEqualTo(64), reason: 'the pebble is the one control of the path');
            expect(
              t.getSize(find.byKey(const Key('course-back'))).shortestSide,
              greaterThanOrEqualTo(64),
              reason: 'the way back',
            );
            for (final String k in <String>[
              'course-host',
              'course-play',
              'course-back',
              'course-next-title',
            ]) {
              final Rect r = t.getRect(find.byKey(Key(k)));
              expect(
                board.inflate(0.5).contains(r.topLeft) && board.inflate(0.5).contains(r.bottomRight),
                isTrue,
                reason: '$k $r on the board',
              );
            }
            final Rect title = t.getRect(find.byKey(const Key('course-next-title')));
            expect(
              title.overlaps(t.getRect(find.byKey(const Key('course-play'))).deflate(12)),
              isFalse,
              reason: 'the title stands under the pebble',
            );
            // the stones: 1 done, 2 placed (no key for the next), 4 and 5 later; a lower number is nearer the course's start
            final bool rtl = course == 'heb';
            final double s1 = t.getCenter(find.byKey(const Key('stone-1'))).dx;
            final double s2 = t.getCenter(find.byKey(const Key('stone-2'))).dx;
            final double p = t.getCenter(find.byKey(const Key('course-next'))).dx;
            final double s4 = t.getCenter(find.byKey(const Key('stone-4'))).dx;
            if (rtl) {
              expect(s1 > s2 && s2 > p && p > s4, isTrue, reason: 'Hebrew: from the right: $s1 $s2 $p $s4');
            } else {
              expect(s1 < s2 && s2 < p && p < s4, isTrue, reason: '$course: from the left: $s1 $s2 $p $s4');
            }
            expect(
              (p - b.value.width / 2).abs(),
              lessThan(2),
              reason: 'the next stone opens in the middle of the board',
            );
            // a number is a digit and reads left to right in every course
            expect(find.text('4'), findsOneWidget);
            expect(
              Directionality.of(t.element(find.text('4'))),
              TextDirection.ltr,
              reason: 'digits never mirror',
            );
          },
        );
      }
    }
  });

  group('what the home shows and never shows', () {
    testWidgets(
      'after the placement is over the home says nothing about it: no level, no score, no word of result',
      (WidgetTester t) async {
        await _view(t, 'eng', modelOf('eng', done: <int>{0, 1}), boards['phone']!);
        final List<String> texts = <String>[
          for (final Text w in t.widgetList<Text>(find.byType(Text)))
            w.data ?? w.textSpan?.toPlainText() ?? '',
        ];
        // digits of the stones and the title of the next lesson, nothing else
        for (final String s in texts) {
          final bool digit = RegExp(r'^\d+$').hasMatch(s);
          final bool title = s == modelOf('eng', done: <int>{0, 1}).next!.title;
          expect(digit || title, isTrue, reason: 'unexpected text on the home: "$s"');
        }
      },
    );

    testWidgets('the invitation is the only words on a first visit, and there is no title or bell', (
      WidgetTester t,
    ) async {
      await _view(t, 'rus', modelOf('rus', placementDue: true), boards['phoneSE']!);
      expect(find.byKey(const Key('course-invite')), findsOneWidget);
      expect(find.byKey(const Key('course-next-title')), findsNothing);
      expect(find.byKey(const Key('course-bell')), findsNothing);
    });

    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '${b.key}: a course with no model (not installed) shows the host alone and no pebble; one with no lesson, no strip',
        (WidgetTester t) async {
          await _view(t, 'heb', null, b.value);
          expect(find.byKey(const Key('course-host')), findsOneWidget);
          expect(find.byKey(const Key('course-play')), findsNothing);
          expect(find.byKey(const Key('course-back')), findsOneWidget);
          final CourseHomeModel m = modelOf('heb');
          await _view(
            t,
            'heb',
            CourseHomeModel(
              course: 'heb',
              stones: const <PathStone>[],
              nextIndex: -1,
              stop: m.stop,
              placementDue: false,
            ),
            b.value,
          );
          expect(find.byKey(const Key('course-path')), findsNothing);
          expect(t.takeException(), isNull);
        },
      );
    }

    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '${b.key}: a long lesson title stays on the board (two lines of the Hebrew title with niqqud)',
        (WidgetTester t) async {
          const String longTitle = 'חֲבֵרִים וּמִשְׁפָּחָה וְחַיּוֹת בַּגִּנָּה הַגְּדוֹלָה שֶׁלָּנוּ';
          await _view(t, 'eng', _withTitle(modelOf('eng', done: <int>{0}), longTitle), b.value);
          expect(find.text(longTitle), findsOneWidget);
          final Rect title = t.getRect(find.byKey(const Key('course-next-title')));
          expect(
            title.bottom,
            lessThanOrEqualTo(b.value.height),
            reason: 'the title $title runs off the board ${b.value.height}',
          );
          expect(title.left, greaterThanOrEqualTo(0));
          expect(title.right, lessThanOrEqualTo(b.value.width));
        },
      );
    }
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the way back from the home', () {
    testWidgets('one language on: back is the map; several: back is the doors', (WidgetTester t) async {
      await courseApp(t, <String>['eng']);
      await openCourse(t, 'eng');
      await t.tap(find.byKey(const Key('course-back')));
      await t.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      await t.pumpWidget(const SizedBox());
      await courseApp(t, <String>['eng', 'rus']);
      await openCourse(t, 'eng', doors: true);
      await t.tap(find.byKey(const Key('course-back')));
      await t.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsNothing);
      expect(find.byKey(const Key('door-eng')), findsOneWidget, reason: 'the doors again');
      expect(find.byKey(const Key('door-rus')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the microphone in a course: the app\'s switch and the language\'s own, both ways', () {
    Map<String, PackContent> voiced() {
      final p = courseFixture('eng');
      p.activity('hi_mika_arrive')['voiceAnswer'] = true;
      return <String, PackContent>{'eng': p.content};
    }

    Future<void> placed(AppRig rig) => writePlacement(rig.db, courseContent('eng'), const <(String, bool)>[
      ('pr_hello_1', false),
      ('pr_hello_2', false),
    ], at: DateTime.utc(2026, 10, 27, 9));

    testWidgets('the language\'s voice on but the app\'s voice off: no microphone', (WidgetTester t) async {
      await courseApp(
        t,
        <String>['eng'],
        voice: false,
        packs: voiced(),
        history: placed,
        switches: const <String, LanguageSwitches>{'eng': LanguageSwitches(on: true, voice: true)},
      );
      await openCourse(t, 'eng');
      await t.tap(find.byKey(const Key('course-play')));
      await settle(t);
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.byKey(const Key('lesson-mic')), findsNothing);
    });

    test(
      'a language starts with its voice off (frame 1.4: off until a parent turns it on for that language)',
      () {
        expect(const LanguageSwitches().voice, isFalse);
        expect(const LanguageSwitches(on: true).voice, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the daily limit passing during a course lesson', () {
    testWidgets(
      'ends it gently after the activity (reason "limit", not finished), the home is back and the lesson is still next',
      (WidgetTester t) async {
        final AppRig rig = await courseApp(
          t,
          <String>['eng'],
          clockMs: DateTime(2026, 10, 28, 12).millisecondsSinceEpoch,
          history: (AppRig r) => writePlacement(r.db, courseContent('eng'), const <(String, bool)>[
            ('pr_hello_1', false),
            ('pr_hello_2', false),
          ], at: DateTime.utc(2026, 10, 27, 9)),
          rules: const ParentRules(limitByChild: <String, int>{courseKid: 5}),
        );
        await openCourse(t, 'eng');
        await t.tap(find.byKey(const Key('course-play')));
        await settle(t);
        expect(find.byType(LessonScreen), findsOneWidget);
        rig.clock.advance(const Duration(minutes: 6));
        await answer(t);
        expect(find.text(He.restGoodbye.text), findsWidgets, reason: 'the guide says goodbye');
        final Session visit = (await rig.db.sessionsOf(courseKid)).last;
        expect(visit.plan, startsWith('lesson:eng.'));
        expect(visit.endReason, 'limit');
        await t.tap(find.byKey(const Key('lesson-done')));
        await t.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(
          find.byIcon(Icons.star_rounded),
          findsNothing,
          reason: 'a cut lesson is not a finished one, and nothing says so',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('placementVisitFor after the merge: null exactly when placementLessonFor is', () {
    Future<(AppRig, List<Attempt>)> history(List<(String, bool)> probes) async {
      final AppRig rig = AppRig()..languagePacks = fixturePacks(const <String>['eng']);
      await rig.seedFinishedSetup(id: courseKid, ageBand: 0);
      addTearDown(rig.db.close);
      if (probes.isNotEmpty)
        await writePlacement(rig.db, courseContent('eng'), probes, at: DateTime.utc(2026, 10, 27, 9));
      return (rig, await rig.db.attemptsOf(courseKid));
    }

    test('a child who has not begun gets a visit of the course\'s placement id whose first probe is the game\'s next, and asking twice moves nothing', () async {
      final PackContent eng = courseContent('eng');
      final (AppRig rig, List<Attempt> attempts) = await history(const <(String, bool)>[]);
      final String? next = placementGameFor(eng, attempts)!.next();
      final v1 = placementVisitFor(eng, attempts);
      final v2 = placementVisitFor(eng, attempts);
      expect(v1, isNotNull);
      expect(v1!.lesson.id, placementIdFor('eng'));
      expect(v1.lesson.itemIds, <String>[next!]);
      expect(
        v2!.lesson.itemIds,
        v1.lesson.itemIds,
        reason: 'building a visit does not advance the staircase',
      );
      expect(v1.flow.due, isTrue);
      expect(rig.db, isNotNull);
    });

    test('a finished placement: no visit, and the lesson builder says no too', () async {
      final PackContent eng = courseContent('eng');
      final (AppRig _, List<Attempt> attempts) = await history(const <(String, bool)>[
        ('pr_hello_1', false),
        ('pr_hello_2', false),
      ]);
      final PlacementGame game = placementGameFor(eng, attempts)!;
      expect(game.complete, isTrue);
      expect(placementVisitFor(eng, attempts), isNull);
      expect(placementLessonFor(eng, PlacementFlow(game, eng.placement!)), isNull);
    });

    test('a visit cut after one answer goes on: the next visit starts where the staircase stands', () async {
      final PackContent eng = courseContent('eng');
      final (AppRig _, List<Attempt> attempts) = await history(const <(String, bool)>[('pr_hello_1', true)]);
      final v = placementVisitFor(eng, attempts);
      expect(v, isNotNull);
      expect(v!.lesson.itemIds.single, isNot('pr_hello_1'), reason: 'an answered probe is never asked twice');
      expect(v.flow.game.stairs('o')!.stopped, isFalse);
    });
  });
}
