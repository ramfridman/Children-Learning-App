import '../content/models.dart';
import '../rewards/award.dart';

/// The first skill of lesson [lessonId] that belongs to [land]'s domain, or null when the lesson is not in the pack or has
/// none (the B-39 land rule: the lesson `butterflies` is on the Numbers and the Colours paths, and counts for each by its own
/// skills). This is what the welcome says a stop is about.
String? firstSkillInLand(PackContent content, String lessonId, TrophyLand land) {
  final Lesson? lesson = content.lessons[lessonId];
  if (lesson == null) return null;
  for (final String id in lesson.skillIds) {
    if (content.skills[id]?.domain == land.domain) return id;
  }
  return null;
}
