import 'models.dart';

/// The strand of the Russian placement that asks whether the child understands everyday Russian (docs/languages/band-a-build.md 2.6.1).
const String oralStrandId = '1';

/// How a child is served in one skill of a language course: `new` (the teach screens, the say steps echo first) or `heritage` (a single
/// hearing of some words, the say steps picture first). The parent's [route] is `new`, `heritage` or `reader`, or not set (a new learner).
///
/// A reader is served by its oral route (frame 3.3.7, the curriculum-expert's decision of 2026-11-07): as a heritage speaker when the skill
/// says `readerAs: heritage`, or when strand 1 of the [placement] has put it past its first level (the placement assumed every skill of
/// that level: [assumed] is `LanguageCourse.assumed`); otherwise as a new learner. That includes the time before strand 1 has stopped and
/// a pack with no placement: when we do not know, the child is shown the screens.
///
/// This decides `PackContent.itemsFor` and the order of a say step, and nothing else: the stress marks, the caption after the answer and
/// the letters gate keep reading the parent's own route.
String servedRoute({
  String? route,
  SkillDoc? skill,
  Set<String> assumed = const <String>{},
  PlacementDoc? placement,
}) {
  switch (route) {
    case 'heritage':
      return 'heritage';
    case 'reader':
      if (skill?.readerAs == 'heritage') return 'heritage';
      return strandOnePastFirstLevel(placement, assumed) ? 'heritage' : 'new';
    default:
      return 'new';
  }
}

/// Has strand 1 of [placement] put the child past its first level: the placement has that strand and [assumed] holds every skill the
/// first level assumes. (A first level that assumes nothing says nothing, so it is never "past".)
bool strandOnePastFirstLevel(PlacementDoc? placement, Set<String> assumed) {
  if (placement == null) return false;
  for (final PlacementStrandDoc s in placement.strands) {
    if (s.id != oralStrandId) continue;
    if (s.levels.isEmpty) return false;
    final List<String> first = s.levels.first.assumes;
    return first.isNotEmpty && first.every(assumed.contains);
  }
  return false;
}
