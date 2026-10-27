// The parent's time screen: every control saves at once, the saved rules are what the child's side reads, and nothing
// on it can be pushed past the limits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/parent/rules_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

Future<AppRig> openRules(WidgetTester tester) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup();
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
  final Finder open = find.byKey(const Key('open-time-rules'));
  await tester.scrollUntilVisible(open, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(open);
  await tester.pumpAndSettle();
  expect(find.byType(RulesScreen), findsOneWidget);
  return rig;
}

Future<ParentRules> saved(AppRig rig) async => ParentRules.decode(await rig.db.setting('parent_rules'));

Future<void> tapKey(WidgetTester tester, String key) async {
  final Finder f = find.byKey(Key(key));
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('it starts with the defaults and every change is saved at once', (WidgetTester tester) async {
    final AppRig rig = await openRules(tester);
    expect(find.text(He.timeMinutes.fill(<String, String>{'n': '30'})), findsOneWidget);
    await tapKey(tester, 'limit-B-more');
    expect((await saved(rig)).limitByBand['B'], 35);
    await tapKey(tester, 'limit-A-less');
    await tapKey(tester, 'limit-A-less');
    expect((await saved(rig)).limitByBand['A'], 10);
    expect((await saved(rig)).limitByBand['C'], 40, reason: 'the other bands are untouched');
  });

  testWidgets('the limit cannot go below 5 or above 180 minutes', (WidgetTester tester) async {
    final AppRig rig = await openRules(tester);
    for (int i = 0; i < 6; i++) {
      await tapKey(tester, 'limit-A-less');
    }
    expect((await saved(rig)).limitByBand['A'], ParentRules.minLimit);
    for (int i = 0; i < 40; i++) {
      await tapKey(tester, 'limit-C-more');
    }
    expect((await saved(rig)).limitByBand['C'], ParentRules.maxLimit);
  });

  testWidgets('rest hours move in half hours, wrap around midnight, and can be turned off', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await openRules(tester);
    await tapKey(tester, 'rest-from-more');
    expect((await saved(rig)).restStartMinute, 20 * 60);
    await tapKey(tester, 'rest-to-less');
    await tapKey(tester, 'rest-to-less');
    expect((await saved(rig)).restEndMinute, 5 * 60 + 30);
    await tapKey(tester, 'rest-on');
    expect((await saved(rig)).restOn, isFalse);
    expect(
      find.byKey(const Key('rest-from-more')),
      findsNothing,
      reason: 'nothing to set while they are off',
    );
  });

  testWidgets('a weekday can be limited to a window, moved, and set free again', (WidgetTester tester) async {
    final AppRig rig = await openRules(tester);
    await tapKey(tester, 'day-3');
    expect((await saved(rig)).schedule[3], <List<int>>[
      <int>[15 * 60, 18 * 60],
    ]);
    await tapKey(tester, 'day-3-from-more');
    await tapKey(tester, 'day-3-to-less');
    expect((await saved(rig)).schedule[3], <List<int>>[
      <int>[15 * 60 + 30, 17 * 60 + 30],
    ]);
    await tapKey(tester, 'day-3');
    expect((await saved(rig)).schedule.containsKey(3), isFalse);
  });

  testWidgets('the lock switch and the AI helper switch save too', (WidgetTester tester) async {
    final AppRig rig = await openRules(tester);
    expect((await saved(rig)).lockWhenDone, isTrue);
    await tapKey(tester, 'lock-when-done');
    expect((await saved(rig)).lockWhenDone, isFalse);
    expect(await rig.db.setting('ai_helper'), isNull);
    await tapKey(tester, 'ai-helper-parent-switch');
    expect(await rig.db.setting('ai_helper'), 'on');
    await tapKey(tester, 'ai-helper-parent-switch');
    expect(await rig.db.setting('ai_helper'), 'off');
  });
}
