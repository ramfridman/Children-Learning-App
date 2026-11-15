// The course home (L-course): the host, the path in the reading direction of the course, the invitation to the first visit, the one big
// pebble, and the way back. The view over fixed models, and the app's doors and map opening it over the fixture packs.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/languages_doors.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/course_flow.dart' show knowsALittle;
import 'support/course_history.dart';
import 'support/course_home_model.dart';
import 'support/course_packs.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show boards;

Future<void> _view(
  WidgetTester tester,
  String course,
  Size size, {
  bool placementDue = false,
  bool revisit = false,
  Set<int> done = const <int>{},
  Set<int> placed = const <int>{},
  VoidCallback? onPlay,
}) async {
  await pumpScreen(
    tester,
    CourseHomeView(
      course: course,
      model: modelOf(course, placementDue: placementDue, revisit: revisit, done: done, placed: placed),
      onPlay: onPlay,
    ),
    size: size,
  );
  await tester.pumpAndSettle();
}

double _x(WidgetTester tester, String key) => tester.getCenter(find.byKey(Key(key))).dx;

void main() {
  setUpAll(loadAppFonts);

  group('the view', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '${b.key}: the host, the path and the pebble are on the board, the invitation only when due',
        (WidgetTester tester) async {
          await _view(tester, 'eng', b.value, placementDue: true, onPlay: () {});
          expect(find.byKey(const Key('course-host')), findsOneWidget);
          expect(find.byKey(const Key('course-path')), findsOneWidget);
          expect(find.byKey(const Key('course-play')), findsOneWidget);
          expect(find.byKey(const Key('course-invite')), findsOneWidget);
          expect(find.text(He.courseInvite.text), findsOneWidget);
          expect(find.byKey(const Key('course-bell')), findsNothing);
          expect(
            find.byKey(const Key('course-next-title')),
            findsNothing,
            reason: 'the pebble starts a visit, not a lesson',
          );
          expect(tester.takeException(), isNull);

          await _view(tester, 'eng', b.value, onPlay: () {});
          expect(find.byKey(const Key('course-invite')), findsNothing);
          expect(find.byKey(const Key('course-next-title')), findsOneWidget);
        },
      );
    }

    testWidgets(
      'the path runs in the reading direction of the course: Hebrew from the right, English and Russian from the left',
      (WidgetTester tester) async {
        for (final (String course, bool rtl) in <(String, bool)>[
          ('heb', true),
          ('eng', false),
          ('rus', false),
        ]) {
          // two stones behind the child, the third is next: stones 1 and 2 are on screen, with the pebble between them and the rest
          await _view(tester, course, const Size(852, 393), done: <int>{0, 1}, onPlay: () {});
          final double one = _x(tester, 'stone-1');
          final double two = _x(tester, 'stone-2');
          final double pebble = _x(tester, 'course-play');
          final double four = _x(tester, 'stone-4');
          if (rtl) {
            expect(one, greaterThan(two), reason: '$course starts at the right');
            expect(two, greaterThan(pebble));
            expect(pebble, greaterThan(four));
          } else {
            expect(one, lessThan(two), reason: '$course starts at the left');
            expect(two, lessThan(pebble));
            expect(pebble, lessThan(four));
          }
          expect(pebble, closeTo(426, 1), reason: 'the next stone is in the middle');
        }
      },
    );

    testWidgets('the numbers of the stones are digits that read left to right whatever the course', (
      WidgetTester tester,
    ) async {
      await _view(tester, 'heb', const Size(852, 393), onPlay: () {});
      final Text four = tester.widget<Text>(
        find.descendant(of: find.byKey(const Key('stone-4')), matching: find.byType(Text)),
      );
      expect(four.data, '4');
      final Directionality d = tester.widget<Directionality>(
        find.ancestor(of: find.byWidget(four), matching: find.byType(Directionality)).first,
      );
      expect(d.textDirection, TextDirection.ltr);
    });

    testWidgets('a stone is done, placed or further on, and none of them is a button', (
      WidgetTester tester,
    ) async {
      await _view(tester, 'eng', const Size(852, 393), done: <int>{2}, placed: <int>{0, 1}, onPlay: () {});
      expect(
        find.descendant(of: find.byKey(const Key('stone-3')), matching: find.byIcon(Icons.star_rounded)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stone-1')),
          matching: find.byIcon(Icons.star_outline_rounded),
        ),
        findsOneWidget,
      );
      expect(find.descendant(of: find.byKey(const Key('stone-6')), matching: find.text('6')), findsOneWidget);
      // touching a stone starts nothing
      int starts = 0;
      await _view(
        tester,
        'eng',
        const Size(852, 393),
        done: <int>{2},
        placed: <int>{0, 1},
        onPlay: () => starts++,
      );
      await tester.tap(find.byKey(const Key('stone-3')));
      await tester.tap(find.byKey(const Key('stone-6')));
      await tester.pump();
      expect(starts, 0);
    });

    testWidgets('the pebble starts what is next, once per touch, and its name says what it does', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int starts = 0;
      await _view(tester, 'rus', const Size(852, 393), placementDue: true, onPlay: () => starts++);
      expect(find.bySemanticsLabel(He.courseVisitSemantics.text), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-play')));
      await tester.pump();
      expect(starts, 1);
      await _view(tester, 'rus', const Size(852, 393), onPlay: () => starts++);
      expect(find.bySemanticsLabel(He.courseNextSemantics.text), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape('${He.courseHomeSemantics.text}: ${He.langRussian.text}')),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a check that fell due puts a bell on the pebble, and the invitation never shows with it', (
      WidgetTester tester,
    ) async {
      await _view(tester, 'rus', const Size(852, 393), done: <int>{0, 1}, revisit: true, onPlay: () {});
      expect(find.byKey(const Key('course-bell')), findsOneWidget);
      await _view(tester, 'rus', const Size(852, 393), done: <int>{0, 1}, onPlay: () {});
      expect(find.byKey(const Key('course-bell')), findsNothing);
    });

    testWidgets('with no way to start yet the next stone is a stone, not a pebble', (
      WidgetTester tester,
    ) async {
      await _view(tester, 'eng', const Size(852, 393));
      expect(find.byKey(const Key('course-play')), findsNothing);
      expect(
        find.descendant(of: find.byKey(const Key('course-next')), matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets('a language that is not installed shows the host and the way back, and no path', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const CourseHomeView(course: 'heb', model: null), size: const Size(852, 393));
      expect(find.byKey(const Key('course-host')), findsOneWidget);
      expect(find.byKey(const Key('course-path')), findsNothing);
      expect(find.byKey(const Key('course-back')), findsOneWidget);
    });

    testWidgets('the text that the home shows comes from the strings file, with niqqud', (
      WidgetTester tester,
    ) async {
      await _view(tester, 'eng', const Size(852, 393), placementDue: true, onPlay: () {});
      final RegExp niqqud = RegExp('[ְ-ׇ]');
      for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
        final String s = t.data ?? '';
        if (RegExp('[֐-׿]').hasMatch(s)) expect(niqqud.hasMatch(s), isTrue, reason: s);
      }
    });
  });

  group('in the app', () {
    Future<AppRig> app(
      WidgetTester tester,
      List<String> on, {
      Size size = const Size(852, 393),
      Future<void> Function(AppRig rig)? history,
      Map<String, LanguageSwitches>? switches,
    }) async {
      final AppRig rig = AppRig()..languagePacks = fixturePacks(on);
      await rig.seedFinishedSetup(id: courseKid);
      if (history != null) await history(rig);
      FamilyLanguages f = const FamilyLanguages();
      for (final String c in on) {
        f = f.withSwitches(courseKid, c, switches?[c] ?? const LanguageSwitches(on: true))!;
      }
      await rig.db.putSetting(languagesSettingKey, f.encode());
      await rig.pump(tester, size: size);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      return rig;
    }

    Future<void> openLanguages(WidgetTester tester) async {
      final Finder tap = find.byKey(const Key('land-tap-languages'));
      await tester.ensureVisible(tap);
      await tester.pumpAndSettle();
      await tester.tap(tap);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'one language on: the island opens the course home with the invitation, and back comes to the map',
      (WidgetTester tester) async {
        final AppRig rig = await app(tester, <String>['heb'], switches: knowsALittle('heb'));
        await openLanguages(tester);
        expect(find.byType(LanguagesDoorsScreen), findsNothing);
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(
          find.byKey(const Key('course-invite')),
          findsOneWidget,
          reason: 'the first visit: the host invites',
        );
        expect(find.byKey(const Key('course-path')), findsOneWidget);
        expect((await rig.db.sessionsOf(courseKid)), isEmpty, reason: 'opening the home starts no visit');
        await tester.tap(find.byKey(const Key('course-back')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('several languages on: a door opens that course, and back comes to the doors as they were', (
      WidgetTester tester,
    ) async {
      await app(tester, <String>['eng', 'heb', 'rus']);
      await openLanguages(tester);
      await tester.tap(find.byKey(const Key('door-rus')));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsOneWidget);
      expect(tester.widget<CourseHomeScreen>(find.byType(CourseHomeScreen)).course, 'rus');
      expect(find.byKey(const Key('course-host')), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-back')));
      await tester.pumpAndSettle();
      expect(find.byType(LanguagesDoorsScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('doors-back')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      'the home reads the child\'s own history: a lesson finished moves the next stone on, and another course does not',
      (WidgetTester tester) async {
        await app(
          tester,
          <String>['eng', 'rus'],
          history: (AppRig rig) => writeFinishedLesson(
            rig.db,
            courseContent('eng'),
            'eng.hello_1',
            at: DateTime.utc(2026, 11, 3, 9),
          ),
        );
        await openLanguages(tester);
        await tester.tap(find.byKey(const Key('door-rus')));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const Key('course-path')),
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsNothing,
          reason: 'an English lesson is not a Russian one',
        );
        await tester.tap(find.byKey(const Key('course-back')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('door-eng')));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(tester.widget<CourseHomeScreen>(find.byType(CourseHomeScreen)).course, 'eng');
        expect(
          find.descendant(of: find.byKey(const Key('stone-1')), matching: find.byIcon(Icons.star_rounded)),
          findsOneWidget,
        );
      },
    );
  });
}
