import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/starter.dart';

Finder _bubble() => find.descendant(of: find.byKey(const Key('lesson-bubble')), matching: find.byType(Text));

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  testWidgets(
    'the first visit to the counting hills starts with the warm-up, and the answers are written as the warm-up',
    (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(warmUp: true);
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await openCountingLesson(tester);
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);
      final Lesson warm = placementLesson(content, 'numbers')!;
      final Activity first = content.activities[warm.itemIds.first]!;
      expect(tester.widget<Text>(_bubble()).data, first.promptLine.caption);
      // "I'm not sure" is written against the warm-up, not against a lesson of the path.
      await tester.tap(find.byKey(const Key('lesson-show-me')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      final List<Attempt> rows = await rig.db.attemptsOf('p-1');
      expect(rows.every((Attempt a) => a.lessonId == placementId), isTrue);
    },
  );

  testWidgets('a child who turned the warm-up off in the parent area goes straight to the first lesson', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_bubble()).data, content.activities['pick.red.flower']!.promptLine.caption);
  });
}
