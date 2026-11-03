// The voice tool in three languages (hand-off H1 of docs/languages/voices.md): the `language` key, the character check
// of each language, IPA-only clips, the language in the plan, the output folder, and the audition-only candidate voices.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/audition_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/fake_eleven.dart';

String u(int r) => String.fromCharCode(r);

Map<String, Object?> _config() =>
    jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;

Map<String, Object?> _spec(
  List<Map<String, Object?>> clips, {
  Map<String, Object?>? defaults,
}) => <String, Object?>{
  'schema': 'audition/v1',
  'title': 'languages',
  'defaults':
      defaults ??
      <String, Object?>{
        'character': 'nitzi',
        'model': 'eleven_v4',
        'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75, 'use_speaker_boost': true},
      },
  'clips': clips,
};

List<AuditionClip> _read(List<Map<String, Object?>> clips, {Map<String, Object?>? defaults}) =>
    readAuditionSpec(_spec(clips, defaults: defaults), config: _config());

Set<String> _chars(List<TextProblem> p) => p.map((TextProblem t) => t.char).toSet();

const Set<Allowance> _ipa = <Allowance>{Allowance.ipa};

void main() {
  group('the character check, by language', () {
    test('Hebrew is the default and is checked as it always was', () {
      expect(preflight('a', 'שלום, בואו נשחק.'), isEmpty);
      expect(preflight('a', 'שלום, בואו נשחק.', language: 'he'), isEmpty);
      expect(_chars(preflight('a', 'שלום Nitzi')), <String>{'N', 'i', 't', 'z'});
    });

    test(
      'English: Latin letters and the usual punctuation; Hebrew, Cyrillic, digits and "!" are refused',
      () {
        expect(preflight('e', "What's this? It's a cat.", language: 'en'), isEmpty);
        expect(preflight('e', 'Hello, my-friend... ok: yes; "no" - done', language: 'en'), isEmpty);
        expect(preflight('e', 'cat', language: 'en'), isEmpty);
        for (final MapEntry<String, String> c in <String, String>{
          'cat שלום': 'ש',
          'cat кот': 'к',
          'cat 3': '3',
          'cat!': '!',
          'caf${u(0xE9)}': u(0xE9),
          'it${u(0x2019)}s': u(0x2019),
          'cat {child}': '{',
          'cat​': u(0x200B),
        }.entries) {
          expect(_chars(preflight('e', c.key, language: 'en')), contains(c.value), reason: c.key);
        }
      },
    );

    test(
      'Russian: Cyrillic, Ёё and the stress mark U+0301 after a letter; Latin, Hebrew and Greek are refused',
      () {
        expect(preflight('r', 'мама.', language: 'ru'), isEmpty);
        expect(preflight('r', 'Ёлка. ёж, Я ви${u(0x301)}жу ко${u(0x301)}шку?', language: 'ru'), isEmpty);
        expect(
          preflight('r', 'АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя', language: 'ru'),
          isEmpty,
        );
        for (final MapEntry<String, String> c in <String, String>{
          'мама a': 'a',
          'мама o': 'o', // a Latin o inside a Russian word is a look-alike, refused
          'мама שלום': 'ש',
          'мама ${u(0x3B1)}': u(0x3B1),
          'мама 3': '3',
          'мама!': '!',
          '${u(0x301)}мама': u(0x301), // a stress mark with no letter before it
          'ма ${u(0x301)}ма': u(0x301),
          'ma${u(0x301)}ma': 'm',
        }.entries) {
          expect(_chars(preflight('r', c.key, language: 'ru')), contains(c.value), reason: c.key);
        }
        expect(
          preflight('r', 'м${u(0x301)}а ${u(0x301)}', language: 'ru').map((TextProblem p) => p.char),
          <String>[u(0x301)],
          reason: 'one good mark does not excuse a bad one',
        );
      },
    );

    test('a Latin or Cyrillic letter in a Hebrew clip is refused, and the reverse; the split-clip rule', () {
      expect(_chars(preflight('h', 'שלום cat')), <String>{'c', 'a', 't'});
      expect(_chars(preflight('h', 'שלום кот')), <String>{'к', 'о', 'т'});
      expect(preflight('h', 'שלום кот').first.why, contains('not Hebrew'));
      expect(preflight('e', 'cat שלום', language: 'en').first.why, contains('English'));
      expect(preflight('r', 'кот cat', language: 'ru').first.why, contains('Russian'));
      expect(_chars(preflight('e', 'cat кот', language: 'en')), <String>{'к', 'о', 'т'});
      expect(_chars(preflight('r', 'кот שלום', language: 'ru')), <String>{'ש', 'ל', 'ו', 'ם'});
    });

    test('Hebrew points and the rare points are Hebrew only', () {
      expect(preflight('h', 'שָׁלוֹם'), isEmpty);
      expect(_chars(preflight('e', 'cat${u(0x5B6)}', language: 'en')), contains(u(0x5B6)));
      expect(
        _chars(preflight('e', 'cat${u(0x5C7)}', language: 'en', allow: <Allowance>{Allowance.rarePoints})),
        contains(u(0x5C7)),
        reason: 'the allowance is about Hebrew points',
      );
    });

    test('a text with no letter of its language has nothing to say, and the message names the language', () {
      expect(preflight('e', '... ?', language: 'en').map((TextProblem p) => p.why), <String>[
        'there is nothing to say: the text has no English letter',
      ]);
      expect(preflight('r', '... ?', language: 'ru').map((TextProblem p) => p.why), <String>[
        'there is nothing to say: the text has no Russian letter',
      ]);
      expect(preflight('h', '... ?').map((TextProblem p) => p.why), <String>[
        'there is nothing to say: the text has no Hebrew letter',
      ]);
    });

    test('a language that is not he, en or ru is refused', () {
      for (final String l in <String>['fr', 'HE', '', 'heb']) {
        expect(() => preflight('x', 'שלום', language: l), throwsA(isA<VoiceGenFailed>()), reason: l);
      }
    });
  });

  group('IPA-only clips', () {
    test('a clip that is only one IPA word is accepted in every language', () {
      for (final String l in voiceLanguages) {
        for (final String t in <String>['/ma/', '/ʃaˈve/', '/s/', '/${u(0xE6)}/', '/${u(0x3B8)}/']) {
          expect(
            preflight('i', t, allow: _ipa, language: l),
            isEmpty,
            reason: '$l $t',
          );
        }
      }
    });

    test('U+02B2 (palatalised) and U+0361 (tie bar) are IPA letters; other marks and signs are not', () {
      expect(preflight('i', '/m${u(0x2B2)}a/', allow: _ipa, language: 'ru'), isEmpty);
      expect(preflight('i', '/t${u(0x361)}s/', allow: _ipa, language: 'ru'), isEmpty);
      expect(preflight('i', '/t${u(0x361)}${u(0x255)}${u(0x2D0)}/', allow: _ipa, language: 'ru'), isEmpty);
      for (final String bad in <String>[u(0x303), u(0x301), '1', '!', '{', ' ', u(0x1C3)]) {
        expect(
          preflight('i', '/m${bad}a/', allow: _ipa, language: 'ru'),
          isNotEmpty,
          reason: 'U+${bad.runes.first.toRadixString(16)}',
        );
      }
    });

    test(
      'IPA needs the allowance, an audio tag alone is still nothing to say, and text around IPA is checked',
      () {
        expect(preflight('i', '/ma/', language: 'en'), isNotEmpty, reason: 'no allowance');
        expect(
          preflight(
            'i',
            '[gently]',
            allow: Allowance.values.toSet(),
            language: 'en',
          ).map((TextProblem p) => p.why),
          <String>['there is nothing to say: the text has no English letter'],
        );
        expect(_chars(preflight('i', '/ma/ שלום', allow: _ipa, language: 'en')), contains('ש'));
        expect(preflight('i', 'cat /kæt/', allow: _ipa, language: 'en'), isEmpty);
      },
    );

    test('the Hebrew IPA pilot files read with the Hebrew default', () {
      for (final String f in <String>['pilot-ipa', 'pilot-round2-ipa']) {
        final Map<String, Object?> spec =
            jsonDecode(File('../docs/languages/hebrew/$f.json').readAsStringSync()) as Map<String, Object?>;
        final List<AuditionClip> clips = readAuditionSpec(spec, config: _config());
        expect(clips, isNotEmpty);
        expect(clips.every((AuditionClip c) => c.request.languageCode == 'he'), isTrue, reason: f);
        expect(clips.expand((AuditionClip c) => c.request.problems(c.id)), isEmpty, reason: f);
      }
    });
  });

  group('the language key of a spec', () {
    test('a clip and the defaults carry it into language_code, and the clip wins; Hebrew is the default', () {
      final Map<String, Object?> defaults = <String, Object?>{
        'character': 'lang-en-jessica',
        'language': 'en',
        'model': 'eleven_v4',
        'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
      };
      final List<AuditionClip> c = _read(<Map<String, Object?>>[
        <String, Object?>{'id': 'en', 'text': 'cat.'},
        <String, Object?>{'id': 'he', 'text': 'שלום.', 'language': 'he', 'character': 'nitzi'},
      ], defaults: defaults);
      expect(c[0].request.languageCode, 'en');
      expect(c[0].request.body['language_code'], 'en');
      expect(c[1].request.languageCode, 'he');
      final List<AuditionClip> plain = _read(<Map<String, Object?>>[
        <String, Object?>{'id': 'a', 'text': 'שלום.'},
      ]);
      expect(plain.single.request.languageCode, 'he');
      expect(plain.single.request.body['language_code'], 'he');
    });

    test('the language is part of the hash, and a Hebrew clip hashes as it did before the key existed', () {
      final AuditionClip he = _read(<Map<String, Object?>>[
        <String, Object?>{'id': 'a', 'text': 'cat'},
      ]).single;
      final AuditionClip en = _read(<Map<String, Object?>>[
        <String, Object?>{'id': 'a', 'text': 'cat', 'language': 'en'},
      ]).single;
      expect(en.request.hash, isNot(he.request.hash));
      final ClipRequest legacy = ClipRequest(
        text: 'cat',
        voiceId: he.request.voiceId,
        modelId: he.request.modelId,
        settings: he.request.settings,
        outputFormat: he.request.outputFormat,
      );
      expect(legacy.languageCode, 'he');
      expect(legacy.hash, he.request.hash);
    });

    test('an unknown language is refused when the spec is read', () {
      for (final Object? l in <Object?>['fr', 'EN', '', 3]) {
        expect(
          () => _read(<Map<String, Object?>>[
            <String, Object?>{'id': 'a', 'text': 'שלום', 'language': l},
          ]),
          throwsA(isA<VoiceGenFailed>()),
          reason: '$l',
        );
      }
      expect(
        () => _read(
          <Map<String, Object?>>[
            <String, Object?>{'id': 'a', 'text': 'שלום'},
          ],
          defaults: <String, Object?>{
            'character': 'nitzi',
            'language': 'xx',
            'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
          },
        ),
        throwsA(isA<VoiceGenFailed>()),
      );
    });

    test('the plan refuses a letter of the wrong language in a clip, and the reverse', () {
      final AuditionPlan p = AuditionPlan(
        title: 't',
        clips: _read(<Map<String, Object?>>[
          <String, Object?>{'id': 'he-with-latin', 'text': 'שלום cat'},
          <String, Object?>{'id': 'en-with-hebrew', 'text': 'cat שלום', 'language': 'en'},
          <String, Object?>{'id': 'ru-with-latin', 'text': 'кот cat', 'language': 'ru'},
          <String, Object?>{'id': 'ok-en', 'text': 'cat.', 'language': 'en'},
        ]),
      );
      final String text = p.describe((String m) => 0.08);
      expect(text, contains('he-with-latin: "c"'));
      expect(text, contains('en-with-hebrew: "ש"'));
      expect(text, contains('ru-with-latin: "c"'));
      expect(p.problems.map((TextProblem x) => x.id).toSet(), <String>{
        'he-with-latin',
        'en-with-hebrew',
        'ru-with-latin',
      });
    });

    test('a "line" clip is Hebrew text, so it is refused in another language', () {
      final List<AuditionClip> c = readAuditionSpec(
        _spec(<Map<String, Object?>>[
          <String, Object?>{'id': 'l', 'line': 'vo:t.prompt', 'from': 'voice_text', 'language': 'en'},
        ]),
        config: _config(),
        lines: const LineTexts(voiceText: <String, String>{'vo:t.prompt': 'פרפרים באו לגינה.'}),
      );
      expect(c.single.request.problems('l'), isNotEmpty);
    });
  });

  group('the plan output and the output folder', () {
    double price(String m) => m == 'eleven_v4' ? 0.08 : 0.04;

    test('every clip shows its language, and the characters are totalled by language', () {
      final AuditionPlan p = AuditionPlan(
        title: 't',
        clips: _read(<Map<String, Object?>>[
          <String, Object?>{'id': 'a', 'text': 'cat.', 'language': 'en', 'character': 'lang-en-jessica'},
          <String, Object?>{'id': 'b', 'text': 'שלום.'},
          <String, Object?>{
            'id': 'c',
            'text': '/ma/',
            'allow': <Object?>['ipa'],
            'language': 'en',
            'character': 'lang-en-sarah',
          },
        ]),
      );
      expect(p.byLanguage, <String, int>{'en': 8, 'he': 5});
      final String text = p.describe(price);
      expect(text, contains('a: lang-en-jessica, language en, eleven_v4'));
      expect(text, contains('b: nitzi, language he, eleven_v4'));
      expect(text, contains('Characters by language: en 8, he 5'));
      expect(text, contains('Characters of text in total: 13'));
      expect(text, isNot(contains('MISSING')));
    });

    test('the default folder of a Hebrew spec keeps its name; another language goes in front', () {
      List<AuditionClip> clips(String language, {int hebrew = 0}) => _read(<Map<String, Object?>>[
        for (int i = 0; i < hebrew; i++) <String, Object?>{'id': 'h$i', 'text': 'שלום'},
        <String, Object?>{'id': 'x', 'text': language == 'he' ? 'שלום' : 'cat', 'language': language},
        <String, Object?>{'id': 'y', 'text': language == 'he' ? 'שלום' : 'cat', 'language': language},
      ]);
      expect(auditionFolderName('pilot', clips('he')), 'pilot');
      expect(auditionFolderName('pilot', clips('en')), 'en-pilot');
      expect(
        auditionFolderName('pilot', clips('en', hebrew: 1)),
        'en-pilot',
        reason: 'the frame is the minority',
      );
      expect(auditionFolderName('pilot-round2', clips('en')), 'en-pilot-round2');
      expect(auditionLanguage(clips('he', hebrew: 3)), 'he');
      final Set<String> names = <String>{
        auditionFolderName('pilot', clips('he')),
        auditionFolderName('pilot', clips('en')),
        auditionFolderName(
          'pilot',
          _read(<Map<String, Object?>>[
            <String, Object?>{'id': 'z', 'text': 'кот', 'language': 'ru'},
          ]),
        ),
      };
      expect(names.length, 3, reason: 'the three pilot.json files never share a folder');
    });
  });

  group('the audition candidates in content/voices.json', () {
    Map<String, Object?> voices() => _config()['voices']! as Map<String, Object?>;
    Iterable<String> candidates() => voices().entries
        .where((MapEntry<String, Object?> e) => (e.value! as Map<String, Object?>)['candidate'] == true)
        .map((MapEntry<String, Object?> e) => e.key);

    test('the eight pilot voices are there, marked as candidates; the placeholders are marked and empty', () {
      expect(candidates().toSet(), <String>{
        'lang-en-jessica',
        'lang-en-sarah',
        'lang-en-matilda',
        'lang-en-brian',
        'lang-ru-marina',
        'lang-ru-ekaterina',
        'lang-ru-maxim',
        'lang-ru-ivan',
      });
      for (final String c in candidates()) {
        final Map<String, Object?> v = voices()[c]! as Map<String, Object?>;
        final String id = v['voiceId']! as String;
        if (id.isEmpty) {
          expect(v['idStatus'], 'OWNER-TO-FILL', reason: c);
        } else {
          checkVoiceId(id);
          expect(v['idStatus'], 'from-third-party-list-unverified', reason: c);
        }
        expect(
          v.keys.where((String k) => k.startsWith('_')),
          isEmpty,
          reason: 'underscore notes are dropped',
        );
      }
      expect(
        voices()['nitzi'],
        isNot(contains('candidate')),
        reason: 'the real characters are not candidates',
      );
    });

    test('a candidate is never a character of the packs: plan, generate and a plain profile refuse it', () {
      final Map<String, Object?> config = _config();
      expect(packCharacters(config), isNot(anyOf(contains('lang-en-jessica'), contains('lang-ru-marina'))));
      expect(packCharacters(config), containsAll(<String>['nitzi', 'hero-son', 'climber-tzuri']));
      for (final String c in candidates()) {
        expect(() => VoiceProfile.fromConfig(config, c), throwsA(isA<VoiceGenFailed>()), reason: c);
      }
      expect(
        VoiceProfile.fromConfig(config, 'lang-en-jessica', audition: true).voiceId,
        'cgSgspJ2msm6clMCkdW9',
      );
      expect(VoiceProfile.fromConfig(config, 'lang-ru-marina', audition: true).voiceId, isEmpty);
      expect(
        () => VoiceProfile.fromConfig(config, 'nobody', audition: true),
        throwsA(isA<VoiceGenFailed>()),
        reason: 'a name that is not in the file is still an error',
      );
      expect(
        () => VoiceProfile.fromConfig(<String, Object?>{
          ...config,
          'voices': <String, Object?>{
            'nitzi': <String, Object?>{'voiceId': ''},
          },
        }, 'nitzi'),
        throwsA(isA<VoiceGenFailed>()),
        reason: 'a pack voice with no id is still an error',
      );
    });

    group('a voice with no id yet', () {
      late FakeEleven server;
      late Directory out;
      late List<String> printed;
      late int synths;
      setUp(() {
        server = FakeEleven();
        out = Directory(
          '${Directory.systemTemp.createTempSync('nn_lang_').path}${Platform.pathSeparator}round',
        );
        printed = <String>[];
        synths = 0;
      });
      tearDown(() {
        try {
          out.parent.deleteSync(recursive: true);
        } on FileSystemException {
          // Left for the system.
        }
      });

      AuditionPlan plan() => AuditionPlan(
        title: 'ru',
        clips: _read(<Map<String, Object?>>[
          <String, Object?>{'id': 'ru-a', 'text': 'мама.', 'language': 'ru', 'character': 'lang-ru-marina'},
          <String, Object?>{'id': 'ru-b', 'text': 'кот.', 'language': 'ru', 'character': 'lang-ru-marina'},
          <String, Object?>{'id': 'ru-c', 'text': 'дом.', 'language': 'ru', 'character': 'lang-ru-maxim'},
          <String, Object?>{'id': 'en-a', 'text': 'cat.', 'language': 'en', 'character': 'lang-en-jessica'},
        ]),
      );

      test('plan names the voices to fill in and the clips that wait, and does not crash', () {
        final AuditionPlan p = plan();
        expect(p.missingVoices.keys, <String>['lang-ru-marina', 'lang-ru-maxim']);
        final String text = p.describe((String m) => 0.08);
        expect(text, contains('ru-a: lang-ru-marina, language ru, eleven_v4, mp3_44100_64'));
        expect(text, contains(', VOICE ID MISSING'));
        expect(
          text,
          contains(
            'en-a: lang-en-jessica, language en, eleven_v4, mp3_44100_64, {"similarity_boost":0.75,"stability":0.5,"use_speaker_boost":true}, 4 characters\n',
          ),
        );
        expect(text, contains('VOICE IDS MISSING for 2 voices'));
        expect(text, contains('  lang-ru-marina: 2 clips, 9 characters'));
        expect(text, contains('  lang-ru-maxim: 1 clips, 4 characters'));
        expect(text, contains('Characters of text in total: 17'), reason: 'the count is still there to read');
        expect(text, isNot(contains('run in a terminal')), reason: 'it cannot be run yet');
        expect(text, isNot(contains('Type the total')));
      });

      test('run prints the plan and then refuses: nothing typed, no voice made, no folder', () async {
        final FakeKeyboard kb = FakeKeyboard(typed: <String>['17']);
        await expectLater(
          runAudition(
            plan(),
            keyboard: kb,
            synth: () {
              synths++;
              return ElevenLabsSynthesizer(apiKey: 'k', client: server.client);
            },
            out: out,
            write: printed.add,
          ),
          throwsA(
            isA<VoiceGenFailed>().having(
              (VoiceGenFailed e) => e.message,
              'message',
              allOf(contains('lang-ru-marina, lang-ru-maxim'), contains('Nothing was sent')),
            ),
          ),
        );
        expect(printed.first, contains('VOICE IDS MISSING'));
        expect(kb.reads, 0);
        expect(synths, 0);
        expect(server.requests, isEmpty);
        expect(out.existsSync(), isFalse);
      });

      test('a plan whose voices all have ids is run as before', () async {
        final AuditionPlan p = AuditionPlan(
          title: 'en',
          clips: _read(<Map<String, Object?>>[
            <String, Object?>{'id': 'en-a', 'text': 'cat.', 'language': 'en', 'character': 'lang-en-jessica'},
          ]),
        );
        expect(p.missingVoices, isEmpty);
        final List<File> made = await runAudition(
          p,
          keyboard: FakeKeyboard(typed: <String>['4']),
          synth: () => ElevenLabsSynthesizer(apiKey: 'k', client: server.client),
          out: out,
          write: printed.add,
        );
        expect(made, hasLength(1));
        expect(server.requests, hasLength(1));
        expect(server.bodies.single['language_code'], 'en');
      });
    });
  });

  group('the pilot files of docs/languages', () {
    final List<String> files = <String>[
      'english/pilot',
      'english/pilot-round2',
      'russian/pilot',
      'russian/pilot-round2',
      'hebrew/pilot',
      'hebrew/pilot-ipa',
      'hebrew/pilot-round2',
      'hebrew/pilot-round2-ipa',
    ];

    for (final String f in files) {
      test('$f reads, passes the pre-flight check, and is in the language its folder says', () {
        final Map<String, Object?> spec =
            jsonDecode(File('../docs/languages/$f.json').readAsStringSync()) as Map<String, Object?>;
        final List<AuditionClip> clips = readAuditionSpec(spec, config: _config());
        expect(clips, isNotEmpty);
        expect(clips.expand((AuditionClip c) => c.request.problems(c.id)), isEmpty);
        final String folder = f.split('/').first;
        expect(
          auditionLanguage(clips),
          <String, String>{'english': 'en', 'russian': 'ru', 'hebrew': 'he'}[folder],
        );
        for (final AuditionClip c in clips) {
          expect(c.request.outputFormat, 'mp3_44100_64');
          expect(c.request.characters, lessThanOrEqualTo(maxAuditionClipCharacters));
        }
      });
    }
  });
}
