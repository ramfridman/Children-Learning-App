import '../content/models.dart';

/// The lesson a land plays next: the first lesson on its path (by `sequence`, then by id) that the child has not finished
/// yet; when every lesson has been finished, the one finished fewest times, so the path goes round and round. [finished]
/// is how many times the child has finished each lesson. Null when the land has no lesson.
String? nextLessonId({
  required PackContent content,
  required String domain,
  required Map<String, int> finished,
}) {
  final List<Lesson> path =
      <Lesson>[
        for (final Lesson l in content.lessons.values)
          if (l.skillIds.any((String s) => content.skills[s]?.domain == domain)) l,
      ]..sort(
        (Lesson a, Lesson b) =>
            a.sequence != b.sequence ? a.sequence.compareTo(b.sequence) : a.id.compareTo(b.id),
      );
  if (path.isEmpty) return null;
  for (final Lesson l in path) {
    if ((finished[l.id] ?? 0) == 0) return l.id;
  }
  Lesson best = path.first;
  for (final Lesson l in path) {
    if ((finished[l.id] ?? 0) < (finished[best.id] ?? 0)) best = l;
  }
  return best.id;
}
