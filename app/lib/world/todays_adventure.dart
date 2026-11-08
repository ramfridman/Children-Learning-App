import '../engine/age.dart' show SchoolStage;
import 'adventure_land.dart';
import 'lesson_path.dart';

/// Today's Adventure: the one stop the bottle in the child's home opens (B-26 step 5; the rule and its worked examples are
/// `docs/curriculum/todays-adventure-rule.md`). A pure function of plain values and an explicit day number: no clock, no
/// random source, no database and no UI, so the same input always gives the same stop and every tie has a fixed order
/// (the map order of the lands, the place on the path, the skill id). `world/adventure_adapter.dart` fills the input from
/// the app's real data.

enum AdventureKind { revisit, lesson, replay, none }

/// [checkVisit]: a language course's check visit, the short visit of one skill on a later day that gives it the evidence a lesson cannot
/// (docs/languages/band-a-build.md section 7.4). The child sees a visit, like a revisit; nothing says "check" or "test".
enum AdventureReason { welcome, callForHelp, checkVisit, sameLand, otherLand, playAgain, nothing }

/// What one visit of the child was.
enum VisitKind { lesson, warmUp, revisit }

/// How a visit ended: the session's own word, or [open] when it has none.
enum VisitEnd { finished, home, limit, open }

/// How many lessons come between two revisits in a day, and how many lessons in a row stay in one land. One table per
/// age band today (all the same); the parent-confirmed school stage (B-29) will choose a row here and nowhere else.
class AdventureParams {
  const AdventureParams({required this.newAfterRevisit, required this.stayInLand});

  final int newAfterRevisit;
  final int stayInLand;
}

const List<AdventureParams> _paramsByBand = <AdventureParams>[
  AdventureParams(newAfterRevisit: 2, stayInLand: 3),
  AdventureParams(newAfterRevisit: 2, stayInLand: 3),
  AdventureParams(newAfterRevisit: 2, stayInLand: 3),
];

AdventureParams paramsFor({required int band}) => _paramsByBand[band.clamp(0, _paramsByBand.length - 1)];

/// The row the school stage chooses (B-29 step 8): the stage the parent confirmed, or the middle of the band. The stage sets the row through
/// its band and nothing else: no age, no birth month and no look reaches the rule.
AdventureParams paramsForStage(SchoolStage stage) => paramsFor(band: stage.band);

/// A lesson on a land's path with its level: 0, 1 or 2 for the bands A, B and C. A [locked] lesson has a skill that is not unlocked
/// yet (the path gate, `path_gate.dart`): the path skips it and comes back to it.
class PathLesson {
  const PathLesson(this.id, this.level, {this.locked = false});

  final String id;
  final int level;
  final bool locked;
}

/// One visit of the child, built from their answers: [id] is the lesson id (a revisit: the skill id).
class Visit {
  const Visit({
    required this.kind,
    required this.land,
    required this.id,
    required this.day,
    this.end = VisitEnd.finished,
    this.lastIncorrect = false,
    this.check = false,
  });

  final VisitKind kind;
  final AdventureLand land;
  final String id;

  /// `Engine.dayKey` of the visit's last answer.
  final int day;
  final VisitEnd end;

  /// The visit's last answer was incorrect (an unsure answer is never incorrect).
  final bool lastIncorrect;

  /// A revisit that was a course's check visit (`mission-<skill>-check`), not the revisit of a fresh skill.
  final bool check;
}

/// A skill whose check is due, in a land the bottle may open.
class DueSkill {
  const DueSkill({
    required this.skillId,
    required this.land,
    required this.dueAt,
    this.reviewedToday = false,
    this.check = false,
    this.reteachLessonId,
  });

  final String skillId;
  final AdventureLand land;
  final DateTime dueAt;

  /// A course's check visit (the skill's lessons are done, it is not fresh yet) and not the revisit of a fresh skill. It comes after
  /// every revisit of a fresh skill, in the revisit's slot (owner's OK 2026-11-07).
  final bool check;

  /// A check visit whose skill failed its checks on two visits in a row: the lesson to play again before the next check visit.
  final String? reteachLessonId;

  /// The engine already took today's memory review of this skill, so a second check only feels like being asked again.
  final bool reviewedToday;
}

class AdventureInput {
  const AdventureInput({
    required this.today,
    required this.band,
    required this.enabledLands,
    required this.paths,
    this.finished = const <String, int>{},
    this.visits = const <Visit>[],
    this.due = const <DueSkill>[],
  });

  /// `Engine.dayKey` of now.
  final int today;
  final int band;
  final Set<AdventureLand> enabledLands;

  /// Each land's lessons in path order.
  final Map<AdventureLand, List<PathLesson>> paths;

  /// How many times each lesson was finished.
  final Map<String, int> finished;

  /// The child's visits, oldest first.
  final List<Visit> visits;
  final List<DueSkill> due;
}

class TodaysAdventure {
  const TodaysAdventure._(this.kind, this.reason, {this.land, this.lessonId, this.skillId});

  const TodaysAdventure.none() : this._(AdventureKind.none, AdventureReason.nothing);

  /// A call for help: the revisit of [skillId].
  const TodaysAdventure.revisit(AdventureLand land, String skillId)
    : this._(AdventureKind.revisit, AdventureReason.callForHelp, land: land, skillId: skillId);

  /// A course's check visit of [skillId] (a revisit by kind: it takes the revisit's slot).
  const TodaysAdventure.checkVisit(AdventureLand land, String skillId)
    : this._(AdventureKind.revisit, AdventureReason.checkVisit, land: land, skillId: skillId);

  /// The land's next lesson, as the path offers it (before any warm-up).
  const TodaysAdventure.lesson(AdventureLand land, String? lessonId, AdventureReason reason)
    : this._(AdventureKind.lesson, reason, land: land, lessonId: lessonId);

  const TodaysAdventure.replay(AdventureLand land, String lessonId)
    : this._(AdventureKind.replay, AdventureReason.playAgain, land: land, lessonId: lessonId);

  final AdventureKind kind;
  final AdventureReason reason;
  final AdventureLand? land;

  /// A lesson or a replay: the lesson to play.
  final String? lessonId;

  /// A revisit: the skill to check.
  final String? skillId;

  @override
  bool operator ==(Object other) =>
      other is TodaysAdventure &&
      other.kind == kind &&
      other.reason == reason &&
      other.land == land &&
      other.lessonId == lessonId &&
      other.skillId == skillId;

  @override
  int get hashCode => Object.hash(kind, reason, land, lessonId, skillId);

  @override
  String toString() => 'TodaysAdventure($kind, $reason, $land, $lessonId, $skillId)';
}

/// The stop the bottle opens (rule section 4).
TodaysAdventure todaysAdventure(AdventureInput input, {AdventureParams? params}) {
  final AdventureParams p = params ?? paramsFor(band: input.band);
  // Map order, the `order` of each land: every sort below ends on it, so no input order can matter.
  final List<AdventureLand> lands = <AdventureLand>[
    for (final AdventureLand l in input.enabledLands)
      if ((input.paths[l] ?? const <PathLesson>[]).isNotEmpty) l,
  ]..sort((AdventureLand a, AdventureLand b) => a.order.compareTo(b.order));
  if (lands.isEmpty) return const TodaysAdventure.none();
  final _View v = _View(input, lands);

  final AdventureLand? newPick = _newLearning(v, p);
  final bool revisitAllowed =
      v.visitsSinceRevisitToday == null || v.visitsSinceRevisitToday! >= p.newAfterRevisit;
  final DueSkill? revisit = _firstDue(v);
  if (revisit != null && (revisitAllowed || newPick == null)) {
    if (revisit.reteachLessonId != null) {
      return TodaysAdventure.replay(revisit.land, revisit.reteachLessonId!);
    }
    return revisit.check
        ? TodaysAdventure.checkVisit(revisit.land, revisit.skillId)
        : TodaysAdventure.revisit(revisit.land, revisit.skillId);
  }
  if (newPick != null) {
    final AdventureReason reason = input.visits.isEmpty
        ? AdventureReason.welcome
        : newPick == v.current
        ? AdventureReason.sameLand
        : AdventureReason.otherLand;
    return TodaysAdventure.lesson(newPick, v.next(newPick), reason);
  }
  final TodaysAdventure? again = _playAgain(v);
  if (again != null) return again;
  // Only resting lessons are left: offered again from the start, an empty bottle would be worse.
  final AdventureLand land = v.current ?? lands.first;
  return TodaysAdventure.lesson(land, v.next(land), AdventureReason.sameLand);
}

/// The land that has new learning to offer, or null: stay in the current land for [AdventureParams.stayInLand]
/// lessons, then the lowest level first, the land not played for the longest time, the map order.
AdventureLand? _newLearning(_View v, AdventureParams p) {
  final List<AdventureLand> fresh = <AdventureLand>[
    for (final AdventureLand l in v.lands)
      if (v.hasNewLearning(l)) l,
  ];
  if (fresh.isEmpty) return null;
  if (v.current != null && fresh.contains(v.current) && v.run < p.stayInLand) return v.current;
  final List<AdventureLand> others = <AdventureLand>[
    for (final AdventureLand l in fresh)
      if (l != v.current) l,
  ];
  if (others.isEmpty) return v.current;
  others.sort((AdventureLand a, AdventureLand b) {
    final int byLevel = v.levelOfNext(a).compareTo(v.levelOfNext(b));
    if (byLevel != 0) return byLevel;
    final int byRecency = v.recency(a).compareTo(v.recency(b));
    return byRecency != 0 ? byRecency : a.order.compareTo(b.order);
  });
  return others.first;
}

/// The check that fell due earliest, in an open land and not taken today; at the same time the current land first. A course's check
/// visit comes after every revisit of a fresh skill.
DueSkill? _firstDue(_View v) {
  final List<DueSkill> waiting = <DueSkill>[
    for (final DueSkill d in v.input.due)
      if (v.lands.contains(d.land) && !d.reviewedToday) d,
  ];
  if (waiting.isEmpty) return null;
  waiting.sort((DueSkill a, DueSkill b) {
    final int byKind = (a.check ? 1 : 0).compareTo(b.check ? 1 : 0);
    if (byKind != 0) return byKind;
    final int byTime = a.dueAt.compareTo(b.dueAt);
    if (byTime != 0) return byTime;
    final int byCurrent = (a.land == v.current ? 0 : 1).compareTo(b.land == v.current ? 0 : 1);
    if (byCurrent != 0) return byCurrent;
    final int byLand = a.land.order.compareTo(b.land.order);
    return byLand != 0 ? byLand : a.skillId.compareTo(b.skillId);
  });
  return waiting.first;
}

/// Nothing new and nothing due: the lesson played fewest times, in the land not played for the longest time.
TodaysAdventure? _playAgain(_View v) {
  final Map<AdventureLand, List<PathLesson>> known = <AdventureLand, List<PathLesson>>{
    for (final AdventureLand l in v.lands)
      l: <PathLesson>[
        for (final PathLesson x in v.input.paths[l]!)
          if (v.count(x.id) >= 1 && !v.resting(x.id)) x,
      ],
  }..removeWhere((AdventureLand _, List<PathLesson> ls) => ls.isEmpty);
  if (known.isEmpty) return null;
  final List<AdventureLand> order = known.keys.toList()
    ..sort((AdventureLand a, AdventureLand b) {
      final int byRecency = v.recency(a).compareTo(v.recency(b));
      return byRecency != 0 ? byRecency : a.order.compareTo(b.order);
    });
  final AdventureLand land = order.first;
  PathLesson best = known[land]!.first;
  for (final PathLesson x in known[land]!) {
    if (v.count(x.id) < v.count(best.id)) best = x;
  }
  return TodaysAdventure.replay(land, best.id);
}

/// What the rule reads off the input, worked out once.
class _View {
  _View(this.input, this.lands) {
    final List<Visit> onPath = <Visit>[
      for (final Visit x in input.visits)
        if (x.kind != VisitKind.revisit) x,
    ];
    for (int i = 0; i < input.visits.length; i++) {
      final Visit x = input.visits[i];
      if (x.kind != VisitKind.revisit) _lastPathAt[x.land] = i;
      if (x.kind == VisitKind.lesson) _lastLesson[x.id] = x;
    }
    final AdventureLand? last = onPath.isEmpty ? null : onPath.last.land;
    current = last != null && lands.contains(last) ? last : null;
    if (current != null) {
      for (final Visit x in onPath.reversed) {
        if (x.land != current) break;
        if (x.kind == VisitKind.lesson && x.end == VisitEnd.finished) run++;
      }
    }
    int? sinceRevisit;
    for (final Visit x in input.visits) {
      if (x.day != input.today) continue;
      if (x.kind == VisitKind.revisit) {
        sinceRevisit = 0;
      } else if (sinceRevisit != null) {
        sinceRevisit++;
      }
    }
    visitsSinceRevisitToday = sinceRevisit;
  }

  final AdventureInput input;
  final List<AdventureLand> lands;
  final Map<AdventureLand, int> _lastPathAt = <AdventureLand, int>{};
  final Map<String, Visit> _lastLesson = <String, Visit>{};

  /// The land of the most recent lesson or warm-up, if it is open.
  late final AdventureLand? current;

  /// Lessons finished in a row in the current land (warm-ups and unfinished visits neither count nor stop it).
  int run = 0;

  /// Lessons and warm-ups since the most recent revisit of today, or null when there was no revisit today.
  late final int? visitsSinceRevisitToday;

  int count(String lessonId) => input.finished[lessonId] ?? 0;

  /// Where the land's most recent lesson or warm-up sits in the visits; −1 for a land never played.
  int recency(AdventureLand l) => _lastPathAt[l] ?? -1;

  /// Left today right after an incorrect answer: the bottle offers something else for the rest of the day.
  bool resting(String lessonId) {
    final Visit? x = _lastLesson[lessonId];
    return x != null && x.day == input.today && x.end == VisitEnd.home && x.lastIncorrect;
  }

  String? next(AdventureLand l) => nextOnPath(
    <String>[for (final PathLesson x in input.paths[l]!) x.id],
    input.finished,
    locked: <String>{
      for (final PathLesson x in input.paths[l]!)
        if (x.locked) x.id,
    },
  );

  bool hasNewLearning(AdventureLand l) {
    final String? id = next(l);
    return id != null && count(id) == 0 && !resting(id);
  }

  int levelOfNext(AdventureLand l) {
    final String? id = next(l);
    return input.paths[l]!.firstWhere((PathLesson x) => x.id == id).level;
  }
}
