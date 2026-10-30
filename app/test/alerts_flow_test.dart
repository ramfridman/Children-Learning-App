// The parent's alerts in the real app: they appear when the parent area opens, the unread count clears when they are
// read, a spoken answer that sets one off is saved on the phone (with the words only if the parent allows it), and the
// child's side never shows any of it.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:nitznutz/app/providers.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/alerts_screen.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Future<void> wait(WidgetTester t, [int ms = 2000]) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> openArea(WidgetTester tester, AppRig rig) async {
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // The pictures are made on Windows and checked on Linux in CI: letters are smoothed a little differently.
    // The alerts screen is almost all text, so that smoothing alone came to 4.28% on CI (the card times,
    // the only part that depends on the machine, were 0.02%; every letter is in Heebo). Hence 5% here.
    useTolerantGoldens(0.05);
  });
  goldenAlerts();

  testWidgets(
    'a gate alert found when the parent area opens shows as new, is listed, and is read on opening',
    (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.db.recordEvent(
        'gate_alert',
        DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs()),
        detail: 'n=3',
      );
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await openArea(tester, rig);
      final Finder open = find.byKey(const Key('open-alerts'));
      expect(find.text(He.alertsOpenUnread.fill(<String, String>{'n': '1'})), findsOneWidget);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(AlertsScreen), findsOneWidget);
      expect(find.text(He.alertGateTitle.text), findsOneWidget);
      expect(find.text(He.alertGateDetail.fill(<String, String>{'n': '3'})), findsOneWidget);
      expect(find.text(He.alertGateDo.text), findsOneWidget);
      expect(await rig.db.unreadAlertCount(), 0, reason: 'opening the screen read them');
      expect(
        find.byKey(const Key('alerts-honest')),
        findsOneWidget,
        reason: 'what the alerts can and cannot do',
      );
      await tester.ensureVisible(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byKey(const Key('open-alerts')), matching: find.text(He.alertsOpen.text)),
        findsOneWidget,
        reason: 'nothing unread now',
      );
    },
  );

  testWidgets('with nothing to report the screen says so, and scanning again never repeats an alert', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openArea(tester, rig);
    await tester.tap(find.byKey(const Key('open-alerts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alerts-none')), findsOneWidget);
  });

  for (final bool keep in <bool>[true, false]) {
    testWidgets(
      'a spoken swear word is saved as an alert, with the words only when "keep the words" is on ($keep)',
      (WidgetTester tester) async {
        {
          final AppRig rig = AppRig(voice: true, speech: FakeSpeechEngine(<Scripted>[Scripted.says('חרא')]));
          await rig.seedFinishedSetup();
          if (!keep) await rig.db.putSetting('keep_words', 'off');
          await rig.pump(tester);
          await tester.tap(find.text('נועה'));
          await tester.pumpAndSettle();
          await openActivities(tester, <String>['col.world.apple.red']); // a spoken question (board B-24)
          await tester.pumpAndSettle();
          expect(find.byType(ActivityFrame), findsOneWidget);
          await wait(tester, 300);
          await tester.tap(find.byKey(const Key('lesson-mic')));
          await wait(tester, 1500);
          final List<Alert> alerts = await rig.db.allAlerts();
          expect(alerts.length, 1, reason: 'keep=$keep');
          expect(alerts.single.category, 'inappropriateWords');
          expect(alerts.single.severity, 'info', reason: 'a note, never pushed');
          expect(alerts.single.profileId, 'p-1');
          expect(alerts.single.words, keep ? 'חרא' : '');
          // The child's screen shows nothing about it.
          expect(find.text(He.alertNoteTitle.text), findsNothing);
          expect(find.byType(AlertsScreen), findsNothing);
        }
      },
    );
  }

  testWidgets(
    'at the start of the app an alert past 30 days is gone, and no words stay when they are not kept',
    (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      final DateTime now = DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs());
      await rig.db.addAlert(AlertsCompanionHelper.words(now.subtract(const Duration(days: 31)), 'חרא'));
      await rig.db.addAlert(
        AlertsCompanion.insert(
          at: now,
          category: 'disclosure',
          severity: 'important',
          dedupeKey: 'words:p-1:2',
          profileId: const Value<String?>('p-1'),
          words: const Value<String>('מכים אותי'),
        ),
      );
      await rig.db.putSetting('keep_words', 'off');
      await rig.pump(tester);
      await tester.pumpAndSettle();
      final List<Alert> left = await rig.db.allAlerts();
      expect(left.map((Alert a) => a.dedupeKey), <String>['words:p-1:2']);
      expect(left.single.words, isEmpty);
    },
  );

  testWidgets('an ordinary answer by voice saves no alert', (WidgetTester tester) async {
    final AppRig rig = AppRig(voice: true, speech: FakeSpeechEngine(<Scripted>[Scripted.says('אדום')]));
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openActivities(tester, <String>['col.world.apple.red']);
    await tester.pumpAndSettle();
    await wait(tester, 300);
    await tester.tap(find.byKey(const Key('lesson-mic')));
    await wait(tester, 1500);
    expect(await rig.db.allAlerts(), isEmpty);
  });

  testWidgets('turning "keep the words" off in the alerts screen clears the words already kept', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs());
    await rig.db.addAlert(AlertsCompanionHelper.words(now, 'חרא'));
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openArea(tester, rig);
    await tester.tap(find.byKey(const Key('open-alerts')));
    await tester.pumpAndSettle();
    final String heard = He.alertHeard.fill(<String, String>{'child': 'נועה', 'w': 'חרא'});
    expect(find.text(heard), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('keep-words')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('keep-words')));
    await tester.pumpAndSettle();
    expect(find.text(heard), findsNothing);
    expect(await rig.db.setting('keep_words'), 'off');
    expect((await rig.db.allAlerts()).single.words, isEmpty);
  });

  testWidgets('SEC-33: the child\'s heard words cannot be copied to the clipboard, the help numbers can', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs());
    await rig.db.addAlert(
      AlertsCompanion.insert(
        at: now,
        category: 'disclosure',
        severity: 'important',
        dedupeKey: 'k-sec33',
        profileId: const Value<String?>('p-1'),
        words: const Value<String>('הוא מכה אותי'),
      ),
    );
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openArea(tester, rig);
    await tester.tap(find.byKey(const Key('open-alerts')));
    await tester.pumpAndSettle();
    final String heard = He.alertHeard.fill(<String, String>{'child': 'נועה', 'w': 'הוא מכה אותי'});
    expect(find.text(heard), findsOneWidget, reason: 'the words are shown to the parent');

    final List<String> copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map<Object?, Object?>)['text']! as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    // Select everything in the act's text and copy it, as a parent's "select all, copy" does.
    await tester.ensureVisible(find.text(He.alertHelp118.text));
    await tester.pumpAndSettle();
    tester.state<SelectableRegionState>(find.byType(SelectableRegion)).selectAll();
    await tester.pump();
    Actions.invoke(tester.element(find.text(He.alertHelp118.text)), CopySelectionTextIntent.copy);
    await tester.pump();

    expect(copied, hasLength(1));
    expect(copied.single, contains(He.alertHelp118.text), reason: 'the help numbers stay selectable');
    expect(copied.single, contains(He.alertHelp1201.text));
    expect(
      copied.single,
      isNot(contains('הוא מכה אותי')),
      reason: 'the child\'s words never reach the clipboard',
    );
  });
}

void goldenAlerts() {
  testWidgets('the alerts screen with one alert of each kind of severity', (WidgetTester tester) async {
    // The cards' times are drawn in UTC, so the picture is the same on any machine's time zone.
    final AppRig rig = AppRig(
      extraOverrides: <Override>[localTimeProvider.overrideWithValue((DateTime t) => t.toUtc())],
    );
    await rig.seedFinishedSetup();
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs());
    Future<void> add(
      String category,
      String severity,
      String key,
      Duration ago, {
      int count = 0,
      String words = '',
      String detail = '',
    }) => rig.db.addAlert(
      AlertsCompanion.insert(
        at: now.subtract(ago),
        category: category,
        severity: severity,
        dedupeKey: key,
        profileId: const Value<String?>('p-1'),
        count: Value<int>(count),
        words: Value<String>(words),
        detail: Value<String>(detail),
      ),
    );
    await add('disclosure', 'important', 'k1', const Duration(hours: 2), words: 'הוא מכה אותי');
    await add('frustration', 'attention', 'k2', const Duration(hours: 26));
    await add('pastLimit', 'info', 'k3', const Duration(days: 2), count: 14);
    await add('absence', 'info', 'k4', const Duration(days: 3), count: 8);
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openArea(tester, rig);
    await tester.tap(find.byKey(const Key('open-alerts')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    // QA-46: every line is plain text on one edge; the whole act can be selected (to copy a help number).
    expect(find.byType(SelectableText), findsNothing);
    expect(find.byType(SelectionArea), findsOneWidget);
    double rightOf(String text) => tester.getTopRight(find.text(text)).dx;
    expect(
      rightOf(He.alertHelp118.text),
      rightOf(He.alertActStep4.text),
      reason: 'a help line and a step line',
    );
    expect(rightOf(He.alertActDuty.text), rightOf(He.alertActNoReport.text));
    await expectLater(find.byType(AlertsScreen), matchesGoldenFile('goldens/alerts_view.png'));
  });
}

/// A saved alert with words, for the screen test.
abstract final class AlertsCompanionHelper {
  static AlertsCompanion words(DateTime at, String w) => AlertsCompanion.insert(
    at: at,
    category: 'inappropriateWords',
    severity: 'attention',
    dedupeKey: 'words:p-1:1',
    profileId: const Value<String?>('p-1'),
    words: Value<String>(w),
  );
}
