// The sync inside the real app: opening the parent area sends what this phone holds, and removing a child there
// deletes the child on the family server too. (The engine itself is tested with two phones in sync_engine_test.dart.)
import 'package:flutter/material.dart' show Scrollable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/sync_providers.dart' show syncEngineProvider;
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/app_harness.dart';
import 'support/fake_family_server.dart';
import 'support/harness.dart';

const String phone = 'd1d1d1d1-0000-4000-8000-000000000001';

AppRig rigWith(FakeFamilyServer server, AppRig Function(List<Override>) make) {
  late AppRig rig;
  final List<Override> extras = <Override>[
    syncEngineProvider.overrideWith(
      (Ref ref) async => SyncEngine(
        db: rig.db,
        call: server.callFor(phone),
        deviceId: phone,
        isParent: true,
        nowMs: () => rig.clock.nowMs(),
      ),
    ),
  ];
  rig = make(extras);
  return rig;
}

Future<void> openArea(WidgetTester tester, AppRig rig) async {
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
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('opening the parent area sends the child, the answers and the alerts this phone holds', (
    WidgetTester tester,
  ) async {
    final FakeFamilyServer server = FakeFamilyServer();
    final AppRig rig = rigWith(server, (List<Override> x) => AppRig(extraOverrides: x));
    await rig.seedFinishedSetup();
    await rig.db.recordAttempt(
      AttemptsCompanion.insert(
        at: DateTime.utc(2026, 10, 26, 9),
        profileId: 'p-1',
        packId: 'starter',
        packVersion: '0.2.0',
        activityId: 'count.butterflies.3',
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: 'NUM-A-03',
        result: 'correct',
        attemptNo: 1,
        hintLevel: 0,
      ),
    );
    await rig.db.recordEvent(
      'gate_alert',
      DateTime.fromMillisecondsSinceEpoch(rig.clock.nowMs()),
      detail: 'n=3',
    );
    await rig.pump(tester);
    await openArea(tester, rig);
    await tester.pumpAndSettle();
    expect(server.children.keys, <String>['p-1'], reason: 'the child, with the nickname');
    expect(server.children['p-1']!['nickname'], 'נועה');
    expect(server.log.length, 1, reason: 'the answer');
    expect(server.alerts.length, 1, reason: 'the alert found when the parent area opened');
    expect((await rig.db.unsyncedAttempts()), isEmpty);
    expect((await rig.db.unsyncedAlerts()), isEmpty);
  });

  testWidgets('removing a child in the parent area deletes the child on the family server, not only here', (
    WidgetTester tester,
  ) async {
    final FakeFamilyServer server = FakeFamilyServer();
    final AppRig rig = rigWith(server, (List<Override> x) => AppRig(extraOverrides: x));
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await openArea(tester, rig);
    expect(server.children.keys, <String>['p-1']);
    await tester.scrollUntilVisible(
      find.text(He.areaRemove.text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(He.areaRemove.text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(He.confirmYes.text));
    await tester.pumpAndSettle();
    expect(await rig.db.allProfiles(), isEmpty);
    expect(server.children, isEmpty);
    expect(server.tombstones, <String>['p-1']);
  });

  testWidgets('with no family to sync with the parent area works as before, and removing a child is local', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await openArea(tester, rig);
    await tester.scrollUntilVisible(
      find.text(He.areaRemove.text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(He.areaRemove.text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(He.confirmYes.text));
    await tester.pumpAndSettle();
    expect(await rig.db.allProfiles(), isEmpty);
  });
}
