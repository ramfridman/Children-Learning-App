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
          'hero-son': <String, Object?>{'voiceId': 'FixtureVoice0002', 'modelId': 'eleven_v4'},
          'lang-en-fixture': <String, Object?>{'candidate': true, 'voiceId': 'FixtureEnglish01'},
          'lang-ru-fixture': <String, Object?>{'candidate': true, 'voiceId': '', 'idStatus': 'OWNER-TO-FILL'},
          'lang-en-fixture-male': <String, Object?>{'candidate': true, 'voiceId': 'FixtureEnglish02'},
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
      'content/lines/ui.he.json',
      jsonEncode(<String, Object?>{
        'schema': 'ui-lines/v1',
        'masterSource': 'app/lib/strings/he.dart',
        'lands': <String, Object?>{'counting': 'גבעות', 'market': 'כפר'},
        'lines': <Object?>[
          <String, Object?>{'id': 'core.adventure.welcome', 'string': 'adventureWelcome', 'perLand': true},
          <String, Object?>{'id': 'core.home.bubble_empty', 'string': 'homeBubbleNoName'},
        ],
      }),
    );
    _put(
      repo,
      'docs/audio/voicing-groups.json',
      jsonEncode(<String, Object?>{
        'schema': 'voicing-groups/v1',
        'groups': <Object?>[
          <String, Object?>{
            'name': 'first',
            'ids': <Object?>['vo:f.1.prompt', 'vo:f.1.correct'],
            'chars': 8,
          },
          <String, Object?>{
            'name': 'greet',
            'ids': <Object?>['vo:core.greeting.hello'],
            'chars': 16,
          },
          <String, Object?>{
            'name': 'wait',
            'ids': <Object?>['vo:core.wait.fixture'],
            'chars': 4,
          },
        ],
      }),
    );
    _put(
      repo,
      'content/languages/eng/voice-plan.json',
      jsonEncode(<String, Object?>{
        'course': 'eng',
        'pack': 'lang-eng',
        'frameLines': <Object?>[
          <String, Object?>{'id': 'he-a', 'vo': 'vo:eng.he_a', 'voice': 'הקשיבו.', 'review': 'text-ready'},
          <String, Object?>{'id': 'he-b', 'vo': 'vo:eng.he_b', 'voice': null, 'review': 'text-ready'},
        ],
        'targetClips': <Object?>[
          <String, Object?>{'id': 'en-hi', 'vo': 'vo:eng.en_hi', 'shown': 'Hi!', 'say': 'Hi!'},
          <String, Object?>{'id': 'en-hi-slow', 'vo': 'vo:eng.en_hi_slow', 'shown': 'Hi!', 'say': 'Hi!'},
        ],
      }),
    );
    // The puppet's line of the course: the clip `en-hi` is the puppet's own.
    _put(
      repo,
      'content/languages/eng/pack/activity.eng.a01.i01.json',
      jsonEncode(<String, Object?>{
        'id': 'eng.a01.i01',
        'template': 'puppet_talk',
        'prompt': <String, Object?>{'vo': 'vo:eng.he_a', 'target': 'vo:eng.en_hi'},
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
        _row(
          'app/lib/strings/he.dart',
          'adventureWelcome',
          'בואו נצא אל {land}.',
          'בואו נצא אל {land}.',
          'owner-approved',
        ),
        _row('app/lib/strings/he.dart', 'homeBubbleNoName', 'מה בבקבוק?', 'מה בבקבוק?', 'text-ready'),
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
      // 'שלום.' 5 + 'כן.' 3 + 'שלום, בואו נשחק.' 16 + 'בואו נצא אל גבעות.' 18 + 'בואו נצא אל כפר.' 16.
      expect(
        text,
        contains(
          'nitzi (eleven_v4_turbo, mp3_44100_64): new 5, changed 0, unchanged 0; '
          'characters to send for this voice 58',
        ),
      );
      expect(text, contains('vo:core.adventure.welcome.counting'));
      expect(
        text,
        contains('vo:core.home.bubble_empty: app/lib/strings/he.dart › homeBubbleNoName is text-ready'),
      );
      expect(text, contains('--lines lessons leaves the shell'));
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

  test('audition-batch plan names a candidate voice with no id instead of crashing, shows the language, and puts '
      'a Russian spec in its own default folder', () async {
    final File spec = File('${tmp.path}${Platform.pathSeparator}pilot.json')
      ..writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schema': 'audition/v1',
          'title': 'Russian fixture',
          'defaults': <String, Object?>{
            'character': 'lang-ru-fixture',
            'language': 'ru',
            'model': 'eleven_v4',
            'settings': <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
          },
          'clips': <Object?>[
            <String, Object?>{'id': 'ru-1', 'text': 'мама.'},
            <String, Object?>{
              'id': 'ru-2',
              'text': '/mʲa/',
              'allow': <Object?>['ipa'],
            },
            <String, Object?>{'id': 'he-1', 'text': 'הקשיבו.', 'language': 'he', 'character': 'nitzi'},
          ],
        }),
      );
    final ProcessResult r = await run(<String>['audition-batch', 'plan', spec.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final String out = r.stdout as String;
    expect(out, contains('ru-1: lang-ru-fixture, language ru, eleven_v4'));
    expect(out, contains('he-1: nitzi, language he, eleven_v4'));
    expect(out, contains('VOICE ID MISSING'));
    expect(out, contains('VOICE IDS MISSING for 1 voices'));
    expect(out, contains('  lang-ru-fixture: 2 clips, 10 characters'));
    expect(out, contains('Characters by language: ru 10, he 7'));
    expect(out, contains('${Platform.pathSeparator}auditions${Platform.pathSeparator}ru-pilot'));
    expect(out, isNot(contains('run in a terminal')));
    expect(home.listSync(), isEmpty, reason: 'a plan writes nothing');
    final ProcessResult paid = await run(<String>['plan', '--characters', 'lang-ru-fixture']);
    expect(paid.exitCode, 1);
    expect(paid.stderr, contains('audition candidate only'));
  });

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
      <String>['generate', 'nitzi', '--lines', 'own', '--out', out],
      <String>['generate', 'nitzi', '--groups', 'first', '--budget', '10', '--out', out],
      <String>['generate-lang', 'eng', '--voice', 'lang-en-fixture', '--out', out],
      <String>['generate-lang', 'eng', '--voice', 'lang-en-fixture', '--confirm-chars', '9', '--out', out],
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
      <String>['generate-lang', 'eng', '--voice', 'lang-en-fixture', '--out', out],
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

  test(
    'plan --lines picks a set: own lines of a friend, the shell lines, or the lessons without them',
    () async {
      String line(String text, String voice) => const LineSplitter()
          .convert(text)
          .firstWhere((String l) => l.startsWith('  $voice (eleven_v4_turbo'));
      final ProcessResult own = await run(<String>['plan', '--characters', 'nitzi', '--lines', 'own']);
      expect(own.exitCode, 0, reason: '${own.stderr}');
      expect(
        line(own.stdout as String, 'nitzi'),
        contains('new 1, changed 0, unchanged 0; characters to send for this voice 16'),
      );
      final ProcessResult ui = await run(<String>['plan', '--characters', 'nitzi', '--lines', 'ui']);
      expect(
        line(ui.stdout as String, 'nitzi'),
        contains('new 2, changed 0, unchanged 0; characters to send for this voice 34'),
      );
      final ProcessResult lessons = await run(<String>[
        'plan',
        '--characters',
        'nitzi',
        '--lines',
        'lessons',
      ]);
      expect(
        line(lessons.stdout as String, 'nitzi'),
        contains('new 3, changed 0, unchanged 0; characters to send for this voice 24'),
      );
      expect(lessons.stdout, isNot(contains('--lines lessons leaves the shell')));
      final ProcessResult bad = await run(<String>['plan', '--lines', 'everything']);
      expect(bad.exitCode, 1);
      expect(bad.stderr, contains('is not a set of lines'));
    },
  );

  test('plan --as-if-approved counts the lines that wait, says so, and generate refuses the flag', () async {
    final ProcessResult r = await run(<String>['plan', '--characters', 'nitzi', '--as-if-approved']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final String text = r.stdout as String;
    expect(text, contains('AS IF every row were approved'));
    expect(text, contains('nitzi (eleven_v4_turbo, mp3_44100_64): new 7, changed 0, unchanged 0'));
    expect(text, isNot(contains('lines cannot be voiced yet')));
  });

  test(
    'a voice with its own model shows its model, and the plan shows the characters and price of each model',
    () async {
      final ProcessResult r = await run(<String>['plan', '--characters', 'nitzi,hero-son', '--lines', 'own']);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final String text = r.stdout as String;
      expect(text, contains('nitzi (eleven_v4_turbo, mp3_44100_64): new 1'));
      expect(text, contains('hero-son (eleven_v4, mp3_44100_64): new 1'));
      expect(text, contains('eleven_v4_turbo: 16 characters at 0.04 per 1,000 characters'));
      expect(text, contains('eleven_v4: 16 characters at 0.08 per 1,000 characters'));
      expect(text, contains('Estimated cost, all models: 0.00'));
    },
  );

  test('plan-lang is free: the course, the voices, "!" sent as ".", the slow copy that is not voiced, and ffmpeg missing', () async {
    final String out = '${tmp.path}${Platform.pathSeparator}lang-out';
    final ProcessResult r = await run(<String>[
      'plan-lang',
      'eng',
      '--voice',
      'lang-en-fixture',
      '--ffmpeg',
      '${tmp.path}${Platform.pathSeparator}no-such-ffmpeg',
      '--out',
      out,
      '--list',
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final String text = r.stdout as String;
    expect(text.toLowerCase(), startsWith('repository: ${repo.path.toLowerCase()}'));
    expect(text, contains('Hebrew frame lines are voiced by nitzi, the clips in en by lang-en-fixture'));
    expect(text, contains('Frame lines with no voice text, not voiced: 1'));
    expect(text, contains('Target clips sent with "." for their "!": 2'));
    expect(text, contains('slow copies at 0.8 times the speed 1'));
    expect(text, contains('[new] lang-en-fixture vo:eng.en_hi (3)'));
    expect(text, isNot(contains('vo:eng.en_hi_slow (')));
    expect(text, contains('Characters of text in total: 10'));
    expect(text, contains('BLOCKED: ffmpeg is not installed'));
    expect(Directory(out).existsSync(), isFalse);
    expect(File('$out.voiced.jsonl').existsSync(), isFalse);
    expect(home.listSync(), isEmpty);
  });

  test(
    'plan-lang with --puppet-voice gives the puppet its own lines and shows each voice, and stays free',
    () async {
      final String out = '${tmp.path}${Platform.pathSeparator}lang-puppet-out';
      final ProcessResult r = await run(<String>[
        'plan-lang',
        'eng',
        '--voice',
        'lang-en-fixture',
        '--puppet-voice',
        'lang-en-fixture-male',
        '--ffmpeg',
        '${tmp.path}${Platform.pathSeparator}no-such-ffmpeg',
        '--out',
        out,
        '--list',
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final String text = r.stdout as String;
      expect(text, contains("The puppet's own lines (1 clips) are voiced by lang-en-fixture-male"));
      expect(text, contains('lang-en-fixture-male (eleven_v4_turbo, mp3_44100_64): new 1'));
      expect(text, contains('characters to send for this voice 3'));
      expect(text, contains('[new] lang-en-fixture-male vo:eng.en_hi (3)'));
      expect(text, isNot(contains('lang-en-fixture vo:eng.en_hi')));
      expect(text, contains('Characters of text in total: 10'));
      expect(Directory(out).existsSync(), isFalse);
      expect(home.listSync(), isEmpty);
    },
  );

  test('plan-lang refuses a puppet voice that is also the course voice', () async {
    final ProcessResult same = await run(<String>[
      'plan-lang',
      'eng',
      '--voice',
      'lang-en-fixture',
      '--puppet-voice',
      'lang-en-fixture',
    ]);
    expect(same.exitCode, 1);
    expect(same.stderr, contains('must be another voice'));
  });

  test('plan-lang needs a course and a voice', () async {
    final ProcessResult noVoice = await run(<String>['plan-lang', 'eng']);
    expect(noVoice.exitCode, 1);
    expect(noVoice.stderr, contains('--voice <name> is needed'));
    final ProcessResult noCourse = await run(<String>['plan-lang', 'fra', '--voice', 'lang-en-fixture']);
    expect(noCourse.exitCode, 1);
    expect(noCourse.stderr, contains('needs one course'));
  });

  test('plan --groups plans only those groups, and a line outside them does not block the run', () async {
    final ProcessResult r = await run(<String>['plan', '--characters', 'nitzi', '--groups', 'first']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final String text = r.stdout as String;
    expect(text, contains('Groups in this run (1): first; 8 characters'));
    expect(
      text,
      contains(
        'nitzi (eleven_v4_turbo, mp3_44100_64): new 2, changed 0, unchanged 0; characters to send for this voice 8',
      ),
    );
    expect(
      text,
      isNot(contains('lines cannot be voiced yet')),
      reason: 'core.wait.fixture is outside the groups',
    );
    expect(text, isNot(contains('--confirm-chars')));
  });

  test('plan --budget takes the groups in order and stops before the first that does not fit, and says what waits', () async {
    final ProcessResult r = await run(<String>['plan', '--characters', 'nitzi', '--budget', '10']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final String text = r.stdout as String;
    expect(text, contains('Groups in this run (1): first; 8 characters (limit 10)'));
    expect(
      text,
      contains('Left for next time (1 groups, 16 characters; whole groups, none is split): greet 16'),
    );
    expect(text, contains('Waiting for the owner to approve their rows (not counted above): wait, ui'));
    final ProcessResult alias = await run(<String>[
      'plan',
      '--characters',
      'nitzi',
      '--max-characters',
      '10',
    ]);
    expect(alias.stdout, contains('(limit 10)'));
    final ProcessResult wide = await run(<String>['plan', '--characters', 'nitzi', '--budget', '30']);
    expect(wide.stdout, contains('Groups in this run (2): first, greet; 24 characters'));
  });

  test('a group that is not in the manifest and a budget that is not a number are refused', () async {
    final ProcessResult bad = await run(<String>['plan', '--groups', 'nope']);
    expect(bad.exitCode, 1);
    expect(bad.stderr, contains('not a group: nope'));
    expect(bad.stderr, contains('first, greet, wait, ui'));
    final ProcessResult number = await run(<String>['plan', '--budget', 'many']);
    expect(number.exitCode, 1);
    expect(number.stderr, contains('--budget is a number'));
  });

  test('groups lists each group with its lines and the characters a run of it alone would send', () async {
    final ProcessResult r = await run(<String>['groups', '--characters', 'nitzi']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final String text = r.stdout as String;
    expect(text, contains('first'));
    expect(
      RegExp(r'first\s+2 lines, 0 waiting for approval, 8 characters to send').hasMatch(text),
      isTrue,
      reason: text,
    );
    expect(
      RegExp(r'wait\s+1 lines, 1 waiting for approval, 0 characters to send').hasMatch(text),
      isTrue,
      reason: text,
    );
    expect(
      RegExp(r'ui\s+3 lines, 1 waiting for approval, 34 characters to send').hasMatch(text),
      isTrue,
      reason: text,
    );
    expect(home.listSync(), isEmpty);
  });

  test('verify is free, finds clips that are not there, and exits with 1', () async {
    final String out = '${tmp.path}${Platform.pathSeparator}verify-out';
    final ProcessResult r = await run(<String>['verify', 'nitzi', '--groups', 'first,greet', '--out', out]);
    expect(r.exitCode, 1);
    final String text = r.stdout as String;
    expect(text, contains('first: 0 of 2 clips are as the text says; 2 are not'));
    expect(text, contains('vo:f.1.prompt: missing'));
    expect(text, contains('3 clips need attention.'));
    expect(Directory(out).existsSync(), isFalse);
    expect(home.listSync(), isEmpty);
  });

  test('verify-lang is free and says what is missing', () async {
    final ProcessResult r = await run(<String>[
      'verify-lang',
      'eng',
      '--voice',
      'lang-en-fixture',
      '--out',
      '${tmp.path}${Platform.pathSeparator}vl',
    ]);
    expect(r.exitCode, 1);
    expect(r.stdout, contains('clips are missing or were made from another text or setting'));
    expect(r.stdout, contains('vo:eng.en_hi'));
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
