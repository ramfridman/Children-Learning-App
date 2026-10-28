// The parent's time rules inside the real app: rest hours show a calm scene instead of the lesson, the daily limit ends
// a lesson gently between two activities, and with the lock off the child goes on.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

Future<void> wait(WidgetTester t, [int ms = 2000]) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

int at(int hour, [int minute = 0]) => DateTime(2026, 10, 28, hour, minute).millisecondsSinceEpoch;

Future<AppRig> toMap(WidgetTester tester, AppRig rig) async {
  await rig.seedFinishedSetup();
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('in rest hours the map shows a calm scene instead of the lesson, and the way back works', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await toMap(tester, AppRig(clockMs: at(22)));
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-scene')), findsOneWidget);
    expect(find.byType(ActivityFrame), findsNothing);
    expect(find.text(He.restScene.text), findsOneWidget);
    expect(await rig.db.sessionsOf('p-1'), isEmpty, reason: 'no visit was started');
    await tester.tap(find.bySemanticsLabel(He.restBackSemantics.text));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-scene')), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('with the lock off, rest hours do not stop the child', (WidgetTester tester) async {
    await toMap(tester, AppRig(clockMs: at(22), rules: const ParentRules(lockWhenDone: false)));
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-scene')), findsNothing);
    expect(find.byType(ActivityFrame), findsOneWidget);
  });

  testWidgets('at noon with time left, the lesson opens as usual', (WidgetTester tester) async {
    await toMap(tester, AppRig(clockMs: at(12)));
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ActivityFrame), findsOneWidget);
  });

  testWidgets(
    'when the daily limit passes during a lesson, it ends gently after the activity, not as finished',
    (WidgetTester tester) async {
      final AppRig rig = await toMap(
        tester,
        AppRig(
          clockMs: at(12),
          rules: const ParentRules(limitByChild: <String, int>{'p-1': 5}),
        ),
      );
      await openCountingLesson(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ActivityFrame), findsOneWidget);
      await wait(tester, 300);
      // Six minutes go by while the child works on the first activity; then the right answer is given.
      rig.clock.advance(const Duration(minutes: 6));
      await tester.tap(find.byKey(const Key('option-o1')), warnIfMissed: false);
      await wait(tester, 3000);
      expect(find.text(He.restGoodbye.text), findsWidgets, reason: 'the guide says goodbye in the bubble');
      final List<Session> sessions = await rig.db.sessionsOf('p-1');
      expect(sessions.single.endReason, 'limit', reason: 'not "finished": the child did not reach the end');
    },
  );

  testWidgets('a lesson that is still within the limit goes on to the next activity', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await toMap(
      tester,
      AppRig(
        clockMs: at(12),
        rules: const ParentRules(limitByChild: <String, int>{'p-1': 5}),
      ),
    );
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    await wait(tester, 300);
    rig.clock.advance(const Duration(minutes: 2));
    await tester.tap(find.byKey(const Key('option-o1')), warnIfMissed: false);
    await wait(tester, 3000);
    expect(find.text(He.restGoodbye.text), findsNothing);
    expect((await rig.db.sessionsOf('p-1')).single.endReason, '');
  });
}
