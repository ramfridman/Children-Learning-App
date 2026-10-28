import 'dart:convert';
import 'dart:typed_data';

import 'pack_verify.dart';

// Typed views of the documents of a pack that has passed `verifyPack`. The documents were checked
// against the schemas and the cross-file rules, so these classes read them without defending against
// a wrong shape; they are never built from anything that has not been verified.

Map<String, Object?> _map(Object? o) => o! as Map<String, Object?>;
List<Map<String, Object?>> _maps(Object? o) => <Map<String, Object?>>[
  for (final Object? e in (o as List<Object?>? ?? const <Object?>[])) _map(e),
];

/// The Hebrew of a caption list (exactly one element, `t` is always `he`).
String _caption(Object? o) => _map((o! as List<Object?>).single)['v']! as String;

/// A line to be voiced and shown: the voice id (`vo:…`) and its caption.
class Spoken {
  const Spoken({required this.vo, required this.caption});

  factory Spoken.fromJson(Object? json) {
    final Map<String, Object?> m = _map(json);
    return Spoken(vo: m['vo']! as String, caption: _caption(m['caption']));
  }

  final String vo;
  final String caption;
}

enum HintAction { replayPromptSlow, highlightObjectsSequentially, showFingers, workedExample }

HintAction _hintAction(String s) => switch (s) {
  'replay_prompt_slow' => HintAction.replayPromptSlow,
  'highlight_objects_sequentially' => HintAction.highlightObjectsSequentially,
  'show_fingers' => HintAction.showFingers,
  _ => HintAction.workedExample,
};

class Hint {
  const Hint({required this.level, required this.action, required this.say});

  final int level;
  final HintAction action;
  final Spoken say;
}

/// A rule of `feedback.incorrect`: `when` is `default` or `misconception:<tag>`.
class IncorrectRule {
  const IncorrectRule({required this.tag, required this.say});

  /// Null for the default rule.
  final String? tag;
  final Spoken say;
}

class ActivityFeedback {
  const ActivityFeedback({required this.correct, required this.incorrect, required this.unsure});

  final Spoken correct;
  final List<IncorrectRule> incorrect;
  final Spoken unsure;

  /// The line for a wrong answer carrying [tag] (or none): the rule for that tag, else the default.
  Spoken forIncorrect(String? tag) {
    IncorrectRule? fallback;
    for (final IncorrectRule r in incorrect) {
      if (r.tag == null) {
        fallback = r;
      } else if (r.tag == tag) {
        return r.say;
      }
    }
    return fallback!.say;
  }
}

class Skill {
  const Skill({required this.id, required this.weight});

  final String id;
  final double weight;
}

/// What every activity has, whatever its template.
sealed class Activity {
  Activity._(this.json, this.assets)
    : id = json['id']! as String,
      revision = json['revision']! as int,
      template = json['template']! as String,
      templateVersion = json['templateVersion']! as String,
      skills = <Skill>[
        for (final Map<String, Object?> s in _maps(json['skills']))
          Skill(id: s['id']! as String, weight: (s['weight']! as num).toDouble()),
      ],
      purpose = json['purpose']! as String,
      checkType = json['checkType']! as String,
      representation = json['representation']! as String,
      variantGroup = json['variantGroup']! as String,
      difficulty = (_map(json['difficulty'])['authored']! as num).toDouble(),
      contradicts = json['contradicts'] as String?,
      promptLine = Spoken.fromJson(json['prompt']),
      feedback = ActivityFeedback(
        correct: Spoken.fromJson(_map(json['feedback'])['correct']),
        incorrect: <IncorrectRule>[
          for (final Map<String, Object?> r in _maps(_map(json['feedback'])['incorrect']))
            IncorrectRule(
              tag: (r['when']! as String) == 'default'
                  ? null
                  : (r['when']! as String).substring('misconception:'.length),
              say: Spoken.fromJson(r),
            ),
        ],
        unsure: Spoken.fromJson(_map(json['feedback'])['unsure']),
      ),
      hints = <Hint>[
        for (final Map<String, Object?> h in _maps(json['hints']))
          Hint(
            level: h['level']! as int,
            action: _hintAction(h['action']! as String),
            say: Spoken.fromJson(h),
          ),
      ],
      maxAttempts = _map(json['scoring'])['maxAttempts']! as int,
      altText = _map(json['a11y'])['altText']! as String;

  factory Activity.fromJson(Map<String, Object?> json, PackAssets assets) => switch (json['template']) {
    'count_tap' => CountTapActivity._(json, assets),
    'tap_answer' => TapAnswerActivity._(json, assets),
    'flash' => FlashActivity._(json, assets),
    'sort_drag' => SortDragActivity._(json, assets),
    'build_pattern' => BuildPatternActivity._(json, assets),
    _ => GiveNActivity._(json, assets),
  };

  final Map<String, Object?> json;
  final PackAssets assets;

  /// May the AI tutor speak in this activity (the author's choice)?
  bool get llmAllowed => _map(json['tutor'])['llmAllowed'] == true;

  /// The misconception tags this activity's wrong answers can carry (what the tutor may be asked about).
  List<String> get misconceptionTags => <String>{
    for (final Map<String, Object?> o in _maps(_map(json['answer'])['options']))
      if (o['misconception'] is String) o['misconception']! as String,
    if (_map(json['answer'])['misconception'] is String) _map(json['answer'])['misconception']! as String,
    for (final Map<String, Object?> c in _maps(_map(json['answer'])['classifiers']))
      if (c['misconception'] is String) c['misconception']! as String,
  }.toList();

  /// What the learning engine needs to know about the activity.
  final String purpose;
  final String checkType;
  final String representation;
  final String variantGroup;
  final double difficulty;
  final String? contradicts;
  final String id;
  final int revision;
  final String template;
  final String templateVersion;
  final List<Skill> skills;
  final Spoken promptLine;
  final ActivityFeedback feedback;
  final List<Hint> hints;
  final int maxAttempts;
  final String altText;

  String get skillId => skills.first.id;

  /// How many choices the child has (0 for an open task), and the misconceptions the wrong answers can show.
  int get optionCount;
  Set<String> get engineTags;

  /// The asset reference (`asset:butterfly`) of the scene background, if any.
  String? get background => _map(json['scene'])['background'] as String?;
}

/// Some of a thing, to draw as a group: the set to count in a scene, or an answer that is a set (tap_answer 1.1).
class SpriteSet {
  const SpriteSet({
    required this.sprite,
    required this.count,
    this.arrangement = 'line',
    this.seed = 0,
    this.scale = 1,
  });

  factory SpriteSet.fromJson(Object? json) {
    final Map<String, Object?> m = _map(json);
    return SpriteSet(
      sprite: m['sprite']! as String,
      count: m['count']! as int,
      arrangement: (m['arrangement'] as String?) ?? 'line',
      seed: (m['seed'] as int?) ?? 0,
      scale: ((m['scale'] as num?) ?? 1).toDouble(),
    );
  }

  final String sprite;
  final int count;
  final String arrangement;
  final int seed;
  final double scale;
}

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    this.value,
    this.numeral,
    this.set,
    this.sprite,
    this.label,
    this.misconception,
    this.speech = const <String>[],
  });

  final String id;

  /// The number a count option shows (`count_tap`).
  final int? value;

  /// A `tap_answer` option that is a numeral (drawn as a number tile), or a set (some of a thing).
  final int? numeral;
  final SpriteSet? set;

  /// The picture of a `tap_answer` option (an `asset:` reference).
  final String? sprite;
  final String? label;
  final String? misconception;

  /// Extra words a child may say for this option (see the `speech` list of the activity file).
  final List<String> speech;
}

List<ChoiceOption> _options(Object? answer) => <ChoiceOption>[
  for (final Map<String, Object?> o in _maps(_map(answer)['options']))
    ChoiceOption(
      id: o['id']! as String,
      value: o['value'] as int?,
      numeral: o['numeral'] as int?,
      set: o['set'] == null ? null : SpriteSet.fromJson(o['set']),
      sprite: o['sprite'] as String?,
      label: o['label'] as String?,
      misconception: o['misconception'] as String?,
      speech: <String>[
        for (final Object? w in (o['speech'] as List<Object?>? ?? const <Object?>[])) w! as String,
      ],
    ),
];

class TapAnswerActivity extends Activity {
  TapAnswerActivity._(super.json, super.assets)
    : options = _options(json['answer']),
      correctId = _map(json['answer'])['correct']! as String,
      group = _map(json['scene'])['group'] == null ? null : SpriteSet.fromJson(_map(json['scene'])['group']),
      group2 = _map(json['scene'])['group2'] == null
          ? null
          : SpriteSet.fromJson(_map(json['scene'])['group2']),
      stageNumeral = _map(json['scene'])['numeral'] as int?,
      _tilesFlag = _map(json['scene'])['optionsOnTiles'] == true,
      row = <String>[
        for (final Object? r in (_map(json['scene'])['row'] as List<Object?>? ?? const <Object?>[]))
          r! as String,
      ],
      super._();

  final List<ChoiceOption> options;
  final String correctId;

  /// The thing to count or compare, shown above the answers (1.1), and a second one beside it for a comparison.
  final SpriteSet? group;
  final SpriteSet? group2;

  /// A row of pictures (asset references) with `?` for the gap to fill (1.1); empty when the scene has none.
  final List<String> row;

  /// A numeral drawn large on the stage (1.1), or null.
  final int? stageNumeral;

  /// Numerals and sets are answered on tiles below the stage (it is too small for them); pictures stay on the stage.
  bool get optionsInTiles => _tilesFlag || options.any((ChoiceOption o) => o.sprite == null);
  final bool _tilesFlag;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
  };
}

/// A bin of the sort-and-drag template: a picture (or a set of them) that shows the rule, and its name.
class SortBin {
  const SortBin({required this.id, required this.sprite, required this.count, required this.label});

  final String id;
  final String sprite;

  /// How many of the picture to draw in the bin (a bin that shows its rule with three of them), at least 1.
  final int count;
  final String label;
}

/// A picture to be sorted, and the bin it belongs in (null in share mode, where any bin may be right).
class SortItem {
  const SortItem({required this.id, required this.sprite, required this.bin});

  final String id;
  final String sprite;
  final String? bin;
}

/// The sort-and-drag template (T03): pictures go into bins by touch or by drag; in `share` mode they are dealt between
/// two friends until both have the same.
class SortDragActivity extends Activity {
  SortDragActivity._(super.json, super.assets)
    : bins = <SortBin>[
        for (final Map<String, Object?> b in _maps(_map(json['scene'])['bins']))
          SortBin(
            id: b['id']! as String,
            sprite: b['sprite']! as String,
            count: (b['count'] as int?) ?? 1,
            label: b['label']! as String,
          ),
      ],
      items = <SortItem>[
        for (final Map<String, Object?> i in _maps(_map(json['scene'])['items']))
          SortItem(id: i['id']! as String, sprite: i['sprite']! as String, bin: i['bin'] as String?),
      ],
      share = _map(json['answer'])['mode'] == 'share',
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  final List<SortBin> bins;
  final List<SortItem> items;

  /// Share mode: the answer is right when every bin holds the same number.
  final bool share;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// The build-a-pattern template (T05): fill the places from a palette.
class BuildPatternActivity extends Activity {
  BuildPatternActivity._(super.json, super.assets)
    : model = <String>[
        for (final Object? m in (_map(json['scene'])['model'] as List<Object?>? ?? const <Object?>[]))
          m! as String,
      ],
      slots = _map(json['scene'])['slots']! as int,
      palette = <String>[
        for (final Object? p in _map(json['scene'])['palette']! as List<Object?>) p! as String,
      ],
      sequence = <String>[
        for (final Object? s in _map(json['answer'])['sequence']! as List<Object?>) s! as String,
      ],
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  /// The pattern to copy (may be empty), the number of places, the pictures to choose from and the right order.
  final List<String> model;
  final int slots;
  final List<String> palette;
  final List<String> sequence;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// The flash template (T14): a group is shown for [flashMs] and covered, and the child picks how many.
class FlashActivity extends Activity {
  FlashActivity._(super.json, super.assets)
    : options = _options(json['answer']),
      correctId = _map(json['answer'])['correct']! as String,
      group = SpriteSet.fromJson(_map(json['scene'])['group']),
      flashMs = _map(json['scene'])['flashMs']! as int,
      super._();

  final List<ChoiceOption> options;
  final String correctId;
  final SpriteSet group;
  final int flashMs;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
  };
}

class CountTapActivity extends Activity {
  CountTapActivity._(super.json, super.assets)
    : options = _options(json['answer']),
      correctId = _map(json['answer'])['correct']! as String,
      count = _map(_map(_map(json['scene'])['objects']))['count']! as int,
      arrangement = _map(_map(json['scene'])['objects'])['arrangement']! as String,
      onTap = _map(_map(json['scene'])['objects'])['onTap']! as String,
      seed = _map(_map(json['scene'])['objects'])['seed']! as int,
      sprite = _map(_map(json['scene'])['objects'])['sprite']! as String,
      litSprite = _map(_map(json['scene'])['objects'])['litSprite']! as String,
      targetSprite = _map(_map(json['scene'])['target'])['sprite']! as String,
      answerPrompt = Spoken.fromJson(json['answerPrompt']),
      traceTags = <String, String>{
        for (final Map<String, Object?> c in _maps(json['traceClassifiers']))
          c['when']! as String: c['misconception']! as String,
      },
      super._();

  final List<ChoiceOption> options;
  final String correctId;
  final int count;

  /// `line` or `scatter`.
  final String arrangement;

  /// `fly_to_target` or `glow`.
  final String onTap;
  final int seed;
  final String sprite;
  final String litSprite;
  final String targetSprite;

  /// Asked once every object has been counted: "how many?".
  final Spoken answerPrompt;

  /// `same_object_tapped_twice` and `object_never_tapped` to the tag each one is evidence for.
  final Map<String, String> traceTags;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
    ...traceTags.values,
  };
}

class GiveNActivity extends Activity {
  GiveNActivity._(super.json, super.assets)
    : n = _map(json['answer'])['n']! as int,
      sourceCount = _map(_map(_map(json['scene'])['source']))['count']! as int,
      sourceSprite = _map(_map(json['scene'])['source'])['sprite']! as String,
      targetSprite = _map(_map(json['scene'])['target'])['sprite']! as String,
      classifiers = <String, String>{
        for (final Map<String, Object?> c in _maps(_map(json['answer'])['classifiers']))
          c['when']! as String: c['misconception']! as String,
      },
      super._();

  /// How many the child must give.
  final int n;
  final int sourceCount;
  final String sourceSprite;
  final String targetSprite;

  /// `took_all`, `took_more` or `took_fewer` to the tag each one is evidence for.
  final Map<String, String> classifiers;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => classifiers.values.toSet();
}

class Lesson {
  Lesson._(Map<String, Object?> json)
    : id = json['id']! as String,
      revision = json['revision']! as int,
      title = _caption(json['title']),
      itemIds = <String>[for (final Object? i in json['items']! as List<Object?>) i! as String],
      skillIds = <String>[for (final Object? s in json['skills']! as List<Object?>) s! as String],
      sequence = (json['sequence'] as int?) ?? 1000,
      stopAfterStruggles = 0,
      celebration = Spoken.fromJson(json['celebration']);

  /// A short lesson made on the spot for one skill's revisit (M8): the bell flag on the map. It is not in any pack.
  Lesson.mission({
    required this.id,
    required this.itemIds,
    required this.skillIds,
    required this.celebration,
    this.stopAfterStruggles = 0,
  }) : revision = 1,
       sequence = 1000,
       title = '';

  final String id;
  final int revision;
  final String title;
  final List<String> itemIds;
  final List<String> skillIds;

  /// Where the lesson sits on the path of its land (smaller comes first); 1000 for a lesson that has no place.
  final int sequence;

  /// A lesson that ends gently, with its celebration, once the child has needed the full help on this many activities in a
  /// row (the placement warm-up: it must never become a string of failures). 0 means it never stops early.
  final int stopAfterStruggles;
  final Spoken celebration;
}

/// A skill of the pack, for the learning engine.
class SkillDoc {
  SkillDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      domain = json['domain']! as String,
      title = _caption(json['title']),
      prerequisites = <String, double>{
        for (final Map<String, Object?> p in _maps(json['prerequisites']))
          p['skill']! as String: (p['weight']! as num).toDouble(),
      },
      representations = <String>[
        for (final Object? r in json['representations']! as List<Object?>) r! as String,
      ],
      misconceptions = <String>[
        for (final Object? t in json['misconceptions']! as List<Object?>) t! as String,
      ],
      worldObject = json['worldObject'] as String?,
      childLine = json['childLine'] == null ? null : _caption(json['childLine']),
      core = (json['core'] as bool?) ?? false,
      masteryRequires = (json['masteryRequires'] as Map<String, Object?>?) ?? const <String, Object?>{},
      initialStabilityDays = (_map(json['retention'])['initialStabilityDays']! as num).toDouble(),
      targetRetention = (_map(json['retention'])['targetRetention']! as num).toDouble();

  final String id;

  /// One of the domains (`numbers`, `colors`, ...), and the skill as a plain sentence of what the child can do.
  final String domain;
  final String title;
  final Map<String, double> prerequisites;
  final List<String> representations;
  final List<String> misconceptions;

  /// Which drawing grows for this skill (an id of the app's world art), or null: the app's own catalog then decides.
  final String? worldObject;

  /// One line for the child, with niqqud, of what they can do; or null.
  final String? childLine;
  final bool core;
  final Map<String, Object?> masteryRequires;
  final double initialStabilityDays;
  final double targetRetention;
}

/// A misconception of the pack.
class TagDoc {
  TagDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      parentText = json['parentText']! as String,
      homeActivity = json['homeActivity'] == null ? null : _caption(json['homeActivity']),
      skills = <String>[for (final Object? s in json['skills']! as List<Object?>) s! as String],
      repairActivities = <String>[
        for (final Object? a in json['repairActivities']! as List<Object?>) a! as String,
      ],
      preferredRepresentations = <String>[
        for (final Object? r in json['preferredRepresentations']! as List<Object?>) r! as String,
      ];

  final String id;

  /// What a parent reads about this misunderstanding, in plain Hebrew.
  final String parentText;

  /// Something a parent can do at home in about five minutes, or null.
  final String? homeActivity;
  final List<String> skills;
  final List<String> repairActivities;
  final List<String> preferredRepresentations;
}

/// The pictures of a pack, by asset id, as SVG text. Nothing else is ever drawn from a pack.
class PackAssets {
  PackAssets(Map<String, String> svg) : _svg = svg;

  factory PackAssets.fromPack(VerifiedPack pack) {
    final Map<String, String> svg = <String, String>{};
    for (final Map<String, Object?> a in _maps(pack.manifest['assets'])) {
      final Uint8List? bytes = pack.files[a['file']! as String];
      if (bytes != null) svg[a['id']! as String] = utf8.decode(bytes);
    }
    return PackAssets(svg);
  }

  final Map<String, String> _svg;

  /// The SVG text of an `asset:<id>` reference.
  String svg(String ref) => _svg[ref.substring('asset:'.length)]!;
}

/// A verified pack, ready to be played.
class PackContent {
  PackContent._({
    required this.packId,
    required this.packVersion,
    required this.lessons,
    required this.activities,
    required this.assets,
    required this.skills,
    required this.tags,
  });

  factory PackContent.fromPack(VerifiedPack pack) {
    final PackAssets assets = PackAssets.fromPack(pack);
    final Map<String, Lesson> lessons = <String, Lesson>{};
    final Map<String, Activity> activities = <String, Activity>{};
    final Map<String, SkillDoc> skills = <String, SkillDoc>{};
    final Map<String, TagDoc> tags = <String, TagDoc>{};
    for (final MapEntry<String, Object?> d in pack.docs.entries) {
      final Map<String, Object?> doc = _map(d.value);
      if (d.key.startsWith('lesson.')) {
        final Lesson l = Lesson._(doc);
        lessons[l.id] = l;
      } else if (d.key.startsWith('skill.')) {
        final SkillDoc s = SkillDoc._(doc);
        skills[s.id] = s;
      } else if (d.key.startsWith('misconception.')) {
        final TagDoc t = TagDoc._(doc);
        tags[t.id] = t;
      } else if (d.key.startsWith('activity.')) {
        final Activity a = Activity.fromJson(doc, assets);
        activities[a.id] = a;
      }
    }
    return PackContent._(
      packId: pack.id,
      packVersion: pack.version,
      lessons: lessons,
      activities: activities,
      assets: assets,
      skills: skills,
      tags: tags,
    );
  }

  final String packId;
  final String packVersion;
  final Map<String, Lesson> lessons;
  final Map<String, Activity> activities;
  final PackAssets assets;
  final Map<String, SkillDoc> skills;
  final Map<String, TagDoc> tags;

  /// The activities of a lesson, in order.
  List<Activity> itemsOf(Lesson lesson) => <Activity>[
    for (final String id in lesson.itemIds) activities[id]!,
  ];
}
