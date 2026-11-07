// F5, the validator's language checks (docs/languages/frame.md section 2.1 and the two-choice rule of section 2.3), each on a
// fixture pack: script purity per course, look-alike letters, Hebrew frame lines, decodable words, tagged distractors, accent
// tags, the limits on two-choice items and the catalogue of tags. Fixture courses, not content.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/scripts.dart';

import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

String _cp(int r) => String.fromCharCode(r);

/// The words of the three fixture courses: one right word and two others.
const Map<String, List<String>> _words = <String, List<String>>{
  'eng': <String>['cat', 'dog', 'sun', 'pig', 'cow'],
  'rus': <String>['кот', 'дом', 'сон', 'нос', 'лук'],
  'heb': <String>['כֶּלֶב', 'חָתוּל', 'שֶׁמֶשׁ', 'סוּס', 'דָּג'],
};

/// Adds a three-choice item of text tiles: the right word first, then two tagged distractors.
void _three(LangPack p, String id, {int at = 0, String? tag2, String? skill, String purpose = 'learn'}) {
  final List<String> w = _words[p.course]!;
  p.add(
    tapJson(
      course: p.course,
      id: id,
      skill: skill,
      purpose: purpose,
      band: 'A',
      options: <Map<String, Object?>>[
        textOption('o1', w[at], clip: 'vo:${p.course}.$id.a'),
        textOption('o2', w[(at + 1) % 5], tag: p.tag('lis.sem'), clip: 'vo:${p.course}.$id.b'),
        textOption('o3', w[(at + 2) % 5], tag: tag2 ?? p.tag('lis.guess'), clip: 'vo:${p.course}.$id.c'),
      ],
      correct: 'o1',
      target: 'vo:${p.course}.$id.word',
    ),
  );
}

/// Adds a two-choice item (one tagged distractor), optionally a [pole] and a [pair].
void _two(
  LangPack p,
  String id, {
  String purpose = 'learn',
  String? pole,
  String? pair,
  String? skill,
  int at = 0,
}) {
  final List<String> w = _words[p.course]!;
  p.add(
    tapJson(
      course: p.course,
      id: id,
      skill: skill,
      purpose: purpose,
      options: <Map<String, Object?>>[
        textOption('o1', w[at]),
        textOption('o2', w[(at + 1) % 5], tag: p.tag('lis.sem')),
      ],
      correct: 'o1',
      answer: <String, Object?>{'pole': ?pole, 'pairWith': ?pair},
    ),
  );
}

/// A valid pack of [course]: three items of three choices and one of two.
LangPack _valid([String course = 'eng']) {
  final LangPack p = LangPack(course);
  _three(p, 'words.i01');
  _three(p, 'words.i02', at: 1);
  _three(p, 'words.i03', at: 2);
  _two(p, 'words.i04');
  return p;
}

List<Object?> _options(LangPack p, String id) =>
    (p.activity(id)['answer']! as Map<String, Object?>)['options']! as List<Object?>;

Map<String, Object?> _option(LangPack p, String id, int i) => _options(p, id)[i]! as Map<String, Object?>;

String _file(LangPack p, String id) => 'activity.${p.course}.$id.json';

/// A problem at [path] that says [message].
Matcher _refused(String path, String message) => predicate<List<Problem>>(
  (List<Problem> ps) => ps.any((Problem x) => x.path == path && x.message.contains(message)),
  'refuses "$path": $message',
);

void _skill(LangPack p, String id, Map<String, Object?> fields) {
  p.pack.addDocument('skill.$id.json', 'skills', id, <String, Object?>{
    ...p.pack.doc('skill.${p.skill}.json'),
    'id': id,
    'prerequisites': <Object?>[],
    ...fields,
  });
}

void main() {
  group('the script helpers', () {
    test('a word reads with the graphemes in any way that works, digraphs included', () {
      expect(decodes('shop', <String>{'sh', 'o', 'p'}), isTrue);
      expect(decodes('shop', <String>{'s', 'o', 'p'}), isFalse, reason: 'h alone is not taught');
      expect(decodes('Shop', <String>{'sh', 'o', 'p'}), isTrue, reason: 'case makes no new letter');
      expect(decodes('', <String>{'a'}), isTrue);
      expect(decodes('ссс', <String>{'с'}), isTrue);
    });

    test('words are cut at spaces and punctuation, and a stress mark is not a letter', () {
      expect(wordsOf("it's a cat."), <String>['it', 's', 'a', 'cat']);
      expect(plainWord('Ма${_cp(0x301)}ма'), 'мама');
    });

    test('a Hebrew word of two letters or more without a point is found, a single letter is not', () {
      expect(unpointedHebrewWords('כלב'), <String>['כלב']);
      expect(unpointedHebrewWords('כֶּלֶב ב'), isEmpty);
      expect(unpointedHebrewWords('סוּס דג'), <String>['דג']);
    });
  });

  group('the fixture packs are valid, so every case below fails for its one reason', () {
    for (final String c in <String>['eng', 'rus', 'heb']) {
      test(c, () => expect(_run(_valid(c).pack), isEmpty));
    }

    test('a sound-only option, a picture with a revealed word and a word on show are valid', () {
      final LangPack p = _valid();
      p.add(
        tapJson(
          id: 'mix.i01',
          options: <Map<String, Object?>>[
            soundOption('o1', 'vo:eng.mix.a'),
            soundOption('o2', 'vo:eng.mix.b', tag: p.tag('lis.sem')),
            soundOption('o3', 'vo:eng.mix.c', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
          show: 'sun',
        ),
      );
      p.add(
        tapJson(
          id: 'mix.i02',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'flower_red', reveal: 'rose'),
            pictureOption('o2', 'flower_yellow', tag: p.tag('lis.sem')),
            pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      expect(_run(p.pack), isEmpty);
    });
  });

  group('script purity per course', () {
    final List<(String, String, String Function(LangPack), String)>
    cases = <(String, String, String Function(LangPack), String)>[
      (
        'eng',
        'a letter with an accent',
        (LangPack p) => 'caf${_cp(0xE9)}',
        'English is written with the letters a to z',
      ),
      ('eng', 'a Hebrew letter', (LangPack p) => 'ca${_cp(0x5D0)}', 'Hebrew letter'),
      ('eng', 'a digit', (LangPack p) => 'cat3', 'has the digit 3'),
      ('eng', 'a stress mark', (LangPack p) => 'ca${_cp(0x301)}t', 'only a Russian text may carry'),
      ('eng', 'a direction control', (LangPack p) => '${_cp(0x2067)}cat', 'direction control'),
      ('eng', 'a space at the end', (LangPack p) => 'cat ', 'a space at an end'),
      (
        'rus',
        'a Ukrainian letter',
        (LangPack p) => 'к${_cp(0x456)}т',
        'Russian is written with the Cyrillic letters',
      ),
      ('rus', 'a stress mark after a consonant', (LangPack p) => 'м${_cp(0x301)}ама', 'not after a vowel'),
      ('rus', 'a stress mark on ё', (LangPack p) => 'ё${_cp(0x301)}ж', 'always stressed already'),
      ('rus', 'a stress mark at the start', (LangPack p) => '${_cp(0x301)}ама', 'not after a vowel'),
      ('rus', 'ё taken apart', (LangPack p) => 'е${_cp(0x308)}ж', 'as one letter'),
      ('rus', 'a Hebrew letter', (LangPack p) => 'к${_cp(0x5D0)}т', 'Hebrew letter'),
      ('rus', 'a digit', (LangPack p) => 'кот2', 'has the digit 2'),
      ('heb', 'a Latin letter', (LangPack p) => 'כֶּלֶבa', 'Hebrew is written with Hebrew letters and nikud'),
      ('heb', 'a Cyrillic letter', (LangPack p) => 'כֶּלֶב${_cp(0x436)}', 'Cyrillic letter'),
    ];

    for (final (String course, String name, String Function(LangPack) text, String message) in cases) {
      test('$course: $name', () {
        final LangPack p = _valid(course);
        _option(p, 'words.i01', 0)['text'] = text(p);
        expect(_run(p.pack), _refused('${_file(p, 'words.i01')} › answer.options[0].text', message));
      });
    }

    test('a stress mark after a vowel is Russian and valid', () {
      final LangPack p = _valid('rus');
      _option(p, 'words.i01', 0)['text'] = 'ма${_cp(0x301)}ма';
      expect(_run(p.pack), isEmpty);
    });

    test('ё is a letter of the alphabet and valid', () {
      final LangPack p = _valid('rus');
      _option(p, 'words.i01', 0)['text'] = 'ёж';
      expect(_run(p.pack), isEmpty);
    });

    test('the punctuation of a sentence is valid', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 0)['text'] = "it's a cat.";
      expect(_run(p.pack), isEmpty);
    });

    test('Hebrew in Bands A and B is pointed, in Band C it need not be', () {
      final LangPack p = _valid('heb');
      _option(p, 'words.i01', 0)['text'] = 'כלב';
      expect(_run(p.pack), _refused('${_file(p, 'words.i01')} › answer.options[0].text', 'has no niqqud'));
      p.activity('words.i01')['band'] = 'C';
      expect(_run(p.pack).where((Problem x) => x.message.contains('niqqud')), isEmpty);
    });

    test('the graphemes and tricky words of a skill are held to the same script', () {
      final LangPack p = _valid();
      p.pack.doc('skill.ENG-A-02.json')['graphemes'] = <Object?>['a', 'я'];
      p.pack.doc('skill.ENG-A-02.json')['tricky'] = <Object?>['the', 'are${_cp(0xE9)}'];
      final List<Problem> ps = _run(p.pack);
      expect(ps, _refused('skill.ENG-A-02.json › graphemes[1]', 'Cyrillic'));
      expect(ps, _refused('skill.ENG-A-02.json › tricky[1]', 'a to z'));
    });
  });

  group('no look-alike letters from another script', () {
    test('a Cyrillic а in an English word names the Latin letter it looks like', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 0)['text'] = 'c${_cp(0x430)}t';
      expect(
        _run(p.pack),
        _refused(
          '${_file(p, 'words.i01')} › answer.options[0].text',
          'looks like the Latin "a": a text is all one script',
        ),
      );
    });

    test('a Latin o in a Russian word names the Cyrillic letter it looks like', () {
      final LangPack p = _valid('rus');
      _option(p, 'words.i01', 0)['text'] = 'к${_cp(0x6F)}т';
      expect(
        _run(p.pack),
        _refused(
          '${_file(p, 'words.i01')} › answer.options[0].text',
          'looks like the Cyrillic "о": a text is all one script',
        ),
      );
    });

    test('every look-alike pair is caught in both directions, capitals too', () {
      const List<(int, int)> pairs = <(int, int)>[
        (0x430, 0x61),
        (0x435, 0x65),
        (0x43E, 0x6F),
        (0x440, 0x70),
        (0x441, 0x63),
        (0x443, 0x79),
        (0x445, 0x78),
        (0x412, 0x42),
        (0x41A, 0x4B),
        (0x41C, 0x4D),
        (0x41D, 0x48),
        (0x422, 0x54),
      ];
      for (final (int cyr, int lat) in pairs) {
        final LangPack en = _valid();
        _option(en, 'words.i01', 0)['text'] = 'a${_cp(cyr)}';
        expect(
          _run(en.pack),
          _refused('${_file(en, 'words.i01')} › answer.options[0].text', 'looks like the Latin'),
        );
        final LangPack ru = _valid('rus');
        _option(ru, 'words.i01', 0)['text'] = 'к${_cp(lat)}';
        expect(
          _run(ru.pack),
          _refused('${_file(ru, 'words.i01')} › answer.options[0].text', 'looks like the Cyrillic'),
        );
      }
    });

    test('a word on show is checked too', () {
      final LangPack p = _valid();
      (p.activity('words.i01')['prompt']! as Map<String, Object?>)['show'] = 'c${_cp(0x430)}t';
      expect(_run(p.pack), _refused('${_file(p, 'words.i01')} › prompt.show', 'looks like the Latin "a"'));
    });
  });

  group('no Latin or Cyrillic inside a Hebrew frame line', () {
    test('a Cyrillic word in a Hebrew caption is refused, in a language pack and in the lands', () {
      final LangPack p = _valid();
      final Map<String, Object?> prompt = p.activity('words.i01')['prompt']! as Map<String, Object?>;
      ((prompt['caption']! as List<Object?>).single! as Map<String, Object?>)['v'] =
          'הַקְשִׁיבוּ לַמִּלָּה кот';
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i01')} › prompt.caption[0].v', 'contains Cyrillic letters'),
      );

      final SamplePack land = SamplePack();
      final Map<String, Object?> tap = land.doc(tapFile)['prompt']! as Map<String, Object?>;
      ((tap['caption']! as List<Object?>).single! as Map<String, Object?>)['v'] = 'סְפֹר кот';
      expect(_run(land), _refused('$tapFile › prompt.caption[0].v', 'contains Cyrillic letters'));
    });

    test('a Latin word in a Hebrew caption is refused, as it always was', () {
      final LangPack p = _valid();
      final Map<String, Object?> prompt = p.activity('words.i01')['prompt']! as Map<String, Object?>;
      ((prompt['caption']! as List<Object?>).single! as Map<String, Object?>)['v'] = 'הַקְשִׁיבוּ sun';
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i01')} › prompt.caption[0].v', 'contains Latin letters'),
      );
    });

    test('the word goes in `show`, and a word on show has nothing beside it', () {
      final LangPack p = _valid();
      (p.activity('words.i01')['prompt']! as Map<String, Object?>)['show'] = 'sun';
      expect(_run(p.pack), isEmpty);
      (p.activity('words.i01')['prompt']! as Map<String, Object?>)['show'] = 'sun?';
      expect(_run(p.pack), _refused('${_file(p, 'words.i01')} › prompt.show', 'stands alone in its chip'));
    });
  });

  group('decodable words', () {
    LangPack letters() {
      final LangPack p = LangPack();
      p.pack.doc('skill.ENG-A-01.json')['graphemes'] = <Object?>['a', 'm', 's', 'sh'];
      p.pack.doc('skill.ENG-A-01.json')['tricky'] = <Object?>['the'];
      p.pack.doc('skill.ENG-A-02.json')['letters'] = true;
      p.pack.doc('skill.ENG-A-02.json')['graphemes'] = <Object?>['t', 'o', 'p'];
      for (final (String, String) w in <(String, String)>[('i01', 'mat'), ('i02', 'sat'), ('i03', 'top')]) {
        p.add(
          tapJson(
            id: 'dec.${w.$1}',
            options: <Map<String, Object?>>[
              textOption('o1', w.$2),
              textOption('o2', 'am', tag: p.tag('lis.sem')),
              textOption('o3', 'mas', tag: p.tag('lis.guess')),
            ],
            correct: 'o1',
          ),
        );
      }
      return p;
    }

    test('words made of the taught graphemes, a digraph, and a tricky word are valid', () {
      final LangPack p = letters();
      _option(p, 'dec.i03', 1)['text'] = 'shop';
      _option(p, 'dec.i03', 2)['text'] = 'the';
      expect(_run(p.pack), isEmpty);
    });

    test('a letter nobody up to the skill teaches is refused and named', () {
      final LangPack p = letters();
      _option(p, 'dec.i01', 0)['text'] = 'cat';
      expect(
        _run(p.pack),
        _refused(
          '${_file(p, 'dec.i01')} › answer.options[0].text',
          'the word "cat" cannot be read yet at ENG-A-02: no skill up to it teaches c',
        ),
      );
    });

    test('a letter that a skill of its own band teaches later (not below this one) does not count', () {
      final LangPack p = letters();
      _skill(p, 'ENG-A-03', <String, Object?>{
        'graphemes': <Object?>['c'],
      });
      _option(p, 'dec.i01', 0)['text'] = 'cat';
      expect(_run(p.pack), _refused('${_file(p, 'dec.i01')} › answer.options[0].text', 'teaches c'));
    });

    test('letters taught in the order they are not all there for: "h" alone when only "sh" is taught', () {
      final LangPack p = letters();
      _option(p, 'dec.i01', 0)['text'] = 'ham';
      expect(_run(p.pack), _refused('${_file(p, 'dec.i01')} › answer.options[0].text', 'cannot be read yet'));
    });

    test('a word on show is held to it too', () {
      final LangPack p = letters();
      (p.activity('dec.i01')['prompt']! as Map<String, Object?>)['show'] = 'dog';
      expect(_run(p.pack), _refused('${_file(p, 'dec.i01')} › prompt.show', 'cannot be read yet'));
    });

    test('a skill that is not letter work may offer any word', () {
      final LangPack p = letters();
      p.pack.doc('skill.ENG-A-02.json')['letters'] = false;
      _option(p, 'dec.i01', 0)['text'] = 'cat';
      expect(_run(p.pack), isEmpty);
    });

    test('a letter skill that nothing teaches is refused', () {
      final LangPack p = letters();
      p.pack.doc('skill.ENG-A-01.json').remove('graphemes');
      p.pack.doc('skill.ENG-A-02.json').remove('graphemes');
      expect(_run(p.pack), _refused('skill.ENG-A-02.json › letters', 'no skill up to it teaches a grapheme'));
    });

    test('Russian: a stress mark and the case of a letter make no new letter', () {
      final LangPack p = LangPack('rus');
      p.pack.doc('skill.RUS-A-02.json')['letters'] = true;
      p.pack.doc('skill.RUS-A-02.json')['graphemes'] = <Object?>['м', 'а'];
      p.add(
        tapJson(
          course: 'rus',
          id: 'dec.i01',
          options: <Map<String, Object?>>[
            textOption('o1', 'Ма${_cp(0x301)}ма'),
            textOption('o2', 'ам', tag: p.tag('lis.sem')),
            textOption('o3', 'ма', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      expect(_run(p.pack), isEmpty);
      _option(p, 'dec.i01', 1)['text'] = 'мак';
      expect(_run(p.pack), _refused('${_file(p, 'dec.i01')} › answer.options[1].text', 'teaches к'));
    });
  });

  group('every distractor is tagged', () {
    test('a three-choice item with an untagged distractor', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 1).remove('misconception');
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i01')} › answer.options[1].misconception', 'every distractor is tagged'),
      );
    });

    test('a two-choice item with an untagged distractor', () {
      final LangPack p = _valid();
      _option(p, 'words.i04', 1).remove('misconception');
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i04')} › answer.options[1].misconception', 'every distractor is tagged'),
      );
    });

    test('a four-choice item: all three distractors, one message each', () {
      final LangPack p = _valid();
      p.add(
        tapJson(
          id: 'words.i05',
          options: <Map<String, Object?>>[
            textOption('o1', 'cat'),
            textOption('o2', 'dog'),
            textOption('o3', 'sun'),
            textOption('o4', 'pig', tag: p.tag('lis.sem')),
          ],
          correct: 'o1',
        ),
      );
      expect(
        _run(p.pack).where((Problem x) => x.message.contains('every distractor is tagged')),
        hasLength(2),
      );
    });

    test('two distractors may carry the same tag when one misconception explains both', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 2)['misconception'] = p.tag('lis.sem');
      expect(_run(p.pack), isEmpty);
    });

    test('a tag that is not in the catalogue of the pack, or of another course, is refused', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 1)['misconception'] = 'eng.lis.nothing';
      _option(p, 'words.i02', 1)['misconception'] = 'rus.lis.sem';
      final List<Problem> ps = _run(p.pack);
      expect(
        ps,
        _refused(
          '${_file(p, 'words.i01')} › answer.options[1].misconception',
          'not in the misconception catalogue',
        ),
      );
      expect(
        ps,
        _refused(
          '${_file(p, 'words.i02')} › answer.options[1].misconception',
          'not in the misconception catalogue',
        ),
      );
    });

    test('the right answer cannot carry a tag', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 0)['misconception'] = p.tag('lis.sem');
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i01')} › answer.options[0].misconception', 'cannot carry'),
      );
    });
  });

  group('no accent tag on a distractor', () {
    test('an accent tag on a distractor is refused', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 1)['misconception'] = p.tag('spk.accent');
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i01')} › answer.options[1].misconception', 'accent tag'),
      );
    });

    test('an on-the-way tag on a distractor is valid', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 1)['misconception'] = p.tag('lis.early');
      expect(_run(p.pack), isEmpty);
    });
  });

  group('the limits on two-choice items', () {
    test('a skill whose items all have two choices is refused unless it is binary', () {
      final LangPack p = LangPack();
      _two(p, 'two.i01');
      _two(p, 'two.i02', at: 1);
      expect(
        _run(p.pack),
        _refused('skill.ENG-A-02.json', 'has only items with two choices and is not binary'),
      );
    });

    test('a probe is not counted in the half: it is no evidence of mastery (band-a-build.md 7.7, D6)', () {
      final LangPack p = LangPack();
      _three(p, 'mix.i01');
      _three(p, 'mix.i02', at: 1);
      _two(p, 'mix.i03');
      _two(p, 'mix.i04', at: 1);
      _two(p, 'mix.p01', at: 2, purpose: 'probe');
      _two(p, 'mix.p02', at: 3, purpose: 'probe');
      expect(_run(p.pack), isEmpty, reason: 'two of four scored items, and two probes on top');
      _two(p, 'mix.i05', at: 2);
      expect(
        _run(p.pack),
        _refused('skill.ENG-A-02.json', '3 of its 5 scored items have two choices; at most half may'),
      );
    });

    test('exactly half is allowed; one more is refused', () {
      final LangPack p = LangPack();
      _three(p, 'mix.i01');
      _three(p, 'mix.i02', at: 1);
      _two(p, 'mix.i03');
      _two(p, 'mix.i04', at: 1);
      expect(_run(p.pack), isEmpty);
      _two(p, 'mix.i05', at: 2);
      expect(
        _run(p.pack),
        _refused('skill.ENG-A-02.json', '3 of its 5 scored items have two choices; at most half may'),
      );
    });

    test(
      'a binary skill needs its two-choice items balanced: as many yes as no, as many same as different',
      () {
        final LangPack p = LangPack();
        _skill(p, 'ENG-A-05', <String, Object?>{'binary': true});
        _three(p, 'yn.i01', skill: 'ENG-A-05');
        _three(p, 'yn.i02', skill: 'ENG-A-05', at: 1);
        _three(p, 'yn.i03', skill: 'ENG-A-05', at: 2);
        _three(p, 'yn.i10', skill: 'ENG-A-05', at: 3);
        _two(p, 'yn.i04', skill: 'ENG-A-05', pole: 'yes');
        _two(p, 'yn.i05', skill: 'ENG-A-05', pole: 'no', at: 1);
        _two(p, 'yn.i06', skill: 'ENG-A-05', pole: 'same', at: 2);
        _two(p, 'yn.i07', skill: 'ENG-A-05', pole: 'different', at: 3);
        expect(_run(p.pack), isEmpty);

        _two(p, 'yn.i08', skill: 'ENG-A-05', pole: 'yes', at: 4);
        _three(p, 'yn.i09', skill: 'ENG-A-05');
        expect(_run(p.pack), _refused('skill.ENG-A-05.json', '2 yes, 1 no'));
      },
    );

    test('a two-choice item of a binary skill says which side it is', () {
      final LangPack p = LangPack();
      _skill(p, 'ENG-A-05', <String, Object?>{'binary': true});
      _three(p, 'yn.i01', skill: 'ENG-A-05');
      _three(p, 'yn.i02', skill: 'ENG-A-05', at: 1);
      _two(p, 'yn.i03', skill: 'ENG-A-05');
      expect(_run(p.pack), _refused('${_file(p, 'yn.i03')} › answer.pole', 'says which side it is'));
    });
  });

  group('a check is never a lone two-choice item', () {
    test('a check with three choices is fine', () {
      final LangPack p = _valid();
      _three(p, 'chk.i01', purpose: 'check');
      expect(_run(p.pack), isEmpty);
    });

    test('a check with two choices in a skill that is not binary is refused', () {
      final LangPack p = _valid();
      _two(p, 'chk.i01', purpose: 'check');
      expect(_run(p.pack), _refused('${_file(p, 'chk.i01')} › purpose', 'balanced pair in a binary skill'));
    });

    test('a binary skill: the check with two choices is one of a balanced pair, naming each other', () {
      LangPack binary() {
        final LangPack p = LangPack();
        _skill(p, 'ENG-A-05', <String, Object?>{'binary': true});
        _three(p, 'yn.i01', skill: 'ENG-A-05');
        _three(p, 'yn.i02', skill: 'ENG-A-05', at: 1);
        _three(p, 'yn.i03', skill: 'ENG-A-05', at: 2);
        _three(p, 'yn.i04', skill: 'ENG-A-05', at: 3);
        _two(p, 'chk.a', skill: 'ENG-A-05', purpose: 'check', pole: 'yes', pair: 'eng.chk.b');
        _two(p, 'chk.b', skill: 'ENG-A-05', purpose: 'check', pole: 'no', pair: 'eng.chk.a', at: 1);
        return p;
      }

      expect(_run(binary().pack), isEmpty);

      final LangPack alone = binary();
      (alone.activity('chk.a')['answer']! as Map<String, Object?>).remove('pairWith');
      expect(_run(alone.pack), _refused('${_file(alone, 'chk.a')} › answer.pairWith', 'never alone'));

      final LangPack oneWay = binary();
      (oneWay.activity('chk.b')['answer']! as Map<String, Object?>)['pairWith'] = 'eng.words.i01';
      expect(
        _run(oneWay.pack),
        _refused('${_file(oneWay, 'chk.a')} › answer.pairWith', 'does not name this item back'),
      );

      final LangPack sameSide = binary();
      (sameSide.activity('chk.b')['answer']! as Map<String, Object?>)['pole'] = 'yes';
      expect(_run(sameSide.pack), _refused('${_file(sameSide, 'chk.a')} › answer.pole', 'two sides'));

      final LangPack missing = binary();
      (missing.activity('chk.a')['answer']! as Map<String, Object?>)['pairWith'] = 'eng.chk.zzz';
      expect(
        _run(missing.pack),
        _refused('${_file(missing, 'chk.a')} › answer.pairWith', 'there is no activity'),
      );

      final LangPack partnerNotCheck = binary();
      partnerNotCheck.activity('chk.b')['purpose'] = 'practice';
      expect(
        _run(partnerNotCheck.pack),
        _refused('${_file(partnerNotCheck, 'chk.a')} › answer.pairWith', 'must be a check'),
      );
    });

    test('a probe with two choices is not a check', () {
      final LangPack p = _valid();
      _two(p, 'prb.i01', purpose: 'probe');
      expect(_run(p.pack), isEmpty);
    });
  });

  group('every tag is defined once in its course\'s catalogue', () {
    test('a language tag with no kind', () {
      final LangPack p = _valid();
      p.pack.doc('misconception.eng.lis.sem.json').remove('kind');
      expect(_run(p.pack), _refused('misconception.eng.lis.sem.json › kind', 'needs a kind'));
    });

    test('an unknown kind is refused by the schema', () {
      final LangPack p = _valid();
      p.pack.doc('misconception.eng.lis.sem.json')['kind'] = 'maybe';
      expect(_run(p.pack), isNotEmpty);
    });

    test('the same slug under two strands is one tag defined twice', () {
      final LangPack p = _valid();
      p.addTag('rd.sem', 'diagnostic');
      expect(
        _run(p.pack),
        predicate<List<Problem>>(
          (List<Problem> ps) => ps.any(
            (Problem x) => x.message.contains('is the same tag as eng.') && x.message.contains('"sem"'),
          ),
          'a tag defined twice',
        ),
      );
    });

    test('a tag in the lands needs no kind', () {
      expect(_run(SamplePack()), isEmpty);
    });
  });

  group('the new fields belong to the language courses', () {
    test('a pack of the lands refuses text, clips, a revealed word, a second clip and a word on show', () {
      final SamplePack p = SamplePack();
      final Map<String, Object?> tap = p.doc(tapFile);
      final List<Object?> options = (tap['answer']! as Map<String, Object?>)['options']! as List<Object?>;
      (options[0]! as Map<String, Object?>)['reveal'] = 'red';
      (options[1]! as Map<String, Object?>)['clip'] = 'vo:fb.again';
      (tap['prompt']! as Map<String, Object?>)['show'] = 'red';
      (tap['prompt']! as Map<String, Object?>)['target'] = 'vo:fb.again';
      final List<Problem> ps = _run(p);
      expect(ps, _refused('$tapFile › answer.options[0].reveal', 'belongs to a language course'));
      expect(ps, _refused('$tapFile › answer.options[1].clip', 'belongs to a language course'));
      expect(ps, _refused('$tapFile › prompt.show', 'belongs to a language course'));
      expect(ps, _refused('$tapFile › prompt.target', 'belongs to a language course'));
    });

    test('a land\'s option with only a text is not an option', () {
      final SamplePack p = SamplePack();
      final List<Object?> options =
          (p.doc(tapFile)['answer']! as Map<String, Object?>)['options']! as List<Object?>;
      options[0] = <String, Object?>{'id': 'o1', 'text': 'red', 'label': 'red'};
      final List<Problem> ps = _run(p);
      expect(
        ps,
        _refused('$tapFile › answer.options[0]', 'must be exactly one of a sprite, a numeral or a set'),
      );
      expect(ps, _refused('$tapFile › answer.options[0].text', 'belongs to a language course'));
    });

    test('in a language course an option is one face, or only a sound, never two faces or none', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 0)['sprite'] = 'asset:flower_red';
      _option(p, 'words.i02', 0).remove('text');
      _option(p, 'words.i02', 0).remove('clip');
      _option(p, 'words.i03', 0)['reveal'] = 'cat';
      final List<Problem> ps = _run(p.pack);
      expect(ps, _refused('${_file(p, 'words.i01')} › answer.options[0]', 'only a clip (a sound button)'));
      expect(ps, _refused('${_file(p, 'words.i02')} › answer.options[0]', 'only a clip (a sound button)'));
      expect(ps, _refused('${_file(p, 'words.i03')} › answer.options[0].reveal', 'needs a sprite or a set'));
    });

    test('a clip or a second clip that the pack neither records nor lists is refused', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 0)['clip'] = 'vo:eng.nowhere.a';
      (p.activity('words.i01')['prompt']! as Map<String, Object?>)['target'] = 'vo:eng.nowhere.b';
      final List<Problem> ps = _run(p.pack);
      expect(
        ps,
        _refused('${_file(p, 'words.i01')} › answer.options[0].clip', 'neither recorded nor listed'),
      );
      expect(ps, _refused('${_file(p, 'words.i01')} › prompt.target', 'neither recorded nor listed'));
    });

    test('two options with the same text, or the same sound, look the same', () {
      final LangPack p = _valid();
      _option(p, 'words.i01', 1)['text'] = 'cat';
      expect(
        _run(p.pack),
        _refused('${_file(p, 'words.i01')} › answer.options', 'two options look the same'),
      );
    });
  });

  group('SEC-L1-1: the celebration of a lesson is a spoken line like the others', () {
    test('a pack of the lands refuses a second clip and a word on show in it', () {
      final SamplePack land = SamplePack();
      (land.doc(lessonFile)['celebration']! as Map<String, Object?>)
        ..['show'] = 'cat'
        ..['target'] = 'vo:not.in.this.pack';
      final List<Problem> ps = _run(land);
      expect(ps, _refused('$lessonFile › celebration.show', 'belongs to a language course'));
      expect(ps, _refused('$lessonFile › celebration.target', 'belongs to a language course'));
    });

    test('a language pack checks the clip against its voice lines and the word against the script rules', () {
      final SamplePack lang = SamplePack.language('eng');
      final String file = lang.docs.keys.firstWhere((String k) => k.startsWith('lesson.'));
      (lang.doc(file)['celebration']! as Map<String, Object?>)
        ..['show'] = 'c${_cp(0x202E)}at'
        ..['target'] = 'vo:not.in.this.pack';
      final List<Problem> ps = _run(lang);
      expect(ps, _refused('$file › celebration.target', 'neither recorded nor listed'));
      expect(ps, _refused('$file › celebration.show', 'direction control'));
    });
  });

  group('SEC-L1-2: a Hebrew caption holds no direction control and no letter of another script', () {
    final Map<String, String> crafted = <String, String>{
      'a right-to-left override': 'א${_cp(0x202E)}ב',
      'a left-to-right override': 'א${_cp(0x202D)}ב',
      'an isolate': 'א${_cp(0x2066)}ב${_cp(0x2069)}',
      'a zero-width joiner': 'א${_cp(0x200D)}ב',
      'a soft hyphen': 'א${_cp(0xAD)}ב',
      'a fullwidth word': 'א ${_cp(0xFF43)}${_cp(0xFF41)}${_cp(0xFF54)}',
      'a Greek word': 'א ${_cp(0x39A)}${_cp(0x391)}${_cp(0x3A4)}',
      'an accented letter': 'א caf${_cp(0xE9)}',
      'mathematical letters': 'א ${String.fromCharCodes(<int>[0x1D5BC, 0x1D5BA, 0x1D5CD])}',
    };
    crafted.forEach((String name, String text) {
      test(name, () {
        final LangPack p = _valid();
        final Map<String, Object?> prompt = p.activity('words.i01')['prompt']! as Map<String, Object?>;
        ((prompt['caption']! as List<Object?>).single! as Map<String, Object?>)['v'] = text;
        expect(
          _run(p.pack).where((Problem x) => x.path == '${_file(p, 'words.i01')} › prompt.caption[0].v'),
          isNotEmpty,
        );
        final SamplePack land = SamplePack();
        ((((land.doc(tapFile)['prompt']! as Map<String, Object?>)['caption']!) as List<Object?>).single!
                as Map<String, Object?>)['v'] =
            text;
        expect(_run(land).where((Problem x) => x.path.startsWith(tapFile)), isNotEmpty);
      });
    });

    test('plain Hebrew with its points, a geresh and a maqaf is still clean', () {
      expect(
        hebrewLineProblems('הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה. צ${_cp(0x5F3)}יפּ חֲצִי${_cp(0x5BE)}חֲצִי'),
        isEmpty,
      );
    });
  });

  group('SEC-L1-5: Hebrew nikud sits on a letter, at most three on one, and a text is not marks alone', () {
    test('a point with no letter before it, four on a letter, and a text of marks only are refused', () {
      final String dalet = _cp(0x5D3);
      final List<(String, String)> cases = <(String, String)>[
        (_cp(0x5B8), 'with no letter before it'),
        ('$dalet ${_cp(0x5B8)}', 'with no letter before it'),
        ('$dalet${_cp(0x5B0)}${_cp(0x5B8)}${_cp(0x5BC)}${_cp(0x5C1)}', 'more than 3 marks'),
        ('${_cp(0x5B8)}${_cp(0x5BC)}', 'shows nothing'),
        ('  ', 'shows nothing'),
      ];
      for (final (String text, String message) in cases) {
        expect(
          textProblems('heb', text).any((String m) => m.contains(message)),
          isTrue,
          reason: '$text: $message',
        );
      }
    });

    test('a pointed letter with three marks is valid, and so are the paseq-like signs refused as marks', () {
      final String shin = _cp(0x5E9);
      expect(textProblems('heb', '$shin${_cp(0x5C1)}${_cp(0x5BC)}${_cp(0x5B8)}'), isEmpty);
      expect(textProblems('heb', '${_cp(0x5D3)}${_cp(0x5C0)}'), isNotEmpty, reason: 'the paseq is no point');
    });

    test('a vowel sign taught on its own is a grapheme, not a text', () {
      final LangPack p = LangPack('heb');
      p.pack.doc('skill.HEB-A-02.json')['graphemes'] = <Object?>[_cp(0x5B8), '${_cp(0x5D3)}${_cp(0x5BC)}'];
      expect(_run(p.pack), isEmpty);
    });
  });

  group('what a tile may show besides letters', () {
    test('Hebrew numeral cards (HEB-A-10): digits and the shapes of the batch are valid; other courses refuse a digit', () {
      for (final String card in <String>['5', '0', _cp(0x25CF), _cp(0x2665), _cp(0x273F), _cp(0x2600)]) {
        expect(textProblems('heb', card), isEmpty, reason: card);
      }
      expect(textProblems('eng', '5'), isNotEmpty);
      expect(textProblems('rus', '5'), isNotEmpty);
      expect(textProblems('eng', _cp(0x25CF)), isNotEmpty);
    });

    test(
      'a phrase may use the ellipsis, the dash, the slash and the double quote; a single word may not',
      () {
        for (final String mark in <String>[_cp(0x2026), _cp(0x2014), '/', '"']) {
          expect(textProblems('eng', 'one $mark two'), isEmpty, reason: mark);
          expect(textProblems('eng', 'one${mark}two'), isNotEmpty, reason: 'a word with $mark');
        }
      },
    );

    test('the curly apostrophe is an apostrophe, in a word as in a phrase', () {
      expect(textProblems('eng', 'it${_cp(0x2019)}s'), isEmpty);
      expect(textProblems('eng', 'it${_cp(0x2019)}s a cat'), isEmpty);
    });

    test(
      'QA-L1-3: the marks of a Hebrew letter in the other order are the same grapheme, and the word decodes',
      () {
        final String a = '${_cp(0x5D1)}${_cp(0x5BC)}${_cp(0x5B8)}';
        final String b = '${_cp(0x5D1)}${_cp(0x5B8)}${_cp(0x5BC)}';
        expect(plainWord(a), plainWord(b));
        expect(decodes(a, <String>{b}), isTrue);
      },
    );
  });

  group('the item says the face of its text tiles', () {
    LangPack shortItem(String course, List<String> w, {String? face}) {
      final LangPack p = LangPack(course);
      p.add(
        tapJson(
          course: course,
          id: 'face',
          options: <Map<String, Object?>>[
            textOption('o1', w[0]),
            textOption('o2', w[1], tag: p.tag('lis.sem')),
            textOption('o3', w[2], tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
          answer: <String, Object?>{'face': ?face},
        ),
      );
      return p;
    }

    test('an item whose options are all one or two letters must say letter or word, in every course', () {
      for (final (String, List<String>) c in <(String, List<String>)>[
        ('eng', <String>['on', 'up', 'in']),
        ('eng', <String>['sh', 'ch', 'th']),
        ('eng', <String>['a', 'b', 'c']),
        ('rus', <String>['да', 'он', 'ёж']),
        ('heb', <String>['בֵּן', 'טַל', 'דָּן']),
      ]) {
        final LangPack p = shortItem(c.$1, c.$2);
        expect(
          _run(p.pack),
          _refused('activity.${c.$1}.face.json › answer.face', 'say whether the tiles are `letter`'),
          reason: '${c.$2}',
        );
        for (final String face in <String>['letter', 'word']) {
          expect(_run(shortItem(c.$1, c.$2, face: face).pack), isEmpty, reason: '${c.$2} $face');
        }
      }
    });

    test('an item with any longer option needs no marker, and may still say word', () {
      expect(_run(shortItem('eng', <String>['on', 'cat', 'sun']).pack), isEmpty);
      expect(_run(shortItem('eng', <String>['on', 'cat', 'sun'], face: 'word').pack), isEmpty);
    });

    test('a letter item holds letters and digraphs only', () {
      final LangPack p = shortItem('eng', <String>['a', 'b', 'cat'], face: 'letter');
      expect(
        _run(p.pack),
        _refused('activity.eng.face.json › answer.options[2].text', 'a letter item holds letters only'),
      );
    });

    test('the face is one of letter and word', () {
      final LangPack p = shortItem('eng', <String>['a', 'b', 'c'], face: 'maybe');
      expect(_run(p.pack), isNotEmpty);
    });

    test('a picture item and a sound item have no face to say', () {
      final LangPack p = LangPack();
      p.add(
        tapJson(
          id: 'pic',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'flower_red'),
            pictureOption('o2', 'flower_yellow', tag: p.tag('lis.sem')),
            pictureOption('o3', 'butterfly', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      expect(_run(p.pack), isEmpty);
    });
  });
}
