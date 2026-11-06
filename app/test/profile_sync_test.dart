// B-29 step 4: the school stage and the look letter travel with the family; the month and year of birth never do. Two simulated
// phones and the fake family server, which now refuses a key the real gateway does not name.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/look_settings.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/fake_family_server.dart';

const String kid = 'child-aaaa-0001';
const String kid2 = 'child-bbbb-0002';
const String dev1 = 'd1d1d1d1-0000-4000-8000-000000000001';
const String dev2 = 'd2d2d2d2-0000-4000-8000-000000000002';
const String dev3 = 'd3d3d3d3-0000-4000-8000-000000000003';
final int noon = DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch;

class Phone {
  Phone(this.id, this.server, {bool parent = true})
    : db = AppDatabase(NativeDatabase.memory()),
      parent = parent {
    engine = SyncEngine(
      db: db,
      call: server.callFor(id, parent: parent),
      deviceId: id,
      isParent: parent,
      nowMs: () => noon,
      pageSize: 4,
      batch: 4,
    );
  }

  final String id;
  final FakeFamilyServer server;
  final bool parent;
  final AppDatabase db;
  late final SyncEngine engine;

  Future<void> addChild({String childId = kid, String name = 'נועה', int band = 1}) => db.addProfile(
    ProfilesCompanion.insert(
      id: childId,
      name: name,
      avatar: 'avatar-noa',
      addressForm: 'f',
      ageBand: band,
      createdAt: DateTime.utc(2026, 11, 1),
    ),
  );

  Future<Profile> profile([String childId = kid]) async =>
      (await db.allProfiles()).firstWhere((Profile p) => p.id == childId);
}

int _childPuts(FakeFamilyServer s) => s.calls.where((String c) => c.endsWith(':child-put')).length;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeFamilyServer server;
  late Phone p1;
  late Phone p2;

  setUp(() {
    server = FakeFamilyServer();
    p1 = Phone(dev1, server);
    p2 = Phone(dev2, server);
  });

  tearDown(() async {
    await p1.db.close();
    await p2.db.close();
  });

  group('the school stage', () {
    test('a child with none is sent as before: no school_stage key, and the server has null', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      expect(server.children[kid], isNotNull);
      expect(server.children[kid]!['school_stage'], isNull);
      expect(
        server.wire.where((w) => w.name == 'child-put' && !w.answer).single.json,
        isNot(contains('school_stage')),
      );
    });

    test('confirming one sends the child again with the word, once, and both phones then agree', () async {
      await p1.addChild(band: 0);
      await p1.engine.syncOnce();
      final int before = _childPuts(server);
      await p1.db.setSchoolStage(kid, SchoolStage.grade2);
      await p1.engine.syncOnce();
      expect(_childPuts(server), before + 1, reason: 'the fingerprint holds the stage');
      expect(server.children[kid]!['school_stage'], 'grade2');
      expect(server.children[kid]!['age_band'], 2, reason: 'the band went with it');
      await p1.engine.syncOnce();
      expect(_childPuts(server), before + 1, reason: 'and not again');

      await p2.engine.syncOnce();
      final Profile there = await p2.profile();
      expect(there.schoolStage, 'grade2');
      expect(there.ageBand, 2);
      await p2.engine.syncOnce();
      expect(_childPuts(server), before + 1, reason: 'the second phone does not send back what it was given');
    });

    test('changing it again sends the new one', () async {
      await p1.addChild();
      await p1.db.setSchoolStage(kid, SchoolStage.gan5);
      await p1.engine.syncOnce();
      await p1.db.setSchoolStage(kid, SchoolStage.grade1);
      await p1.engine.syncOnce();
      expect(server.children[kid]!['school_stage'], 'grade1');
      await p2.engine.syncOnce();
      expect((await p2.profile()).schoolStage, 'grade1');
    });

    test(
      'a stage the server does not know yet, or sends wrongly, never wipes or overwrites the one here',
      () async {
        await p1.addChild();
        await p1.db.setSchoolStage(kid, SchoolStage.gan5);
        await p1.engine.syncOnce();
        for (final Object? bad in <Object?>[null, 'grade4', 'Gan5', '', 7, '2021-05', 'grade2']) {
          // 'grade2' is a real word but its band (2) is not the band the server sent (1): the pair is a mistake.
          server.children[kid] = <String, Object?>{...server.children[kid]!, 'school_stage': bad};
          await p1.engine.syncOnce();
          expect((await p1.profile()).schoolStage, 'gan5', reason: '$bad');
          expect((await p1.profile()).ageBand, 1, reason: '$bad');
        }
      },
    );

    test('a server older than B-29 (no school_stage in the answer) leaves the stage alone', () async {
      await p1.addChild();
      await p1.db.setSchoolStage(kid, SchoolStage.gan5);
      await p1.engine.syncOnce();
      server.children[kid]!.remove('school_stage');
      await p1.engine.syncOnce();
      expect((await p1.profile()).schoolStage, 'gan5');
    });

    test('a child device never sends a child, so it cannot change a stage', () async {
      await p1.addChild();
      await p1.db.setSchoolStage(kid, SchoolStage.gan5);
      await p1.engine.syncOnce();
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
      await kidPhone.engine.syncOnce();
      expect((await kidPhone.profile()).schoolStage, 'gan5');
      await kidPhone.db.setSchoolStage(kid, SchoolStage.grade3);
      final int before = _childPuts(server);
      await kidPhone.engine.syncOnce();
      expect(_childPuts(server), before);
      expect(server.children[kid]!['school_stage'], 'gan5');
    });
  });

  group('the look letter', () {
    test('a family that sets none syncs exactly the rules document it did before', () async {
      await p1.engine.syncOnce();
      expect(server.rules!.containsKey('looks'), isFalse);
    });

    test(
      'a look chosen on one parent phone reaches the other as a letter, and nothing is sent back',
      () async {
        await p1.engine.syncOnce();
        await p1.db.putSetting(looksSettingKey, const FamilyLooks().withBand(kid, 2)!.encode());
        await p1.engine.syncOnce();
        expect(server.rules!['looks'], <String, Object?>{kid: 'C'});
        final int version = server.rulesVersion;
        expect((await p2.engine.syncOnce()).rulesApplied, isTrue);
        expect(FamilyLooks.decode(await p2.db.setting(looksSettingKey)).bandOf(kid), 2);
        expect(server.rulesVersion, version);
      },
    );

    test('clearing the look takes the key out of the rules and off the other phone', () async {
      await p1.engine.syncOnce();
      await p1.db.putSetting(looksSettingKey, const FamilyLooks().withBand(kid, 0)!.encode());
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await p1.db.putSetting(looksSettingKey, const FamilyLooks().encode());
      await p1.engine.syncOnce();
      expect(server.rules!.containsKey('looks'), isFalse);
      await p2.engine.syncOnce();
      expect(FamilyLooks.decode(await p2.db.setting(looksSettingKey)).isEmpty, isTrue);
    });

    test('a damaged look in the server\'s rules is dropped here, not turned into something else', () async {
      await p1.engine.syncOnce();
      server.rules = <String, Object?>{
        ...server.rules!,
        'looks': <String, Object?>{kid: 'Z', kid2: 'B', 'x': 'A'},
      };
      server.rulesVersion++;
      await p2.engine.syncOnce();
      final FamilyLooks got = FamilyLooks.decode(await p2.db.setting(looksSettingKey));
      expect(got.bandOf(kid), isNull);
      expect(got.bandOf(kid2), 1);
    });

    test('deleting a child takes its look with it', () async {
      await p1.addChild();
      await p1.db.putSetting(looksSettingKey, const FamilyLooks().withBand(kid, 1)!.encode());
      await p1.db.deleteChildData(kid);
      expect(FamilyLooks.decode(await p1.db.setting(looksSettingKey)).isEmpty, isTrue);
    });
  });

  group('the fake server is as strict as the real one', () {
    Future<Map<String, Object?>> put(Map<String, Object?> over) =>
        server.callFor(dev1)('child-put', <String, Object?>{
          'child_id': kid,
          'nickname': 'נועה',
          'avatar_id': 'avatar-noa',
          'address_form': 'f',
          'age_band': 1,
          ...over,
        });

    test('it takes a good child, with or without a stage', () async {
      await put(<String, Object?>{});
      await put(<String, Object?>{'school_stage': 'gan5'});
      expect(server.children[kid]!['school_stage'], 'gan5');
      await put(<String, Object?>{'nickname': 'נועה כהן'});
      expect(server.children[kid]!['school_stage'], 'gan5', reason: 'a save without one keeps it');
    });

    test(
      'it refuses a key it does not know, a stage it does not know and a stage against the band',
      () async {
        for (final Map<String, Object?> bad in <Map<String, Object?>>[
          <String, Object?>{'birth_month': 5},
          <String, Object?>{'birth_year': 2021},
          <String, Object?>{'birth': '2021-05'},
          <String, Object?>{'age_months': 66},
          <String, Object?>{'presentation_stage': 'p3'},
          <String, Object?>{'school_stage': 'grade4'},
          <String, Object?>{'school_stage': null},
          <String, Object?>{'school_stage': 'grade2'},
          <String, Object?>{'age_band': 3},
        ]) {
          await expectLater(put(bad), throwsA(isA<GatewayException>()), reason: '$bad');
        }
      },
    );

    test('it refuses rules with a key it does not name and a look that is not a letter', () async {
      Future<Map<String, Object?>> rules(Map<String, Object?> r) =>
          server.callFor(dev1)('settings-put', <String, Object?>{'rules_json': jsonEncode(r)});
      await rules(<String, Object?>{
        'looks': <String, Object?>{kid: 'B'},
      });
      for (final Map<String, Object?> bad in <Map<String, Object?>>[
        <String, Object?>{'birth': '2021-05'},
        <String, Object?>{
          'looks': <String, Object?>{kid: 'D'},
        },
        <String, Object?>{
          'looks': <String, Object?>{kid: 1},
        },
        <String, Object?>{'looks': 'A'},
      ]) {
        await expectLater(rules(bad), throwsA(isA<GatewayException>()), reason: '$bad');
      }
    });
  });

  group('the month and year of birth never leave the device', () {
    // A distinctive birth: 2018-12. Nothing the engine sends or receives may hold this year as a number, a date, or any key that is
    // about a birth, an age in months or a presentation stage.
    const BirthMonth born = BirthMonth(2018, 12);
    final RegExp aboutBirth = RegExp('birth|born|dob|age_?months|presentation|assumed', caseSensitive: false);

    bool holdsBirth(Object? node) {
      if (node is Map) {
        return node.entries.any(
          (MapEntry<Object?, Object?> e) => aboutBirth.hasMatch('${e.key}') || holdsBirth(e.value),
        );
      }
      if (node is List) return node.any(holdsBirth);
      if (node is num) return node == born.year;
      if (node is String) {
        return node.contains('${born.year}-12') || node.contains('12/${born.year}') || node == '${born.year}';
      }
      return false;
    }

    Future<void> playEverything(Phone p) async {
      await p.addChild();
      await p.db.setSchoolStage(kid, SchoolStage.gan5);
      await p.db.setBirth(kid, born);
      await p.db.putSetting(looksSettingKey, const FamilyLooks().withBand(kid, 1)!.encode());
      final int s = await p.db.startSession(kid, DateTime.utc(2026, 11, 20, 10), plan: 'lesson:butterflies');
      await p.db.endSession(s, DateTime.utc(2026, 11, 20, 10, 8), 'finished');
      await p.db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 11, 20, 10, 1),
          profileId: kid,
          packId: 'starter',
          packVersion: '0.2.0',
          activityId: 'A.1',
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'SK-A-01',
          result: 'correct',
          attemptNo: 1,
          hintLevel: 0,
          sessionId: Value<int?>(s),
        ),
      );
    }

    test('no request and no answer of any round holds a birth month, a year of birth, an age in months or a look stage', () async {
      await playEverything(p1);
      for (int i = 0; i < 3; i++) {
        await p1.engine.syncOnce();
        await p2.engine.syncOnce();
      }
      expect(server.children[kid], isNotNull, reason: 'the child did reach the server');
      expect(server.rules!['looks'], isNotNull, reason: 'and so did the look');
      expect(server.wire, isNotEmpty);
      for (final w in server.wire) {
        expect(holdsBirth(jsonDecode(w.json)), isFalse, reason: '${w.name}: ${w.json}');
        expect(w.json, isNot(contains('2018')), reason: '${w.name}: ${w.json}');
      }
      // The other phone never had it, because it was never sent.
      expect(await p2.db.birthOf(kid), isNull);
    });

    test('the tripwire works: a request that did carry the month would be seen', () {
      expect(holdsBirth(<String, Object?>{'birth_month': 12}), isTrue);
      expect(holdsBirth(<String, Object?>{'x': 2018}), isTrue);
      expect(holdsBirth(<String, Object?>{'x': '2018-12'}), isTrue);
      expect(holdsBirth(<String, Object?>{'age_months': 95}), isTrue);
      expect(holdsBirth(<String, Object?>{'school_stage': 'gan5', 'age_band': 1}), isFalse);
    });

    test('no log line of a round holds it', () async {
      final List<String> printed = <String>[];
      final DebugPrintCallback old = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => printed.add(message ?? '');
      addTearDown(() => debugPrint = old);
      await playEverything(p1);
      // A round the server refuses everything in is the one that logs.
      server.failing.addAll(<String>['sync-push', 'child-put']);
      await p1.engine.syncOnce();
      server.failing.clear();
      await p1.engine.syncOnce();
      expect(printed.where((String l) => l.contains('2018') || aboutBirth.hasMatch(l)), isEmpty);
      expect(const BirthMonth(2018, 12).toString(), isNot(contains('2018')));
    });

    test('the profile row and its JSON, the thing a backup or an export would read, hold no birth', () async {
      await playEverything(p1);
      final Profile row = await p1.profile();
      expect(jsonEncode(row.toJson()), isNot(contains('2018')));
      expect(row.toString(), isNot(contains('2018')));
      expect(jsonEncode(row.toJson()).toLowerCase(), isNot(contains('birth')));
    });

    test('the sync engine, the gateway client and the tutor cannot even name it (source rule)', () {
      final RegExp names = RegExp(
        r'BirthMonth|birthOf|setBirth|ProfileBirth|profile_births|birthYear|birthMonth|childAge\b|ChildAge',
      );
      for (final String dir in <String>[
        'lib/sync',
        'lib/net',
        'lib/tutor',
        'lib/core',
        'lib/push',
        'lib/auth',
        'lib/device',
      ]) {
        for (final FileSystemEntity f in Directory(dir).listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          expect(names.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
        }
      }
    });
  });
}
