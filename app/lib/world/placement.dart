import '../content/models.dart';
import '../data/app_database.dart';
import '../strings/he.dart';

/// The warm-up game at the first visit to a land (M9): a few activities spread along the path, from the first lesson to the
/// last, so the island can start where the child is. It is not a test: every answer is written like any other, the help
/// is the same as in a lesson, nothing says "wrong", and when the child needs the full help twice in a row the game ends
/// kindly and the path starts at the beginning.
const String placementId = 'placement';

/// How many activities the warm-up has at most, and how many struggles end it.
const int placementItems = 8;
const int placementStruggles = 2;

/// The warm-up of a land, or null when the land has fewer than three lessons (there is nothing to place on).
Lesson? placementLesson(PackContent content, String domain) {
  final List<Lesson> path = landPath(content, domain);
  if (path.length < 3) return null;
  final int n = path.length < placementItems ? path.length : placementItems;
  final List<String> items = <String>[];
  final List<String> skills = <String>[];
  for (int i = 0; i < n; i++) {
    // Evenly along the path, first to last.
    final Lesson l = path[(i * (path.length - 1) / (n - 1)).round()];
    final String? pick = _middleItem(content, l);
    if (pick != null && !items.contains(pick)) {
      items.add(pick);
      for (final String s in content.activities[pick]!.skills.map((Skill k) => k.id)) {
        if (!skills.contains(s)) skills.add(s);
      }
    }
  }
  if (items.isEmpty) return null;
  return Lesson.mission(
    id: placementId,
    itemIds: items,
    skillIds: skills,
    celebration: Spoken(vo: 'vo:core.placement.done', caption: He.placementDone.text),
    stopAfterStruggles: placementStruggles,
  );
}

/// The lessons that the warm-up showed the child already knows: the activity of the lesson that the warm-up gave was
/// answered right at the first try, with no help. They count as finished for the path.
Set<String> placedLessons(PackContent content, Iterable<Attempt> attempts) {
  final Set<String> done = <String>{};
  for (final Attempt a in attempts) {
    if (a.lessonId != placementId || a.result != 'correct' || a.attemptNo != 1 || a.hintLevel != 0) continue;
    for (final Lesson l in content.lessons.values) {
      if (l.itemIds.contains(a.activityId)) done.add(l.id);
    }
  }
  return done;
}

/// Whether the warm-up should be offered now: it has not been played, and the child has not played in this land.
bool placementDue(PackContent content, String domain, Iterable<Attempt> attempts) {
  if (placementLesson(content, domain) == null) return false;
  final Set<String> inLand = <String>{for (final Lesson l in landPath(content, domain)) ...l.itemIds};
  return !attempts.any((Attempt a) => a.lessonId == placementId || inLand.contains(a.activityId));
}

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

/// The activity of a lesson of middle difficulty, which is what tells whether the lesson's skill is there.
String? _middleItem(PackContent content, Lesson l) {
  final List<Activity> items = <Activity>[
    for (final String id in l.itemIds)
      if (content.activities[id] != null) content.activities[id]!,
  ]..sort((Activity a, Activity b) => a.difficulty.compareTo(b.difficulty));
  return items.isEmpty ? null : items[items.length ~/ 2].id;
}
