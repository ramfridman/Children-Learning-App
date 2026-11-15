import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../engine/engine.dart';
import '../engine/gates.dart';
import '../parent/language_settings.dart';
import 'language_placement.dart' show PlacementStatus, placedOpenGates;

// The letters gates of a language course as one child stands (docs/languages/frame.md section 3.3.6; docs/milestones/L7.md step L7-8). The
// gates are pure (`engine/gates.dart`); here a pack's gates meet the child: the engine's mastery and known skills, the age (in months when
// the parent gave a birth month, else the bracket), the parent's switches, and what the placement confirmed. The result is what is held
// back (a lesson that teaches a held skill is not offered, the parent sees the gate as "not yet", never a lock) and whether the child's
// letters are open (the Meet screen prints a word only then). A gate never reads the presentation band.

/// What a gate looks at for one child of [content]'s course.
GateInput languageGateInput({
  required PackContent content,
  required Engine engine,
  required LanguageSwitches switches,
  required int ageBand,
  int? ageMonths,
  PlacementStatus? placement,
}) => GateInput(
  mastery: masteryLevels(engine),
  known: knownSkills(engine),
  ageBand: ageBand,
  ageMonths: ageMonths,
  switchesOn: switches.gateSwitchesOn(ageBand: ageBand, ageMonths: ageMonths),
  placedOpen: placedOpenGates(content, placement, switches),
  route: switches.route,
);

/// What the letters gates read besides the engine and the pack: the parent's switches for the course, the child's age bracket and, when a
/// birth month is on the device, the age in months (worked out on the phone for the check; it goes nowhere).
class GateContext {
  const GateContext({this.switches = const LanguageSwitches(), this.ageBand = 1, this.ageMonths});

  final LanguageSwitches switches;
  final int ageBand;
  final int? ageMonths;
}

/// Which skills the course's closed **letters** gates hold back from this child, and whether the child's letters are open: the course has a
/// gate that holds letter skills (`letters: true` on the skill) and every such gate is open. A course whose pack has no letters gate holds
/// nothing and has no letters open (nothing is printed). A gate that holds other skills (the Russian sounds gate) is left to the parent's
/// view, as before: the course path does not hold lessons for it.
({Set<String> held, bool lettersOpen}) courseGateState({
  required PackContent content,
  required Engine engine,
  required GateContext context,
  PlacementStatus? placement,
}) {
  final List<CourseGate> letterGates = <CourseGate>[
    for (final CourseGate g in courseGates(content))
      if (g.holds.any((String s) => content.skills[s]?.letters ?? false)) g,
  ];
  if (letterGates.isEmpty) return (held: const <String>{}, lettersOpen: false);
  final GateInput input = languageGateInput(
    content: content,
    engine: engine,
    switches: context.switches,
    ageBand: context.ageBand,
    ageMonths: context.ageMonths,
    placement: placement,
  );
  return (
    held: heldSkills(letterGates, input),
    lettersOpen: letterGates.every((CourseGate g) => gateResult(g, input).open),
  );
}
