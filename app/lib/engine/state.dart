import 'retention.dart';
import 'types.dart';

/// What the child sees of a skill (a seedling, a leafy plant, a tree) and what the parent reads.
enum SkillStatus {
  notStarted,
  ready,
  learning,
  freshMastery,
  durableMastery,
  needsRevisit,
  gap,

  /// A trace node (E-1) with every letter traced once with the start dot: met, and never anything more.
  practised,
}

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

  /// How many of the successes were spoken (LS09). At most half of a speaking skill's successes may be.
  int speechSuccesses = 0;
  final Set<int> successDays = <int>{};
  final Set<Representation> representationsPassed = <Representation>{};
  final Set<CheckType> checksPassed = <CheckType>{};
  final Set<String> successItems = <String>{};

  /// The variant groups (the words, or the letters of a set skill) answered right without a hint, outside probes.
  final Set<String> successGroups = <String>{};
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

  /// The way of explaining in which the child last got this skill wrong (a probe counts).
  Representation? lastFailedRepresentation;

  /// Wrong answers in a row, "not sure" in a row, and the tags of the wrong answers in that run.
  int failRun = 0;
  int unsureRun = 0;
  final List<String> runTags = <String>[];
  int lastHintLevel = 0;
  bool assumed = false;

  /// Writing (E-1). Answers of a trace node and of a trace item are practice: they are counted here and nowhere else.
  int practiceCount = 0;

  /// The letters (variant groups) of a trace node traced once with the start dot only.
  final Set<String> practisedGroups = <String>{};

  /// For a memory writing node: the days, the cues and the letters of its memory successes.
  final Set<int> memorySuccessDays = <int>{};
  final Set<WritingCue> memoryCues = <WritingCue>{};
  final Set<String> memoryGroups = <String>{};

  bool get started => n > 0 || practiceCount > 0;

  /// What the check visit reads of this skill's checks and visits.
  final CheckTrail trail = CheckTrail();
}

/// How a skill's checks went, for the check visit (docs/languages/band-a-build.md section 7.4): which balanced pairs are half answered,
/// which checks were failed and in what way of showing, what the last visit held. A visit is the answers of one session (one day when
/// the answers carry no session).
class CheckTrail {
  /// A balanced pair's item answered right without a hint, to the visit it was answered in (C-5).
  final Map<String, int> pairHalves = <String, int>{};

  /// The check types failed and not passed since, the items they were failed on, and the way of showing the last failed one used (C-4).
  final Set<CheckType> failedTypes = <CheckType>{};
  final Set<String> failedItems = <String>{};
  Representation? failedRepresentation;

  /// The visits in a row in which a check was failed, and whether the skill was taught again (a learn item answered in a visit after the
  /// last failure): after two failed visits the course offers the skill's lesson again before the next check visit (C-4).
  int failedVisits = 0;
  bool taughtSinceFail = true;
  int? _checkVisit;
  bool _checkVisitFailed = false;

  /// The visit of the skill's last answer, and the items answered in it (C-3: a word not asked in the last visit comes first).
  int? _lastVisit;
  Set<String> lastVisitItems = <String>{};

  bool get needsReteach => failedVisits >= 2 && !taughtSinceFail;

  /// Notes an answer of an item (not a probe) in [visit].
  void answered(String itemId, int visit) {
    if (visit != _lastVisit) {
      _lastVisit = visit;
      lastVisitItems = <String>{};
    }
    lastVisitItems.add(itemId);
  }

  /// A balanced pair's item was answered right without a hint: whether its partner was as well, in this visit, so that the pair counts.
  bool pairComplete(ItemMeta item, int visit) {
    final String? partner = item.pairWith;
    if (partner == null) return true;
    if (pairHalves[partner] == visit) {
      pairHalves.remove(partner);
      return true;
    }
    pairHalves[item.id] = visit;
    return false;
  }

  /// A check was answered in [visit]: wrongly, or right without a hint (any other answer says nothing of the check). [credited]: its
  /// type counted as passed (a half of a pair does not).
  void checkAnswered(ItemMeta item, int visit, {required bool wrong, bool credited = true}) {
    if (visit != _checkVisit) {
      if (!_checkVisitFailed) failedVisits = 0;
      _checkVisit = visit;
      _checkVisitFailed = false;
    }
    if (wrong) {
      failedTypes.add(item.checkType);
      failedItems.add(item.id);
      failedRepresentation = item.representation;
      taughtSinceFail = false;
      if (!_checkVisitFailed) failedVisits++;
      _checkVisitFailed = true;
    } else if (credited) {
      failedTypes.remove(item.checkType);
    }
  }

  /// A learn item, a practice or a repair item (anything but a check) was answered in [visit]: after a failed check, it taught again.
  void taught(int visit) {
    if (_checkVisitFailed && visit != _checkVisit) taughtSinceFail = true;
  }
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

  /// The skill whose probe is being answered, and how many of its items in a row were right so far.
  String? target;
  int correctRun = 0;
  int wrongRun = 0;
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

  /// Skills for which a search ended without finding anything missing below.
  final List<String> closedSearches = <String>[];

  /// Per `family|representation`.
  final Map<String, RepStats> representations = <String, RepStats>{};

  /// Per session id: the answers in order (activity id, result, hint level, skill), for the stuck rules.
  final Map<int, List<SessionAnswer>> sessions = <int, List<SessionAnswer>>{};

  /// How many probes each session has used.
  final Map<int, int> probesInSession = <int, int>{};

  /// Skills first attempted in each session.
  final Map<int, Set<String>> newSkillsInSession = <int, Set<String>>{};

  /// The words (variant groups) of a speaking skill's practice set that have been met, by whatever answer, spoken or not and
  /// counted as evidence or not. A speaking skill is met when its set is done (frame section 3.3.8). Kept apart from [skills]
  /// so that a spoken answer that counts for nothing still changes nothing there.
  final Map<String, Set<String>> metWords = <String, Set<String>>{};

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
