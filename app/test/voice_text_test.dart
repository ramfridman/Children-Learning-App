import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/voice_text_lib.dart';

/// One CSV field as the editor's tools write it: quoted when it holds a comma, a quote or a line break.
String _field(String s) =>
    s.contains(',') || s.contains('"') || s.contains('\n') ? '"${s.replaceAll('"', '""')}"' : s;

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

/// A master table with a byte-order mark, as Excel saves it.
String _master(List<List<String>> rows) =>
    '${String.fromCharCode(0xFEFF)}${<List<String>>[_head, ...rows].map((List<String> r) => r.map(_field).join(',')).join('\r\n')}\r\n';

List<String> _row(String source, String id, String text, String voice, String status, {String? ui}) =>
    <String>['3. Lesson content', source, id, 'child (nikud)', 'yes', text, ui ?? text, voice, status];

final String _qamatsQatan = String.fromCharCode(0x05C7);
final String _hatafQamats = String.fromCharCode(0x05B3);

void main() {
  group('the CSV reader', () {
    test(
      'reads quoted fields with commas, doubled quotes and line breaks, and skips the byte-order mark',
      () {
        final List<List<String>> rows = parseCsv(
          '${String.fromCharCode(0xFEFF)}a,b,c\r\n"x, y","say ""hi""","two\nlines"\n,,last\n',
        );
        expect(rows, <List<String>>[
          <String>['a', 'b', 'c'],
          <String>['x, y', 'say "hi"', 'two\nlines'],
          <String>['', '', 'last'],
        ]);
      },
    );

    test('the rows are found by source and id, with the columns the generator reads', () {
      final Map<String, MasterRow> m = readMaster(
        _master(<List<String>>[
          _row('activity.t.1.json', 'prompt.caption.0.v', 'שָׁלוֹם!', 'שלום, בואו נשחק.', 'owner-approved'),
        ]),
      );
      final MasterRow r = m[masterKey('activity.t.1.json', 'prompt.caption.0.v')]!;
      expect(r.voiceText, 'שלום, בואו נשחק.');
      expect(r.status, 'owner-approved');
      expect(() => readMaster('a,b\n1,2\n'), throwsA(isA<VoiceGenFailed>()));
    });
  });

  group('the words sent come from voice_text, never from the caption', () {
    late Directory dir;
    late Directory content;
    late File core;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('nn_vt_');
      content = Directory('${dir.path}${Platform.pathSeparator}starter')..createSync();
      void put(String name, Object doc) =>
          File('${content.path}${Platform.pathSeparator}$name').writeAsStringSync(jsonEncode(doc));
      put('activity.t.1.json', <String, Object?>{
        'prompt': <String, Object?>{
          'vo': 'vo:t.1.prompt',
          'caption': <Object?>[
            <String, Object?>{'v': 'פַּרְפָּרִים בָּאוּ!'},
          ],
        },
        'feedback': <String, Object?>{
          'incorrect': <Object?>[
            <String, Object?>{
              'vo': 'vo:fb.almost',
              'caption': <Object?>[
                <String, Object?>{'v': 'כִּמְעַט!'},
              ],
            },
          ],
        },
      });
      put('activity.t.2.json', <String, Object?>{
        'feedback': <String, Object?>{
          'incorrect': <Object?>[
            <String, Object?>{
              'vo': 'vo:fb.almost',
              'caption': <Object?>[
                <String, Object?>{'v': 'כִּמְעַט!'},
              ],
            },
          ],
        },
        'hints': <Object?>[
          <String, Object?>{
            'vo': 'vo:t.2.h1',
            'caption': <Object?>[
              <String, Object?>{'v': 'נִסְפֹּר'},
            ],
          },
        ],
      });
      put('skill.x.json', <String, Object?>{
        'prompt': <String, Object?>{
          'vo': 'vo:not.a.line',
          'caption': <Object?>[
            <String, Object?>{'v': 'לא'},
          ],
        },
      });
      core = File('${dir.path}${Platform.pathSeparator}core.he.json')
        ..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'lines': <Object?>[
              <String, Object?>{'id': 'core.greeting.hello', 'text': 'שָׁלוֹם! בּוֹאוּ נְשַׂחֵק.'},
              <String, Object?>{'id': 'core.listen.mixed', 'text': 'אוֹפְּס!'},
            ],
          }),
        );
    });
    tearDown(() => dir.deleteSync(recursive: true));

    VoiceTexts texts(List<List<String>> rows) =>
        voiceTextsOf(content: content, core: core, master: readMaster(_master(rows)));

    List<List<String>> approved() => <List<String>>[
      _row(
        'activity.t.1.json',
        'prompt.caption.0.v',
        'פַּרְפָּרִים בָּאוּ!',
        'פרפרים באו.',
        'owner-approved',
      ),
      _row(
        'activity.t.1.json',
        'feedback.incorrect.0.caption.0.v',
        'כִּמְעַט!',
        'כמעט, בואו ננסה שוב.',
        'owner-approved',
      ),
      _row(
        'activity.t.2.json',
        'feedback.incorrect.0.caption.0.v',
        'כִּמְעַט!',
        'כמעט, בואו ננסה שוב.',
        'voice-ready',
      ),
      _row('activity.t.2.json', 'hints.0.caption.0.v', 'נִסְפֹּר', 'נספור', 'owner-approved'),
      _row(
        coreSource,
        'core.greeting.hello',
        'שָׁלוֹם! בּוֹאוּ נְשַׂחֵק.',
        'שלום, בואו נשחק.',
        'owner-approved',
      ),
      _row(coreSource, 'core.listen.mixed', 'אוֹפְּס!', 'אוֹפְּס, האוזניים שלי התבלבלו.', 'owner-approved'),
    ];

    test(
      'every approved line gets its voice_text, once per voice id, pack lines first and core lines last',
      () {
        final VoiceTexts t = texts(approved());
        expect(t.blocked, isEmpty);
        expect(
          <String, String>{for (final SpokenLine l in t.ready) l.voId: l.text},
          <String, String>{
            'vo:t.1.prompt': 'פרפרים באו.',
            'vo:fb.almost': 'כמעט, בואו ננסה שוב.',
            'vo:t.2.h1': 'נספור',
            'vo:core.greeting.hello': 'שלום, בואו נשחק.',
            'vo:core.listen.mixed': 'אוֹפְּס, האוזניים שלי התבלבלו.',
          },
        );
        expect(t.ready.map((SpokenLine l) => l.voId).toList(), <String>[
          'vo:t.1.prompt',
          'vo:fb.almost',
          'vo:t.2.h1',
          'vo:core.greeting.hello',
          'vo:core.listen.mixed',
        ]);
        expect(
          t.ready.map((SpokenLine l) => l.voId),
          isNot(contains('vo:not.a.line')),
          reason: 'skills ask no lines',
        );
      },
    );

    test('a proposed row is refused, and the refusal names the line and where it comes from', () {
      final List<List<String>> rows = approved();
      rows[5] = _row(coreSource, 'core.listen.mixed', 'אוֹפְּס!', 'אוֹפְּס, האוזניים התבלבלו.', 'proposed');
      final VoiceTexts t = texts(rows);
      expect(t.ready.map((SpokenLine l) => l.voId), isNot(contains('vo:core.listen.mixed')));
      expect(t.blocked.single.voId, 'vo:core.listen.mixed');
      expect(
        t.describeBlocked(),
        contains('vo:core.listen.mixed: content/lines/core.he.json › core.listen.mixed is proposed'),
      );
      expect(
        t.forTestVoices.map((SpokenLine l) => l.voId),
        contains('vo:core.listen.mixed'),
        reason: 'free tones only',
      );
    });

    test('a line shared by two activities waits when either of its rows is not approved', () {
      final List<List<String>> rows = approved();
      rows[2] = _row(
        'activity.t.2.json',
        'feedback.incorrect.0.caption.0.v',
        'כִּמְעַט!',
        'כמעט, בואו ננסה שוב.',
        '',
      );
      final VoicedLine l = texts(rows).blocked.single;
      expect(l.voId, 'vo:fb.almost');
      expect(l.problem, contains('activity.t.2.json › feedback.incorrect.0.caption.0.v is without a status'));
    });

    test(
      'no row, no voice_text, two different voice texts, or a caption changed since the table: all wait',
      () {
        final List<List<String>> rows = approved()
          ..removeAt(3) // vo:t.2.h1 has no row
          ..[0] = _row(
            'activity.t.1.json',
            'prompt.caption.0.v',
            'פַּרְפָּרִים בָּאוּ!',
            '',
            'owner-approved',
          )
          ..[2] = _row(
            'activity.t.2.json',
            'feedback.incorrect.0.caption.0.v',
            'כִּמְעַט!',
            'כמעט.',
            'owner-approved',
          )
          ..[3] = _row(coreSource, 'core.greeting.hello', 'שָׁלוֹם!', 'שלום.', 'owner-approved');
        final Map<String, String?> why = <String, String?>{
          for (final VoicedLine l in texts(rows).blocked) l.voId: l.problem,
        };
        expect(
          why['vo:t.2.h1'],
          contains('no row in the master table for activity.t.2.json › hints.0.caption.0.v'),
        );
        expect(why['vo:t.1.prompt'], contains('has no voice_text'));
        expect(why['vo:fb.almost'], contains('2 different voice texts'));
        expect(why['vo:core.greeting.hello'], contains('changed after the master table was made'));
      },
    );

    test('the editor\'s corrected screen text (ui_text) counts as the same caption', () {
      final List<List<String>> rows = approved();
      rows[3] = _row(
        'activity.t.2.json',
        'hints.0.caption.0.v',
        'נִסְפַּר',
        'נספור',
        'owner-approved',
        ui: 'נִסְפֹּר',
      );
      expect(texts(rows).blocked, isEmpty);
    });
  });

  group('only rows the owner approved are voiced', () {
    late Directory dir;
    late Directory content;
    late File core;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('nn_vt_st_');
      content = Directory('${dir.path}${Platform.pathSeparator}starter')..createSync();
      File('${content.path}${Platform.pathSeparator}activity.s.1.json').writeAsStringSync(
        jsonEncode(<String, Object?>{
          'prompt': <String, Object?>{
            'vo': 'vo:s.prompt',
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

    List<String> row(String voice, String status) =>
        _row('activity.s.1.json', 'prompt.caption.0.v', 'שָׁלוֹם', voice, status);

    test('owner-approved, voice-ready and voiced are voiced; text-ready waits for the owner', () {
      expect(voiceableStatuses, <String>{'owner-approved', 'voice-ready', 'voiced'});
      for (final String status in <String>['owner-approved', 'voice-ready', 'voiced']) {
        expect(texts(<List<String>>[row('שלום.', status)]).ready.single.text, 'שלום.', reason: status);
      }
      for (final String status in <String>['text-ready', 'proposed', 'unchanged', '']) {
        final VoiceTexts t = texts(<List<String>>[row('שלום.', status)]);
        expect(t.ready, isEmpty, reason: status);
        expect(t.describeBlocked(), contains('voiced only once the owner approved it'), reason: status);
      }
      expect(
        texts(<List<String>>[row('שלום.', 'text-ready')]).blocked.single.problem,
        contains('is text-ready'),
      );
    });

    test('a key that appears twice with a different voice_text or status waits, whatever the order', () {
      for (final List<List<String>> rows in <List<List<String>>>[
        <List<String>>[row('שלום חדש.', 'proposed'), row('שלום.', 'voice-ready')],
        <List<String>>[row('שלום.', 'voice-ready'), row('שלום חדש.', 'proposed')],
        <List<String>>[row('שלום.', 'owner-approved'), row('שלום.', 'voice-ready')],
        <List<String>>[row('שלום.', 'voice-ready'), row('שלום.', 'voice-ready'), row('אחר.', 'voice-ready')],
      ]) {
        final VoiceTexts t = texts(rows);
        expect(t.ready, isEmpty, reason: '$rows');
        expect(t.blocked.single.problem, contains('appears twice'), reason: '$rows');
      }
      expect(
        texts(<List<String>>[row('שלום.', 'voice-ready'), row('שלום.', 'voice-ready')]).ready.single.text,
        'שלום.',
        reason: 'the same row twice is harmless',
      );
    });

    test('a voice id that is not a plain name waits (it becomes a file name)', () {
      File('${content.path}${Platform.pathSeparator}activity.s.1.json').writeAsStringSync(
        jsonEncode(<String, Object?>{
          'prompt': <String, Object?>{
            'vo': 'vo:../evil',
            'caption': <Object?>[
              <String, Object?>{'v': 'שָׁלוֹם'},
            ],
          },
        }),
      );
      final VoiceTexts t = texts(<List<String>>[row('שלום.', 'owner-approved')]);
      expect(t.ready, isEmpty);
      expect(t.blocked.single.problem, contains('not a plain name'));
    });
  });

  group('the real master table and starter pack', () {
    final VoiceTexts real = voiceTextsOf(
      content: Directory('../content/starter'),
      core: File('../content/lines/core.he.json'),
      master: readMaster(File('../docs/review/hebrew-master.csv').readAsStringSync()),
    );

    test(
      'every line the pack asks for has a row and an unchanged caption; it is ready or waits on its status',
      () {
        expect(real.lines.length, greaterThan(2000));
        expect(real.ready.length + real.blocked.length, real.lines.length);
        for (final VoicedLine l in real.blocked) {
          expect(l.problem, isNot(contains('no row')), reason: l.voId);
          expect(l.problem, isNot(contains('changed after')), reason: l.voId);
          expect(l.problem, isNot(contains('appears twice')), reason: l.voId);
        }
        final Map<String, String> captions = <String, String>{
          for (final SpokenLine l in <SpokenLine>[
            ...linesOfContent(Directory('../content/starter')),
            ...coreLines(File('../content/lines/core.he.json')),
          ])
            l.voId: l.text,
        };
        expect(captions.keys.toSet(), real.lines.map((VoicedLine l) => l.voId).toSet());
        final List<SpokenLine> spoken = real.forTestVoices;
        final int differ = spoken.where((SpokenLine l) => l.text != captions[l.voId]).length;
        expect(
          differ,
          greaterThan(spoken.length ~/ 2),
          reason: 'the voice texts are the editor\'s spoken forms',
        );
      },
    );

    test('every voice text, approved or not yet, passes the pre-flight check', () {
      final List<TextProblem> problems = <TextProblem>[
        for (final SpokenLine l in real.forTestVoices) ...preflight(l.voId, l.text),
      ];
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });

  group('the pre-flight check', () {
    String u(int code) => String.fromCharCode(code);

    test('lets plain and partly pointed Hebrew through', () {
      expect(preflight('a', 'שלום, בואו נשחק.'), isEmpty);
      expect(preflight('b', 'אַחַת, שְׁתַּיִם… שָׁלוֹשׁ — עכשיו תורכם?'), isEmpty);
      expect(preflight('c', 'עוד לא – אבל כמעט; "כן".'), isEmpty);
    });

    test('refuses each forbidden character once, naming the line and the character', () {
      final Map<String, String> cases = <String, String>{
        'כל הכבוד!': '!',
        'יש 3 פרפרים': '3',
        'שלום Nitzi': 'N',
        '{child}, הבקבוק הגיע.': '{',
        '<break time="1s"/> שלום': '<',
        'כ$_qamatsQatanל הכבוד': _qamatsQatan,
        'צִפֳּרִים': _hatafQamats,
        'שלום (כן)': '(',
        'שלום\nעוד': '\n',
      };
      for (final MapEntry<String, String> c in cases.entries) {
        final List<TextProblem> p = preflight('vo:x', c.key);
        expect(p.map((TextProblem t) => t.char), contains(c.value), reason: c.key);
        expect(p.first.id, 'vo:x');
      }
      final List<TextProblem> many = preflight('vo:y', 'שלום!! 12 ab');
      expect(many.map((TextProblem t) => t.char).toList(), <String>['!', '1', '2', 'a', 'b']);
      expect(
        many.first.toString(),
        'vo:y: "!" (U+0021) an exclamation mark is never sent: it makes the voice shout',
      );
      expect(preflight('vo:z', 'כ$_qamatsQatanל').single.toString(), contains('(U+05C7) qamats qatan'));
      expect(preflight('vo:z', '{child}').map((TextProblem t) => t.why).first, contains('voiced per child'));
      expect(preflight('vo:e', '  ').single.why, 'the text is empty');
      expect(
        preflight('vo:i', 'של${u(0x200B)}ום').single.toString(),
        'vo:i: U+200B an invisible or control character is never sent',
      );
    });

    test('refuses every look-alike: other exclamation marks, number signs, other scripts, invisible characters, brackets', () {
      final Map<String, String> cases = <String, String>{
        'fullwidth exclamation': 'כל הכבוד${u(0xFF01)}',
        'double exclamation': 'כל הכבוד${u(0x203C)}',
        'small exclamation': 'כל הכבוד${u(0xFE57)}',
        'heavy exclamation': 'כל הכבוד${u(0x2757)}',
        'inverted exclamation': '${u(0x00A1)}כל הכבוד',
        'click letter U+01C3': 'כל הכבוד${u(0x01C3)}',
        'superscript two': 'יש ${u(0x00B2)} פרפרים',
        'vulgar half': 'יש ${u(0x00BD)}',
        'circled one': 'יש ${u(0x2460)}',
        'Arabic-Indic digit': 'יש ${u(0x0663)}',
        'Greek': 'שלום ${u(0x039D)}${u(0x03B9)}',
        'Cyrillic': 'שלום ${u(0x0430)}',
        'Hebrew presentation form': 'שלום ${u(0xFB2A)}',
        'zero-width joiner': 'של${u(0x200D)}ום',
        'right-to-left mark': 'שלום${u(0x200F)}.',
        'bidi isolate': '${u(0x2067)}שלום${u(0x2069)}',
        'byte-order mark': 'של${u(0xFEFF)}ום',
        'no-break space': 'שלום${u(0x00A0)}לכם',
        'fullwidth braces': '${u(0xFF5B)}ילד${u(0xFF5D)} הבקבוק הגיע.',
        'fullwidth angle brackets': '${u(0xFF1C)}בריק${u(0xFF1E)} שלום',
        'square brackets': '[בעדינות] כמעט.',
        'cantillation mark': 'של${u(0x0591)}ום',
      };
      final List<String> passed = <String>[
        for (final MapEntry<String, String> c in cases.entries)
          if (preflight('vo:x', c.value).isEmpty) c.key,
      ];
      expect(passed, isEmpty);
    });

    test(
      'a text with nothing to say is refused: only invisible characters, only a tag, only punctuation',
      () {
        final Set<Allowance> all = Allowance.values.toSet();
        for (final String t in <String>[
          u(0x200B),
          '${u(0x200B)}${u(0x200B)}',
          '[gently]',
          '… — .',
          '/ʃaˈve/',
        ]) {
          expect(
            preflight('x', t, allow: all).map((TextProblem p) => p.why),
            contains('there is nothing to say: the text has no Hebrew letter'),
            reason: t,
          );
        }
      },
    );

    test(
      'an audition clip may allow what it tests; digits, placeholders, markup and look-alikes never pass',
      () {
        expect(preflight('L4x', 'כל הכבוד!', allow: <Allowance>{Allowance.exclamation}), isEmpty);
        expect(
          preflight('L4x', 'כל הכבוד${u(0xFF01)}', allow: <Allowance>{Allowance.exclamation}),
          isNotEmpty,
          reason: 'only the plain sign',
        );
        expect(
          preflight(
            'L4p',
            'כ$_qamatsQatanל הַכָּבוֹד!',
            allow: <Allowance>{Allowance.exclamation, Allowance.rarePoints},
          ),
          isEmpty,
        );
        expect(preflight('L6i', 'שלוש ועוד שתיים /ʃaˈve/ חמש.', allow: <Allowance>{Allowance.ipa}), isEmpty);
        expect(preflight('L6i', 'שלוש ועוד שתיים /ʃaˈve/ חמש.'), isNotEmpty, reason: 'IPA only when allowed');
        expect(
          preflight('R2', '[gently] כמעט, בואו ננסה שוב.', allow: <Allowance>{Allowance.audioTags}),
          isEmpty,
        );
        expect(preflight('R2', '[warmly] שאלה טובה.', allow: <Allowance>{Allowance.audioTags}), isEmpty);
        expect(preflight('R2', '[gently] כמעט.'), isNotEmpty, reason: 'tags only when allowed');
        expect(
          preflight('R2', '[shout] כמעט.', allow: <Allowance>{Allowance.audioTags}),
          isNotEmpty,
          reason: 'only tags of the closed list',
        );
        expect(preflight('L10', 'שורה אחת.\nשורה שתיים.', allow: <Allowance>{Allowance.lineBreaks}), isEmpty);
        expect(
          preflight(
            'x',
            'שלום Nitzi /ʃaˈve/',
            allow: <Allowance>{Allowance.ipa},
          ).map((TextProblem p) => p.char),
          <String>['N', 'i', 't', 'z'],
          reason: 'Latin only inside /…/',
        );
        final Set<Allowance> all = Allowance.values.toSet();
        for (final MapEntry<String, String> c in <String, String>{
          'יש /12/ פרפרים': '1',
          '/{child}/ שלום': '{',
          'שלום /<x>/': '<',
          'שלום /!/': '/',
          'שלום /${u(0x01C3)}/': '/',
          'יש 3': '3',
          '{child} שלום': '{',
          '[gently${u(0x200B)}] שלום': '[',
        }.entries) {
          expect(
            preflight('x', c.key, allow: all).map((TextProblem p) => p.char),
            contains(c.value),
            reason: c.key,
          );
        }
        expect(Allowance.parse('rare-points'), Allowance.rarePoints);
        expect(Allowance.parse('line-breaks'), Allowance.lineBreaks);
        expect(() => Allowance.parse('digits'), throwsA(isA<VoiceGenFailed>()));
      },
    );
  });
}
