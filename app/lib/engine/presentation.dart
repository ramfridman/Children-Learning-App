import 'course.dart';
import 'params.dart';
import 'types.dart';

// Two bands (docs/languages/frame.md section 3.1). The presentation band comes from the child's age and says how a screen looks
// and paces: the number of choices, the items in an activity, the length of a visit. The content level comes from mastery
// and says which skill the child is on: the band letter of a skill's id is only where the skill is usually first taught. The
// two are independent: a 7-year-old new to English does `ENG-A-01` with the pacing of the oldest band, and a 4-year-old who
// hears Russian at home may do Band B sound work with the look of the youngest.

/// 0, 1 or 2 for Bands A, B and C. The age bracket decides, and the parent may override it for a course.
int presentationBandFor({required int ageBand, int? override}) => (override ?? ageBand).clamp(0, 2);

/// The content level of a skill: 0, 1 or 2 for the band letter A, B or C in its id, or -1 for an id of another shape.
int contentLevelOf(String skillId) => SkillIds.levelOf(skillId);

/// Letter skills offered under the youngest presentation band all the same: Hebrew print awareness and the child's own name
/// (docs/languages/frame.md section 3.1).
const Set<String> lettersAllowedUnderBandA = <String>{'HEB-A-10', 'HEB-A-11', 'HEB-A-12'};

/// Whether [skill] may be offered under the presentation [band]: letter work is never offered under Band A (0), except the
/// Hebrew skills above. Every other skill is offered under every band, whatever its content level.
bool offeredUnder(int band, SkillNode skill) =>
    band > 0 || !skill.letters || lettersAllowedUnderBandA.contains(skill.id);

/// How a screen looks and paces under one presentation band.
class PresentationSpec {
  const PresentationSpec({
    required this.band,
    required this.maxChoices,
    required this.itemsMin,
    required this.itemsMax,
    required this.sessionMinutes,
    required this.oneInstruction,
    required this.readingDemand,
  });

  final int band;

  /// The most choices an item may show, or null for no limit (Band A shows at most 3).
  final int? maxChoices;

  /// Items in an activity: 3 to 5, 5 to 8, and up to 12 (the lower end for the oldest band is a reading of "up to 12").
  final int itemsMin;
  final int itemsMax;

  /// The length of a visit in minutes.
  final int sessionMinutes;

  /// One instruction at a time, no left and right words (Band A).
  final bool oneInstruction;

  /// Whether an item may ask the child to read (never under Band A, whatever the skill).
  final bool readingDemand;
}

/// A course may set a shorter visit than the app's default: English Band A is 6 to 8 minutes, Band B 10 to 12 and Band C 12 to
/// 15 (its syllabus section 7.1). The visit takes the middle of the range.
const Map<String, List<(int, int)>> _sessionMinutesByCourse = <String, List<(int, int)>>{
  Course.eng: <(int, int)>[(6, 8), (10, 12), (12, 15)],
};

/// The look and pace of [band] in [course]; [params] holds the app's defaults for the length of a visit.
PresentationSpec presentationSpec(int band, {String course = Course.core, EngineParams? params}) {
  final int b = band.clamp(0, 2);
  final EngineParams p = params ?? const EngineParams();
  final (int, int)? own = _sessionMinutesByCourse[course]?[b];
  return PresentationSpec(
    band: b,
    maxChoices: b == 0 ? 3 : null,
    itemsMin: const <int>[3, 5, 8][b],
    itemsMax: const <int>[5, 8, 12][b],
    sessionMinutes: own == null ? p.sessionMinutes[b] : (own.$1 + own.$2) ~/ 2,
    oneInstruction: b == 0,
    readingDemand: b > 0,
  );
}
