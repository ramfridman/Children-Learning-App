import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/age.dart' show SchoolStage;
import '../engine/staircase.dart';
import '../play/lesson_controller.dart' show ItemFlow;
import '../strings/he.dart';
import 'path_gate.dart';
import 'placement.dart';

// The warm-up of a land as a staircase (M10, E0b; audit F7; docs/curriculum.md section 10.1). The warm-up used to take one right
// answer at the first try as "this child knows the lesson", so one lucky tap could put a lesson behind a child. It now plays the same
// staircase as the language courses (`engine/staircase.dart`, the rules in one place): two right answers go up a unit, one wrong goes
// down, it stops after two reversals or eight probes, and the child is placed at the highest unit with two thirds right, minus one
// unit. The units are the land's: each band of the path is cut into up to four consecutive units (A1 ... B4, and C1 ... when the pack
// has them), and the start is the school stage's prior (the child's band). Nothing is stored but the answers: the placement is read by
// replaying them, so it is the same however often it is read.

/// How a band of a land's path is cut into units: one unit for about every three lessons, at least one and at most four.
const int _lessonsPerUnit = 3;
const int _mostUnits = 4;

/// The most probes in one unit: the staircase asks two thirds right of what it asked there, so a unit needs a few to draw on.
const int _mostProbes = 4;

/// One step of a land's ladder: the lessons of a unit of a band, and the probes (activities of those lessons) that tell whether the child
/// knows them.
class PlacementLevel {
  const PlacementLevel({
    required this.label,
    required this.band,
    required this.lessons,
    required this.probes,
  });

  /// `A1` ... `B4`: the band letter and the unit's place in the band.
  final String label;

  /// 0, 1 or 2 for the bands A, B and C.
  final int band;

  /// The lessons of the unit, in path order.
  final List<String> lessons;

  /// The probes of the unit, in the order they are asked. Each is an activity wholly of this land, of middle difficulty in its lesson.
  final List<String> probes;
}

/// The ladder of [domain]'s path, easiest unit first; empty when the land has fewer than three lessons (there is nothing to place on).
/// Every lesson is in exactly one unit, and no probe is in two units. A unit with no probe to ask hands its lessons to the next one
/// (the last one, to the one before): they are placed only when the child is placed beyond that unit.
List<PlacementLevel> placementLevels(PackContent content, String domain) {
  final List<Lesson> path = landPath(content, domain);
  if (path.length < 3) return const <PlacementLevel>[];
  final Map<int, List<Lesson>> byBand = <int, List<Lesson>>{};
  for (final Lesson l in path) {
    (byBand[lessonLevel(content, l, domain)] ??= <Lesson>[]).add(l);
  }
  final Set<String> used = <String>{};
  final List<PlacementLevel> levels = <PlacementLevel>[];
  List<String> waiting = <String>[];
  for (final int band in byBand.keys.toList()..sort()) {
    final List<Lesson> lessons = byBand[band]!;
    final int units = (lessons.length ~/ _lessonsPerUnit).clamp(1, _mostUnits);
    for (int u = 0; u < units; u++) {
      final List<Lesson> chunk = lessons.sublist(
        u * lessons.length ~/ units,
        (u + 1) * lessons.length ~/ units,
      );
      final List<String> probes = _probesOf(content, domain, chunk, used);
      final List<String> ids = <String>[...waiting, for (final Lesson l in chunk) l.id];
      if (probes.isEmpty) {
        waiting = ids;
        continue;
      }
      waiting = <String>[];
      levels.add(
        PlacementLevel(
          label: '${String.fromCharCode(0x41 + band)}${u + 1}',
          band: band,
          lessons: ids,
          probes: probes,
        ),
      );
    }
  }
  if (waiting.isNotEmpty && levels.isNotEmpty) {
    final PlacementLevel last = levels.removeLast();
    levels.add(
      PlacementLevel(
        label: last.label,
        band: last.band,
        lessons: <String>[...last.lessons, ...waiting],
        probes: last.probes,
      ),
    );
  }
  return levels;
}

/// Up to [_mostProbes] probes for the lessons of one unit: the activity of middle difficulty of each lesson, then the one above it, then
/// the one below, so that a unit is judged on several lessons before it is judged on one lesson twice. Only an activity wholly of this
/// land can be a probe (so an answer says which land it was given in), and an activity already a probe elsewhere cannot.
List<String> _probesOf(PackContent content, String domain, List<Lesson> lessons, Set<String> used) {
  final List<List<String>> candidates = <List<String>>[
    for (final Lesson l in lessons)
      <String>[
        for (final Activity a
            in <Activity>[for (final String id in l.itemIds) ?content.activities[id]]..sort(
              (Activity x, Activity y) =>
                  x.difficulty != y.difficulty ? x.difficulty.compareTo(y.difficulty) : x.id.compareTo(y.id),
            ))
          if (!a.unscored &&
              a.skills.isNotEmpty &&
              a.skills.every((Skill s) => content.skills[s.id]?.domain == domain))
            a.id,
      ],
  ];
  final List<String> probes = <String>[];
  for (final int step in const <int>[0, 1, -1]) {
    for (final List<String> ids in candidates) {
      final int at = ids.length ~/ 2 + step;
      if (probes.length >= _mostProbes) return probes;
      if (at >= 0 && at < ids.length && !used.contains(ids[at])) {
        used.add(ids[at]);
        probes.add(ids[at]);
      }
    }
  }
  return probes;
}

/// The unit the staircase starts at for a child at school [stage] (its prior, B-29): the middle unit of the stage's band, minus one unit
/// (curriculum section 10.1). The stage reaches the staircase only through its band, never through an age. A band the ladder does not
/// have starts in the highest band it has below it, or the lowest it has.
int startLevelFor(List<PlacementLevel> levels, SchoolStage stage) {
  if (levels.isEmpty) return 0;
  final List<int> bands = <int>{for (final PlacementLevel l in levels) l.band}.toList()..sort();
  final int want = stage.band;
  final int band = bands.lastWhere((int b) => b <= want, orElse: () => bands.first);
  final int first = levels.indexWhere((PlacementLevel l) => l.band == band);
  final int count = levels.where((PlacementLevel l) => l.band == band).length;
  return (first + count ~/ 2 - 1).clamp(0, levels.length - 1);
}

/// Where one child's warm-up in one land stands: the ladder, the staircase with the child's answers replayed into it, and what it found.
class LandPlacement {
  LandPlacement._(this.domain, this.levels, this.game, this.answered);

  final String domain;
  final List<PlacementLevel> levels;
  final PlacementGame game;

  /// How many probes the child has answered.
  final int answered;

  Staircase get stairs => game.stairs(domain)!;

  /// The staircase has stopped (two reversals, eight probes, two misses at the floor, or the top passed twice): only then does the
  /// warm-up place anybody. A warm-up left before that, or ended kindly by two hard activities, places nobody and the path starts
  /// at its beginning.
  bool get stopped => stairs.stopped;

  /// The highest unit with two thirds right, or null when no unit qualified.
  int? get best => stairs.result.best;

  /// The unit the child starts at (the best, minus one), or null while the staircase has not stopped.
  int? get entry => stopped ? stairs.result.entry : null;

  /// The unit a probe belongs to, or null for an activity that is no probe of this land.
  int? levelOfProbe(String id) => game.whereIs(id)?.level;

  /// The lessons of the units below the entry: they count as finished once.
  Set<String> get placedLessons => <String>{for (int i = 0; i < (entry ?? 0); i++) ...levels[i].lessons};

  /// The skills of this land that those lessons teach: taken as probably known (the engine's prior for an assumed skill), until the
  /// child's own answers say otherwise.
  Set<String> assumedSkills(PackContent content) => <String>{
    for (final String id in placedLessons)
      for (final String s in content.lessons[id]?.skillIds ?? const <String>[])
        if (content.skills[s]?.domain == domain) s,
  };
}

/// The warm-up of [domain] for one child, with the answers they gave in it replayed into the staircase; null when the land has none.
/// [attempts] may hold any answers: only those given in the warm-up to a probe of this land count. The staircase starts where the
/// child's first answer was (the first probe is the start unit's, so the replay does not depend on the band the child has now);
/// without an answer it starts at the prior of the school [stage] (a child with no confirmed stage has the middle one of their band).
///
/// A probe is right when it was answered right at the first try with no help; a miss, a hint or a second try is not right.
LandPlacement? landPlacementOf(
  PackContent content,
  String domain,
  Iterable<Attempt> attempts, {
  SchoolStage stage = SchoolStage.gan5,
}) {
  final List<PlacementLevel> levels = placementLevels(content, domain);
  if (levels.isEmpty) return null;
  final Map<String, int> unitOf = <String, int>{
    for (final (int i, PlacementLevel l) in levels.indexed)
      for (final String p in l.probes) p: i,
  };
  final List<Attempt> mine = <Attempt>[
    for (final Attempt a in attempts)
      if (a.lessonId == placementId && unitOf.containsKey(a.activityId)) a,
  ]..sort((Attempt a, Attempt b) => a.at != b.at ? a.at.compareTo(b.at) : a.id.compareTo(b.id));
  final Map<String, List<Attempt>> byProbe = <String, List<Attempt>>{};
  for (final Attempt a in mine) {
    (byProbe[a.activityId] ??= <Attempt>[]).add(a);
  }
  final int start = mine.isEmpty ? startLevelFor(levels, stage) : unitOf[mine.first.activityId]!;
  final PlacementGame game = PlacementGame(
    strands: <StrandPlan>[
      StrandPlan(
        id: domain,
        levels: <List<String>>[for (final PlacementLevel l in levels) l.probes],
      ).startingAt(start),
    ],
    perVisit: Staircase.mostItems,
  );
  for (final MapEntry<String, List<Attempt>> e in byProbe.entries) {
    final List<Attempt> rows = e.value;
    game.record(
      e.key,
      right:
          rows.every((Attempt a) => a.result == 'correct') &&
          rows.first.attemptNo == 1 &&
          rows.first.hintLevel == 0,
    );
  }
  return LandPlacement._(domain, levels, game, byProbe.length);
}

/// What the warm-ups of every land found for one child: the lessons they put behind the child (counted as finished once) and the
/// skills those lessons teach (assumed known).
({Set<String> lessons, Set<String> skills}) placedByWarmUp(PackContent content, Iterable<Attempt> attempts) {
  final Set<String> lessons = <String>{};
  final Set<String> skills = <String>{};
  if (!attempts.any((Attempt a) => a.lessonId == placementId)) return (lessons: lessons, skills: skills);
  for (final String domain in <String>{for (final SkillDoc s in content.skills.values) s.domain}) {
    final LandPlacement? p = landPlacementOf(content, domain, attempts);
    if (p == null) continue;
    lessons.addAll(p.placedLessons);
    skills.addAll(p.assumedSkills(content));
  }
  return (lessons: lessons, skills: skills);
}

/// The lessons that the warm-ups put behind the child; they count as finished for the path ([placedByWarmUp]).
Set<String> placedLessons(PackContent content, Iterable<Attempt> attempts) =>
    placedByWarmUp(content, attempts).lessons;

/// Whether the warm-up should be offered now: this land's warm-up is not over (its staircase has not stopped), and the child has not
/// played a lesson in this land. The warm-up is per land: an answer to another land's probe says nothing here. A warm-up that was left
/// goes on where it stopped, until the child plays in the land.
bool placementDue(PackContent content, String domain, Iterable<Attempt> attempts) {
  final LandPlacement? p = landPlacementOf(content, domain, attempts);
  if (p == null || p.stopped) return false;
  final Set<String> inLand = <String>{for (final Lesson l in landPath(content, domain)) ...l.itemIds};
  return !attempts.any((Attempt a) => a.lessonId != placementId && inLand.contains(a.activityId));
}

/// The warm-up visit of [domain]: a one-activity lesson whose id is [placementId] (so the answers it writes are told apart from every
/// lesson's) and the flow that chooses the next probe by how the last one went. Null when the land has no warm-up, or its staircase has
/// stopped. A visit goes on where the last one ended. The visit ends kindly, as the old warm-up did, when the child needs all the help
/// on [placementStruggles] activities in a row.
({Lesson lesson, ItemFlow flow})? placementVisit(
  PackContent content,
  String domain,
  Iterable<Attempt> attempts, {
  SchoolStage stage = SchoolStage.gan5,
}) {
  final LandPlacement? p = landPlacementOf(content, domain, attempts, stage: stage);
  if (p == null || p.stopped) return null;
  final LandPlacementFlow flow = LandPlacementFlow(p.game);
  final Activity first = content.activities[flow.first()]!;
  return (
    lesson: Lesson.mission(
      id: placementId,
      itemIds: <String>[first.id],
      skillIds: <String>[for (final Skill s in first.skills) s.id],
      celebration: flow.celebration,
      stopAfterStruggles: placementStruggles,
    ),
    flow: flow,
  );
}

/// The probes of a land's warm-up, one after another as the staircase chooses them.
class LandPlacementFlow implements ItemFlow {
  LandPlacementFlow(this.game);

  final PlacementGame game;
  int _given = 0;

  @override
  String first() {
    final String? probe = game.next();
    if (probe == null) {
      throw StateError('the warm-up of this land is over: check `placementDue` first');
    }
    return probe;
  }

  @override
  String? after(String id, {required bool right}) {
    game.record(id, right: right);
    _given++;
    return game.next(doneThisVisit: _given);
  }

  @override
  int get length => game.perVisit;

  @override
  Spoken get thanks => Spoken(vo: 'vo:core.celebrate.well', caption: He.celebrateWell.text);

  @override
  Spoken get celebration => Spoken(vo: 'vo:core.placement.done', caption: He.placementDone.text);
}
