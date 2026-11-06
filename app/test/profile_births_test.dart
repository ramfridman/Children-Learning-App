// B-29 step 4: the local data. The month and year of birth live in their own table of the encrypted database (not on Profiles: sync,
// the picker and the tutor read that), the school stage is a column of Profiles, a band-only profile from before B-29 migrates with
// its progress untouched, and deleting a child removes the birth row too.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/encrypted_storage.dart';
import 'package:nitznutz/engine/age.dart';

import 'support/fakes.dart';

Future<void> _child(AppDatabase db, {String id = 'child-aaaa-0001', int band = 1}) => db.addProfile(
  ProfilesCompanion.insert(
    id: id,
    name: 'נועה',
    avatar: 'avatar-noa',
    addressForm: 'f',
    ageBand: band,
    createdAt: DateTime.utc(2026, 11, 1),
  ),
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the month and year of birth', () {
    test('are kept for a child, read back, replaced and cleared', () async {
      await _child(db);
      expect(await db.birthOf('child-aaaa-0001'), isNull);
      await db.setBirth('child-aaaa-0001', const BirthMonth(2021, 5));
      expect(await db.birthOf('child-aaaa-0001'), const BirthMonth(2021, 5));
      await db.setBirth('child-aaaa-0001', const BirthMonth(2020, 11));
      expect(await db.birthOf('child-aaaa-0001'), const BirthMonth(2020, 11));
      await db.setBirth('child-aaaa-0001', null);
      expect(await db.birthOf('child-aaaa-0001'), isNull);
    });

    test('belong to one child each', () async {
      await _child(db);
      await _child(db, id: 'child-bbbb-0002');
      await db.setBirth('child-aaaa-0001', const BirthMonth(2021, 5));
      expect(await db.birthOf('child-bbbb-0002'), isNull);
    });

    test(
      'are in a table of their own, holding a month and a year and nothing else (no day, no text)',
      () async {
        final List<String> columns = <String>[
          for (final row in await db.customSelect('PRAGMA table_info(profile_births)').get())
            row.data['name']! as String,
        ];
        expect(columns, <String>['profile_id', 'birth_year', 'birth_month']);
        final List<String> profile = <String>[
          for (final row in await db.customSelect('PRAGMA table_info(profiles)').get())
            row.data['name']! as String,
        ];
        expect(profile.where((String c) => c.contains('birth') || c.contains('born')), isEmpty);
      },
    );

    test('are refused by the table when the month is not 1 to 12 or the year is absurd', () async {
      await _child(db);
      for (final (int, int) bad in <(int, int)>[(2021, 0), (2021, 13), (1500, 5), (3000, 5)]) {
        await expectLater(
          db.customStatement(
            'INSERT INTO profile_births (profile_id, birth_year, birth_month) VALUES (?, ?, ?)',
            <Object?>['child-aaaa-0001', bad.$1, bad.$2],
          ),
          throwsA(anything),
          reason: '$bad',
        );
      }
    });

    test('go when the child is deleted, with the answers and the rest', () async {
      await _child(db);
      await _child(db, id: 'child-bbbb-0002');
      await db.setBirth('child-aaaa-0001', const BirthMonth(2021, 5));
      await db.setBirth('child-bbbb-0002', const BirthMonth(2019, 2));
      await db.deleteChildData('child-aaaa-0001');
      expect(await db.birthOf('child-aaaa-0001'), isNull);
      expect(
        await db.birthOf('child-bbbb-0002'),
        const BirthMonth(2019, 2),
        reason: 'the other child keeps theirs',
      );
      final int left = (await db.customSelect('SELECT COUNT(*) AS n FROM profile_births').getSingle())
          .read<int>('n');
      expect(left, 1);
    });

    test('go with removeProfile too', () async {
      await _child(db);
      await db.setBirth('child-aaaa-0001', const BirthMonth(2021, 5));
      await db.removeProfile('child-aaaa-0001');
      expect(await db.birthOf('child-aaaa-0001'), isNull);
    });
  });

  group('the school stage', () {
    test('a child has none until a parent confirms one', () async {
      await _child(db);
      expect((await db.allProfiles()).single.schoolStage, isNull);
      expect(await db.schoolStageOf('child-aaaa-0001'), isNull);
    });

    test('setting it sets the band with it, in one write', () async {
      await _child(db, band: 0);
      await db.setSchoolStage('child-aaaa-0001', SchoolStage.grade2);
      final Profile p = (await db.allProfiles()).single;
      expect(p.schoolStage, 'grade2');
      expect(p.ageBand, 2);
      expect(await db.schoolStageOf('child-aaaa-0001'), SchoolStage.grade2);
      await db.setSchoolStage('child-aaaa-0001', SchoolStage.gan4);
      expect((await db.allProfiles()).single.ageBand, 0);
    });

    test('the table refuses a word that is not one of the six', () async {
      await _child(db);
      await expectLater(db.customStatement("UPDATE profiles SET school_stage = 'grade4'"), throwsA(anything));
      await expectLater(
        db.customStatement("UPDATE profiles SET school_stage = '2021-05'"),
        throwsA(anything),
      );
    });

    test('a child brought in from the family keeps the stage the server had', () async {
      await db.upsertProfileFromFamily(
        ProfilesCompanion(
          id: const Value<String>('child-aaaa-0001'),
          name: const Value<String>('נועה'),
          avatar: const Value<String>('avatar-noa'),
          addressForm: const Value<String>('f'),
          ageBand: const Value<int>(2),
          schoolStage: const Value<String?>('grade2'),
          createdAt: Value<DateTime>(DateTime.utc(2026, 11, 1)),
        ),
        isNew: true,
      );
      expect(await db.schoolStageOf('child-aaaa-0001'), SchoolStage.grade2);
      // A pull that carries no stage (a server older than B-29) never wipes it.
      await db.upsertProfileFromFamily(
        const ProfilesCompanion(
          id: Value<String>('child-aaaa-0001'),
          name: Value<String>('נועה'),
          avatar: Value<String>('avatar-noa'),
          addressForm: Value<String>('f'),
          ageBand: Value<int>(2),
        ),
        isNew: false,
      );
      expect(await db.schoolStageOf('child-aaaa-0001'), SchoolStage.grade2);
    });
  });

  group('a profile from before B-29 (band only)', () {
    late Directory dir;
    late DatabaseKeyService keys;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('nn_births');
      keys = DatabaseKeyService(MemoryStore());
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('moves to version 10 with its band, its answers and its sessions untouched, and the middle of the band as its look', () async {
      final String keyHex = await keys.keyHex();
      final AppDatabase v10 = openAppDatabase(folder: dir.path, keyHex: keyHex);
      await _child(v10, band: 0);
      await v10.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 10, 26),
          profileId: 'child-aaaa-0001',
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
      final int session = await v10.startSession(
        'child-aaaa-0001',
        DateTime.utc(2026, 11, 1),
        plan: 'lesson:x',
      );
      await v10.endSession(session, DateTime.utc(2026, 11, 1, 0, 5), 'finished');
      // Make a version 9 file: no stage column and no births table.
      await v10.customStatement('DROP TABLE profile_births');
      await v10.customStatement('ALTER TABLE profiles DROP COLUMN school_stage');
      await v10.customStatement('PRAGMA user_version = 9');
      await v10.close();

      final AppDatabase db = openAppDatabase(folder: dir.path, keyHex: keyHex);
      addTearDown(db.close);
      final Profile p = (await db.allProfiles()).single;
      expect(p.ageBand, 0);
      expect(p.schoolStage, isNull, reason: 'nobody has confirmed a stage');
      expect(await db.birthOf('child-aaaa-0001'), isNull, reason: 'and nobody gave a month');
      expect((await db.attemptsOf('child-aaaa-0001')).single.activityId, 'count.butterflies.3');
      expect((await db.sessionsOf('child-aaaa-0001')).single.endReason, 'finished');
      final ChildAge age = childAge(
        band: p.ageBand,
        stage: SchoolStage.fromWire(p.schoolStage),
        now: DateTime(2026, 11, 6),
      );
      expect(age.stage, SchoolStage.gan4);
      expect(age.presentation, PresentationStage.p2, reason: 'A 4;0');
      await db.setBirth('child-aaaa-0001', const BirthMonth(2021, 5));
      expect(await db.birthOf('child-aaaa-0001'), const BirthMonth(2021, 5), reason: 'the new table works');
      final rows = await db.customSelect('PRAGMA user_version').get();
      expect(rows.single.data['user_version'], AppDatabase.currentSchemaVersion);
    });
  });
}
