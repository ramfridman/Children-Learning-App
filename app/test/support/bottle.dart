import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/lesson_screen.dart';

/// Touches the bottle in the child's home and waits, in 100 ms steps, for the line to have been in front of the child and
/// for the lesson it opens (B-39: the stop opens after the line, about 2.2 s without a recording), then lets the page settle.
Future<void> tapBottleAndWait(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-island-bottle')));
  for (int i = 0; i < 80 && find.byType(LessonScreen).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
