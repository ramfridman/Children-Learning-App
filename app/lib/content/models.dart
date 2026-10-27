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

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    this.value,
    this.sprite,
    this.label,
    this.misconception,
    this.speech = const <String>[],
  });

  final String id;

  /// The number a count option shows (`count_tap`).
  final int? value;

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
      super._();

  final List<ChoiceOption> options;
  final String correctId;

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
      celebration = Spoken.fromJson(json['celebration']);

  final String id;
  final int revision;
  final String title;
  final List<String> itemIds;
  final List<String> skillIds;
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
