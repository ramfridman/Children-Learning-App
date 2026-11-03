// Fixture language packs for the course screens (L-course): a few real Band A items of each course
// (docs/languages/{english,hebrew,russian}/band-a-content.md), with the approved pictures of `content/languages/pictures`, a path of
// lessons, a placement document and the tags the items name. Not content: the clips are only names (all pending), and the lessons hold
// the few items the batch lists, not the whole skill. The real packs make the same screens work with no change.
//
// English: ENG-A-01 greetings, A-03 colours, A-05 animals, A-06 body words (7 lessons); placement strand `o`, four levels.
// Hebrew:  HEB-A-02 words from stories, A-07 rhymes, A-10 letters (5 lessons); placement strands `l` and `c`.
// Russian: RUS-A-05 animals, A-06 colours, A-19 the first sound (5 lessons); placement strands `1` and `2`.

import 'package:nitznutz/content/models.dart';

import 'language_content.dart';
import 'sample_pack.dart';

const String _tap = 'הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה.';
const String _rhyme = 'אֵיזוֹ מִלָּה נִגְמֶרֶת אוֹתוֹ דָּבָר?';
const String _find = 'בּוֹאוּ נִמְצָא:';
const String _letters = 'אֵיפֹה הָאוֹתִיּוֹת?';

/// A pick-the-picture item of the batch: the right picture and the distractors with their tags (slugs of the course).
class Pick {
  const Pick(this.id, this.right, this.others, {this.clip, this.frame = _tap, this.text = false});

  /// The id inside the course (`ani_cat`): the item is `<course>.<id>`.
  final String id;
  final String right;

  /// `(asset, tag slug)` of each distractor.
  final List<(String, String)> others;

  /// The target word's clip, which the prompt plays after the Hebrew frame.
  final String? clip;
  final String frame;

  /// The options are letters or marks of a text, not pictures.
  final bool text;
}

class _Skill {
  const _Skill(this.id, this.strand, this.title, {this.after});

  final String id;
  final String strand;
  final String title;
  final String? after;
}

class _Lesson {
  const _Lesson(this.id, this.title, this.skill, this.items);

  final String id;
  final String title;
  final String skill;
  final List<Pick> items;
}

class _Level {
  const _Level(this.skill, this.probes);

  final String skill;
  final List<Pick> probes;
}

/// The strand a placement document holds and its start rule: `(answer, equals, level)`.
class _Strand {
  const _Strand(this.id, this.levels, {this.start = const <(String, String, int)>[]});

  final String id;
  final List<_Level> levels;
  final List<(String, String, int)> start;
}

class _Course {
  const _Course({
    required this.skills,
    required this.tags,
    required this.lessons,
    required this.strands,
    required this.celebration,
  });

  final List<_Skill> skills;

  /// `(slug, strand)` of each tag, all diagnostic.
  final List<(String, String)> tags;
  final List<_Lesson> lessons;
  final List<_Strand> strands;
  final String celebration;
}

// ---- English ----

const Pick _hello1 = Pick('hi_pip_leave', 'pip-leave', <(String, String)>[
  ('pip-arrive', 'sem'),
  ('mika-eat', 'guess'),
], clip: 'vo:eng.w.goodbye');
const Pick _hello2 = Pick('hi_mika_arrive', 'mika-arrive', <(String, String)>[
  ('mika-leave', 'sem'),
  ('mika-eat', 'guess'),
], clip: 'vo:eng.w.hi');
const Pick _hello3 = Pick('hi_mika_hello', 'mika-arrive', <(String, String)>[
  ('mika-leave', 'sem'),
  ('mika-eat', 'guess'),
], clip: 'vo:eng.w.hello');
const Pick _hello4 = Pick('hi_mika_bye', 'mika-leave', <(String, String)>[
  ('mika-arrive', 'sem'),
  ('mika-eat', 'guess'),
], clip: 'vo:eng.w.goodbye2');
const Pick _hello5 = Pick('hi_pip_hello', 'pip-arrive', <(String, String)>[
  ('pip-leave', 'sem'),
  ('mika-eat', 'guess'),
], clip: 'vo:eng.w.hello2');
const Pick _hello6 = Pick('hi_pip_bye', 'pip-leave', <(String, String)>[
  ('pip-arrive', 'sem'),
  ('mika-eat', 'guess'),
], clip: 'vo:eng.w.bye');

const List<Pick> _colours1 = <Pick>[
  Pick('col_red', 'balloon-red', <(String, String)>[
    ('balloon-blue', 'sem'),
    ('balloon-yellow', 'guess'),
  ], clip: 'vo:eng.w.red'),
  Pick('col_blue', 'balloon-blue', <(String, String)>[
    ('balloon-green', 'sem'),
    ('balloon-red', 'guess'),
  ], clip: 'vo:eng.w.blue'),
  Pick('col_yellow', 'balloon-yellow', <(String, String)>[
    ('balloon-red', 'sem'),
    ('balloon-blue', 'guess'),
  ], clip: 'vo:eng.w.yellow'),
  Pick('col_green', 'balloon-green', <(String, String)>[
    ('balloon-yellow', 'sem'),
    ('balloon-blue', 'guess'),
  ], clip: 'vo:eng.w.green'),
];
const List<Pick> _colours2 = <Pick>[
  Pick('boat_red', 'boat-red', <(String, String)>[
    ('boat-yellow', 'sem'),
    ('boat-blue', 'guess'),
  ], clip: 'vo:eng.w.red2'),
  Pick('boat_blue', 'boat-blue', <(String, String)>[
    ('boat-red', 'sem'),
    ('boat-green', 'guess'),
  ], clip: 'vo:eng.w.blue2'),
  Pick('boat_yellow', 'boat-yellow', <(String, String)>[
    ('boat-blue', 'sem'),
    ('boat-red', 'guess'),
  ], clip: 'vo:eng.w.yellow2'),
  Pick('boat_green', 'boat-green', <(String, String)>[
    ('boat-blue', 'sem'),
    ('boat-yellow', 'guess'),
  ], clip: 'vo:eng.w.green2'),
];
const List<Pick> _animals1 = <Pick>[
  Pick('ani_cat', 'cat', <(String, String)>[('dog', 'sem'), ('pig', 'guess')], clip: 'vo:eng.w.cat'),
  Pick('ani_dog', 'dog', <(String, String)>[('cat', 'sem'), ('cow', 'guess')], clip: 'vo:eng.w.dog'),
  Pick('ani_fish', 'fish', <(String, String)>[('frog', 'sem'), ('bird', 'guess')], clip: 'vo:eng.w.fish'),
  Pick('ani_bird', 'bird', <(String, String)>[('duck', 'sem'), ('cat', 'guess')], clip: 'vo:eng.w.bird'),
];
const List<Pick> _animals2 = <Pick>[
  Pick('ani_duck', 'duck', <(String, String)>[('bird', 'sem'), ('dog', 'guess')], clip: 'vo:eng.w.duck'),
  Pick('ani_pig', 'pig', <(String, String)>[('cow', 'sem'), ('frog', 'guess')], clip: 'vo:eng.w.pig'),
  Pick('ani_frog', 'frog', <(String, String)>[('fish', 'sem'), ('duck', 'guess')], clip: 'vo:eng.w.frog'),
];
const List<Pick> _body = <Pick>[
  Pick('body_nose', 'body-nose', <(String, String)>[
    ('body-mouth', 'sem'),
    ('body-ears', 'guess'),
  ], clip: 'vo:eng.w.nose'),
  Pick('body_ears', 'body-ears', <(String, String)>[
    ('body-eyes', 'sem'),
    ('body-nose', 'guess'),
  ], clip: 'vo:eng.w.ears'),
  Pick('body_feet', 'body-feet', <(String, String)>[
    ('body-hands', 'sem'),
    ('body-head', 'guess'),
  ], clip: 'vo:eng.w.feet'),
  Pick('body_tummy', 'body-tummy', <(String, String)>[
    ('body-head', 'sem'),
    ('body-hands', 'guess'),
  ], clip: 'vo:eng.w.tummy'),
];

Pick _probe(Pick of, String id) =>
    Pick(id, of.right, of.others, clip: of.clip, frame: of.frame, text: of.text);

_Course _english() => _Course(
  skills: const <_Skill>[
    _Skill('ENG-A-01', 'lis', 'Greetings'),
    _Skill('ENG-A-03', 'lis', 'Four colours', after: 'ENG-A-01'),
    _Skill('ENG-A-05', 'lis', 'Eight animals', after: 'ENG-A-01'),
    _Skill('ENG-A-06', 'lis', 'Body words', after: 'ENG-A-05'),
  ],
  tags: const <(String, String)>[('sem', 'lis'), ('guess', 'lis')],
  celebration: 'לְהִתְרָאוֹת! הָיָה כֵּיף לְשַׂחֵק בְּאַנְגְּלִית.',
  lessons: <_Lesson>[
    _Lesson('hello_1', 'בְּרָכוֹת', 'ENG-A-01', <Pick>[_hello2, _hello3, _hello5]),
    _Lesson('hello_2', 'בְּרָכוֹת שׁוּב', 'ENG-A-01', <Pick>[_hello1, _hello4, _hello6]),
    _Lesson('colours_1', 'צְבָעִים', 'ENG-A-03', _colours1),
    _Lesson('colours_2', 'צְבָעִים בַּסִּירוֹת', 'ENG-A-03', _colours2),
    _Lesson('animals_1', 'חַיּוֹת', 'ENG-A-05', _animals1),
    _Lesson('animals_2', 'עוֹד חַיּוֹת', 'ENG-A-05', _animals2),
    _Lesson('body_1', 'הַגּוּף', 'ENG-A-06', _body),
  ],
  strands: <_Strand>[
    _Strand(
      'o',
      <_Level>[
        _Level('ENG-A-01', <Pick>[_probe(_hello1, 'pr_hello_1'), _probe(_hello5, 'pr_hello_2')]),
        _Level('ENG-A-03', <Pick>[_probe(_colours1[0], 'pr_col_1'), _probe(_colours2[0], 'pr_col_2')]),
        _Level('ENG-A-05', <Pick>[_probe(_animals1[0], 'pr_ani_1'), _probe(_animals2[0], 'pr_ani_2')]),
        _Level('ENG-A-06', <Pick>[_probe(_body[0], 'pr_body_1'), _probe(_body[1], 'pr_body_2')]),
      ],
      start: const <(String, String, int)>[('knowsLetters', 'some', 1)],
    ),
  ],
);

// ---- Hebrew ----

const List<Pick> _words1 = <Pick>[
  Pick(
    'w_bush',
    'bush',
    <(String, String)>[('tree', 'sem'), ('pot', 'soundalike')],
    clip: 'vo:heb.w.bush',
    frame: _find,
  ),
  Pick(
    'w_flour',
    'flour',
    <(String, String)>[('sugar', 'sem'), ('rainbow', 'soundalike')],
    clip: 'vo:heb.w.flour',
    frame: _find,
  ),
  Pick(
    'w_bowl',
    'bowl',
    <(String, String)>[('plate', 'sem'), ('cave', 'soundalike')],
    clip: 'vo:heb.w.bowl',
    frame: _find,
  ),
  Pick(
    'w_oven',
    'oven',
    <(String, String)>[('fridge', 'sem'), ('ball', 'soundalike')],
    clip: 'vo:heb.w.oven',
    frame: _find,
  ),
];
const List<Pick> _words2 = <Pick>[
  Pick(
    'w_boat',
    'boat',
    <(String, String)>[('plane', 'sem'), ('teacher-sing', 'soundalike')],
    clip: 'vo:heb.w.boat',
    frame: _find,
  ),
  Pick(
    'w_hat',
    'hat',
    <(String, String)>[('shirt', 'sem'), ('star', 'soundalike')],
    clip: 'vo:heb.w.hat',
    frame: _find,
  ),
  Pick(
    'w_wind',
    'wind',
    <(String, String)>[('rain', 'sem'), ('apple', 'soundalike')],
    clip: 'vo:heb.w.wind',
    frame: _find,
  ),
  Pick(
    'w_ball',
    'ball',
    <(String, String)>[('doll', 'sem'), ('oven', 'soundalike')],
    clip: 'vo:heb.w.ball',
    frame: _find,
  ),
];
const List<Pick> _rhymes1 = <Pick>[
  Pick(
    'r_dag',
    'house-roof',
    <(String, String)>[('teddy', 'allit'), ('sea', 'sem')],
    clip: 'vo:heb.w.dag',
    frame: _rhyme,
  ),
  Pick(
    'r_pil',
    'rocket',
    <(String, String)>[('pizza', 'allit'), ('camel', 'sem')],
    clip: 'vo:heb.w.pil',
    frame: _rhyme,
  ),
  Pick(
    'r_kaf',
    'teddy-nose',
    <(String, String)>[('ball', 'allit'), ('fork', 'sem')],
    clip: 'vo:heb.w.kaf',
    frame: _rhyme,
  ),
];
const List<Pick> _rhymes2 = <Pick>[
  Pick(
    'r_kochav',
    'rabbit-tail',
    <(String, String)>[('cup', 'allit'), ('moon', 'sem')],
    clip: 'vo:heb.w.kochav',
    frame: _rhyme,
  ),
  Pick(
    'r_balon',
    'cupboard',
    <(String, String)>[('doll', 'allit'), ('ball', 'sem')],
    clip: 'vo:heb.w.balon',
    frame: _rhyme,
  ),
  Pick(
    'r_tut',
    'thread',
    <(String, String)>[('rooster', 'allit'), ('needle', 'sem')],
    clip: 'vo:heb.w.tut',
    frame: _rhyme,
  ),
];
const List<Pick> _letters1 = <Pick>[
  Pick('l_bet', 'ב', <(String, String)>[('5', 'num'), ('●', 'shape')], frame: _letters, text: true),
  Pick('l_shin', 'ש', <(String, String)>[('7', 'num'), ('⭐', 'shape')], frame: _letters, text: true),
  Pick('l_alef', 'א', <(String, String)>[('2', 'num'), ('○', 'shape')], frame: _letters, text: true),
];

_Course _hebrew() => _Course(
  skills: const <_Skill>[
    _Skill('HEB-A-02', 'ol', 'Words from stories'),
    _Skill('HEB-A-07', 'pa', 'Rhymes', after: 'HEB-A-02'),
    _Skill('HEB-A-10', 'pk', 'Letters', after: 'HEB-A-02'),
  ],
  tags: const <(String, String)>[
    ('sem', 'ol'),
    ('soundalike', 'ol'),
    ('allit', 'pa'),
    ('num', 'pk'),
    ('shape', 'pk'),
  ],
  celebration: 'כׇּל הַכָּבוֹד!',
  lessons: <_Lesson>[
    _Lesson('words_1', 'מִלִּים', 'HEB-A-02', _words1),
    _Lesson('words_2', 'עוֹד מִלִּים', 'HEB-A-02', _words2),
    _Lesson('rhymes_1', 'חֲרוּזִים', 'HEB-A-07', _rhymes1),
    _Lesson('rhymes_2', 'עוֹד חֲרוּזִים', 'HEB-A-07', _rhymes2),
    _Lesson('letters_1', 'אוֹתִיּוֹת', 'HEB-A-10', _letters1),
  ],
  strands: <_Strand>[
    _Strand('l', <_Level>[
      _Level('HEB-A-02', <Pick>[_probe(_words1[0], 'pr_w_1'), _probe(_words2[1], 'pr_w_2')]),
      _Level('HEB-A-07', <Pick>[_probe(_rhymes1[0], 'pr_r_1'), _probe(_rhymes2[2], 'pr_r_2')]),
    ]),
    _Strand('c', <_Level>[
      _Level('HEB-A-10', <Pick>[_probe(_letters1[0], 'pr_l_1'), _probe(_letters1[1], 'pr_l_2')]),
      _Level('HEB-A-10', <Pick>[_probe(_letters1[2], 'pr_l_3'), _probe(_letters1[0], 'pr_l_4')]),
    ]),
  ],
);

// ---- Russian ----

const List<Pick> _rusAnimals1 = <Pick>[
  Pick('a_cat', 'cat', <(String, String)>[('dog', 'sem'), ('mouse', 'sem')], clip: 'vo:rus.w.koshka'),
  Pick('a_dog', 'dog', <(String, String)>[('cat', 'sem'), ('cow', 'sem')], clip: 'vo:rus.w.sobaka'),
  Pick('a_fish', 'fish', <(String, String)>[('bird', 'sem'), ('whale', 'sem')], clip: 'vo:rus.w.ryba'),
  Pick('a_bird', 'bird', <(String, String)>[('fish', 'sem'), ('squirrel', 'sem')], clip: 'vo:rus.w.ptitsa'),
];
const List<Pick> _rusAnimals2 = <Pick>[
  Pick('a_cow', 'cow', <(String, String)>[('goat', 'sound'), ('horse', 'sem')], clip: 'vo:rus.w.korova'),
  Pick('a_horse', 'horse', <(String, String)>[('cow', 'sem'), ('pig', 'sem')], clip: 'vo:rus.w.loshad'),
  Pick('a_duck', 'duck', <(String, String)>[('hen', 'sem'), ('fish', 'sem')], clip: 'vo:rus.w.utka'),
];
const List<Pick> _rusColours1 = <Pick>[
  Pick('c_red', 'col-red', <(String, String)>[
    ('col-yellow', 'sem'),
    ('col-blue', 'sem'),
  ], clip: 'vo:rus.w.krasnyj'),
  Pick('c_blue', 'col-blue', <(String, String)>[
    ('col-green', 'sem'),
    ('col-black', 'sem'),
  ], clip: 'vo:rus.w.sinij'),
  Pick('c_yellow', 'col-yellow', <(String, String)>[
    ('col-green', 'sound'),
    ('col-white', 'sem'),
  ], clip: 'vo:rus.w.zhyoltyj'),
];
const List<Pick> _rusColours2 = <Pick>[
  Pick('c_green', 'col-green', <(String, String)>[
    ('col-yellow', 'sound'),
    ('col-blue', 'sem'),
  ], clip: 'vo:rus.w.zelyonyj'),
  Pick('c_white', 'col-white', <(String, String)>[
    ('col-black', 'sem'),
    ('col-yellow', 'sem'),
  ], clip: 'vo:rus.w.belyj'),
  Pick('c_black', 'col-black', <(String, String)>[
    ('col-white', 'sem'),
    ('col-red', 'sound'),
  ], clip: 'vo:rus.w.chyornyj'),
];
const List<Pick> _rusSounds = <Pick>[
  Pick('s_mouse', 'mouse', <(String, String)>[
    ('body-nose', 'sound'),
    ('house', 'notfirst'),
  ], clip: 'vo:rus.sf.mama'),
  Pick('s_cheese', 'cheese', <(String, String)>[
    ('balloon-big', 'sound'),
    ('body-nose', 'notfirst'),
  ], clip: 'vo:rus.sf.sok'),
  Pick('s_scarf', 'scarf', <(String, String)>[
    ('juice', 'sound'),
    ('mouse', 'notfirst'),
  ], clip: 'vo:rus.sf.shapka'),
  Pick('s_mouth', 'body-mouth', <(String, String)>[
    ('cat-tomcat', 'sound'),
    ('balloon-big', 'notfirst'),
  ], clip: 'vo:rus.sf.ryba'),
];

_Course _russian() => _Course(
  skills: const <_Skill>[
    _Skill('RUS-A-05', 'voc', 'Animals'),
    _Skill('RUS-A-06', 'voc', 'Colours', after: 'RUS-A-05'),
    _Skill('RUS-A-19', 'pho', 'The first sound', after: 'RUS-A-05'),
  ],
  tags: const <(String, String)>[('sem', 'voc'), ('sound', 'voc'), ('notfirst', 'pho')],
  celebration: 'כׇּל הַכָּבוֹד!',
  lessons: <_Lesson>[
    _Lesson('animals_1', 'חַיּוֹת', 'RUS-A-05', _rusAnimals1),
    _Lesson('animals_2', 'עוֹד חַיּוֹת', 'RUS-A-05', _rusAnimals2),
    _Lesson('colours_1', 'צְבָעִים', 'RUS-A-06', _rusColours1),
    _Lesson('colours_2', 'עוֹד צְבָעִים', 'RUS-A-06', _rusColours2),
    _Lesson('sounds_1', 'צְלִילִים', 'RUS-A-19', _rusSounds),
  ],
  strands: <_Strand>[
    _Strand('1', <_Level>[
      _Level('RUS-A-05', <Pick>[_probe(_rusAnimals1[0], 'pr_a_1'), _probe(_rusAnimals2[0], 'pr_a_2')]),
      _Level('RUS-A-06', <Pick>[_probe(_rusColours1[0], 'pr_c_1'), _probe(_rusColours2[1], 'pr_c_2')]),
    ]),
    _Strand('2', <_Level>[
      _Level('RUS-A-19', <Pick>[_probe(_rusSounds[0], 'pr_s_1'), _probe(_rusSounds[1], 'pr_s_2')]),
      _Level('RUS-A-19', <Pick>[_probe(_rusSounds[2], 'pr_s_3'), _probe(_rusSounds[3], 'pr_s_4')]),
    ]),
  ],
);

_Course _courseOf(String course) => switch (course) {
  'eng' => _english(),
  'heb' => _hebrew(),
  _ => _russian(),
};

// ---- building the pack ----

Map<String, Object?> _skillDoc(String course, _Skill s, List<String> tags) => <String, Object?>{
  'schema': 'skill/v1',
  'id': s.id,
  'course': course,
  'domain': 'languages',
  'band': 'A',
  'title': he(s.title),
  'strand': s.strand,
  'prerequisites': <Object?>[
    if (s.after != null) <String, Object?>{'skill': s.after, 'weight': 0.8},
  ],
  'representations': <Object?>['pictorial'],
  'misconceptions': tags,
  'retention': <String, Object?>{'targetRetention': 0.9, 'initialStabilityDays': 1},
};

/// A fixture pack of [course] ready for the course screens: skills, lessons, items, probes and a placement document.
///
/// The placement visit says its warm lines from the pack; the lessons' celebration is the course's own.
LangPack courseFixture(String course) {
  final _Course c = _courseOf(course);
  final LangPack p = LangPack(course);
  _clear(p.pack);
  for (final (String slug, String strand) in c.tags) {
    final String id = '$course.$strand.$slug';
    p.pack.addDocument('misconception.$id.json', 'misconceptions', id, <String, Object?>{
      'schema': 'misconception/v1',
      'id': id,
      'course': course,
      'kind': 'diagnostic',
      'skills': <String>[
        for (final _Skill s in c.skills)
          if (s.strand == strand) s.id,
      ],
      'parentText': 'The child is still learning this word.',
      'repairActivities': <Object?>[],
      'preferredRepresentations': <Object?>['pictorial'],
    });
  }
  for (final _Skill s in c.skills) {
    p.pack.addDocument(
      'skill.${s.id}.json',
      'skills',
      s.id,
      _skillDoc(course, s, <String>[
        for (final (String slug, String strand) in c.tags)
          if (strand == s.strand) '$course.$strand.$slug',
      ]),
    );
  }
  final Set<String> assets = <String>{};
  void addItem(Pick it, String skill, {bool probe = false}) {
    for (final String a in <String>[it.right, for (final (String a, String _) in it.others) a]) {
      if (!it.text) assets.add(_asset(a));
    }
    p.add(_tapItem(course, c, it, skill, probe: probe));
  }

  int sequence = 0;
  for (final _Lesson l in c.lessons) {
    for (final Pick it in l.items) {
      addItem(it, l.skill);
    }
    p.pack.addDocument('lesson.$course.${l.id}.json', 'lessons', '$course.${l.id}', <String, Object?>{
      'schema': 'lesson/v1',
      'id': '$course.${l.id}',
      'revision': 1,
      'course': course,
      'band': 'A',
      'title': he(l.title),
      'skills': <Object?>[l.skill],
      'items': <Object?>[
        '$course.${l.items.first.id}',
        for (final Pick it in l.items.skip(1)) '$course.${it.id}',
      ],
      'estimatedMinutes': 4,
      'sequence': ++sequence,
      'celebration': line('vo:$course.${l.id}.done', c.celebration),
    });
    (p.pack.manifest['voPending']! as List<Object?>).add('vo:$course.${l.id}.done');
  }
  for (final _Strand s in c.strands) {
    for (final _Level l in s.levels) {
      for (final Pick it in l.probes) {
        addItem(it, l.skill, probe: true);
      }
    }
  }
  p.addPictures(assets);
  p.addPlacement(
    placementJson(course, perVisit: 8, <Map<String, Object?>>[
      for (final _Strand s in c.strands)
        strandJson(
          s.id,
          course,
          <List<String>>[
            for (final _Level l in s.levels) <String>[for (final Pick it in l.probes) it.id],
          ],
          assumes: <List<String>>[
            for (final _Level l in s.levels) <String>[l.skill],
          ],
          start: <Map<String, Object?>>[
            for (final (String a, String e, int lv) in s.start)
              <String, Object?>{'answer': a, 'equals': e, 'level': lv},
          ],
        ),
    ]),
  );
  return p;
}

/// An asset id of a pack is lower case with underscores; the approved picture files use hyphens.
String _asset(String picture) => picture.replaceAll('-', '_');

Map<String, Object?> _tapItem(String course, _Course c, Pick it, String skill, {required bool probe}) {
  String tag(String slug) {
    for (final (String s, String strand) in c.tags) {
      if (s == slug) return '$course.$strand.$slug';
    }
    throw StateError('no tag $slug in $course');
  }

  final List<Map<String, Object?>> options = <Map<String, Object?>>[
    if (it.text) textOption('o1', it.right, tag: null) else pictureOption('o1', _asset(it.right)),
    for (final (int i, (String, String) o) in it.others.indexed)
      if (it.text)
        textOption('o${i + 2}', o.$1, tag: tag(o.$2))
      else
        pictureOption('o${i + 2}', _asset(o.$1), tag: tag(o.$2)),
  ];
  return tapJson(
    course: course,
    id: it.id,
    skill: skill,
    purpose: probe ? 'probe' : 'learn',
    options: options,
    correct: 'o1',
    target: it.clip,
    promptText: it.frame,
    answer: it.text ? const <String, Object?>{'face': 'letter'} : const <String, Object?>{},
  );
}

/// Takes the sample pack's own lesson, skills, items and tags out, leaving a valid empty language pack.
void _clear(SamplePack p) {
  const List<String> kinds = <String>['activity.', 'lesson.', 'skill.', 'misconception.', 'cue.'];
  final List<String> gone = <String>[
    for (final String k in p.docs.keys)
      if (kinds.any(k.startsWith)) k,
  ];
  p.docs.removeWhere((String k, Object? _) => gone.contains(k));
  p.files.removeWhere((String f) => gone.contains(f) || f.endsWith('.svg') || f.endsWith('.mp3'));
  final List<Object?> files = p.manifest['files']! as List<Object?>;
  files.removeWhere((Object? f) => !p.files.contains((f! as Map<String, Object?>)['name']));
  (p.manifest['assets']! as List<Object?>).clear();
  (p.manifest['vo']! as List<Object?>).clear();
  (p.manifest['voPending']! as List<Object?>).clear();
  (p.manifest['templates']! as Map<String, Object?>).clear();
  final Map<String, Object?> entries = p.manifest['entries']! as Map<String, Object?>;
  for (final MapEntry<String, Object?> e in entries.entries) {
    if (e.value is List<Object?>) (e.value! as List<Object?>).clear();
  }
}

/// The fixture pack of [course] as the app holds an installed one.
PackContent courseContent(String course) => courseFixture(course).content;

/// The fixture packs of [courses] as the installed language packs of a rig (`AppRig.languagePacks`).
Map<String, PackContent> fixturePacks(Iterable<String> courses) => <String, PackContent>{
  for (final String c in courses) c: courseContent(c),
};
