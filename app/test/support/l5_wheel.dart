// The S1 wheel of the Hebrew pilot and the Russian strip as fixture items of LS05 (docs/languages/hebrew/band-b-pilot.md section 5.7, rus B-21):
// real letters, signs and units, every clip pending. Not content: only the shapes of the data the template must carry.
import 'l5_content.dart';
import 'language_content.dart';

const String qamats = '\u{05B8}';
const String patah = '\u{05B7}';
const String hiriq = '\u{05B4}';
const String shva = '\u{05B0}';

/// The letters of the S1 wheel and what each makes with each sign: a continuant with no sign sounds on its own, a letter that is never voiced alone
/// (the alef, a stop) makes nothing with no sign.
const List<String> s1Letters = <String>['מ', 'ל', 'שׁ', 'ר', 'א', 'בּ', 'ת'];
const List<String> s1Names = <String>['ma', 'la', 'sha', 'ra', 'a', 'ba', 'ta'];
const Set<String> s1Continuants = <String>{'מ', 'ל', 'שׁ', 'ר'};

/// The explore screen of S1: seven letters, qamats, patah and no sign (parts p1 to p7, p8, p9, p10).
Map<String, Object?> s1Explore({String id = 'whl0'}) {
  final List<PartSpec> parts = <PartSpec>[
    for (int i = 0; i < s1Letters.length; i++) part('p${i + 1}', 0, s1Letters[i]),
    part('p8', 1, qamats),
    part('p9', 1, patah),
    part('p10', 1, ''),
  ];
  final List<ResultSpec> results = <ResultSpec>[
    for (int i = 0; i < s1Letters.length; i++) ...<ResultSpec>[
      made(<String>['p${i + 1}', 'p8'], s1Letters[i] + qamats, clip: 'vo:heb.u.${s1Names[i]}'),
      made(<String>['p${i + 1}', 'p9'], s1Letters[i] + patah, clip: 'vo:heb.u.${s1Names[i]}'),
      if (s1Continuants.contains(s1Letters[i]))
        made(<String>['p${i + 1}', 'p10'], s1Letters[i], clip: 'vo:heb.s.${s1Names[i]}'),
    ],
  ];
  return changeJson(id: id, mode: 'explore', frame: '__', parts: parts, results: results);
}

/// B-19.4: make la. Parts lamed and resh, qamats and no sign; the distractors carry their tags (`heb.dec.letter_mix`, `heb.dec.vowel_skip`).
Map<String, Object?> s1Make(LangPack p, {String id = 'whl1'}) => changeJson(
  id: id,
  frame: '__',
  targetClip: 'vo:heb.u.la',
  parts: <PartSpec>[
    part('p1', 0, 'ל'),
    part('p2', 0, 'ר', tag: p.tag('dec.letter_mix')),
    part('p3', 1, qamats),
    part('p4', 1, '', tag: p.tag('dec.vowel_skip')),
  ],
  results: <ResultSpec>[
    made(<String>['p1', 'p3'], 'ל$qamats', clip: 'vo:heb.u.la', sprite: 'cat'),
    made(<String>['p1', 'p4'], 'ל', clip: 'vo:heb.s.lamed'),
    made(<String>['p2', 'p3'], 'ר$qamats', clip: 'vo:heb.u.ra'),
    made(<String>['p2', 'p4'], 'ר', clip: 'vo:heb.s.resh'),
  ],
  answer: <String>['p1', 'p3'],
);

/// The explore strip of Russian: kot and kit, each with its picture (a vowel changes the word).
Map<String, Object?> stripExplore({String id = 'str0'}) => changeJson(
  course: 'rus',
  id: id,
  mode: 'explore',
  frame: 'к_т',
  parts: <PartSpec>[part('p1', 0, 'о'), part('p2', 0, 'и')],
  results: <ResultSpec>[
    made(<String>['p1'], 'кот', clip: 'vo:rus.w.kot', sprite: 'cat'),
    made(<String>['p2'], 'кит', clip: 'vo:rus.w.kit', sprite: 'whale'),
  ],
);

/// B-21: make li, with the four vowels of the strip (ы and и a pair, у and ю a pair).
Map<String, Object?> stripMake(LangPack p, {String id = 'str1'}) => changeJson(
  course: 'rus',
  id: id,
  frame: 'л_',
  targetClip: 'vo:rus.sy.li',
  parts: <PartSpec>[
    part('p1', 0, 'ы', tag: p.tag('dec.yi')),
    part('p2', 0, 'и'),
    part('p3', 0, 'у', tag: p.tag('dec.hard_soft')),
    part('p4', 0, 'ю', tag: p.tag('dec.hard_soft')),
  ],
  results: <ResultSpec>[
    made(<String>['p1'], 'лы', clip: 'vo:rus.sy.ly'),
    made(<String>['p2'], 'ли', clip: 'vo:rus.sy.li'),
    made(<String>['p3'], 'лу', clip: 'vo:rus.sy.lu'),
    made(<String>['p4'], 'лю', clip: 'vo:rus.sy.lyu'),
  ],
  answer: <String>['p2'],
);

/// The widest wheel the validator allows: seven letters and four signs (S3 and later: qamats, patah, hiriq, shva), every combination heard.
Map<String, Object?> widestWheel({String id = 'whl2'}) {
  final List<String> signs = <String>[qamats, patah, hiriq, shva];
  return changeJson(
    id: id,
    mode: 'explore',
    frame: '__',
    parts: <PartSpec>[
      for (int i = 0; i < s1Letters.length; i++) part('p${i + 1}', 0, s1Letters[i]),
      for (int j = 0; j < signs.length; j++) part('p${8 + j}', 1, signs[j]),
    ],
    results: <ResultSpec>[
      for (int i = 0; i < s1Letters.length; i++)
        for (int j = 0; j < signs.length; j++)
          made(<String>['p${i + 1}', 'p${8 + j}'], s1Letters[i] + signs[j], clip: 'vo:heb.u.$i$j'),
    ],
  );
}

/// The longest strip: the six vowels of the Russian pilot's B-21, each with a picture, so that the check and the picture compete for the strip's room.
Map<String, Object?> sixVowelStrip({String id = 'str2', bool pictures = true}) {
  const List<String> v = <String>['а', 'я', 'о', 'ё', 'у', 'ю'];
  return changeJson(
    course: 'rus',
    id: id,
    mode: 'explore',
    frame: 'м_',
    parts: <PartSpec>[for (int i = 0; i < v.length; i++) part('p${i + 1}', 0, v[i])],
    results: <ResultSpec>[
      for (int i = 0; i < v.length; i++)
        made(
          <String>['p${i + 1}'],
          'м${v[i]}',
          clip: 'vo:rus.sy.m${i + 1}',
          sprite: pictures ? (i.isEven ? 'cat' : 'whale') : null,
        ),
    ],
  );
}
