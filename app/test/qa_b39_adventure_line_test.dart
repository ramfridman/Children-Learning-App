// QA of B-39's bubble line: can the child see or hear the line of the stop before the lesson covers it?
//
// The line is put in the friend's bubble and the stop is held back for it (`BottleHold`, about 2.2 s without a recording).
// This test measures how long the home with its line stays uncovered (from the frame the bubble says the line to the frame
// the lesson page is pushed, the page transition itself not counted): at least 1.5 seconds.
// QA-B39-1 was open until the stop was held for the line; it now runs in every run.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

String _bubble(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('home-island-bubble'), skipOffstage: false),
        matching: find.byType(Text, skipOffstage: false),
      ),
    )
    .data!;

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('QA-B39-1: the bottle\'s line stays in front of the child long enough to be seen (1.5 s)', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeIslandScreen), findsOneWidget);
    final String welcome = _bubble(tester);
    await tester.tap(find.byKey(const Key('home-island-bottle')));

    int lineAt = -1;
    int coveredAt = -1;
    for (int ms = 0; ms <= 4000; ms += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      if (lineAt < 0 && _bubble(tester) != welcome) lineAt = ms;
      if (coveredAt < 0 && find.byType(LessonScreen).evaluate().isNotEmpty) coveredAt = ms;
      if (lineAt >= 0 && coveredAt >= 0) break;
    }
    expect(lineAt, isNonNegative, reason: 'the line was put in the bubble');
    expect(coveredAt, isNonNegative, reason: 'the lesson page was pushed');
    final int shown = coveredAt - lineAt;
    // ignore: avoid_print
    print(
      'QA-B39-1: the line shows from ${lineAt}ms; the lesson page is pushed at ${coveredAt}ms; '
      'the line is in front for ${shown}ms before the page starts to cover it (the real page transition, 300 ms or '
      'more on a phone, is not in this number).',
    );
    expect(shown, greaterThanOrEqualTo(1500), reason: 'a child cannot see a line that is gone in ${shown}ms');
    expect(He.adventureWelcome.text, isNotEmpty);
  });
}
