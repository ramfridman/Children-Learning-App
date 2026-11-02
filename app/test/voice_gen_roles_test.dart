// B-45: the tone of a line by the end of its voice id (`*.h3`), and a friend's own lines only. All with mocks: nothing
// here reaches ElevenLabs, and no key is read.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/fake_eleven.dart';
import 'support/pack_fixtures.dart';

Map<String, Object?> _realConfig() =>
    jsonDecode(File('../content/voices.json').readAsStringSync()) as Map<String, Object?>;

/// A small config: two narrators, two friends, the rules and styles of the real file.
Map<String, Object?> _config({Object? narrators = const <String>['nitzi', 'hero-son'], Object? ownLines}) =>
    <String, Object?>{
      'modelId': 'eleven_v4_turbo',
      'outputFormat': 'mp3_44100_64',
      'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.8, 'use_speaker_boost': true},
      'styles': <String, Object?>{
        'cheer': <String, Object?>{'stability': 0.35},
        'ask': <String, Object?>{'stability': 0.6},
        'hint3': <String, Object?>{'stability': 0.7},
      },
      'styleRules': <String, Object?>{
        'cheer': <String>['vo:celebrate.'],
        'hint3': <String>['*.h3'],
        'ask': <String>['*.prompt', 'vo:fb.'],
      },
      'narrators': ?narrators,
      'ownLines': ownLines ?? <String>['vo:core.greeting.hello', 'vo:core.celebrate.well'],
      'voices': <String, Object?>{
        'nitzi': <String, Object?>{'voiceId': 'NarratorOne0001'},
        'hero-son': <String, Object?>{'voiceId': 'NarratorTwo0002'},
        'tower-tamir': <String, Object?>{'voiceId': 'FriendOne000003'},
        'inventor-gali': <String, Object?>{'voiceId': 'FriendTwo000004'},
      },
    };

const List<SpokenLine> _lines = <SpokenLine>[
  SpokenLine('vo:core.greeting.hello', 'שלום.'),
  SpokenLine('vo:a.one.prompt', 'כמה?'),
  SpokenLine('vo:a.one.correct', 'כן.'),
  SpokenLine('vo:core.celebrate.well', 'כל הכבוד.'),
  SpokenLine('vo:a.one.h3', 'אחד, שניים, שלושה.'),
];

Set<String> get _release => <String>{for (final SpokenLine l in _lines) l.voId};

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());

  group('styleOf: a pattern with * matches the end of the voice id, any other the start', () {
    const Map<String, List<String>> rules = <String, List<String>>{
      'cheer': <String>['vo:celebrate.'],
      'hint3': <String>['*.h3'],
      'hint': <String>['*.h1', '*.h2', 'vo:hint.'],
      'ask': <String>['*.prompt', 'vo:fb.'],
    };

    test('the end of the id', () {
      expect(styleOf('vo:b.numb01.1.h3', rules), 'hint3');
      expect(styleOf('vo:b.numb01.1.h2', rules), 'hint');
      expect(styleOf('vo:b.numb01.1.prompt', rules), 'ask');
    });

    test('the start of the id, as before', () {
      expect(styleOf('vo:celebrate.towers', rules), 'cheer');
      expect(styleOf('vo:hint.plate.h2', rules), 'hint');
      expect(styleOf('vo:fb.ord', rules), 'ask');
    });

    test('neither the start nor the end: the usual voice', () {
      expect(styleOf('vo:b.numb01.1.correct', rules), isNull);
      expect(styleOf('vo:core.greeting.hello', rules), isNull);
    });

    test('a suffix must be at the end, and a prefix at the start', () {
      expect(styleOf('vo:x.h3.correct', rules), isNull, reason: '.h3 in the middle');
      expect(styleOf('vo:x.h3x', rules), isNull);
      expect(styleOf('x.vo:celebrate.y', rules), isNull, reason: 'a prefix in the middle');
      expect(styleOf('vo:celebrate', rules), isNull, reason: 'the dot is part of the prefix');
    });

    test('the first style in the order written wins when two match', () {
      expect(styleOf('vo:celebrate.x.h3', rules), 'cheer', reason: 'cheer is written first');
      expect(styleOf('vo:fb.x.h3', rules), 'hint3', reason: 'hint3 is written before ask');
      const Map<String, List<String>> reversed = <String, List<String>>{
        'ask': <String>['vo:fb.'],
        'hint3': <String>['*.h3'],
      };
      expect(styleOf('vo:fb.x.h3', reversed), 'ask');
    });

    test('a pattern that would match every line is refused when the profile is read', () {
      for (final String bad in <String>['*', '']) {
        final Map<String, Object?> config = _config();
        (config['styleRules']! as Map<String, Object?>)['ask'] = <String>[bad];
        expect(
          () => VoiceProfile.fromConfig(config, 'nitzi'),
          throwsA(isA<VoiceGenFailed>()),
          reason: '"$bad"',
        );
      }
    });
  });

  group('content/voices.json keeps its rule order and gives the tones of the plan', () {
    late VoiceProfile nitzi;
    setUp(() => nitzi = VoiceProfile.fromConfig(_realConfig(), 'nitzi'));

    double stability(String voId) =>
        nitzi.requestFor(SpokenLine(voId, 'שלום')).settings['stability']! as double;

    test('the styles are read in the order written in the file', () {
      expect(nitzi.styleRules.keys.toList(), <String>[
        'cheer',
        'ceremony',
        'thinking',
        'hint3',
        'hint',
        'ask',
      ]);
    });

    test('one id of each kind gets the stability of its kind', () {
      expect(stability('vo:core.celebrate.well'), 0.35);
      expect(stability('vo:celebrate.growing_towers'), 0.35);
      expect(stability('vo:core.ceremony.medal'), 0.45);
      expect(stability('vo:core.thinking.think'), 0.55);
      expect(stability('vo:b.numb14.8.h3'), 0.7);
      expect(stability('vo:ordinal.first.h1'), 0.65);
      expect(stability('vo:ordinal.first.h2'), 0.65);
      expect(stability('vo:hint.plate.h2'), 0.65);
      expect(stability('vo:ordinal.first.prompt'), 0.6);
      expect(stability('vo:fb.ord'), 0.6);
      expect(stability('vo:core.encourage.mistake'), 0.6);
      expect(stability('vo:b.numb03.8.correct'), 0.5);
      expect(stability('vo:core.greeting.hello'), 0.5);
    });
  });

  group('a friend says only its own lines, a narrator says every line', () {
    test('the profile of a narrator has no own lines; a friend has the list', () {
      final Map<String, Object?> config = _config();
      expect(VoiceProfile.fromConfig(config, 'nitzi').ownLines, isNull);
      expect(VoiceProfile.fromConfig(config, 'hero-son').ownLines, isNull);
      expect(VoiceProfile.fromConfig(config, 'tower-tamir').ownLines, <String>{
        'vo:core.greeting.hello',
        'vo:core.celebrate.well',
      });
    });

    test('with no narrators in the file, every character says every line', () {
      final Map<String, Object?> config = _config(narrators: null);
      expect(VoiceProfile.fromConfig(config, 'tower-tamir').ownLines, isNull);
      expect(VoiceProfile.fromConfig(config, 'tower-tamir').linesOf(_lines), _lines);
    });

    test('linesOf keeps the order and the lines given, and says() agrees', () {
      final VoiceProfile friend = VoiceProfile.fromConfig(_config(), 'tower-tamir');
      expect(friend.linesOf(_lines).map((SpokenLine l) => l.voId), <String>[
        'vo:core.greeting.hello',
        'vo:core.celebrate.well',
      ]);
      expect(friend.says('vo:a.one.prompt'), isFalse);
      expect(friend.says('vo:core.greeting.hello'), isTrue);
      expect(VoiceProfile.fromConfig(_config(), 'nitzi').linesOf(_lines), _lines);
    });

    test('a friend with no own lines, a narrator with no voice, or a list that is not ids is refused', () {
      expect(
        () => VoiceProfile.fromConfig(_config(ownLines: <String>[]), 'tower-tamir'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => VoiceProfile.fromConfig(_config(ownLines: <String>['core.greeting.hello']), 'tower-tamir'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => VoiceProfile.fromConfig(_config(ownLines: 'vo:core.greeting.hello'), 'tower-tamir'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => VoiceProfile.fromConfig(_config(narrators: <String>['nitzi', 'nobody']), 'nitzi'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => VoiceProfile.fromConfig(_config(narrators: 'nitzi'), 'nitzi'),
        throwsA(isA<VoiceGenFailed>()),
      );
    });

    test('an own line that no content asks for is refused, so a misspelt id cannot shrink the pack', () {
      final VoiceProfile friend = VoiceProfile.fromConfig(_config(), 'tower-tamir');
      friend.checkOwnLines(_release);
      expect(() => friend.checkOwnLines(<String>{'vo:core.greeting.hello'}), throwsA(isA<VoiceGenFailed>()));
      VoiceProfile.fromConfig(_config(), 'nitzi').checkOwnLines(<String>{});
    });

    test('the plan gives a friend its own lines and a narrator every line, and counts each voice', () {
      final Map<String, Object?> config = _config();
      final VoicePlan plan = planVoices(<String, VoiceProfile>{
        'nitzi': VoiceProfile.fromConfig(config, 'nitzi'),
        'tower-tamir': VoiceProfile.fromConfig(config, 'tower-tamir'),
      }, _lines);
      List<String> ids(String c) => <String>[
        for (final PlannedClip p in plan.clips)
          if (p.character == c) p.line.voId,
      ];
      expect(ids('nitzi'), _release.toList());
      expect(ids('tower-tamir'), <String>['vo:core.greeting.hello', 'vo:core.celebrate.well']);
      expect(plan.toSay, _lines.length + 2);
      expect(plan.perCharacter, _lines.fold<int>(0, (int s, SpokenLine l) => s + l.text.runes.length));
      final String text = plan.describe(0.04);
      expect(text, contains('Lines per voice: nitzi 5, tower-tamir 2'));
      expect(
        text,
        contains(
          'tower-tamir (eleven_v4_turbo, mp3_44100_64): new 2, changed 0, unchanged 0; characters to send for this voice 14',
        ),
      );
    });

    test('two friends with the same lines print one line count; the clips are in the order of the lines', () {
      final Map<String, Object?> config = _config();
      final VoicePlan plan = planVoices(<String, VoiceProfile>{
        'tower-tamir': VoiceProfile.fromConfig(config, 'tower-tamir'),
        'inventor-gali': VoiceProfile.fromConfig(config, 'inventor-gali'),
      }, _lines);
      expect(plan.describe(0.04), contains('Lines per voice: 2\n'));
      expect(plan.total, 28);
    });

    test('a friend\'s voice pack holds only its own lines, and the tool sends only those', () async {
      final FakeEleven server = FakeEleven();
      final Directory work = Directory.systemTemp.createTempSync('nn_vg_roles_');
      addTearDown(() {
        for (final FileSystemEntity e in <FileSystemEntity>[work, File('${work.path}.voiced.jsonl')]) {
          if (e.existsSync()) e.deleteSync(recursive: true);
        }
      });
      final BuiltPack built = await generateVoicePack(
        characterId: 'tower-tamir',
        lines: _lines,
        synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: server.client),
        profile: VoiceProfile.fromConfig(_config(), 'tower-tamir'),
        key: key,
        workDir: work,
      );
      expect(server.requests.length, 2);
      expect(
        <Object?>[for (final Map<String, Object?> b in server.bodies) b['text']],
        <String>['שלום.', 'כל הכבוד.'],
      );
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      expect(VoiceBank.fromPack(pack).ids.toSet(), <String>{
        'vo:core.greeting.hello',
        'vo:core.celebrate.well',
      });
    });

    test('a narrator\'s pack holds every line', () async {
      final Directory work = Directory.systemTemp.createTempSync('nn_vg_roles_');
      addTearDown(() {
        for (final FileSystemEntity e in <FileSystemEntity>[work, File('${work.path}.voiced.jsonl')]) {
          if (e.existsSync()) e.deleteSync(recursive: true);
        }
      });
      final BuiltPack built = await generateVoicePack(
        characterId: 'nitzi',
        lines: _lines,
        synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: FakeEleven().client),
        profile: VoiceProfile.fromConfig(_config(), 'nitzi'),
        key: key,
        workDir: work,
      );
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      expect(VoiceBank.fromPack(pack).ids.toSet(), _release);
    });
  });

  group('the release check: every vo id has a recording in every shipped voice pack', () {
    final VoiceProfile narrator = VoiceProfile.fromConfig(_config(), 'nitzi');
    final VoiceProfile friend = VoiceProfile.fromConfig(_config(), 'tower-tamir');
    const Set<String> own = <String>{'vo:core.greeting.hello', 'vo:core.celebrate.well'};

    test('a complete narrator pack and a friend pack with only its own lines both pass', () {
      expect(missingVoLines(narrator, _release, _release), isEmpty);
      expect(missingVoLines(friend, _release, own), isEmpty);
    });

    test('a narrator pack that misses a line fails, and names the line', () {
      expect(missingVoLines(narrator, _release, _release.difference(<String>{'vo:a.one.h3'})), <String>[
        'vo:a.one.h3',
      ]);
      expect(missingVoLines(narrator, _release, own), hasLength(_release.length - own.length));
    });

    test('a friend that misses one of its own lines fails', () {
      expect(missingVoLines(friend, _release, <String>{'vo:core.greeting.hello'}), <String>[
        'vo:core.celebrate.well',
      ]);
      expect(missingVoLines(friend, _release, <String>{}), hasLength(own.length));
    });

    test('a friend pack of a larger release still needs nothing beyond its own lines', () {
      final Set<String> bigger = <String>{..._release, 'vo:b.new.prompt'};
      expect(missingVoLines(friend, bigger, own), isEmpty);
      expect(missingVoLines(narrator, bigger, _release), <String>['vo:b.new.prompt']);
    });

    test('the same check on packs built by the tool: narrator and friend', () async {
      final Map<String, Object?> config = _config();
      for (final String c in <String>['nitzi', 'tower-tamir']) {
        final Directory work = Directory.systemTemp.createTempSync('nn_vg_cover_');
        addTearDown(() {
          for (final FileSystemEntity e in <FileSystemEntity>[work, File('${work.path}.voiced.jsonl')]) {
            if (e.existsSync()) e.deleteSync(recursive: true);
          }
        });
        final VoiceProfile profile = VoiceProfile.fromConfig(config, c);
        final BuiltPack built = await generateVoicePack(
          characterId: c,
          lines: _lines,
          synth: MockSynthesizer(c),
          profile: profile,
          key: key,
          workDir: work,
        );
        final VoiceBank bank = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
        expect(missingVoLines(profile, _release, bank.ids.toSet()), isEmpty, reason: c);
      }
    });
  });

  group('content/voices.json: the seven friends and the nine own lines', () {
    final Map<String, Object?> config = _realConfig();
    const List<String> friends = <String>[
      'alien-jili',
      'climber-tzuri',
      'compass-romi',
      'friend-daughter',
      'inventor-gali',
      'tower-tamir',
      'weaver-keshet',
    ];

    test('the narrators are Nitzi and hero-son; every other voice is a friend with the same nine lines', () {
      expect(config['narrators'], <String>['nitzi', 'hero-son']);
      final Set<String> voices = (config['voices']! as Map<String, Object?>).keys.toSet();
      expect(voices.difference(<String>{'nitzi', 'hero-son'}), friends.toSet());
      for (final String f in friends) {
        final VoiceProfile p = VoiceProfile.fromConfig(config, f);
        expect(p.ownLines, hasLength(9), reason: f);
        expect(p.ownLines, VoiceProfile.fromConfig(config, 'tower-tamir').ownLines, reason: f);
      }
      for (final String n in <String>['nitzi', 'hero-son']) {
        expect(VoiceProfile.fromConfig(config, n).ownLines, isNull, reason: n);
      }
    });

    test('each own line is a real line of the core lines, so no id is misspelt', () {
      final Set<String> core = <String>{
        for (final SpokenLine l in coreLines(File('../content/lines/core.he.json'))) l.voId,
      };
      VoiceProfile.fromConfig(config, 'tower-tamir').checkOwnLines(core);
    });
  });
}
