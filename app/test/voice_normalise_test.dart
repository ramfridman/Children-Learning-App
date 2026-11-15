// `voice_gen normalise`: free, local, keyless loudness for the voice packs (tool/loudness_lib.dart). The logic is tested
// with a pretend ffmpeg; the real ffmpeg (tiny generated tones) checks that the loudness lands on target, that nothing but the
// sound changes in a pack, and that the originals are left byte for byte as they were. Without ffmpeg on the PC those cases
// are skipped, and the pretend-ffmpeg ones still run.
@Timeout(Duration(minutes: 6))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart' show ZipLimits;

import '../tool/loudness_lib.dart';
import '../tool/pack_builder_lib.dart';

final String _sep = Platform.pathSeparator;

bool _hasFfmpeg() {
  try {
    return Process.runSync('ffmpeg', const <String>['-version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

final bool _ffmpeg = _hasFfmpeg();
final Object _skip = _ffmpeg ? false : 'ffmpeg is not on the PATH';

/// A tone whose peak is at [dbfs] (lavfi's sine is 18 dB under full scale), as the voice's own clips are: MP3, mono, 44.1 kHz, 64 kbps.
void _tone(File out, {required double seconds, required double dbfs, double hz = 330}) {
  final ProcessResult r = Process.runSync('ffmpeg', <String>[
    '-nostdin',
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=$hz:duration=$seconds:sample_rate=44100',
    '-af',
    'volume=${dbfs + 18.06}dB',
    '-codec:a',
    'libmp3lame',
    '-b:a',
    '64k',
    '-ac',
    '1',
    out.path,
  ]);
  expect(r.exitCode, 0, reason: '${r.stderr}');
}

void _silence(File out, double seconds) {
  final ProcessResult r = Process.runSync('ffmpeg', <String>[
    '-nostdin',
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-f',
    'lavfi',
    '-i',
    'anullsrc=r=44100:cl=mono',
    '-t',
    '$seconds',
    '-codec:a',
    'libmp3lame',
    '-b:a',
    '64k',
    out.path,
  ]);
  expect(r.exitCode, 0, reason: '${r.stderr}');
}

/// The length of an MP3 in seconds, as ffmpeg reports it.
double _seconds(File f) {
  final ProcessResult r = Process.runSync('ffmpeg', <String>['-nostdin', '-hide_banner', '-i', f.path]);
  final RegExpMatch m = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)').firstMatch('${r.stderr}')!;
  return int.parse(m.group(1)!) * 3600 + int.parse(m.group(2)!) * 60 + double.parse(m.group(3)!);
}

Uint8List _bytes(File f) => f.readAsBytesSync();

String _cue(String id) => jsonEncode(<String, Object?>{
  'schema': 'cue/v1',
  'id': id,
  'cues': <Object?>[
    <String, Object?>{'t': 0, 'o': 1},
    <String, Object?>{'t': 400, 'o': 0},
  ],
});

/// A pack of tones with the shape of a voice pack: `vo` lists ids with files (two ids share one file), a cue document for
/// each id. Returns its source folder.
Directory _voiceSource(Directory root, {String id = 'voice-tonetest', String version = '1.0.0'}) {
  final Directory dir = Directory('${root.path}$_sep$id-src')..createSync(recursive: true);
  File f(String name) => File('${dir.path}$_sep$name');
  _tone(f('vo.a.quiet.mp3'), seconds: 2.0, dbfs: -34);
  _tone(f('vo.a.loud.mp3'), seconds: 2.0, dbfs: -12, hz: 700);
  _tone(f('vo.a.mid.mp3'), seconds: 1.5, dbfs: -24, hz: 440);
  _tone(f('vo.a.short.mp3'), seconds: 0.25, dbfs: -30, hz: 500);
  _silence(f('vo.a.silent.mp3'), 1.0);
  final List<Map<String, String>> vo = <Map<String, String>>[
    <String, String>{'id': 'a.quiet', 'file': 'vo.a.quiet.mp3'},
    <String, String>{'id': 'a.quiet.twin', 'file': 'vo.a.quiet.mp3'},
    <String, String>{'id': 'a.loud', 'file': 'vo.a.loud.mp3'},
    <String, String>{'id': 'a.mid', 'file': 'vo.a.mid.mp3'},
    <String, String>{'id': 'a.short', 'file': 'vo.a.short.mp3'},
    <String, String>{'id': 'a.silent', 'file': 'vo.a.silent.mp3'},
  ];
  for (final Map<String, String> v in vo) {
    f('cue.${v['id']}.json').writeAsStringSync(_cue(v['id']!));
  }
  f('pack.json').writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schema': 'pack-source/v1',
      'id': id,
      'version': version,
      'minAppVersion': '0.3.0',
      'assets': <Object?>[],
      'vo': vo,
    }),
  );
  return dir;
}

void main() {
  late Directory tmp;
  late PackKey key;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('nn_loud_test_');
    key = await generateKeyFile('${tmp.path}${_sep}test.key');
  });

  tearDownAll(() {
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // The system's temporary folder is cleared in time.
    }
  });

  group('what ffmpeg says', () {
    test('summaries are read by the number of the clip, whatever their order; -70 is no loudness, -inf is silence', () {
      const String log = '''
[ebur128@m1 @ 000001] Summary:

  Integrated loudness:
    I:         -31.2 LUFS
    Threshold: -41.2 LUFS

  Loudness range:
    LRA:         0.0 LU

  True peak:
    Peak:       -8.5 dBFS
[ebur128@m0 @ 000002] Summary:

  Integrated loudness:
    I:         -70.0 LUFS
    Threshold:   0.0 LUFS

  True peak:
    Peak:      -18.1 dBFS
[ebur128@m2 @ 000003] Summary:

  Integrated loudness:
    I:         -70.0 LUFS

  True peak:
    Peak:        -inf dBFS
size=N/A time=00:00:03.52
''';
      final Map<int, Loudness> found = parseSummaries(log);
      expect(found[1]!.lufs, -31.2);
      expect(found[1]!.truePeak, -8.5);
      expect(found[0]!.lufs, isNull);
      expect(found[0]!.truePeak, -18.1);
      expect(found[2]!.silent, isTrue);
      expect(() => parseSummaries('[ebur128@m0 @ 1] Summary:\n  nothing useful'), throwsA(anything));
    });

    test(
      'the arguments name one measurement per clip, and never change the speed or the length of a clip',
      () {
        final List<String> measure = measureArguments(<String>['a.mp3', 'b.mp3']);
        expect(measure.join(' '), contains('[0:a]ebur128@m0=peak=true'));
        expect(measure.join(' '), contains('[1:a]ebur128@m1=peak=true'));
        final List<String> render = renderArguments(<RenderJob>[RenderJob('in.mp3', 'out.mp3', 12.5, -1.5)]);
        final String text = render.join(' ');
        expect(text, contains('volume=12.500dB'));
        expect(text, contains('alimiter=limit=0.8414'));
        expect(text, contains('level=0'));
        expect(text, contains('-codec:a libmp3lame -b:a 64k -ar 44100 -ac 1'));
        for (final String never in <String>['atempo', 'asetrate', 'aresample', '-ss', '-to', '-t ', 'trim']) {
          expect(text, isNot(contains(never)), reason: 'a clip must keep its length and speed');
        }
      },
    );
  });

  group('the numbers', () {
    test('a pack version goes up by its minor number', () {
      expect(nextMinor('2.0.1'), '2.1.0');
      expect(nextMinor('1.9.0'), '1.10.0');
      expect(() => nextMinor('2.0'), throwsA(anything));
    });

    test(
      'statistics: minimum, median, maximum, loudest peak, and the clips with no loudness counted apart',
      () {
        final LoudnessStats s = LoudnessStats(const <Loudness>[
          Loudness(lufs: -30, truePeak: -10),
          Loudness(lufs: -20, truePeak: -4),
          Loudness(lufs: -24, truePeak: -6),
          Loudness(lufs: -22, truePeak: -5),
          Loudness(lufs: null, truePeak: -9),
        ]);
        expect((s.min, s.median, s.max), (-30.0, -23.0, -20.0));
        expect(s.maxTruePeak, -4);
        expect((s.clips, s.unmeasured), (5, 1));
      },
    );

    test('the newest version of a voice is found, with all its parts and no other pack', () {
      final Directory d = Directory('${tmp.path}${_sep}found')..createSync();
      for (final String n in <String>[
        'voice-nitzi-2.0.0.nnpack',
        'voice-nitzi-2-2.0.0.nnpack',
        'voice-nitzi-2.0.1.nnpack',
        'voice-nitzi-2-2.0.1.nnpack',
        'voice-nitzi-10.0.0.nnpack.bak',
        'voice-nitzi-3.2.0.nnpack.loudness.json',
        'voice-other-9.0.0.nnpack',
        'char-nitzi-1.0.0.nnpack',
      ]) {
        File('${d.path}$_sep$n').writeAsBytesSync(<int>[1]);
      }
      final List<FoundPack> found = newestVoicePacks(d, 'voice-nitzi');
      expect(found.map((FoundPack p) => (p.part, p.version, p.file.uri.pathSegments.last)).toList(), <Object>[
        (1, '2.0.1', 'voice-nitzi-2.0.1.nnpack'),
        (2, '2.0.1', 'voice-nitzi-2-2.0.1.nnpack'),
      ]);
      expect(() => newestVoicePacks(d, 'voice-absent'), throwsA(anything));
    });

    test('the output folder may not be the folder of the originals, or inside it', () {
      final Directory from = Directory('${tmp.path}${_sep}voice${_sep}nitzi');
      expect(() => checkOutputFolder(from, from), throwsA(anything));
      expect(() => checkOutputFolder(from, Directory('${from.path}${_sep}loud')), throwsA(anything));
      checkOutputFolder(from, Directory('${tmp.path}${_sep}voice-loud${_sep}nitzi'));
    });
  });

  group('the gain of each clip (a pretend ffmpeg)', () {
    test('every clip gets target minus its loudness, a short one its peak\'s share, silence none', () async {
      final _FakeTool tool = _FakeTool(<String, Loudness>{
        'a': const Loudness(lufs: -32, truePeak: -16), // 16 dB peak over loudness
        'b': const Loudness(lufs: -24, truePeak: -10), // 14 dB
        'c': const Loudness(lufs: -20, truePeak: -6), // 14 dB
        'short': const Loudness(lufs: null, truePeak: -20),
        'silent': const Loudness(lufs: null, truePeak: double.negativeInfinity),
      });
      final List<ClipResult> r = await _run(tmp, tool, <String>['a', 'b', 'c', 'short', 'silent']);
      expect(r[0].gainDb, closeTo(16, 1.0));
      expect(r[1].gainDb, closeTo(8, 0.5));
      expect(r[2].gainDb, closeTo(4, 0.5));
      // The median peak is 14 dB over loudness: this clip is taken to be at -20 - 14 = -34 LUFS, so it gets 18 dB.
      expect(r[3].gainDb, closeTo(18, 0.5));
      expect(r[3].notes, contains('short'));
      expect(r[4].gainDb, 0);
      expect(r[4].notes, contains('silent'));
      expect(
        tool.rendered.any((RenderJob j) => j.input.endsWith('silent')),
        isFalse,
        reason: 'silence is copied, not encoded',
      );
      expect(File('${tmp.path}${_sep}fake-out${_sep}silent').readAsStringSync(), 'input-silent');
      for (final ClipResult c in r) {
        expect(c.after.truePeak, lessThanOrEqualTo(maxTruePeak));
      }
    });

    test('a true peak over the limit is made again with the limiter lower, and a loudness the limiter took away with more gain', () async {
      // The pretend limiter overshoots by 0.8 dB, so the first pass is over -1 dBTP.
      final _FakeTool tool = _FakeTool(<String, Loudness>{
        'peaky': const Loudness(lufs: -30, truePeak: -14),
      }, overshoot: 0.8);
      final List<ClipResult> r = await _run(tmp, tool, <String>['peaky']);
      expect(tool.renderRounds, greaterThan(1));
      expect(r.single.after.truePeak, lessThanOrEqualTo(maxTruePeak));
      expect(r.single.after.lufs!, closeTo(targetLufs, 0.8));
    });

    test(
      'a clip that would need more limiting than allowed stays quieter and is listed as off target',
      () async {
        final _FakeTool tool = _FakeTool(<String, Loudness>{
          'spike': const Loudness(lufs: -34, truePeak: -2),
          'body': const Loudness(lufs: -30, truePeak: -16),
        });
        final List<ClipResult> r = await _run(tmp, tool, <String>['spike', 'body']);
        expect(r[0].limitedDb, lessThanOrEqualTo(defaultMaxLimiting + 0.5));
        expect(r[0].notes, contains('off target'));
        expect(r[1].notes, isNot(contains('off target')));
      },
    );

    test('a very quiet clip is never given more than 30 dB, and is listed as off target', () async {
      final _FakeTool tool = _FakeTool(<String, Loudness>{'faint': const Loudness(lufs: -58, truePeak: -54)});
      final List<ClipResult> r = await _run(tmp, tool, <String>['faint']);
      expect(r.single.gainDb, lessThanOrEqualTo(30));
      expect(r.single.notes, containsAll(<String>['gain capped', 'off target']));
    });

    test('the run refuses to go on when a peak cannot be brought under the limit', () async {
      final _FakeTool tool = _FakeTool(<String, Loudness>{
        'bad': const Loudness(lufs: -30, truePeak: -8),
      }, stuckPeak: 3);
      await expectLater(_run(tmp, tool, <String>['bad']), throwsA(anything));
    });
  });

  group('no network, no key', () {
    test('the loudness code has no way to the network and no way to a key', () {
      final String lib = File('tool/loudness_lib.dart').readAsStringSync();
      for (final String never in <String>[
        'package:http',
        'HttpClient',
        'Socket',
        'WebSocket',
        'ElevenLabs',
        'ELEVENLABS',
        'Platform.environment',
        'voice_gen_lib',
        'Uri.https',
        'Uri.http',
      ]) {
        expect(lib, isNot(contains(never)), reason: 'loudness_lib.dart must not touch $never');
      }
      final String cli = File('tool/voice_gen.dart').readAsStringSync();
      final String body = cli.substring(
        cli.indexOf('Future<void> _normalise('),
        cli.indexOf('/// What `plan-lang`'),
      );
      for (final String never in <String>[
        '_eleven',
        '_keyVariable',
        'Platform.environment',
        'Synthesizer',
        'http',
      ]) {
        expect(body, isNot(contains(never)), reason: 'the normalise command must not touch $never');
      }
      // ...and it is not one of the paid commands.
      final String paid = cli.substring(
        cli.indexOf('const Set<String> _paid'),
        cli.indexOf('Future<void> main('),
      );
      expect(paid, isNot(contains('normalise')));
    });

    test('a whole run opens no HTTP connection (any attempt in it throws)', () async {
      final Directory src = _voiceSource(tmp, id: 'voice-nonet');
      final Uint8List pack = (await buildPack(src, key)).bytes;
      final PackLoudness r = await HttpOverrides.runWithHttpOverrides(
        () => normalisePack(
          source: pack,
          publicKey: key.publicKey,
          tool: const FfmpegLoudness(),
          version: '1.1.0',
          key: key,
        ),
        _NoNetwork(),
      );
      expect(r.built, isNotNull);
    }, skip: _skip);
  });

  group('with ffmpeg and tones', () {
    late Directory src;
    late Uint8List source;
    late PackLoudness result;
    late VerifiedPack before;
    late VerifiedPack after;

    setUpAll(() async {
      if (!_ffmpeg) return;
      src = _voiceSource(tmp);
      source = (await buildPack(src, key)).bytes;
      before = await verifyPack(source, publicKey: key.publicKey);
      result = await normalisePack(
        source: source,
        publicKey: key.publicKey,
        tool: const FfmpegLoudness(batch: 4, jobs: 2),
        version: '1.1.0',
        key: key,
      );
      after = await verifyPack(result.built!.bytes, publicKey: key.publicKey);
    });

    test('every clip with a loudness lands within a LU of -16, and no clip peaks over -1 dBTP', () {
      for (final ClipResult c in result.clips) {
        if (c.notes.contains('silent')) continue;
        expect(c.after.truePeak, lessThanOrEqualTo(maxTruePeak), reason: c.file);
        if (c.after.lufs != null) expect(c.after.lufs!, closeTo(targetLufs, 1.0), reason: c.file);
      }
      final LoudnessStats s = result.statsAfter;
      expect(s.max! - s.min!, lessThan(2.0), reason: 'the spread across clips was 22 LU before');
      expect(result.statsBefore.max! - result.statsBefore.min!, greaterThan(15));
    }, skip: _skip);

    test('a clip under 0.4 s has no loudness and is set from its peak, which stays under the limit', () {
      final ClipResult short = result.clips.singleWhere((ClipResult c) => c.file == 'vo.a.short.mp3');
      expect(short.before.lufs, isNull);
      expect(short.notes, contains('short'));
      expect(short.gainDb, greaterThan(5));
      expect(short.after.truePeak, lessThanOrEqualTo(maxTruePeak));
    }, skip: _skip);

    test('a silent clip is the same bytes', () {
      expect(after.files['vo.a.silent.mp3'], before.files['vo.a.silent.mp3']);
    }, skip: _skip);

    test(
      'nothing but the version and the sound changed: same ids, same lines, same cue files, same file names',
      () {
        expect(after.version, '1.1.0');
        expect(after.id, before.id);
        expect(jsonEncode(after.manifest['vo']), jsonEncode(before.manifest['vo']));
        expect(jsonEncode(after.manifest['entries']), jsonEncode(before.manifest['entries']));
        expect(after.manifest['minAppVersion'], before.manifest['minAppVersion']);
        expect(after.files.keys.toSet(), before.files.keys.toSet());
        for (final String name in before.files.keys) {
          if (name.endsWith('.mp3')) continue;
          expect(after.files[name], before.files[name], reason: '$name is not sound and must not change');
        }
        // Two ids share one file in the source: they still do.
        final Map<String, String> files = <String, String>{
          for (final Object? v in after.manifest['vo']! as List<Object?>)
            (v! as Map<String, Object?>)['id']! as String: (v as Map<String, Object?>)['file']! as String,
        };
        expect(files['a.quiet'], files['a.quiet.twin']);
      },
      skip: _skip,
    );

    test('a clip keeps its length (nothing is stretched), so its mouth cues still fit', () {
      for (final String name in before.files.keys.where((String n) => n.endsWith('.mp3'))) {
        final File a = File('${tmp.path}$_sep${'len-a-$name'}')..writeAsBytesSync(before.files[name]!);
        final File b = File('${tmp.path}$_sep${'len-b-$name'}')..writeAsBytesSync(after.files[name]!);
        expect((_seconds(b) - _seconds(a)).abs(), lessThan(0.06), reason: name);
      }
    }, skip: _skip);

    test('the new pack is at the size of the old one, and under the app\'s limit', () {
      expect(result.built!.bytes.length, closeTo(source.length, source.length * 0.1));
      expect(result.filesBytes, lessThan(ZipLimits.maxTotalBytes));
      expect(result.audioBytesAfter, closeTo(result.audioBytesBefore, result.audioBytesBefore * 0.1));
    }, skip: _skip);

    test('a pack that does not verify with the public key is never read', () async {
      final Uint8List forged = Uint8List.fromList(source)..[source.length ~/ 2] ^= 0xFF;
      await expectLater(
        normalisePack(
          source: forged,
          publicKey: key.publicKey,
          tool: const FfmpegLoudness(),
          version: '1.1.0',
        ),
        throwsA(isA<PackRejected>()),
      );
    }, skip: _skip);

    test('a dry run (no key) builds no pack', () async {
      final PackLoudness dry = await normalisePack(
        source: source,
        publicKey: key.publicKey,
        tool: const FfmpegLoudness(),
        version: '1.1.0',
      );
      expect(dry.built, isNull);
      expect(dry.clips.length, result.clips.length);
    }, skip: _skip);
  });

  group('the command, in its own process, with no ElevenLabs key in the environment', () {
    test('builds the level pack in another folder, leaves every original file as it was, and will not go over its own output', () async {
      final Directory root = Directory('${tmp.path}${_sep}cli')..createSync();
      final Directory from = Directory('${root.path}${_sep}voice')..createSync();
      final Directory voiceDir = Directory('${from.path}${_sep}tonetest')..createSync();
      final Directory src = _voiceSource(root);
      // The work folder of the originals: clips, cues and the record next to them, as `generate` leaves them.
      for (final FileSystemEntity e in src.listSync()) {
        if (e is File && !e.path.endsWith('pack.json')) {
          e.copySync('${voiceDir.path}$_sep${e.uri.pathSegments.last}');
        }
      }
      File('${from.path}${_sep}tonetest.voiced.jsonl').writeAsStringSync('{"id":"a.quiet","hash":"x"}\n');
      final BuiltPack original = await buildPack(src, key);
      File('${voiceDir.path}$_sep${original.fileName}').writeAsBytesSync(original.bytes);
      final File publicKeyFile = File('${root.path}${_sep}public.txt')
        ..writeAsStringSync('${hex(key.publicKey)}\n');
      final File keyFile = File('${tmp.path}${_sep}test.key');

      Map<String, String> snapshot(Directory d) => <String, String>{
        for (final FileSystemEntity e in d.listSync(recursive: true))
          if (e is File) e.path: sha256Hex(_bytes(e)),
      };
      final Map<String, String> originals = snapshot(from);

      final Map<String, String> env = <String, String>{
        for (final MapEntry<String, String> e in Platform.environment.entries)
          if (!e.key.toUpperCase().contains('ELEVENLABS')) e.key: e.value,
      };
      Future<ProcessResult> run(List<String> extra) => Process.run(
        'dart',
        <String>[
          'run',
          'tool/voice_gen.dart',
          'normalise',
          'tonetest',
          '--from-root',
          from.path,
          '--out-root',
          '${root.path}${_sep}loud',
          '--public-key',
          publicKeyFile.path,
          '--key',
          keyFile.path,
          ...extra,
        ],
        environment: env,
        includeParentEnvironment: false,
        runInShell: true,
      );
      final ProcessResult ok = await run(<String>[]);
      expect(ok.exitCode, 0, reason: '${ok.stdout}${ok.stderr}');
      expect('${ok.stdout}', contains('voice-tonetest 1.0.0 -> 1.1.0'));
      expect(snapshot(from), originals, reason: 'the originals are only read');

      final File made = File('${root.path}${_sep}loud${_sep}tonetest${_sep}voice-tonetest-1.1.0.nnpack');
      expect(made.existsSync(), isTrue);
      expect(File('${made.path}.loudness.json').existsSync(), isTrue);
      final VerifiedPack p = await verifyPack(_bytes(made), publicKey: key.publicKey);
      expect(p.version, '1.1.0');
      final Object? sidecar = jsonDecode(File('${made.path}.loudness.json').readAsStringSync());
      expect((sidecar! as Map<String, Object?>)['target'], targetLufs);

      // The result is not made level a second time, and an existing pack is never overwritten.
      final ProcessResult again = await Process.run(
        'dart',
        <String>[
          'run',
          'tool/voice_gen.dart',
          'normalise',
          'tonetest',
          '--from-root',
          '${root.path}${_sep}loud',
          '--out-root',
          '${root.path}${_sep}loud2',
          '--public-key',
          publicKeyFile.path,
          '--key',
          keyFile.path,
        ],
        environment: env,
        includeParentEnvironment: false,
        runInShell: true,
      );
      expect(again.exitCode, isNot(0));
      expect('${again.stderr}', contains('was made level already'));

      final ProcessResult same = await run(<String>[]);
      expect(same.exitCode, isNot(0));
      expect('${same.stderr}', contains('exists already'));

      // A dry run needs no key at all.
      final ProcessResult dry = await Process.run(
        'dart',
        <String>[
          'run',
          'tool/voice_gen.dart',
          'normalise',
          'tonetest',
          '--dry-run',
          '--from-root',
          from.path,
          '--out-root',
          '${root.path}${_sep}loud3',
          '--public-key',
          publicKeyFile.path,
          '--key',
          '${tmp.path}${_sep}no-such.key',
        ],
        environment: env,
        includeParentEnvironment: false,
        runInShell: true,
      );
      expect(dry.exitCode, 0, reason: '${dry.stdout}${dry.stderr}');
      expect(Directory('${root.path}${_sep}loud3').existsSync(), isFalse);
      expect(snapshot(from), originals);
    }, skip: _skip);
  });
}

/// Runs [normaliseClips] on the files [names] in a folder of [tmp], each holding `input-<name>`; the pretend ffmpeg knows what each
/// clip measures.
Future<List<ClipResult>> _run(Directory tmp, _FakeTool tool, List<String> names) async {
  final Directory in_ = Directory('${tmp.path}${_sep}fake-in')..createSync(recursive: true);
  final Directory out = Directory('${tmp.path}${_sep}fake-out')..createSync(recursive: true);
  final List<File> inputs = <File>[
    for (final String n in names) File('${in_.path}$_sep$n')..writeAsStringSync('input-$n'),
  ];
  return normaliseClips(
    inputs: inputs,
    outputs: <File>[for (final String n in names) File('${out.path}$_sep$n')],
    tool: tool,
  );
}

/// A pretend ffmpeg: a clip's name says what it measures (the first time it is measured); a render adds the gain, lets a limiter
/// stop the sample peak at the ceiling (the true peak then lies [overshoot] dB above it) and takes a little loudness off
/// for each dB the limiter works. [stuckPeak] is a peak that no limiter level brings under -1: it is always that.
class _FakeTool implements LoudnessTool {
  _FakeTool(this.clips, {this.overshoot = 0.0, this.stuckPeak});

  final Map<String, Loudness> clips;
  final double overshoot;
  final double? stuckPeak;
  final List<RenderJob> rendered = <RenderJob>[];
  int renderRounds = 0;
  final Map<String, RenderJob> _last = <String, RenderJob>{};

  String _name(String path) => path.split(RegExp(r'[/\\]')).last;

  @override
  Future<String?> unavailableReason() async => null;

  @override
  Future<List<Loudness>> measure(List<File> files) async => <Loudness>[
    for (final File f in files)
      if (_last[_name(f.path)] case final RenderJob j when f.path == j.output)
        _after(clips[_name(f.path)]!, j)
      else
        clips[_name(f.path)]!,
  ];

  Loudness _after(Loudness before, RenderJob j) {
    if (stuckPeak != null) return Loudness(lufs: before.lufs, truePeak: stuckPeak!);
    final double peak = before.truePeak + j.gainDb;
    final double limitedBy = peak > j.ceilingDb ? peak - j.ceilingDb : 0;
    return Loudness(
      lufs: before.lufs == null ? null : before.lufs! + j.gainDb - limitedBy * 0.3,
      truePeak: (peak > j.ceilingDb ? j.ceilingDb : peak) + (limitedBy > 0 ? overshoot : 0),
    );
  }

  @override
  Future<void> render(List<RenderJob> jobs) async {
    renderRounds++;
    for (final RenderJob j in jobs) {
      rendered.add(j);
      _last[_name(j.input)] = j;
      File(j.output).writeAsStringSync('rendered');
    }
  }
}

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('the loudness run opened an HTTP connection');
}
