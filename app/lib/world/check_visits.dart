import '../content/models.dart';
import '../engine/check_visit.dart';
import '../engine/course.dart';
import '../engine/engine.dart';
import '../engine/state.dart';
import '../engine/types.dart';
import 'adventure_land.dart';
import 'placement.dart' show landPath;
import 'todays_adventure.dart';

// The check visit of a language course as the course home and Today's Adventure read it (docs/languages/band-a-build.md section 7.4):
// which skill is ready, and the visit's short lesson. The rules of the visit's items are the engine's (`engine/check_visit.dart`); the
// lessons are read here, because the engine knows none.

/// The id of a check visit's short lesson: a mission (it is a revisit by kind, so the rule of the day counts it), told from the revisit of
/// a fresh skill by its ending. Lower case, as `sync-push` takes a lesson id.
String checkVisitIdOf(String skillId) => 'mission-${skillId.toLowerCase()}-check';

/// Whether [lessonId] is a check visit's.
bool isCheckVisitId(String lessonId) => lessonId.startsWith('mission-') && lessonId.endsWith('-check');

/// The skills of [path] that were taught: placement took them as known, or every lesson of the path that names them was finished (or
/// placed) at least once ([seen]: the finished lessons with the placed ones counted once). A skill no lesson names is not taught.
Set<String> taughtSkills(List<Lesson> path, Map<String, int> seen, Set<String> assumed) {
  final Map<String, bool> done = <String, bool>{};
  for (final Lesson l in path) {
    final bool played = (seen[l.id] ?? 0) > 0;
    for (final String skill in l.skillIds) {
      done[skill] = (done[skill] ?? true) && played;
    }
  }
  return <String>{
    for (final MapEntry<String, bool> e in done.entries)
      if (e.value || assumed.contains(e.key)) e.key,
  };
}

/// The checks that stand in a lesson of [path] (a question about the story just heard): the check visit never serves them.
Set<String> checksInLessons(List<Lesson> path, Catalog catalog) => <String>{
  for (final Lesson l in path)
    for (final String id in l.itemIds)
      if (catalog.items[id]?.purpose == Purpose.check) id,
};

/// The skill of the course of [content] that the check visit of today is for, as a due skill of the rule, or null when none is (C-1 and C-2):
/// at most one a day for a course (none when one was already played today), the skill whose last answer is oldest first, then the
/// path's order. [seen] are the finished lessons with the placed ones counted, [visits] the child's visits (any course's), [band] their
/// age band.
DueSkill? checkVisitDue({
  required PackContent content,
  required Engine engine,
  required Set<String> assumed,
  required Map<String, int> seen,
  required Iterable<Visit> visits,
  required DateTime now,
  required int band,
}) {
  final int today = Engine.dayKey(now);
  final LanguageLand land = LanguageLand(content.course);
  if (visits.any((Visit v) => v.check && v.land == land && v.day == today)) return null;
  final List<Lesson> path = landPath(content, Course.languagesDomain);
  final Set<String> taught = taughtSkills(path, seen, assumed);
  final Set<String> inLesson = checksInLessons(path, engine.catalog);
  final Set<String> tried = <String>{};
  DueSkill? best;
  for (final Lesson lesson in path) {
    for (final String skill in lesson.skillIds) {
      if (!tried.add(skill) ||
          !checkVisitReady(engine, skill, taught: taught.contains(skill), today: today)) {
        continue;
      }
      if (checkVisitItemIds(engine, skill, inLessonChecks: inLesson, max: checkVisitMax(band)).isEmpty) {
        continue;
      }
      final SkillState? s = engine.state.skills[skill];
      final DateTime at = s?.lastAttemptAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      // The path is walked in order, so on equal times the earlier skill stays.
      if (best != null && !at.isBefore(best.dueAt)) continue;
      best = DueSkill(
        skillId: skill,
        land: land,
        dueAt: at,
        check: true,
        reteachLessonId: (s?.trail.needsReteach ?? false) ? _lastLessonOf(path, skill) : null,
      );
    }
  }
  return best;
}

String _lastLessonOf(List<Lesson> path, String skillId) =>
    path.lastWhere((Lesson l) => l.skillIds.contains(skillId)).id;
