// Plain data the engine works with. No clock, no database, no widgets: the app turns its pack documents and
// its `attempt` rows into these, and the simulator makes them up.

import 'course.dart';

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

/// How a spelling skill treats an answer that writes every sound with a spelling the author listed but is not the book
/// spelling (docs/languages/frame.md section 3.3.5). A skill either accepts it as correct while the convention has not
/// been taught, or teaches the convention and counts it as a mistake.
enum SoundRightPolicy { accepts, teaches }

/// How a skill of letter writing is mastered (docs/languages/writing-mastery.md, rule E-1). A `memory` node (copy and memory writing)
/// is fresh only with memory successes on two days, one cued by the sound and one by the name. A `practised` node (tracing, the
/// pre-writing strokes, the own name) is never mastered: it is met once every letter of it was traced with the start dot only.
enum WritingRule { memory, practised }

/// What an LS02 item asks of the child. Tracing is practice, a copy counts like an answer with one more hint, and a memory answer
/// counts in full.
enum WritingMode { trace, copy, memory }

/// What the voice says in a memory item: the letter's sound, or its name.
enum WritingCue { sound, name }

/// A skill of the graph.
class SkillNode {
  const SkillNode({
    required this.id,
    this.course = Course.core,
    this.prerequisites = const <String, double>{},
    this.core = false,
    this.representations = const <Representation>{},
    this.tags = const <String>{},
    this.initialStabilityDays = 1,
    this.targetRetention,
    this.needSuccesses,
    this.needDays,
    this.needRepresentations,
    this.needChecks,
    this.bundle,
    this.setCoverage = false,
    this.soundRight = SoundRightPolicy.teaches,
    this.letters = false,
    this.speaking = false,
    this.writing,
  });

  final String id;

  /// A skill of letter writing (E-1), or null for every other skill.
  final WritingRule? writing;

  /// A speaking skill (strand `spk`): the only kind that spoken answers count for.
  final bool speaking;

  /// The course this skill belongs to (`core` for every land that exists today). A skill never relates to another course.
  final String course;

  /// Prerequisite skill id to the weight of the edge (0 to 1).
  final Map<String, double> prerequisites;

  /// A core skill (three or more skills depend on it) needs more evidence for mastery.
  final bool core;
  final Set<Representation> representations;

  /// Misconception tags to watch for in this skill.
  final Set<String> tags;
  final double initialStabilityDays;
  final double? targetRetention;

  /// What this skill needs for fresh mastery, when it differs from the engine's defaults.
  final int? needSuccesses;
  final int? needDays;
  final int? needRepresentations;
  final int? needChecks;

  /// The letter bundle this skill is a facet of (shape, sound, name or writing of one letter group). The facets of a bundle
  /// are introduced together and count as one new skill; mastery stays per facet.
  final String? bundle;

  /// A set skill (a set of words, or the letters of a group): its items rotate through the words, and fresh mastery also
  /// needs every word answered right once without a hint.
  final bool setCoverage;

  /// What a spelling that is right by sound counts as in this skill.
  final SoundRightPolicy soundRight;

  /// The skill is letter work: it is never offered under the youngest presentation band (Hebrew A-10 to A-12 aside).
  final bool letters;

  /// The same skill with other prerequisites (the catalogue replaces a roll-up by its groups).
  SkillNode withPrerequisites(Map<String, double> prerequisites) => SkillNode(
    id: id,
    course: course,
    prerequisites: prerequisites,
    core: core,
    representations: representations,
    tags: tags,
    initialStabilityDays: initialStabilityDays,
    targetRetention: targetRetention,
    needSuccesses: needSuccesses,
    needDays: needDays,
    needRepresentations: needRepresentations,
    needChecks: needChecks,
    bundle: bundle,
    setCoverage: setCoverage,
    soundRight: soundRight,
    letters: letters,
    speaking: speaking,
    writing: writing,
  );

  /// The family of a skill for the representation statistics: its id without the number (`NUM-A`).
  String get family => id.contains('-') ? id.substring(0, id.lastIndexOf('-')) : id;
}

/// What the engine needs to know about an activity.
class ItemMeta {
  const ItemMeta({
    required this.id,
    required this.skills,
    this.course = Course.core,
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
    this.writingMode,
    this.cue,
    this.startGuide = false,
    this.practiceOnly = false,
    this.pairWith,
    this.speech = false,
  });

  final String id;

  /// A say step (LS09): its answer is a word the child says, which the microphone, when the parent turned it on, may hear. A word that only
  /// such steps ask is never a word a skill's fresh mastery waits for ([Catalog.coverageGroupsOf]): without the microphone nothing could
  /// ever cover it (a speaking skill is met when its set is met, whatever the answer; docs/languages/frame.md section 3.3.8).
  final bool speech;

  /// The item that forms a balanced pair with this one (a yes and a no, docs/languages/frame.md section 2.3), or null. The check type of
  /// either counts only when both are answered right, without a hint, in one visit ([Engine] enforces it): one half alone has a
  /// 1 in 2 chance of being a guess.
  final String? pairWith;

  /// The mode of an LS02 2.0 item; null for every item that is not one (the tracing of the lands keeps its behaviour).
  final WritingMode? writingMode;

  /// The cue of a memory item.
  final WritingCue? cue;

  /// A trace with the start dot only (or an own-name item): its success marks the letter as practised.
  final bool startGuide;

  /// A handwriting step that is only practice, whatever skill it names (`"practice": true` on a word canvas).
  final bool practiceOnly;

  /// The course of the item: the course of every skill, tag and repair it names.
  final String course;

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
    this.course = Course.core,
    this.skills = const <String>[],
    this.repairActivities = const <String>[],
    this.preferredRepresentations = const <Representation>[],
  });

  final String id;
  final String course;

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
    this.course,
    this.viaSpeech = false,
  });

  final int id;
  final DateTime at;
  final String activityId;

  /// The course of the pack the answer was given in, when it is known (the app's rows always know it). An answer of another
  /// course than its item's is no evidence for that item: two packs that share an activity id never share evidence
  /// (docs/languages/frame.md section 1.5, invariant 3). Null: not said, and the answer is taken as it is (tests, simulator).
  final String? course;
  final Result result;
  final int hintLevel;
  final String tag;
  final int? sessionId;
  final int attemptNo;

  /// The answer is a word the child said and the per-word matcher heard (LS09, docs/languages/frame.md section 5.1). Speech is
  /// evidence for a speaking skill only, and at most half of that skill's successes ([Engine] enforces both).
  final bool viaSpeech;
}

/// Skills, items and misconceptions together.
class Catalog {
  Catalog({
    required Iterable<SkillNode> skills,
    required Iterable<ItemMeta> items,
    Iterable<TagInfo> tags = const <TagInfo>[],
  }) : skills = _resolveRollUps(skills),
       items = <String, ItemMeta>{for (final ItemMeta i in items) i.id: i},
       tags = <String, TagInfo>{for (final TagInfo t in tags) t.id: t};

  /// The skills, with a prerequisite on a roll-up already replaced by the roll-up's groups (so "needs `HEB-B-14`" means
  /// "needs every group of it", docs/languages/frame.md section 3.3.2, and no other code has to know).
  final Map<String, SkillNode> skills;
  final Map<String, ItemMeta> items;
  final Map<String, TagInfo> tags;

  /// Each roll-up skill to its groups (the skills whose id is the roll-up's, a dot and a suffix), in id order. A roll-up has
  /// no estimate or items of its own: it is mastered when all its groups are.
  late final Map<String, List<String>> subSkills = () {
    final Map<String, List<String>> out = <String, List<String>>{};
    for (final String id in skills.keys) {
      final String? parent = SkillIds.parentOf(id);
      if (parent != null && skills.containsKey(parent)) (out[parent] ??= <String>[]).add(id);
    }
    for (final List<String> groups in out.values) {
      groups.sort();
    }
    return out;
  }();

  bool isRollUp(String id) => subSkills.containsKey(id);

  /// The facets of each letter bundle, in id order.
  late final Map<String, List<String>> bundles = () {
    final Map<String, List<String>> out = <String, List<String>>{};
    for (final SkillNode s in skills.values) {
      if (s.bundle != null) (out[s.bundle!] ??= <String>[]).add(s.id);
    }
    for (final List<String> members in out.values) {
      members.sort();
    }
    return out;
  }();

  /// What counts as one new skill against the limit per session: the skill's bundle, or the skill itself.
  String unitOf(String skillId) => skills[skillId]?.bundle ?? skillId;

  /// The variant groups (the words, or the letters) of a set skill, from its items. Items for practice and checks count;
  /// probes and free play do not.
  late final Map<String, Set<String>> _groups = () {
    final Map<String, Set<String>> out = <String, Set<String>>{};
    for (final ItemMeta i in items.values) {
      if (i.purpose == Purpose.probe || i.delight || i.variantGroup.isEmpty) continue;
      for (final String skill in i.skills.keys) {
        (out[skill] ??= <String>{}).add(i.variantGroup);
      }
    }
    return out;
  }();

  Set<String> variantGroupsOf(String skillId) => _groups[skillId] ?? const <String>{};

  /// The words fresh mastery of a set skill waits for: [variantGroupsOf] less the words that only say steps ask.
  late final Map<String, Set<String>> _coverage = _groupsWhere(
    (ItemMeta i) => !i.speech && i.purpose != Purpose.probe,
  );

  Set<String> coverageGroupsOf(String skillId) => _coverage[skillId] ?? const <String>{};

  /// The letters of a writing skill that a memory success must cover: the variant groups of its memory items, probes aside.
  late final Map<String, Set<String>> _memoryGroups = _groupsWhere(
    (ItemMeta i) => i.writingMode == WritingMode.memory && i.purpose != Purpose.probe,
  );

  /// The letters of a trace node that must each be traced once with the start dot: the groups of its start-dot items.
  late final Map<String, Set<String>> _practiceGroups = _groupsWhere((ItemMeta i) => i.startGuide);

  Map<String, Set<String>> _groupsWhere(bool Function(ItemMeta) test) {
    final Map<String, Set<String>> out = <String, Set<String>>{};
    for (final ItemMeta i in items.values) {
      if (i.delight || i.variantGroup.isEmpty || !test(i)) continue;
      for (final String skill in i.skills.keys) {
        (out[skill] ??= <String>{}).add(i.variantGroup);
      }
    }
    return out;
  }

  Set<String> memoryGroupsOf(String skillId) => _memoryGroups[skillId] ?? const <String>{};

  Set<String> practiceGroupsOf(String skillId) => _practiceGroups[skillId] ?? const <String>{};

  static Map<String, SkillNode> _resolveRollUps(Iterable<SkillNode> raw) {
    final Map<String, SkillNode> byId = <String, SkillNode>{for (final SkillNode s in raw) s.id: s};
    final Map<String, List<String>> groups = <String, List<String>>{};
    for (final String id in byId.keys) {
      final String? parent = SkillIds.parentOf(id);
      if (parent != null && byId.containsKey(parent)) (groups[parent] ??= <String>[]).add(id);
    }
    if (groups.isEmpty) return byId;
    return <String, SkillNode>{
      for (final MapEntry<String, SkillNode> e in byId.entries)
        e.key: e.value.prerequisites.keys.any(groups.containsKey)
            ? e.value.withPrerequisites(<String, double>{
                for (final MapEntry<String, double> p in e.value.prerequisites.entries)
                  if (groups.containsKey(p.key))
                    for (final String g in groups[p.key]!) g: p.value
                  else
                    p.key: p.value,
              })
            : e.value,
    };
  }

  List<ItemMeta> itemsFor(String skillId) => <ItemMeta>[
    for (final ItemMeta i in items.values)
      if (i.skills.containsKey(skillId)) i,
  ];

  /// The courses that have at least one skill here.
  Set<String> get courses => <String>{for (final SkillNode s in skills.values) s.course};

  /// Only [course]: its skills, its items and its misconception tags. A visit plays one course, and an engine built on this
  /// view cannot see, serve or learn from another course's data.
  Catalog forCourse(String course) => Catalog(
    skills: skills.values.where((SkillNode s) => s.course == course),
    items: items.values.where((ItemMeta i) => i.course == course),
    tags: tags.values.where((TagInfo t) => t.course == course),
  );
}
