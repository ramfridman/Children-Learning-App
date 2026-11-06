import '../content/models.dart';
import '../engine/course.dart';

/// The warm-up game at the first visit to a land (M9, a staircase since M10 E0b, `land_placement.dart`): a few activities, each
/// chosen by how the last one went, so the island can start where the child is. It is not a test: every answer is written like
/// any other, the help is the same as in a lesson, nothing says "wrong", and when the child needs the full help twice in a row
/// the game ends kindly and the path starts at the beginning.
const String placementId = 'placement';

/// The id of a course's placement visit: `placement` for the lands that exist, `placement-eng` for a language. A course is
/// placed on its own, strand by strand (docs/languages/frame.md section 3.2), so its answers are told apart from every other
/// course's by this id.
String placementIdFor(String course) => course == Course.core ? placementId : '$placementId-$course';

/// The course a placement lesson id belongs to, or null when [lessonId] is not a placement id.
String? courseOfPlacementId(String lessonId) {
  if (lessonId == placementId) return Course.core;
  if (!lessonId.startsWith('$placementId-')) return null;
  final String course = lessonId.substring(placementId.length + 1);
  return Course.isLanguage(course) ? course : null;
}

/// The warm-up ends kindly when the child needs the full help on this many activities in a row.
const int placementStruggles = 2;

/// The lessons of a land in path order: every lesson that has a skill of the land's domain, by `sequence`, then by id.
/// The land's play pebble (`nextLessonId`), the warm-up and Today's Adventure all read the path from here.
List<Lesson> landPath(PackContent content, String domain) =>
    <Lesson>[
      for (final Lesson l in content.lessons.values)
        if (l.skillIds.any((String s) => content.skills[s]?.domain == domain)) l,
    ]..sort(
      (Lesson a, Lesson b) =>
          a.sequence != b.sequence ? a.sequence.compareTo(b.sequence) : a.id.compareTo(b.id),
    );
