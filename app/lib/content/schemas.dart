import '../engine/course.dart';
import 'schema.dart';

// The schemas of a content pack. Ids, tags and references use fixed shapes so that a file can never
// carry a path, a markup fragment or a command: every value is a short plain string, a number or a
// listed word. Text for the child is Hebrew only (`t` is always "he") and is shown as plain text.

abstract final class Patterns {
  static const String packId = r'[a-z0-9][a-z0-9-]{2,40}';
  static const String semver = r'\d{1,3}\.\d{1,3}\.\d{1,3}';
  static const String templateVersion = r'\d{1,2}\.\d{1,2}';
  static const String activityId = r'[a-z0-9][a-z0-9._-]{2,80}';
  // `ENG-B-19.G1`: the group of a skill taught group by group (a dotted id, docs/languages/frame.md section 3.3.2).
  static const String skillId = r'[A-Z]{2,5}-[ABC]-\d{2}(?:\.[A-Z][0-9]{1,2})?';
  // `M-CNT-DOUBLE` in the existing lands; `eng.ph.dir` (course, strand, slug) in a language course.
  static const String tag = r'M-[A-Z]{2,5}-[A-Z0-9]{2,12}|[a-z]{3}\.[a-z]{2,4}\.[a-z0-9_]{1,24}';
  static const String assetRef = r'asset:[a-z0-9_]{1,40}';
  static const String voRef = r'vo:[a-z0-9_.]{1,80}';
  static const String assetId = r'[a-z0-9_]{1,40}';
  static const String voId = r'[a-z0-9_.]{1,80}';
  static const String fileName = r'[A-Za-z0-9][A-Za-z0-9._-]{0,100}';
  static const String sha256 = r'[0-9a-f]{64}';
  static const String optionId = r'o[0-9]{1,2}';
  static const String worldObject = r'[a-z][a-z0-9-]{1,23}';

  // A letter bundle and a gate: the course, a dot and a short name (`eng.g1`, `eng.oral`).
  static const String bundle = r'[a-z]{3}\.[a-z0-9_]{1,19}';
  static const String gateId = r'[a-z]{3}\.[a-z0-9_]{1,19}';

  // The placement document of a course: `eng.placement`.
  static const String placementId = r'[a-z]{3}\.placement';

  // A stroke set (`latin`, `cyrillic`, `hebrew-print`, `hebrew-script`) and a form of one (`latin.a.cap`, `hebrew-print.mem-final`).
  static const String strokeSet = r'[a-z]+(?:-[a-z]+)?';
  static const String strokeForm = r'[a-z]+(?:-[a-z]+)?\.[a-z0-9]+(?:-[a-z0-9]+)*(?:\.[a-z]+)?';
}

/// The four kinds of document in a pack, by the `schema` field of the file.
abstract final class SchemaIds {
  static const String manifest = 'manifest/v1';
  static const String packSource = 'pack-source/v1';
  static const String character = 'character-lite/v1';
  static const String cue = 'cue/v1';
  static const String activity = 'activity/v1';
  static const String lesson = 'lesson/v1';
  static const String gate = 'gate/v1';
  static const String placement = 'placement/v1';
  static const String skill = 'skill/v1';
  static const String misconception = 'misconception/v1';

  /// The stroke data of a script (docs/languages/strokes.md); a pack document `strokes.<set>.json`.
  static const String strokes = 'nitznutz.strokes/1';
}

/// Templates this app can play, and the version of each (what `templateVersion` must not exceed).
const Map<String, String> supportedTemplates = <String, String>{
  // 1.4: the language fields of LS01 (L5-1: stem, cloze, tap-all, text faces) and, for M10 step 0.4, stage pictures, the row signs `<` `>`
  // `(` `)`, numbers to 10,000, five choices in Band C and the number answer. One version carries both. 1.5: the own-name answer of Hebrew
  // Band A (`answer.type` `name`): the options are made on the device from the child's first name.
  'tap_answer': '1.5',
  // 1.1: the print-direction modes of Hebrew Band A, `zones` and `follow` (a page that shows its text).
  'story': '1.1',
  'listen_do': '1.0',
  'sing_along': '1.0',
  'puppet_talk': '1.0',
  'sound_boxes': '1.0',
  'count_tap': '1.1',
  'give_n': '1.0',
  'flash': '1.0',
  'sort_drag': '1.1',
  'build_pattern': '1.1',
  'robot_path': '1.0',
  'shape_builder': '1.0',
  'number_line': '1.0',
  'balance': '1.0',
  // 1.1: the language fields of L5-1 (text cells, the model picture) and, for M10, the signs `<` `>` `(` `)` and numbers to 10,000 in a cell.
  'spot_error': '1.1',
  'match_pairs': '1.1',
  'shop_pay': '1.0',
  'clock_set': '1.0',
  'trace': '2.0',
  'say_it': '1.0',
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

const List<String> domains = <String>['numbers', 'colors', 'shapes', 'logic', 'cs', 'math', languagesDomain];

/// The domain of every skill of a language course; the course itself says which language.
const String languagesDomain = Course.languagesDomain;
const List<String> bands = <String>['A', 'B', 'C'];

/// The parent switches a gate may name (docs/languages/frame.md section 1.4): the English "oral only" keeps its gate closed,
/// the Russian "letters before 5" opens its gate.
const List<String> gateSwitchNames = <String>['oralOnly', 'lettersBefore5'];

/// The routes of a Russian child (docs/languages/frame.md section 3.3.7).
const List<String> courseRoutes = <String>['new', 'heritage', 'reader'];
const List<String> representations = <String>['concrete', 'pictorial', 'story', 'embodied', 'symbolic'];

/// The kinds of misconception tag of a language course (docs/languages/frame.md section 4.1).
const List<String> tagKinds = <String>['diagnostic', 'on_the_way', 'accent', 'practice'];

/// The families of misconception tags of a language course (docs/languages/frame.md section 4.1).
const List<String> tagFamilies = <String>[
  'DIR',
  'NAME',
  'SHAPE',
  'STROKE',
  'CONTRAST',
  'SEGMENT',
  'RHYME',
  'VOWEL',
  'CODE',
  'GRAMMAR',
  'PRINT',
  'GUESS',
  'MEANING',
  'ACCENT',
  'FLUENCY',
];

/// The only four things a scripted personal turn may ask (docs/languages/frame.md section 5.2): the child's name, age, likes and family.
/// Never where the child lives, an address, a city, the gan or school, a phone number, photos or feelings about home.
const List<String> personalTopics = <String>['name', 'age', 'likes', 'family'];

/// The sides of a two-way skill (yes or no, same or different), and the pairs they come in.
const List<String> poles = <String>['yes', 'no', 'same', 'different'];

/// The routes of a child in a language course (the parent's setting): a new learner, a heritage speaker, a reader. A child whose route is
/// not set yet is served as a new learner.
const List<String> languageRoutes = <String>['new', 'heritage', 'reader'];

/// The routes a lesson's `teach` set may name. The reader is served as a new learner or as a heritage speaker before the lesson is built
/// (`servedRoute`), so it is no value here. What each route may be shown is held by the validator: a `teach` set only the new learner
/// (a heritage speaker already knows the words and is never shown a teach screen), a `hear` set only the heritage speaker.
const List<String> teachRoutes = <String>['new', 'heritage'];

/// The two kinds of set a lesson's `teach` holds: teach screens (the new words, echo) and hearing screens (one hearing of a word, no demand).
const List<String> teachModes = <String>['teach', 'hear'];

/// How a skill serves a child whose route is `reader`: by its oral route (the placement's strand 1 decides) or as a heritage speaker.
const List<String> readerServes = <String>['oral', 'heritage'];

/// The order a say step is played in on a route: the model first and then the child (echo), or the picture and the question first, and the
/// model after a pause (picture).
const List<String> sayOrders = <String>['echo', 'picture'];

const SString _id = SString(minLength: 3, maxLength: 81, pattern: Patterns.activityId);

/// Every answer carries its lesson id, and `sync-push` takes at most 40 characters (SEC-12).
const SString _lessonId = SString(minLength: 3, maxLength: 40, pattern: Patterns.activityId);
const SString _characterId = SString(minLength: 3, maxLength: 41, pattern: Patterns.packId);
const SString _tag = SString(minLength: 5, maxLength: 36, pattern: Patterns.tag);
const SString _skill = SString(minLength: 6, maxLength: 14, pattern: Patterns.skillId);

/// The course of a document (docs/languages/frame.md section 1.5). Missing means `core`, so every pack that exists keeps
/// its bytes; a language pack puts its course on the manifest and on every document, and the validator makes them agree.
const SField _course = SField(SEnum(Course.all), required: false);
const SString _vo = SString(minLength: 4, maxLength: 83, pattern: Patterns.voRef);

/// A word the child is asked to say, as the recogniser will be told it: none of the characters that change a hotword list (`:`,
/// `#`, `@`, `/`) and no control character.
const SString _sayWord = SString(minLength: 1, maxLength: _targetTextMax, pattern: r'[^:#@/\x00-\x1f]+');

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

/// What any spoken line may carry in a language course (docs/languages/frame.md F1 and F3): the target clip that follows the
/// Hebrew frame clip (a two-clip line), and a target word to show in a chip under the line (never inside the Hebrew).
const Map<String, SField> _lineExtras = <String, SField>{
  'target': SField(_vo, required: false),
  // A second target clip, played right after the first: a question and its answer, or the two sounds of a same-or-different item. Only
  // with a first one (the validator).
  'target2': SField(_vo, required: false),
  'show': SField(SString(minLength: 1, maxLength: _targetTextMax), required: false),
};

/// The most characters of the text of a tile, a word on show or a revealed word.
const int _targetTextMax = 40;

/// A rectangle in a picture, as shares of the picture's width and height (a hotspot, a place, a thing in a room).
const SObject _at = SObject(<String, SField>{
  'x': SField(SNum(min: 0, max: 1)),
  'y': SField(SNum(min: 0, max: 1)),
  'w': SField(SNum(min: 0.04, max: 1)),
  'h': SField(SNum(min: 0.04, max: 1)),
});

const SObject _spoken = SObject(<String, SField>{
  'vo': SField(_vo),
  'caption': SField(_caption),
  ..._lineExtras,
});

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
  'course': _course,
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
      'lessons': SField(SArray(_lessonId, maxItems: 400)),
      'skills': SField(SArray(_skill, maxItems: 600)),
      'misconceptions': SField(SArray(_tag, maxItems: 400)),
      // Characters and mouth cues (M4); absent in packs that have none.
      'characters': SField(SArray(_characterId, maxItems: 20), required: false),
      'cues': SField(
        SArray(SString(minLength: 1, maxLength: 80, pattern: Patterns.voId), maxItems: 4000),
        required: false,
      ),
      // The gates of a course (docs/languages/frame.md section 3.3.6); absent in packs that have none.
      'gates': SField(
        SArray(SString(minLength: 5, maxLength: 24, pattern: Patterns.gateId), maxItems: 20),
        required: false,
      ),
      // The placement game of a course (docs/languages/frame.md section 3.2): one document, absent in packs that have none.
      'placements': SField(
        SArray(SString(minLength: 13, maxLength: 13, pattern: Patterns.placementId), maxItems: 1),
        required: false,
      ),
      // The stroke sets of a language course (docs/languages/strokes.md): the scripts its letters are written in; absent in packs that
      // have none.
      'strokes': SField(
        SArray(SString(minLength: 5, maxLength: 20, pattern: Patterns.strokeSet), maxItems: 4),
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
  'course': _course,
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
  // Language courses (docs/languages/frame.md section 3.3): the letter bundle the skill is a facet of; a set of words or
  // letters whose every member must be answered right once; what a spelling that is right by sound counts as; letter work.
  'bundle': SField(SString(minLength: 5, maxLength: 24, pattern: Patterns.bundle), required: false),
  'setCoverage': SField(SBool(), required: false),
  'soundRight': SField(SEnum(<String>['accepts', 'teaches']), required: false),
  'letters': SField(SBool(), required: false),
  // Letter writing (rule E-1, docs/languages/writing-mastery.md): `memory` is a writing node (copy and memory writing, mastered by
  // memory successes on two days with both cues), `practised` a trace node (met once every letter was traced with the start dot).
  'writing': SField(SEnum(<String>['memory', 'practised']), required: false),
  // The graphemes this skill teaches (a letter, a digraph, a vowel sign), and the whole words it teaches as they are. A skill
  // that is letter work may offer only words made of the graphemes taught by it and by the skills below it, and its tricky
  // words (the decodable check, docs/languages/frame.md F5).
  'graphemes': SField(SArray(SString(minLength: 1, maxLength: 3), maxItems: 40), required: false),
  'tricky': SField(SArray(SString(minLength: 1, maxLength: _targetTextMax), maxItems: 60), required: false),
  // A skill that is two-way by nature (yes or no, same or different): its two-choice items must be balanced.
  'binary': SField(SBool(), required: false),
  // The strand of the course the skill is in (frame section 4.1: `lis`, `spk`, `pa`, `ph`, `rd`, `wr`; `ol`, `pk`, `dec`; `voc`,
  // `grm`, `pho`, `let`, `rea`, `wri`): the parent's progress view groups a language's skills by it.
  'strand': SField(SString(minLength: 2, maxLength: 4, pattern: r'[a-z]{2,4}'), required: false),
  // The Russian course: how a child whose route is `reader` is served in this skill (`oral`, the default: as the placement's first strand
  // says; or as a heritage speaker). Only the Russian course has routes.
  'readerAs': SField(SEnum(readerServes), required: false),
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

/// A gate of a language course: a condition on skills that holds other skills back (docs/languages/frame.md section 3.3.6).
const SObject gateSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.gate)),
  'id': SField(SString(minLength: 5, maxLength: 24, pattern: Patterns.gateId)),
  'review': _review,
  'course': _course,
  // Every one of these needs the mastery the gate asks for (a roll-up means all its groups).
  'requires': SField(SArray(_skill, maxItems: 60)),
  // And of each of these groups, at least `count` skills.
  'requireAtLeast': SField(
    SArray(
      SObject(<String, SField>{
        'skills': SField(SArray(_skill, minItems: 2, maxItems: 40)),
        'count': SField(SInt(min: 1, max: 40)),
      }),
      maxItems: 6,
    ),
    required: false,
  ),
  // The skills held back until the gate is open.
  'holds': SField(SArray(_skill, minItems: 1, maxItems: 200)),
  'minAge': SField(SInt(min: 3, max: 8), required: false),
  'neverUnderBand': SField(SInt(min: 0, max: 2), required: false),
  'durableBelowBand': SField(SInt(min: 1, max: 2), required: false),
  'parentSwitch': SField(
    SObject(<String, SField>{
      'name': SField(SEnum(gateSwitchNames)),
      'effect': SField(SEnum(<String>['closes', 'opens'])),
    }),
    required: false,
  ),
  'routeBypass': SField(SArray(SEnum(courseRoutes), maxItems: 3), required: false),
});

/// A questionnaire answer a placement rule reads: the question and the answer it takes (enums, as the parent's questionnaire keeps them).
const SString _answerKey = SString(minLength: 2, maxLength: 24, pattern: r'[a-z][A-Za-z0-9]{1,23}');

/// The placement game of a language course (docs/languages/frame.md section 3.2, LS13): its strands, each a ladder of levels of probe
/// items. The rules of the staircase (two right up, one wrong down, 2 reversals or 8 items, 2/3 right minus one, two misses at the
/// floor stop it) are the app's and not data, so a pack can only choose the ladders, where a questionnaire answer starts them, and which
/// strand is offered only on an answer.
const SObject placementSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.placement)),
  'id': SField(SString(minLength: 13, maxLength: 13, pattern: Patterns.placementId)),
  'review': _review,
  'course': _course,
  // The one warm line said after every probe, whatever the answer (no result is shown to the child), and the line that ends a visit.
  'thanks': SField(_spoken),
  'celebration': SField(_spoken),
  // Never more than about this many probes in one visit (frame section 3.2: about 8).
  'perVisit': SField(SInt(min: 4, max: 10)),
  'strands': SField(
    SArray(
      SObject(<String, SField>{
        'id': SField(SString(minLength: 1, maxLength: 4, pattern: r'[a-z0-9]{1,4}')),
        // The strand is offered only when the questionnaire says so and the presentation band is at least `minBand` (eng literacy).
        'offer': SField(
          SObject(<String, SField>{
            'answer': SField(_answerKey, required: false),
            'equals': SField(_answerKey, required: false),
            'minBand': SField(SInt(min: 0, max: 2), required: false),
          }),
          required: false,
        ),
        // Where the staircase starts when the questionnaire gave this answer: never where it ends.
        'start': SField(
          SArray(
            SObject(<String, SField>{
              'answer': SField(_answerKey),
              'equals': SField(_answerKey),
              'level': SField(SInt(min: 0, max: 7)),
            }),
            maxItems: 8,
          ),
          required: false,
        ),
        // The levels from the floor up: probe items (activities with `purpose` probe), and the skills a placement above the level takes as known.
        'levels': SField(
          SArray(
            SObject(<String, SField>{
              'items': SField(SArray(_id, minItems: 1, maxItems: 6)),
              'assumes': SField(SArray(_skill, maxItems: 20), required: false),
            }),
            minItems: 2,
            maxItems: 8,
          ),
        ),
      }),
      minItems: 1,
      maxItems: 6,
      uniqueKey: 'id',
    ),
  ),
});

const SObject misconceptionSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.misconception)),
  'id': SField(_tag),
  'review': _review,
  'course': _course,
  // What a wrong choice of this tag means (docs/languages/frame.md section 4.1): `diagnostic` is misconception evidence,
  // `on_the_way` is accepted as success in early skills, `accent` is speech only (never on a distractor), `practice` gives no signal.
  // Optional in the lands; a language pack must give it (the validator).
  'kind': SField(SEnum(tagKinds), required: false),
  // The family of the tag (frame section 4.1), for the parent view and for the rules that look at a kind of mistake: only a tag of the family
  // SHAPE may stand on an option that has no sound of its own (L5-1). Optional: the lands have none.
  'family': SField(SEnum(tagFamilies), required: false),
  // A language tag is used all over its course (eng.lis.sem names 12 skills of Band A alone), so the bound is the size of a course;
  // the array stays bounded and every entry is a skill id, so nothing a hostile pack puts here can grow.
  'skills': SField(SArray(_skill, minItems: 1, maxItems: 60)),
  'parentText': SField(SString(minLength: 1, maxLength: 240)),
  // Something a parent can do at home in about five minutes (M7, pack 0.3.0). Plain Hebrew for the parent.
  'homeActivity': SField(_caption, required: false),
  'repairActivities': SField(SArray(_id, maxItems: 10)),
  'preferredRepresentations': SField(SArray(SEnum(representations), maxItems: 5)),
});

const SObject lessonSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.lesson)),
  'id': SField(_lessonId),
  'review': _review,
  'course': _course,
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
  // The screens that come before a language lesson's items, each set with the routes that are shown it: teach screens (LS09, echo;
  // mode `teach`, the default) for a new learner, who is shown the new words before the lesson asks them, and hearing screens (mode
  // `hear`) for a heritage speaker, who hears a word once before it is asked. The ids are activities of the pack that are teach screens
  // (`say_it` with `answer.teach`) and are not in `items`.
  'teach': SField(
    SArray(
      SObject(<String, SField>{
        'items': SField(SArray(_id, minItems: 1, maxItems: 8)),
        'routes': SField(SArray(SEnum(teachRoutes), minItems: 1, maxItems: 2)),
        'mode': SField(SEnum(teachModes), required: false),
      }),
      minItems: 1,
      maxItems: 6,
    ),
    required: false,
  ),
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
  // A language course (1.1): a text, or only a sound (a sound card), is a face as well; a face of the bottom row may carry the tag that
  // taking it for a wrong one shows.
  'text': SField(_faceText, required: false),
  'clip': _optionClip,
  // Hint level 2 (1.1): the face in another form, a picture beside it (a letter's key word).
  'alt': SField(_asset, required: false),
  'misconception': SField(_tag, required: false),
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

/// A face of an LS01 mode that has text (L5-1): a letter, a unit, a syllable or a word, on a sort card, a bin sign, a match face, an order
/// tile or a cell. The validator holds it to the rules of a language course (script, nikud, decodable words) and the fit check to the
/// phone SE; the text is shown as plain text only.
const SString _faceText = SString(minLength: 1, maxLength: _targetTextMax);

/// A picture (`asset:id`) or a text (`txt:` and the text) on a cell of an order row or of a story line.
const SString _cellFace = SString(
  minLength: 5,
  maxLength: 46,
  pattern: r'asset:[a-z0-9_]{1,40}|txt:[^ -]{1,40}',
);

/// An option's own sound (a `vo:` reference), played by a speaker on its tile or by the tile itself (LS01 b and c).
const SField _optionClip = SField(_vo, required: false);

/// The pictures a `tap_answer` 1.4 can draw on its stage for a number skill (M10, X1). The scene says which and how many; the session
/// draws it. Each kind has its own fields, and the validator makes the scene say all of its kind's and none of another's.
const List<String> stagePictureKinds = <String>[
  'base_ten',
  'array',
  'hundred_chart',
  'clock',
  'ruler',
  'column',
  'fraction',
];

/// A whole number from 0 to 10,000 written with no leading zero (a column number; the row cells say the same after `n:`).
const String _columnNumber = r'0|[1-9][0-9]{0,3}|10000';

const SObject _stagePicture = SObject(<String, SField>{
  'kind': SField(SEnum(stagePictureKinds)),
  // base_ten: hundreds flats, tens rods and ones cubes; thousands are drawn as a stack.
  'thousands': SField(SInt(min: 0, max: 9), required: false),
  'hundreds': SField(SInt(min: 0, max: 9), required: false),
  'tens': SField(SInt(min: 0, max: 9), required: false),
  'ones': SField(SInt(min: 0, max: 9), required: false),
  // array: rows by columns of objects.
  'rows': SField(SInt(min: 1, max: 12), required: false),
  'columns': SField(SInt(min: 1, max: 12), required: false),
  // hundred_chart: the numbers of the cells that are lit, and those left blank to be found.
  'lit': SField(SArray(SInt(min: 1, max: 100), maxItems: 100), required: false),
  'blank': SField(SArray(SInt(min: 1, max: 100), maxItems: 100), required: false),
  // clock: any time, analog, with the digital reading beside it when asked.
  'hour': SField(SInt(min: 1, max: 12), required: false),
  'minute': SField(SInt(min: 0, max: 59), required: false),
  'digital': SField(SBool(), required: false),
  // ruler: a strip of `length` cm laid on the ruler at `from` cm.
  'length': SField(SInt(min: 1, max: 30), required: false),
  'from': SField(SInt(min: 0, max: 10), required: false),
  // column: two numbers in their places with an operation, and the carry and borrow marks.
  'op': SField(SEnum(<String>['+', '-']), required: false),
  // A number to 10,000 with no leading zero (SEC-M10-4).
  'top': SField(SString(minLength: 1, maxLength: 5, pattern: _columnNumber), required: false),
  'bottom': SField(SString(minLength: 1, maxLength: 5, pattern: _columnNumber), required: false),
  'marks': SField(
    SArray(
      SObject(<String, SField>{
        // The place the mark stands over, counted from the ones (0) up to the ten-thousands (4).
        'place': SField(SInt(min: 0, max: 4)),
        'kind': SField(SEnum(<String>['carry', 'borrow'])),
      }),
      maxItems: 5,
    ),
    required: false,
  ),
  // fraction (batch C9): a shape cut into `parts` equal parts with `shaded` of them shaded.
  'parts': SField(SInt(min: 2, max: 12), required: false),
  'shaded': SField(SInt(min: 0, max: 12), required: false),
});

/// The rules that tell what kind of mistake a wrong number is (M10, X3): the smaller digit taken from the larger, the ten forgotten, the
/// other operation done, a ten too many or too few, and a digit read at its face value. Each names the tag it is evidence for.
const List<String> numberRules = <String>[
  'smaller_from_larger',
  'forgot_the_ten',
  'added_instead',
  'off_by_ten',
  'face_value',
];

/// The number answer of a `tap_answer` 1.4 (M10, X3): the child types the number on a calm keypad, read left to right. Every wrong
/// number the author expects names the tag it shows; any other wrong number is classified by the item's rules, or is just wrong.
const Map<String, SField> _numberAnswerFields = <String, SField>{
  'value': SField(SInt(min: 0, max: 10000), required: false),
  'expected': SField(
    SArray(
      SObject(<String, SField>{'value': SField(SInt(min: 0, max: 10000)), 'misconception': SField(_tag)}),
      maxItems: 8,
    ),
    required: false,
  ),
  'rules': SField(
    SArray(
      SObject(<String, SField>{'when': SField(SEnum(numberRules)), 'misconception': SField(_tag)}),
      maxItems: 5,
    ),
    required: false,
  ),
};

/// What an option of the own-name answer is made of at run time (docs/languages/hebrew/band-a-content.md, HEB-A-11): the child's name, a
/// name of the closed list with the same first letter (NAME-FIRST) or the same number of letters (NAME-LENGTH); or, in a row of letters,
/// the first letter of the name, its look-alike and its last letter.
const List<String> nameSources = <String>['own', 'first', 'length', 'lookalike', 'last'];

/// A letter of the Hebrew alphabet and a name made of them (print, no marks): the closed list of names holds nothing else.
const String _hebrewName = r'[\u05D0-\u05EA]{2,8}';

/// The fields of the own-name answer (`tap_answer` 1.5, HEB-A-11). A pack holds only the rules and the closed list of names, never a name:
/// the options are made on the device from the child's profile and are never sent, logged, stored or voiced.
const Map<String, SField> _nameAnswerFields = <String, SField>{
  // `name`: the options are names; `letter`: a row of three letters of the name.
  'unit': SField(SEnum(<String>['name', 'letter']), required: false),
  // The closed list the distractor names come from (never made up at run time).
  'names': SField(
    SArray(SString(minLength: 2, maxLength: 8, pattern: _hebrewName), minItems: 20, maxItems: 60),
    required: false,
  ),
  // The look-alike pairs of letters, and the tag a touch on the look-alike carries.
  'pairs': SField(
    SArray(
      SObject(<String, SField>{
        'a': SField(SString(minLength: 1, maxLength: 1, pattern: r'[\u05D0-\u05EA]')),
        'b': SField(SString(minLength: 1, maxLength: 1, pattern: r'[\u05D0-\u05EA]')),
        'misconception': SField(_tag),
      }),
      minItems: 1,
      maxItems: 12,
    ),
    required: false,
  ),
};

/// The `answer` of a `tap_answer`: `choice` (two to five options and the right one, or the list of right ones of a tap-all), `number` (the
/// number itself) or `name` (options made on the device from the child's first name). The validator checks that the rest fits the type.
SObject _tapAnswer(
  Map<String, SField> optionFields, {
  Map<String, SField> answerFields = const <String, SField>{},
  SField correct = const SField(_optionId, required: false),
}) => SObject(<String, SField>{
  'type': const SField(SEnum(<String>['choice', 'number', 'name'])),
  'options': SField(
    SArray(SObject(optionFields), minItems: 2, maxItems: 5, uniqueKey: 'id'),
    required: false,
  ),
  'correct': correct,
  'shuffle': const SField(SBool(), required: false),
  'unsureAllowed': const SField(SBool(), required: false),
  ..._numberAnswerFields,
  ...answerFields,
});

SObject _answerOptions(
  Map<String, SField> optionFields, {
  Map<String, SField> answerFields = const <String, SField>{},
  int maxOptions = 4,
  SField correct = const SField(_optionId),
}) => SObject(<String, SField>{
  'type': const SField(SConst('choice')),
  'options': SField(SArray(SObject(optionFields), minItems: 2, maxItems: maxOptions, uniqueKey: 'id')),
  'correct': correct,
  'shuffle': const SField(SBool()),
  'unsureAllowed': const SField(SBool()),
  ...answerFields,
});

/// The fields of one option of a choice in the language templates of L4 (story, listen and do, sing along, puppet talk): a picture or
/// a text or only a sound, its own clip, a label for screen readers, where it is in the scene (`at`) and the tag a wrong choice carries.
const Map<String, SField> _l4Option = <String, SField>{
  'id': SField(_optionId),
  'sprite': SField(_asset, required: false),
  'numeral': SField(SInt(min: 0, max: 100), required: false),
  'text': SField(SString(minLength: 1, maxLength: _targetTextMax), required: false),
  'clip': _optionClip,
  'label': SField(SString(minLength: 1, maxLength: 80)),
  // One place, or several for a part that has more than one (both ears, both hands): a touch on any of them is the option.
  'at': SField(SAnyOf(<Schema>[_at, SArray(_at, minItems: 1, maxItems: 4)]), required: false),
  'misconception': SField(_tag, required: false),
  // Where a touch is taken as this option on a page that shows its text (`story` modes `zones` and `follow`): the picture, the start or the end of
  // a line (`line1-start`: the end the reading starts at, the right end in Hebrew), the word that is due, or any other word.
  'zone': SField(
    SString(minLength: 4, maxLength: 16, pattern: r'picture|word|other|line[1-3]-(?:start|end)'),
    required: false,
  ),
};

/// The `answer` of a template of L4: `type` is `choice` (options and the right one) or `none` (a step that is not scored). The mode
/// says which; the validator checks that the rest fits it. [extra] are the fields of the template itself.
SObject _l4Answer(
  List<String> modes, {
  Map<String, SField> extra = const <String, SField>{},
  int minOptions = 2,
  int maxOptions = 3,
}) => SObject(<String, SField>{
  'type': const SField(SEnum(<String>['choice', 'none'])),
  'mode': SField(SEnum(modes)),
  'options': SField(
    SArray(SObject(_l4Option), minItems: minOptions, maxItems: maxOptions, uniqueKey: 'id'),
    required: false,
  ),
  'correct': const SField(_optionId, required: false),
  'shuffle': const SField(SBool(), required: false),
  'unsureAllowed': const SField(SBool(), required: false),
  // Which side of a two-way skill the item is, as in `tap_answer`.
  'pole': const SField(SEnum(poles), required: false),
  'pairWith': const SField(_id, required: false),
  // What the text options are, as in `tap_answer`: `letter` (square, large, bold) or `word`; a place of LS11 may be a letter stone (L5-1).
  'face': const SField(SEnum(<String>['letter', 'word']), required: false),
  ...extra,
});

const SObject _feedback = SObject(<String, SField>{
  'correct': SField(_spoken),
  'incorrect': SField(
    SArray(
      SObject(<String, SField>{
        // "default", or "misconception:" followed by a tag from the catalogue.
        'when': SField(
          SString(minLength: 7, maxLength: 50, pattern: 'default|misconception:(?:${Patterns.tag})'),
        ),
        'vo': SField(_vo),
        'caption': SField(_caption),
        ..._lineExtras,
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
    ..._lineExtras,
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
      'story',
      'listen_do',
      'sing_along',
      'puppet_talk',
      'sound_boxes',
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
      'say_it',
    ]),
  ),
  'templateVersion': const SField(SString(minLength: 3, maxLength: 5, pattern: Patterns.templateVersion)),
  'course': _course,
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
  // The face the item's Hebrew text is set in when it is not the course's usual one: `display` is Secular One (a transfer check of the
  // same letters or names in the display face). A Hebrew course only; the validator refuses it elsewhere.
  'font': const SField(SEnum(<String>['display']), required: false),
  'difficulty': const SField(SObject(<String, SField>{'authored': SField(SNum(min: 0, max: 1))})),
  'prompt': const SField(
    SObject(<String, SField>{
      'vo': SField(_vo),
      'caption': SField(_caption),
      'replayButton': SField(SBool()),
      ..._lineExtras,
    }),
  ),
  ...templateParts,
  // Board B-24: the child may answer by voice (the mic is shown) only when this is true; missing is false. Only a word the
  // question does not already say (a number, a colour, a shape, a day) is a spoken answer: see `pack_validation.dart`.
  'voiceAnswer': const SField(SBool(), required: false),
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

/// The schema of an activity of the given template, or null for a template this app does not know. [version] is the activity's
/// `templateVersion`: `trace` 2.0 (LS02, write a letter) is another document from the tracing of the lands (1.0).
SObject? activitySchemaFor(String template, {String? version}) => switch (template) {
  'trace' when version != null && version.startsWith('2.') => letterWriteSchema,
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
          'numeral': SField(SInt(min: 0, max: 10000), required: false),
          // A picture of a number or a measure, drawn on the stage (1.4): blocks, an array, a hundred chart, a clock, a ruler, a column sum.
          'picture': SField(_stagePicture, required: false),
          // Picture answers on tiles below the stage instead of on it (1.1): when the pictures are the whole point.
          'optionsOnTiles': SField(SBool(), required: false),
          // A written word, unit or letter on the stage that the child reads (1.4, LS01 d): the clip is what "read it to me" plays.
          'stem': SField(
            SObject(<String, SField>{'text': SField(_faceText), 'clip': SField(_vo, required: false)}),
            required: false,
          ),
          // A sentence with one gap, marked `_`, that a word tile fills (1.4, LS01 e); the picture stands beside it.
          'cloze': SField(
            SObject(<String, SField>{
              'text': SField(SString(minLength: 3, maxLength: 120)),
              'picture': SField(_asset, required: false),
            }),
            required: false,
          ),
          // A chart to read (1.2): columns of pictures, each a category with how many it has (a pictograph).
          'chart': SField(
            SArray(
              SObject(<String, SField>{'sprite': SField(_asset), 'count': SField(SInt(min: 0, max: 8))}),
              minItems: 2,
              maxItems: 5,
            ),
            required: false,
          ),
          // A row of pictures with an optional gap ("?") to fill, for patterns and order (1.1). A cell may also be a number (`n:7`, to
          // 10,000) or a sign (`op:+`; `op:<`, `op:>`, `op:(` and `op:)` from 1.4), for a number sentence.
          'row': SField(
            SArray(
              SString(
                minLength: 1,
                maxLength: 46,
                pattern: r'asset:[a-z0-9_]{1,40}|\?|n:(?:0|[1-9][0-9]{0,3}|10000)|op:[+=x:<>()-]',
              ),
              minItems: 2,
              maxItems: 11,
            ),
            required: false,
          ),
        }),
      ),
      'answer': SField(
        _tapAnswer(
          <String, SField>{
            'id': const SField(_optionId),
            // An option is a picture, a numeral (to 10,000 from 1.4), or a set (1.1): exactly one of the three. In a language course
            // it may also be a text (1.3), or only a sound (a `clip` and nothing else, a sound button); the validator allows both
            // there only.
            'sprite': const SField(_asset, required: false),
            'numeral': const SField(SInt(min: 0, max: 10000), required: false),
            'set': const SField(_spriteSet, required: false),
            'text': const SField(SString(minLength: 1, maxLength: _targetTextMax), required: false),
            'clip': _optionClip,
            // The word shown under the picture once the answer is accepted (LS01 g), in the course's font.
            'reveal': const SField(SString(minLength: 1, maxLength: _targetTextMax), required: false),
            'label': const SField(SString(minLength: 1, maxLength: 80)),
            'speech': _speechWords,
            'misconception': const SField(_tag, required: false),
            // The own-name answer (`answer.type` `name`): what the option is made of at run time, from the child's first name.
            'source': const SField(SEnum(nameSources), required: false),
          },
          answerFields: <String, SField>{
            ..._nameAnswerFields,
            // Which side of a two-way skill this item is, and the item it is paired with in a check (frame section 2.3).
            'pole': const SField(SEnum(poles), required: false),
            'pairWith': const SField(_id, required: false),
            // What the text tiles are: `letter` (square, large, bold) or `word` (Medium, as wide as the row allows). The text never
            // decides: an item whose options are all one or two letters must say which it is (the validator). Missing is `word`.
            'face': const SField(SEnum(<String>['letter', 'word']), required: false),
            // Tap-all (1.4, LS01): several right cards in one row. `correct` is then the list of the right options, and the item checks
            // itself once as many cards are picked as there are right ones.
            'all': const SField(SBool(), required: false),
          },
          correct: const SField(
            SAnyOf(<Schema>[_optionId, SArray(_optionId, minItems: 1, maxItems: 5)]),
            required: false,
          ),
        ),
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
              // In a language course: the number word each tap plays, in counting order (practice, never scored).
              'clips': SField(SArray(_vo, minItems: 1, maxItems: 20), required: false),
            }),
          ),
          'target': SField(_sprite),
        }),
      ),
      'answer': SField(
        _answerOptions(<String, SField>{
          'id': const SField(_optionId),
          'value': const SField(SInt(min: 0, max: 20)),
          // In a language course the options of "how many?" are sound buttons: the number word each one plays.
          'clip': _optionClip,
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
                // The sign of the bin: a picture; in a language course (1.1) a text or a sound (`clip`) may be it instead.
                'sprite': SField(_asset, required: false),
                'text': SField(_faceText, required: false),
                'clip': _optionClip,
                // Hint level 2 (1.1): the sign in another form, a picture beside it (a letter's key word).
                'alt': SField(_asset, required: false),
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
                // A card: a picture; in a language course (1.1) a text, or only a sound (a sound card, `clip`).
                'sprite': SField(_asset, required: false),
                'text': SField(_faceText, required: false),
                'clip': _optionClip,
                'label': SField(SString(minLength: 1, maxLength: 80), required: false),
                // The tag of the mistake of putting this card in a wrong bin (a language course; the item's `answer.misconception` otherwise).
                'misconception': SField(_tag, required: false),
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
          // Each cell is a picture (`asset:`), a number (`n:7`, to 10,000 from 1.1), an arrow (`dir:up`) or a sign (`op:+`; `op:<`,
          // `op:>`, `op:(` and `op:)` from 1.1) or, in a language course (1.1), a text (`txt:` and a letter, a unit or a word).
          'cells': SField(
            SArray(
              SString(
                minLength: 3,
                maxLength: 46,
                pattern: r'asset:[a-z0-9_]{1,40}|n:(?:0|[1-9][0-9]{0,3}|10000)|dir:(up|down|left|right)|op:[+=x:<>()-]|txt:[^ -]{1,40}',
              ),
              minItems: 3,
              maxItems: 9,
            ),
          ),
          // A language course (1.1): the picture the cells are to match, and its word (heard on a touch).
          'model': SField(
            SObject(<String, SField>{
              'sprite': SField(_asset),
              'clip': SField(_vo, required: false),
              // The model's own spelling, cell for cell with the row (hint levels 2 and 3 show it against the row).
              'spelling': SField(SArray(_cellFace, minItems: 3, maxItems: 9), required: false),
            }),
            required: false,
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
          // The pattern to copy, shown above the places. In a language course (1.1) a cell may be a text (`txt:`), as may a tile.
          'model': SField(SArray(_cellFace, maxItems: 8), required: false),
          'slots': SField(SInt(min: 2, max: 8)),
          'palette': SField(SArray(_cellFace, minItems: 2, maxItems: 6)),
          // A story line (1.1): the line of each picture as a clip, in the order of the palette (hint level 1 plays them as it lights them).
          'clips': SField(SArray(_vo, minItems: 2, maxItems: 6), required: false),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('build')),
          'sequence': SField(SArray(_cellFace, minItems: 2, maxItems: 8), required: false),
          // A sequence, the story line of a language course (1.1, LS01 f): the palette stands in a shuffled order, and this is the index
          // of each place's picture in the right order.
          'order': SField(SArray(SInt(min: 0, max: 5), minItems: 2, maxItems: 6), required: false),
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
  // LS08: a picture book of 2 to 10 pages, narrated page by page; the child turns the pages and may touch a picture to hear its word.
  // `listen` is heard to its end and is never scored. `dialogic` stops after the page `pauseAfter` and asks `question`, a choice that
  // is scored; the item's `feedback.correct` is the recast, and the story then goes on to its last page.
  'story' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          'pages': SField(
            SArray(
              SObject(<String, SField>{
                'picture': SField(_asset),
                // The page's narration: the clip (and the second clip of a two-clip line). It is never shown as text.
                'clips': SField(SArray(_vo, minItems: 1, maxItems: 2)),
                // What a screen reader says of the page (Hebrew, for the adult).
                'alt': SField(SString(minLength: 1, maxLength: 240)),
                // The things in the picture that say their word when touched.
                'words': SField(
                  SArray(SObject(<String, SField>{'at': SField(_at), 'clip': SField(_vo)}), maxItems: 4),
                  required: false,
                ),
                // The text of the page, shown (modes `zones` and `follow`, Hebrew Band A, where the child reads nothing and the voice reads):
                // up to three lines of up to eight words. In `follow` every word has the clip of the voice saying it alone.
                'lines': SField(
                  SArray(
                    SArray(
                      SObject(<String, SField>{
                        'text': SField(SString(minLength: 1, maxLength: _targetTextMax)),
                        'clip': SField(_vo, required: false),
                      }),
                      minItems: 1,
                      maxItems: 8,
                    ),
                    minItems: 1,
                    maxItems: 3,
                  ),
                  required: false,
                ),
              }),
              minItems: 1,
              maxItems: 10,
            ),
          ),
        }),
      ),
      'answer': SField(
        _l4Answer(
          const <String>['listen', 'dialogic', 'zones', 'follow'],
          extra: const <String, SField>{
            // The page after which the story stops to ask (counted from 0), and what it asks.
            'pauseAfter': SField(SInt(min: 0, max: 9), required: false),
            'question': SField(_spoken, required: false),
          },
        ),
      ),
    }),
  ),
  // LS11: the child carries out a command in a scene. `hotspots`: touch one of the glowing parts of the picture (a body, a room);
  // `buttons`: one of 2 or 3 action pictures, and the friend does it; `drag`: one of 2 or 3 things goes to the target (a plate, a box,
  // the friend); `place`: the one thing goes to one of 2 or 3 places; `embodied`: the child does it and touches "done" (never scored).
  'listen_do' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // The picture of the scene: the friend, the body, the room.
          'picture': SField(_asset),
          // Where things are dropped (`drag`).
          'target': SField(
            SObject(<String, SField>{'at': SField(_at), 'sprite': SField(_asset, required: false)}),
            required: false,
          ),
          // The one thing that is moved (`place`).
          'thing': SField(
            SObject(<String, SField>{'at': SField(_at), 'sprite': SField(_asset)}),
            required: false,
          ),
        }),
      ),
      'answer': SField(
        _l4Answer(const <String>['hotspots', 'buttons', 'cards', 'drag', 'place', 'embodied']),
      ),
    }),
  ),
  // LS12: an original song, chant or rhyme. `chant`: the lines are said one after another, the pictures of a line light while it is said, a
  // touch on a picture says its word; joining in is practice and writes nothing. `rhyme`: the verse is heard whole, stops before its last
  // word, the child chooses among 2 or 3 pictures (scored), and the whole verse is heard again. No melody: the lines are spoken to a beat.
  'sing_along' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // The pictures of the song: they light on their key words, and say their word when touched.
          'pictures': SField(
            SArray(
              SObject(<String, SField>{
                'picture': SField(_asset),
                'label': SField(SString(minLength: 1, maxLength: 80)),
                'clip': SField(_vo, required: false),
              }),
              minItems: 1,
              maxItems: 6,
            ),
          ),
          // `chant`: the lines, each with the pictures (by index) that light while it is said.
          'lines': SField(
            SArray(
              SObject(<String, SField>{
                'clips': SField(SArray(_vo, minItems: 1, maxItems: 2)),
                'lights': SField(SArray(SInt(min: 0, max: 5), maxItems: 3)),
              }),
              maxItems: 8,
            ),
            required: false,
          ),
          // `rhyme`: the verse heard whole, up to its gap, and whole again after the answer; `cue` is the end word of the first line
          // (the hints say it, alone and before each option).
          'verse': SField(
            SObject(<String, SField>{
              'whole': SField(SArray(_vo, minItems: 1, maxItems: 4)),
              'open': SField(SArray(_vo, minItems: 1, maxItems: 4)),
              'full': SField(SArray(_vo, minItems: 1, maxItems: 4)),
              'cue': SField(SArray(_vo, minItems: 1, maxItems: 2)),
            }),
            required: false,
          ),
        }),
      ),
      'answer': SField(
        _l4Answer(
          const <String>['chant', 'rhyme'],
          extra: const <String, SField>{'question': SField(_spoken, required: false)},
        ),
      ),
    }),
  ),
  // LS10: a puppet speaks one turn (the prompt, two clips), and the child answers. `bubble`: one of 2 or 3 answer bubbles that fit the
  // scene (a picture or a text, each with a speaker), scored; the puppet answers with the item's right line. `personal` (docs/languages/
  // frame.md section 5.2): one of the four things a lesson may ask (`topic`), the puppet goes first, the child touches a card or passes;
  // the reply is generic and warm; the answer is never checked, kept, logged, synced or used, and nothing is written.
  'puppet_talk' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // The scene of the turn: the puppet, the friend, the thing in the room.
          'picture': SField(_asset),
          // The key picture of the scene: it glows at the second hint (a place in `picture`).
          'key': SField(SObject(<String, SField>{'at': SField(_at)}), required: false),
        }),
      ),
      'answer': SField(
        _l4Answer(
          const <String>['bubble', 'personal'],
          minOptions: 0,
          maxOptions: 8,
          extra: const <String, SField>{
            'topic': SField(SEnum(personalTopics), required: false),
            // The puppet's reply to a pass ("That's OK!").
            'pass': SField(_spoken, required: false),
          },
        ),
      ),
    }),
  ),
  // LS03, drum mode (Band A; the boxes and colours of Bands B and C are L5): the word is heard with its picture and the child taps a drum
  // once for each part. Free response: there are no options, so no fixed distractors; a count one more or one fewer than `beats` is
  // mapped to a tag (`classifiers`), any other count is a retry with no tag. The response is the count (`n=3`).
  'sound_boxes' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{
          'background': SField(_asset, required: false),
          // The picture of the word.
          'picture': SField(_asset),
          // The word, heard with its picture; the same word slowly, with a pause between the beats; and the sound of a tap on the drum.
          'word': SField(SArray(_vo, minItems: 1, maxItems: 2)),
          'slow': SField(SArray(_vo, minItems: 1, maxItems: 2), required: false),
          'drum': SField(_vo, required: false),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('drum')),
          'mode': SField(SConst('drum')),
          // How many parts the word has: the right number of taps (1 to 6).
          'beats': SField(SInt(min: 1, max: 6)),
          // `one_more` and `one_fewer` to the tag each one is evidence for. Any other count is a retry with no tag.
          'classifiers': SField(
            SArray(
              SObject(<String, SField>{
                'when': SField(SEnum(<String>['one_more', 'one_fewer'])),
                'misconception': SField(_tag),
              }),
              maxItems: 2,
              uniqueKey: 'when',
            ),
          ),
        }),
      ),
    }),
  ),
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
  // LS09 say it with me (docs/languages/frame.md section 2.3): the voice says a word with its picture, the child may say it (the
  // per-word matcher answers confident or unsure, never wrong), then taps the picture to go on. Language courses only.
  'say_it' => SObject(
    _base(<String, SField>{
      'scene': const SField(
        SObject(<String, SField>{'background': SField(_asset, required: false), 'picture': SField(_sprite)}),
      ),
      'say': const SField(
        SObject(<String, SField>{
          // The target word and the forms its teacher lists, and the foils (the item's other options, the minimal-pair partner).
          'forms': SField(SArray(_sayWord, minItems: 1, maxItems: 6)),
          'foils': SField(SArray(_sayWord, minItems: 1, maxItems: 6)),
          // A chunk: every one of these must be heard on its own.
          'keyWords': SField(SArray(_sayWord, minItems: 1, maxItems: 4), required: false),
          // The word said by the voice (the model, and the choral clip after an unsure result).
          'clip': SField(_vo),
          // "I heard:" and "let's say it together" (Hebrew frame lines; the word follows as the line's own target clip).
          'heard': SField(_spoken),
          'together': SField(_spoken),
          // The Russian course: the order the step is played in on each route, and the line that asks the child to say the word before it
          // is heard (never with a clip after it: the word is what the child is asked for).
          'order': SField(
            SObject(<String, SField>{'new': SField(SEnum(sayOrders)), 'heritage': SField(SEnum(sayOrders))}),
            required: false,
          ),
          'pictureFirst': SField(_spoken, required: false),
        }),
      ),
      'answer': const SField(
        SObject(<String, SField>{
          'type': SField(SConst('say_it')),
          // The tap on the picture is a scored listening item when the author marks it; otherwise it is practice.
          'scored': SField(SBool()),
          // A teach screen of a lesson (`lesson.teach`): the word is shown, not asked. It is never scored, writes nothing, has no
          // microphone, and the engine does not see it.
          'teach': SField(SBool(), required: false),
          // A hearing screen (`lesson.teach` mode `hear`): a teach screen that is only heard: the line and the word once, no microphone, no
          // "I said it", the word again as often as the child touches the replay button, the picture once the word has been said.
          'hear': SField(SBool(), required: false),
        }),
      ),
    }),
  ),
  _ => null,
};

// ---- LS02: write a letter, and the stroke data it reads ----

const SString _strokeFormId = SString(minLength: 3, maxLength: 40, pattern: Patterns.strokeForm);

/// A point of a stroke: whole units of the box of 100 by 100.
const SArray _boxPoint = SArray(SInt(min: 0, max: 100), minItems: 2, maxItems: 2);

/// The ways a stroke goes, in words (docs/languages/strokes.md section 2): a straight run, or a curve as seen on the screen.
const List<String> strokeMoves = <String>[
  'down',
  'up',
  'left',
  'right',
  'down-left',
  'down-right',
  'up-left',
  'up-right',
  'cw',
  'ccw',
  'dot',
];

const SObject _strokeSchema = SObject(<String, SField>{
  'kind': SField(SEnum(<String>['line', 'dot', 'short'])),
  // The smooth path (M, L and C in box units) for the model letter and the "watch it drawn" motion. The schema keeps it to numbers and
  // three letters; its grammar (an M first, then L with 2 numbers and C with 6, each number from 0 to 100) is `checkStrokeSet`'s rule.
  'd': SField(SString(minLength: 5, maxLength: 500, pattern: r'[MLC0-9 .\-]+')),
  // The bounds of docs/milestones/L5.md section 11: points inside the box, 2 to 60 of them.
  'points': SField(SArray(_boxPoint, minItems: 2, maxItems: 60)),
  'start': SField(_boxPoint),
  'end': SField(_boxPoint),
  'moves': SField(SArray(SEnum(strokeMoves), minItems: 1, maxItems: 12)),
  'retrace': SField(SBool(), required: false),
  'loop': SField(SBool(), required: false),
  'startOk': SField(SString(minLength: 1, maxLength: 400), required: false),
});

/// A stroke of another right build of a letter (QA-L52-1): only compared with what the child writes, never drawn, so it has no path
/// and no words for the way it goes.
const SObject _buildStrokeSchema = SObject(<String, SField>{
  'kind': SField(SEnum(<String>['line', 'dot', 'short'])),
  'points': SField(SArray(_boxPoint, minItems: 2, maxItems: 60)),
  'retrace': SField(SBool(), required: false),
});

/// Another way to write the letter that is right: a few strokes, read in any order like the model's (`tools/strokes_alternates.py`).
const SObject _buildSchema = SObject(<String, SField>{
  'how': SField(SString(minLength: 1, maxLength: 40, pattern: r'[a-z ,-]+')),
  'strokes': SField(SArray(_buildStrokeSchema, minItems: 1, maxItems: 6)),
});

const SObject _strokeFormSchema = SObject(<String, SField>{
  'id': SField(_strokeFormId),
  'char': SField(SString(minLength: 1, maxLength: 2)),
  'name': SField(SString(minLength: 1, maxLength: 16, pattern: r'[A-Za-z0-9-]+')),
  'case': SField(SEnum(<String>['lower', 'upper']), required: false),
  'final': SField(SBool(), required: false),
  'group': SField(SString(minLength: 1, maxLength: 16, pattern: r'[a-z-]+'), required: false),
  'groupProposed': SField(SBool(), required: false),
  // The upper and lower guide line the body of the letter sits on (null where it is not on one, like t's top).
  'sits': SField(
    SArray(
      SAnyOf(<Schema>[SString(minLength: 1, maxLength: 12, pattern: r'[a-z]+'), SNull()]),
      minItems: 2,
      maxItems: 2,
    ),
  ),
  // At most six strokes a form (Yo has six).
  'strokes': SField(SArray(_strokeSchema, minItems: 1, maxItems: 6)),
  // The other builds of the letter that are right (a ball and a stick for a): at most four, within the same caps.
  'alternates': SField(SArray(_buildSchema, minItems: 1, maxItems: 4), required: false),
});

/// The stroke data of one script (`nitznutz.strokes/1`), as `content/languages/strokes/<set>.json` and as the pack document
/// `strokes.<set>.json`. Parsed content: every number is bounded and the only commands are the M, L and C of a stroke's drawing path
/// (`d`), whose grammar `checkStrokeSet` holds; the validator refuses a set that is not `teacher-checked` (`ls02_checks.dart`).
const SObject strokesSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.strokes)),
  'set': SField(SString(minLength: 5, maxLength: 20, pattern: Patterns.strokeSet)),
  'courses': SField(SArray(SEnum(Course.languages), minItems: 1, maxItems: 3)),
  'review': SField(SEnum(<String>['needs-teacher', 'teacher-checked'])),
  'reviewer': SField(SString(minLength: 1, maxLength: 40, pattern: r'[a-z-]+')),
  'box': SField(SInt(min: 100, max: 100)),
  'ink': SField(SInt(min: 2, max: 20)),
  'em': SField(SNum(min: 1, max: 200)),
  'baseline': SField(SNum(min: 0, max: 100)),
  // The lines letters sit on, as y in the box, and which of them are drawn solid.
  'guides': SField(SMap(SNum(min: 0, max: 100), keyPattern: r'[a-z]{1,12}', maxEntries: 8)),
  'solidGuides': SField(SArray(SString(minLength: 1, maxLength: 12, pattern: r'[a-z]+'), maxItems: 8)),
  'inset': SField(SNum(min: 0, max: 20)),
  'direction': SField(SEnum(<String>['ltr', 'rtl'])),
  'generator': SField(SString(minLength: 1, maxLength: 120)),
  'font': SField(
    SObject(<String, SField>{
      'family': SField(SString(minLength: 1, maxLength: 40)),
      'weight': SField(SInt(min: 100, max: 900)),
      'file': SField(SString(minLength: 1, maxLength: 80)),
      'css': SField(SString(minLength: 1, maxLength: 8)),
    }),
    required: false,
  ),
  'groups': SField(
    SMap(SString(minLength: 1, maxLength: 240), keyPattern: r'[a-z]{1,12}', maxEntries: 8),
    required: false,
  ),
  'count': SField(SInt(min: 1, max: 80)),
  'forms': SField(SArray(_strokeFormSchema, minItems: 1, maxItems: 80, uniqueKey: 'id')),
});

/// LS02 write a letter, `trace` 2.0 (docs/milestones/L5.md section 5.2): an `intro` (the worked example of a letter, unscored) and the
/// three modes `trace`, `copy` and `memory`, on a canvas of one letter or of a word. The letters are form ids of the stroke set of the
/// course's script. The classifiers map the errors the free-stroke check can name to the course's tags; an error it cannot name is a
/// retry with no tag and no evidence.
const SObject letterWriteSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.activity)),
  'id': SField(_id),
  'review': _review,
  'revision': SField(_revision),
  'template': SField(SConst('trace')),
  'templateVersion': SField(SString(minLength: 3, maxLength: 5, pattern: Patterns.templateVersion)),
  'course': _course,
  'domain': SField(SEnum(domains)),
  'band': SField(SEnum(bands)),
  'skills': SField(
    SArray(
      SObject(<String, SField>{'id': SField(_skill), 'weight': SField(SNum(min: 0, max: 1))}),
      minItems: 1,
      maxItems: 4,
      uniqueKey: 'id',
    ),
  ),
  'purpose': SField(SEnum(<String>['learn', 'practice', 'probe', 'repair', 'check'])),
  'contradicts': SField(_tag, required: false),
  'checkType': SField(
    SEnum(<String>['practice', 'transfer', 'reverse', 'error_spotting', 'explain_back', 'predict']),
  ),
  'representation': SField(SEnum(representations)),
  'variantGroup': SField(SString(minLength: 3, maxLength: 60, pattern: r'[a-z0-9._-]+')),
  'difficulty': SField(SObject(<String, SField>{'authored': SField(SNum(min: 0, max: 1))})),
  'prompt': SField(
    SObject(<String, SField>{
      'vo': SField(_vo),
      'caption': SField(_caption),
      'replayButton': SField(SBool()),
      ..._lineExtras,
    }),
  ),
  'scene': SField(
    SObject(<String, SField>{
      'mode': SField(SEnum(<String>['intro', 'trace', 'copy', 'memory'])),
      'canvas': SField(SEnum(<String>['letter', 'word'])),
      // One form for a letter canvas; two to six for a word canvas (the boxes, in the course's direction).
      'forms': SField(SArray(_strokeFormId, minItems: 1, maxItems: 6)),
      // `own_name`: the letters of the child's name, made on the device from the parent-typed name; nothing of it is in the pack.
      'source': SField(SEnum(<String>['forms', 'own_name']), required: false),
      // trace: the whole dotted path, or only the start dot and the first direction.
      'guide': SField(SEnum(<String>['full', 'start']), required: false),
      // copy: the model beside the box, or shown and then covered.
      'model': SField(SEnum(<String>['beside', 'hide']), required: false),
      // memory: what the voice says, the sound of the letter or its name (the clip is the prompt's `target`).
      'cue': SField(SEnum(<String>['sound', 'name']), required: false),
      // intro: the sound in a key word with its picture, and the name as a separate fact.
      'intro': SField(
        SObject(<String, SField>{
          'sound': SField(_vo),
          'keyword': SField(_vo, required: false),
          'name': SField(_vo),
          'picture': SField(_asset, required: false),
        }),
        required: false,
      ),
      // A handwriting step that is only practice, whatever skill it names (a word canvas of eng C-23 and rus C-23).
      'practice': SField(SBool(), required: false),
    }),
  ),
  'answer': SField(
    SObject(<String, SField>{
      'type': SField(SEnum(<String>['trace', 'none'])),
      'classify': SField(
        SObject(<String, SField>{
          'start': SField(_tag, required: false),
          'direction': SField(_tag, required: false),
          'lines': SField(_tag, required: false),
          'mirror': SField(_tag, required: false),
          // A look-alike form the child may write instead of the target, and the tag of that mix-up.
          'partners': SField(SMap(_tag, keyPattern: Patterns.strokeForm, maxEntries: 6), required: false),
        }),
        required: false,
      ),
    }),
  ),
  'voiceAnswer': SField(SBool(), required: false),
  'feedback': SField(_feedback),
  'hints': SField(_hints),
  'scoring': SField(
    SObject(<String, SField>{
      'maxAttempts': SField(SInt(min: 1, max: 5)),
      'creditByHintLevel': SField(SArray(SNum(min: 0, max: 1), minItems: 4, maxItems: 4)),
    }),
  ),
  'tutor': SField(
    SObject(<String, SField>{
      'llmAllowed': SField(SBool()),
      'goal': SField(SString(minLength: 5, maxLength: 200)),
      'mustNotRevealBeforeHint': SField(SInt(min: 0, max: 3)),
    }),
  ),
  'a11y': SField(SObject(<String, SField>{'altText': SField(SString(minLength: 1, maxLength: 240))})),
});

/// The file an author writes next to the content files of a pack (`pack.json`); the pack builder reads
/// it, works out the rest of the manifest (files, hashes, entries, template versions) and signs.
const SObject packSourceSchema = SObject(<String, SField>{
  'schema': SField(SConst(SchemaIds.packSource)),
  'id': SField(SString(minLength: 3, maxLength: 41, pattern: Patterns.packId)),
  'version': SField(SString(minLength: 5, maxLength: 11, pattern: Patterns.semver)),
  'minAppVersion': SField(SString(minLength: 5, maxLength: 11, pattern: Patterns.semver)),
  'course': _course,
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
  'gate': gateSchema,
  'placement': placementSchema,
  'activity.tap_answer': activitySchemaFor('tap_answer')!,
  'activity.story': activitySchemaFor('story')!,
  'activity.listen_do': activitySchemaFor('listen_do')!,
  'activity.sing_along': activitySchemaFor('sing_along')!,
  'activity.puppet_talk': activitySchemaFor('puppet_talk')!,
  'activity.sound_boxes': activitySchemaFor('sound_boxes')!,
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
  'activity.trace_write': letterWriteSchema,
  'strokes': strokesSchema,
  'activity.say_it': activitySchemaFor('say_it')!,
};
