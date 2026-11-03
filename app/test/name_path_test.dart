// B-42 part (d): the name path on the phone. The spelling goes with the child and the family; the clip is made through the
// gateway (a mock here: nothing reaches a provider), kept in the encrypted database by child, character and a hash of the
// spelling, deleted when any of them changes, never synced; only a greeting or the map bubble's clip follows it.
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/sync/sync_engine.dart';
import 'package:nitznutz/voice/name_clips.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/world/welcome_lines.dart';

import 'support/fake_family_server.dart';
import 'support/voice_fixtures.dart';

const String kid = 'child-aaaa-0001';
const String dev1 = 'd1d1d1d1-0000-4000-8000-000000000001';
const String dev2 = 'd2d2d2d2-0000-4000-8000-000000000002';

Uint8List sound(String text) => Uint8List.fromList(utf8.encode(text.padRight(120, '.')));

class Phone {
  Phone(this.id, this.server) : db = AppDatabase(NativeDatabase.memory());

  final String id;
  final FakeFamilyServer server;
  final AppDatabase db;

  late final SyncEngine engine = SyncEngine(
    db: db,
    call: server.callFor(id),
    deviceId: id,
    isParent: true,
    nowMs: () => DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch,
    pageSize: 4,
    batch: 4,
  );

  Future<void> addChild({String name = 'נועה', String? companion}) => db.addProfile(
    ProfilesCompanion.insert(
      id: kid,
      name: name,
      avatar: 'avatar-noa',
      addressForm: 'f',
      ageBand: 1,
      createdAt: DateTime.utc(2026, 11, 1),
      companionId: Value<String?>(companion),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('the sound of the name on the phone', () {
    late AppDatabase db;
    final DateTime at = DateTime.utc(2026, 11, 3, 9);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
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
    });
    tearDown(() => db.close());

    Future<void> keep(String character, String spelling, Uint8List clip) => db.putNameClip(
      profileId: kid,
      characterId: character,
      spellingHash: spellingHash(spelling),
      sound: clip,
      at: at,
    );

    test('no spelling, no clip; a spelling with no clip made yet, no clip', () async {
      expect(await nameClipFor(db, kid, 'nitzi'), isNull);
      await db.setNameSpoken(kid, 'נועה');
      expect(await nameClipFor(db, kid, 'nitzi'), isNull);
    });

    test(
      'a clip is found for the child, the friend and the spelling it was made for, and only those',
      () async {
        await db.setNameSpoken(kid, 'נועה');
        await keep('nitzi', 'נועה', sound('one'));
        expect(await nameClipFor(db, kid, 'nitzi'), sound('one'));
        expect(await nameClipFor(db, kid, 'hero-son'), isNull, reason: 'another friend');
        expect(await nameClipFor(db, 'child-zzzz-9999', 'nitzi'), isNull, reason: 'another child');
      },
    );

    test('a changed spelling deletes the clip; the same spelling saved again keeps it', () async {
      await db.setNameSpoken(kid, 'נועה');
      await keep('nitzi', 'נועה', sound('one'));
      await db.setNameSpoken(kid, 'נועה');
      expect(await nameClipFor(db, kid, 'nitzi'), sound('one'), reason: 'nothing changed');
      await db.setNameSpoken(kid, 'נֹעָה');
      expect(
        await db.nameClipOf(kid, 'nitzi', spellingHash('נועה')),
        isNull,
        reason: 'the old clip is gone from the store',
      );
      expect(await nameClipFor(db, kid, 'nitzi'), isNull);
      await db.setNameSpoken(kid, null);
      expect(await db.nameSpokenOf(kid), isNull, reason: 'the parent cleared it');
    });

    test('a new friend makes the old friend\'s clip unused, and it is deleted when the child plays with the new one', () async {
      await db.setNameSpoken(kid, 'נועה');
      await keep('nitzi', 'נועה', sound('one'));
      expect(await nameClipFor(db, kid, 'hero-son'), isNull);
      expect(
        await db.nameClipOf(kid, 'nitzi', spellingHash('נועה')),
        isNull,
        reason: 'deleted, not kept for later',
      );
    });

    test('a new clip replaces the old one: one clip a child', () async {
      await db.setNameSpoken(kid, 'נועה');
      await keep('nitzi', 'נועה', sound('one'));
      await keep('hero-son', 'נועה', sound('two'));
      expect(await db.nameClipOf(kid, 'nitzi', spellingHash('נועה')), isNull);
      expect(await nameClipFor(db, kid, 'hero-son'), sound('two'));
      await keep('hero-son', 'נועה', sound('three'));
      expect(await nameClipFor(db, kid, 'hero-son'), sound('three'));
    });

    test('deleting the child deletes the clip and the spelling with it', () async {
      await db.setNameSpoken(kid, 'נועה');
      await keep('nitzi', 'נועה', sound('one'));
      await db.deleteChildData(kid);
      expect(await db.select(db.nameClips).get(), isEmpty);
      expect(await db.nameSpokenOf(kid), isNull);
    });

    test('the key is a hash of the spelling, the same everywhere and 16 hex characters', () {
      expect(spellingHash('נועה'), spellingHash('נועה'));
      expect(spellingHash('נועה'), isNot(spellingHash('נֹעָה')));
      expect(spellingHash('נועה'), matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(spellingHash('נועה'), isNot(contains('נועה')));
    });

    test('the table that holds the clips is not a table the sync engine reads or writes', () async {
      final FakeFamilyServer server = FakeFamilyServer();
      final Phone p = Phone(dev1, server);
      addTearDown(p.db.close);
      await p.addChild();
      await p.db.setNameSpoken(kid, 'נועה');
      await p.db.putNameClip(
        profileId: kid,
        characterId: 'nitzi',
        spellingHash: spellingHash('נועה'),
        sound: sound('one'),
        at: at,
      );
      await p.engine.syncOnce();
      final String everythingSent = jsonEncode(server.children) + jsonEncode(server.log);
      expect(everythingSent, isNot(contains(base64Encode(sound('one')))));
      expect(everythingSent, isNot(contains(spellingHash('נועה'))));
      expect(server.calls.where((String c) => c.endsWith('name-voice')), isEmpty);
    });
  });

  group('the spelling goes with the child to the family', () {
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

    test('a parent writes it on one phone, and the other phone has it after a round', () async {
      await p1.addChild();
      await p1.db.setNameSpoken(kid, 'נֹעָה');
      await p1.engine.syncOnce();
      expect(server.children[kid]!['name_spoken'], 'נֹעָה');
      await p2.engine.syncOnce();
      expect(await p2.db.nameSpokenOf(kid), 'נֹעָה');
    });

    test(
      'a child saved with no spelling has none; a spelling cleared on one phone is cleared on the other',
      () async {
        await p1.addChild();
        await p1.db.setNameSpoken(kid, 'נועה');
        await p1.engine.syncOnce();
        await p2.engine.syncOnce();
        expect(await p2.db.nameSpokenOf(kid), 'נועה');
        await p1.db.setNameSpoken(kid, null);
        await p1.engine.syncOnce();
        await p2.engine.syncOnce();
        expect(await p2.db.nameSpokenOf(kid), isNull);
      },
    );

    test('a changed spelling that arrives deletes the clip made from the old one', () async {
      await p1.addChild();
      await p1.db.setNameSpoken(kid, 'נועה');
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await p2.db.putNameClip(
        profileId: kid,
        characterId: 'nitzi',
        spellingHash: spellingHash('נועה'),
        sound: sound('one'),
        at: DateTime.utc(2026, 11, 3),
      );
      await p1.db.setNameSpoken(kid, 'נֹעָה');
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      expect(await p2.db.select(p2.db.nameClips).get(), isEmpty);
    });

    test(
      'a spelling this phone changed and has not sent is not wiped by an older one from the server',
      () async {
        await p1.addChild();
        await p1.db.setNameSpoken(kid, 'נועה');
        await p1.engine.syncOnce();
        await p1.db.setNameSpoken(kid, 'נֹעָה');
        server.failing.add('child-put');
        await p1.engine.syncOnce();
        expect(await p1.db.nameSpokenOf(kid), 'נֹעָה', reason: 'the server still has the old one');
        server.failing.clear();
        await p1.engine.syncOnce();
        expect(server.children[kid]!['name_spoken'], 'נֹעָה', reason: 'and it goes in the next round');
      },
    );

    test(
      'a spelling from the server that is not the narrow rule is not kept (the server\'s copy is untrusted)',
      () async {
        await p1.addChild();
        await p1.engine.syncOnce();
        server.children[kid]!['name_spoken'] = 'Evil <b>';
        await p2.engine.syncOnce();
        expect(await p2.db.nameSpokenOf(kid), isNull);
      },
    );

    test('a spelling outside the rule stays on the phone: the child is still saved, without it', () async {
      await p1.addChild();
      await p1.db.setNameSpoken(kid, 'Noa');
      await p1.engine.syncOnce();
      expect(
        server.children.containsKey(kid),
        isTrue,
        reason: 'the server would have refused the whole child',
      );
      expect(server.children[kid]!['name_spoken'], isNull);
    });
  });

  group('asking the gateway', () {
    Future<Map<String, Object?>> Function(String, Map<String, Object?>) answering(
      Object? audio, {
      Object? mime = 'audio/mpeg',
    }) => (String name, Map<String, Object?> body) async {
      expect(name, 'name-voice');
      expect(body.keys.toSet(), <String>{'child_id', 'character_id'}, reason: 'two ids and nothing else');
      return <String, Object?>{'audio': audio, 'mime': mime, 'chars': 5};
    };
    Future<Map<String, Object?>> Function(String, Map<String, Object?>) failing(String code) =>
        (String name, Map<String, Object?> body) async => throw GatewayException(code, status: 400);

    Future<NameVoiceFailure?> failureOf(NameVoice voice) async {
      try {
        await voice.make(childId: kid, characterId: 'nitzi');
      } on NameVoiceException catch (e) {
        return e.failure;
      }
      return null;
    }

    test('a good answer is the sound', () async {
      final Uint8List clip = sound('hello');
      final Uint8List got = await GatewayNameVoice(answering(base64Encode(clip)))
          .make(childId: kid, characterId: 'nitzi');
      expect(got, clip);
    });

    test('each answer of the gateway is told to the parent in its own way', () async {
      expect(await failureOf(GatewayNameVoice(failing('unavailable'))), NameVoiceFailure.off);
      expect(await failureOf(GatewayNameVoice(failing('rate_limited'))), NameVoiceFailure.cap);
      expect(await failureOf(GatewayNameVoice(failing('bad_request'))), NameVoiceFailure.notThere);
      expect(await failureOf(GatewayNameVoice(failing('not_found'))), NameVoiceFailure.notThere);
      expect(await failureOf(GatewayNameVoice(failing('network'))), NameVoiceFailure.unreachable);
      expect(await failureOf(GatewayNameVoice(failing('unauthorized'))), NameVoiceFailure.unreachable);
      expect(
        await failureOf(
          GatewayNameVoice((String n, Map<String, Object?> b) async => throw StateError('offline')),
        ),
        NameVoiceFailure.unreachable,
      );
    });

    test('anything that is not a small mp3 sound is refused', () async {
      expect(await failureOf(GatewayNameVoice(answering(null))), NameVoiceFailure.unreachable);
      expect(await failureOf(GatewayNameVoice(answering('not base64 !!'))), NameVoiceFailure.unreachable);
      expect(
        await failureOf(GatewayNameVoice(answering(base64Encode(<int>[1, 2, 3])))),
        NameVoiceFailure.unreachable,
        reason: 'too short',
      );
      expect(
        await failureOf(GatewayNameVoice(answering(base64Encode(Uint8List(500 * 1024))))),
        NameVoiceFailure.unreachable,
        reason: 'too long',
      );
      expect(
        await failureOf(GatewayNameVoice(answering(base64Encode(sound('x')), mime: 'text/html'))),
        NameVoiceFailure.unreachable,
      );
    });
  });

  group('only a greeting or the map bubble follows a name clip', () {
    final Uint8List name = sound('the-name');

    test('the director says the name, then the line, in that order', () async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 100);
      final VoiceDirector director = VoiceDirector(player: player);
      addTearDown(director.dispose);
      // A bank is not needed for the name; the line needs one with the clip.
      final VoiceBank bank = VoiceBank.empty('nitzi');
      director.useBank(bank);
      await sayWithName(director, name, homeBubbleVoice);
      expect(player.played.first, name);
    });

    test(
      'a topic, a land line, the closing line and a lesson line are refused before anything is said',
      () async {
        final FakePlayer player = FakePlayer();
        final VoiceDirector director = VoiceDirector(player: player);
        addTearDown(director.dispose);
        for (final String id in <String>[
          'vo:welcome.topic.counting.count',
          'vo:welcome.land.counting',
          welcomeClose,
          'vo:core.greeting.hello',
          'vo:count.butterflies.3',
        ]) {
          await expectLater(sayWithName(director, name, id), throwsArgumentError, reason: id);
        }
        expect(player.plays, 0, reason: 'not even the name was said');
        await sayWithName(director, name, welcomeHelloFirst);
        await sayWithName(director, name, welcomeHellos[2]);
        expect(player.plays, 2, reason: 'a greeting may follow it');
      },
    );
  });
}
