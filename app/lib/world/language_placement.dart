import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/course.dart';
import '../engine/staircase.dart';
import '../parent/language_settings.dart' show LanguageSwitches;
import '../play/lesson_controller.dart' show ItemFlow;
import 'placement.dart' show landPath, placementIdFor;

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

/// The game of [content]'s course as it stands for one child: the answers that child already gave in the course's placement visits are
/// replayed into it. Null when the pack has no placement document (or no strand is offered). [attempts] are the child's own answers;
/// only those of the course's pack and its placement lesson count ([replayPlacement]).
PlacementGame? placementGameFor(
  PackContent content,
  Iterable<Attempt> attempts, {
  Map<String, String> answers = const <String, String>{},
  int presentationBand = 0,
}) {
  final PlacementGame? game = placementGameOf(content, answers: answers, presentationBand: presentationBand);
  if (game == null) return null;
  replayPlacement(game, content.course, attempts.where((Attempt a) => a.packId == content.packId));
  return game;
}

/// The placement game of one child's course as the parent's settings stand (docs/milestones/L7.md step L7-2): none for a beginner, whose
/// parent's answers say the child knows nothing of the language, or are missing, and who has not been asked to play it (the course then
/// starts at lesson 1, with no probe and no assumed skill). A game that was begun stays, whatever the answers say now: what it found is
/// the child's history. [ageBand] is the child's age bracket; the presentation band is the parent's choice or the age's.
PlacementGame? placementGameOfChild(
  PackContent content,
  Iterable<Attempt> attempts,
  LanguageSwitches switches, {
  required int ageBand,
}) {
  final PlacementGame? game = placementGameFor(
    content,
    attempts,
    answers: switches.placementAnswers(content.course),
    presentationBand: switches.presentationBand(ageBand),
  );
  if (game == null) return null;
  return switches.wantsPlacement(content.course) || PlacementStatus.of(game).begun ? game : null;
}

/// Where a child's placement stands in a course: what each strand found so far, and whether every strand has stopped. Read from a game
/// ([PlacementStatus.of]); the screens and the parent's progress read this and never the staircase itself.
class PlacementStatus {
  const PlacementStatus({required this.results, required this.complete});

  factory PlacementStatus.of(PlacementGame game) =>
      PlacementStatus(results: game.results, complete: game.complete);

  /// The result of each offered strand, by its id in the placement document.
  final Map<String, StrandResult> results;

  /// Every offered strand has stopped: the placement visits are over.
  final bool complete;

  /// At least one probe was answered.
  bool get begun => results.values.any((StrandResult r) => r.asked > 0);

  /// The level a strand starts at ("we start here"), counted from 0, or null while that strand has not stopped (or was not offered).
  int? entryOf(String strand) {
    final StrandResult? r = results[strand];
    return r != null && r.stopped ? r.entry : null;
  }
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

/// The lessons whose every skill the placement assumed: they count as passed once, as the lessons a land's warm-up showed the child
/// knows do. A lesson with no skill is never placed.
Set<String> placedLanguageLessons(PackContent content, Set<String> assumed) {
  if (assumed.isEmpty) return const <String>{};
  return <String>{
    for (final Lesson l in landPath(content, Course.languagesDomain))
      if (l.skillIds.isNotEmpty && l.skillIds.every(assumed.contains)) l.id,
  };
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

/// The next placement visit of a course for one child, or null when there is nothing to ask (no placement document, no strand offered, or
/// every strand has stopped). The game has the child's earlier answers replayed into it, so a visit goes on where the last one ended.
({Lesson lesson, PlacementFlow flow})? placementVisitFor(
  PackContent content,
  Iterable<Attempt> attempts, {
  Map<String, String> answers = const <String, String>{},
  int presentationBand = 0,
}) {
  final PlacementDoc? doc = content.placement;
  final PlacementGame? game = placementGameFor(
    content,
    attempts,
    answers: answers,
    presentationBand: presentationBand,
  );
  if (doc == null || game == null || game.next() == null) return null;
  final PlacementFlow flow = PlacementFlow(game, doc);
  final Lesson? lesson = placementLessonFor(content, flow);
  if (lesson == null) return null;
  return (lesson: lesson, flow: flow);
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
