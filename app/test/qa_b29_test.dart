// QA proofs for B-29 steps 5a to 9 (qa-engineer, 2026-11-08): two defects found by reading the code, written as tests that fail until fixed.
//  QA-B29-1: a child's tablet must not show the month and year of birth anywhere (SEC-B29-6); the settings page's age card did.
//  QA-B29-2: deleting a child must remove everything this device holds about them; `profile_pushed_<id>` kept the birth (and the name).
import 'dart:ui' show Size;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/device/secure_store.dart' show StoreKeys;
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/app_harness.dart';
import 'support/fake_family_server.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadAppFonts);

  testWidgets("QA-B29-1: a child's tablet does not show the month and year on the settings page's age card", (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup(id: langKid, ageBand: 1);
    await rig.db.confirmStage(langKid, SchoolStage.gan5, DateTime.utc(2026, 10, 26));
    await rig.db.setBirth(langKid, const BirthMonth(2021, 3));
    await rig.store.write(StoreKeys.role, 'child');
    final Profile p = (await rig.db.allProfiles()).firstWhere((Profile x) => x.id == langKid);
    await pumpParentScreen(
      tester,
      rig,
      ChildSettingsScreen(profile: p, onClose: () {}),
      size: const Size(820, 2400),
    );
    expect(
      find.text('${He.months[2].text} 2021'),
      findsNothing,
      reason: 'the birth is on the server copy only',
    );
    expect(find.textContaining('2021'), findsNothing);
  });

  test('QA-B29-2: deleting a child leaves no setting that holds the birth month and year', () async {
    const String kid = 'child-aaaa-0001';
    const String dev = 'd1d1d1d1-0000-4000-8000-000000000001';
    final int noon = DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch;
    final FakeFamilyServer server = FakeFamilyServer();
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final SyncEngine engine = SyncEngine(
      db: db,
      call: server.callFor(dev),
      deviceId: dev,
      isParent: true,
      nowMs: () => noon,
      pageSize: 4,
      batch: 4,
    );
    await db.addProfile(
      ProfilesCompanion.insert(
        id: kid,
        name: 'נועה',
        avatar: 'avatar-noa',
        addressForm: 'f',
        ageBand: 1,
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    );
    await db.setBirth(kid, const BirthMonth(2021, 5));
    await engine.syncOnce();
    expect(
      await db.setting('profile_pushed_$kid'),
      contains('2021-05'),
      reason: 'the premise: the fingerprint holds it',
    );
    await engine.deleteChild(kid);
    final rows = await db.customSelect('SELECT key, value FROM app_settings').get();
    final List<String> holding = <String>[
      for (final r in rows)
        if ((r.read<String>('value')).contains('2021-05') || r.read<String>('key').contains(kid))
          r.read<String>('key'),
    ];
    expect(holding, isEmpty, reason: 'settings still about the deleted child: $holding');
  });
}
