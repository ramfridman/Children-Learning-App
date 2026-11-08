// B-29 steps 4 and 5a: the school stage, the look letter and (owner, 2026-11-08) the month and year of birth travel with the family, the
// birth only in child-put and sync-pull. Two simulated phones and the fake family server, which refuses a key the real gateway does not name.
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

    test('a pull with another band than the stage held here clears the stage, so the next save is accepted (SEC-B29-1)', () async {
      await p1.addChild();
      await p1.db.setSchoolStage(kid, SchoolStage.grade2);
      await p1.engine.syncOnce();
      // Another phone saved the child with band 1 (a server before the fix kept grade2 beside it).
      server.children[kid] = <String, Object?>{
        ...server.children[kid]!,
        'age_band': 1,
        'school_stage': 'grade2',
      };
      await p1.engine.syncOnce();
      final Profile pulled = await p1.profile();
      expect(pulled.ageBand, 1);
      expect(pulled.schoolStage, isNull, reason: 'a stage against the band is cleared');
      final int before = _childPuts(server);
      await p1.db.setCompanion(kid, 'hero-son');
      await p1.engine.syncOnce();
      expect(_childPuts(server), before + 1, reason: 'the save went out and the fake server took it');
      expect(server.children[kid]!['companion_id'], 'hero-son');
      expect(server.children[kid]!['age_band'], 1);
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

  group('the month and year of birth travel with the family (owner, 2026-11-08)', () {
    const BirthMonth born = BirthMonth(2018, 12);

    Map<String, Object?> lastChildPut() =>
        jsonDecode(server.wire.lastWhere((w) => w.name == 'child-put' && !w.answer).json)
            as Map<String, Object?>;

    test(
      'a child with a birth is sent with {year, month} and nothing else about it; the server keeps it',
      () async {
        await p1.addChild();
        await p1.db.setBirth(kid, born);
        await p1.engine.syncOnce();
        expect(lastChildPut()['birth'], <String, Object?>{'year': 2018, 'month': 12});
        expect(lastChildPut().keys, isNot(contains('birth_year')));
        expect(server.children[kid]!['birth'], <String, Object?>{'year': 2018, 'month': 12});
      },
    );

    test('a child with none is sent as before: no birth key, so nothing is cleared', () async {
      await p1.addChild();
      await p1.engine.syncOnce();
      expect(lastChildPut().containsKey('birth'), isFalse);
      expect(server.children[kid]!['birth'], isNull);
    });

    test('the other phones get it, and nothing is sent back', () async {
      await p1.addChild();
      await p1.db.setBirth(kid, born);
      await p1.engine.syncOnce();
      final int puts = _childPuts(server);
      await p2.engine.syncOnce();
      expect(await p2.db.birthOf(kid), born);
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(kidPhone.db.close);
      await kidPhone.engine.syncOnce();
      expect(await kidPhone.db.birthOf(kid), born, reason: 'a child device is told too');
      await p2.engine.syncOnce();
      expect(_childPuts(server), puts, reason: 'what a phone was given it does not send back');
    });

    test(
      'changing it sends the child again, once; clearing it sends null and the other phone forgets it',
      () async {
        await p1.addChild();
        await p1.db.setBirth(kid, born);
        await p1.engine.syncOnce();
        await p2.engine.syncOnce();
        final int puts = _childPuts(server);
        await p1.db.setBirth(kid, const BirthMonth(2019, 3));
        await p1.engine.syncOnce();
        await p1.engine.syncOnce();
        expect(_childPuts(server), puts + 1, reason: 'the fingerprint holds the birth');
        expect(server.children[kid]!['birth'], <String, Object?>{'year': 2019, 'month': 3});
        await p2.engine.syncOnce();
        expect(await p2.db.birthOf(kid), const BirthMonth(2019, 3));

        await p1.db.setBirth(kid, null);
        await p1.engine.syncOnce();
        expect(lastChildPut().containsKey('birth'), isTrue, reason: 'null is sent, to clear');
        expect(lastChildPut()['birth'], isNull);
        expect(server.children[kid]!['birth'], isNull);
        await p2.engine.syncOnce();
        expect(await p2.db.birthOf(kid), isNull);
      },
    );

    test('a phone that never had a birth does not clear the server\'s when it saves the child', () async {
      await p1.addChild();
      await p1.db.setBirth(kid, born);
      await p1.engine.syncOnce();
      // The second phone has the child but has not pulled the birth (an older copy of the profile).
      await p2.addChild();
      await p2.db.setCompanion(kid, 'hero-son');
      await p2.engine.syncOnce();
      expect(lastChildPut().containsKey('birth'), isFalse, reason: 'absent keeps');
      expect(server.children[kid]!['birth'], <String, Object?>{'year': 2018, 'month': 12});
      expect(await p2.db.birthOf(kid), born, reason: 'and the pull then gave it to this phone');
    });

    test('the server\'s value is untrusted: a month 13, a future month, a child of ten, a string or extra keys are ignored', () async {
      await p1.addChild();
      await p1.db.setBirth(kid, born);
      await p1.engine.syncOnce();
      for (final Object? bad in <Object?>[
        <String, Object?>{'year': 2018, 'month': 13},
        <String, Object?>{'year': 2026, 'month': 12}, // after the (fake) today, 2026-11-20
        <String, Object?>{'year': 2010, 'month': 1}, // ten or older
        <String, Object?>{'year': '2018', 'month': 12},
        <String, Object?>{'year': 2018},
        '2018-12',
        7,
        <Object?>[2018, 12],
        <String, Object?>{'year': 2019, 'month': 2, 'day': 5},
      ]) {
        server.children[kid] = <String, Object?>{...server.children[kid]!, 'birth': bad};
        await p1.engine.syncOnce();
        expect(await p1.db.birthOf(kid), born, reason: '$bad');
      }
    });

    test('a server older than this change (no birth in the answer) leaves the birth here alone', () async {
      await p1.addChild();
      await p1.db.setBirth(kid, born);
      await p1.engine.syncOnce();
      server.children[kid]!.remove('birth');
      await p1.engine.syncOnce();
      expect(await p1.db.birthOf(kid), born);
    });

    test('a birth entered here and not yet sent is not overwritten by what the server still holds', () async {
      await p1.addChild();
      await p1.db.setBirth(kid, born);
      await p1.engine.syncOnce();
      await p1.db.setBirth(kid, const BirthMonth(2019, 3));
      server.failing.add('child-put');
      await p1.engine.syncOnce();
      server.failing.clear();
      expect(await p1.db.birthOf(kid), const BirthMonth(2019, 3), reason: 'the pull did not undo the edit');
      await p1.engine.syncOnce();
      expect(server.children[kid]!['birth'], <String, Object?>{
        'year': 2019,
        'month': 3,
      }, reason: 'and it went out later');
    });

    test('deleting the child deletes its birth on both sides', () async {
      await p1.addChild();
      await p1.db.setBirth(kid, born);
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await p1.engine.deleteChild(kid);
      await p1.engine.syncOnce();
      expect(server.children.containsKey(kid), isFalse);
      await p2.engine.syncOnce();
      expect(await p2.db.birthOf(kid), isNull);
    });

    test(
      'the fake server is as strict as the real one about a birth (testvectors/profile-sync.json)',
      () async {
        final Map<String, Object?> vectors =
            jsonDecode(File('../testvectors/profile-sync.json').readAsStringSync()) as Map<String, Object?>;
        Future<Map<String, Object?>> put(Object? birth) =>
            server.callFor(dev1)('child-put', <String, Object?>{
              'child_id': kid,
              'nickname': 'נועה',
              'avatar_id': 'avatar-noa',
              'address_form': 'f',
              'age_band': 1,
              'birth': birth,
            });
        for (final Object? ok in vectors['birth_examples']! as List<Object?>) {
          await put(ok);
          expect(server.children[kid]!['birth'], ok);
        }
        await put(null);
        expect(server.children[kid]!['birth'], isNull);
        for (final Object? bad in vectors['birth_refused']! as List<Object?>) {
          await expectLater(put(bad), throwsA(isA<GatewayException>()), reason: '$bad');
        }
      },
    );
  });

  group('the month and year of birth are in child-put and sync-pull and in nothing else', () {
    // A distinctive birth: 2018-12. Allowed only inside the `birth` object of child-put's body and of sync-pull's answer.
    const BirthMonth born = BirthMonth(2018, 12);
    final RegExp aboutBirth = RegExp('birth|born|dob|age_?months|presentation|assumed', caseSensitive: false);

    /// Whether [node] holds the birth (or any other age) where it must not. With [allowBirthKey] a `birth` key is fine when it holds
    /// null or exactly `{year, month}`; the year, the month and every other age key are not fine anywhere else.
    bool holdsBirth(Object? node, {bool allowBirthKey = false}) {
      if (node is Map) {
        return node.entries.any((MapEntry<Object?, Object?> e) {
          if (e.key == 'birth' && allowBirthKey) {
            final Object? v = e.value;
            return !(v == null || (v is Map && v.length == 2 && v['year'] is int && v['month'] is int));
          }
          return aboutBirth.hasMatch('${e.key}') || holdsBirth(e.value, allowBirthKey: allowBirthKey);
        });
      }
      if (node is List) return node.any((Object? n) => holdsBirth(n, allowBirthKey: allowBirthKey));
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

    test('child-put\'s request and sync-pull\'s answer carry it; no other request or answer of any round holds a birth', () async {
      await playEverything(p1);
      for (int i = 0; i < 3; i++) {
        await p1.engine.syncOnce();
        await p2.engine.syncOnce();
      }
      expect(server.children[kid], isNotNull, reason: 'the child did reach the server');
      expect(server.rules!['looks'], isNotNull, reason: 'and so did the look');
      expect(server.wire, isNotEmpty);
      bool carriedIt = false;
      for (final w in server.wire) {
        final bool mayCarry = (w.name == 'child-put' && !w.answer) || (w.name == 'sync-pull' && w.answer);
        final Object? body = jsonDecode(w.json);
        expect(
          holdsBirth(body, allowBirthKey: mayCarry),
          isFalse,
          reason: '${w.name} (answer: ${w.answer}): ${w.json}',
        );
        if (!mayCarry) {
          expect(w.json, isNot(contains('2018')), reason: '${w.name}: ${w.json}');
          expect(w.json, isNot(contains('birth')), reason: '${w.name}: ${w.json}');
        } else if (w.json.contains('"birth":{')) {
          carriedIt = true;
        }
      }
      expect(carriedIt, isTrue, reason: 'it was in child-put and sync-pull');
      // The rules document (settings-put), which every phone gets, never held it.
      expect(jsonEncode(server.rules), isNot(contains('2018')));
    });

    test('the tripwire works: a request that carried the month where it must not would be seen', () {
      Map<String, Object?> b(Map<String, Object?> inner) => <String, Object?>{'birth': inner};
      expect(holdsBirth(<String, Object?>{'birth_month': 12}), isTrue);
      expect(holdsBirth(b(<String, Object?>{'year': 2018, 'month': 12})), isTrue);
      expect(holdsBirth(b(<String, Object?>{'year': 2018, 'month': 12}), allowBirthKey: true), isFalse);
      expect(
        holdsBirth(b(<String, Object?>{'year': 2018, 'month': 12, 'day': 3}), allowBirthKey: true),
        isTrue,
      );
      expect(holdsBirth(<String, Object?>{'birth': '2018-12'}, allowBirthKey: true), isTrue);
      expect(holdsBirth(<String, Object?>{'x': 2018}), isTrue);
      expect(holdsBirth(<String, Object?>{'x': 2018}, allowBirthKey: true), isTrue);
      expect(holdsBirth(<String, Object?>{'x': '2018-12'}), isTrue);
      expect(holdsBirth(<String, Object?>{'age_months': 95}, allowBirthKey: true), isTrue);
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
      await p2.engine.syncOnce();
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

    test('only the age files and a few named ones can name a birth, an age in months or a look stage (source rule)', () {
      expect(ageRuleBreaks(Directory('lib')), isEmpty);
    });

    test('the net, the tutor, the log, the push, the auth, the voice and the sync files other than the sync engine never name a birth', () {
      for (final String dir in <String>[
        'net',
        'tutor',
        'core',
        'push',
        'auth',
        'device',
        'voice',
        'speech',
        'sync',
      ]) {
        for (final FileSystemEntity f in Directory('lib/$dir').listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart') || f.path.endsWith('sync_engine.dart')) continue;
          expect(birthNames.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
          expect(ageNames.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
        }
      }
    });

    test('the source rule catches a stray name and a whole-file import', () {
      final Directory root = Directory.systemTemp.createTempSync('age_rule_');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/play').createSync();
      Directory('${root.path}/engine').createSync();
      Directory('${root.path}/app').createSync();
      File('${root.path}/engine/age.dart').writeAsStringSync('class ChildAge {}');
      File('${root.path}/app/age_providers.dart')
          .writeAsStringSync("import '../engine/age.dart';\nfinal childAgeProvider = 1;");
      File('${root.path}/play/fine.dart').writeAsStringSync("import '../engine/age.dart' show SchoolStage;");
      expect(ageRuleBreaks(root), isEmpty);

      File('${root.path}/play/names.dart').writeAsStringSync('final x = childAgeProvider;');
      File('${root.path}/play/birth.dart').writeAsStringSync('final x = BirthMonth(2018, 1);');
      File('${root.path}/play/whole.dart').writeAsStringSync("import 'package:nitznutz/engine/age.dart';");
      File('${root.path}/play/more.dart')
          .writeAsStringSync("import '../engine/age.dart' show SchoolStage, PresentationStage;");
      final List<String> broken = ageRuleBreaks(root);
      expect(broken.length, 5, reason: '$broken');
      expect(
        broken.join('\n'),
        allOf(contains('names.dart'), contains('birth.dart'), contains('whole.dart'), contains('more.dart')),
      );
    });
  });
}

/// The names that carry a month and year of birth.
final RegExp birthNames = RegExp(
  r'BirthMonth|birthOf|setBirth|ProfileBirth|profile_births|birthYear|birthMonth',
);

/// The names that carry an age in months, an age bundle or a look stage.
final RegExp ageNames = RegExp(
  r'ChildAge|childAge|ageInMonths|assumedMonths|PresentationStage|effectiveStage',
);

/// The files under [root] that break the age rule (B-29, SEC-B29-3, changed 2026-11-08): the month and year of birth may be named only by
/// the age files and by the few files that must handle them (the sync engine that sends and takes them, and the parent pages that
/// ask for them); an age in months or a look stage may be named only by the age files and the files that choose how a screen looks;
/// and any other file may import `engine/age.dart` only as `show SchoolStage`. The report names files by their path under [root].
List<String> ageRuleBreaks(Directory root) {
  // The age files: the types, the tables and database that keep the month, the providers that read it, and the generated code.
  const Set<String> ageFiles = <String>{
    'engine/age.dart',
    'data/tables.dart',
    'data/app_database.dart',
    'data/app_database.g.dart',
    'app/age_providers.dart',
    'app/look_providers.dart',
  };
  // Also allowed to name a birth: the sync engine (sends and takes the family's copy) and the parent pages that ask for it.
  const Set<String> birthFiles = <String>{
    'sync/sync_engine.dart',
    'parent/age_fields.dart',
    'parent/age_page.dart',
    'parent/child_form.dart',
  };
  // Also allowed to name an age in months or a look stage: the files that choose the look and the pace of a screen.
  const Set<String> lookFiles = <String>{
    'design/stage_spec.dart',
    'engine/presentation.dart',
    'engine/gates.dart',
    'parent/look_settings.dart',
    'parent/screens_card.dart',
    'parent/age_cards.dart',
    'app/language_providers.dart',
    'app/lesson_launch.dart',
    'app/app.dart',
    'play/lesson_controller.dart',
    'play/lesson_screen.dart',
    'play/idle_ladder.dart',
    'play/choice_cap.dart',
    'play/activity_frame.dart',
    'child/home_screen.dart',
    'child/land_screen.dart',
    'child/profile_picker.dart',
  };
  final RegExp ageImport = RegExp(r'''\b(?:import|export)\s+['"]([^'"]*)['"]([^;]*);''');
  final List<String> breaks = <String>[];
  for (final FileSystemEntity f in root.listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final String path = f.path.replaceAll(r'\', '/');
    final String inside = path.substring(root.path.replaceAll(r'\', '/').length + 1);
    if (ageFiles.contains(inside)) continue;
    final String source = f.readAsStringSync();
    final bool mayBirth = birthFiles.contains(inside);
    final bool mayLook = mayBirth || lookFiles.contains(inside);
    if (birthNames.hasMatch(source) && !mayBirth) breaks.add('$inside names a birth');
    if (ageNames.hasMatch(source) && !mayLook) breaks.add('$inside names an age or a look stage');
    for (final RegExpMatch m in ageImport.allMatches(source)) {
      final String uri = m.group(1)!;
      if (uri != 'age.dart' && !uri.endsWith('/age.dart')) continue;
      if (!mayLook && !_onlyPureRules(m.group(2)!)) {
        breaks.add('$inside imports all of $uri (use `show SchoolStage`)');
      }
    }
  }
  return breaks;
}

/// Names of `engine/age.dart` that carry no birth and no age in months: the stage and the pure rules over dates. An import that shows only
/// these is fine anywhere.
const Set<String> _pureRules = <String>{
  'SchoolStage',
  'CaptionSetting',
  'captionsShownFor',
  'schoolYearOf',
  'suggestedStage',
  'septemberCardDue',
  'addAgeCardDue',
};

/// Whether an import's tail (`show A, B`) names only the pure rules.
bool _onlyPureRules(String tail) {
  final String t = tail.trim();
  if (!t.startsWith('show ')) return false;
  return t.substring(5).split(',').map((String n) => n.trim()).every(_pureRules.contains);
}
