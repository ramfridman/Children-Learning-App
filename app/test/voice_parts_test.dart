// The voice of a character in several packs: `voice-<id>` and `voice-<id>-N` (N from 2 to 9), each proven on its own and
// joined into one bank. A part that is missing is text only; a line in two parts, a part that fails its checks, and any
// pack named with another suffix are never read.
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

import 'package:nitznutz/content/schemas.dart';

import '../tool/pack_builder_lib.dart';
import 'support/character_fixtures.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const List<(int, int)> _cues = <(int, int)>[(0, 1), (100, 0)];

void main() {
  late PackKey key;
  late Directory dir;
  late AppDatabase db;
  late PackInstaller installer;
  late InstalledCharacterSource source;

  setUpAll(() async => key = await newTestKey());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nn_voice_parts_');
    db = AppDatabase(NativeDatabase.memory());
    installer = PackInstaller(
      root: Directory('${dir.path}${Platform.pathSeparator}packs'),
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

  /// Installs the voice pack `voice-<packOf>` with [lines]; every clip says whose pack it is and which line.
  Future<void> install(String packOf, List<String> lines, {String version = '1.0.0'}) async =>
      installer.install(
        (await buildVoicePack(key, packOf, <String, List<(int, int)>>{
          for (final String l in lines) l: _cues,
        }, version: version)).bytes,
      );

  String played(VoiceBank bank, String line) => utf8.decode(bank.clip('vo:$line')!.mp3);

  group('the pack ids of a voice', () {
    test('part 1 is voice-<id>, part N is voice-<id>-N, and nothing outside 1 to 9 is a part', () {
      expect(voicePackId('hero-son', 1), 'voice-hero-son');
      expect(voicePackId('hero-son', 2), 'voice-hero-son-2');
      expect(voicePackId('hero-son', 9), 'voice-hero-son-9');
      expect(lastVoicePart, 9);
      for (final int bad in <int>[0, 10, -1, 12]) {
        expect(() => voicePackId('hero-son', bad), throwsRangeError);
      }
    });
  });

  group('joining the parts', () {
    test('the lines of every installed part are in one bank, each played from its own pack', () async {
      await install('hero-son', <String>['a.one', 'a.two']);
      await install('hero-son-2', <String>['b.one']);
      await install('hero-son-3', <String>['c.one']);
      final VoiceBank bank = await source.voice('hero-son');
      expect(bank.characterId, 'hero-son');
      expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:a.two', 'vo:b.one', 'vo:c.one'});
      expect(played(bank, 'a.two'), 'mp3:hero-son:a.two');
      expect(played(bank, 'b.one'), 'mp3:hero-son-2:b.one');
      expect(played(bank, 'c.one'), 'mp3:hero-son-3:c.one');
      expect(bank.clip('vo:b.one')!.mouth.openAt(50), isTrue);
    });

    test('a part that is not installed means text only for its lines, with no error', () async {
      await install('hero-son', <String>['a.one']);
      final VoiceBank only1 = await source.voice('hero-son');
      expect(only1.ids, <String>['vo:a.one']);
      expect(only1.has('vo:b.one'), isFalse);
      expect(only1.clip('vo:b.one'), isNull);

      await install('hero-son-2', <String>['b.one']);
      await installer.registry.all();
      final VoiceBank both = await source.voice('hero-son');
      expect(both.length, 2);
    });

    test(
      'part 2 alone is read when part 1 is missing, and a character with no voice has an empty bank',
      () async {
        await install('hero-son-2', <String>['b.one']);
        expect((await source.voice('hero-son')).ids, <String>['vo:b.one']);
        final VoiceBank none = await source.voice('nitzi');
        expect(none.length, 0);
        expect(none.characterId, 'nitzi');
      },
    );

    test(
      'a line that is in two parts refuses the later part; the earlier parts and the others stay',
      () async {
        await install('hero-son', <String>['a.one', 'a.two']);
        await install('hero-son-2', <String>['a.two', 'b.one']);
        await install('hero-son-3', <String>['c.one']);
        final VoiceBank bank = await source.voice('hero-son');
        expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:a.two', 'vo:c.one'});
        expect(played(bank, 'a.two'), 'mp3:hero-son:a.two', reason: 'the first part keeps its recording');
        expect(bank.has('vo:b.one'), isFalse, reason: 'the whole part that repeats a line is refused');
      },
    );

    test(
      'withPart refuses a repeated line with the rules stage, and shares the clips instead of copying them',
      () async {
        await install('hero-son', <String>['a.one']);
        await install('hero-son-2', <String>['a.one']);
        final VoiceBank one = VoiceBank.fromPack((await installer.load('voice-hero-son'))!);
        final VoiceBank two = VoiceBank.fromPack((await installer.load('voice-hero-son-2'))!);
        expect(
          () => one.withPart(two),
          throwsA(
            isA<PackRejected>()
                .having((PackRejected e) => e.stage, 'stage', 'rules')
                .having(
                  (PackRejected e) => e.reason,
                  'reason',
                  contains('"vo:a.one" is in two packs of the voice of hero-son'),
                ),
          ),
        );
        await install('hero-son-3', <String>['c.one']);
        final VoiceBank three = VoiceBank.fromPack((await installer.load('voice-hero-son-3'))!);
        final VoiceBank joined = one.withPart(three);
        expect(identical(joined.clip('vo:a.one'), one.clip('vo:a.one')), isTrue);
        expect(one.length, 1, reason: 'the bank it was made from is not changed');
      },
    );

    test(
      'a part that fails its own checks (a file changed on disk) is left out; the others still play',
      () async {
        await install('hero-son', <String>['a.one']);
        await install('hero-son-2', <String>['b.one']);
        final File clip = File('${dir.path}/packs/voice-hero-son-2/1.0.0/vo.b.one.mp3');
        clip.writeAsBytesSync(<int>[1, 2, 3]);
        final VoiceBank bank = await source.voice('hero-son');
        expect(bank.ids, <String>['vo:a.one']);
      },
    );

    test('a pack not signed by the app\'s key is never installed, so it is never a part', () async {
      final PackKey other = await newTestKey();
      final BuiltPack forged = await buildVoicePack(other, 'hero-son-2', <String, List<(int, int)>>{
        'x.one': _cues,
      });
      await expectLater(installer.install(forged.bytes), throwsA(isA<PackRejected>()));
      await install('hero-son', <String>['a.one']);
      expect((await source.voice('hero-son')).ids, <String>['vo:a.one']);
    });
  });

  group('names that are not parts', () {
    test('only a single digit from 2 to 9 after the id makes a part: 1, 0, 10, 02, letters and a second suffix do not', () async {
      await install('hero-son', <String>['a.one']);
      for (final String suffix in <String>['1', '0', '10', '02', '12', 'x', '2x', 'a2', '2-2', 'two']) {
        await install('hero-son-$suffix', <String>['evil.$suffix'.replaceAll('-', '_')]);
      }
      final VoiceBank bank = await source.voice('hero-son');
      expect(bank.ids, <String>['vo:a.one']);
    });

    test('a character whose id ends in -2 to -9 cannot exist: the character builder and the schema refuse it (SEC-VP-2)', () async {
      final Directory tmp = Directory('${dir.path}/chars')..createSync();
      for (final String id in <String>['hero-son-2', 'hero-son-5', 'hero-son-9', 'abc-3']) {
        await expectLater(
          buildCharacterPack(writeCharacterFolder(tmp, id), key),
          throwsA(isA<BuildFailed>()),
          reason: id,
        );
      }
      // Other endings are ordinary ids.
      for (final String id in <String>[
        'hero-son',
        'hero-son-1',
        'hero-son-10',
        'hero-son-0',
        'hero-son2',
        'abc-12',
      ]) {
        await buildCharacterPack(writeCharacterFolder(tmp, id), key);
      }
      final RegExp pattern = RegExp('^(?:${Patterns.characterId})\$');
      expect(pattern.hasMatch('hero-son-2'), isFalse);
      expect(pattern.hasMatch('hero-son-9'), isFalse);
      expect(pattern.hasMatch('hero-son-1'), isTrue);
      expect(pattern.hasMatch('hero-son-22'), isTrue);
      expect(
        RegExp('^(?:${Patterns.packId})\$').hasMatch('hero-son-2'),
        isTrue,
        reason: 'pack ids are as they were',
      );
    });

    test(
      'as a second layer, voice-<id>-N is not a part of <id> while a character <id>-N is installed',
      () async {
        await install('hero-son', <String>['a.one']);
        await install('hero-son-2', <String>['own.one']);
        expect((await source.voice('hero-son')).ids.toSet(), <String>{
          'vo:a.one',
          'vo:own.one',
        }, reason: 'a part today');
        await installer.registry.save(
          id: 'char-hero-son-2',
          version: '1.0.0',
          manifestSha256: 'a' * 64,
          at: DateTime.utc(2026, 11, 8),
          hidden: false,
          hiddenReason: '',
        );
        expect((await source.voice('hero-son')).ids, <String>['vo:a.one']);
        expect((await source.voice('hero-son-2')).ids, <String>['vo:own.one']);
      },
    );
  });

  group('one build at a time, and a bound on the audio (SEC-VP-3, SEC-VP-4)', () {
    test('a part from another build (another version than the first part read) is left out', () async {
      await install('hero-son', <String>['a.one'], version: '2.0.0');
      await install('hero-son-2', <String>['b.one'], version: '1.0.0');
      await install('hero-son-3', <String>['c.one'], version: '2.0.0');
      final VoiceBank bank = await source.voice('hero-son');
      expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:c.one'});
    });

    test('the first part that is read sets the version, also when part 1 is not installed', () async {
      await install('hero-son-2', <String>['b.one'], version: '3.0.0');
      await install('hero-son-3', <String>['c.one'], version: '2.0.0');
      await install('hero-son-4', <String>['d.one'], version: '3.0.0');
      expect((await source.voice('hero-son')).ids.toSet(), <String>{'vo:b.one', 'vo:d.one'});
    });

    test('a stale part cannot keep an old recording or refuse a fresh part of the same build', () async {
      await install('hero-son', <String>['a.one', 'a.two'], version: '2.0.0');
      await install('hero-son-2', <String>['a.two', 'b.one'], version: '1.0.0');
      final VoiceBank bank = await source.voice('hero-son');
      expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:a.two'});
      expect(played(bank, 'a.two'), 'mp3:hero-son:a.two');
    });

    test(
      'the clips of one voice are bounded across its parts: a part over the cap is left out, the others stay',
      () async {
        expect(maxVoiceBytes, 2 * 64 * 1024 * 1024);
        // Each clip is 'mp3:hero-son:a.one' (18 bytes); the cap here is 40.
        final InstalledCharacterSource small = InstalledCharacterSource(
          installer: installer,
          bundledHouse: () async => Uint8List(0),
          maxVoiceClipBytes: 40,
        );
        await install('hero-son', <String>['a.one', 'a.two']);
        await install('hero-son-2', <String>['b.one', 'b.two', 'b.three']);
        await install('hero-son-3', <String>['c.one']);
        final VoiceBank bank = await small.voice('hero-son');
        expect(bank.clipBytes, lessThanOrEqualTo(40));
        expect(bank.ids.toSet(), <String>{
          'vo:a.one',
          'vo:a.two',
        }, reason: 'part 2 would pass 40, part 3 as well');
        final VoiceBank wide = await source.voice('hero-son');
        expect(wide.length, 6);
        expect(wide.clipBytes, greaterThan(40));
      },
    );
  });
}
