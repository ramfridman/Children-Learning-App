// The validator rules of LS03 `boxes`, LS05 change one part and LS04 blend slide (docs/milestones/L5.md sections 5.3 to 5.5 and 5.9, with the
// curriculum-expert's decisions of 2026-11-07), one test for each rule: a case that is right passes, and the same case broken in one place is refused
// with the rule's own words. Fixture course, no content.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/ls03_checks.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';

import 'support/l5_content.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

Map<String, Object?> _word(Map<String, Object?> a) =>
    (a['scene']! as Map<String, Object?>)['word']! as Map<String, Object?>;

bool _has(List<String> messages, String part) => messages.any((String m) => m.contains(part));

const List<String> _pictures = <String>[
  'sun',
  'whale',
  'fish',
  'banana',
  'cat',
  'mouth_teeth',
  'mouth_round',
  'mouth_tongue',
];

LangPack _pack(String course) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  for (final String slug in <String>[
    'pa.seg_syll',
    'pa.add_vowel',
    'pa.mirror',
    'pa.syll',
    'pa.vowel_cons',
    'pa.hard_soft',
    'pa.stress_last',
    'pa.not_first',
    'dec.vowel_skip',
    'dec.letter_mix',
    'dec.vowel_ou',
    'rea.reversed',
    'rea.letter_name',
    'rea.first_guess',
  ]) {
    p.addTag(slug, 'diagnostic');
  }
  return p;
}

/// English "sun": three phonemes, the count and then the box of /n/.
Map<String, Object?> _sun(LangPack p, {String id = 'box1'}) => boxesJson(
  course: 'eng',
  id: id,
  kinds: <String>['c', 'vowel', 'c'],
  steps: <String>['count', 'which'],
  which: 3,
  classify: <String, String>{
    'count=1': p.tag('pa.seg_syll'),
    'count=more': p.tag('pa.add_vowel'),
    'which=1': p.tag('pa.mirror'),
  },
  mouths: <String?>['mouth_teeth', 'mouth_round', 'mouth_tongue'],
);

/// Russian "рыба" (ry-ba): hard, vowel, hard, vowel; the colours and then the stress.
Map<String, Object?> _rus(LangPack p, {String id = 'box1', List<String>? steps, int? stress = 2}) =>
    boxesJson(
      course: 'rus',
      id: id,
      picture: 'fish',
      skill: 'RUS-A-02',
      kinds: <String>['hard', 'vowel', 'hard', 'vowel'],
      steps: steps ?? <String>['count', 'colour', 'stress'],
      colours: 'brbr',
      stress: stress,
      classify: <String, String>{
        if ((steps ?? <String>['count', 'colour', 'stress']).contains('colour')) ...<String, String>{
          'colour=vowel_cons': p.tag('pa.vowel_cons'),
          'colour=hard_soft': p.tag('pa.hard_soft'),
        },
        'stress=4': p.tag('pa.stress_last'),
      },
    );

LangPack _rusPack(Map<String, Object?> a, {bool stressSkill = true}) {
  final LangPack p = _pack('rus');
  if (stressSkill) p.pack.doc('skill.RUS-A-02.json')['stress'] = true;
  p.add(a);
  return p;
}

void main() {
  group('LS03 boxes', () {
    test('an English count-and-which item passes and reads as its model', () {
      final LangPack p = _pack('eng');
      p.add(_sun(p));
      expect(_messages(p), isEmpty);
      final BoxesActivity a = p.content.activities['eng.box1']! as BoxesActivity;
      expect(a.count, 3);
      expect(a.steps, <BoxStep>[BoxStep.count, BoxStep.which]);
      expect(a.which, 3);
      expect(a.whichClip, 'vo:eng.box1.u2');
      expect(a.optionCount, 0, reason: 'a free response has no options');
      expect(a.engineTags, <String>{'eng.pa.seg_syll', 'eng.pa.add_vowel', 'eng.pa.mirror'});
      expect(a.unscored, isFalse);
    });

    test('the schema is the version 1.1 one: a drum item has no steps and a boxes item no beats', () {
      expect(activitySchemaFor('sound_boxes', version: '1.1'), isNot(same(activitySchemaFor('sound_boxes'))));
      expect(supportedTemplates['sound_boxes'], '1.1');
    });

    test('the units are as many as the count', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = _sun(p);
      (a['answer']! as Map<String, Object?>)['count'] = 4;
      p.add(a);
      expect(_has(_messages(p), 'the word has 3 units'), isTrue);
    });

    test('a count is at most the rail less one: 4 in Band A, 5 in Band B, 6 in Band C', () {
      Map<String, Object?> word(String band, int n) => boxesJson(
        course: 'eng',
        id: 'box1',
        band: band,
        kinds: List<String>.filled(n, 'c'),
        steps: <String>['count'],
      );
      for (final (String band, int ok, int tooMany) in <(String, int, int)>[
        ('A', 4, 5),
        ('B', 5, 6),
        ('C', 6, 7),
      ]) {
        final LangPack fine = _pack('eng')..add(word(band, ok));
        expect(_has(_messages(fine), 'rail'), isFalse, reason: 'band $band, $ok units');
        if (tooMany > 6) continue;
        final LangPack broken = _pack('eng')..add(word(band, tooMany));
        expect(
          _has(_messages(broken), 'rail leaves room for $ok units'),
          isTrue,
          reason: 'band $band, $tooMany units',
        );
      }
      expect(boxesMostUnits, <String, int>{'A': 4, 'B': 5, 'C': 6});
    });

    test('the steps come once each, in the order count, colour, stress, which', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = _sun(p);
      (a['scene']! as Map<String, Object?>)['steps'] = <String>['which', 'count'];
      p.add(a);
      expect(_has(_messages(p), 'in the order count, colour, stress, which'), isTrue);
    });

    test('a step needs its value in the answer and a value needs its step', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = _sun(p);
      (a['answer']! as Map<String, Object?>).remove('which');
      p.add(a);
      expect(_has(_messages(p), 'answer.which: the which step needs it'), isTrue);
      final LangPack q = _pack('eng');
      final Map<String, Object?> b = _sun(q);
      (b['scene']! as Map<String, Object?>)['steps'] = <String>['count'];
      q.add(b);
      expect(_has(_messages(q), 'the item has no which step'), isTrue);
    });

    test('which is a place of the word', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = _sun(p);
      (a['answer']! as Map<String, Object?>)['which'] = 5;
      p.add(a);
      expect(_has(_messages(p), 'is not a place of the word (1 to 3)'), isTrue);
    });

    test(
      'the colours are the Russian scheme: only there, as many as the units, and each the colour of its kind',
      () {
        final LangPack ok = _rusPack(_rus(_pack('rus')));
        expect(_messages(ok), isEmpty);
        final LangPack eng = _pack('eng');
        final Map<String, Object?> e = _sun(eng);
        (e['scene']! as Map<String, Object?>)['steps'] = <String>['count', 'colour', 'which'];
        (e['answer']! as Map<String, Object?>)['colours'] = 'brb';
        eng.add(e);
        expect(_has(_messages(eng), 'the Russian course'), isTrue);
        final Map<String, Object?> shortColours = _rus(_pack('rus'));
        (shortColours['answer']! as Map<String, Object?>)['colours'] = 'brb';
        expect(_has(_messages(_rusPack(shortColours)), 'has 3 colours for 4 units'), isTrue);
        final Map<String, Object?> wrongKind = _rus(_pack('rus'));
        (wrongKind['answer']! as Map<String, Object?>)['colours'] = 'brbb';
        expect(_has(_messages(_rusPack(wrongKind)), 'unit 4 is vowel, so its colour is r, not b'), isTrue);
      },
    );

    test('the stress step needs a skill flagged for it, a vowel to mark and the colour step (or a scheme given coloured) before it', () {
      expect(_messages(_rusPack(_rus(_pack('rus')))), isEmpty);
      expect(
        _has(_messages(_rusPack(_rus(_pack('rus')), stressSkill: false)), 'a skill flagged "stress"'),
        isTrue,
        reason: 'a skill without the flag',
      );
      final Map<String, Object?> onConsonant = _rus(_pack('rus'), stress: 3);
      expect(_has(_messages(_rusPack(onConsonant)), 'place 3 is not a vowel'), isTrue);
      // A count step and then the stress, with no colour between: the raised chips would be where she first learns which sounds are vowels.
      final Map<String, Object?> noColour = _rus(_pack('rus'), steps: <String>['count', 'stress']);
      (noColour['answer']! as Map<String, Object?>).remove('colours');
      expect(
        _has(_messages(_rusPack(noColour)), 'after the colour step, or on a scheme given coloured'),
        isTrue,
      );
      // Stress on a scheme given coloured: no count and no colour step.
      final Map<String, Object?> given = _rus(_pack('rus'), steps: <String>['stress']);
      (given['answer']! as Map<String, Object?>).remove('colours');
      expect(_messages(_rusPack(given)), isEmpty);
      // A word of one vowel has nothing to choose.
      final Map<String, Object?> oneVowel = boxesJson(
        course: 'rus',
        id: 'box2',
        picture: 'whale',
        skill: 'RUS-A-02',
        kinds: <String>['hard', 'vowel', 'hard'],
        steps: <String>['stress'],
        stress: 2,
      );
      expect(_has(_messages(_rusPack(oneVowel)), 'at least two vowels'), isTrue);
    });

    test(
      'a stress step on a word with two vowels is a two-choice item, and with three a three-choice one',
      () {
        final BoxesActivity two =
            _rusPack(_rus(_pack('rus'))).content.activities['rus.box1']! as BoxesActivity;
        expect(two.optionCount, 2);
        final BoxesActivity none =
            (_pack('eng')..add(_sun(_pack('eng')))).content.activities['eng.box1']! as BoxesActivity;
        expect(none.optionCount, 0);
      },
    );

    test('the keys of classify name a mistake of a step the item has, and never the right answer', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = _sun(p);
      ((a['answer']! as Map<String, Object?>)['classify']! as Map<String, Object?>)
        ..['count=3'] = p.tag('pa.mirror')
        ..['stress=2'] = p.tag('pa.mirror')
        ..['which=3'] = p.tag('pa.mirror');
      p.add(a);
      final List<String> m = _messages(p);
      expect(_has(m, '"count=3" is the right count'), isTrue);
      expect(_has(m, '"stress=2" is a mistake of the stress step, which the item does not have'), isTrue);
      expect(_has(m, '"which=3" is the right place'), isTrue);
    });

    test('a boxes item is never a check, and a probe has one answer so only a count step can be one', () {
      final LangPack p = _pack('eng');
      p.add(_sun(p)..['purpose'] = 'check');
      expect(_has(_messages(p), 'never a check'), isTrue);
      final LangPack q = _pack('eng');
      q.add(_sun(q)..['purpose'] = 'probe');
      expect(_has(_messages(q), 'only a count step can be one'), isTrue);
      final LangPack r = _pack('eng');
      r.add(
        boxesJson(
          course: 'eng',
          id: 'box3',
          purpose: 'probe',
          kinds: <String>['c', 'vowel', 'c'],
          steps: <String>['count'],
        ),
      );
      expect(_has(_messages(r), 'probe'), isFalse);
    });

    test('a unit has a kind its course knows, and the Hebrew course counts syllables and CV units', () {
      final LangPack p = _pack('eng');
      p.add(
        boxesJson(course: 'eng', id: 'box1', kinds: <String>['hard', 'vowel', 'c'], steps: <String>['count']),
      );
      expect(_has(_messages(p), '"hard" is not a kind of unit in the course eng'), isTrue);
      final LangPack h = _pack('heb');
      h.add(
        boxesJson(
          course: 'heb',
          id: 'box1',
          unit: 'phoneme',
          kinds: <String>['cv', 'cv'],
          steps: <String>['count'],
          picture: 'banana',
        ),
      );
      expect(_has(_messages(h), 'syllables and CV units'), isTrue);
    });

    test('in a pack of the lands the template is refused', () {
      final List<String> said = <String>[];
      checkLs03Activity(
        'f',
        _sun(_pack('eng')),
        language: false,
        course: 'core',
        skills: const <String, Map<String, Object?>>{},
        say: (String file, String path, String message) => said.add(message),
      );
      expect(said.single, contains('belong to a language course'));
    });

    test('the clips, the picture and the mouths are in the pack', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = _sun(p);
      _word(a)['sprite'] = 'asset:nope';
      p.add(a);
      expect(_has(_messages(p), 'scene.word.sprite'), isTrue);
    });
  });

  group('LS05 change one part', () {
    // The S1 wheel of the Hebrew pilot: letters and the signs qamats and patah (one sound) and no sign.
    List<PartSpec> wheelParts({bool extra = false}) => <PartSpec>[
      part('p1', 0, 'ל'),
      part('p2', 0, 'ר', tag: 'heb.dec.letter_mix'),
      part('p3', 1, 'ָ'),
      part('p4', 1, '', tag: 'heb.dec.vowel_skip'),
      if (extra) part('p5', 1, 'ַ', tag: 'heb.dec.vowel_ou'),
    ];
    List<ResultSpec> wheelResults({bool clips = true, bool extra = false}) => <ResultSpec>[
      made(<String>['p1', 'p3'], 'לָ', clip: clips ? 'vo:heb.u.la' : null),
      made(<String>['p1', 'p4'], 'ל', clip: clips ? 'vo:heb.s.lamed' : null),
      made(<String>['p2', 'p3'], 'רָ', clip: clips ? 'vo:heb.u.ra' : null),
      made(<String>['p2', 'p4'], 'ר', clip: clips ? 'vo:heb.s.resh' : null),
      if (extra) ...<ResultSpec>[
        made(<String>['p1', 'p5'], 'לַ', clip: 'vo:heb.u.la'),
        made(<String>['p2', 'p5'], 'רַ', clip: 'vo:heb.u.ra'),
      ],
    ];
    Map<String, Object?> make({
      bool extra = false,
      bool clips = true,
      List<PartSpec>? parts,
      List<ResultSpec>? results,
    }) => changeJson(
      id: 'wh1',
      frame: '__',
      parts: parts ?? wheelParts(extra: extra),
      results: results ?? wheelResults(clips: clips, extra: extra),
      answer: <String>['p1', 'p3'],
    );
    Map<String, Object?> explore({List<PartSpec>? parts, List<ResultSpec>? results}) => changeJson(
      id: 'wh0',
      mode: 'explore',
      frame: '__',
      parts: parts ?? <PartSpec>[for (final PartSpec p in wheelParts()) part(p.id, p.slot, p.text)],
      results: results ?? wheelResults(clips: false),
    );

    LangPack hebPack(Map<String, Object?> a) {
      final LangPack p = _pack('heb');
      p.add(a);
      return p;
    }

    test('a make item and a teaching screen pass and read as their model', () {
      final LangPack p = hebPack(make());
      p.add(explore());
      expect(_messages(p), isEmpty);
      final ChangePartActivity a = p.content.activities['heb.wh1']! as ChangePartActivity;
      expect(a.make, isTrue);
      expect(a.answerParts, <String>['p1', 'p3']);
      expect(a.target!.text, 'לָ');
      expect(a.resultFor(<String>['p2', 'p4'])!.clip, 'vo:heb.s.resh');
      expect(a.resultFor(<String>['p3', 'p1']), isNull);
      expect(a.engineTags, <String>{'heb.dec.letter_mix', 'heb.dec.vowel_skip'});
      final ChangePartActivity e = p.content.activities['heb.wh0']! as ChangePartActivity;
      expect(e.unscored, isTrue, reason: 'explore writes nothing');
    });

    test('a make item offers at most four parts', () {
      final LangPack p = hebPack(make(extra: true));
      expect(_has(_messages(p), 'at most 4 parts, not 5'), isTrue);
    });

    test(
      'a Hebrew wheel holds at most 7 letters and 4 signs in explore, and an item is the same on every board',
      () {
        final List<PartSpec> letters = <PartSpec>[
          for (int i = 0; i < 7; i++) part('p${i + 1}', 0, String.fromCharCode(0x05D0 + i)),
          for (int j = 0; j < 4; j++)
            part('p${8 + j}', 1, String.fromCharCode(<int>[0x05B8, 0x05B7, 0x05B4, 0x05B5][j])),
        ];
        List<ResultSpec> results(List<PartSpec> ps) => <ResultSpec>[
          for (final PartSpec l in ps.where((PartSpec p) => p.slot == 0))
            for (final PartSpec s in ps.where((PartSpec p) => p.slot == 1))
              made(<String>[l.id, s.id], l.text + s.text),
        ];
        expect(
          _messages(hebPack(explore(parts: letters, results: results(letters)))),
          isEmpty,
          reason: '7 letters and 4 signs',
        );
        // The schema stops at 11 parts (7 and 4); the rule says which side is too many.
        final List<PartSpec> eightLetters = <PartSpec>[
          for (int i = 0; i < 8; i++) part('p${i + 1}', 0, String.fromCharCode(0x05D0 + i)),
          for (int j = 0; j < 3; j++)
            part('p${9 + j}', 1, String.fromCharCode(<int>[0x05B8, 0x05B7, 0x05B4][j])),
        ];
        expect(
          _has(
            _messages(hebPack(explore(parts: eightLetters, results: results(eightLetters)))),
            'a wheel holds at most 7 letters, not 8',
          ),
          isTrue,
        );
        final List<PartSpec> fiveSigns = <PartSpec>[
          for (int i = 0; i < 6; i++) part('p${i + 1}', 0, String.fromCharCode(0x05D0 + i)),
          for (int j = 0; j < 5; j++)
            part('p${7 + j}', 1, String.fromCharCode(<int>[0x05B8, 0x05B7, 0x05B4, 0x05B5, 0x05B6][j])),
        ];
        expect(
          _has(
            _messages(hebPack(explore(parts: fiveSigns, results: results(fiveSigns)))),
            'a wheel holds at most 4 signs, not 5',
          ),
          isTrue,
        );
      },
    );

    test('the Russian strip holds at most 6 parts in explore', () {
      final List<String> vowels = <String>['а', 'я', 'о', 'ё', 'у', 'ю', 'ы'];
      List<PartSpec> parts(int n) => <PartSpec>[for (int i = 0; i < n; i++) part('p${i + 1}', 0, vowels[i])];
      List<ResultSpec> results(int n) => <ResultSpec>[
        for (int i = 0; i < n; i++) made(<String>['p${i + 1}'], 'м${vowels[i]}'),
      ];
      Map<String, Object?> strip(int n) => changeJson(
        course: 'rus',
        id: 'st1',
        mode: 'explore',
        frame: 'м_',
        parts: parts(n),
        results: results(n),
      );
      final LangPack six = _pack('rus')..add(strip(6));
      expect(_messages(six), isEmpty);
      final LangPack seven = _pack('rus')..add(strip(7));
      expect(_has(_messages(seven), 'a strip holds at most 6 parts, not 7'), isTrue);
    });

    test(
      'no two parts of a make item give the same result with the target\'s other part (qamats with patah)',
      () {
        final LangPack p = hebPack(
          make(
            extra: true,
            parts: <PartSpec>[
              part('p1', 0, 'ל'),
              part('p3', 1, 'ָ'),
              part('p5', 1, 'ַ', tag: 'heb.dec.vowel_ou'),
              part('p4', 1, '', tag: 'heb.dec.vowel_skip'),
            ],
            results: <ResultSpec>[
              made(<String>['p1', 'p3'], 'לָ', clip: 'vo:heb.u.la'),
              made(<String>['p1', 'p5'], 'לַ', clip: 'vo:heb.u.la'),
              made(<String>['p1', 'p4'], 'ל', clip: 'vo:heb.s.lamed'),
            ],
          ),
        );
        expect(_has(_messages(p), 'give the same result with the other part of the answer'), isTrue);
      },
    );

    test('every result a make item can reach has a clip; in explore a result may have none (a stop with no vowel)', () {
      expect(
        _has(_messages(hebPack(make(clips: false))), 'every result a make item can reach has a clip'),
        isTrue,
      );
      final List<ResultSpec> some = <ResultSpec>[
        made(<String>['p1', 'p3'], 'לָ', clip: 'vo:heb.u.la'),
        made(<String>['p1', 'p4'], 'ל'),
        made(<String>['p2', 'p3'], 'רָ', clip: 'vo:heb.u.ra'),
        made(<String>['p2', 'p4'], 'ר'),
      ];
      expect(_has(_messages(hebPack(explore(results: some))), 'clip'), isFalse);
    });

    test('every combination a make item can reach has a result', () {
      final LangPack p = hebPack(
        make(
          results: <ResultSpec>[
            made(<String>['p1', 'p3'], 'לָ', clip: 'vo:heb.u.la'),
            made(<String>['p1', 'p4'], 'ל', clip: 'vo:heb.s.lamed'),
            made(<String>['p2', 'p3'], 'רָ', clip: 'vo:heb.u.ra'),
          ],
        ),
      );
      expect(_has(_messages(p), 'p2 + p4 but it has no result'), isTrue);
    });

    test(
      'the wheel has "no sign" or the shva, never both (from S3 the shva takes the place of "no sign")',
      () {
        final String shva = String.fromCharCode(0x05B0);
        final LangPack p = hebPack(
          explore(
            parts: <PartSpec>[part('p1', 0, 'ל'), part('p2', 1, ''), part('p3', 1, shva)],
            results: <ResultSpec>[
              made(<String>['p1', 'p2'], 'ל'),
              made(<String>['p1', 'p3'], 'לְ'),
            ],
          ),
        );
        expect(_has(_messages(p), 'no sign" or the shva, never both'), isTrue);
        final LangPack s3 = hebPack(
          explore(
            parts: <PartSpec>[part('p1', 0, 'ל'), part('p3', 1, 'ָ'), part('p4', 1, shva)],
            results: <ResultSpec>[
              made(<String>['p1', 'p3'], 'לָ'),
              made(<String>['p1', 'p4'], 'לְ'),
            ],
          ),
        );
        expect(_has(_messages(s3), 'never both'), isFalse);
      },
    );

    test(
      'a bead is one letter or one vowel sign: a two-letter bead (hiriq with yod) is not a bead of Band B',
      () {
        final LangPack p = hebPack(
          explore(
            parts: <PartSpec>[part('p1', 0, 'ל'), part('p2', 1, 'ָ'), part('p3', 1, 'ִי')],
            results: <ResultSpec>[
              made(<String>['p1', 'p2'], 'לָ'),
              made(<String>['p1', 'p3'], 'לִי'),
            ],
          ),
        );
        expect(_has(_messages(p), 'is neither a letter'), isTrue);
      },
    );

    test('a distractor of make has its tag; a teaching screen has none', () {
      final LangPack p = hebPack(
        make(parts: wheelParts().map((PartSpec x) => part(x.id, x.slot, x.text)).toList()),
      );
      expect(_has(_messages(p), 'is a distractor: it names the mistake it shows'), isTrue);
      final LangPack q = hebPack(explore(parts: wheelParts()));
      expect(_has(_messages(q), 'nothing in it is wrong'), isTrue);
    });

    test('a result is what its parts make, and a combination is given once', () {
      final LangPack p = hebPack(
        make(
          results: <ResultSpec>[
            made(<String>['p1', 'p3'], 'מָ', clip: 'vo:heb.u.la'),
            made(<String>['p1', 'p3'], 'לָ', clip: 'vo:heb.u.la'),
            made(<String>['p1', 'p4'], 'ל', clip: 'vo:heb.s.lamed'),
            made(<String>['p2', 'p3'], 'רָ', clip: 'vo:heb.u.ra'),
            made(<String>['p2', 'p4'], 'ר', clip: 'vo:heb.s.resh'),
          ],
        ),
      );
      final List<String> m = _messages(p);
      expect(_has(m, 'but the parts make "לָ"'), isTrue);
      expect(_has(m, 'is given twice'), isTrue);
    });

    test('the marks of a result may stand in either order (a shin dot and a qamats are one unit)', () {
      final String shin = String.fromCharCodes(<int>[0x05E9, 0x05C1]);
      final LangPack p = hebPack(
        explore(
          parts: <PartSpec>[part('p1', 0, shin), part('p2', 1, 'ָ')],
          results: <ResultSpec>[
            made(<String>['p1', 'p2'], String.fromCharCodes(<int>[0x05E9, 0x05B8, 0x05C1])),
          ],
        ),
      );
      expect(_has(_messages(p), 'but the parts make'), isFalse);
    });

    test('an explore item is practice with no answer; a make item names the parts', () {
      final LangPack p = hebPack(explore()..['purpose'] = 'learn');
      expect(_has(_messages(p), 'is never scored: it is practice'), isTrue);
      final Map<String, Object?> noAnswer = make();
      (noAnswer['answer']! as Map<String, Object?>).remove('parts');
      expect(_has(_messages(hebPack(noAnswer)), 'names the parts that make what is heard'), isTrue);
      final LangPack probe = hebPack(make()..['purpose'] = 'probe');
      expect(_has(_messages(probe), 'never a probe and never a check'), isTrue);
    });
  });

  group('LS04 blend slide', () {
    Map<String, Object?> pan(LangPack p) => blendJson(
      course: 'eng',
      id: 'sl1',
      text: 'pan',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('p', clip: 'vo:eng.snd.p', stretch: false),
        bpart('a', clip: 'vo:eng.snd.a'),
        bpart('n', clip: 'vo:eng.snd.n'),
      ],
      whole: 'vo:eng.pan',
      stretched: 'vo:eng.blend.pan',
      options: <Map<String, Object?>>[
        slideOption('o1', picture: 'cat'),
        slideOption('o2', picture: 'sun', tag: p.tag('rea.reversed')),
        slideOption('o3', picture: 'fish', tag: p.tag('rea.first_guess')),
      ],
      correct: 'o1',
    );

    Map<String, Object?> ma(LangPack p, {String? stopClip, int parts = 2}) => blendJson(
      course: 'rus',
      id: 'mg1',
      text: parts == 2 ? 'ма' : 'мао',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('м', clip: 'vo:rus.snd.m'),
        bpart('а', clip: 'vo:rus.snd.a'),
        if (parts == 3) bpart('о', clip: 'vo:rus.snd.o'),
      ],
      whole: 'vo:rus.mg.ma',
      options: <Map<String, Object?>>[
        slideOption('o1', clip: 'vo:rus.mg.ma'),
        slideOption('o2', clip: 'vo:rus.snd.m', tag: p.tag('rea.letter_name')),
        slideOption('o3', clip: 'vo:rus.mg.am', tag: p.tag('rea.reversed')),
      ],
      correct: 'o1',
    );

    test('English graphemes pass and read as their model', () {
      final LangPack p = _pack('eng');
      p.add(pan(p));
      expect(_messages(p), isEmpty);
      final BlendSlideActivity a = p.content.activities['eng.sl1']! as BlendSlideActivity;
      expect(a.mode, 'graphemes');
      expect(a.word.parts.map((BlendPart x) => x.text).join(), 'pan');
      expect(a.word.parts[0].stretch, isFalse);
      expect(a.word.whole, 'vo:eng.pan');
      expect(a.correctId, 'o1');
      expect(a.optionCount, 3);
      expect(a.merge, isFalse);
      expect(a.unscored, isFalse, reason: 'the choice is scored');
      expect(a.engineTags, <String>{'eng.rea.reversed', 'eng.rea.first_guess'});
    });

    test('the parts join to the word', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = pan(p);
      _word(a)['text'] = 'pat';
      p.add(a);
      expect(_has(_messages(p), 'join to "pan", not to the word "pat"'), isTrue);
    });

    test('each course slides in its own mode', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = pan(p);
      (a['scene']! as Map<String, Object?>)['mode'] = 'merge';
      p.add(a);
      expect(_has(_messages(p), 'the course eng slides in the mode graphemes, not merge'), isTrue);
    });

    test('a merge is two parts, answered with sound buttons; a slide is answered with pictures', () {
      final LangPack ok = _pack('rus');
      ok.add(ma(ok));
      expect(_messages(ok), isEmpty);
      final LangPack three = _pack('rus');
      three.add(ma(three, parts: 3));
      expect(_has(_messages(three), 'a merge has two parts'), isTrue);
      final LangPack eng = _pack('eng');
      final Map<String, Object?> a = pan(eng);
      ((a['answer']! as Map<String, Object?>)['options']! as List<Object?>)[0] = slideOption(
        'o1',
        clip: 'vo:eng.pan',
      );
      eng.add(a);
      expect(_has(_messages(eng), 'is answered with the picture of the word'), isTrue);
    });

    test('a stop never sounds alone in a merge: a clip on a stretch: false part is refused', () {
      final LangPack p = _pack('rus');
      final Map<String, Object?> a = ma(p);
      (((a['scene']! as Map<String, Object?>)['word']! as Map<String, Object?>)['parts']!
          as List<Object?>)[0] = <String, Object?>{
        'text': 'м',
        'clip': 'vo:rus.snd.k',
        'stretch': false,
      };
      p.add(a);
      expect(_has(_messages(p), 'a stop (stretch: false) has no clip in a merge'), isTrue);
      final LangPack silent = _pack('rus');
      final Map<String, Object?> b = ma(silent);
      (((b['scene']! as Map<String, Object?>)['word']! as Map<String, Object?>)['parts']!
          as List<Object?>)[0] = <String, Object?>{
        'text': 'м',
        'stretch': false,
      };
      silent.add(b);
      expect(_has(_messages(silent), 'stop'), isFalse, reason: 'a stop with no clip moves in silence');
    });

    test('every distractor carries a tag of its course', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = pan(p);
      (((a['answer']! as Map<String, Object?>)['options']! as List<Object?>)[1]! as Map<String, Object?>)
          .remove('misconception');
      p.add(a);
      expect(_messages(p), isNotEmpty);
    });

    test('the whole word has its clip, and the slide is never a probe', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = pan(p)..['purpose'] = 'probe';
      _word(a).remove('whole');
      p.add(a);
      final List<String> m = _messages(p);
      expect(_has(m, 'the clip of the whole word is what plays after the choice'), isTrue);
      expect(_has(m, 'never a probe'), isTrue);
    });
  });

  group('the hints that borrow another template\'s screen (L5 5.9)', () {
    Map<String, Object?> stem(LangPack p) => stemJson(
      course: 'heb',
      id: 'st1',
      stem: 'שָׁ',
      clip: 'vo:heb.st1.stem',
      options: <Map<String, Object?>>[
        pictureOption('o1', 'cat'),
        pictureOption('o2', 'sun', tag: p.tag('dec.vowel_skip')),
        pictureOption('o3', 'fish', tag: p.tag('dec.letter_mix')),
      ],
      correct: 'o1',
    );

    test('a text stem whose level 2 opens the wheel and level 3 the slide passes and reads', () {
      final LangPack p = _pack('heb');
      final Map<String, Object?> a = stem(p);
      borrow(a, 2, <String, Object?>{'template': 'change_part'});
      borrow(a, 3, <String, Object?>{'template': 'blend_slide'});
      p.add(a);
      expect(_messages(p), isEmpty);
      final TapAnswerActivity t = p.content.activities['heb.st1']! as TapAnswerActivity;
      expect(t.hints[0].show, isNull);
      expect(t.hints[1].show!.template, 'change_part');
      expect(t.hints[2].show!.template, 'blend_slide');
    });

    test('level 1 is "read it to me": a borrowed screen is level 2 or 3', () {
      final LangPack p = _pack('heb');
      final Map<String, Object?> a = stem(p);
      borrow(a, 1, <String, Object?>{'template': 'change_part'});
      p.add(a);
      expect(_has(_messages(p), 'a borrowed screen is level 2 or 3'), isTrue);
    });

    test('only the text stem of LS01 borrows', () {
      final LangPack p = _pack('eng');
      final Map<String, Object?> a = tapJson(
        id: 'tap1',
        options: <Map<String, Object?>>[
          pictureOption('o1', 'cat'),
          pictureOption('o2', 'sun', tag: p.tag('lis.sem')),
        ],
        correct: 'o1',
      );
      borrow(a, 2, <String, Object?>{'template': 'blend_slide'});
      p.add(a);
      expect(_has(_messages(p), 'only the text stem of LS01'), isTrue);
    });

    test('data a hint gives obey the rules of the template it borrows', () {
      final LangPack p = _pack('heb');
      final Map<String, Object?> a = stem(p);
      borrow(a, 2, <String, Object?>{
        'template': 'change_part',
        'frame': <String, Object?>{'text': 'ש_', 'slots': 1},
        'parts': <Object?>[
          <String, Object?>{'id': 'p1', 'slot': 0, 'text': 'ָ'},
          <String, Object?>{'id': 'p2', 'slot': 0, 'text': ''},
        ],
        'results': <Object?>[
          <String, Object?>{
            'parts': <String>['p1'],
            'text': 'מָ',
          },
        ],
      });
      p.add(a);
      expect(_has(_messages(p), 'but the parts make'), isTrue);
    });

    test('a slide a hint gives is checked as a slide is: its parts join to its word', () {
      final LangPack p = _pack('heb');
      final Map<String, Object?> a = stem(p);
      borrow(a, 3, <String, Object?>{
        'template': 'blend_slide',
        'word': <String, Object?>{
          'text': 'שָׁר',
          'parts': <Object?>[
            <String, Object?>{'text': 'שָׁ'},
            <String, Object?>{'text': 'ל'},
          ],
        },
      });
      p.add(a);
      expect(_has(_messages(p), 'join to'), isTrue);
    });
  });

  group('the ladders', () {
    test('LS03, LS04 and LS05 each have a three-level ladder whose second level is another representation and whose third is the demonstration', () {
      for (final String t in <String>['sound_boxes', 'change_part', 'blend_slide']) {
        expect(HintLadder.problemWith(t), isNull, reason: t);
        expect(HintLadder.of(t)!.at(3), HintPicture.demonstration, reason: t);
        expect(HintLadder.of(t)!.at(1).marksAnswer, isFalse, reason: t);
        expect(HintLadder.of(t)!.at(2).marksAnswer, isFalse, reason: t);
      }
      expect(HintLadder.of('change_part')!.at(1), HintPicture.targetAndResult);
      expect(HintLadder.of('blend_slide')!.at(1), HintPicture.slideParts);
    });

    test('every template the app can play has a ladder', () {
      // A say-it step has nothing to get wrong, so no hints.
      for (final String t in supportedTemplates.keys.where((String k) => k != 'say_it')) {
        expect(HintLadder.of(t), isNotNull, reason: t);
      }
    });
  });
}
