import '../rewards/award.dart';
import 'lesson_path.dart';

/// Today's Adventure: the one stop the bottle in the child's home opens (B-26 step 5; the rule and its worked examples are
/// `docs/curriculum/todays-adventure-rule.md`). A pure function of plain values and an explicit day number: no clock, no
/// random source, no database and no UI, so the same input always gives the same stop and every tie has a fixed order
/// (the map order of the lands, the place on the path, the skill id). `world/adventure_adapter.dart` fills the input from
/// the app's real data.

enum AdventureKind { revisit, lesson, replay, none }

enum AdventureReason { welcome, callForHelp, sameLand, otherLand, playAgain, nothing }

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

/// A lesson on a land's path with its level: 0, 1 or 2 for the bands A, B and C.
class PathLesson {
  const PathLesson(this.id, this.level);

  final String id;
  final int level;
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
  });

  final VisitKind kind;
  final TrophyLand land;
  final String id;

  /// `Engine.dayKey` of the visit's last answer.
  final int day;
  final VisitEnd end;

  /// The visit's last answer was incorrect (an unsure answer is never incorrect).
  final bool lastIncorrect;
}

/// A skill whose check is due, in a land the bottle may open.
class DueSkill {
  const DueSkill({
    required this.skillId,
    required this.land,
    required this.dueAt,
    this.reviewedToday = false,
  });

  final String skillId;
  final TrophyLand land;
  final DateTime dueAt;

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
  final Set<TrophyLand> enabledLands;

  /// Each land's lessons in path order.
  final Map<TrophyLand, List<PathLesson>> paths;

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
  const TodaysAdventure.revisit(TrophyLand land, String skillId)
    : this._(AdventureKind.revisit, AdventureReason.callForHelp, land: land, skillId: skillId);

  /// The land's next lesson, as the path offers it (before any warm-up).
  const TodaysAdventure.lesson(TrophyLand land, String? lessonId, AdventureReason reason)
    : this._(AdventureKind.lesson, reason, land: land, lessonId: lessonId);

  const TodaysAdventure.replay(TrophyLand land, String lessonId)
    : this._(AdventureKind.replay, AdventureReason.playAgain, land: land, lessonId: lessonId);

  final AdventureKind kind;
  final AdventureReason reason;
  final TrophyLand? land;

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
  // Map order, the order of `TrophyLand`: every sort below ends on it, so no input order can matter.
  final List<TrophyLand> lands = <TrophyLand>[
    for (final TrophyLand l in TrophyLand.values)
      if (input.enabledLands.contains(l) && (input.paths[l] ?? const <PathLesson>[]).isNotEmpty) l,
  ];
  if (lands.isEmpty) return const TodaysAdventure.none();
  final _View v = _View(input, lands);

  final TrophyLand? newPick = _newLearning(v, p);
  final bool revisitAllowed =
      v.visitsSinceRevisitToday == null || v.visitsSinceRevisitToday! >= p.newAfterRevisit;
  final DueSkill? revisit = _firstDue(v);
  if (revisit != null && (revisitAllowed || newPick == null)) {
    return TodaysAdventure.revisit(revisit.land, revisit.skillId);
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
  final TrophyLand land = v.current ?? lands.first;
  return TodaysAdventure.lesson(land, v.next(land), AdventureReason.sameLand);
}

/// The land that has new learning to offer, or null: stay in the current land for [AdventureParams.stayInLand]
/// lessons, then the lowest level first, the land not played for the longest time, the map order.
TrophyLand? _newLearning(_View v, AdventureParams p) {
  final List<TrophyLand> fresh = <TrophyLand>[
    for (final TrophyLand l in v.lands)
      if (v.hasNewLearning(l)) l,
  ];
  if (fresh.isEmpty) return null;
  if (v.current != null && fresh.contains(v.current) && v.run < p.stayInLand) return v.current;
  final List<TrophyLand> others = <TrophyLand>[
    for (final TrophyLand l in fresh)
      if (l != v.current) l,
  ];
  if (others.isEmpty) return v.current;
  others.sort((TrophyLand a, TrophyLand b) {
    final int byLevel = v.levelOfNext(a).compareTo(v.levelOfNext(b));
    if (byLevel != 0) return byLevel;
    final int byRecency = v.recency(a).compareTo(v.recency(b));
    return byRecency != 0 ? byRecency : a.index.compareTo(b.index);
  });
  return others.first;
}

/// The check that fell due earliest, in an open land and not taken today; at the same time the current land first.
DueSkill? _firstDue(_View v) {
  final List<DueSkill> waiting = <DueSkill>[
    for (final DueSkill d in v.input.due)
      if (v.lands.contains(d.land) && !d.reviewedToday) d,
  ];
  if (waiting.isEmpty) return null;
  waiting.sort((DueSkill a, DueSkill b) {
    final int byTime = a.dueAt.compareTo(b.dueAt);
    if (byTime != 0) return byTime;
    final int byCurrent = (a.land == v.current ? 0 : 1).compareTo(b.land == v.current ? 0 : 1);
    if (byCurrent != 0) return byCurrent;
    final int byLand = a.land.index.compareTo(b.land.index);
    return byLand != 0 ? byLand : a.skillId.compareTo(b.skillId);
  });
  return waiting.first;
}

/// Nothing new and nothing due: the lesson played fewest times, in the land not played for the longest time.
TodaysAdventure? _playAgain(_View v) {
  final Map<TrophyLand, List<PathLesson>> known = <TrophyLand, List<PathLesson>>{
    for (final TrophyLand l in v.lands)
      l: <PathLesson>[
        for (final PathLesson x in v.input.paths[l]!)
          if (v.count(x.id) >= 1 && !v.resting(x.id)) x,
      ],
  }..removeWhere((TrophyLand _, List<PathLesson> ls) => ls.isEmpty);
  if (known.isEmpty) return null;
  final List<TrophyLand> order = known.keys.toList()
    ..sort((TrophyLand a, TrophyLand b) {
      final int byRecency = v.recency(a).compareTo(v.recency(b));
      return byRecency != 0 ? byRecency : a.index.compareTo(b.index);
    });
  final TrophyLand land = order.first;
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
    final TrophyLand? last = onPath.isEmpty ? null : onPath.last.land;
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
  final List<TrophyLand> lands;
  final Map<TrophyLand, int> _lastPathAt = <TrophyLand, int>{};
  final Map<String, Visit> _lastLesson = <String, Visit>{};

  /// The land of the most recent lesson or warm-up, if it is open.
  late final TrophyLand? current;

  /// Lessons finished in a row in the current land (warm-ups and unfinished visits neither count nor stop it).
  int run = 0;

  /// Lessons and warm-ups since the most recent revisit of today, or null when there was no revisit today.
  late final int? visitsSinceRevisitToday;

  int count(String lessonId) => input.finished[lessonId] ?? 0;

  /// Where the land's most recent lesson or warm-up sits in the visits; −1 for a land never played.
  int recency(TrophyLand l) => _lastPathAt[l] ?? -1;

  /// Left today right after an incorrect answer: the bottle offers something else for the rest of the day.
  bool resting(String lessonId) {
    final Visit? x = _lastLesson[lessonId];
    return x != null && x.day == input.today && x.end == VisitEnd.home && x.lastIncorrect;
  }

  String? next(TrophyLand l) =>
      nextOnPath(<String>[for (final PathLesson x in input.paths[l]!) x.id], input.finished);

  bool hasNewLearning(TrophyLand l) {
    final String? id = next(l);
    return id != null && count(id) == 0 && !resting(id);
  }

  int levelOfNext(TrophyLand l) {
    final String? id = next(l);
    return input.paths[l]!.firstWhere((PathLesson x) => x.id == id).level;
  }
}
