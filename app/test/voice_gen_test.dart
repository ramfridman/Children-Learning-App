import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/pack_fixtures.dart';

/// A pretend ElevenLabs on this PC: answers every request with a short sound and one timestamp per character.
class FakeEleven {
  FakeEleven._(this._server);

  final HttpServer _server;
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];
  int failWith = 0;
  int failAfter = -1;

  static Future<FakeEleven> start() async {
    final FakeEleven f = FakeEleven._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    unawaited(f._serve());
    return f;
  }

  String get url => 'http://127.0.0.1:${_server.port}';

  Future<void> _serve() async {
    await for (final HttpRequest req in _server) {
      final Map<String, Object?> body = jsonDecode(await utf8.decodeStream(req)) as Map<String, Object?>;
      requests.add(<String, Object?>{
        'path': req.uri.path,
        'query': req.uri.query,
        'key': req.headers.value('xi-api-key'),
        'body': body,
      });
      final bool fail = failWith != 0 || (failAfter >= 0 && requests.length > failAfter);
      if (fail) {
        req.response
          ..statusCode = failWith != 0 ? failWith : 500
          ..write('{"detail":"echo ${jsonEncode(body)}"}');
        await req.response.close();
        continue;
      }
      final String text = body['text']! as String;
      final List<String> chars = text.split('');
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, Object?>{
            'audio_base64': base64Encode(utf8.encode('mp3:$text')),
            'alignment': <String, Object?>{
              'characters': chars,
              'character_start_times_seconds': <double>[for (int i = 0; i < chars.length; i++) i * 0.1],
              'character_end_times_seconds': <double>[for (int i = 0; i < chars.length; i++) (i + 1) * 0.1],
            },
          }),
        );
      await req.response.close();
    }
  }

  Future<void> close() => _server.close(force: true);
}

Directory _temp(String name) => Directory.systemTemp.createTempSync(name);

void _drop(Directory d) {
  try {
    d.deleteSync(recursive: true);
  } on FileSystemException {
    // Left for the system.
  }
}

const List<SpokenLine> _lines = <SpokenLine>[
  SpokenLine('vo:a.one', 'שָׁלוֹם'),
  SpokenLine('vo:a.two', 'כֵּן'),
  SpokenLine('vo:a.three', 'לֹא'),
];

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

    test('text without niqqud gives no open mouth at all, which is why lines are written with niqqud', () {
      final Alignment a = Alignment(<String>['ש', 'ל', 'ו', 'ם'], <double>[0, 0.1, 0.2, 0.3], <double>[
        0.1,
        0.2,
        0.3,
        0.4,
      ]);
      expect(cuesFromAlignment(a), isEmpty);
    });
  });

  group('the lines', () {
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

  group('the plan counts characters before anything is sent', () {
    test('per voice and in total, with the cost at the price given', () {
      final VoicePlan plan = planVoices(<String>['a', 'b', 'c'], _lines);
      final int per = _lines.fold<int>(0, (int s, SpokenLine l) => s + l.text.runes.length);
      expect(plan.perCharacter, per);
      expect(plan.total, per * 3);
      expect(plan.cost(0.5), closeTo(per * 3 / 1000 * 0.5, 1e-9));
      expect(plan.describe(0.5), contains('--confirm-chars ${per * 3}'));
    });

    test('a respelled word is counted as it will be sent', () {
      final VoicePlan plain = planVoices(<String>['a'], _lines);
      final VoicePlan respell = planVoices(
        <String>['a'],
        _lines,
        pronunciation: <String, String>{'כֵּן': 'כֵּןכֵּן'},
      );
      expect(respell.total, greaterThan(plain.total));
    });
  });

  group('styles and what is still to say', () {
    test('a line is said in the style whose prefix its id starts with', () {
      const Map<String, List<String>> rules = <String, List<String>>{
        'cheer': <String>['vo:core.celebrate.', 'vo:core.ceremony.'],
      };
      expect(styleOf('vo:core.celebrate.well', rules), 'cheer');
      expect(styleOf('vo:core.ceremony.gold', rules), 'cheer');
      expect(styleOf('vo:core.greeting.hello', rules), isNull);
      expect(styleOf('vo:celebrate.butterflies', rules), isNull);
    });

    test(
      'lines whose sound exists are reused and not counted, and the confirmation is for what will be said',
      () {
        final VoicePlan all = planVoices(<String>['a', 'b'], _lines);
        final VoicePlan some = planVoices(
          <String>['a', 'b'],
          _lines,
          alreadyMade: (String c, SpokenLine l) => c == 'a' || l == _lines.first,
        );
        expect(some.toSay, _lines.length - 1);
        expect(some.reused, _lines.length + 1);
        expect(some.total, lessThan(all.total));
        expect(some.describe(0.04), contains('--confirm-chars ${some.total}'));
        final VoicePlan none = planVoices(
          <String>['a'],
          _lines,
          alreadyMade: (String c, SpokenLine l) => true,
        );
        expect(none.total, 0);
      },
    );
  });

  group('the real service (a fake one on this PC)', () {
    late FakeEleven server;
    setUp(() async => server = await FakeEleven.start());
    tearDown(() => server.close());

    ElevenLabsSynthesizer synth({String apiKey = 'test-key-123'}) => ElevenLabsSynthesizer(
      apiKey: apiKey,
      voiceId: 'voice-xyz',
      modelId: 'model-abc',
      baseUrl: server.url,
      voiceSettings: const <String, Object?>{'stability': 0.5},
    );

    test('is asked for the right voice, model, language and format, with the key in a header only', () async {
      final Synthesis s = await synth().say('שָׁלוֹם');
      final Map<String, Object?> r = server.requests.single;
      expect(r['path'], '/v1/text-to-speech/voice-xyz/with-timestamps');
      expect(r['query'], 'output_format=mp3_22050_32');
      expect(r['key'], 'test-key-123');
      final Map<String, Object?> body = r['body']! as Map<String, Object?>;
      expect(body['text'], 'שָׁלוֹם');
      expect(body['model_id'], 'model-abc');
      expect(body['language_code'], 'he');
      expect(body['voice_settings'], <String, Object?>{'stability': 0.5});
      expect(jsonEncode(body), isNot(contains('test-key-123')));
      expect(s.extension, 'mp3');
      expect(utf8.decode(s.audio), 'mp3:שָׁלוֹם');
      expect(s.alignment.characters.length, 'שָׁלוֹם'.length);
    });

    test(
      'a line in a style is sent with the settings of that style, and the others with the usual ones',
      () async {
        final Directory work = _temp('nn_vg_style_');
        try {
          await generateVoicePack(
            characterId: 'hero-son',
            lines: <SpokenLine>[
              const SpokenLine('vo:core.celebrate.well', 'כׇּל הַכָּבוֹד!'),
              const SpokenLine('vo:core.greeting.hello', 'שָׁלוֹם!'),
            ],
            synth: synth(),
            key: key,
            workDir: work,
            styleRules: const <String, List<String>>{
              'cheer': <String>['vo:core.celebrate.'],
            },
            styles: const <String, Map<String, Object?>>{
              'cheer': <String, Object?>{'stability': 0.1, 'style': 0.9},
            },
          );
          final List<Object?> sent = <Object?>[
            for (final Map<String, Object?> r in server.requests)
              (r['body']! as Map<String, Object?>)['voice_settings'],
          ];
          expect(sent, <Object?>[
            <String, Object?>{'stability': 0.1, 'style': 0.9},
            <String, Object?>{'stability': 0.5},
          ]);
        } finally {
          work.deleteSync(recursive: true);
        }
      },
    );

    test('an error is reported by its status only: no body, no key', () async {
      server.failWith = 401;
      await expectLater(
        synth(apiKey: 'secret-key-777').say('שָׁלוֹם'),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.toString(),
            'message',
            allOf(contains('401'), isNot(contains('secret-key-777')), isNot(contains('echo'))),
          ),
        ),
      );
    });

    test('builds a signed voice pack the app accepts, with the sound and the cues of each line', () async {
      final Directory work = _temp('nn_vg_');
      try {
        final BuiltPack built = await generateVoicePack(
          characterId: 'hero-son',
          lines: _lines,
          synth: synth(),
          key: key,
          workDir: work,
        );
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
      } finally {
        _drop(work);
      }
    });

    test('said lines are not said (or paid for) again: a second run sends nothing', () async {
      final Directory work = _temp('nn_vg_');
      try {
        await generateVoicePack(characterId: 'x', lines: _lines, synth: synth(), key: key, workDir: work);
        expect(server.requests.length, 3);
        await generateVoicePack(characterId: 'x', lines: _lines, synth: synth(), key: key, workDir: work);
        expect(server.requests.length, 3);
      } finally {
        _drop(work);
      }
    });

    test('a run that stops half way is continued where it stopped', () async {
      final Directory work = _temp('nn_vg_');
      try {
        server.failAfter = 2;
        await expectLater(
          generateVoicePack(characterId: 'x', lines: _lines, synth: synth(), key: key, workDir: work),
          throwsA(isA<VoiceGenFailed>()),
        );
        expect(server.requests.length, 3, reason: 'two said, the third refused');
        server.failAfter = -1;
        final BuiltPack built = await generateVoicePack(
          characterId: 'x',
          lines: _lines,
          synth: synth(),
          key: key,
          workDir: work,
        );
        expect(server.requests.length, 4, reason: 'only the third line is asked for again');
        await verifyPack(built.bytes, publicKey: key.publicKey);
      } finally {
        _drop(work);
      }
    });

    test('the key is never written to any file of the work folder or the pack', () async {
      final Directory work = _temp('nn_vg_');
      try {
        final BuiltPack built = await generateVoicePack(
          characterId: 'x',
          lines: _lines,
          synth: synth(apiKey: 'needle-key-98765'),
          key: key,
          workDir: work,
        );
        File('${work.path}${Platform.pathSeparator}${built.fileName}').writeAsBytesSync(built.bytes);
        expect(anyFileContains(work, 'needle-key-98765'), isFalse);
        expect(anyFileContains(work, 'mp3:'), isTrue, reason: 'the scan itself works');
      } finally {
        _drop(work);
      }
    });
  });

  group('free test voices', () {
    test('are the same every time, and differ from one character to the next', () async {
      final Synthesis a1 = await MockSynthesizer('hero-son').say('שָׁלוֹם');
      final Synthesis a2 = await MockSynthesizer('hero-son').say('שָׁלוֹם');
      final Synthesis b = await MockSynthesizer('nitzi').say('שָׁלוֹם');
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

  group('the command line', () {
    Future<ProcessResult> run(List<String> args, {Map<String, String>? env}) => Process.run(
      'dart',
      <String>['run', 'tool/voice_gen.dart', ...args],
      environment: env,
      runInShell: true,
    );

    test('plan prints the number of characters and sends nothing', () async {
      final ProcessResult r = await run(<String>['plan', '--price', '0.3']);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      expect(r.stdout, contains('Characters of text in total:'));
      expect(r.stdout, contains('--confirm-chars'));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('generate refuses unless the count typed equals the planned count', () async {
      final ProcessResult none = await run(
        <String>['generate', 'nitzi'],
        env: <String, String>{'ELEVENLABS_API_KEY': 'k'},
      );
      expect(none.exitCode, 1);
      expect(none.stderr, contains('Nothing was sent'));
      final ProcessResult wrong = await run(
        <String>['generate', 'nitzi', '--confirm-chars', '1'],
        env: <String, String>{'ELEVENLABS_API_KEY': 'k'},
      );
      expect(wrong.exitCode, 1);
      expect(wrong.stderr, contains('Nothing was sent'));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('the tool source', () {
    test('reads the ElevenLabs key from the environment only and never prints it', () {
      final String lib = File('tool/voice_gen_lib.dart').readAsStringSync();
      final String cli = File('tool/voice_gen.dart').readAsStringSync();
      expect(RegExp(r'(print|stdout\.write\w*|stderr\.write\w*)\([^;]*apiKey').hasMatch(lib), isFalse);
      expect(
        RegExp(r'(print|stdout\.write\w*|stderr\.write\w*)\([^;]*(key\b|ELEVENLABS)').hasMatch(cli),
        isFalse,
      );
      expect(cli, contains('Platform.environment[_keyVariable]'));
      expect(
        RegExp(r"'--(api-)?key'\s*\)").hasMatch(cli),
        isTrue,
        reason: 'only the pack-signing key file option',
      );
      expect(cli, isNot(contains('--eleven')));
    });
  });
}
