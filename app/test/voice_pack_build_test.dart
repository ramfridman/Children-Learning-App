// B-45: a narrator's voice is made into several signed packs, each of which the app accepts; a pack that is too big fails the
// build but not the clips, and the packs are made again from the saved clips for nothing. All with mock clips and a
// throw-away key: nothing here reaches ElevenLabs, and no real key is read.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_pack_ids.dart';

import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/pack_fixtures.dart';

Map<String, Object?> _realConfig() =>
    jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;

Directory _temp() => Directory.systemTemp.createTempSync('nn_vpack_');

void _drop(Directory d) {
  for (final FileSystemEntity e in <FileSystemEntity>[d, File('${d.path}.voiced.jsonl')]) {
    try {
      e.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}

/// Clips of a fixed size, so that a test can make a pack as big as it likes without a network.
class _Clips implements Synthesizer {
  _Clips({this.bytes = 24});

  final int bytes;
  int said = 0;

  @override
  Future<Synthesis> say(ClipRequest request) async {
    said++;
    return Synthesis(
      Uint8List(bytes)..fillRange(0, bytes, 0x49),
      'mp3',
      const Alignment(<String>['ש', 'ל'], <double>[0, 0.1], <double>[0.1, 0.2]),
    );
  }
}

/// Every voice id the content asks for, each with a plain Hebrew text.
final List<SpokenLine> _realLines = <SpokenLine>[
  for (final String id in <String>{
    for (final SpokenLine l in linesOfContent(Directory('../content/starter'))) l.voId,
    for (final SpokenLine l in coreLines(File('../content/lines/core.he.json'))) l.voId,
  })
    SpokenLine(id, 'שלום.'),
];

/// One line for each of [count] skills: each skill is a unit of its own, so a layout can cut between them.
List<SpokenLine> _skills(int count) => <SpokenLine>[
  for (int i = 1; i <= count; i++) SpokenLine('vo:b.numb${i.toString().padLeft(2, '0')}.1.prompt', 'שלום.'),
];

void main() {
  late PackKey key;
  late Directory work;
  setUpAll(() async => key = await newTestKey());
  setUp(() => work = _temp());
  tearDown(() => _drop(work));

  group('the voice packs of a narrator', () {
    test('are several, and every one of them passes the app\'s own check under ZipLimits', () async {
      final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
      final List<SpokenLine> sample = <SpokenLine>[
        for (final (int i, SpokenLine l) in _realLines.indexed)
          if (i % 3 == 0) l,
      ];
      final List<BuiltPack> built = await generateVoicePack(
        characterId: 'nitzi',
        lines: sample,
        synth: _Clips(),
        profile: nitzi,
        key: key,
        workDir: work,
        version: '2.0.0',
      );
      final List<VoicePackGroup> layout = voicePackLayout('nitzi', nitzi, sample);
      expect(built.length, layout.length);
      expect(built.length, greaterThan(10), reason: 'a narrator is many packs, not one');
      final Set<String> seen = <String>{};
      final List<VerifiedPack> packs = <VerifiedPack>[];
      for (int i = 0; i < built.length; i++) {
        final VerifiedPack pack = await verifyPack(built[i].bytes, publicKey: key.publicKey);
        packs.add(pack);
        expect(pack.id, layout[i].packId);
        expect(built[i].fileName, '${pack.id}-2.0.0.nnpack');
        expect(pack.version, '2.0.0');
        expect(pack.hidden, isFalse);
        expect(isVoicePackOf('nitzi', pack.id), isTrue);
        final List<ZipEntry> entries = readStoredZip(built[i].bytes);
        expect(entries.length, lessThanOrEqualTo(VoicePackLimits.maxEntries), reason: pack.id);
        expect(built[i].bytes.length, lessThanOrEqualTo(VoicePackLimits.maxBytes), reason: pack.id);
        expect(entries.length, layout[i].entries);
        for (final Object? v in pack.manifest['vo']! as List<Object?>) {
          expect(seen.add((v! as Map<String, Object?>)['id']! as String), isTrue, reason: 'in two packs');
        }
      }
      expect(seen, <String>{for (final SpokenLine l in sample) l.fileId}, reason: 'every line is in a pack');
      // The app finds every line, whichever pack holds it.
      final VoiceBank bank = VoiceBank.fromPacks('nitzi', packs);
      expect(bank.length, sample.length);
      expect(bank.characterId, 'nitzi');
      for (final SpokenLine l in sample) {
        expect(bank.has(l.voId), isTrue, reason: l.voId);
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('are signed with the one key, and the same clips give the same packs again', () async {
      final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
      final List<SpokenLine> lines = <SpokenLine>[
        ..._skills(6),
        const SpokenLine('vo:core.greeting.hello', 'שלום.'),
      ];
      final List<BuiltPack> first = await generateVoicePack(
        characterId: 'nitzi',
        lines: lines,
        synth: _Clips(),
        profile: nitzi,
        key: key,
        workDir: work,
        version: '2.0.0',
        maxLines: 2,
      );
      expect(first.map((BuiltPack b) => b.fileName), <String>[
        'voice-nitzi-2.0.0.nnpack',
        'voice-nitzi-part-num-b-1-2.0.0.nnpack',
        'voice-nitzi-part-num-b-2-2.0.0.nnpack',
        'voice-nitzi-part-num-b-3-2.0.0.nnpack',
      ]);
      final List<BuiltPack> again = await repackVoicePacks(
        characterId: 'nitzi',
        lines: lines,
        profile: nitzi,
        key: key,
        workDir: work,
        version: '2.0.0',
        maxLines: 2,
      );
      expect(
        <List<int>>[for (final BuiltPack b in again) b.bytes],
        <List<int>>[for (final BuiltPack b in first) b.bytes],
      );
      for (final BuiltPack b in first) {
        await verifyPack(b.bytes, publicKey: key.publicKey);
        await expectLater(
          verifyPack(b.bytes, publicKey: (await newTestKey()).publicKey),
          throwsA(isA<PackRejected>()),
        );
      }
    });

    test('hold only their own lines: no older pack file or other file of the folder goes in', () async {
      final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
      final List<SpokenLine> lines = _skills(3);
      await generateVoicePack(
        characterId: 'nitzi',
        lines: lines,
        synth: _Clips(),
        profile: nitzi,
        key: key,
        workDir: work,
        maxLines: 1,
      );
      File('${work.path}${Platform.pathSeparator}voice-nitzi-1.3.1.nnpack').writeAsBytesSync(<int>[1, 2, 3]);
      File('${work.path}${Platform.pathSeparator}notes.txt').writeAsStringSync('not a clip');
      File('${work.path}${Platform.pathSeparator}pack.json').writeAsStringSync('{}');
      final List<BuiltPack> built = await repackVoicePacks(
        characterId: 'nitzi',
        lines: lines,
        profile: nitzi,
        key: key,
        workDir: work,
        maxLines: 1,
      );
      expect(built.length, 3);
      for (final BuiltPack b in built) {
        expect(
          readStoredZip(b.bytes).map((ZipEntry e) => e.name),
          everyElement(matches(RegExp(r'^(vo\.|cue\.|manifest)'))),
        );
        expect(
          readStoredZip(b.bytes).length,
          4,
          reason: 'one sound, one cue file, the manifest and its signature',
        );
      }
    });
  });

  group('a friend', () {
    test('keeps one small pack with the plain id, however the ids of its lines look', () async {
      final VoiceProfile tamir = VoiceProfile.fromConfig(_realConfig(), 'tower-tamir');
      final List<VoicePackGroup> layout = voicePackLayout('tower-tamir', tamir, _realLines);
      expect(layout.single.packId, 'voice-tower-tamir');
      expect(layout.single.voIds, hasLength(9));
      final List<BuiltPack> built = await generateVoicePack(
        characterId: 'tower-tamir',
        lines: _realLines,
        synth: _Clips(),
        profile: tamir,
        key: key,
        workDir: work,
        version: '2.0.0',
      );
      expect(built.single.fileName, 'voice-tower-tamir-2.0.0.nnpack');
      final VerifiedPack pack = await verifyPack(built.single.bytes, publicKey: key.publicKey);
      expect(VoiceBank.fromPack(pack).length, 9);
      expect(characterOfVoicePack(pack.id), 'tower-tamir');
    });

    test('keeps one pack even when its own lines are lessons, which a narrator\'s would be cut by land', () {
      final String lesson = _realLines.firstWhere((SpokenLine l) => l.voId.startsWith('vo:b.numb')).voId;
      final String old = _realLines.firstWhere((SpokenLine l) => l.voId.startsWith('vo:col.')).voId;
      final VoiceProfile friend = VoiceProfile.fromConfig(<String, Object?>{
        ..._realConfig(),
        'ownLines': <String>['vo:core.greeting.hello', lesson, old],
      }, 'tower-tamir');
      expect(voicePackLayout('tower-tamir', friend, _realLines).single.voIds, hasLength(3));
    });
  });

  group('the size guard', () {
    const int mib = 1024 * 1024;

    test('fails the build of a pack over 40 MiB, but keeps every clip, and builds nothing', () async {
      final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
      final _Clips clips = _Clips(bytes: mib);
      await expectLater(
        generateVoicePack(
          characterId: 'nitzi',
          lines: _skills(41),
          synth: clips,
          profile: nitzi,
          key: key,
          workDir: work,
        ),
        throwsA(
          isA<VoiceGenFailed>()
              .having((VoiceGenFailed e) => e.message, 'pack', contains('voice-nitzi-part-num-b'))
              .having((VoiceGenFailed e) => e.message, 'free', contains('none needs to be paid for again'))
              .having(
                (VoiceGenFailed e) => e.message,
                'how',
                contains('voice_gen.dart pack nitzi --max-lines'),
              ),
        ),
      );
      expect(clips.said, 41, reason: 'every clip was made and kept');
      final List<String> files = <String>[
        for (final FileSystemEntity e in work.listSync()) e.uri.pathSegments.last,
      ];
      expect(files.where((String f) => f.startsWith('vo.')), hasLength(41));
      expect(files.where((String f) => f.startsWith('cue.')), hasLength(41));
      expect(files.where((String f) => f.endsWith('.nnpack')), isEmpty);
      expect(ClipLedger(work).hashes(), hasLength(41), reason: 'the cache of what was paid for is whole');
    });

    test(
      'is mended for nothing: the packs are made again from the same clips with fewer lines in each',
      () async {
        final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
        final _Clips clips = _Clips(bytes: mib);
        await expectLater(
          generateVoicePack(
            characterId: 'nitzi',
            lines: _skills(41),
            synth: clips,
            profile: nitzi,
            key: key,
            workDir: work,
          ),
          throwsA(isA<VoiceGenFailed>()),
        );
        final List<BuiltPack> built = await repackVoicePacks(
          characterId: 'nitzi',
          lines: _skills(41),
          profile: nitzi,
          key: key,
          workDir: work,
          version: '2.0.0',
          maxLines: 20,
        );
        expect(clips.said, 41, reason: 'nothing was said again');
        expect(built.map((BuiltPack b) => b.fileName), <String>[
          'voice-nitzi-part-num-b-1-2.0.0.nnpack',
          'voice-nitzi-part-num-b-2-2.0.0.nnpack',
          'voice-nitzi-part-num-b-3-2.0.0.nnpack',
        ]);
        for (final BuiltPack b in built) {
          expect(b.bytes.length, lessThanOrEqualTo(VoicePackLimits.maxBytes));
          expect(b.bytes.length, lessThan(ZipLimits.maxZipBytes));
          await verifyPack(b.bytes, publicKey: key.publicKey);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('packing again from the saved clips', () {
    test('has no voice to ask, so it cannot say a line or spend anything', () {
      final String lib = File('tool/voice_gen_lib.dart').readAsStringSync();
      final String repack = lib.substring(
        lib.indexOf('Future<List<BuiltPack>> repackVoicePacks('),
        lib.indexOf('Future<List<BuiltPack>> buildVoicePacks('),
      );
      expect(repack, isNot(contains('Synthesizer')));
      expect(repack, isNot(contains('synth')));
      expect(repack, isNot(contains('.say(')));
      final String build = lib.substring(lib.indexOf('Future<List<BuiltPack>> buildVoicePacks('));
      expect(build.substring(0, build.indexOf('/// Whether any file under')), isNot(contains('.say(')));
      final String cli = File('tool/voice_gen.dart').readAsStringSync();
      final String pack = cli.substring(
        cli.indexOf('Future<void> _pack('),
        cli.indexOf('Future<void> _generate('),
      );
      expect(pack, isNot(contains('_eleven')));
      expect(pack, isNot(contains('Platform.environment')));
      expect(pack, isNot(contains('requireTyped')));
      expect(cli, contains("case 'pack':"));
      expect(
        cli,
        contains("const Set<String> _paid = <String>{'generate', 'audition'};"),
        reason: 'pack is not paid',
      );
    });

    test(
      'refuses, and builds nothing, when a line has no clip, or only a clip made from other settings',
      () async {
        final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
        final List<SpokenLine> lines = _skills(3);
        await generateVoicePack(
          characterId: 'nitzi',
          lines: lines,
          synth: _Clips(),
          profile: nitzi,
          key: key,
          workDir: work,
        );
        Future<List<BuiltPack>> repack(VoiceProfile p, List<SpokenLine> l) =>
            repackVoicePacks(characterId: 'nitzi', lines: l, profile: p, key: key, workDir: work);
        await repack(nitzi, lines);
        // A line that was never made.
        await expectLater(
          repack(nitzi, <SpokenLine>[...lines, const SpokenLine('vo:b.numb09.1.prompt', 'שלום.')]),
          throwsA(
            isA<VoiceGenFailed>()
                .having((VoiceGenFailed e) => e.message, 'count', startsWith('1 lines have no clip'))
                .having((VoiceGenFailed e) => e.message, 'which', contains('vo:b.numb09.1.prompt'))
                .having((VoiceGenFailed e) => e.message, 'what to do', contains('run `generate` first')),
          ),
        );
        // A line whose text changed since its clip was made.
        await expectLater(
          repack(nitzi, <SpokenLine>[const SpokenLine('vo:b.numb01.1.prompt', 'כן.'), ...lines.skip(1)]),
          throwsA(isA<VoiceGenFailed>()),
        );
        // A clip that was lost.
        File('${work.path}${Platform.pathSeparator}vo.b.numb02.1.prompt.mp3').deleteSync();
        await expectLater(repack(nitzi, lines), throwsA(isA<VoiceGenFailed>()));
      },
    );

    test('refuses a work folder written as "." or ".."', () async {
      final VoiceProfile nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi');
      await expectLater(
        repackVoicePacks(
          characterId: 'nitzi',
          lines: _skills(1),
          profile: nitzi,
          key: key,
          workDir: Directory('${work.path}${Platform.pathSeparator}..'),
        ),
        throwsA(isA<VoiceGenFailed>()),
      );
    });
  });
}
