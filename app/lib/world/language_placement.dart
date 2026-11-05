import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/course.dart' show Course;
import '../engine/staircase.dart';
import '../play/lesson_controller.dart' show ItemFlow;
import 'placement.dart' show placementIdFor;

// The placement game of a language course (docs/languages/frame.md section 3.2, LS13), wired to the app. The staircase itself is pure
// (`engine/staircase.dart`); here the course's placement document becomes its strands, the answers recorded under the course's
// placement lesson id (`placementIdFor`, from L0) are replayed into them, and the skills below each strand's entry point are handed to
// the engine as assumed. Nothing is stored for the placement but the answers themselves: the same replay is how the engine works.

/// The game of [content]'s course, or null when the pack has no placement document. [answers] are the parent's questionnaire (enums
/// only): an answer sets where a staircase starts and never where it ends, and may make a strand offered or not. [presentationBand]
/// is the child's (0 to 2): the English literacy strand is offered only to Band B or C.
PlacementGame? placementGameOf(
  PackContent content, {
  Map<String, String> answers = const <String, String>{},
  int presentationBand = 0,
}) {
  final PlacementDoc? doc = content.placement;
  if (doc == null) return null;
  final List<StrandPlan> strands = <StrandPlan>[];
  for (final PlacementStrandDoc s in doc.strands) {
    final bool asked = s.offerAnswer == null || answers[s.offerAnswer] == s.offerEquals;
    if (!asked || presentationBand < s.offerMinBand) continue;
    int start = 0;
    for (final ({String answer, String equals, int level}) rule in s.start) {
      if (answers[rule.answer] == rule.equals && rule.level > start) start = rule.level;
    }
    strands.add(
      StrandPlan(
        id: s.id,
        levels: <List<String>>[
          for (final ({List<String> items, List<String> assumes}) l in s.levels) l.items,
        ],
      ).startingAt(start),
    );
  }
  return strands.isEmpty ? null : PlacementGame(strands: strands, perVisit: doc.perVisit);
}

/// Feeds the answers of the course's placement visits into [game], in the order they were given. An answer of another lesson, or one
/// that is neither right nor wrong (an "unsure"), is not part of the placement.
void replayPlacement(PlacementGame game, String course, Iterable<Attempt> attempts) {
  final String lesson = placementIdFor(course);
  final List<Attempt> mine = <Attempt>[
    for (final Attempt a in attempts)
      if (a.lessonId == lesson &&
          Course.ofActivityId(a.activityId) == course &&
          (a.result == 'correct' || a.result == 'incorrect'))
        a,
  ]..sort((Attempt a, Attempt b) => a.at.compareTo(b.at));
  // One answer for each probe, the first: a row sent twice (two devices, a re-sent event) must not move a strand (SEC-L4-3).
  final Set<String> seen = <String>{};
  for (final Attempt a in mine) {
    if (seen.add(a.activityId)) game.record(a.activityId, right: a.result == 'correct');
  }
}

/// The skills a finished strand takes as known: those of every level below its entry point, as the document lists them and as the
/// probes' own skills name them. A strand that has not stopped yet places nobody anywhere.
Set<String> assumedSkills(PackContent content, PlacementGame game) {
  final PlacementDoc? doc = content.placement;
  if (doc == null) return const <String>{};
  final Set<String> out = <String>{};
  final Map<String, StrandResult> results = game.results;
  for (final PlacementStrandDoc s in doc.strands) {
    final StrandResult? r = results[s.id];
    if (r == null || !r.stopped) continue;
    for (final (int l, ({List<String> items, List<String> assumes}) level) in s.levels.indexed) {
      if (l >= r.entry) break;
      out.addAll(level.assumes);
      for (final String item in level.items) {
        final Activity? a = content.activities[item];
        if (a != null) out.addAll(<String>[for (final Skill k in a.skills) k.id]);
      }
    }
  }
  return out;
}

/// The placement visit of a language course: the staircase chooses each next probe by how the last one went. [doneThisVisit] counts
/// the probes already given in the visit that is going on (0 for a new one); it is what keeps a visit to about eight.
class PlacementFlow implements ItemFlow {
  PlacementFlow(this.game, this.doc);

  final PlacementGame game;
  final PlacementDoc doc;
  int _given = 0;

  /// The placement has something to ask now: a strand has not stopped.
  bool get due => !game.complete;

  @override
  String first() {
    final String? probe = game.next();
    if (probe == null) {
      throw StateError('the placement of this course is complete: check `due` before a visit');
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
  Spoken get thanks => doc.thanks;

  @override
  Spoken get celebration => doc.celebration;
}

/// The lesson that carries a placement visit: its id is the course's placement id, so that the answers it writes are told apart from
/// every other lesson's (and from every other course's), and the controller plays the flow's first probe.
Lesson? placementLessonFor(PackContent content, PlacementFlow flow) {
  if (!flow.due) return null;
  final String first = flow.first();
  return Lesson.mission(
    id: placementIdFor(content.course),
    itemIds: <String>[first],
    skillIds: <String>[content.activities[first]!.skillId],
    celebration: flow.celebration,
  );
}
