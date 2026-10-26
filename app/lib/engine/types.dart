// Plain data the engine works with. No clock, no database, no widgets: the app turns its pack documents and
// its `attempt` rows into these, and the simulator makes them up.

enum Result { correct, incorrect, unsure }

enum Representation { concrete, pictorial, story, embodied, symbolic }

enum Purpose { learn, practice, probe, repair, check }

enum CheckType { practice, transfer, reverse, errorSpotting, explainBack, predict }

Result resultOf(String s) => switch (s) {
  'correct' => Result.correct,
  'unsure' => Result.unsure,
  _ => Result.incorrect,
};

Representation? representationOf(String s) {
  for (final Representation r in Representation.values) {
    if (r.name == s) return r;
  }
  return null;
}

Purpose purposeOf(String s) {
  for (final Purpose p in Purpose.values) {
    if (p.name == s) return p;
  }
  return Purpose.practice;
}

CheckType checkTypeOf(String s) => switch (s) {
  'transfer' => CheckType.transfer,
  'reverse' => CheckType.reverse,
  'error_spotting' => CheckType.errorSpotting,
  'explain_back' => CheckType.explainBack,
  'predict' => CheckType.predict,
  _ => CheckType.practice,
};

/// A skill of the graph.
class SkillNode {
  const SkillNode({
    required this.id,
    this.prerequisites = const <String, double>{},
    this.core = false,
    this.representations = const <Representation>{},
    this.tags = const <String>{},
    this.initialStabilityDays = 1,
    this.targetRetention,
  });

  final String id;

  /// Prerequisite skill id to the weight of the edge (0 to 1).
  final Map<String, double> prerequisites;

  /// A core skill (three or more skills depend on it) needs more evidence for mastery.
  final bool core;
  final Set<Representation> representations;

  /// Misconception tags to watch for in this skill.
  final Set<String> tags;
  final double initialStabilityDays;
  final double? targetRetention;

  /// The family of a skill for the representation statistics: its id without the number (`NUM-A`).
  String get family => id.contains('-') ? id.substring(0, id.lastIndexOf('-')) : id;
}

/// What the engine needs to know about an activity.
class ItemMeta {
  const ItemMeta({
    required this.id,
    required this.skills,
    this.purpose = Purpose.practice,
    this.checkType = CheckType.practice,
    this.representation = Representation.concrete,
    this.variantGroup = '',
    this.difficulty = 0.5,
    this.optionCount = 0,
    this.tags = const <String>{},
    this.contradicts,
    this.delight = false,
    this.revision = 1,
  });

  final String id;

  /// Skill id to the weight of the evidence this item gives for it.
  final Map<String, double> skills;
  final Purpose purpose;
  final CheckType checkType;
  final Representation representation;
  final String variantGroup;

  /// Authored difficulty from 0 (easy) to 1 (hard).
  final double difficulty;

  /// How many choices the child has; 0 for an open task (drag, trace, give).
  final int optionCount;

  /// The misconceptions this item's wrong answers can show.
  final Set<String> tags;

  /// The misconception this item is built to expose (used after a repair).
  final String? contradicts;
  final bool delight;
  final int revision;

  String get primarySkill => skills.keys.first;
}

/// A misconception of the catalogue.
class TagInfo {
  const TagInfo({
    required this.id,
    this.skills = const <String>[],
    this.repairActivities = const <String>[],
    this.preferredRepresentations = const <Representation>[],
  });

  final String id;

  /// The skills this misconception traces back to, most likely first.
  final List<String> skills;
  final List<String> repairActivities;
  final List<Representation> preferredRepresentations;
}

/// One answer, as the `attempt` table holds it.
class AttemptEvent {
  const AttemptEvent({
    required this.at,
    required this.activityId,
    required this.result,
    this.hintLevel = 0,
    this.tag = '',
    this.sessionId,
    this.attemptNo = 1,
    this.id = 0,
  });

  final int id;
  final DateTime at;
  final String activityId;
  final Result result;
  final int hintLevel;
  final String tag;
  final int? sessionId;
  final int attemptNo;
}

/// Skills, items and misconceptions together.
class Catalog {
  Catalog({
    required Iterable<SkillNode> skills,
    required Iterable<ItemMeta> items,
    Iterable<TagInfo> tags = const <TagInfo>[],
  }) : skills = <String, SkillNode>{for (final SkillNode s in skills) s.id: s},
       items = <String, ItemMeta>{for (final ItemMeta i in items) i.id: i},
       tags = <String, TagInfo>{for (final TagInfo t in tags) t.id: t};

  final Map<String, SkillNode> skills;
  final Map<String, ItemMeta> items;
  final Map<String, TagInfo> tags;

  List<ItemMeta> itemsFor(String skillId) => <ItemMeta>[
    for (final ItemMeta i in items.values)
      if (i.skills.containsKey(skillId)) i,
  ];
}
