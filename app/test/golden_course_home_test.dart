// Goldens of the course home (L-course) on the four boards: the invitation to the first visit, a path with lessons done and placed in each
// course's reading direction, a check that fell due, and a course with nothing to start. Drawn from fixed models over the fixture packs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/world/course_path.dart' show CourseHomeModel;

import 'support/course_home_model.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show boards;

Future<void> _shot(
  WidgetTester tester,
  String course,
  CourseHomeModel model,
  Size size,
  String name, {
  bool play = true,
}) async {
  await pumpScreen(
    tester,
    CourseHomeView(course: course, model: model, onPlay: play ? () {} : null),
    size: size,
  );
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the first visit: the host invites the child', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('English, ${b.key}', (WidgetTester tester) async {
        await _shot(
          tester,
          'eng',
          modelOf('eng', placementDue: true),
          b.value,
          'course_home_eng_invite_${b.key}',
        );
      });
    }
  });

  group('a path with lessons behind the child, in the reading direction of the course', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('Hebrew, ${b.key}: the path starts at the right', (WidgetTester tester) async {
        await _shot(
          tester,
          'heb',
          modelOf('heb', done: <int>{0}, placed: <int>{1}),
          b.value,
          'course_home_heb_path_${b.key}',
        );
      });
    }

    testWidgets('English, phone: the path starts at the left, a lesson placed and two done', (
      WidgetTester tester,
    ) async {
      await _shot(
        tester,
        'eng',
        modelOf('eng', done: <int>{2, 3}, placed: <int>{0, 1}),
        boards['phone']!,
        'course_home_eng_path_phone',
      );
    });

    testWidgets('Russian, phone: a check that fell due, the bell is on the pebble', (
      WidgetTester tester,
    ) async {
      await _shot(
        tester,
        'rus',
        modelOf('rus', done: <int>{0, 1}, revisit: true),
        boards['phone']!,
        'course_home_rus_revisit_phone',
      );
    });

    testWidgets('English, phone: every lesson done, the path goes round', (WidgetTester tester) async {
      await _shot(
        tester,
        'eng',
        modelOf('eng', done: <int>{0, 1, 2, 3, 4, 5, 6}),
        boards['phone']!,
        'course_home_eng_round_phone',
      );
    });
  });
}
