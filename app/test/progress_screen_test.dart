// The progress screen in the real parent area: an empty history says so, a real history shows this week and the status of
// the skills, and nothing on it can show speed or counts of mistakes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/progress_charts.dart';
import 'package:nitznutz/parent/progress_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

Future<AppRig> openProgress(WidgetTester tester, AppRig rig, {bool seed = true}) async {
  if (seed) await rig.seedFinishedSetup();
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('progress-p-1')));
  await tester.pumpAndSettle();
  expect(find.byType(ProgressScreen), findsOneWidget);
  return rig;
}

Future<void> attempt(AppRig rig, DateTime at, String result, {int no = 1, int hint = 0}) =>
    rig.db.recordAttempt(
      AttemptsCompanion.insert(
        at: at.toUtc(),
        profileId: 'p-1',
        packId: 'starter',
        packVersion: '0.2.0',
        activityId: 'count.butterflies.3',
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: 'NUM-A-03',
        result: result,
        attemptNo: no,
        hintLevel: hint,
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a child who has not played gets one calm sentence, and no empty charts', (
    WidgetTester tester,
  ) async {
    await openProgress(tester, AppRig());
    expect(find.byKey(const Key('progress-empty')), findsOneWidget);
    expect(find.byType(MinutesBars), findsNothing);
    expect(find.byType(GrowthLines), findsNothing);
  });

  testWidgets('with play behind it the screen shows this week, the skills with their status, and the curve', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs());
    final int s1 = await rig.db.startSession(
      'p-1',
      now.subtract(const Duration(hours: 3)),
      plan: 'lesson:butterflies',
    );
    await rig.db.endSession(
      s1,
      now.subtract(const Duration(hours: 3)).add(const Duration(minutes: 12)),
      'finished',
    );
    final int s2 = await rig.db.startSession(
      'p-1',
      now.subtract(const Duration(days: 2)),
      plan: 'lesson:butterflies',
    );
    await rig.db.endSession(
      s2,
      now.subtract(const Duration(days: 2)).add(const Duration(minutes: 9)),
      'home',
    );
    for (int d = 0; d < 5; d++) {
      for (int i = 0; i < 3; i++) {
        await attempt(rig, now.subtract(Duration(days: d, minutes: i)), 'correct');
      }
    }
    await attempt(rig, now.subtract(const Duration(minutes: 30)), 'unsure');
    await openProgress(tester, rig, seed: false);
    expect(find.byKey(const Key('progress-empty')), findsNothing);
    expect(find.byType(MinutesBars), findsOneWidget);
    expect(find.text(He.progressSessions.fill(<String, String>{'n': '2'})), findsOneWidget);
    expect(find.text(He.progressAdventures.fill(<String, String>{'n': '1'})), findsOneWidget);
    final Finder status = find.byKey(const Key('status-NUM-A-03'));
    await tester.scrollUntilVisible(status, 200, scrollable: find.byType(Scrollable).first);
    final String shown = tester.widget<Text>(status).data!;
    expect(
      <String>[He.statusPractising.text, He.statusUnderstood.text],
      contains(shown),
      reason: 'five days of right answers is learning or learnt',
    );
    final Finder curve = find.byType(GrowthLines);
    await tester.scrollUntilVisible(curve, 200, scrollable: find.byType(Scrollable).first);
    expect(curve, findsOneWidget);
    expect(find.text(He.progressNothingToWatch.text), findsOneWidget);
    expect(find.text(He.habitAsked.fill(<String, String>{'n': '1'})), findsOneWidget);
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await expectLater(find.byType(ProgressScreen), matchesGoldenFile('goldens/progress_view.png'));
  });

  test('nothing in the progress files can show speed, time per question or counts of mistakes', () {
    for (final String name in <String>['progress.dart', 'progress_screen.dart', 'progress_charts.dart']) {
      final String source = File('lib/parent/$name')
          .readAsLinesSync()
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join(' ');
      for (final String banned in <String>[
        'latency',
        'durationMs',
        'seconds',
        'Result.incorrect',
        'errors',
        'speed',
      ]) {
        expect(source.contains(banned), isFalse, reason: '$name must not mention $banned');
      }
    }
  });

  test('the weekday letters run from Sunday (alef) to Saturday (shin)', () {
    expect(dayLetter(DateTime(2026, 11, 22)), 'א', reason: 'a Sunday');
    expect(dayLetter(DateTime(2026, 11, 26)), 'ה', reason: 'a Thursday');
    expect(dayLetter(DateTime(2026, 11, 28)), 'ש', reason: 'a Saturday');
  });

  test('the latest value of a line is the newest week that has one', () {
    final List<Map<String, double?>> weeks = <Map<String, double?>>[
      <String, double?>{'numbers': 0.2},
      <String, double?>{'numbers': null},
      <String, double?>{'numbers': 0.75},
      <String, double?>{'numbers': null},
    ];
    expect(GrowthLines.latest(weeks, 'numbers'), 75);
    expect(GrowthLines.latest(weeks, 'colors'), isNull);
  });
}
