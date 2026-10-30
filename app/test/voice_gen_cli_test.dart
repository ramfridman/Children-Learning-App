// The voice tool's command line, on its own fixture data (not today's master table), with no ElevenLabs key in the
// environment and no terminal: a `Process.run` child has no interactive stdin, like an agent's shell. The tool is
// compiled once and every case runs the compiled program, so the file adds one compile, not one per case.
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _sep(String path) => path.replaceAll('/', Platform.pathSeparator);

void _put(Directory root, String path, String text) => (File(
  '${root.path}${Platform.pathSeparator}${_sep(path)}',
)..createSync(recursive: true)).writeAsStringSync(text);

String _csv(List<List<String>> rows) =>
    rows.map((List<String> r) => r.map((String f) => f.contains(',') ? '"$f"' : f).join(',')).join('\n');

List<String> _row(String source, String id, String text, String voice, String status) => <String>[
  'g',
  source,
  id,
  'child (nikud)',
  'yes',
  text,
  text,
  voice,
  status,
];

void main() {
  late Directory tmp;
  late String exe;
  late Directory repo;
  late Directory home;
  late Map<String, String> env;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('nn_vg_cli_');
    exe = '${tmp.path}${Platform.pathSeparator}voice_gen.exe';
    final ProcessResult built = await Process.run('dart', <String>[
      'compile',
      'exe',
      'tool/voice_gen.dart',
      '-o',
      exe,
    ], runInShell: true);
    expect(built.exitCode, 0, reason: '${built.stdout}${built.stderr}');

    repo = Directory('${tmp.path}${Platform.pathSeparator}repo');
    _put(
      repo,
      'content/voices.json',
      jsonEncode(<String, Object?>{
        'schema': 'voices/v1',
        'modelId': 'eleven_v4_turbo',
        'outputFormat': 'mp3_44100_64',
        'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75, 'use_speaker_boost': true},
        'listPricePer1000Chars': <String, Object?>{'eleven_v4': 0.08, 'eleven_v4_turbo': 0.04},
        'voices': <String, Object?>{
          'nitzi': <String, Object?>{'voiceId': 'FixtureVoice0001'},
        },
      }),
    );
    _put(
      repo,
      'content/starter/activity.f.1.json',
      jsonEncode(<String, Object?>{
        'prompt': <String, Object?>{
          'vo': 'vo:f.1.prompt',
          'caption': <Object?>[
            <String, Object?>{'v': 'שָׁלוֹם!'},
          ],
        },
        'feedback': <String, Object?>{
          'correct': <String, Object?>{
            'vo': 'vo:f.1.correct',
            'caption': <Object?>[
              <String, Object?>{'v': 'כֵּן'},
            ],
          },
        },
      }),
    );
    _put(
      repo,
      'content/lines/core.he.json',
      jsonEncode(<String, Object?>{
        'lines': <Object?>[
          <String, Object?>{'id': 'core.greeting.hello', 'text': 'שָׁלוֹם! בּוֹאוּ נְשַׂחֵק.'},
          <String, Object?>{'id': 'core.wait.fixture', 'text': 'רֶגַע.'},
        ],
      }),
    );
    _put(
      repo,
      'docs/review/hebrew-master.csv',
      _csv(<List<String>>[
        <String>['group', 'source', 'id', 'kind', 'spoken', 'text', 'ui_text', 'voice_text', 'status'],
        _row('activity.f.1.json', 'prompt.caption.0.v', 'שָׁלוֹם!', 'שלום.', 'owner-approved'),
        _row('activity.f.1.json', 'feedback.correct.caption.0.v', 'כֵּן', 'כן.', 'voice-ready'),
        _row(
          'content/lines/core.he.json',
          'core.greeting.hello',
          'שָׁלוֹם! בּוֹאוּ נְשַׂחֵק.',
          'שלום, בואו נשחק.',
          'voiced',
        ),
        _row('content/lines/core.he.json', 'core.wait.fixture', 'רֶגַע.', 'רגע.', 'text-ready'),
      ]),
    );
    home = Directory('${tmp.path}${Platform.pathSeparator}home')..createSync();
    env = Map<String, String>.of(Platform.environment)
      ..remove('ELEVENLABS_API_KEY')
      ..['USERPROFILE'] = home.path;
  });

  tearDownAll(() {
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  });

  /// Runs the tool; with [fixture], on the fixture repository (only the free commands accept that).
  Future<ProcessResult> run(List<String> args, {bool fixture = true}) => Process.run(
    exe,
    <String>[
      ...args,
      if (fixture) ...<String>['--repo', repo.path],
    ],
    environment: env,
    includeParentEnvironment: false,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  test(
    'plan is free: it counts each voice, lists the lines that wait for the owner, and writes nothing',
    () async {
      final String out = '${tmp.path}${Platform.pathSeparator}plan-out';
      final ProcessResult r = await run(<String>['plan', '--out', out, '--list']);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final String text = r.stdout as String;
      expect(text.toLowerCase(), startsWith('repository: ${repo.path.toLowerCase()}'));
      // 'שלום.' 5 + 'כן.' 3 + 'שלום, בואו נשחק.' 16.
      expect(
        text,
        contains(
          'nitzi (eleven_v4_turbo, mp3_44100_64): new 3, changed 0, unchanged 0; '
          'characters to send for this voice 24',
        ),
      );
      expect(text, contains('[new] nitzi vo:f.1.prompt (5)'));
      expect(text, contains('vo:core.wait.fixture'));
      expect(text, contains('is text-ready'));
      expect(text, contains('Nothing is voiced until the owner marks these rows owner-approved'));
      expect(text, contains('the count of exactly what that run sends'));
      expect(text, isNot(contains('--confirm-chars')));
      expect(Directory(out).existsSync(), isFalse);
      expect(File('$out.voiced.jsonl').existsSync(), isFalse);
      expect(home.listSync(), isEmpty);
    },
  );

  test(
    'audition-batch plan is free: every clip, the characters by model and the total, nothing written',
    () async {
      final String out = '${tmp.path}${Platform.pathSeparator}aud-plan';
      final ProcessResult r = await run(<String>[
        'audition-batch',
        'plan',
        'tool/audition_example.json',
        '--out',
        out,
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      expect((r.stdout as String).toLowerCase(), startsWith('repository: ${repo.path.toLowerCase()}'));
      for (final String id in <String>['M1-turbo', 'M1-v4', 'M2-cheer', 'M3-voice-text']) {
        expect(r.stdout, contains('$id: nitzi, '));
      }
      expect(r.stdout, contains('text (voice_text of vo:core.greeting.hello): שלום, בואו נשחק.'));
      expect(r.stdout, contains('Characters of text in total: 57'));
      expect(r.stdout, isNot(contains('--confirm-chars')));
      expect(Directory(out).existsSync(), isFalse);
    },
  );

  test('every paid command refuses without a terminal, with or without --confirm-chars, before planning, reading '
      'the key or naming the count', () async {
    final String out = '${tmp.path}${Platform.pathSeparator}paid-out';
    for (final List<String> args in <List<String>>[
      <String>['audition', 'nitzi', 'שלום.', '--confirm-chars', '5', '--out', out],
      <String>['audition', 'nitzi', 'שלום.', '--out', out],
      <String>['audition-batch', 'run', 'tool/audition_example.json', '--out', out],
      <String>['audition-batch', 'run', 'tool/audition_example.json', '--confirm-chars', '57', '--out', out],
      <String>['generate', 'nitzi', '--out', out],
      <String>['generate', 'nitzi', '--confirm-chars', '24', '--out', out],
    ]) {
      // The default repository: a paid command takes no other.
      final ProcessResult r = await run(args, fixture: false);
      final String all = '${r.stdout}${r.stderr}';
      expect(r.exitCode, 1, reason: '$args');
      expect(r.stderr, contains('interactive terminal'), reason: '$args');
      expect(r.stderr, contains('Nothing was sent'), reason: '$args');
      expect(r.stdout, isEmpty, reason: 'no plan, so no count, is printed: $args');
      expect(all, isNot(contains('set the environment variable')), reason: 'the gate did not pass: $args');
      for (final String n in <String>['5', '24', '57']) {
        expect(all, isNot(contains('--confirm-chars $n')), reason: '$args');
      }
    }
    expect(Directory(out).existsSync(), isFalse);
    expect(File('$out.voiced.jsonl').existsSync(), isFalse);
    expect(home.listSync(), isEmpty);
  });

  test('a paid command refuses --repo outside the default repository, before the terminal check; the default '
      'itself passes on to that check', () async {
    final String out = '${tmp.path}${Platform.pathSeparator}repo-out';
    for (final List<String> args in <List<String>>[
      <String>['generate', 'nitzi', '--out', out],
      <String>['audition-batch', 'run', 'tool/audition_example.json', '--out', out],
      <String>['audition', 'nitzi', 'שלום.', '--out', out],
    ]) {
      final ProcessResult r = await run(args);
      expect(r.exitCode, 1, reason: '$args');
      expect(r.stderr, contains('--repo'), reason: '$args');
      expect(r.stderr, isNot(contains('interactive terminal')), reason: 'checked first: $args');
      expect(r.stdout, isEmpty, reason: '$args');
      final ProcessResult own = await run(<String>[...args, '--repo', '..'], fixture: false);
      expect(own.exitCode, 1, reason: '$args');
      expect(own.stderr, contains('interactive terminal'), reason: 'the default root is accepted: $args');
      expect(own.stdout, isEmpty, reason: '$args');
    }
    expect(Directory(out).existsSync(), isFalse);
  });

  test('mock refuses a folder that holds ElevenLabs clips, whatever the case of .mp3', () async {
    final Directory paid = Directory('${tmp.path}${Platform.pathSeparator}paid')..createSync();
    final File clip = File('${paid.path}${Platform.pathSeparator}vo.f.1.prompt.MP3')
      ..writeAsStringSync('paid');
    final ProcessResult r = await run(<String>['mock', 'nitzi', '--out', paid.path]);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('holds ElevenLabs clips'));
    expect(clip.readAsStringSync(), 'paid');
    expect(paid.listSync().length, 1);
  });
}
