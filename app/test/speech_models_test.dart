import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/app/voice_input.dart';
import 'package:nitznutz/models/model_installer.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/speech/model_spec.dart';
import 'package:nitznutz/speech/sherpa_config.dart' show hotwordList;

/// A model of two tiny files, to try the installer and the checks without 70 MB of weights.
SpeechModelSpec tinySpec(Map<String, List<int>> files, {Decoding decoding = Decoding.open}) =>
    SpeechModelSpec(
      course: 'eng',
      id: 'tiny',
      folderName: 'speech-model-tiny-1',
      licence: 'test',
      source: 'test',
      revision: 'test',
      modelType: '',
      decoding: decoding,
      hotwordBoost: 8,
      upperCaseWords: true,
      files: <ModelFile>[
        for (final MapEntry<String, List<int>> e in files.entries)
          ModelFile(e.key, e.value.length, sha256.convert(e.value).toString()),
      ],
    );

class ScriptedFetcher implements ModelFetcher {
  ScriptedFetcher(this.bytes, {this.failAfter});

  final Map<String, List<int>> bytes;
  final int? failAfter;
  final List<String> asked = <String>[];

  @override
  Stream<List<int>> fetch(SpeechModelSpec spec, ModelFile file) async* {
    asked.add(file.name);
    final List<int> b = bytes[file.name]!;
    if (failAfter != null) {
      yield b.sublist(0, failAfter!);
      throw const SocketException('connection lost');
    }
    // In two pieces, as a download arrives.
    yield b.sublist(0, b.length ~/ 2);
    yield b.sublist(b.length ~/ 2);
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('nn-model-'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final Map<String, List<int>> good = <String, List<int>>{
    'encoder.int8.onnx': List<int>.generate(3000, (int i) => i % 251),
    'tokens.txt': 'a 0\nb 1\n'.codeUnits,
  };

  group('the pinned models', () {
    test('every file has a size and a 64-digit SHA-256, and no name or folder is shared', () {
      final Set<String> folders = <String>{};
      for (final SpeechModelSpec m in SpeechModels.all) {
        expect(folders.add(m.folderName), isTrue, reason: 'a folder is used twice');
        final Set<String> names = <String>{};
        for (final ModelFile f in m.files) {
          expect(names.add(f.name), isTrue, reason: '${m.id}: ${f.name} twice');
          expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(f.sha256Hex), isTrue, reason: '${m.id}/${f.name}');
          expect(f.size, greaterThan(0));
        }
        for (final String needed in <String>[
          SpeechModelSpec.encoder,
          SpeechModelSpec.joiner,
          SpeechModelSpec.tokens,
          m.decoder,
        ]) {
          expect(names, contains(needed), reason: '${m.id} lacks $needed');
        }
        expect(m.revision, matches(RegExp(r'^[0-9a-f]{40}$')), reason: '${m.id} pins a revision');
        expect(m.licence, isNotEmpty);
        // The biased models need the vocabulary of their word pieces for the hotword list.
        expect(names.contains(SpeechModelSpec.bpeVocab), m.biased, reason: m.id);
      }
    });

    test('the Hebrew files are the ones M5 pinned', () {
      final Map<String, String> sha = <String, String>{
        for (final ModelFile f in SpeechModels.hebrew.files) f.name: f.sha256Hex,
      };
      expect(sha['encoder.int8.onnx'], startsWith('6c6febcb'));
      expect(sha['tokens.txt'], startsWith('e4ebb5e7'));
      expect(SpeechModels.hebrew.folderName, 'speech-model-he-1');
      expect(SpeechModels.hebrew.biased, isFalse, reason: 'Hebrew keeps open decoding');
    });

    test('a course finds its model; the lands speak Hebrew; a name that is no course finds none', () {
      expect(SpeechModels.forCourse('eng'), same(SpeechModels.english));
      expect(SpeechModels.forCourse('rus'), same(SpeechModels.russian));
      expect(SpeechModels.forCourse('heb'), same(SpeechModels.hebrew));
      expect(SpeechModels.forCourse('core'), same(SpeechModels.hebrew));
      expect(SpeechModels.forCourse('fra'), isNull);
    });

    test(
      'English hotwords are upper case, Russian ones are not; both boost 8 and need a second of lead silence',
      () {
        expect(SpeechModels.english.upperCaseWords, isTrue);
        expect(SpeechModels.russian.upperCaseWords, isFalse);
        expect(
          <double>[SpeechModels.english.hotwordBoost, SpeechModels.russian.hotwordBoost],
          <double>[8, 8],
        );
        expect(
          <int>[SpeechModels.english.leadSilenceMs, SpeechModels.russian.leadSilenceMs],
          <int>[1000, 1000],
        );
      },
    );
  });

  group('checking the files', () {
    test(
      'a model that is exactly right passes; one wrong byte, a short file and a missing file are named',
      () async {
        final SpeechModelSpec spec = tinySpec(good);
        for (final MapEntry<String, List<int>> e in good.entries) {
          File('${dir.path}/${e.key}').writeAsBytesSync(e.value);
        }
        expect(spec.looksInstalled(dir), isTrue);
        expect(spec.verifySync(dir), isEmpty);
        expect(await spec.verify(dir), isEmpty, reason: 'the isolate gives the same answer');

        final List<int> flipped = List<int>.of(good['encoder.int8.onnx']!)..[10] ^= 1;
        File('${dir.path}/encoder.int8.onnx').writeAsBytesSync(flipped);
        expect(spec.looksInstalled(dir), isTrue, reason: 'the quick look checks size only');
        expect(spec.verifySync(dir), <String>['encoder.int8.onnx']);

        File('${dir.path}/tokens.txt').deleteSync();
        expect(spec.looksInstalled(dir), isFalse);
        expect(spec.verifySync(dir), <String>['encoder.int8.onnx', 'tokens.txt']);
      },
    );

    test('the hash of a file is the same as the hash of its bytes, whatever the block size', () {
      final List<int> big = List<int>.generate((1 << 20) * 2 + 77, (int i) => (i * 31) % 256);
      final File f = File('${dir.path}/big.bin')..writeAsBytesSync(big);
      expect(sha256Of(f), sha256.convert(big).toString());
    });
  });

  group('the installer: temporary name, check, rename', () {
    test('without a host nothing is written under a real name and nothing is left over', () async {
      final SpeechModelSpec spec = tinySpec(good);
      final InstallOutcome r = await const ModelInstaller().install(spec, dir);
      expect(r, InstallOutcome.unavailable);
      expect(dir.listSync(), isEmpty);
    });

    test('good bytes are installed under their names, with no temporary file left', () async {
      final SpeechModelSpec spec = tinySpec(good);
      final ScriptedFetcher fetcher = ScriptedFetcher(good);
      final InstallOutcome r = await ModelInstaller(fetcher: fetcher).install(spec, dir);
      expect(r, InstallOutcome.installed);
      expect(spec.verifySync(dir), isEmpty);
      expect(
        dir.listSync().map((FileSystemEntity e) => e.path.split(Platform.pathSeparator).last).toSet(),
        good.keys.toSet(),
      );
    });

    test('a file with the wrong bytes is deleted and the install stops', () async {
      final SpeechModelSpec spec = tinySpec(good);
      final Map<String, List<int>> bad = <String, List<int>>{
        'encoder.int8.onnx': List<int>.of(good['encoder.int8.onnx']!)..[5] ^= 1,
        'tokens.txt': good['tokens.txt']!,
      };
      final ScriptedFetcher fetcher = ScriptedFetcher(bad);
      final InstallOutcome r = await ModelInstaller(fetcher: fetcher).install(spec, dir);
      expect(r, InstallOutcome.rejected);
      expect(dir.listSync(), isEmpty, reason: 'no real name and no .part');
      expect(fetcher.asked, <String>['encoder.int8.onnx'], reason: 'it did not go on to the next file');
    });

    test('a host that sends more than the pinned size is stopped and refused', () async {
      final SpeechModelSpec spec = tinySpec(good);
      final Map<String, List<int>> more = <String, List<int>>{
        'encoder.int8.onnx': <int>[...good['encoder.int8.onnx']!, 1, 2, 3],
        'tokens.txt': good['tokens.txt']!,
      };
      final InstallOutcome r = await ModelInstaller(fetcher: ScriptedFetcher(more)).install(spec, dir);
      expect(r, InstallOutcome.rejected);
      expect(dir.listSync(), isEmpty);
    });

    test('a connection that drops half way leaves nothing behind', () async {
      final SpeechModelSpec spec = tinySpec(good);
      final InstallOutcome r = await ModelInstaller(fetcher: ScriptedFetcher(good, failAfter: 100))
          .install(spec, dir);
      expect(r, InstallOutcome.unavailable);
      expect(dir.listSync(), isEmpty);
    });

    test(
      'a file that is already right is not fetched again; a wrong one is replaced; an old .part is cleared',
      () async {
        final SpeechModelSpec spec = tinySpec(good);
        File('${dir.path}/encoder.int8.onnx').writeAsBytesSync(good['encoder.int8.onnx']!);
        File('${dir.path}/tokens.txt').writeAsStringSync('damaged');
        File('${dir.path}/tokens.txt.part').writeAsStringSync('half');
        final ScriptedFetcher fetcher = ScriptedFetcher(good);
        final InstallOutcome r = await ModelInstaller(fetcher: fetcher).install(spec, dir);
        expect(r, InstallOutcome.installed);
        expect(fetcher.asked, <String>['tokens.txt']);
        expect(File('${dir.path}/tokens.txt.part').existsSync(), isFalse);
      },
    );

    test('removing a model deletes its folder', () {
      File('${dir.path}/tokens.txt').writeAsStringSync('x');
      const ModelInstaller().remove(dir);
      expect(dir.existsSync(), isFalse);
    });

    test('the registry has no network code and no address', () {
      final String src = File('lib/models/model_installer.dart').readAsStringSync();
      expect(src, isNot(contains('http')));
      expect(src, isNot(contains('dart:io\' show HttpClient')));
      expect(RegExp(r'''['"][a-z]+://''').hasMatch(src), isFalse);
    });
  });

  group('the release gate is enforced, and a recogniser is freed with its switch', () {
    test('QA-L3-1: no language has passed its release gate: every course says released false', () {
      for (final SpeechModelSpec m in SpeechModels.all) {
        expect(m.released, isFalse, reason: m.id);
      }
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      for (final String course in <String>['eng', 'heb', 'rus']) {
        expect(c.read(sayItReleasedProvider(course)), isFalse, reason: course);
      }
    });

    test(
      'SEC-L3-4: the recogniser of a language is made again when the last voice switch for it turns off',
      () async {
        final _Languages languages = _Languages();
        final ProviderContainer c = ProviderContainer(
          overrides: [languagesProvider.overrideWith(() => languages)],
        );
        addTearDown(c.dispose);
        await c.read(languagesProvider.future);
        const String kid = 'child-lang-0001';
        await languages.setSwitches(kid, 'eng', const LanguageSwitches(on: true, voice: true));
        final Object first = c.read(languageSpeechEngineProvider('eng'));
        // Other settings do not free it.
        await languages.setSwitches(
          kid,
          'eng',
          const LanguageSwitches(on: true, voice: true, personal: false),
        );
        expect(c.read(languageSpeechEngineProvider('eng')), same(first));
        // Another language's switch does not either.
        await languages.setSwitches(kid, 'rus', const LanguageSwitches(on: true, voice: true));
        expect(c.read(languageSpeechEngineProvider('eng')), same(first));
        // The switch turned off: the recogniser (and the model it holds) is dropped.
        await languages.setSwitches(kid, 'eng', const LanguageSwitches(on: true));
        expect(c.read(languageSpeechEngineProvider('eng')), isNot(same(first)));
      },
    );
  });

  group('the hotword list of a listen', () {
    test(
      'English words are upper case, one line each with the boost, and the same word twice is one line',
      () {
        expect(
          hotwordList(SpeechModels.english, <String>['apple', 'Pear', 'apple']),
          'APPLE :8.0\nPEAR :8.0',
        );
      },
    );

    test('Russian words stay lower case', () {
      expect(hotwordList(SpeechModels.russian, <String>['Лук', 'люк']), 'лук :8.0\nлюк :8.0');
    });

    test('an open model gets no list at all', () {
      expect(hotwordList(SpeechModels.hebrew, <String>['שלום']), '');
    });

    test('a word cannot add a line or change a boost: the characters of the list format are dropped', () {
      final String list = hotwordList(SpeechModels.english, <String>[
        'cat :99',
        'dog\nBIRD',
        'x#0.1@y',
        'a/b',
        ':',
        '  ',
      ]);
      expect(list.split('\n'), <String>['CAT 99 :8.0', 'DOG BIRD :8.0', 'X 0.1 Y :8.0', 'A B :8.0']);
      for (final String line in list.split('\n')) {
        expect(RegExp(':').allMatches(line).length, 1, reason: line);
      }
    });
  });
}

/// The languages setting without a database: it holds the family's switches in memory.
class _Languages extends LanguagesNotifier {
  FamilyLanguages _family = const FamilyLanguages();

  @override
  Future<FamilyLanguages> build() async => _family;

  @override
  Future<bool> setSwitches(String childId, String course, LanguageSwitches switches) async {
    final FamilyLanguages? next = _family.withSwitches(childId, course, switches);
    if (next == null) return false;
    _family = next;
    state = AsyncData<FamilyLanguages>(next);
    return true;
  }
}
