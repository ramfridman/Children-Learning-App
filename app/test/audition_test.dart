import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/audition_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/fake_eleven.dart';

Map<String, Object?> _config() =>
    jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;

Map<String, Object?> _spec(
  List<Map<String, Object?>> clips, {
  Map<String, Object?>? defaults,
}) => <String, Object?>{
  'schema': 'audition/v1',
  'title': 'test round',
  'defaults':
      defaults ??
      <String, Object?>{
        'character': 'nitzi',
        'model': 'eleven_v4_turbo',
        'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75, 'use_speaker_boost': true},
      },
  'clips': clips,
};

const LineTexts _lines = LineTexts(
  voiceText: <String, String>{'vo:t.prompt': 'פרפרים באו לגינה.'},
  caption: <String, String>{'vo:t.prompt': 'פַּרְפָּרִים בָּאוּ לַגִּנָּה!'},
);

List<AuditionClip> _read(Map<String, Object?> spec) =>
    readAuditionSpec(spec, config: _config(), lines: _lines);

void main() {
  group('the spec', () {
    test('the example spec of the format reads, and every clip is explicit and at 44.1 kHz', () {
      final Map<String, Object?> spec =
          jsonDecode(File('tool/audition_example.json').readAsStringSync()) as Map<String, Object?>;
      expect(spec['review'], 'needs-editor', reason: 'its Hebrew is new');
      final List<AuditionClip> clips = readAuditionSpec(
        spec,
        config: _config(),
        lines: const LineTexts(voiceText: <String, String>{'vo:core.greeting.hello': 'שלום, בואו נשחק.'}),
      );
      expect(clips.map((AuditionClip c) => c.id), <String>['M1-turbo', 'M1-v4', 'M2-cheer', 'M3-voice-text']);
      for (final AuditionClip c in clips) {
        expect(c.request.outputFormat, 'mp3_44100_64');
        expect(c.request.settings.keys, containsAll(<String>['stability', 'similarity_boost']));
      }
      expect(clips[1].request.modelId, 'eleven_v4');
      expect(clips[2].request.settings['stability'], 0.1);
      expect(clips[2].request.allow, <Allowance>{Allowance.exclamation});
      expect(clips[3].request.text, 'שלום, בואו נשחק.');
      expect(clips[3].source, 'voice_text of vo:core.greeting.hello');
    });

    test('a clip names a line of the master table or of today\'s captions, or gives its exact text', () {
      final List<AuditionClip> c = _read(
        _spec(<Map<String, Object?>>[
          <String, Object?>{'id': 'v', 'line': 'vo:t.prompt', 'from': 'voice_text'},
          <String, Object?>{
            'id': 'p',
            'line': 'vo:t.prompt',
            'from': 'caption',
            'allow': <Object?>['exclamation'],
          },
          <String, Object?>{'id': 't', 'text': 'כל הכבוד.'},
        ]),
      );
      expect(c.map((AuditionClip x) => x.request.text), <String>[
        'פרפרים באו לגינה.',
        'פַּרְפָּרִים בָּאוּ לַגִּנָּה!',
        'כל הכבוד.',
      ]);
    });

    test('on a v4 model, style and speed are left out and the plan says so', () {
      final AuditionClip c = _read(
        _spec(<Map<String, Object?>>[
          <String, Object?>{
            'id': 's',
            'text': 'שלום.',
            'model': 'eleven_v4',
            'settings': <String, Object?>{'style': 0.4, 'speed': 0.9},
          },
        ]),
      ).single;
      expect(c.request.settings.keys, isNot(anyOf(contains('style'), contains('speed'))));
      expect(c.dropped, <String>['style', 'speed']);
      expect(
        AuditionPlan(title: 't', clips: <AuditionClip>[c]).describe((String m) => 0.08),
        contains('not sent, eleven_v4 does not use: style, speed'),
      );
    });

    test('mistakes in a spec are refused before anything is planned', () {
      final List<Map<String, Object?>> bad = <Map<String, Object?>>[
        <String, Object?>{'id': 'a', 'text': 'שלום', 'line': 'vo:t.prompt', 'from': 'caption'},
        <String, Object?>{'id': 'a'},
        <String, Object?>{'id': 'a b', 'text': 'שלום'},
        <String, Object?>{'id': '../a', 'text': 'שלום'},
        <String, Object?>{'id': 'a', 'text': 'שלום', 'stabilty': 0.5},
        <String, Object?>{'id': 'a', 'text': 'שלום', 'model': 'eleven_multilingual_v2'},
        <String, Object?>{'id': 'a', 'text': 'שלום', 'format': 'mp3_22050_32'},
        <String, Object?>{'id': 'a', 'text': 'שלום', 'character': 'nobody'},
        <String, Object?>{
          'id': 'a',
          'text': 'שלום',
          'settings': <String, Object?>{'stability': 2},
        },
        <String, Object?>{
          'id': 'a',
          'text': 'שלום',
          'allow': <Object?>['digits'],
        },
        <String, Object?>{'id': 'a', 'line': 'vo:none', 'from': 'voice_text'},
        <String, Object?>{'id': 'a', 'line': 'vo:t.prompt', 'from': 'screen'},
        <String, Object?>{'id': 'a', 'text': 'שלום', 'from': 'caption'},
      ];
      for (final Map<String, Object?> clip in bad) {
        expect(
          () => _read(_spec(<Map<String, Object?>>[clip])),
          throwsA(isA<VoiceGenFailed>()),
          reason: '$clip',
        );
      }
      expect(
        () => _read(
          _spec(<Map<String, Object?>>[
            <String, Object?>{'id': 'a', 'text': 'שלום'},
            <String, Object?>{'id': 'A', 'text': 'שלום'},
          ]),
        ),
        throwsA(isA<VoiceGenFailed>()),
        reason: 'ids are file names, and Windows does not tell A from a',
      );
      expect(
        () => _read(<String, Object?>{..._spec(<Map<String, Object?>>[]), 'clips': <Object?>[]}),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => _read(<String, Object?>{..._spec(<Map<String, Object?>>[]), 'schema': 'audition/v2'}),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => _read(<String, Object?>{..._spec(<Map<String, Object?>>[]), 'rounds': 2}),
        throwsA(isA<VoiceGenFailed>()),
      );
    });
  });

  group('limits on one clip', () {
    test('a clip over 300 characters is refused; 300 is accepted', () {
      final String word = 'שלום ';
      final String exactly = '${(word * 60).substring(0, 299)}.';
      expect(exactly.runes.length, 300);
      expect(
        _read(
          _spec(<Map<String, Object?>>[
            <String, Object?>{'id': 'long', 'text': exactly},
          ]),
        ).single.request.characters,
        300,
      );
      expect(
        () => _read(
          _spec(<Map<String, Object?>>[
            <String, Object?>{'id': 'long', 'text': '$exactlyא'},
          ]),
        ),
        throwsA(
          isA<VoiceGenFailed>().having((VoiceGenFailed e) => e.message, 'message', contains('at most 300')),
        ),
      );
    });

    test('a clip id that Windows reserves is refused', () {
      for (final String id in <String>['nul', 'CON', 'com1', 'aux.x']) {
        expect(
          () => _read(
            _spec(<Map<String, Object?>>[
              <String, Object?>{'id': id, 'text': 'שלום.'},
            ]),
          ),
          throwsA(isA<VoiceGenFailed>()),
          reason: id,
        );
      }
    });
  });

  group('plan and run', () {
    late FakeEleven server;
    late Directory out;
    late int synths;
    late List<String> printed;
    setUp(() {
      server = FakeEleven();
      out = Directory('${Directory.systemTemp.createTempSync('nn_aud_').path}${Platform.pathSeparator}round');
      synths = 0;
      printed = <String>[];
    });
    tearDown(() {
      try {
        out.parent.deleteSync(recursive: true);
      } on FileSystemException {
        // Left for the system.
      }
    });

    Synthesizer voice() {
      synths++;
      return ElevenLabsSynthesizer(apiKey: 'k', client: server.client);
    }

    List<AuditionClip> clips() => _read(
      _spec(<Map<String, Object?>>[
        <String, Object?>{'id': 'L1-turbo', 'text': 'איפה הפרח האדום?', 'tests': 'P1'},
        <String, Object?>{'id': 'L1-v4', 'text': 'איפה הפרח האדום?', 'model': 'eleven_v4'},
        <String, Object?>{
          'id': 'L4x',
          'text': 'כל הכבוד!',
          'allow': <Object?>['exclamation'],
          'settings': <String, Object?>{'stability': 0.1},
        },
      ]),
    );

    AuditionPlan plan() =>
        AuditionPlan(title: 'test round', clips: clips(), made: madeAuditionClips(clips(), out));

    double prices(String m) => m == 'eleven_v4' ? 0.08 : 0.04;

    Future<List<File>> run(AuditionPlan p, Keyboard kb) =>
        runAudition(p, keyboard: kb, synth: voice, out: out, write: printed.add, pricePer1000: prices);

    test(
      'plan prints every clip with its exact text, model, settings and characters, and the total and cost',
      () {
        final AuditionPlan p = plan();
        expect(p.total, 16 + 16 + 9);
        expect(p.byModel, <String, int>{'eleven_v4_turbo': 25, 'eleven_v4': 16});
        expect(p.cost(prices), closeTo(25 / 1000 * 0.04 + 16 / 1000 * 0.08, 1e-12));
        final String text = p.describe(prices, runCommand: 'RUN');
        for (final String s in <String>[
          'L1-turbo: nitzi, eleven_v4_turbo, mp3_44100_64, {"similarity_boost":0.75,"stability":0.5,"use_speaker_boost":true}, 16 characters',
          'L1-v4: nitzi, eleven_v4, mp3_44100_64',
          'L4x: nitzi, eleven_v4_turbo, mp3_44100_64, {"similarity_boost":0.75,"stability":0.1,"use_speaker_boost":true}, 9 characters',
          '  text (text): איפה הפרח האדום?',
          '  allowed in this clip: exclamation',
          'Characters by model: eleven_v4_turbo 25, eleven_v4 16',
          'Characters of text in total: 41',
          'Estimated cost at list prices: 0.0023 USD',
          'run in a terminal:  RUN',
        ]) {
          expect(text, contains(s));
        }
        expect(text, contains('Nothing was sent'));
        expect(text, isNot(contains('--confirm-chars')));
      },
    );

    test('plan writes nothing and sends nothing', () {
      plan().describe(prices);
      expect(out.existsSync(), isFalse);
      expect(server.requests, isEmpty);
    });

    test('run refuses without a terminal before printing anything: no number, no voice, no folder', () async {
      final FakeKeyboard kb = FakeKeyboard(isTerminal: false, typed: <String>['41']);
      await expectLater(
        run(plan(), kb),
        throwsA(
          isA<VoiceGenFailed>().having(
            (VoiceGenFailed e) => e.message,
            'message',
            allOf(contains('interactive terminal'), isNot(contains('41'))),
          ),
        ),
      );
      expect(printed, isEmpty);
      expect(kb.reads, 0);
      expect(server.requests, isEmpty);
      expect(synths, 0, reason: 'the key is read only after the gate');
      expect(out.existsSync(), isFalse);
    });

    test('run prints the plan it will send, then refuses a wrong number: nothing sent, no folder', () async {
      for (final List<String> typed in <List<String>>[
        <String>[],
        <String>['40'],
        <String>['42'],
        <String>['0'],
      ]) {
        printed.clear();
        await expectLater(
          run(plan(), FakeKeyboard(typed: typed)),
          throwsA(
            isA<VoiceGenFailed>().having(
              (VoiceGenFailed e) => e.message,
              'message',
              contains('Nothing was sent'),
            ),
          ),
          reason: '$typed',
        );
        expect(printed.first, contains('Characters of text in total: 41'));
        expect(printed.first, contains('Characters by model: eleven_v4_turbo 25, eleven_v4 16'));
      }
      expect(server.requests, isEmpty);
      expect(synths, 0);
      expect(out.existsSync(), isFalse);
    });

    test('inside the run, the plan asks for the total instead of saying how to start a run', () async {
      await expectLater(run(plan(), FakeKeyboard(typed: <String>['0'])), throwsA(isA<VoiceGenFailed>()));
      expect(printed.first, contains('Type the total below to make them'));
      expect(printed.first, isNot(contains('Nothing was sent')));
      expect(printed.first, isNot(contains('run in a terminal')));
    });

    test('a text the pre-flight check refuses is refused before the count is asked', () async {
      final AuditionPlan p = AuditionPlan(
        title: 't',
        clips: _read(
          _spec(<Map<String, Object?>>[
            <String, Object?>{'id': 'loud', 'text': 'כל הכבוד!'},
          ]),
        ),
      );
      expect(p.describe(prices), contains('loud: "!" (U+0021)'));
      final FakeKeyboard kb = FakeKeyboard(typed: <String>['${p.total}']);
      await expectLater(
        run(p, kb),
        throwsA(
          isA<VoiceGenFailed>().having((VoiceGenFailed e) => e.message, 'message', contains('loud: "!"')),
        ),
      );
      expect(kb.reads, 0);
      expect(server.requests, isEmpty);
      expect(synths, 0);
    });

    test(
      'run with the typed count makes each clip with its own request, and records what was sent',
      () async {
        final List<File> files = await run(plan(), FakeKeyboard(typed: <String>['41']));
        expect(files.map((File f) => f.uri.pathSegments.last), <String>[
          'L1-turbo.mp3',
          'L1-v4.mp3',
          'L4x.mp3',
        ]);
        expect(server.bodies.map((Map<String, Object?> b) => b['model_id']), <String>[
          'eleven_v4_turbo',
          'eleven_v4',
          'eleven_v4_turbo',
        ]);
        for (final Map<String, Object?> r in server.requests) {
          expect(r['query'], 'output_format=mp3_44100_64');
          expect(r['followRedirects'], isFalse);
          expect(jsonEncode(r['body']), isNot(anyOf(contains('"style"'), contains('"speed"'))));
        }
        expect(server.bodies.last['text'], 'כל הכבוד!');
        final Map<String, Object?> record = jsonDecode(
          File('${out.path}${Platform.pathSeparator}L4x.json').readAsStringSync(),
        ) as Map<String, Object?>;
        expect(record['hash'], clips()[2].request.hash);
        expect(record['text'], 'כל הכבוד!');
        expect(jsonEncode(record), isNot(contains('"k"')), reason: 'no key in the record');
      },
    );

    test('a second plan counts only what changed, and a run then sends only that', () async {
      await run(plan(), FakeKeyboard(typed: <String>['41']));
      expect(plan().total, 0);
      expect(plan().describe(prices), contains('(already made, not sent again)'));
      final FakeKeyboard none = FakeKeyboard(isTerminal: false);
      expect(await run(plan(), none), isEmpty, reason: 'nothing to pay for needs no terminal');
      // The v4 clip gets another stability: only it is new.
      final List<AuditionClip> changed = _read(
        _spec(<Map<String, Object?>>[
          <String, Object?>{'id': 'L1-turbo', 'text': 'איפה הפרח האדום?'},
          <String, Object?>{
            'id': 'L1-v4',
            'text': 'איפה הפרח האדום?',
            'model': 'eleven_v4',
            'settings': <String, Object?>{'stability': 0.8},
          },
        ]),
      );
      final AuditionPlan again = AuditionPlan(
        title: 't',
        clips: changed,
        made: madeAuditionClips(changed, out),
      );
      expect(again.total, 16);
      await run(again, FakeKeyboard(typed: <String>['16']));
      expect(server.requests.length, 4);
      expect((server.bodies.last['voice_settings']! as Map<String, Object?>)['stability'], 0.8);
    });
  });
}
