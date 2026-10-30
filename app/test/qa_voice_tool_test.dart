// QA (2026-10-29): the defects found while verifying the voice-tool change (docs/qa/voice-tool-verification.md).
// Each test failed before its fix and proves it now (QA-22 to QA-27, QA-30). The round-2 group is QA's own attack on the
// fixes (allowlist, allowances, key).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../tool/voice_gen_lib.dart';

const List<String> _head = <String>[
  'group',
  'source',
  'id',
  'kind',
  'spoken',
  'text',
  'ui_text',
  'voice_text',
  'status',
];

String _master(List<List<String>> rows) =>
    <List<String>>[_head, ...rows].map((List<String> r) => r.join(',')).join('\n');

List<String> _row(String id, String voice, String status) => <String>[
  'g',
  'activity.q.1.json',
  id,
  'child (nikud)',
  'yes',
  'שָׁלוֹם',
  'שָׁלוֹם',
  voice,
  status,
];

void main() {
  late Directory dir;
  late Directory content;
  late File core;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('nn_qa_vt_');
    content = Directory('${dir.path}${Platform.pathSeparator}starter')..createSync();
    File('${content.path}${Platform.pathSeparator}activity.q.1.json').writeAsStringSync(
      jsonEncode(<String, Object?>{
        'prompt': <String, Object?>{
          'vo': 'vo:q.prompt',
          'caption': <Object?>[
            <String, Object?>{'v': 'שָׁלוֹם'},
          ],
        },
      }),
    );
    core = File('${dir.path}${Platform.pathSeparator}core.he.json')
      ..writeAsStringSync(jsonEncode(<String, Object?>{'lines': <Object?>[]}));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  VoiceTexts texts(List<List<String>> rows) =>
      voiceTextsOf(content: content, core: core, master: readMaster(_master(rows)));

  test('QA-22: only rows the owner approved are voiced (README › statuses, M9.md, B-18): owner-approved, voice-ready and '
      'voiced pass; text-ready waits for the owner', () {
    for (final String status in <String>['owner-approved', 'voice-ready', 'voiced']) {
      expect(
        texts(<List<String>>[_row('prompt.caption.0.v', 'שלום.', status)]).blocked,
        isEmpty,
        reason: status,
      );
    }
    expect(
      texts(<List<String>>[_row('prompt.caption.0.v', 'שלום.', 'text-ready')]).blocked.single.voId,
      'vo:q.prompt',
      reason: 'text-ready is "waiting for the owner"',
    );
  });

  test('QA-27: two rows with the same source and id are refused, not decided by their order in the file', () {
    final VoiceTexts t = texts(<List<String>>[
      _row('prompt.caption.0.v', 'שלום חדש.', 'proposed'),
      _row('prompt.caption.0.v', 'שלום.', 'voice-ready'),
    ]);
    expect(t.ready, isEmpty, reason: 'a proposed duplicate must not be hidden by a later approved one');
  });

  test('QA-23: the pre-flight check refuses what it means to refuse in any Unicode form', () {
    String u(int code) => String.fromCharCode(code);
    final Map<String, String> cases = <String, String>{
      'fullwidth exclamation U+FF01': 'כל הכבוד${u(0xFF01)}',
      'double exclamation U+203C': 'כל הכבוד${u(0x203C)}',
      'small exclamation U+FE57': 'כל הכבוד${u(0xFE57)}',
      'heavy exclamation U+2757': 'כל הכבוד${u(0x2757)}',
      'inverted exclamation U+00A1': '${u(0x00A1)}כל הכבוד',
      'superscript two U+00B2': 'יש ${u(0x00B2)} פרפרים',
      'vulgar half U+00BD': 'יש ${u(0x00BD)}',
      'circled one U+2460': 'יש ${u(0x2460)}',
      'Greek capital nu and iota U+039D': 'שלום ${u(0x039D)}${u(0x03B9)}',
      'Cyrillic a U+0430': 'שלום ${u(0x0430)}',
      'zero-width space only U+200B': u(0x200B),
      'zero-width joiner U+200D': 'של${u(0x200D)}ום',
      'right-to-left mark U+200F': 'שלום${u(0x200F)}.',
      'bidi isolate U+2067': '${u(0x2067)}שלום${u(0x2069)}',
      'byte-order mark inside U+FEFF': 'של${u(0xFEFF)}ום',
      'fullwidth braces U+FF5B': '${u(0xFF5B)}ילד${u(0xFF5D)} הבקבוק הגיע.',
      'fullwidth angle brackets U+FF1C': '${u(0xFF1C)}בריק${u(0xFF1E)} שלום',
      'square brackets in a pack line': '[בעדינות] כמעט.',
    };
    final List<String> passed = <String>[
      for (final MapEntry<String, String> c in cases.entries)
        if (preflight('vo:x', c.value).isEmpty) c.key,
    ];
    expect(passed, isEmpty, reason: 'these reach the voice today');
  });

  test('QA-24: the IPA allowance lets only IPA through: digits, placeholders, markup and "!" inside slashes are refused', () {
    final Set<Allowance> all = Allowance.values.toSet();
    for (final String t in <String>['יש /12/ פרפרים', '/{child}/ שלום', 'שלום /<x>/', 'שלום /!/']) {
      expect(preflight('L6i', t, allow: all), isNotEmpty, reason: t);
    }
  });

  test('QA-26: a NaN setting is refused like any value out of range', () {
    expect(
      () => settingsToSend('eleven_v4', <String, Object?>{'stability': double.nan, 'similarity_boost': 0.75}),
      throwsA(isA<VoiceGenFailed>()),
    );
  });

  test(
    'QA-25: a key with a line break or a non-ASCII character is refused by name, never echoed in an error',
    () async {
      // A mock client only (the host is fixed in the tool since SEC-18): nothing leaves the PC.
      int requests = 0;
      final http.Client client = MockClient((http.Request r) async {
        requests++;
        return http.Response('', 401);
      });
      const String key = 'sk_FAKE_QA_KEY_0123';
      try {
        for (final String bad in <String>['$key\r\n', '$key\n', '$key${String.fromCharCode(0xE9)}']) {
          Object? error;
          try {
            await ElevenLabsSynthesizer(apiKey: bad, client: client).say(
              const ClipRequest(
                text: 'שלום.',
                voiceId: 'QaVoice0123',
                modelId: 'eleven_v4',
                settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
                outputFormat: 'mp3_44100_64',
              ),
            );
          } catch (e) {
            error = e;
          }
          expect(
            error,
            isA<VoiceGenFailed>(),
            reason: 'main() prints anything else as an unhandled exception',
          );
          expect('$error', isNot(contains(key)));
        }
        expect(requests, 0, reason: 'refused before any request');
      } finally {
        client.close();
      }
    },
  );

  group('round 2 (2026-10-29): the allowlist, the allowances and the key, tried by QA', () {
    String u(int code) => String.fromCharCode(code);

    test(
      'the allowlist refuses look-alikes, digits, presentation forms, cantillation, spaces, marks and emoji',
      () {
        final Map<String, String> cases = <String, String>{
          'fullwidth colon U+FF1A': 'שלום${u(0xFF1A)} כן',
          'fullwidth full stop U+FF0E': 'שלום${u(0xFF0E)}',
          'fullwidth comma U+FF0C': 'שלום${u(0xFF0C)} כן',
          'fullwidth digit three U+FF13': 'יש ${u(0xFF13)}',
          'Arabic-Indic digit U+0663': 'יש ${u(0x0663)}',
          'negative circled one U+2776': 'יש ${u(0x2776)}',
          'circled twenty-one U+3251': 'יש ${u(0x3251)}',
          'digit comma one U+1F102': 'יש ${u(0x1F102)}',
          'yod with hiriq U+FB1D': 'שלום ${u(0xFB1D)}',
          'shin with shin dot U+FB2A': '${u(0xFB2A)}לום',
          'alternative plus sign U+FB29': 'שתיים ${u(0xFB29)} שלוש',
          'alef lamed ligature U+FB4F': 'שלום ${u(0xFB4F)}',
          'Yiddish double vav U+05F0': 'שלום ${u(0x05F0)}',
          'etnahta U+0591': 'של${u(0x0591)}ום',
          'merkha U+05A5': 'של${u(0x05A5)}ום',
          'meteg U+05BD': 'של${u(0x05BD)}ום',
          'rafe U+05BF': 'של${u(0x05BF)}ום',
          'upper dot U+05C4': 'של${u(0x05C4)}ום',
          'paseq U+05C0': 'שלום ${u(0x05C0)} כן',
          'sof pasuq U+05C3': 'שלום${u(0x05C3)}',
          'nun hafukha U+05C6': 'שלום ${u(0x05C6)}',
          'no-break space U+00A0': 'שלום${u(0x00A0)}כן',
          'narrow no-break space U+202F': 'שלום${u(0x202F)}כן',
          'thin space U+2009': 'שלום${u(0x2009)}כן',
          'ideographic space U+3000': 'שלום${u(0x3000)}כן',
          'tab': 'שלום\tכן',
          'carriage return': 'שלום\rכן',
          'line feed (no allowance)': 'שלום\nכן',
          'left-to-right mark U+200E': 'שלום${u(0x200E)}.',
          'Arabic letter mark U+061C': 'שלום${u(0x061C)}.',
          'right-to-left embedding U+202B': '${u(0x202B)}שלום',
          'right-to-left override U+202E': '${u(0x202E)}שלום',
          'soft hyphen U+00AD': 'של${u(0x00AD)}ום',
          'combining acute on a Hebrew letter U+0301': 'ש${u(0x0301)}לום',
          'combining grapheme joiner U+034F': 'של${u(0x034F)}ום',
          'variation selector 16 U+FE0F': 'שלום${u(0xFE0F)}',
          'Latin e with combining acute': 'שלום e${u(0x0301)}',
          'grinning face U+1F600': 'שלום ${String.fromCharCodes(<int>[0x1F600])}',
          'heavy black heart U+2764': 'שלום ${u(0x2764)}',
          'thumbs up with skin tone': 'שלום ${String.fromCharCodes(<int>[0x1F44D, 0x1F3FD])}',
          'keycap one': 'שלום 1${u(0xFE0F)}${u(0x20E3)}',
          'family ZWJ sequence': 'שלום ${String.fromCharCodes(<int>[0x1F468, 0x200D, 0x1F467])}',
          'Arabic letter beh U+0628': 'שלום ${u(0x0628)}',
          'Arabic comma U+060C': 'שלום${u(0x060C)} כן',
          'Samaritan letter alaf U+0800': 'שלום ${u(0x0800)}',
          'lone surrogate U+D800': 'שלום ${u(0xD800)}',
          'parentheses': 'שלום (כן)',
          'slash without the ipa allowance': 'כן/לא',
          'backslash': 'כן\\לא',
          'percent': 'מאה %',
          'plus sign': 'שתיים + שלוש',
          'equals sign': 'שתיים = שתיים',
          'division sign U+00F7': 'שש ${u(0x00F7)} שתיים',
          'multiplication sign U+00D7': 'שתיים ${u(0x00D7)} שלוש',
          'only punctuation': '...',
          'only points': '${u(0x05B8)}${u(0x05B7)}',
        };
        final List<String> passed = <String>[
          for (final MapEntry<String, String> c in cases.entries)
            if (preflight('vo:x', c.value).isEmpty) c.key,
        ];
        expect(passed, isEmpty, reason: 'these would reach the voice');
      },
    );

    test('an exclamation allowance passes the plain "!" only, never a look-alike', () {
      final Set<Allowance> ex = <Allowance>{Allowance.exclamation};
      expect(preflight('L4x', 'כל הכבוד!', allow: ex), isEmpty);
      for (final int r in <int>[0xFF01, 0x203C, 0xFE57, 0x2757, 0x00A1, 0x01C3, 0x2049, 0xFE15]) {
        expect(preflight('L4x', 'כל הכבוד${u(r)}', allow: ex), isNotEmpty, reason: r.toRadixString(16));
      }
    });

    test('the ipa allowance passes one IPA word between slashes and nothing else', () {
      final Set<Allowance> ipa = <Allowance>{Allowance.ipa};
      expect(preflight('L6i', 'שלוש ועוד שתיים /ʃaˈve/ חמש.', allow: ipa), isEmpty);
      for (final String t in <String>[
        'שווה /ʃa ve/', // a space inside
        'שווה /ʃa1/', // a digit inside
        'שווה /ʃ${u(0x01C3)}/', // a click letter
        'שווה /ʃa${u(0x0303)}/', // a combining mark
        'שווה /ʃaˈve', // not closed
        'שווה //', // empty
        'שווה /${'a' * 41}/', // too long
        'שווה /ʃaˈve/ /{x}/', // a second, bad slash pair
        '/ʃaˈve/', // nothing Hebrew to say
      ]) {
        expect(preflight('L6i', t, allow: ipa), isNotEmpty, reason: t);
      }
    });

    test('the audio-tags allowance passes the closed list only, and the line-breaks allowance a plain line feed only', () {
      final Set<Allowance> tags = <Allowance>{Allowance.audioTags};
      expect(preflight('R7', '[gently] כמעט, בואו ננסה שוב.', allow: tags), isEmpty);
      for (final String t in <String>[
        '[Gently] כמעט.',
        '[gently ] כמעט.',
        '[evil] כמעט.',
        '[gently כמעט.',
        '[gently]',
      ]) {
        expect(preflight('R7', t, allow: tags), isNotEmpty, reason: t);
      }
      final Set<Allowance> lines = <Allowance>{Allowance.lineBreaks};
      expect(preflight('L10', 'שורה אחת.\nשורה שתיים.', allow: lines), isEmpty);
      expect(preflight('L10', 'שורה אחת.\r\nשורה שתיים.', allow: lines), isNotEmpty, reason: 'CR');
      expect(
        preflight('L10', 'שורה אחת.${u(0x2028)}שורה שתיים.', allow: lines),
        isNotEmpty,
        reason: 'U+2028',
      );
    });

    test(
      'the key: 1 to 200 printable ASCII characters; anything else is refused by name and never shown',
      () {
        const String needle = 'sk_FAKE_round2_9';
        expect(() => checkApiKey('a' * 200), returnsNormally);
        for (final String bad in <String>[
          'a' * 201,
          '$needle${u(0xE9)}',
          '${u(0xFEFF)}$needle',
          '$needle${u(0x00)}',
          '$needle${u(0x7F)}',
          '',
          '   ',
          '$needle\r\n',
        ]) {
          expect(
            () => checkApiKey(bad),
            throwsA(
              isA<VoiceGenFailed>().having(
                (VoiceGenFailed e) => e.message,
                'message',
                allOf(contains('ELEVENLABS_API_KEY'), isNot(contains(needle)), isNot(contains('a' * 20))),
              ),
            ),
            reason: jsonEncode(bad),
          );
        }
      },
    );

    test('say() turns a client error that quotes the key into an error that names its kind only', () async {
      const String key = 'sk_FAKE_round2_quoted';
      final http.Client client = MockClient(
        (http.Request r) async =>
            throw FormatException('Invalid HTTP header field value: "${r.headers['xi-api-key']}"'),
      );
      Object? error;
      try {
        await ElevenLabsSynthesizer(apiKey: key, client: client).say(
          const ClipRequest(
            text: 'שלום.',
            voiceId: 'QaVoice0123',
            modelId: 'eleven_v4',
            settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
            outputFormat: 'mp3_44100_64',
          ),
        );
      } catch (e) {
        error = e;
      }
      expect(error, isA<VoiceGenFailed>());
      expect('$error', isNot(contains(key)));
    });
  });

  group('round 2: the work folder and its ledger (SEC-20)', () {
    late Directory parent;
    setUp(() => parent = Directory.systemTemp.createTempSync('nn_qa_ledger_'));
    tearDown(() => parent.deleteSync(recursive: true));

    test(r'nitzi, nitzi\, nitzi\\ and nitzi\. share one ledger beside the folder, never inside it', () {
      final String sep = Platform.pathSeparator;
      final String base = '${parent.path}${sep}nitzi';
      final String expected = '${normalisedFolder(Directory(base))}.voiced.jsonl';
      for (final String spelled in <String>[base, '$base$sep', '$base$sep$sep', '$base$sep.']) {
        final Directory work = Directory(spelled);
        expect(ClipLedger(work).file.path, expected, reason: spelled);
        expect(isInsideFolder(ClipLedger(work).file, work), isFalse, reason: spelled);
      }
    });

    test('a work folder that ends in . or .. is refused', () {
      final String sep = Platform.pathSeparator;
      for (final String bad in <String>[
        '.',
        '..',
        '${parent.path}$sep.',
        '${parent.path}$sep..',
        '${parent.path}$sep..$sep',
      ]) {
        expect(() => checkWorkFolder(Directory(bad)), throwsA(isA<VoiceGenFailed>()), reason: bad);
      }
      expect(() => checkWorkFolder(Directory('${parent.path}${sep}nitzi')), returnsNormally);
    });
  });

  test(
    'QA-30: stdin from the NUL device is not an interactive terminal: a paid command prints no plan and no '
    'count, and refuses by name (Windows: Dart says hasTerminal for NUL, so the PowerShell tool and "< NUL" pass the '
    'first half of the gate before the fix)',
    () async {
      final ProcessResult r = await Process.run(
        'cmd',
        <String>[
          '/c',
          'dart run tool/voice_gen.dart audition-batch run tool/audition_example.json --out qa_never < NUL',
        ],
        environment: <String, String>{'ELEVENLABS_API_KEY': ''},
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      expect(r.exitCode, 1);
      expect(
        r.stdout as String,
        isNot(contains('Characters of text in total')),
        reason: 'the count is not shown',
      );
      expect(r.stderr as String, contains('interactive terminal'));
      expect(Directory('qa_never').existsSync(), isFalse);
    },
    skip: Platform.isWindows ? null : 'Windows only',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
