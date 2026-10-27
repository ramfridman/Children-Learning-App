// A small valid pack, built fresh for every test so a test can break one thing and see what the
// validator says. It holds one activity of each template, a lesson, a skill and a misconception.
// File hashes here are placeholders: `validatePack` does not look at bytes (the installer does).

const String countFile = 'activity.count.butterflies.3.json';
const String tapFile = 'activity.pick.red.flower.json';
const String giveFile = 'activity.give.three.jar.json';
const String lessonFile = 'lesson.butterflies.json';
const String skillFile = 'skill.NUM-A-03.json';
const String skill2File = 'skill.NUM-A-04.json';
const String tagFile = 'misconception.M-CNT-DOUBLE.json';
const String tag2File = 'misconception.M-CNT-SKIP.json';
const String tag3File = 'misconception.M-CNT-CARD.json';
const String cueFile = 'cue.prompt.count.butterflies.3.json';

List<Object?> _he(String text) => <Object?>[
  <String, Object?>{'t': 'he', 'v': text},
];

Map<String, Object?> _spoken(String vo, String text) => <String, Object?>{'vo': vo, 'caption': _he(text)};

Map<String, Object?> _feedback() => <String, Object?>{
  'correct': _spoken('vo:fb.correct', 'יָפֶה מְאֹד!'),
  'incorrect': <Object?>[
    <String, Object?>{'when': 'default', 'vo': 'vo:fb.again', 'caption': _he('בּוֹא נִסְפֹּר שׁוּב')},
    <String, Object?>{
      'when': 'misconception:M-CNT-DOUBLE',
      'vo': 'vo:fb.double',
      'caption': _he('סָפַרְנוּ אֶחָד פַּעֲמַיִם'),
    },
  ],
  'unsure': _spoken('vo:fb.unsure', 'זֶה בְּסֵדֶר, נְנַסֶּה יַחַד'),
};

List<Object?> _hints() => <Object?>[
  <String, Object?>{
    'level': 1,
    'action': 'replay_prompt_slow',
    'vo': 'vo:hint.1',
    'caption': _he('נַקְשִׁיב שׁוּב'),
  },
  <String, Object?>{
    'level': 2,
    'action': 'highlight_objects_sequentially',
    'vo': 'vo:hint.2',
    'caption': _he('נַדְלִיק אֶחָד אֶחָד'),
  },
  <String, Object?>{
    'level': 3,
    'action': 'show_fingers',
    'vo': 'vo:hint.3',
    'caption': _he('נִרְאֶה עִם אֶצְבָּעוֹת'),
  },
];

Map<String, Object?> _base(String id, String template, Map<String, Object?> parts) => <String, Object?>{
  'schema': 'activity/v1',
  'id': id,
  'revision': 1,
  'template': template,
  'templateVersion': '1.0',
  'domain': 'numbers',
  'band': 'A',
  'skills': <Object?>[
    <String, Object?>{'id': 'NUM-A-03', 'weight': 1},
  ],
  'purpose': 'learn',
  'checkType': 'practice',
  'representation': 'concrete',
  'variantGroup': 'count-to-3',
  'difficulty': <String, Object?>{'authored': 0.1},
  'prompt': <String, Object?>{
    'vo': 'vo:prompt.$id',
    'caption': _he('סְפֹר אֶת הַפַּרְפָּרִים'),
    'replayButton': true,
  },
  ...parts,
  'feedback': _feedback(),
  'hints': _hints(),
  'scoring': <String, Object?>{
    'maxAttempts': 3,
    'creditByHintLevel': <Object?>[1, 0.75, 0.5, 0.25],
  },
  'tutor': <String, Object?>{'llmAllowed': false, 'goal': 'count one to one', 'mustNotRevealBeforeHint': 2},
  'a11y': <String, Object?>{'altText': 'שְׁלֹשָׁה פַּרְפָּרִים עַל הַדֶּשֶׁא'},
};

Map<String, Object?> _countActivity() => _base('count.butterflies.3', 'count_tap', <String, Object?>{
  'scene': <String, Object?>{
    'objects': <String, Object?>{
      'sprite': 'asset:butterfly',
      'litSprite': 'asset:butterfly_lit',
      'count': 3,
      'arrangement': 'scatter',
      'onTap': 'fly_to_target',
      'seed': 7,
    },
    'target': <String, Object?>{'sprite': 'asset:jar'},
  },
  'answer': <String, Object?>{
    'type': 'choice',
    'options': <Object?>[
      <String, Object?>{'id': 'o1', 'value': 2, 'misconception': 'M-CNT-SKIP'},
      <String, Object?>{'id': 'o2', 'value': 3},
      <String, Object?>{'id': 'o3', 'value': 4, 'misconception': 'M-CNT-DOUBLE'},
    ],
    'correct': 'o2',
    'shuffle': true,
    'unsureAllowed': true,
  },
  'answerPrompt': _spoken('vo:count.how_many', 'כַּמָּה פַּרְפָּרִים יֵשׁ?'),
  'traceClassifiers': <Object?>[
    <String, Object?>{'when': 'same_object_tapped_twice', 'misconception': 'M-CNT-DOUBLE'},
    <String, Object?>{'when': 'object_never_tapped', 'misconception': 'M-CNT-SKIP'},
  ],
});

Map<String, Object?> _tapActivity() => _base('pick.red.flower', 'tap_answer', <String, Object?>{
  'scene': <String, Object?>{'background': 'asset:meadow'},
  'answer': <String, Object?>{
    'type': 'choice',
    'options': <Object?>[
      <String, Object?>{'id': 'o1', 'sprite': 'asset:flower_red', 'label': 'red'},
      <String, Object?>{'id': 'o2', 'sprite': 'asset:flower_yellow', 'label': 'yellow'},
    ],
    'correct': 'o1',
    'shuffle': true,
    'unsureAllowed': true,
  },
});

Map<String, Object?> _giveActivity() => _base('give.three.jar', 'give_n', <String, Object?>{
  'scene': <String, Object?>{
    'source': <String, Object?>{'sprite': 'asset:butterfly', 'count': 6},
    'target': <String, Object?>{'sprite': 'asset:jar'},
  },
  'answer': <String, Object?>{
    'type': 'give',
    'n': 3,
    'classifiers': <Object?>[
      <String, Object?>{'when': 'took_all', 'misconception': 'M-CNT-CARD'},
    ],
  },
});

Map<String, Object?> _lesson() => <String, Object?>{
  'schema': 'lesson/v1',
  'id': 'butterflies',
  'revision': 1,
  'band': 'A',
  'title': _he('פַּרְפָּרִים וּפְרָחִים'),
  'skills': <Object?>['NUM-A-03'],
  'items': <Object?>['count.butterflies.3', 'pick.red.flower', 'give.three.jar'],
  'estimatedMinutes': 5,
  'celebration': _spoken('vo:celebrate', 'כָּל הַכָּבוֹד!'),
};

Map<String, Object?> _skill(String id, {List<Object?> prerequisites = const <Object?>[]}) =>
    <String, Object?>{
      'schema': 'skill/v1',
      'id': id,
      'domain': 'numbers',
      'band': 'A',
      'title': _he('סְפִירָה'),
      'prerequisites': prerequisites,
      'representations': <Object?>['concrete', 'pictorial'],
      'misconceptions': <Object?>['M-CNT-DOUBLE'],
      'retention': <String, Object?>{'targetRetention': 0.9, 'initialStabilityDays': 1},
    };

Map<String, Object?> _tag(String id, {List<Object?> repair = const <Object?>[]}) => <String, Object?>{
  'schema': 'misconception/v1',
  'id': id,
  'skills': <Object?>['NUM-A-03'],
  'parentText': 'The child counts one object twice or skips one.',
  'repairActivities': repair,
  'preferredRepresentations': <Object?>['concrete'],
};

class SamplePack {
  SamplePack._(this.manifest, this.docs, this.files);

  /// A fresh valid pack. Change [manifest], [docs] or [files] in place, then call `validatePack`.
  factory SamplePack() {
    final Map<String, Object?> docs = <String, Object?>{
      countFile: _countActivity(),
      tapFile: _tapActivity(),
      giveFile: _giveActivity(),
      lessonFile: _lesson(),
      skillFile: _skill('NUM-A-03'),
      skill2File: _skill(
        'NUM-A-04',
        prerequisites: <Object?>[
          <String, Object?>{'skill': 'NUM-A-03', 'weight': 0.8},
        ],
      ),
      tagFile: _tag('M-CNT-DOUBLE', repair: <Object?>['count.butterflies.3']),
      tag2File: _tag('M-CNT-SKIP'),
      tag3File: _tag('M-CNT-CARD'),
      cueFile: <String, Object?>{
        'schema': 'cue/v1',
        'id': 'prompt.count.butterflies.3',
        'cues': <Object?>[
          <String, Object?>{'t': 0, 'o': 0},
          <String, Object?>{'t': 200, 'o': 1},
          <String, Object?>{'t': 380, 'o': 0},
        ],
      },
    };
    const List<String> assetFiles = <String>[
      'butterfly',
      'butterfly_lit',
      'jar',
      'meadow',
      'flower_red',
      'flower_yellow',
    ];
    final List<String> names = <String>[
      ...docs.keys,
      for (final String a in assetFiles) '$a.svg',
      'prompt_butterflies.mp3',
    ];
    final Map<String, Object?> manifest = <String, Object?>{
      'schema': 'manifest/v1',
      'id': 'sample-pack',
      'version': '1.0.0',
      'minAppVersion': '0.1.0',
      'templates': <String, Object?>{'tap_answer': '1.0', 'count_tap': '1.0', 'give_n': '1.0'},
      'files': <Object?>[
        for (final (int i, String n) in names.indexed)
          <String, Object?>{'name': n, 'sha256': i.toRadixString(16).padLeft(64, '0'), 'size': 100 + i},
      ],
      'assets': <Object?>[
        for (final String a in assetFiles) <String, Object?>{'id': a, 'file': '$a.svg'},
      ],
      'vo': <Object?>[
        <String, Object?>{'id': 'prompt.count.butterflies.3', 'file': 'prompt_butterflies.mp3'},
      ],
      'voPending': <Object?>[
        for (final String v in <String>[
          'fb.correct',
          'fb.again',
          'fb.double',
          'fb.unsure',
          'hint.1',
          'hint.2',
          'hint.3',
          'prompt.pick.red.flower',
          'prompt.give.three.jar',
          'count.how_many',
          'celebrate',
        ])
          'vo:$v',
      ],
      'entries': <String, Object?>{
        'activities': <Object?>['count.butterflies.3', 'pick.red.flower', 'give.three.jar'],
        'lessons': <Object?>['butterflies'],
        'skills': <Object?>['NUM-A-03', 'NUM-A-04'],
        'misconceptions': <Object?>['M-CNT-DOUBLE', 'M-CNT-SKIP', 'M-CNT-CARD'],
        'characters': <Object?>[],
        'cues': <Object?>['prompt.count.butterflies.3'],
      },
    };
    return SamplePack._(manifest, docs, names.toSet());
  }

  final Map<String, Object?> manifest;

  /// Each JSON file by name.
  final Map<String, Object?> docs;

  /// Every file name in the pack.
  final Set<String> files;

  Map<String, Object?> doc(String name) => docs[name]! as Map<String, Object?>;

  List<Map<String, Object?>> manifestList(String key) => <Map<String, Object?>>[
    for (final Object? e in manifest[key]! as List<Object?>) e! as Map<String, Object?>,
  ];
}
