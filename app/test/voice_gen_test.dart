import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/fake_eleven.dart';
import 'support/pack_fixtures.dart';

Directory _temp(String name) => Directory.systemTemp.createTempSync(name);

void _drop(Directory d) {
  for (final FileSystemEntity e in <FileSystemEntity>[d, File('${d.path}.voiced.jsonl')]) {
    try {
      e.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}

const List<SpokenLine> _lines = <SpokenLine>[
  SpokenLine('vo:a.one', 'שָׁלוֹם'),
  SpokenLine('vo:a.two', 'כֵּן'),
  SpokenLine('vo:a.three', 'לֹא'),
];

const String _voice = 'VoiceXyz0123';

/// A v4 voice with explicit settings, as content/voices.json gives it.
const VoiceProfile _v4 = VoiceProfile(
  voiceId: _voice,
  modelId: 'eleven_v4',
  outputFormat: 'mp3_44100_64',
  settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75, 'use_speaker_boost': true},
);

VoiceProfile _with({
  String voiceId = _voice,
  String modelId = 'eleven_v4',
  String outputFormat = 'mp3_44100_64',
  Map<String, Object?> settings = const <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
  Map<String, Map<String, Object?>> styles = const <String, Map<String, Object?>>{},
  Map<String, List<String>> styleRules = const <String, List<String>>{},
  Map<String, String> pronunciation = const <String, String>{},
}) => VoiceProfile(
  voiceId: voiceId,
  modelId: modelId,
  outputFormat: outputFormat,
  settings: settings,
  styles: styles,
  styleRules: styleRules,
  pronunciation: pronunciation,
);

Map<String, Object?> _realConfig() =>
    jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());

  group('mouth cues from the character timestamps', () {
    // ש + qamats + shin dot, ל, ו + holam, ם — a tenth of a second for each character.
    final Alignment hello = Alignment(
      <String>['ש', 'ָ', 'ׁ', 'ל', 'ו', 'ֹ', 'ם'],
      <double>[for (int i = 0; i < 7; i++) i * 0.1],
      <double>[for (int i = 0; i < 7; i++) (i + 1) * 0.1],
    );

    test('a letter with a vowel opens the mouth for its whole group; a bare consonant does not', () {
      expect(cuesFromAlignment(hello), <(int, int)>[(0, 1), (300, 0), (400, 1), (600, 0)]);
    });

    test('shva and a dagesh do not open the mouth, a shin dot alone does not either', () {
      final Alignment a = Alignment(
        <String>['ב', 'ְ', 'ת', 'ּ', 'ש', 'ׁ'],
        <double>[0, 0.1, 0.2, 0.3, 0.4, 0.5],
        <double>[0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
      );
      expect(cuesFromAlignment(a), isEmpty);
    });

    test('pauses, spaces and punctuation leave it closed, and the times always increase', () {
      final Alignment a = Alignment(
        <String>['א', 'ַ', ' ', '!', 'ב', 'ָ'],
        <double>[0, 0.05, 0.1, 0.1, 0.1, 0.1],
        <double>[0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
      );
      final List<(int, int)> c = cuesFromAlignment(a);
      expect(c.first.$2, 1);
      for (int i = 1; i < c.length; i++) {
        expect(c[i].$1, greaterThan(c[i - 1].$1), reason: '$c');
      }
    });

    test(
      'a word without niqqud (the voice texts are mostly plain) opens on every other letter, from the first',
      () {
        final Alignment a = Alignment(<String>['ש', 'ל', 'ו', 'ם'], <double>[0, 0.1, 0.2, 0.3], <double>[
          0.1,
          0.2,
          0.3,
          0.4,
        ]);
        expect(cuesFromAlignment(a), <(int, int)>[(0, 1), (100, 0), (200, 1), (300, 0)]);
      },
    );

    test('in mixed text each word follows its own rule, and a space starts the count again', () {
      // "בוא" plain, a space, then ש + shva (closed), ת + patah (open).
      final List<String> chars = <String>['ב', 'ו', 'א', ' ', 'ש', 'ְ', 'ת', 'ַ'];
      final Alignment a = Alignment(
        chars,
        <double>[for (int i = 0; i < chars.length; i++) i * 0.1],
        <double>[for (int i = 0; i < chars.length; i++) (i + 1) * 0.1],
      );
      expect(cuesFromAlignment(a), <(int, int)>[(0, 1), (100, 0), (200, 1), (300, 0), (600, 1), (800, 0)]);
    });
  });

  group('the captions (what the old clips were made from)', () {
    test('are found in the lessons and activities of the starter pack, with their niqqud', () {
      final List<SpokenLine> lines = linesOfContent(Directory('../content/starter'));
      expect(lines, isNotEmpty);
      expect(lines.map((SpokenLine l) => l.voId), contains('vo:pick.red.flower.prompt'));
      expect(lines.map((SpokenLine l) => l.voId).toSet().length, lines.length, reason: 'no line twice');
      for (final SpokenLine l in lines) {
        expect(l.text, matches(RegExp('[ְ-ׇ]')), reason: '${l.voId} has no niqqud');
      }
    });

    test('the core lines are read from content/lines/core.he.json', () {
      final List<SpokenLine> core = coreLines(File('../content/lines/core.he.json'));
      expect(core.length, greaterThan(10));
      expect(core.first.voId, startsWith('vo:core.'));
    });

    test(
      'the lines the guide says while listening are in the core file with the same words as the captions',
      () {
        final Map<String, String> core = <String, String>{
          for (final SpokenLine l in coreLines(File('../content/lines/core.he.json'))) l.voId: l.text,
        };
        expect(core['vo:core.listen.mixed'], He.listenMixed.text);
        expect(core['vo:core.listen.confirm'], He.listenConfirm.text);
        expect(core['vo:core.listen.tap'], He.listenTap.text);
      },
    );

    test('respelling replaces the listed words and nothing else', () {
      expect(respelled('אבגד', <String, String>{'בג': 'XX'}), 'אXXד');
      expect(respelled('אבגד', <String, String>{}), 'אבגד');
    });
  });

  group('the settings sent with every line', () {
    test('stability and similarity are always explicit: settings without them are refused', () {
      expect(
        () => settingsToSend('eleven_v4', <String, Object?>{}),
        throwsA(
          isA<VoiceGenFailed>().having((VoiceGenFailed e) => e.message, 'message', contains('stability')),
        ),
      );
      expect(
        () => settingsToSend('eleven_v4', <String, Object?>{'stability': 0.5}),
        throwsA(isA<VoiceGenFailed>()),
      );
    });

    test('a v4 model never gets style or speed; another model keeps them', () {
      const Map<String, Object?> cheer = <String, Object?>{
        'stability': 0.1,
        'similarity_boost': 0.8,
        'style': 0.9,
        'speed': 1.0,
        'use_speaker_boost': true,
      };
      for (final String m in <String>['eleven_v4', 'eleven_v4_turbo']) {
        expect(settingsToSend(m, cheer), <String, Object?>{
          'similarity_boost': 0.8,
          'stability': 0.1,
          'use_speaker_boost': true,
        });
      }
      expect(settingsToSend('eleven_v3', cheer).keys, containsAll(<String>['style', 'speed']));
    });

    test('a style goes on top of the usual settings key by key, keys sorted and numbers as decimals', () {
      final Map<String, Object?> s = settingsToSend(
        'eleven_v4',
        <String, Object?>{'stability': 1, 'similarity_boost': 0.75, 'use_speaker_boost': true},
        <String, Object?>{'stability': 0.4},
      );
      expect(jsonEncode(s), '{"similarity_boost":0.75,"stability":0.4,"use_speaker_boost":true}');
      expect(
        settingsToSend('eleven_v4', <String, Object?>{'stability': 1, 'similarity_boost': 1})['stability'],
        1.0,
      );
    });

    test('unknown keys, wrong types, NaN, infinity and values out of range are refused', () {
      const Map<String, Object?> ok = <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75};
      for (final Map<String, Object?> bad in <Map<String, Object?>>[
        <String, Object?>{...ok, 'stabilty': 0.5},
        <String, Object?>{...ok, 'stability': 1.5},
        <String, Object?>{...ok, 'stability': double.nan},
        <String, Object?>{...ok, 'similarity_boost': double.infinity},
        <String, Object?>{...ok, 'style': double.negativeInfinity},
        <String, Object?>{...ok, 'similarity_boost': '0.7'},
        <String, Object?>{...ok, 'use_speaker_boost': 1},
        <String, Object?>{...ok, 'speed': 2.0},
      ]) {
        expect(() => settingsToSend('eleven_v3', bad), throwsA(isA<VoiceGenFailed>()), reason: '$bad');
      }
    });

    test('only the Hebrew models, 44.1 kHz MP3 of 64 kbps or more, and plain voice ids are accepted', () {
      for (final String m in hebrewModels) {
        checkModel(m);
      }
      for (final String m in <String>[
        'eleven_multilingual_v2',
        'eleven_flash_v2_5',
        'eleven_turbo_v2_5',
        'eleven_v4x',
        'eleven_v3_x',
        '',
      ]) {
        expect(() => checkModel(m), throwsA(isA<VoiceGenFailed>()), reason: m);
      }
      for (final String f in <String>['mp3_44100_64', 'mp3_44100_128', 'mp3_44100_192']) {
        checkFormat(f);
      }
      for (final String f in <String>['mp3_22050_32', 'mp3_44100_32', 'pcm_44100', 'mp3_44100_64x']) {
        expect(() => checkFormat(f), throwsA(isA<VoiceGenFailed>()), reason: f);
      }
      checkVoiceId('Tbj9UQjXon5RB9MPEyc2');
      for (final String v in <String>['..', '.', '', 'short', 'a/b0123456789', 'voice-xyz-0123', 'x' * 41]) {
        expect(() => checkVoiceId(v), throwsA(isA<VoiceGenFailed>()), reason: v);
      }
    });

    test(
      'content/voices.json gives every character a v4 request with explicit settings, no style, at 44.1 kHz',
      () {
        final Map<String, Object?> config = _realConfig();
        for (final String c in (config['voices']! as Map<String, Object?>).keys) {
          final VoiceProfile p = VoiceProfile.fromConfig(config, c);
          for (final String vo in <String>[
            'vo:core.greeting.hello',
            'vo:core.celebrate.well',
            'vo:celebrate.x',
          ]) {
            final ClipRequest r = p.requestFor(SpokenLine(vo, 'שלום'));
            expect(r.outputFormat, 'mp3_44100_64', reason: c);
            expect(r.settings.keys, containsAll(<String>['stability', 'similarity_boost']), reason: '$c $vo');
            if (isV4Model(r.modelId)) {
              expect(r.settings.keys, isNot(anyOf(contains('style'), contains('speed'))), reason: '$c $vo');
            }
          }
          expect(VoiceProfile.fromConfig(config, c, model: 'eleven_v4').modelId, 'eleven_v4');
        }
      },
    );

    test('a profile refuses a missing voice, a voice id that is not plain, a model that is not Hebrew, a style rule '
        'with no style and a 22.05 kHz format', () {
      final Map<String, Object?> config = _realConfig();
      expect(() => VoiceProfile.fromConfig(config, 'nobody'), throwsA(isA<VoiceGenFailed>()));
      for (final String id in <String>['..', '.', 'ab/cd0123456']) {
        expect(
          () => VoiceProfile.fromConfig(<String, Object?>{
            ...config,
            'voices': <String, Object?>{
              'nitzi': <String, Object?>{'voiceId': id},
            },
          }, 'nitzi'),
          throwsA(isA<VoiceGenFailed>()),
          reason: id,
        );
      }
      expect(
        () => VoiceProfile.fromConfig(config, 'nitzi', model: 'eleven_multilingual_v2'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => VoiceProfile.fromConfig(<String, Object?>{
          ...config,
          'styleRules': <String, Object?>{
            'loud': <Object?>['vo:core.'],
          },
        }, 'nitzi'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => VoiceProfile.fromConfig(<String, Object?>{...config, 'outputFormat': 'mp3_22050_32'}, 'nitzi'),
        throwsA(isA<VoiceGenFailed>()),
      );
    });
  });

  group('the hash of a clip', () {
    test('is the same for the same request and changes with the text, voice, model, settings or format', () {
      const SpokenLine line = SpokenLine('vo:a.one', 'שלום');
      final String base = _with().requestFor(line).hash;
      expect(_with().requestFor(line).hash, base);
      expect(_with().requestFor(const SpokenLine('vo:a.one', 'שלום.')).hash, isNot(base));
      expect(_with(modelId: 'eleven_v4_turbo').requestFor(line).hash, isNot(base));
      expect(
        _with(settings: <String, Object?>{'stability': 0.4, 'similarity_boost': 0.75}).requestFor(line).hash,
        isNot(base),
      );
      expect(_with(outputFormat: 'mp3_44100_128').requestFor(line).hash, isNot(base));
      expect(_with(voiceId: 'OtherVoice0123').requestFor(line).hash, isNot(base));
    });

    test('a style that v4 does not use changes nothing, so it makes no clip again', () {
      const SpokenLine line = SpokenLine('vo:a.one', 'שלום');
      final VoiceProfile a = _with(
        styles: <String, Map<String, Object?>>{
          'x': <String, Object?>{'style': 0.9},
        },
        styleRules: <String, List<String>>{
          'x': <String>['vo:a.'],
        },
      );
      expect(a.requestFor(line).hash, _with().requestFor(line).hash);
      expect(a.droppedOf('x'), <String>['style']);
    });
  });

  group('the ledger of what was made', () {
    late Directory tmp;
    setUp(() => tmp = _temp('nn_vg_ledger_'));
    tearDown(() => _drop(tmp));

    test(
      'every spelling of the work folder gives the same ledger, next to the folder and never inside it',
      () {
        final String sep = Platform.pathSeparator;
        final String expected = '${normalisedFolder(tmp)}${sep}nitzi.voiced.jsonl';
        for (final String spelling in <String>[
          '${tmp.path}${sep}nitzi',
          '${tmp.path}${sep}nitzi$sep',
          '${tmp.path}${sep}nitzi$sep$sep',
          '${tmp.path}${sep}nitzi$sep.',
          '${tmp.path}$sep.${sep}nitzi',
        ]) {
          final Directory work = Directory(spelling);
          final File ledger = ClipLedger(work).file;
          expect(ledger.path, expected, reason: spelling);
          expect(isInsideFolder(ledger, work), isFalse, reason: spelling);
        }
      },
    );

    test(
      'a work folder written as "." or "..", or ending in one, is refused before anything is sent',
      () async {
        final String sep = Platform.pathSeparator;
        final FakeEleven server = FakeEleven();
        for (final String spelling in <String>[
          '.',
          '..',
          '${tmp.path}$sep.',
          '${tmp.path}${sep}nitzi$sep..',
        ]) {
          expect(
            () => checkWorkFolder(Directory(spelling)),
            throwsA(isA<VoiceGenFailed>()),
            reason: spelling,
          );
          await expectLater(
            generateVoicePack(
              characterId: 'x',
              lines: _lines,
              synth: ElevenLabsSynthesizer(apiKey: 'k', client: server.client),
              profile: _v4,
              key: key,
              workDir: Directory(spelling),
            ),
            throwsA(isA<VoiceGenFailed>()),
            reason: spelling,
          );
        }
        expect(server.requests, isEmpty);
        checkWorkFolder(Directory('${tmp.path}${sep}nitzi'));
        expect(
          isInsideFolder(File('${tmp.path}${sep}nitzi${sep}a.json'), Directory('${tmp.path}${sep}nitzi')),
          isTrue,
        );
      },
    );
  });

  group('the plan counts characters before anything is sent', () {
    test('per voice and in total, with the cost at the price given', () {
      final VoicePlan plan = planVoices(<String, VoiceProfile>{'a': _v4, 'b': _v4, 'c': _v4}, _lines);
      final int per = _lines.fold<int>(0, (int s, SpokenLine l) => s + l.text.runes.length);
      expect(plan.perCharacter, per);
      expect(plan.total, per * 3);
      expect(plan.cost(0.5), closeTo(per * 3 / 1000 * 0.5, 1e-9));
      final String text = plan.describe(0.5);
      expect(
        text,
        contains(
          'a (eleven_v4, mp3_44100_64): new 3, changed 0, unchanged 0; characters to send for this voice $per',
        ),
      );
      expect(text, contains('generate voices one character per run'));
      expect(text, contains('the count of exactly what that run sends'));
      expect(text, isNot(contains('--confirm-chars')), reason: 'no flag passes the gate');
    });

    test('a respelled word is counted as it will be sent', () {
      final VoicePlan plain = planVoices(<String, VoiceProfile>{'a': _v4}, _lines);
      final VoicePlan respell = planVoices(<String, VoiceProfile>{
        'a': _with(pronunciation: <String, String>{'כֵּן': 'כֵּןכֵּן'}),
      }, _lines);
      expect(respell.total, greaterThan(plain.total));
    });

    test('lists new, changed and unchanged lines; only new and changed are counted', () {
      final VoicePlan plan = planVoices(
        <String, VoiceProfile>{'a': _v4, 'b': _v4},
        _lines,
        stateOf: (String c, SpokenLine l, ClipRequest r) =>
            c == 'a' ? ClipState.unchanged : (l == _lines.first ? ClipState.changed : ClipState.newLine),
      );
      final int per = _lines.fold<int>(0, (int s, SpokenLine l) => s + l.text.runes.length);
      expect(plan.toSay, _lines.length);
      expect(plan.reused, _lines.length);
      expect(plan.count(ClipState.changed), 1);
      expect(plan.count(ClipState.newLine), 2);
      expect(plan.total, per);
      final String text = plan.describe(0.04, list: true);
      expect(text, contains('a (eleven_v4, mp3_44100_64): new 0, changed 0, unchanged 3'));
      expect(text, contains('b (eleven_v4, mp3_44100_64): new 2, changed 1, unchanged 0'));
      expect(text, contains('[changed] b vo:a.one'));
      expect(text, contains('שָׁלוֹם'), reason: '--list shows the exact text sent');
    });

    test('a text the pre-flight check refuses is reported by id, and no way to go ahead is offered', () {
      final VoicePlan plan = planVoices(
        <String, VoiceProfile>{'a': _v4},
        const <SpokenLine>[SpokenLine('vo:x.loud', 'כל הכבוד!')],
      );
      expect(plan.problems.single.id, 'vo:x.loud');
      final String text = plan.describe(0.04);
      expect(text, contains('vo:x.loud: "!"'));
      expect(text, isNot(contains('generate voices one character per run')));
    });
  });

  group('the gate: a person types the count at a terminal', () {
    test('without a terminal it refuses before reading anything, and names no number', () {
      final FakeKeyboard kb = FakeKeyboard(isTerminal: false, typed: <String>['42']);
      for (final void Function() gate in <void Function()>[
        () => requireTerminal(kb, 'this run'),
        () => requireTyped(kb, 42, 'this run', (String _) {}),
      ]) {
        expect(
          gate,
          throwsA(
            isA<VoiceGenFailed>().having(
              (VoiceGenFailed e) => e.message,
              'message',
              allOf(contains('interactive terminal'), contains('Nothing was sent'), isNot(contains('42'))),
            ),
          ),
        );
      }
      expect(kb.reads, 0);
    });

    test('a keyboard that cannot be read (stdin from NUL on Windows) is refused by name, with no number', () {
      expect(
        () => requireTyped(_UnreadableKeyboard(), 42, 'this run', (String _) {}),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.message,
            'message',
            allOf(contains('interactive terminal'), contains('Nothing was sent'), isNot(contains('42'))),
          ),
        ),
      );
    });

    test('at a terminal only the exact number lets the run go', () {
      final List<String> asked = <String>[];
      requireTyped(FakeKeyboard(typed: <String>[' 42 ']), 42, 'this run', asked.add);
      expect(asked.single, contains('type the number of characters shown above'));
      for (final List<String> typed in <List<String>>[
        <String>[],
        <String>[''],
        <String>['41'],
        <String>['43'],
        <String>['42x'],
        <String>['forty-two'],
      ]) {
        expect(
          () => requireTyped(FakeKeyboard(typed: typed), 42, 'this run', (String _) {}),
          throwsA(
            isA<VoiceGenFailed>().having(
              (VoiceGenFailed e) => e.message,
              'message',
              contains('Nothing was sent'),
            ),
          ),
          reason: '$typed',
        );
      }
    });
  });

  group('generate, gated, in one process', () {
    late FakeEleven server;
    late Directory work;
    late List<String> printed;
    late int synths;
    setUp(() {
      server = FakeEleven();
      work = _temp('nn_vg_gen_');
      printed = <String>[];
      synths = 0;
    });
    tearDown(() => _drop(work));

    final int total = _lines.fold<int>(0, (int s, SpokenLine l) => s + l.text.runes.length);

    Future<BuiltPack> run(Keyboard kb) => generateGated(
      characterId: 'nitzi',
      lines: _lines,
      profile: _v4,
      workDir: work,
      key: key,
      keyboard: kb,
      synth: () {
        synths++;
        return ElevenLabsSynthesizer(apiKey: 'k', client: server.client);
      },
      write: printed.add,
      pricePer1000Chars: 0.08,
    );

    test(
      'refuses without a terminal: no plan printed, no voice made, nothing sent, nothing written',
      () async {
        await expectLater(run(FakeKeyboard(isTerminal: false)), throwsA(isA<VoiceGenFailed>()));
        expect(printed, isEmpty);
        expect(synths, 0);
        expect(server.requests, isEmpty);
        expect(work.listSync(), isEmpty);
      },
    );

    test('inside the run, the plan says what this run sends, not how to start another one', () async {
      await expectLater(run(FakeKeyboard(typed: <String>['0'])), throwsA(isA<VoiceGenFailed>()));
      expect(printed.first, contains('This run sends the $total characters above for nitzi'));
      expect(printed.first, isNot(contains('generate voices one character per run')));
      expect(printed.first, isNot(contains('Nothing was sent')));
    });

    test('prints the plan of exactly what it sends, then refuses a wrong number', () async {
      await expectLater(run(FakeKeyboard(typed: <String>['${total + 1}'])), throwsA(isA<VoiceGenFailed>()));
      expect(printed.first, contains('characters to send for this voice $total'));
      expect(synths, 0);
      expect(server.requests, isEmpty);
    });

    test('goes ahead with the right number, and a second run with nothing new asks for nothing', () async {
      final BuiltPack built = await run(FakeKeyboard(typed: <String>['$total']));
      expect(server.requests.length, 3);
      expect(synths, 1);
      await verifyPack(built.bytes, publicKey: key.publicKey);
      final FakeKeyboard again = FakeKeyboard();
      await run(again);
      expect(again.reads, 0, reason: 'nothing to pay for, nothing to type');
      expect(synths, 1);
      expect(server.requests.length, 3);
    });
  });

  group('the real service (a mock HTTP client)', () {
    late FakeEleven server;
    setUp(() => server = FakeEleven());

    ElevenLabsSynthesizer synth({
      String apiKey = 'test-key-123',
      Duration timeout = const Duration(seconds: 60),
    }) => ElevenLabsSynthesizer(apiKey: apiKey, client: server.client, timeout: timeout);

    test('is asked over HTTPS for the right voice, model, language, settings and 44.1 kHz format, the key in a header only, '
        'following no redirect', () async {
      final Synthesis s = await synth().say(_v4.requestFor(const SpokenLine('vo:a', 'שָׁלוֹם')));
      final Map<String, Object?> r = server.requests.single;
      expect(r['method'], 'POST');
      expect(r['scheme'], 'https');
      expect(r['host'], 'api.elevenlabs.io');
      expect(r['path'], '/v1/text-to-speech/$_voice/with-timestamps');
      expect(r['query'], 'output_format=mp3_44100_64');
      expect(r['key'], 'test-key-123');
      expect(r['followRedirects'], isFalse);
      final Map<String, Object?> body = r['body']! as Map<String, Object?>;
      expect(body['text'], 'שָׁלוֹם');
      expect(body['model_id'], 'eleven_v4');
      expect(body['language_code'], 'he');
      expect(body['voice_settings'], <String, Object?>{
        'similarity_boost': 0.75,
        'stability': 0.5,
        'use_speaker_boost': true,
      });
      expect(jsonEncode(body), isNot(contains('test-key-123')));
      expect(s.extension, 'mp3');
      expect(utf8.decode(s.audio), 'mp3:שָׁלוֹם');
      expect(s.alignment.characters.length, 'שָׁלוֹם'.length);
    });

    test('a v4 request carries no style and no speed, even when the style asks for them', () async {
      final VoiceProfile p = _with(
        modelId: 'eleven_v4_turbo',
        styles: <String, Map<String, Object?>>{
          'cheer': <String, Object?>{'stability': 0.1, 'style': 0.9, 'speed': 1.1},
        },
        styleRules: <String, List<String>>{
          'cheer': <String>['vo:core.celebrate.'],
        },
      );
      await synth().say(p.requestFor(const SpokenLine('vo:core.celebrate.well', 'כל הכבוד.')));
      final Map<String, Object?> settings = server.bodies.single['voice_settings']! as Map<String, Object?>;
      expect(settings, <String, Object?>{'similarity_boost': 0.75, 'stability': 0.1});
      expect(jsonEncode(server.bodies.single), isNot(anyOf(contains('"style"'), contains('"speed"'))));
    });

    test('refuses before sending anything: a refused text, a 22.05 kHz format, a model that is not Hebrew, a voice id '
        'with dots', () async {
      for (final ClipRequest bad in <ClipRequest>[
        _v4.requestFor(const SpokenLine('vo:a', 'כל הכבוד!')),
        _with(outputFormat: 'mp3_22050_32').requestFor(const SpokenLine('vo:a', 'שלום')),
        _with(modelId: 'eleven_multilingual_v2').requestFor(const SpokenLine('vo:a', 'שלום')),
        for (final String id in <String>['..', '.', ''])
          _with(voiceId: id).requestFor(const SpokenLine('vo:a', 'שלום')),
      ]) {
        await expectLater(synth().say(bad), throwsA(isA<VoiceGenFailed>()));
      }
      expect(server.requests, isEmpty);
    });

    test('a redirect is not followed: one request, and an error that says the status only', () async {
      server.redirectTo = 'https://evil.example/steal';
      await expectLater(
        synth(apiKey: 'redirect-key-555').say(_v4.requestFor(const SpokenLine('vo:a', 'שלום.'))),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.message,
            'message',
            allOf(contains('303'), isNot(contains('evil')), isNot(contains('redirect-key-555'))),
          ),
        ),
      );
      expect(server.requests.length, 1);
    });

    test('a call that never answers ends with an error after the timeout', () async {
      server.hang = true;
      await expectLater(
        synth(timeout: const Duration(milliseconds: 200))
            .say(_v4.requestFor(const SpokenLine('vo:a', 'שלום.'))),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.message,
            'message',
            contains('did not answer'),
          ),
        ),
      );
    });

    test(
      'a key that is not printable ASCII is refused by name before any request, and never shown',
      () async {
        const String needle = 'sk_FAKE_needle_7';
        for (final String bad in <String>[
          '$needle\r\n',
          '$needle\n',
          '$needle ',
          ' $needle',
          '$needle\t',
          '',
        ]) {
          expect(
            () => ElevenLabsSynthesizer(apiKey: bad, client: server.client),
            throwsA(
              isA<VoiceGenFailed>().having(
                (VoiceGenFailed e) => e.message,
                'message',
                allOf(contains('ELEVENLABS_API_KEY'), isNot(contains(needle))),
              ),
            ),
            reason: jsonEncode(bad),
          );
        }
        expect(server.requests, isEmpty);
      },
    );

    test('an error is reported by its status only: no body, no key', () async {
      server.failWith = 401;
      await expectLater(
        synth(apiKey: 'secret-key-777').say(_v4.requestFor(const SpokenLine('vo:a', 'שָׁלוֹם'))),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.toString(),
            'message',
            allOf(contains('401'), isNot(contains('secret-key-777')), isNot(contains('echo'))),
          ),
        ),
      );
    });

    test('any other failure of the client becomes an error that names its kind only', () async {
      final ElevenLabsSynthesizer s = ElevenLabsSynthesizer(
        apiKey: 'other-key-321',
        client: MockClient((http.Request r) async => throw StateError('boom other-key-321')),
      );
      await expectLater(
        s.say(_v4.requestFor(const SpokenLine('vo:a', 'שלום.'))),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.message,
            'message',
            allOf(contains('StateError'), isNot(contains('other-key-321')), isNot(contains('boom'))),
          ),
        ),
      );
    });
  });

  group('the voice pack', () {
    late FakeEleven server;
    late Directory work;
    setUp(() {
      server = FakeEleven();
      work = _temp('nn_vg_');
    });
    tearDown(() => _drop(work));

    ElevenLabsSynthesizer synth({String apiKey = 'test-key-123'}) =>
        ElevenLabsSynthesizer(apiKey: apiKey, client: server.client);

    Future<BuiltPack> make({
      List<SpokenLine> lines = _lines,
      VoiceProfile profile = _v4,
      Synthesizer? voice,
    }) => generateVoicePack(
      characterId: 'hero-son',
      lines: lines,
      synth: voice ?? synth(),
      profile: profile,
      key: key,
      workDir: work,
    );

    test('a line in a style is sent with the settings of that style on top of the usual ones', () async {
      await make(
        lines: const <SpokenLine>[
          SpokenLine('vo:core.celebrate.well', 'כל הכבוד.'),
          SpokenLine('vo:core.greeting.hello', 'שלום.'),
        ],
        profile: _with(
          styles: <String, Map<String, Object?>>{
            'cheer': <String, Object?>{'stability': 0.1, 'similarity_boost': 0.8},
          },
          styleRules: <String, List<String>>{
            'cheer': <String>['vo:core.celebrate.'],
          },
        ),
      );
      expect(
        <Object?>[for (final Map<String, Object?> b in server.bodies) b['voice_settings']],
        <Object?>[
          <String, Object?>{'similarity_boost': 0.8, 'stability': 0.1},
          <String, Object?>{'similarity_boost': 0.75, 'stability': 0.5},
        ],
      );
    });

    test('builds a signed voice pack the app accepts, with the sound and the cues of each line', () async {
      final BuiltPack built = await make();
      expect(server.requests.length, 3);
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      final VoiceBank bank = VoiceBank.fromPack(pack);
      expect(pack.id, 'voice-hero-son');
      expect(bank.characterId, 'hero-son');
      expect(bank.length, 3);
      expect(bank.has('vo:a.two'), isTrue);
      expect(bank.clip('vo:a.one')!.mime, 'audio/mpeg');
      expect(bank.clip('vo:a.one')!.mouth.openAt(50), isTrue, reason: 'the first group has a vowel');
      expect(bank.clip('vo:a.one')!.mouth.openAt(350), isFalse);
    });

    test('the hashes are kept next to the work folder, not in it, so they never go into the pack', () async {
      final BuiltPack built = await make();
      final File ledger = ClipLedger(work).file;
      expect(ledger.existsSync(), isTrue);
      expect(ledger.parent.path, normalisedFolder(work.parent));
      expect(ledger.readAsLinesSync().length, 3);
      final Map<String, String> made = ClipLedger(work).hashes();
      expect(made['a.one'], _v4.requestFor(_lines.first).hash);
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      expect(jsonEncode(pack.manifest), isNot(contains('voiced')));
    });

    test('said lines are not said (or paid for) again: a second run sends nothing', () async {
      await make();
      expect(server.requests.length, 3);
      await make();
      expect(server.requests.length, 3);
    });

    test('a changed text is said again, and only that line', () async {
      await make();
      final BuiltPack built = await make(
        lines: <SpokenLine>[_lines[0], const SpokenLine('vo:a.two', 'כן.'), _lines[2]],
      );
      expect(server.requests.length, 4);
      expect(server.bodies.last['text'], 'כן.');
      final VoiceBank bank = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
      expect(utf8.decode(bank.clip('vo:a.two')!.mp3), 'mp3:כן.');
      expect(utf8.decode(bank.clip('vo:a.one')!.mp3), 'mp3:${_lines[0].text}', reason: 'the others are kept');
    });

    test('changed settings, model or format make every line again', () async {
      const Map<String, Object?> s6 = <String, Object?>{'stability': 0.6, 'similarity_boost': 0.75};
      await make();
      await make(profile: _with(settings: s6));
      expect(server.requests.length, 6);
      await make(
        profile: _with(settings: s6, modelId: 'eleven_v4_turbo'),
      );
      expect(server.requests.length, 9);
      await make(
        profile: _with(settings: s6, modelId: 'eleven_v4_turbo', outputFormat: 'mp3_44100_128'),
      );
      expect(server.requests.length, 12);
    });

    test(
      'a clip made before hashes were kept (or by the test voices) counts as changed and is made again',
      () async {
        await make(voice: MockSynthesizer('hero-son'), profile: VoiceProfile.mock);
        expect(File('${work.path}${Platform.pathSeparator}vo.a.one.wav').existsSync(), isTrue);
        ClipLedger(work).file.deleteSync();
        expect(
          clipState(work, 'a.one', _v4.requestFor(_lines.first), ClipLedger(work).hashes()),
          ClipState.changed,
        );
        final BuiltPack built = await make();
        expect(server.requests.length, 3);
        expect(
          File('${work.path}${Platform.pathSeparator}vo.a.one.wav').existsSync(),
          isFalse,
          reason: 'no stale file',
        );
        final VoiceBank bank = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
        expect(bank.clip('vo:a.one')!.mime, 'audio/mpeg');
      },
    );

    test('a text the pre-flight check refuses stops the run before anything is sent', () async {
      await expectLater(
        make(lines: <SpokenLine>[..._lines, const SpokenLine('vo:a.loud', 'שלום 3')]),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.message,
            'message',
            contains('vo:a.loud: "3"'),
          ),
        ),
      );
      expect(server.requests, isEmpty);
      expect(work.listSync(), isEmpty);
    });

    test('a run that stops half way is continued where it stopped', () async {
      server.failAfter = 2;
      await expectLater(make(), throwsA(isA<VoiceGenFailed>()));
      expect(server.requests.length, 3, reason: 'two said, the third refused');
      server.failAfter = -1;
      final BuiltPack built = await make();
      expect(server.requests.length, 4, reason: 'only the third line is asked for again');
      await verifyPack(built.bytes, publicKey: key.publicKey);
    });

    test('the key is never written to any file of the work folder, the hashes or the pack', () async {
      final BuiltPack built = await make(voice: synth(apiKey: 'needle-key-98765'));
      File('${work.path}${Platform.pathSeparator}${built.fileName}').writeAsBytesSync(built.bytes);
      expect(anyFileContains(work, 'needle-key-98765'), isFalse);
      expect(ClipLedger(work).file.readAsStringSync(), isNot(contains('needle-key-98765')));
      expect(anyFileContains(work, 'mp3:'), isTrue, reason: 'the scan itself works');
    });
  });

  group('free test voices', () {
    test('are the same every time, and differ from one character to the next', () async {
      final ClipRequest r = VoiceProfile.mock.requestFor(const SpokenLine('vo:a', 'שָׁלוֹם'));
      final Synthesis a1 = await MockSynthesizer('hero-son').say(r);
      final Synthesis a2 = await MockSynthesizer('hero-son').say(r);
      final Synthesis b = await MockSynthesizer('nitzi').say(r);
      expect(a1.audio, a2.audio);
      expect(a1.audio, isNot(b.audio));
      expect(a1.extension, 'wav');
      expect(utf8.decode(a1.audio.sublist(0, 4)), 'RIFF');
    });

    test('make a voice pack that plays as audio/wav, with cues from the text', () async {
      final Directory work = _temp('nn_vg_');
      try {
        final BuiltPack built = await generateVoicePack(
          characterId: 'nitzi',
          lines: _lines,
          synth: MockSynthesizer('nitzi'),
          profile: VoiceProfile.mock,
          key: key,
          workDir: work,
        );
        final VoiceBank bank = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
        expect(bank.length, 3);
        expect(bank.clip('vo:a.one')!.mime, 'audio/wav');
        expect(bank.clip('vo:a.one')!.mouth.length, greaterThan(1));
      } finally {
        _drop(work);
      }
    });
  });

  group('the tool source', () {
    final String lib = File('tool/voice_gen_lib.dart').readAsStringSync();
    final String cli = File('tool/voice_gen.dart').readAsStringSync();
    final String audition = File('tool/audition_lib.dart').readAsStringSync();

    test('reads the ElevenLabs key from the environment only and never prints it', () {
      for (final String source in <String>[lib, audition]) {
        expect(
          RegExp(r'(print|stdout\.write\w*|stderr\.write\w*|write)\([^;]*apiKey').hasMatch(source),
          isFalse,
        );
      }
      expect(
        RegExp(r'(print|stdout\.write\w*|stderr\.write\w*)\([^;]*(key\b|ELEVENLABS)').hasMatch(cli),
        isFalse,
      );
      expect(cli, contains('Platform.environment[_keyVariable]'));
      expect(
        RegExp('Platform.environment').allMatches(cli).length,
        2,
        reason: 'the key and the home folder only',
      );
      expect(
        RegExp(r"'--(api-)?key'\s*\)").hasMatch(cli),
        isTrue,
        reason: 'only the pack-signing key file option',
      );
      expect(cli, isNot(contains('--eleven')));
      expect(lib, isNot(contains('baseUrl')), reason: 'the host is a constant');
    });

    test(
      'no paid path takes the count from the command line, and the voice is made only after the typed count',
      () {
        expect(cli, isNot(contains("_option(args, '--confirm-chars')")));
        final String gated = lib.substring(lib.indexOf('Future<BuiltPack> generateGated('));
        expect(gated.indexOf('requireTyped('), lessThan(gated.indexOf('synth()')));
        final String run = audition.substring(audition.indexOf('Future<List<File>> runAudition('));
        expect(run.indexOf('requireTerminal('), lessThan(run.indexOf('write(plan.describe')));
        expect(run.indexOf('requireTyped('), lessThan(run.indexOf('synth()')));
        final String generate = cli.substring(
          cli.indexOf('Future<void> _generate('),
          cli.indexOf('ElevenLabsSynthesizer _eleven('),
        );
        expect(generate, contains('texts.ready'), reason: 'the words come from the master table');
        expect(generate, isNot(contains('linesOfContent')), reason: 'never from the captions');
      },
    );
  });
}

/// A terminal whose keyboard cannot be read, like stdin from the NUL device on Windows.
class _UnreadableKeyboard implements Keyboard {
  @override
  bool get isTerminal => true;

  @override
  String? readLine() => throw const StdinException('cannot read');
}
