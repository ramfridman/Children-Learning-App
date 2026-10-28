// The parent's Prizes screen and the ceremony switch in the real parent area (M8b): a promise is saved when the field is left,
// is checked before it is kept, shows what was earned, goes away when emptied, and reaches the alert list when the trophy
// is earned.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/alerts_screen.dart';
import 'package:nitznutz/parent/prizes_screen.dart';
import 'package:nitznutz/rewards/ribbons.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const String gold = 'trophy:counting:gold';

Future<AppRig> openArea(WidgetTester tester, {Future<void> Function(AppRig rig)? seed}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup();
  if (seed != null) await seed(rig);
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
  return rig;
}

Future<void> openPrizes(WidgetTester tester) async {
  final Finder open = find.byKey(const Key('open-prizes'));
  await tester.scrollUntilVisible(open, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(open);
  await tester.pumpAndSettle();
  expect(find.byType(PrizesScreen), findsOneWidget);
}

Finder field(String key) => find.byKey(Key('promise-p-1-$key'));

Future<void> type(WidgetTester tester, String key, String text) async {
  await tester.scrollUntilVisible(field(key), 200, scrollable: find.byType(Scrollable).first);
  await tester.enterText(field(key), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'every trophy of every land has a field (every land has enough skills now, so none says "not yet")',
    (WidgetTester tester) async {
      await openArea(tester);
      await openPrizes(tester);
      expect(find.text(He.prizesTitle.text), findsOneWidget);
      expect(find.text('נועה'), findsOneWidget);
      expect(find.byType(TextField, skipOffstage: false), findsNWidgets(18));
      expect(find.text(He.prizesNotYet.text, skipOffstage: false), findsNothing);
    },
  );

  testWidgets('a promise is saved when the keyboard says done, and kept in the family\'s settings', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await openArea(tester);
    await openPrizes(tester);
    await type(tester, gold, 'הולכים לגלידה');
    expect(decodeRibbons(await rig.db.setting('ribbons'))['p-1'], <String, String>{gold: 'הולכים לגלידה'});
    // Emptied, it goes away.
    await type(tester, gold, '');
    expect(decodeRibbons(await rig.db.setting('ribbons'))['p-1'] ?? <String, String>{}, isEmpty);
  });

  testWidgets('a link is not kept, and the field says why', (WidgetTester tester) async {
    final AppRig rig = await openArea(tester);
    await openPrizes(tester);
    await type(tester, gold, 'https://example.com');
    expect(find.text(He.prizesBad.text), findsOneWidget);
    expect(await rig.db.setting('ribbons'), isNull);
  });

  testWidgets('a trophy already earned is marked, and shows beside the promise', (WidgetTester tester) async {
    await openArea(
      tester,
      seed: (AppRig rig) => rig.db.addReward(
        RewardsCompanion.insert(
          profileId: 'p-1',
          awardKey: 'trophy:counting:silver',
          kind: 'trophy',
          at: DateTime.utc(2026, 11, 1),
        ),
      ),
    );
    await openPrizes(tester);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('the ceremony switch in the parent area is saved as a family rule', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await openArea(tester);
    final Finder sw = find.byKey(const Key('ceremonies-switch'));
    await tester.scrollUntilVisible(sw, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<Switch>(sw).value, isTrue, reason: 'on unless a parent switched it off');
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(await rig.db.setting('ceremonies'), 'off');
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(await rig.db.setting('ceremonies'), 'on');
  });

  testWidgets('the alert for an earned trophy shows the promise, looked up on this phone', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await openArea(
      tester,
      seed: (AppRig rig) async {
        await rig.db.putSetting(
          'ribbons',
          encodeRibbons(<String, Map<String, String>>{
            'p-1': <String, String>{gold: 'הולכים לגלידה'},
          }),
        );
        await rig.db.addAlert(
          AlertsCompanion.insert(
            at: DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs()),
            profileId: const Value<String?>('p-1'),
            category: 'ribbonEarned',
            severity: 'info',
            detail: const Value<String>(gold),
            dedupeKey: 'ribbon:p-1:$gold',
          ),
        );
      },
    );
    await tester.tap(find.byKey(const Key('open-alerts')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertsScreen), findsOneWidget);
    expect(find.textContaining(He.alertRibbonTitle.text), findsOneWidget);
    expect(find.textContaining('הולכים לגלידה'), findsOneWidget);
    expect(find.text(He.alertRibbonDo.text), findsOneWidget);
    expect((await rig.db.allAlerts()).single.words, isEmpty, reason: 'the words are not in the alert');
  });
}
