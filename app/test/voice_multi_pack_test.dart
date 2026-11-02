// B-45: a character's voice may be several packs (a narrator's is about sixteen). The app looks a line up across all of
// them, and the narrator fallback of a friend works as before.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const List<(int, int)> _cues = <(int, int)>[(0, 1), (100, 0)];

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());

  Future<BuiltPack> pack(String character, String packId, List<String> lines, {String version = '2.0.0'}) =>
      buildVoicePack(
        key,
        character,
        <String, List<(int, int)>>{for (final String l in lines) l: _cues},
        version: version,
        packId: packId,
      );

  Future<VerifiedPack> verified(BuiltPack b) => verifyPack(b.bytes, publicKey: key.publicKey);

  String said(VoiceBank bank, String voId) => utf8.decode(bank.clip(voId)!.mp3);

  group('VoiceBank.fromPacks', () {
    test('finds a line in whichever pack holds it', () async {
      final VoiceBank bank = VoiceBank.fromPacks('nitzi', <VerifiedPack>[
        await verified(await pack('nitzi', 'voice-nitzi', <String>['core.greeting.hello'])),
        await verified(await pack('nitzi', 'voice-nitzi-part-num-b-1', <String>['b.numb03.1.prompt'])),
        await verified(
          await pack('nitzi', 'voice-nitzi-part-col-a', <String>['col.find.1.prompt', 'col.find.2.prompt']),
        ),
      ]);
      expect(bank.characterId, 'nitzi');
      expect(bank.length, 4);
      expect(bank.ids.toSet(), <String>{
        'vo:core.greeting.hello',
        'vo:b.numb03.1.prompt',
        'vo:col.find.1.prompt',
        'vo:col.find.2.prompt',
      });
      expect(bank.has('vo:b.numb03.1.prompt'), isTrue);
      expect(said(bank, 'vo:col.find.2.prompt'), 'mp3:nitzi:col.find.2.prompt');
      expect(bank.clip('vo:col.find.1.prompt')!.mouth.openAt(50), isTrue, reason: 'its own cues');
      expect(bank.clip('vo:no.such.line'), isNull);
      expect(bank.has('vo:no.such.line'), isFalse);
    });

    test(
      'one pack read alone is the same bank as before, and its character comes from the pack id',
      () async {
        final VerifiedPack part = await verified(
          await pack('nitzi', 'voice-nitzi-part-num-b-1', <String>['b.numb03.1.prompt']),
        );
        final VoiceBank bank = VoiceBank.fromPack(part);
        expect(bank.characterId, 'nitzi');
        expect(bank.length, 1);
        expect(
          VoiceBank.fromPack(await verified(await pack('hero-son', 'voice-hero-son', <String>['a'])))
              .characterId,
          'hero-son',
        );
      },
    );

    test(
      'a line in two packs (an older layout left behind) is the newer pack\'s, whatever the order',
      () async {
        final VerifiedPack old = await verified(
          await pack('nitzi', 'voice-nitzi', <String>['core.a', 'core.b'], version: '1.3.1'),
        );
        final VerifiedPack core = await verified(
          await pack('nitzi', 'voice-nitzi-part-a', <String>['core.a']),
        );
        for (final List<VerifiedPack> order in <List<VerifiedPack>>[
          <VerifiedPack>[old, core],
          <VerifiedPack>[core, old],
        ]) {
          final VoiceBank bank = VoiceBank.fromPacks('nitzi', order);
          expect(bank.length, 2);
          expect(bank.clip('vo:core.a'), isNotNull);
        }
        // The clips' bytes name the character they were built for, which tells the two packs apart.
        final VerifiedPack newer = await buildVoicePack(
          key,
          'nitzi-new',
          <String, List<(int, int)>>{'core.a': _cues},
          version: '2.0.0',
          packId: 'voice-nitzi-part-z',
        ).then(verified);
        final VoiceBank bank = VoiceBank.fromPacks('nitzi', <VerifiedPack>[old, newer]);
        expect(said(bank, 'vo:core.a'), 'mp3:nitzi-new:core.a');
        expect(said(bank, 'vo:core.b'), 'mp3:nitzi:core.b', reason: 'a line only the old pack has is kept');
      },
    );

    test('between equal versions the pack that comes first by id wins, always', () async {
      final VerifiedPack a = await buildVoicePack(key, 'x1', <String, List<(int, int)>>{
        'core.a': _cues,
      }, packId: 'voice-nitzi-part-a').then(verified);
      final VerifiedPack b = await buildVoicePack(key, 'x2', <String, List<(int, int)>>{
        'core.a': _cues,
      }, packId: 'voice-nitzi-part-b').then(verified);
      expect(said(VoiceBank.fromPacks('nitzi', <VerifiedPack>[a, b]), 'vo:core.a'), 'mp3:x1:core.a');
      expect(said(VoiceBank.fromPacks('nitzi', <VerifiedPack>[b, a]), 'vo:core.a'), 'mp3:x1:core.a');
    });

    test('a friend\'s one pack still borrows the narrator\'s lines, now spread over several packs', () async {
      final VoiceBank friend = VoiceBank.fromPacks('tower-tamir', <VerifiedPack>[
        await verified(await pack('tower-tamir', 'voice-tower-tamir', <String>['core.greeting.hello'])),
      ]);
      final VoiceBank narrator = VoiceBank.fromPacks('hero-son', <VerifiedPack>[
        await verified(await pack('hero-son', 'voice-hero-son', <String>['core.greeting.hello'])),
        await verified(
          await pack('hero-son', 'voice-hero-son-part-num-a-2', <String>['next.after.2.prompt']),
        ),
      ]);
      final VoiceBank guide = VoiceBank.withFallback(friend, narrator);
      expect(said(guide, 'vo:core.greeting.hello'), 'mp3:tower-tamir:core.greeting.hello');
      expect(said(guide, 'vo:next.after.2.prompt'), 'mp3:hero-son:next.after.2.prompt');
      expect(guide.characterId, 'tower-tamir');
    });
  });

  group('the installed voice of a character', () {
    late Directory dir;
    late Directory root;
    late AppDatabase db;
    late PackInstaller installer;
    late InstalledCharacterSource source;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('nn_voices_');
      root = Directory('${dir.path}${Platform.pathSeparator}packs');
      db = AppDatabase(NativeDatabase.memory());
      installer = PackInstaller(
        root: root,
        registry: DbPackRegistry(db),
        publicKey: key.publicKey,
        capabilities: AppCapabilities.current,
      );
      source = InstalledCharacterSource(installer: installer, bundledHouse: () async => Uint8List(0));
    });

    tearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    Future<void> install(String character, String packId, List<String> lines) async =>
        installer.install((await pack(character, packId, lines)).bytes);

    test('is all its packs in one bank, and nothing from another character\'s packs', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.greeting.hello']);
      await install('nitzi', 'voice-nitzi-part-num-b-1', <String>['b.numb03.1.prompt']);
      await install('nitzi', 'voice-nitzi-part-col-a', <String>['col.find.1.prompt']);
      await install('hero-son', 'voice-hero-son', <String>['core.greeting.hello', 'b.numb03.2.prompt']);
      final VoiceBank bank = await source.voice('nitzi');
      expect(bank.characterId, 'nitzi');
      expect(bank.ids.toSet(), <String>{
        'vo:core.greeting.hello',
        'vo:b.numb03.1.prompt',
        'vo:col.find.1.prompt',
      });
      expect(said(bank, 'vo:b.numb03.1.prompt'), 'mp3:nitzi:b.numb03.1.prompt');
      expect(bank.has('vo:b.numb03.2.prompt'), isFalse, reason: 'hero-son\'s line');
    });

    test('a character whose id starts like another\'s is not given the other\'s packs', () async {
      await install('hero-son', 'voice-hero-son', <String>['core.greeting.hello']);
      await install('hero-son', 'voice-hero-son-part-col-a', <String>['col.find.1.prompt']);
      expect((await source.voice('hero')).length, 0);
      expect((await source.voice('hero-son')).length, 2);
    });

    test('a character with no voice pack has an empty bank, as before', () async {
      final VoiceBank bank = await source.voice('nitzi');
      expect(bank.length, 0);
      expect(bank.characterId, 'nitzi');
    });

    test('a pack that no longer proves itself is left out and the others are kept', () async {
      await install('nitzi', 'voice-nitzi', <String>['core.greeting.hello']);
      await install('nitzi', 'voice-nitzi-part-col-a', <String>['col.find.1.prompt']);
      final File sound = File(
        '${root.path}${Platform.pathSeparator}voice-nitzi-part-col-a${Platform.pathSeparator}2.0.0${Platform.pathSeparator}vo.col.find.1.prompt.mp3',
      );
      sound.writeAsBytesSync(<int>[...sound.readAsBytesSync(), 1]);
      final VoiceBank bank = await source.voice('nitzi');
      expect(bank.ids.toSet(), <String>{'vo:core.greeting.hello'});
    });

    test('a new version of a pack id replaces the old one, so a line only the old one had is gone', () async {
      await installer.install(
        (await pack('nitzi', 'voice-nitzi', <String>['core.a', 'core.b'], version: '1.3.1')).bytes,
      );
      await installer.install(
        (await buildVoicePack(
          key,
          'nitzi-new',
          <String, List<(int, int)>>{'core.a': _cues},
          version: '2.0.0',
          packId: 'voice-nitzi',
        )).bytes,
      );
      final VoiceBank bank = await source.voice('nitzi');
      expect(said(bank, 'vo:core.a'), 'mp3:nitzi-new:core.a');
      expect(
        bank.has('vo:core.b'),
        isFalse,
        reason: 'the pack was replaced by the newer version of the same id',
      );
    });
  });
}
