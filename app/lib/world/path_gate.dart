import '../content/models.dart';
import 'placement.dart' show landPath;

// The path gate (M10, E0; audit F6). The lesson path used to walk every lesson of a land by `sequence`, so a child who had finished
// Band B would have been walked into Band C whether or not they knew what it stands on. A lesson is now offered only when every skill
// it teaches is unlocked: the engine's own question, `Engine.isUnlocked` (every prerequisite at the unlock bar, 0.8). A lesson that is
// not unlocked is skipped, and the path comes back to it when it is.

final RegExp _skillBand = RegExp(r'^[A-Z]+-([ABC])-\d+(?:\.[A-Z]\d+)?$');

/// A lesson's level on its land: the highest band among its skills of that land's domain (`NUM-A-03` is A, level 0; 0, 1 or 2),
/// read from the skill id, which the pack's skill ids all follow (a group's dotted id too: `ENG-B-19.G1` is B). A lesson that is
/// on two lands' paths has its own level on each.
int lessonLevel(PackContent content, Lesson lesson, String domain) {
  int level = 0;
  for (final String id in lesson.skillIds) {
    if (content.skills[id]?.domain != domain) continue;
    final String? band = _skillBand.firstMatch(id)?.group(1);
    if (band != null && band.codeUnitAt(0) - 0x41 > level) level = band.codeUnitAt(0) - 0x41;
  }
  return level;
}

/// The lessons of [domain]'s path that are not offered now, because a skill they teach is not unlocked. [unlocked] is the engine's
/// `isUnlocked`; it is told which skills the lesson teaches together, since those do not wait for each other.
///
/// A land can have no lesson open at all: the first lessons of a land may stand on skills of another land that the child has not
/// reached yet. Then the lessons of the land's lowest band are open, so that a child who comes to the land is never sent away with
/// nothing to play; a higher band stays locked, because it never opens by this exit.
Set<String> lockedLessons(
  PackContent content,
  String domain,
  bool Function(String skillId, Set<String> taughtWith) unlocked,
) {
  final List<Lesson> path = landPath(content, domain);
  final Set<String> locked = <String>{
    for (final Lesson l in path)
      if (!_isOpen(content, l, unlocked)) l.id,
  };
  if (path.isEmpty || locked.length < path.length) return locked;
  final int lowest = path
      .map((Lesson l) => lessonLevel(content, l, domain))
      .reduce((int a, int b) => a < b ? a : b);
  return <String>{
    for (final Lesson l in path)
      if (lessonLevel(content, l, domain) > lowest) l.id,
  };
}

bool _isOpen(PackContent content, Lesson lesson, bool Function(String, Set<String>) unlocked) {
  final Set<String> together = lesson.skillIds.toSet();
  return lesson.skillIds.every((String s) => !content.skills.containsKey(s) || unlocked(s, together));
}
