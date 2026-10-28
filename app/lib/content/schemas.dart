import 'schema.dart';

// The schemas of a content pack. Ids, tags and references use fixed shapes so that a file can never
// carry a path, a markup fragment or a command: every value is a short plain string, a number or a
// listed word. Text for the child is Hebrew only (`t` is always "he") and is shown as plain text.

abstract final class Patterns {
  static const String packId = r'[a-z0-9][a-z0-9-]{2,40}';
  static const String semver = r'\d{1,3}\.\d{1,3}\.\d{1,3}';
  static const String templateVersion = r'\d{1,2}\.\d{1,2}';
  static const String activityId = r'[a-z0-9][a-z0-9._-]{2,80}';
  static const String skillId = r'[A-Z]{2,5}-[ABC]-\d{2}';
  static const String tag = r'M-[A-Z]{2,5}-[A-Z0-9]{2,12}';
  static const String assetRef = r'asset:[a-z0-9_]{1,40}';
  static const String voRef = r'vo:[a-z0-9_.]{1,80}';
  static const String assetId = r'[a-z0-9_]{1,40}';
  static const String voId = r'[a-z0-9_.]{1,80}';
  static const String fileName = r'[A-Za-z0-9][A-Za-z0-9._-]{0,100}';
  static const String sha256 = r'[0-9a-f]{64}';
  static const String optionId = r'o[0-9]{1,2}';
  static const String worldObject = r'[a-z][a-z0-9-]{1,23}';
}

/// The four kinds of document in a pack, by the `schema` field of the file.
abstract final class SchemaIds {
  static const String manifest = 'manifest/v1';
  static const String packSource = 'pack-source/v1';
  static const String character = 'character-lite/v1';
  static const String cue = 'cue/v1';
  static const String activity = 'activity/v1';
  static const String lesson = 'lesson/v1';
  static const String skill = 'skill/v1';
  static const String misconception = 'misconception/v1';
}

/// Templates this app can play, and the version of each (what `templateVersion` must not exceed).
const Map<String, String> supportedTemplates = <String, String>{
  'tap_answer': '1.2',
  'count_tap': '1.0',
  'give_n': '1.0',
  'flash': '1.0',
  'sort_drag': '1.0',
  'build_pattern': '1.0',
  'robot_path': '1.0',
  'shape_builder': '1.0',
  'number_line': '1.0',
  'balance': '1.0',
  'spot_error': '1.0',
  'match_pairs': '1.0',
  'shop_pay': '1.0',
  'clock_set': '1.0',
  'trace': '1.0',
};

/// What the coins and notes of the shop are worth, in agorot, and the picture each is drawn with.
const Map<String, int> coinValues = <String, int>{
  'a10': 10,
  'h50': 50,
  's1': 100,
  's2': 200,
  's5': 500,
  's10': 1000,
  'n20': 2000,
  'n50': 5000,
  'n100': 10000,
  'n200': 20000,
};

const Map<String, String> coinSprites = <String, String>{
  'a10': 'coin_a10',
  'h50': 'coin_h50',
  's1': 'coin_s1',
  's2': 'coin_s2',
  's5': 'coin_s5',
  's10': 'coin_s10',
  'n20': 'note_20',
  'n50': 'note_50',
  'n100': 'note_100',
  'n200': 'note_200',
};

const List<String> domains = <String>['numbers', 'colors', 'shapes', 'logic', 'cs', 'math'];
const List<String> bands = <String>['A', 'B', 'C'];
const List<String> representations = <String>['concrete', 'pictorial', 'story', 'embodied', 'symbolic'];

const SString _id = SString(minLength: 3, maxLength: 81, pattern: Patterns.activityId);
const SString _characterId = SString(minLength: 3, maxLength: 41, pattern: Patterns.packId);
const SString _tag = SString(minLength: 5, maxLength: 20, pattern: Patterns.tag);
const SString _skill = SString(minLength: 6, maxLength: 11, pattern: Patterns.skillId);
const SString _vo = SString(minLength: 4, maxLength: 83, pattern: Patterns.voRef);
const SString _asset = SString(minLength: 7, maxLength: 46, pattern: Patterns.assetRef);
const SString _optionId = SString(minLength: 2, maxLength: 3, pattern: Patterns.optionId);
const SInt _revision = SInt(min: 1, max: 9999);

/// Hebrew written by an AI or an engineer stays `needs-editor` until a person approves it (CLAUDE.md).
const SField _review = SField(SEnum(<String>['needs-editor', 'approved']), required: false);

/// A line of Hebrew shown to the child (or the parent), as a list so another language can be added later.
const SArray _caption = SArray(
  SObject(<String, SField>{'t': SField(SConst('he')), 'v': SField(SString(minLength: 1, maxLength: 240))}),
  minItems: 1,
  maxItems: 1,
);

const SObject _spoken = SObject(<String, SField>{'vo': SField(_vo), 'caption': SField(_caption)});

// ---- manifest ----

const SArray _fileList = SArray(
  SObject(<String, SField>{
    'name': SField(SString(minLength: 1, maxLength: 101, pattern: Patterns.fileName)),
    'sha256': SField(SString(minLength: 64, maxLength: 64, pattern: Patterns.sha256)),
    'size': SField(SInt(min: 0, max: 16 * 1024 * 1024)),
  }),
  minItems: 1,
  maxItems: 8000,
  uniqueKey: 'name',
);

const SString _fileRef = SString(minLength: 1, maxLength: 101, pattern: Patterns.fileName);

const SArray _assetFiles = SArray(
  SObject(<String, SField>{
    'id': SField(SString(minLength: 1, maxLength: 40, pattern: Patterns.assetId)),
    'file': SField(_fileRef),
  }),
  maxItems: 2000,
  uniqueKey: 'id',
);

const SArray _voFiles = SArray(
  SObject(<String, SField>{
    'id': SField(SString(minLength: 1, maxLength: 80, pattern: Patterns.voId)),
    'file': SField(_fileRef),
  }),
  maxItems: 4000,
  uniqueKey: 'id',
);

const SObject manifestSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.manifest)),
  'id': SField(SString(minLength: 3, maxLength: 41, pattern: Patterns.packId)),
  'version': SField(SString(minLength: 5, maxLength: 11, pattern: Patterns.semver)),
  'minAppVersion': SField(SString(minLength: 5, maxLength: 11, pattern: Patterns.semver)),
  // Template name to the version it needs. Names are not limited to the ones this app knows: a pack
  // that needs a newer template is still read this far, so it can be kept hidden instead of crashing.
  'templates': SField(
    SMap(
      SString(minLength: 3, maxLength: 5, pattern: Patterns.templateVersion),
      keyPattern: r'[a-z][a-z0-9_]{1,30}',
      maxEntries: 40,
    ),
  ),
  'files': SField(_fileList),
  'assets': SField(_assetFiles),
  'vo': SField(_voFiles),
  'voPending': SField(SArray(_vo, maxItems: 4000)),
  'entries': SField(
    SObject(<String, SField>{
      'activities': SField(SArray(_id, maxItems: 1500)),
      'lessons': SField(SArray(_id, maxItems: 400)),
      'skills': SField(SArray(_skill, maxItems: 600)),
      'misconceptions': SField(SArray(_tag, maxItems: 400)),
      // Characters and mouth cues (M4); absent in packs that have none.
      'characters': SField(SArray(_characterId, maxItems: 20), required: false),
      'cues': SField(
        SArray(SString(minLength: 1, maxLength: 80, pattern: Patterns.voId), maxItems: 4000),
        required: false,
      ),
    }),
  ),
});

// ---- characters and mouth cues ----

const List<String> characterRoles = <String>[
  'guide_tutor',
  'map_companion',
  'celebration_cameo',
  'activity_helper',
  'sticker',
];

/// The states every character has an image for, and the optional extras.
const List<String> requiredCharacterImages = <String>[
  'idle',
  'talk_closed',
  'talk_open',
  'celebrate',
  'think',
  'listen',
  'encourage',
];
const List<String> optionalCharacterImages = <String>['surprised', 'sleepy', 'blink', 'wave'];

final SObject characterSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.character)),
  'id': SField(_characterId),
  'review': _review,
  // The Hebrew name, with niqqud. A family character's name may carry the child's name as {name}.
  'name': SField(
    SObject(<String, SField>{
      'he': SField(SString(minLength: 2, maxLength: 60)),
      'gender': SField(SEnum(<String>['m', 'f'])),
    }),
  ),
  'roles': SField(SArray(SEnum(characterRoles), minItems: 1, maxItems: 5)),
  'images': SField(
    SObject(<String, SField>{
      for (final String k in requiredCharacterImages) k: SField(_asset),
      for (final String k in optionalCharacterImages) k: SField(_asset, required: false),
    }),
  ),
  // Where the mouth is, as a share of the picture's width and height.
  'mouth': SField(SArray(SNum(min: 0, max: 1), minItems: 2, maxItems: 2)),
  'canvas': SField(
    SObject(<String, SField>{
      'width': SField(SInt(min: 64, max: 4096)),
      'height': SField(SInt(min: 64, max: 4096)),
    }),
  ),
  'distribution': SField(SEnum(<String>['bundled', 'personal'])),
  'personalUseOnly': SField(SBool()),
  'palette': SField(
    SObject(<String, SField>{
      'dominant': SField(SString(minLength: 7, maxLength: 7, pattern: r'#[0-9A-Fa-f]{6}')),
    }),
  ),
});

/// When the mouth of a spoken line is open: `t` in milliseconds from the start, `o` 1 open or 0 closed.
const SObject cueSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.cue)),
  'id': SField(SString(minLength: 1, maxLength: 80, pattern: Patterns.voId)),
  'cues': SField(
    SArray(
      SObject(<String, SField>{'t': SField(SInt(min: 0, max: 120000)), 'o': SField(SInt(min: 0, max: 1))}),
      maxItems: 600,
    ),
  ),
});

// ---- skills, misconceptions, lessons ----

const SObject skillSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.skill)),
  'id': SField(_skill),
  'review': _review,
  'domain': SField(SEnum(domains)),
  'band': SField(SEnum(bands)),
  'title': SField(_caption),
  'prerequisites': SField(
    SArray(
      SObject(<String, SField>{'skill': SField(_skill), 'weight': SField(SNum(min: 0, max: 1))}),
      maxItems: 10,
      uniqueKey: 'skill',
    ),
  ),
  'representations': SField(SArray(SEnum(representations), minItems: 1, maxItems: 5)),
  'misconceptions': SField(SArray(_tag, maxItems: 20)),
  'retention': SField(
    SObject(<String, SField>{
      'targetRetention': SField(SNum(min: 0.5, max: 1)),
      'initialStabilityDays': SField(SNum(min: 0, max: 30)),
    }),
  ),
  // The world (M8, pack 0.3.0): which drawing grows for this skill (an id of the app's world art), and one line for the
  // child, with niqqud, of what they can do (shown on the card of a trophy).
  'worldObject': SField(SString(minLength: 2, maxLength: 24, pattern: Patterns.worldObject), required: false),
  'childLine': SField(_caption, required: false),
  // Learning engine (M3). A core skill (three or more skills depend on it) needs more evidence for mastery.
  'core': SField(SBool(), required: false),
  'masteryRequires': SField(
    SObject(<String, SField>{
      'successes': SField(SInt(min: 1, max: 20), required: false),
      'days': SField(SInt(min: 1, max: 30), required: false),
      'representations': SField(SInt(min: 1, max: 5), required: false),
      'checks': SField(SInt(min: 0, max: 5), required: false),
    }),
    required: false,
  ),
});

const SObject misconceptionSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.misconception)),
  'id': SField(_tag),
  'review': _review,
  'skills': SField(SArray(_skill, minItems: 1, maxItems: 10)),
  'parentText': SField(SString(minLength: 1, maxLength: 240)),
  // Something a parent can do at home in about five minutes (M7, pack 0.3.0). Plain Hebrew for the parent.
  'homeActivity': SField(_caption, required: false),
  'repairActivities': SField(SArray(_id, maxItems: 10)),
  'preferredRepresentations': SField(SArray(SEnum(representations), maxItems: 5)),
});

const SObject lessonSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.lesson)),
  'id': SField(_id),
  'review': _review,
  'revision': SField(_revision),
  'band': SField(SEnum(bands)),
  'title': SField(_caption),
  'skills': SField(SArray(_skill, minItems: 1, maxItems: 10)),
  'items': SField(SArray(_id, minItems: 1, maxItems: 12)),
  'estimatedMinutes': SField(SInt(min: 1, max: 30)),
  'celebration': SField(_spoken),
  // The place of the lesson on the path of its land (M9): the island plays the first lesson, in this order, that the
  // child has not finished yet. Lessons without one come last.
  'sequence': SField(SInt(min: 1, max: 500), required: false),
});

// ---- activities ----

const SObject _sprite = SObject(<String, SField>{'sprite': SField(_asset)});

/// What lies on one pan of a balance: groups of one picture each (`3 + 4` is two groups), and the weight of one of each.
const SObject _pan = SObject(<String, SField>{
  'groups': SField(
    SArray(
      SObject(<String, SField>{
        'sprite': SField(_asset),
        'count': SField(SInt(min: 1, max: 12)),
        // How many blocks one of them weighs; 1 when it is not given.
        'weight': SField(SInt(min: 1, max: 9), required: false),
      }),
      minItems: 0,
      maxItems: 3,
    ),
  ),
});

/// A face on the matching template (T16): a picture (a set, when `count` is more than one) or a numeral, with its label.
const SObject _face = SObject(<String, SField>{
  'id': SField(SString(minLength: 1, maxLength: 8, pattern: r'[a-z][a-z0-9]{0,7}')),
  'sprite': SField(_asset, required: false),
  'count': SField(SInt(min: 1, max: 20), required: false),
  'numeral': SField(SInt(min: 0, max: 100), required: false),
  // A coin or a note of the shop, drawn with its value (the money template's kinds).
  'coin': SField(
    SEnum(<String>['a10', 'h50', 's1', 's2', 's5', 's10', 'n20', 'n50', 'n100', 'n200']),
    required: false,
  ),
  'label': SField(SString(minLength: 1, maxLength: 80)),
});

/// Some of a thing, drawn as a group (tap_answer 1.1): a set to count, or an answer that is a set to choose.
/// [scale] makes each picture larger or smaller without changing how many there are.
const SObject _spriteSet = SObject(<String, SField>{
  'sprite': SField(_asset),
  'count': SField(SInt(min: 0, max: 20)),
  'arrangement': SField(SEnum(<String>['line', 'scatter', 'dice', 'ten_frame']), required: false),
  'seed': SField(SInt(min: 0, max: 9999), required: false),
  'scale': SField(SNum(min: 0.5, max: 1.6), required: false),
});

/// Extra words a child may say for an option, with or without niqqud (a word the number or label does not give).
const SField _speechWords = SField(
  SArray(SString(minLength: 1, maxLength: 40), minItems: 1, maxItems: 8),
  required: false,
);

SObject _answerOptions(Map<String, SField> optionFields) => SObject(<String, SField>{
  'type': const SField(SConst('choice')),
  'options': SField(SArray(SObject(optionFields), minItems: 2, maxItems: 4, uniqueKey: 'id')),
  'correct': const SField(_optionId),
  'shuffle': const SField(SBool()),
  'unsureAllowed': const SField(SBool()),
});

const SObject _feedback = SObject(<String, SField>{
  'correct': SField(_spoken),
  'incorrect': SField(
    SArray(
      SObject(<String, SField>{
        // "default", or "misconception:" followed by a tag from the catalogue.
        'when': SField(
          SString(minLength: 7, maxLength: 40, pattern: r'default|misconception:M-[A-Z]{2,5}-[A-Z0-9]{2,12}'),
        ),
        'vo': SField(_vo),
        'caption': SField(_caption),
      }),
      minItems: 1,
      maxItems: 8,
    ),
  ),
  'unsure': SField(_spoken),
});

const SArray _hints = SArray(
  SObject(<String, SField>{
    'level': SField(SInt(min: 1, max: 3)),
    'action': SField(
      SEnum(<String>[
        'replay_prompt_slow',
        'highlight_objects_sequentially',
        'show_fingers',
        'worked_example',
      ]),
    ),
    'vo': SField(_vo),
    'caption': SField(_caption),
  }),
  maxItems: 3,
  uniqueKey: 'level',
);

Map<String, SField> _base(Map<String, SField> templateParts) => <String, SField>{
  'schema': const SField(SConst(SchemaIds.activity)),
  'id': const SField(_id),
  'review': _review,
  'revision': const SField(_revision),
  'template': const SField(
    SEnum(<String>[
      'tap_answer',
      'count_tap',
      'give_n',
      'flash',
      'sort_drag',
      'build_pattern',
      'robot_path',
      'shape_builder',
      'number_line',
      'balance',
      'spot_error',
      'match_pairs',
      'shop_pay',
      'clock_set',
      'trace',
    ]),
  ),
  'templateVersion': const SField(SString(minLength: 3, maxLength: 5, pattern: Patterns.templateVersion)),
  'domain': const SField(SEnum(domains)),
  'band': const SField(SEnum(bands)),
  'skills': const SField(
    SArray(
      SObject(<String, SField>{'id': SField(_skill), 'weight': SField(SNum(min: 0, max: 1))}),
      minItems: 1,
      maxItems: 4,
      uniqueKey: 'id',
    ),
  ),
  'purpose': const SField(SEnum(<String>['learn', 'practice', 'probe', 'repair', 'check'])),
  // The misconception this item is built to expose (used by the session builder after a repair).
  'contradicts': const SField(_tag, required: false),
  'checkType': const SField(
    SEnum(<String>['practice', 'transfer', 'reverse', 'error_spotting', 'explain_back', 'predict']),
  ),
  'representation': const SField(SEnum(representations)),
  'variantGroup': const SField(SString(minLength: 3, maxLength: 60, pattern: r'[a-z0-9._-]+')),
  'difficulty': const SField(SObject(<String, SField>{'authored': SField(SNum(min: 0, max: 1))})),
  'prompt': const SField(
    SObject(<String, SField>{
      'vo': SField(_vo),
      'caption': SField(_caption),
      'replayButton': SField(SBool()),
    }),
  ),
  ...templateParts,
  'feedback': const SField(_feedback),
  'hints': const SField(_hints),
  'scoring': const SField(
    SObject(<String, SField>{
      'maxAttempts': SField(SInt(min: 1, max: 5)),
      'creditByHintLevel': SField(SArray(SNum(min: 0, max: 1), minItems: 4, maxItems: 4)),
    }),
  ),
  'tutor': const SField(
    SObject(<String, SField>{
      'llmAllowed': SField(SBool()),
      'goal': SField(SString(minLength: 5, maxLength: 200)),
      'mustNotRevealBeforeHint': SField(SInt(min: 0, max: 3)),
    }),
  ),
  'a11y': const SField(SObject(<String, SField>{'altText': SField(SString(minLength: 1, maxLength: 240))})),
};

const SArray _traceClassifiers = SArray(
  SObject(<String, SField>{
    'when': SField(SEnum(<String>['same_object_tapped_twice', 'object_never_tapped'])),
    'misconception': SField(_tag),
  }),
  maxItems: 4,
);

/// The schema of an activity of the given template, or null for a template this app does not know.
SObject? activitySchemaFor(String template) => switch (template) {
  'tap_answer' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // A group shown above the answers, to be counted or compared (1.1).
          'group': SField(_spriteSet, required: false),
          // Two groups side by side, for a comparison (1.1).
          'group2': SField(_spriteSet, required: false),
          // A numeral shown large on the stage, for "find the set that has this many" (1.1).
          'numeral': SField(SInt(min: 0, max: 100), required: false),
          // Picture answers on tiles below the stage instead of on it (1.1): when the pictures are the whole point.
          'optionsOnTiles': SField(SBool(), required: false),
          // A chart to read (1.2): columns of pictures, each a category with how many it has (a pictograph).
          'chart': SField(
            SArray(
              SObject(<String, SField>{'sprite': SField(_asset), 'count': SField(SInt(min: 0, max: 8))}),
              minItems: 2,
              maxItems: 5,
            ),
            required: false,
          ),
          // A row of pictures with an optional gap ("?") to fill, for patterns and order (1.1). A cell may also be a number (`n:7`)
          // or a sign (`op:+`), for a number sentence.
          'row': SField(
            SArray(
              SString(
                minLength: 1,
                maxLength: 46,
                pattern: r'asset:[a-z0-9_]{1,40}|\?|n:[0-9]{1,3}|op:[+=x:-]',
              ),
              minItems: 2,
              maxItems: 8,
            ),
            required: false,
          ),
        }),
      ),
      'answer': SField(
        _answerOptions(<String, SField>{
          'id': const SField(_optionId),
          // An option is a picture, a numeral, or a set (1.1): exactly one of the three.
          'sprite': const SField(_asset, required: false),
          'numeral': const SField(SInt(min: 0, max: 100), required: false),
          'set': const SField(_spriteSet, required: false),
          'label': const SField(SString(minLength: 1, maxLength: 80)),
          'speech': _speechWords,
          'misconception': const SField(_tag, required: false),
        }),
      ),
    }),
  ),
  'count_tap' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'objects': SField(
            SObject(<String, SField>{
              'sprite': SField(_asset),
              'litSprite': SField(_asset),
              'count': SField(SInt(min: 1, max: 20)),
              'arrangement': SField(SEnum(<String>['line', 'scatter'])),
              'onTap': SField(SEnum(<String>['fly_to_target', 'glow'])),
              'seed': SField(SInt(min: 0, max: 9999)),
            }),
          ),
          'target': SField(_sprite),
        }),
      ),
      'answer': SField(
        _answerOptions(<String, SField>{
          'id': const SField(_optionId),
          'value': const SField(SInt(min: 0, max: 20)),
          'speech': _speechWords,
          'misconception': const SField(_tag, required: false),
        }),
      ),
      // Asked once every object has been touched: "how many?".
      'answerPrompt': const SField(_spoken),
      'traceClassifiers': const SField(_traceClassifiers),
    }),
  ),
  // T14: a group is shown for a moment and covered; the child says how many without counting. Every option is a numeral.
  'flash' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'group': SField(_spriteSet),
          // How long the group stays in view, in milliseconds.
          'flashMs': SField(SInt(min: 400, max: 3000)),
        }),
      ),
      'answer': SField(
        _answerOptions(<String, SField>{
          'id': const SField(_optionId),
          'numeral': const SField(SInt(min: 0, max: 100)),
          'speech': _speechWords,
          'misconception': const SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T03: pictures are dragged (or tapped) into bins. `share` mode deals them between two friends until both have the same.
  'sort_drag' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'bins': SField(
            SArray(
              SObject(<String, SField>{
                'id': SField(SString(minLength: 2, maxLength: 2, pattern: r'b[0-9]')),
                'sprite': SField(_asset),
                'count': SField(SInt(min: 1, max: 6), required: false),
                'label': SField(SString(minLength: 1, maxLength: 40)),
              }),
              minItems: 2,
              maxItems: 3,
              uniqueKey: 'id',
            ),
          ),
          'items': SField(
            SArray(
              SObject(<String, SField>{
                'id': SField(SString(minLength: 2, maxLength: 3, pattern: r'i[0-9]{1,2}')),
                'sprite': SField(_asset),
                'bin': SField(SString(minLength: 2, maxLength: 2, pattern: r'b[0-9]'), required: false),
              }),
              minItems: 2,
              maxItems: 8,
              uniqueKey: 'id',
            ),
          ),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('sort')),
          'mode': SField(SEnum(<String>['sort', 'share'])),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T07: a robot on a grid is moved to the flag with arrows, one step at a time (`direct`) or by planning the steps
  // and then pressing go (`plan`). Directions are the screen's own (up is up) and never mirror.
  'robot_path' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'cols': SField(SInt(min: 3, max: 6)),
          'rows': SField(SInt(min: 2, max: 4)),
          'robot': SField(
            SObject(<String, SField>{
              'col': SField(SInt(min: 0, max: 5)),
              'row': SField(SInt(min: 0, max: 3)),
            }),
          ),
          'goal': SField(
            SObject(<String, SField>{
              'col': SField(SInt(min: 0, max: 5)),
              'row': SField(SInt(min: 0, max: 3)),
            }),
          ),
          'robotSprite': SField(_asset),
          'goalSprite': SField(_asset),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('path')),
          'mode': SField(SEnum(<String>['direct', 'plan'])),
          'maxSteps': SField(SInt(min: 1, max: 8)),
          'solution': SField(
            SArray(SEnum(<String>['up', 'down', 'left', 'right']), minItems: 1, maxItems: 8),
          ),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T09: a number line from `from` to `to`, drawn left to right whatever the language. `place`: put the marker on a number.
  // `jump`: the marker starts on a number and jumps; the child says where it lands.
  'number_line' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'from': SField(SInt(min: 0, max: 100)),
          'to': SField(SInt(min: 1, max: 100)),
          // The marker's picture and where it starts (a number on the line); none in `place` mode.
          'markerSprite': SField(_asset),
          'start': SField(SInt(min: 0, max: 100), required: false),
          // The hops of a `jump`: by how much each one goes (positive to the right, negative to the left).
          'hops': SField(SArray(SInt(min: -20, max: 20), maxItems: 6), required: false),
          // The numbers that carry a written numeral; the other ticks are plain marks.
          'labels': SField(SArray(SInt(min: 0, max: 100), maxItems: 21)),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('line')),
          'mode': SField(SEnum(<String>['place', 'jump'])),
          'target': SField(SInt(min: 0, max: 100)),
          'misconception': SField(_tag, required: false),
          // The tag for a child who runs the line from right to left (the mirror of the right answer).
          'mirrorMisconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T08: a balance scale. `compare`: which pan is heavier, or are they the same? `balance`: add blocks to the empty pan until
  // the scale is level.
  'balance' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'left': SField(_pan),
          'right': SField(_pan),
          // In `balance` mode the sprite of the blocks that the child adds.
          'blockSprite': SField(_asset, required: false),
          // The beam stays level until the child has answered (for sums that are being compared, not weighed).
          'hideTilt': SField(SBool(), required: false),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('scale')),
          'mode': SField(SEnum(<String>['compare', 'balance'])),
          // `compare`: left, right or same. `balance`: how many blocks the child must add (as a number).
          'result': SField(SString(minLength: 1, maxLength: 5, pattern: r'left|right|same|[0-9]{1,2}')),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T21: a row made by a friend that has one mistake in it; the child touches the mistake.
  'spot_error' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // Each cell is a picture (`asset:`), a number (`n:7`), an arrow (`dir:up`) or a sign (`op:+`).
          'cells': SField(
            SArray(
              SString(
                minLength: 3,
                maxLength: 46,
                pattern: r'asset:[a-z0-9_]{1,40}|n:[0-9]{1,3}|dir:(up|down|left|right)|op:[+=x:-]',
              ),
              minItems: 3,
              maxItems: 9,
            ),
          ),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('spot')),
          'wrong': SField(SInt(min: 0, max: 8)),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T10: a picture made of shapes is shown as silhouettes; the child puts each shape in its place (by tapping or dragging) and
  // it snaps in, turned the right way.
  'shape_builder' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // The picture's width divided by its height; the slots are placed in that picture, as shares of its width and height.
          'aspect': SField(SNum(min: 0.3, max: 3)),
          'slots': SField(
            SArray(
              SObject(<String, SField>{
                'id': SField(SString(minLength: 2, maxLength: 3, pattern: r's[0-9]{1,2}')),
                'sprite': SField(_asset),
                'x': SField(SNum(min: 0, max: 1)),
                'y': SField(SNum(min: 0, max: 1)),
                'w': SField(SNum(min: 0.05, max: 1)),
                'h': SField(SNum(min: 0.05, max: 1)),
                'rot': SField(SInt(min: -180, max: 180), required: false),
              }),
              minItems: 2,
              maxItems: 8,
              uniqueKey: 'id',
            ),
          ),
          // Pieces that belong nowhere in the picture, so that choosing is a choice.
          'decoys': SField(SArray(_asset, maxItems: 2), required: false),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('shapes')),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T05: the child fills the places of a pattern from a palette, by tapping or dragging.
  'build_pattern' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // The pattern to copy, shown above the places.
          'model': SField(SArray(_asset, maxItems: 8), required: false),
          'slots': SField(SInt(min: 2, max: 8)),
          'palette': SField(SArray(_asset, minItems: 2, maxItems: 6)),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('build')),
          'sequence': SField(SArray(_asset, minItems: 2, maxItems: 8)),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  'give_n' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'source': SField(
            SObject(<String, SField>{'sprite': SField(_asset), 'count': SField(SInt(min: 1, max: 20))}),
          ),
          'target': SField(_sprite),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('give')),
          'n': SField(SInt(min: 1, max: 20)),
          'classifiers': SField(
            SArray(
              SObject(<String, SField>{
                'when': SField(SEnum(<String>['took_all', 'took_more', 'took_fewer'])),
                'misconception': SField(_tag),
              }),
              maxItems: 3,
            ),
          ),
        }),
      ),
    }),
  ),
  // T16: two rows of faces; the child touches one in the top row and one in the bottom row, and a right pair stays together.
  // A face is a picture (with a count, for a set) or a numeral.
  'match_pairs' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'left': SField(SArray(_face, minItems: 2, maxItems: 5)),
          'right': SField(SArray(_face, minItems: 2, maxItems: 5)),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('match')),
          'pairs': SField(
            SArray(
              SObject(<String, SField>{
                'left': SField(SString(minLength: 1, maxLength: 8, pattern: r'[a-z][a-z0-9]{0,7}')),
                'right': SField(SString(minLength: 1, maxLength: 8, pattern: r'[a-z][a-z0-9]{0,7}')),
              }),
              minItems: 2,
              maxItems: 5,
            ),
          ),
          'misconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T17: a price, and a purse of coins and notes. The child touches coins to put them on the counter and presses pay.
  // Values are in agorot (100 = one shekel).
  'shop_pay' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'itemSprite': SField(_asset),
          'itemCount': SField(SInt(min: 1, max: 10)),
          'price': SField(SInt(min: 10, max: 50000)),
          'purse': SField(
            SArray(
              SObject(<String, SField>{
                'kind': SField(
                  SEnum(<String>['a10', 'h50', 's1', 's2', 's5', 's10', 'n20', 'n50', 'n100', 'n200']),
                ),
                'count': SField(SInt(min: 1, max: 8)),
              }),
              minItems: 2,
              maxItems: 8,
              uniqueKey: 'kind',
            ),
          ),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('pay')),
          'misconception': SField(_tag, required: false),
          // The tag for a child who puts as many coins as the price says (three coins for three shekels).
          'countMisconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T18: set the hands of an analog clock to a time. Whole hours (`minute` 0) or half hours (30); the long hand follows.
  'clock_set' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'hour': SField(SInt(min: 1, max: 12)),
          'minute': SField(SInt(min: 0, max: 30)),
          'startHour': SField(SInt(min: 1, max: 12)),
          'startHalf': SField(SBool(), required: false),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('clock')),
          'misconception': SField(_tag, required: false),
          // The tag for a child who reads the long hand as the hour (a whole hour set to 12).
          'handsMisconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  // T04: trace a numeral or a shape. Points are in a 100 x 100 box; a stroke is read from its first point to its last.
  'trace' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'strokes': SField(
            SArray(
              SArray(SArray(SInt(min: 0, max: 100), minItems: 2, maxItems: 2), minItems: 2, maxItems: 60),
              minItems: 1,
              maxItems: 3,
            ),
          ),
          // `full`: the dotted path is drawn. `start`: only the starting dot and the first direction.
          'guide': SField(SEnum(<String>['full', 'start'])),
          'tolerance': SField(SInt(min: 6, max: 24)),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('trace')),
          'misconception': SField(_tag, required: false),
          // The tag for a child who traces the right path from the wrong end.
          'directionMisconception': SField(_tag, required: false),
        }),
      ),
    }),
  ),
  _ => null,
};

/// The file an author writes next to the content files of a pack (`pack.json`); the pack builder reads
/// it, works out the rest of the manifest (files, hashes, entries, template versions) and signs.
const SObject packSourceSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.packSource)),
  'id': SField(SString(minLength: 3, maxLength: 41, pattern: Patterns.packId)),
  'version': SField(SString(minLength: 5, maxLength: 11, pattern: Patterns.semver)),
  'minAppVersion': SField(SString(minLength: 5, maxLength: 11, pattern: Patterns.semver)),
  'assets': SField(_assetFiles),
  'vo': SField(_voFiles),
});

/// Every document schema by name, for the generator of JSON Schema files.
Map<String, Schema> get allSchemas => <String, Schema>{
  'pack-source': packSourceSchema,
  'manifest': manifestSchema,
  'character': characterSchema,
  'cue': cueSchema,
  'skill': skillSchema,
  'misconception': misconceptionSchema,
  'lesson': lessonSchema,
  'activity.tap_answer': activitySchemaFor('tap_answer')!,
  'activity.count_tap': activitySchemaFor('count_tap')!,
  'activity.give_n': activitySchemaFor('give_n')!,
  'activity.flash': activitySchemaFor('flash')!,
  'activity.sort_drag': activitySchemaFor('sort_drag')!,
  'activity.build_pattern': activitySchemaFor('build_pattern')!,
  'activity.robot_path': activitySchemaFor('robot_path')!,
  'activity.shape_builder': activitySchemaFor('shape_builder')!,
  'activity.number_line': activitySchemaFor('number_line')!,
  'activity.balance': activitySchemaFor('balance')!,
  'activity.spot_error': activitySchemaFor('spot_error')!,
  'activity.match_pairs': activitySchemaFor('match_pairs')!,
  'activity.shop_pay': activitySchemaFor('shop_pay')!,
  'activity.clock_set': activitySchemaFor('clock_set')!,
  'activity.trace': activitySchemaFor('trace')!,
};
