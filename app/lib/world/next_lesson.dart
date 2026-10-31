import '../content/models.dart';
import '../data/app_database.dart';
import '../rewards/award.dart';
import 'lesson_path.dart';
import 'placement.dart';

/// How many times the child has finished each lesson: the lessons the warm-up placed count once, and the lesson stickers
/// (`sticker:<lesson>:<n>` award keys) say how many times a lesson was finished.
Map<String, int> finishedLessons(
  PackContent content,
  Iterable<Attempt> attempts,
  Iterable<String> awardKeys,
) {
  final Map<String, int> finished = <String, int>{
    for (final String id in placedLessons(content, attempts)) id: 1,
  };
  for (final String key in awardKeys) {
    final ({String lessonId, int n})? s = Awards.stickerOf(key);
    if (s != null && s.n > (finished[s.lessonId] ?? 0)) finished[s.lessonId] = s.n;
  }
  return finished;
}

/// The lesson a land plays next: the first lesson on its path that the child has not finished yet; when every lesson has
/// been finished, the one finished fewest times, so the path goes round and round ([nextOnPath]). [finished] is how many
/// times the child has finished each lesson. Null when the land has no lesson.
String? nextLessonId({
  required PackContent content,
  required String domain,
  required Map<String, int> finished,
}) => nextOnPath(<String>[for (final Lesson l in landPath(content, domain)) l.id], finished);
