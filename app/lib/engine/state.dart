import 'retention.dart';
import 'types.dart';

/// What the child sees of a skill (a seedling, a leafy plant, a tree) and what the parent reads.
enum SkillStatus { notStarted, ready, learning, freshMastery, durableMastery, needsRevisit, gap }

/// Everything the engine knows about one skill of one child. Built by replaying the attempts.
class SkillState {
  SkillState(this.p);

  /// The estimate that the child knows the skill (BKT).
  double p;
  int n = 0;
  int nCorrect = 0;
  int nUnsure = 0;

  /// Answers right without any hint, outside probes.
  int successes = 0;
  final Set<int> successDays = <int>{};
  final Set<Representation> representationsPassed = <Representation>{};
  final Set<CheckType> checksPassed = <CheckType>{};
  final Set<String> successItems = <String>{};
  Set<String> itemsAtFresh = <String>{};
  DateTime? freshAt;
  DateTime? durableAt;

  /// A delayed check was failed and not yet passed again.
  bool needsRevisit = false;
  MemoryState? memory;
  int? lastReviewDay;
  DateTime? lastAttemptAt;
  String? lastItem;
  String? lastVariantGroup;
  Representation? lastRepresentation;

  /// Wrong answers in a row, "not sure" in a row, and the tags of the wrong answers in that run.
  int failRun = 0;
  int unsureRun = 0;
  final List<String> runTags = <String>[];
  int lastHintLevel = 0;
  bool assumed = false;

  bool get started => n > 0;
}

enum TagStatus { suspected, active, resolved }

/// Evidence for one misconception of one child.
class TagState {
  double score = 0;
  final Set<String> items = <String>{};
  int cleanRuns = 0;
  TagStatus status = TagStatus.suspected;
  DateTime? lastSeen;
}

/// A skill the child is missing, found by walking down from a skill they failed.
class Gap {
  Gap({
    required this.origin,
    required this.skill,
    required this.foundAt,
    required this.probes,
    required this.via,
  });

  /// The skill the child was failing, and the skill below it that is missing (equal if the gap is in the skill itself).
  final String origin;
  final String skill;
  final DateTime foundAt;
  final int probes;

  /// `walk` (found by probing) or `budget` (the probes ran out and the deepest failure was taken).
  final String via;
  int repairSuccesses = 0;
  DateTime? repairedAt;

  bool get repaired => repairedAt != null;
}

/// A search for a gap that is under way.
class GapSearch {
  GapSearch({required this.origin, required this.startedAt, required this.traceSkills});

  final String origin;
  final DateTime startedAt;

  /// Skills the misconception tags of the failures point at (most likely cause first).
  final List<String> traceSkills;

  /// The chain of failed skills, from the origin down; the last one is where the search stands.
  late final List<String> path = <String>[origin];
  final Set<String> cleared = <String>{};
  final Set<String> failed = <String>{};
  int probes = 0;

  /// The skill whose probe is being answered, and whether its first item was right (a confirming item is due).
  String? target;
  bool firstCorrect = false;
}

/// How often each way of explaining worked for a child, per skill family.
class RepStats {
  int tries = 0;
  int successes = 0;
}

/// One child's whole state. Never stored: always the result of replaying `attempt` rows.
class EngineState {
  final Map<String, SkillState> skills = <String, SkillState>{};
  final Map<String, TagState> tags = <String, TagState>{};
  final List<Gap> gaps = <Gap>[];
  GapSearch? search;

  /// Per `family|representation`.
  final Map<String, RepStats> representations = <String, RepStats>{};

  /// Per session id: the answers in order (activity id, result, hint level, skill), for the stuck rules.
  final Map<int, List<SessionAnswer>> sessions = <int, List<SessionAnswer>>{};

  /// How many probes each session has used.
  final Map<int, int> probesInSession = <int, int>{};

  /// Skills first attempted in each session.
  final Map<int, Set<String>> newSkillsInSession = <int, Set<String>>{};

  DateTime? lastEventAt;

  RepStats repStats(String family, Representation r) => representations['$family|${r.name}'] ??= RepStats();

  List<Gap> get openGaps => <Gap>[
    for (final Gap g in gaps)
      if (!g.repaired) g,
  ];

  Iterable<String> get activeTags => <String>[
    for (final MapEntry<String, TagState> e in tags.entries)
      if (e.value.status == TagStatus.active) e.key,
  ];
}

class SessionAnswer {
  const SessionAnswer({
    required this.activityId,
    required this.skillId,
    required this.result,
    required this.hintLevel,
  });

  final String activityId;
  final String skillId;
  final Result result;
  final int hintLevel;
}
