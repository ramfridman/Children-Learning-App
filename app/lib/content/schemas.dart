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
}

/// The four kinds of document in a pack, by the `schema` field of the file.
abstract final class SchemaIds {
  static const String manifest = 'manifest/v1';
  static const String packSource = 'pack-source/v1';
  static const String activity = 'activity/v1';
  static const String lesson = 'lesson/v1';
  static const String skill = 'skill/v1';
  static const String misconception = 'misconception/v1';
}

/// Templates this app can play, and the version of each (what `templateVersion` must not exceed).
const Map<String, String> supportedTemplates = <String, String>{
  'tap_answer': '1.0',
  'count_tap': '1.0',
  'give_n': '1.0',
};

const List<String> domains = <String>['numbers', 'colors', 'shapes', 'logic', 'cs', 'math'];
const List<String> bands = <String>['A', 'B', 'C'];
const List<String> representations = <String>['concrete', 'pictorial', 'story', 'embodied', 'symbolic'];

const SString _id = SString(minLength: 3, maxLength: 81, pattern: Patterns.activityId);
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
  maxItems: 400,
  uniqueKey: 'name',
);

const SString _fileRef = SString(minLength: 1, maxLength: 101, pattern: Patterns.fileName);

const SArray _assetFiles = SArray(
  SObject(<String, SField>{
    'id': SField(SString(minLength: 1, maxLength: 40, pattern: Patterns.assetId)),
    'file': SField(_fileRef),
  }),
  maxItems: 400,
  uniqueKey: 'id',
);

const SArray _voFiles = SArray(
  SObject(<String, SField>{
    'id': SField(SString(minLength: 1, maxLength: 80, pattern: Patterns.voId)),
    'file': SField(_fileRef),
  }),
  maxItems: 400,
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
  'voPending': SField(SArray(_vo, maxItems: 400)),
  'entries': SField(
    SObject(<String, SField>{
      'activities': SField(SArray(_id, maxItems: 200)),
      'lessons': SField(SArray(_id, maxItems: 50)),
      'skills': SField(SArray(_skill, maxItems: 100)),
      'misconceptions': SField(SArray(_tag, maxItems: 100)),
    }),
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
});

// ---- activities ----

const SObject _sprite = SObject(<String, SField>{'sprite': SField(_asset)});

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
  'template': const SField(SEnum(<String>['tap_answer', 'count_tap', 'give_n'])),
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
      'scene': const SField(SObject(<String, SField>{'background': SField(_asset, required: false)})),
      'answer': SField(
        _answerOptions(<String, SField>{
          'id': const SField(_optionId),
          'sprite': const SField(_asset),
          'label': const SField(SString(minLength: 1, maxLength: 80)),
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
              'count': SField(SInt(min: 1, max: 10)),
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
          'misconception': const SField(_tag, required: false),
        }),
      ),
      // Asked once every object has been touched: "how many?".
      'answerPrompt': const SField(_spoken),
      'traceClassifiers': const SField(_traceClassifiers),
    }),
  ),
  'give_n' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'source': SField(
            SObject(<String, SField>{'sprite': SField(_asset), 'count': SField(SInt(min: 1, max: 12))}),
          ),
          'target': SField(_sprite),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('give')),
          'n': SField(SInt(min: 1, max: 12)),
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
  'skill': skillSchema,
  'misconception': misconceptionSchema,
  'lesson': lessonSchema,
  'activity.tap_answer': activitySchemaFor('tap_answer')!,
  'activity.count_tap': activitySchemaFor('count_tap')!,
  'activity.give_n': activitySchemaFor('give_n')!,
};
