// The release voicing tools (docs/audio/release-voicing-plan.md, F1 to F4 and F6): a text voiced once for every id that
// has it, the sets of lines (a friend's own, the shell's), the shell's lines file, the model of each voice, and the language
// courses (a "!" sent as ".", slow copies and cut words made from clips already voiced, placeholders refused). A pretend
// ElevenLabs (a mock HTTP client) and a pretend ffmpeg: nothing leaves the test, and no key is read.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/audio_tool_lib.dart';
import '../tool/lang_voice_lib.dart';
import '../tool/pack_builder_lib.dart';
import '../tool/voice_gen_lib.dart';
import 'support/fake_eleven.dart';
import 'support/pack_fixtures.dart';

Directory _temp(String name) => Directory.systemTemp.createTempSync(name);

void _drop(Directory d) {
  for (final FileSystemEntity e in <FileSystemEntity>[
    d,
    File('${d.path}.voiced.jsonl'),
    Directory('${d.path}.align'),
    Directory('${d.path}.pack-stage'),
  ]) {
    try {
      e.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  }
}

const String _voice = 'VoiceXyz0123';

const VoiceProfile _v4 = VoiceProfile(
  voiceId: _voice,
  modelId: 'eleven_v4',
  outputFormat: 'mp3_44100_64',
  settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75, 'use_speaker_boost': true},
);

const VoiceProfile _english = VoiceProfile(
  voiceId: 'EnglishVoice01',
  modelId: 'eleven_v4',
  outputFormat: 'mp3_44100_64',
  settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
);

PlannedClip _clip(String id, String text, {String character = 'nitzi', ClipState state = ClipState.newLine}) {
  final SpokenLine line = SpokenLine(id, text);
  return PlannedClip(character, line, _v4.requestFor(line), state);
}

/// A pretend ffmpeg: it records what it was asked and answers with bytes that name the request.
class _FakeAudio implements AudioTool {
  _FakeAudio({this.problem});

  final String? problem;
  final List<String> calls = <String>[];
  final List<(double, double)> cuts = <(double, double)>[];

  @override
  Future<String?> unavailableReason() async => problem;

  @override
  Future<Uint8List> slow(Uint8List mp3, double tempo) async {
    calls.add('slow $tempo');
    return Uint8List.fromList(utf8.encode('slow:${utf8.decode(mp3)}'));
  }

  @override
  Future<Uint8List> cut(Uint8List mp3, double fromSeconds, double toSeconds) async {
    calls.add('cut');
    cuts.add((fromSeconds, toSeconds));
    return Uint8List.fromList(utf8.encode('cut:${utf8.decode(mp3)}'));
  }
}

Map<String, Object?> _planJson({
  String course = 'eng',
  List<Map<String, Object?>> frame = const <Map<String, Object?>>[],
  List<Map<String, Object?>> targets = const <Map<String, Object?>>[],
  List<Map<String, Object?>> cuts = const <Map<String, Object?>>[],
}) => <String, Object?>{
  'course': course,
  'pack': 'lang-$course',
  'frameLines': frame,
  'targetClips': targets,
  'cutClips': cuts,
};

Map<String, Object?> _frame(String id, String? voice, {String review = 'text-ready'}) => <String, Object?>{
  'id': id,
  'vo': 'vo:eng.${id.replaceAll('-', '_')}',
  'he': voice,
  'voice': voice,
  'review': review,
};

Map<String, Object?> _target(String id, String shown, {String say = ''}) => <String, Object?>{
  'id': id,
  'vo': 'vo:eng.${id.replaceAll('-', '_')}',
  'shown': shown,
  'say': say,
};

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());

  group('F1: a text said under several ids is voiced once', () {
    test('the plan counts the characters of the first id only, and says how many lines share', () {
      final VoicePlan plan = planVoices(
        <String, VoiceProfile>{'nitzi': _v4},
        const <SpokenLine>[
          SpokenLine('vo:a.one', 'שלום'),
          SpokenLine('vo:a.two', 'שלום'),
          SpokenLine('vo:a.three', 'כן'),
          SpokenLine('vo:a.four', 'שלום'),
        ],
      );
      expect(plan.total, 6, reason: 'שלום 4 and כן 2');
      expect(plan.shared, 2);
      expect(plan.sharedCharacters, 8);
      expect(plan.clips.where((PlannedClip c) => c.isCopy).map((PlannedClip c) => c.copyOf), <String?>[
        'vo:a.one',
        'vo:a.one',
      ]);
      final String text = plan.describe(0.08);
      expect(text, contains('same text as another line 2'));
      expect(text, contains('Lines with the same text as another line of the same voice: 2'));
      expect(text, contains('8 characters not sent'));
      expect(text, contains('Characters of text in total: 6'));
    });

    test('with shareSameText off every id is voiced', () {
      final VoicePlan plan = planVoices(
        <String, VoiceProfile>{'nitzi': _v4},
        const <SpokenLine>[SpokenLine('vo:a.one', 'שלום'), SpokenLine('vo:a.two', 'שלום')],
        shareSameText: false,
      );
      expect(plan.total, 8);
      expect(plan.shared, 0);
      expect(plan.describe(0.08), isNot(contains('same text as another line')));
    });

    test('a line in another style, or in another voice, is not a copy', () {
      const VoiceProfile cheering = VoiceProfile(
        voiceId: _voice,
        modelId: 'eleven_v4',
        outputFormat: 'mp3_44100_64',
        settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
        styles: <String, Map<String, Object?>>{
          'cheer': <String, Object?>{'stability': 0.1},
        },
        styleRules: <String, List<String>>{
          'cheer': <String>['vo:celebrate.'],
        },
      );
      final VoicePlan styled = planVoices(
        <String, VoiceProfile>{'nitzi': cheering},
        const <SpokenLine>[SpokenLine('vo:a.one', 'כל הכבוד'), SpokenLine('vo:celebrate.one', 'כל הכבוד')],
      );
      expect(styled.shared, 0, reason: 'another style is another sound');
      final VoicePlan twoVoices = planVoices(
        <String, VoiceProfile>{'nitzi': _v4, 'alien-jili': _v4},
        const <SpokenLine>[SpokenLine('vo:a.one', 'שלום')],
      );
      expect(twoVoices.shared, 0, reason: 'two characters that share a voice id still each get a pack');
      expect(twoVoices.total, 8);
    });

    test('a line that already has its sound is the one the others copy, so nothing is paid twice', () {
      final List<PlannedClip> shared = sharingSameText(<PlannedClip>[
        _clip('vo:a.one', 'שלום'),
        _clip('vo:a.two', 'שלום', state: ClipState.unchanged),
      ]);
      expect(shared[0].copyOf, 'vo:a.two');
      expect(shared[1].isCopy, isFalse);
      expect(holderIndexes(<String>['x', 'y', 'x'], <bool>[false, false, false]), <int>[0, 1, 0]);
    });

    group('the voice pack', () {
      late FakeEleven server;
      late Directory work;
      setUp(() {
        server = FakeEleven();
        work = _temp('nn_vgr_');
      });
      tearDown(() => _drop(work));

      Future<BuiltPack> make(List<SpokenLine> lines, {bool share = true, String id = 'nitzi'}) =>
          generateVoicePack(
            characterId: id,
            lines: lines,
            synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: server.client),
            profile: _v4,
            key: key,
            workDir: work,
            shareSameText: share,
          );

      const List<SpokenLine> twin = <SpokenLine>[
        SpokenLine('vo:a.one', 'שָׁלוֹם'),
        SpokenLine('vo:a.two', 'כֵּן'),
        SpokenLine('vo:a.three', 'שָׁלוֹם'),
      ];

      test(
        'sends one request for the two ids that share a text, and the pack maps both ids to one file',
        () async {
          final BuiltPack built = await make(twin);
          expect(server.requests.length, 2);
          final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
          final Map<String, String> files = <String, String>{
            for (final Object? v in pack.manifest['vo']! as List<Object?>)
              (v! as Map<String, Object?>)['id']! as String: (v as Map<String, Object?>)['file']! as String,
          };
          expect(files, <String, String>{
            'a.one': 'vo.a.one.mp3',
            'a.two': 'vo.a.two.mp3',
            'a.three': 'vo.a.one.mp3',
          });
          expect(
            pack.files.keys.where((String f) => f.startsWith('vo.')).length,
            2,
            reason: 'the sound is in once',
          );
          expect(
            pack.docs.keys.where((String f) => f.startsWith('cue.')).length,
            3,
            reason: 'one cue file per id',
          );
          final VoiceBank bank = VoiceBank.fromPack(pack);
          expect(bank.length, 3);
          expect(bank.clip('vo:a.three')!.mp3, bank.clip('vo:a.one')!.mp3);
          expect(bank.clip('vo:a.three')!.mouth.openAt(50), isTrue);
          expect(ClipLedger(work).hashes().keys, containsAll(<String>['a.one', 'a.two', 'a.three']));
        },
      );

      test('a second run sends nothing, and --each-id sends every id', () async {
        await make(twin);
        await make(twin);
        expect(server.requests.length, 2);
        final Directory other = _temp('nn_vgr_each_');
        addTearDown(() => _drop(other));
        final FakeEleven each = FakeEleven();
        await generateVoicePack(
          characterId: 'nitzi',
          lines: twin,
          synth: ElevenLabsSynthesizer(apiKey: 'test-key-123', client: each.client),
          profile: _v4,
          key: key,
          workDir: other,
          shareSameText: false,
        );
        expect(each.requests.length, 3);
      });

      test(
        'changing the first id of a shared text says only that id; the copy keeps its own sound',
        () async {
          await make(twin);
          final BuiltPack built = await make(const <SpokenLine>[
            SpokenLine('vo:a.one', 'לֹא'),
            SpokenLine('vo:a.two', 'כֵּן'),
            SpokenLine('vo:a.three', 'שָׁלוֹם'),
          ]);
          expect(server.requests.length, 3, reason: 'one new request, for the new text');
          final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
          final VoiceBank bank = VoiceBank.fromPack(pack);
          expect(utf8.decode(bank.clip('vo:a.one')!.mp3), 'mp3:לֹא');
          expect(utf8.decode(bank.clip('vo:a.three')!.mp3), 'mp3:שָׁלוֹם');
        },
      );

      test('an id whose text becomes that of a sound already made gets a free copy', () async {
        await make(const <SpokenLine>[SpokenLine('vo:a.one', 'שָׁלוֹם'), SpokenLine('vo:a.two', 'כֵּן')]);
        final BuiltPack built = await make(const <SpokenLine>[
          SpokenLine('vo:a.one', 'שָׁלוֹם'),
          SpokenLine('vo:a.two', 'שָׁלוֹם'),
        ]);
        expect(server.requests.length, 2, reason: 'nothing new was sent');
        final VoiceBank bank = VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
        expect(utf8.decode(bank.clip('vo:a.two')!.mp3), 'mp3:שָׁלוֹם');
      });

      test('the pack holds the lines of the run only, and the stage folder is gone afterwards', () async {
        await make(twin);
        final BuiltPack built = await make(const <SpokenLine>[SpokenLine('vo:a.two', 'כֵּן')]);
        final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
        expect(VoiceBank.fromPack(pack).ids, <String>['vo:a.two']);
        expect(pack.files.keys.where((String f) => f.startsWith('vo.')), <String>['vo.a.two.mp3']);
        expect(Directory('${normalisedFolder(work)}.pack-stage').existsSync(), isFalse);
        expect(
          File('${work.path}${Platform.pathSeparator}vo.a.one.mp3').existsSync(),
          isTrue,
          reason: 'kept on disk',
        );
      });
    });
  });

  group('F2 and F3: sets of lines', () {
    VoicedLine line(String id, {bool ui = false}) =>
        VoicedLine(voId: id, text: 'x', rows: const <String>[], ui: ui);
    final VoiceTexts all = VoiceTexts(<VoicedLine>[
      line('vo:a.one'),
      line('vo:core.greeting.hello'),
      line('vo:core.ceremony.gold'),
      line('vo:core.adventure.play_again', ui: true),
    ]);

    test('each set holds its lines, and a run is blocked only by the rows of its own set', () {
      List<String> ids(LineSet s) => all.only(s).lines.map((VoicedLine l) => l.voId).toList();
      expect(ids(LineSet.full), hasLength(4));
      expect(ids(LineSet.lessons), <String>['vo:a.one', 'vo:core.greeting.hello', 'vo:core.ceremony.gold']);
      expect(ids(LineSet.ui), <String>['vo:core.adventure.play_again']);
      expect(ids(LineSet.own), <String>['vo:core.greeting.hello', 'vo:core.ceremony.gold']);
      final VoiceTexts waiting = VoiceTexts(<VoicedLine>[
        line('vo:a.one'),
        const VoicedLine(
          voId: 'vo:core.adventure.play_again',
          text: '',
          rows: <String>[],
          problem: 'text-ready',
          ui: true,
        ),
      ]);
      expect(waiting.only(LineSet.lessons).blocked, isEmpty);
      expect(waiting.only(LineSet.full).blocked, hasLength(1));
    });

    test('a friend has nine own lines, all in the core lines; the shell alone is not a pack', () {
      expect(friendOwnLineIds, hasLength(9));
      final String core = File('../content/lines/core.he.json').readAsStringSync();
      for (final String id in friendOwnLineIds) {
        expect(core, contains('"${id.substring(3)}"'), reason: id);
      }
      expect(LineSet.ui.makesAPack, isFalse);
      expect(<bool>[
        LineSet.full.makesAPack,
        LineSet.lessons.makesAPack,
        LineSet.own.makesAPack,
      ], everyElement(isTrue));
      expect(() => LineSet.parse('everything'), throwsA(isA<VoiceGenFailed>()));
      expect(LineSet.parse('own'), LineSet.own);
    });

    group('the shell lines file', () {
      late Directory tmp;
      setUp(() => tmp = _temp('nn_ui_'));
      tearDown(() => tmp.deleteSync(recursive: true));

      File write(Object? doc) =>
          File('${tmp.path}${Platform.pathSeparator}ui.he.json')..writeAsStringSync(jsonEncode(doc));

      MasterRow row(String voice, {String status = 'owner-approved'}) =>
          MasterRow(text: voice, uiText: voice, voiceText: voice, status: status);

      Map<String, Object?> doc(List<Object?> lines) => <String, Object?>{
        'schema': 'ui-lines/v1',
        'masterSource': 'he.dart',
        'lands': <String, Object?>{'counting': 'גבעות', 'market': 'כפר'},
        'lines': lines,
      };

      test('a line with {land} is voiced once for each land with the land voice name in its place', () {
        final List<VoicedLine> lines = uiLines(
          file: write(
            doc(<Object?>[
              <String, Object?>{'id': 'core.adventure.welcome', 'string': 'welcome', 'perLand': true},
              <String, Object?>{'id': 'core.adventure.play_again', 'string': 'again'},
            ]),
          ),
          master: <String, MasterRow>{
            masterKey('he.dart', 'welcome'): row('אל {land}.'),
            masterKey('he.dart', 'again'): row('שוב.'),
          },
        );
        expect(lines.map((VoicedLine l) => l.voId), <String>[
          'vo:core.adventure.welcome.counting',
          'vo:core.adventure.welcome.market',
          'vo:core.adventure.play_again',
        ]);
        expect(lines.map((VoicedLine l) => l.text), <String>['אל גבעות.', 'אל כפר.', 'שוב.']);
        expect(lines.every((VoicedLine l) => l.ui && l.problem == null), isTrue);
      });

      test('a missing row, an unapproved row, no voice text, and a {land} that is not there all wait', () {
        final List<VoicedLine> lines = uiLines(
          file: write(
            doc(<Object?>[
              <String, Object?>{'id': 'core.a.gone', 'string': 'gone'},
              <String, Object?>{'id': 'core.a.wait', 'string': 'wait'},
              <String, Object?>{'id': 'core.a.empty', 'string': 'empty'},
              <String, Object?>{'id': 'core.a.noland', 'string': 'noland', 'perLand': true},
              <String, Object?>{'id': 'Core.Bad', 'string': 'noland'},
            ]),
          ),
          master: <String, MasterRow>{
            masterKey('he.dart', 'wait'): row('רגע.', status: 'text-ready'),
            masterKey('he.dart', 'empty'): row(''),
            masterKey('he.dart', 'noland'): row('בלי שם.'),
          },
        );
        expect(lines[0].problem, contains('no row in the master table'));
        expect(lines[1].problem, contains('is text-ready'));
        expect(lines[2].problem, contains('has no voice_text'));
        expect(lines[3].problem, contains('has no {land} to fill'));
        expect(lines.last.problem, contains('not a plain name'));
      });

      test('a placeholder that is not filled in is refused by the check before it is sent', () {
        final List<VoicedLine> lines = uiLines(
          file: write(
            doc(<Object?>[
              <String, Object?>{'id': 'core.a.stray', 'string': 'stray'},
            ]),
          ),
          master: <String, MasterRow>{masterKey('he.dart', 'stray'): row('אל {land}.')},
        );
        final ClipRequest request = _v4.requestFor(SpokenLine(lines.single.voId, lines.single.text));
        expect(request.problems(lines.single.voId).map((TextProblem p) => p.char), contains('{'));
      });

      test('a file of another schema is refused', () {
        expect(
          () => uiLines(file: write(<String, Object?>{'schema': 'x'}), master: const <String, MasterRow>{}),
          throwsA(isA<VoiceGenFailed>()),
        );
      });
    });

    test('the real ui.he.json gives the 30 clips the app asks for, each from a row of the master table', () {
      final Map<String, MasterRow> master = readMaster(
        File('../docs/review/hebrew-master.csv').readAsStringSync(),
      );
      final List<VoicedLine> lines = uiLines(file: File('../content/lines/ui.he.json'), master: master);
      expect(lines, hasLength(30));
      expect(lines.map((VoicedLine l) => l.voId).toSet(), hasLength(30));
      for (final VoicedLine l in lines) {
        expect(l.problem ?? '', isNot(contains('no row in the master table')), reason: l.voId);
        expect(l.problem ?? '', isNot(contains('{land}')), reason: l.voId);
        expect(l.text, isNot(contains('{')), reason: l.voId);
        expect(l.ui, isTrue);
      }
      final Set<String> ids = lines.map((VoicedLine l) => l.voId).toSet();
      // adventure_line.dart: vo:core.adventure.<reason>.<land> for four reasons and every land, play_again with no land,
      // vo:core.adventure.lang.<course> for every language.
      for (final TrophyLand land in TrophyLand.values) {
        for (final String reason in <String>['welcome', 'call_for_help', 'same_land', 'other_land']) {
          expect(ids, contains('vo:core.adventure.$reason.${land.name}'));
        }
      }
      expect(ids, contains('vo:core.adventure.play_again'));
      for (final String course in Course.languages) {
        expect(ids, contains('vo:core.adventure.lang.$course'));
      }
    });
  });

  group('F6: each voice may have its own model', () {
    Map<String, Object?> config({Object? heroModel, String? nitziModel}) => <String, Object?>{
      'modelId': 'eleven_v4_turbo',
      'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
      'voices': <String, Object?>{
        'nitzi': <String, Object?>{'voiceId': 'NitziVoice0001', 'modelId': ?nitziModel},
        'hero-son': <String, Object?>{'voiceId': 'HeroVoice0001', 'modelId': ?heroModel},
      },
    };

    test('a voice uses its modelId, the others the global one, and a model argument beats both', () {
      final Map<String, Object?> c = config(nitziModel: 'eleven_v4');
      expect(VoiceProfile.fromConfig(c, 'nitzi').modelId, 'eleven_v4');
      expect(VoiceProfile.fromConfig(c, 'hero-son').modelId, 'eleven_v4_turbo');
      expect(VoiceProfile.fromConfig(c, 'nitzi', model: 'eleven_v4_turbo').modelId, 'eleven_v4_turbo');
      expect(VoiceProfile.fromConfig(config(nitziModel: ''), 'nitzi').modelId, 'eleven_v4_turbo');
    });

    test('a model of a voice that does not read Hebrew, or is not text, is refused', () {
      expect(
        () => VoiceProfile.fromConfig(config(nitziModel: 'eleven_multilingual_v2'), 'nitzi'),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(() => VoiceProfile.fromConfig(config(heroModel: 4), 'hero-son'), throwsA(isA<VoiceGenFailed>()));
    });

    test('v4 drops style and speed for the voice on v4, and a turbo voice keeps the same rule', () {
      final Map<String, Object?> c = config(nitziModel: 'eleven_v4')
        ..['settings'] = <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75, 'style': 0.3};
      expect(
        VoiceProfile.fromConfig(c, 'nitzi').requestFor(const SpokenLine('vo:a', 'שלום')).settings.keys,
        <String>['similarity_boost', 'stability'],
      );
    });

    test('the plan shows the characters and the price of each model, and their sum', () {
      final Map<String, Object?> c = config(nitziModel: 'eleven_v4');
      final VoicePlan plan = planVoices(
        <String, VoiceProfile>{
          'nitzi': VoiceProfile.fromConfig(c, 'nitzi'),
          'hero-son': VoiceProfile.fromConfig(c, 'hero-son'),
        },
        const <SpokenLine>[SpokenLine('vo:a.one', 'שלום וברכה')],
      );
      double price(String model) => model == 'eleven_v4' ? 0.08 : 0.04;
      expect(plan.charactersByModel, <String, int>{'eleven_v4': 10, 'eleven_v4_turbo': 10});
      expect(plan.costBy(price), closeTo(10 / 1000 * 0.08 + 10 / 1000 * 0.04, 1e-12));
      final String text = plan.describe(0.04, priceOf: price);
      expect(text, contains('nitzi (eleven_v4, mp3_44100_64)'));
      expect(text, contains('hero-son (eleven_v4_turbo, mp3_44100_64)'));
      expect(text, contains('eleven_v4: 10 characters at 0.08 per 1,000 characters'));
      expect(text, contains('eleven_v4_turbo: 10 characters at 0.04 per 1,000 characters'));
      expect(text, contains('Estimated cost, all models: 0.00'));
      // One model: the line it always had.
      final VoicePlan one = planVoices(
        <String, VoiceProfile>{'nitzi': _v4},
        const <SpokenLine>[SpokenLine('vo:a.one', 'שלום')],
      );
      expect(one.describe(0.08, priceOf: price), contains('Estimated cost at 0.08 per 1,000 characters'));
    });
  });

  group('F4: the tools that make a clip from a clip', () {
    test('the ffmpeg arguments for a slow copy and a cut, and nothing outside their range', () {
      final List<String> slow = slowArguments('in.mp3', 'out.mp3', 0.8);
      expect(slow, containsAllInOrder(<String>['-i', 'in.mp3', '-filter:a', 'atempo=0.8']));
      expect(slow, containsAllInOrder(<String>['-b:a', '64k', '-ar', '44100']));
      expect(slow.last, 'out.mp3');
      final List<String> cut = cutArguments('in.mp3', 'out.mp3', 0.57, 1.16);
      expect(cut, containsAllInOrder(<String>['-i', 'in.mp3', '-ss', '0.570', '-to', '1.160']));
      expect(() => slowArguments('a', 'b', 1.5), throwsA(isA<VoiceGenFailed>()));
      expect(() => slowArguments('a', 'b', 0.2), throwsA(isA<VoiceGenFailed>()));
      expect(() => cutArguments('a', 'b', 1, 0.5), throwsA(isA<VoiceGenFailed>()));
      expect(() => cutArguments('a', 'b', -1, 0.5), throwsA(isA<VoiceGenFailed>()));
    });

    test('ffmpeg missing is said with how to install it, and a clip is not made without it', () async {
      const FfmpegTool tool = FfmpegTool('this-ffmpeg-is-not-installed-anywhere');
      expect(await tool.unavailableReason(), contains('winget install Gyan.FFmpeg'));
      await expectLater(tool.slow(Uint8List(4), 0.8), throwsA(isA<VoiceGenFailed>()));
    });

    test('the cues of a slow copy are later by the tempo, and still increase', () {
      expect(slowCues(<(int, int)>[(0, 1), (300, 0), (400, 1)], 0.8), <(int, int)>[
        (0, 1),
        (375, 0),
        (500, 1),
      ]);
      expect(slowCues(<(int, int)>[(0, 1), (1, 0)], 0.5), <(int, int)>[(0, 1), (2, 0)]);
      expect(slowCues(<(int, int)>[(0, 1), (1, 0), (2, 1)], 1.0).map(((int, int) c) => c.$1), <int>[0, 1, 2]);
    });

    test(
      'the mouth opens for the vowel letters of English and Russian, and a Hebrew word is read as before',
      () {
        Alignment word(String text) => Alignment(
          text.split(''),
          <double>[for (int i = 0; i < text.length; i++) i * 0.1],
          <double>[for (int i = 0; i < text.length; i++) (i + 1) * 0.1],
        );
        // "cat": the a, from 0.1 to 0.2 s.
        expect(cuesFromAlignment(word('cat')), <(int, int)>[(100, 1), (200, 0)]);
        // "Ё": capital, and "ы" after a consonant; a stress mark is not a letter.
        expect(cuesFromAlignment(word('Ё')), <(int, int)>[(0, 1), (100, 0)]);
        expect(cuesFromAlignment(word('mы́')), <(int, int)>[(100, 1), (200, 0)]);
        expect(cuesFromAlignment(word('shh')), isEmpty);
        expect(cuesFromAlignment(word('שָׁלוֹם')), isNotEmpty);
      },
    );

    test('a word is found by its place among the space-separated characters', () {
      final List<String> chars = 'ab cd  e'.split('');
      expect(wordSpan(chars, 0), (first: 0, last: 1));
      expect(wordSpan(chars, 1), (first: 3, last: 4));
      expect(wordSpan(chars, 2), (first: 7, last: 7));
      expect(wordSpan(chars, 3), isNull);
    });
  });

  group('F4: reading the voice plan of a course', () {
    test('a course, its pack name and the voice ids are checked', () {
      expect(() => LangSource.fromJson(<String, Object?>{'course': 'fra'}), throwsA(isA<VoiceGenFailed>()));
      expect(
        () => LangSource.fromJson(<String, Object?>{..._planJson(), 'pack': 'lang-rus'}),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(
        () => LangSource.fromJson(
          _planJson(
            frame: <Map<String, Object?>>[
              <String, Object?>{'id': 'x', 'vo': 'vo:../x', 'voice': 'שלום.'},
            ],
          ),
        ),
        throwsA(isA<VoiceGenFailed>()),
      );
      expect(() => LangSource.fromJson('x'), throwsA(isA<VoiceGenFailed>()));
      final LangSource ok = LangSource.fromJson(
        _planJson(targets: <Map<String, Object?>>[_target('en-a', 'a')]),
      );
      expect(ok.language, 'en');
      expect(ok.targets.single.spoken, 'a');
      expect(LangSource.fromJson(_planJson(course: 'rus')).language, 'ru');
      expect(LangSource.fromJson(_planJson(course: 'heb')).language, 'he');
    });

    for (final String course in <String>['eng', 'rus', 'heb']) {
      test(
        'the real $course plan reads, plans without a voice or a key, and every cut word is found in its page',
        () {
          final LangSource source = LangSource.fromJson(
            jsonDecode(File('../content/languages/$course/voice-plan.json').readAsStringSync()),
          );
          final Directory work = _temp('nn_real_$course');
          addTearDown(() => _drop(work));
          final LangPlan plan = planLang(
            source,
            frameCharacter: 'nitzi',
            frameProfile: _v4,
            targetCharacter: 'lang',
            targetProfile: _english,
            workDir: work,
          );
          // Today the one open problem is the Russian {puppet} line (release plan section 3.6): it is named, nothing else is.
          expect(
            plan.problems.where((TextProblem p) => !p.why.contains('has a placeholder')),
            isEmpty,
            reason: '${plan.problems}',
          );
          expect(plan.derived.where((DerivedClip d) => !d.slow), hasLength(source.cuts.length));
          expect(plan.voices.clips, isNotEmpty);
          expect(plan.voiceIds.toSet(), hasLength(plan.voiceIds.length));
          expect(
            plan.voiceIds.length,
            source.frame.where((LangFrameLine f) => f.voice != null && f.voice!.isNotEmpty).length +
                source.targets.length +
                source.cuts.length,
          );
          if (course == 'eng') {
            expect(plan.derived.where((DerivedClip d) => d.slow), isNotEmpty);
            expect(plan.softened, greaterThan(0));
          }
        },
      );
    }
  });

  group('F4: planning a course', () {
    late Directory work;
    setUp(() => work = _temp('nn_lang_'));
    tearDown(() => _drop(work));

    LangPlan plan(Map<String, Object?> json, {bool share = true}) => planLang(
      LangSource.fromJson(json),
      frameCharacter: 'nitzi',
      frameProfile: _v4,
      targetCharacter: 'lang-en',
      targetProfile: _english,
      workDir: work,
      shareSameText: share,
    );

    test('"!" is sent as ".", the unspoken frame line is skipped, and a repeated text is voiced once', () {
      final LangPlan p = plan(
        _planJson(
          frame: <Map<String, Object?>>[
            _frame('he-a', 'הקשיבו.'),
            _frame('he-b', null),
            _frame('he-c', 'הקשיבו.'),
          ],
          targets: <Map<String, Object?>>[
            _target('en-hi', 'Hi!', say: 'Hi!'),
            _target('en-wow', 'Wow!'),
            _target('en-hi-again', 'Hi.'),
          ],
        ),
      );
      expect(p.softened, 2);
      expect(p.noVoice, <String>['vo:eng.he_b']);
      final Map<String, String> sent = <String, String>{
        for (final PlannedClip c in p.voices.clips) c.line.voId: c.request.text,
      };
      expect(sent['vo:eng.en_hi'], 'Hi.');
      expect(sent['vo:eng.en_wow'], 'Wow.');
      expect(
        p.voices.clips.firstWhere((PlannedClip c) => c.line.voId == 'vo:eng.en_hi').request.languageCode,
        'en',
      );
      expect(
        p.voices.clips.firstWhere((PlannedClip c) => c.line.voId == 'vo:eng.he_a').request.languageCode,
        'he',
      );
      expect(p.voices.shared, 2, reason: 'he-c copies he-a, and en-hi-again copies en-hi');
      expect(p.total, 'הקשיבו.'.length + 'Hi.'.length + 'Wow.'.length);
      expect(
        plan(
          _planJson(frame: <Map<String, Object?>>[_frame('he-a', 'הקשיבו.'), _frame('he-c', 'הקשיבו.')]),
          share: false,
        ).total,
        14,
      );
      expect(p.voices.problems, isEmpty);
    });

    test('a slow clip with the same text is made from the normal clip and costs nothing; one with its own text is voiced', () {
      final LangPlan p = plan(
        _planJson(
          targets: <Map<String, Object?>>[
            _target('en-cat', 'cat', say: 'cat.'),
            _target('en-cat-slow', 'cat', say: 'cat.'),
            _target('en-dog', 'dog', say: 'dog.'),
            _target('en-dog-slow', 'dog', say: 'dog, dog.'),
            _target('en-bird-slow', 'bird', say: 'bird.'),
          ],
        ),
      );
      expect(p.derived.map((DerivedClip d) => d.voId), <String>['vo:eng.en_cat_slow']);
      expect(p.derived.single.sourceVoId, 'vo:eng.en_cat');
      expect(p.slowToMake, 1);
      expect(p.total, 'cat.'.length + 'dog.'.length + 'dog, dog.'.length + 'bird.'.length);
      expect(p.warnings.single, contains('2 "-slow" clips have a text of their own'));
      expect(p.describe((String m) => 0.08), contains('slow copies at 0.8 times the speed 1'));
    });

    test('a placeholder is refused with the id of the clip, whatever the language', () {
      final LangPlan p = plan(
        _planJson(targets: <Map<String, Object?>>[_target('en-name', 'My name is {puppet}.')]),
      );
      final String text = p.describe((String m) => 0.08);
      expect(p.voices.problems.map((TextProblem t) => t.char), contains('{'));
      expect(text, contains('The check refuses'));
      expect(text, contains('vo:eng.en_name'));
      expect(text, contains('fill'));
      expect(text, isNot(contains('This run sends')));
    });

    test('a Latin letter in a Hebrew line, and a Hebrew letter in an English clip, are refused', () {
      final LangPlan p = plan(
        _planJson(
          frame: <Map<String, Object?>>[_frame('he-a', 'הקשיבו cat.')],
          targets: <Map<String, Object?>>[_target('en-a', 'שלום')],
        ),
      );
      expect(
        p.voices.problems.map((TextProblem t) => t.id),
        containsAll(<String>['vo:eng.he_a', 'vo:eng.en_a']),
      );
    });

    test('a frame line still marked needs-editor is noted, not blocked', () {
      final LangPlan p = plan(
        _planJson(frame: <Map<String, Object?>>[_frame('he-a', 'הקשיבו.', review: 'needs-editor')]),
      );
      expect(p.warnings.single, contains('1 Hebrew frame lines are still marked needs-editor'));
      expect(p.voices.problems, isEmpty);
    });

    group('cut words', () {
      Map<String, Object?> cutPlan({
        String page = 'עכשיו הארנב.',
        String text = 'הארנב.',
        String id = 'heb-a-p-w2',
        String from = 'heb-a-p',
      }) => _planJson(
        course: 'heb',
        targets: <Map<String, Object?>>[_target('heb-a-p', page)],
        cuts: <Map<String, Object?>>[
          <String, Object?>{'id': id, 'from': from, 'text': text, 'vo': 'vo:heb.${id.replaceAll('-', '_')}'},
        ],
      );

      LangPlan hebPlan(Map<String, Object?> json) => planLang(
        LangSource.fromJson(json),
        frameCharacter: 'nitzi',
        frameProfile: _v4,
        targetCharacter: 'nitzi',
        targetProfile: _v4,
        workDir: work,
      );

      test('a word that is in its page is planned from the page, at no cost', () {
        final LangPlan p = hebPlan(cutPlan());
        expect(p.problems, isEmpty);
        expect(p.derived.single.word, 1);
        expect(p.derived.single.sourceVoId, 'vo:eng.heb_a_p');
        expect(p.cutToMake, 1);
        expect(p.total, 'עכשיו הארנב.'.length);
        expect(p.voices.characters, <String>['nitzi'], reason: 'one voice for the frame and the words');
      });

      test(
        'a word that is not where its id says, a missing -w number, and a missing page all stop the run',
        () {
          expect(hebPlan(cutPlan(text: 'עכשיו')).problems.single.toString(), contains('does not read'));
          expect(hebPlan(cutPlan(id: 'heb-a-p-x')).problems.single.toString(), contains('no -w<number>'));
          expect(
            hebPlan(cutPlan(from: 'heb-a-q')).problems.single.toString(),
            contains('not a voiced target clip'),
          );
          expect(hebPlan(cutPlan(id: 'heb-a-p-w9')).problems.single.toString(), contains('does not read'));
        },
      );

      test('a page voiced as more words than it shows cannot give its words by time', () {
        final Map<String, Object?> json = cutPlan(page: 'עכשיו הארנב.');
        ((json['targetClips']! as List<Object?>).single! as Map<String, Object?>)['say'] =
            'עכשיו הארנב קופץ.';
        expect(hebPlan(json).problems.single.toString(), contains('would not line up'));
      });
    });
  });

  group('F4: generate-lang, gated, in one process', () {
    late FakeEleven server;
    late Directory work;
    late List<String> printed;
    late int synths;
    late _FakeAudio audio;
    setUp(() {
      server = FakeEleven();
      work = _temp('nn_genlang_');
      printed = <String>[];
      synths = 0;
      audio = _FakeAudio();
    });
    tearDown(() => _drop(work));

    final Map<String, Object?> json = _planJson(
      course: 'eng',
      frame: <Map<String, Object?>>[
        _frame('he-a', 'הקשיבו.'),
        _frame('he-b', 'הקשיבו.'),
        _frame('he-c', null),
      ],
      targets: <Map<String, Object?>>[
        _target('en-hi', 'Hi!', say: 'Hi!'),
        _target('en-hi-slow', 'Hi!', say: 'Hi!'),
        _target('en-page', 'one two three'),
      ],
      cuts: <Map<String, Object?>>[
        <String, Object?>{'id': 'en-page-w2', 'from': 'en-page', 'text': 'two', 'vo': 'vo:eng.en_page_w2'},
      ],
    );
    final int total = 'הקשיבו.'.length + 'Hi.'.length + 'one two three'.length;

    Future<BuiltPack> run(
      Keyboard keyboard, {
      VoiceProfile english = _english,
      Map<String, Object?>? plan,
      AudioTool? tool,
    }) => generateLangGated(
      source: LangSource.fromJson(plan ?? json),
      frameCharacter: 'nitzi',
      frameProfile: _v4,
      targetCharacter: 'lang-en',
      targetProfile: english,
      workDir: work,
      key: key,
      keyboard: keyboard,
      synth: () {
        synths++;
        return ElevenLabsSynthesizer(apiKey: 'k', client: server.client);
      },
      audio: tool ?? audio,
      write: printed.add,
      priceOf: (String m) => 0.08,
    );

    test('without a terminal nothing is planned, printed, sent or written', () async {
      await expectLater(run(FakeKeyboard(isTerminal: false)), throwsA(isA<VoiceGenFailed>()));
      expect(printed, isEmpty);
      expect(synths, 0);
      expect(server.requests, isEmpty);
      expect(work.existsSync() ? work.listSync() : <FileSystemEntity>[], isEmpty);
    });

    test(
      'prints the plan with the figure, then refuses a wrong number before the voice is asked for',
      () async {
        await expectLater(run(FakeKeyboard(typed: <String>['${total + 1}'])), throwsA(isA<VoiceGenFailed>()));
        expect(printed.first, contains('Characters of text in total: $total'));
        expect(printed.first, contains('This run sends the $total characters above'));
        expect(synths, 0);
        expect(server.requests, isEmpty);
        expect(audio.calls, isEmpty);
        expect(work.listSync(), isEmpty);
      },
    );

    test('with the right number it voices each distinct text once, makes the slow copy and the cut word, and builds the pack', () async {
      final BuiltPack built = await run(FakeKeyboard(typed: <String>['$total']));
      expect(synths, 1);
      expect(
        server.requests.length,
        3,
        reason: 'one Hebrew line, Hi., and the page: he-b copies he-a, the rest is made',
      );
      expect(server.bodies.map((Map<String, Object?> b) => b['text']), <Object?>[
        'הקשיבו.',
        'Hi.',
        'one two three',
      ]);
      expect(server.bodies.map((Map<String, Object?> b) => b['language_code']), <Object?>['he', 'en', 'en']);
      expect(audio.calls, <String>['slow 0.8', 'cut']);
      // "one two three": the word "two" is characters 4 to 6, at 0.1 s each.
      expect(audio.cuts.single.$1, closeTo(0.4 - cutPadBefore, 1e-9));
      expect(audio.cuts.single.$2, closeTo(0.7 + cutPadAfter, 1e-9));

      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      expect(pack.id, 'voice-lang-eng');
      final VoiceBank bank = VoiceBank.fromPack(pack);
      expect(bank.characterId, 'lang-eng');
      expect(bank.ids.toSet(), <String>{
        'vo:eng.he_a',
        'vo:eng.he_b',
        'vo:eng.en_hi',
        'vo:eng.en_hi_slow',
        'vo:eng.en_page',
        'vo:eng.en_page_w2',
      });
      expect(bank.clip('vo:eng.he_b')!.mp3, bank.clip('vo:eng.he_a')!.mp3);
      expect(utf8.decode(bank.clip('vo:eng.en_hi_slow')!.mp3), 'slow:mp3:Hi.');
      expect(utf8.decode(bank.clip('vo:eng.en_page_w2')!.mp3), 'cut:mp3:one two three');
      // The cue of the slow copy is the normal clip's, a fifth later; the word starts 30 ms into its clip.
      final List<(int, int)> normal = readCues(work, 'eng.en_hi');
      expect(
        readCues(work, 'eng.en_hi_slow').map(((int, int) c) => c.$1),
        normal.map(((int, int) c) => (c.$1 / 0.8).round()),
      );
      expect(readCues(work, 'eng.en_page_w2').first.$1, 230, reason: 'the o of two, 0.23 s into the cut');
      expect(pack.files.keys.where((String f) => f.startsWith('vo.')).length, 5, reason: 'he-b shares he-a');
    });

    test('a second run has nothing to pay for, nothing to type and nothing to make', () async {
      await run(FakeKeyboard(typed: <String>['$total']));
      final FakeKeyboard again = FakeKeyboard();
      final _FakeAudio idle = _FakeAudio();
      await run(again, tool: idle);
      expect(again.reads, 0);
      expect(idle.calls, isEmpty);
      expect(server.requests.length, 3);
      expect(synths, 1);
    });

    test('a page whose character times were lost is voiced again, because its words need them', () async {
      await run(FakeKeyboard(typed: <String>['$total']));
      Directory('${normalisedFolder(work)}.align').deleteSync(recursive: true);
      final LangPlan p = planLang(
        LangSource.fromJson(json),
        frameCharacter: 'nitzi',
        frameProfile: _v4,
        targetCharacter: 'lang-en',
        targetProfile: _english,
        workDir: work,
      );
      expect(p.total, 'one two three'.length);
    });

    test(
      'ffmpeg missing stops the run before the number is asked for, and before anything is sent',
      () async {
        final FakeKeyboard keyboard = FakeKeyboard(typed: <String>['$total']);
        await expectLater(
          run(keyboard, tool: _FakeAudio(problem: ffmpegMissing)),
          throwsA(
            isA<VoiceGenFailed>().having(
              (VoiceGenFailed e) => e.message,
              'message',
              contains('ffmpeg is not installed'),
            ),
          ),
        );
        expect(printed.first, contains('BLOCKED: ffmpeg is not installed'));
        expect(keyboard.reads, 0);
        expect(synths, 0);
        expect(server.requests, isEmpty);
      },
    );

    test('a course with no slow copy and no cut word does not need ffmpeg', () async {
      final Map<String, Object?> plain = _planJson(
        targets: <Map<String, Object?>>[_target('en-a', 'cat', say: 'cat.')],
      );
      final BuiltPack built = await run(
        FakeKeyboard(typed: <String>['4']),
        plan: plain,
        tool: _FakeAudio(problem: ffmpegMissing),
      );
      await verifyPack(built.bytes, publicKey: key.publicKey);
      expect(printed.first, isNot(contains('BLOCKED')));
    });

    test(
      'a refused text or a voice with no id stops the run with the plan printed and nothing sent',
      () async {
        final Map<String, Object?> bad = _planJson(
          targets: <Map<String, Object?>>[_target('en-a', 'I am {puppet}.')],
        );
        final FakeKeyboard keyboard = FakeKeyboard(typed: <String>['14']);
        await expectLater(run(keyboard, plan: bad), throwsA(isA<VoiceGenFailed>()));
        expect(keyboard.reads, 0);
        expect(server.requests, isEmpty);
        const VoiceProfile noId = VoiceProfile(
          voiceId: '',
          modelId: 'eleven_v4',
          outputFormat: 'mp3_44100_64',
          settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
        );
        await expectLater(
          run(FakeKeyboard(typed: <String>['$total']), english: noId),
          throwsA(
            isA<VoiceGenFailed>().having(
              (VoiceGenFailed e) => e.message,
              'message',
              contains('no voice id yet'),
            ),
          ),
        );
        expect(server.requests, isEmpty);
      },
    );

    test('the key is never written to the work folder, the character times or the pack', () async {
      final BuiltPack built = await run(FakeKeyboard(typed: <String>['$total']));
      expect(anyFileContains(work, 'k-secret'), isFalse);
      expect(utf8.decode(built.bytes, allowMalformed: true), isNot(contains('xi-api-key')));
    });
  });

  group('the paid language path in the source', () {
    final String lib = File('tool/lang_voice_lib.dart').readAsStringSync();
    final String audioLib = File('tool/audio_tool_lib.dart').readAsStringSync();
    final String cli = File('tool/voice_gen.dart').readAsStringSync();

    test('the voice is asked for only after the typed count, and the terminal is checked first', () {
      final String gated = lib.substring(lib.indexOf('Future<BuiltPack> generateLangGated('));
      expect(gated.indexOf('requireTerminal('), lessThan(gated.indexOf('write(plan.describe')));
      expect(gated.indexOf('requireTyped('), lessThan(gated.indexOf('synth()')));
      expect(
        gated.indexOf('requireTyped(keyboard, plan.total'),
        greaterThan(0),
        reason: 'the count is the plan total',
      );
      final String command = cli.substring(cli.indexOf('Future<void> _generateLang('));
      expect(command.indexOf('requireTerminal('), lessThan(command.indexOf('_langJob(')));
    });

    test('neither library reads the environment, a key or a host', () {
      for (final String source in <String>[lib, audioLib]) {
        expect(source, isNot(contains('Platform.environment')));
        expect(source, isNot(contains('apiKey')));
        expect(source, isNot(contains('elevenlabs.io')));
        expect(source, isNot(contains('xi-api-key')));
      }
      expect(cli, contains("'generate-lang'"));
      expect(cli, isNot(contains("_option(args, '--confirm-chars')")));
    });

    test('ffmpeg is started with an argument list and never through a shell', () {
      expect(audioLib, isNot(contains('runInShell')));
      expect(audioLib, contains('Process.run(executable'));
    });
  });
}
