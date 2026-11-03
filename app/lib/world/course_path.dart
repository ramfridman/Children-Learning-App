import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/course.dart';
import 'adventure_adapter.dart';
import 'language_placement.dart' show placedLanguageLessons;
import 'lesson_path.dart';
import 'next_lesson.dart' show finishedLessons;
import 'placement.dart' show landPath;
import 'todays_adventure.dart';

// The course home's own facts (docs/milestones/L-course.md): the path of a course's lessons with where the child stands on it, and what
// is next. Pure: a course (its pack and the child's engine on it), the child's answers, visits and awards go in, plain values come out.
// Nothing here reads a clock, a database or a widget, and nothing says "behind", "late" or "wrong": a stone is behind the child, in
// front of them, or the one to go to.

/// Where a lesson stands for the child. Nothing is locked: a later stone is simply further on.
enum StoneState {
  /// Finished at least once.
  done,

  /// Never played, and every skill of it is below the child's entry point: the placement showed it is known.
  placed,

  /// Neither finished nor placed.
  later,
}

/// One lesson on the path.
class PathStone {
  const PathStone({required this.lessonId, required this.title, required this.number, required this.state});

  final String lessonId;

  /// The lesson's title in Hebrew with niqqud, from the pack.
  final String title;

  /// Its place on the path, from 1. A digit, so it never mirrors.
  final int number;
  final StoneState state;
}

/// Everything the course home shows.
class CourseHomeModel {
  const CourseHomeModel({
    required this.course,
    required this.stones,
    required this.nextIndex,
    required this.stop,
    required this.placementDue,
  });

  final String course;

  /// The course's lessons in path order.
  final List<PathStone> stones;

  /// The stone the child goes to next: the first lesson neither finished nor placed, or when every lesson was finished the one finished
  /// fewest times, so the path goes round (the rule of a land's pebble, `nextOnPath`). -1 for a course with no lesson.
  final int nextIndex;

  /// What the pebble starts, by the rule of Today's Adventure run on this course alone (a revisit, the next lesson, a lesson again).
  final TodaysAdventure stop;

  /// The course has a placement game with a strand that has not stopped: the host invites the child to a visit, and the pebble starts it.
  final bool placementDue;

  /// There is something to start: a placement visit or a stop of the rule.
  bool get canPlay => placementDue || stop.kind != AdventureKind.none;

  PathStone? get next => nextIndex < 0 ? null : stones[nextIndex];

  /// The lesson the pebble opens, when it opens one (not for a placement visit or a revisit).
  PathStone? get pebbleLesson {
    if (placementDue) return null;
    final String? id = stop.kind == AdventureKind.lesson || stop.kind == AdventureKind.replay
        ? stop.lessonId
        : null;
    return id == null ? null : stones.where((PathStone s) => s.lessonId == id).firstOrNull;
  }
}

/// The course home of one child. [attempts] are the child's answers (every course's: those of other packs are left out), [sessions] their
/// visits and [rewardKeys] the award keys they were given (a lesson's stickers say how many times it was finished).
CourseHomeModel buildCourseHome({
  required LanguageCourse course,
  required Iterable<Attempt> attempts,
  required Iterable<Session> sessions,
  required Iterable<String> rewardKeys,
  required DateTime now,
  required int band,
}) {
  final PackContent content = course.content;
  final List<Attempt> own = <Attempt>[
    for (final Attempt a in attempts)
      if (a.packId == content.packId) a,
  ];
  final Map<String, int> finished = finishedLessons(content, own, rewardKeys);
  final Set<String> placed = placedLanguageLessons(content, course.assumed);
  final List<Lesson> path = landPath(content, Course.languagesDomain);
  final Map<String, int> seen = withPlaced(finished, <LanguageCourse>[course]);
  final String? nextId = nextOnPath(<String>[for (final Lesson l in path) l.id], seen);
  final List<PathStone> stones = <PathStone>[
    for (final (int i, Lesson l) in path.indexed)
      PathStone(
        lessonId: l.id,
        title: l.title,
        number: i + 1,
        state: (finished[l.id] ?? 0) > 0
            ? StoneState.done
            : placed.contains(l.id)
            ? StoneState.placed
            : StoneState.later,
      ),
  ];
  return CourseHomeModel(
    course: course.course,
    stones: stones,
    nextIndex: nextId == null ? -1 : path.indexWhere((Lesson l) => l.id == nextId),
    stop: courseStopFor(
      course: course,
      attempts: own,
      sessions: sessions,
      finished: finished,
      now: now,
      band: band,
    ),
    placementDue: course.placement != null && !course.placement!.complete,
  );
}
