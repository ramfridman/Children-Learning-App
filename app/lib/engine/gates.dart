import 'engine.dart';
import 'state.dart';

// Course gates (docs/languages/frame.md section 3.3.6). A gate is a named condition on a set of skills that holds other skills
// back: the English oral gate keeps letters from a child who cannot yet understand enough English, the Russian letters gate
// keeps them from a new learner who has too few words. A gate holds skills back; the child never sees a lock. Pure: a gate and
// what is known about a child go in, open or closed and the reasons come out.

/// How much a skill is mastered, for a gate: fresh mastery is the first, durable mastery comes after a delayed check.
enum MasteryLevel { none, fresh, durable }

/// A group of skills of which at least [count] must be mastered (the Russian gate: "A-12 and one theme").
class SkillQuota {
  const SkillQuota({required this.skills, required this.count});

  final Set<String> skills;
  final int count;
}

/// Which way a parent switch acts on a gate: the English "oral only" keeps its gate closed, the Russian "letters before 5"
/// opens its gate whatever else is true (except the words, see [CourseGate.early]).
enum SwitchEffect { closes, opens }

/// The parent switch "letters together with words" (English and Russian): it lowers a gate to its early set. It is shown from
/// [lettersWithWordsShownAge], and when the parent never chose it, it is on from [lettersWithWordsDefaultOnAge]
/// (docs/languages/frame.md section 3.3.6).
const String lettersWithWordsSwitch = 'lettersWithWords';
const int lettersWithWordsShownAge = 6;
const int lettersWithWordsDefaultOnAge = 7;

/// The smaller set of skills that "letters together with words" asks, and that every way into letters that skips the full list (the
/// child's level, the Russian "letters before 5" switch) still asks: a letter lesson's pictures are words already met, so no switch,
/// age or route serves letters to a child who has met none of the course's words.
class EarlySet {
  const EarlySet({this.requires = const <String>{}, this.requireAtLeast = const <SkillQuota>[]});

  /// Every one of these.
  final Set<String> requires;

  /// And of each of these groups, at least `count` skills.
  final List<SkillQuota> requireAtLeast;
}

class CourseGate {
  const CourseGate({
    required this.id,
    required this.course,
    this.requires = const <String>{},
    this.requireAtLeast = const <SkillQuota>[],
    this.holds = const <String>{},
    this.minAge,
    this.durableBelowAge,
    this.early,
    this.switchName,
    this.switchEffect,
    this.routeBypass = const <String>{},
  });

  final String id;
  final String course;

  /// Every one of these needs the mastery below.
  final Set<String> requires;

  /// And of each of these groups, at least `count` skills.
  final List<SkillQuota> requireAtLeast;

  /// The skills held back until the gate is open.
  final Set<String> holds;

  /// The youngest age, in years, at which the gate opens by default (English oral gate and Russian letters gate 5, Hebrew letters
  /// gate 5). A gate reads the age, never the presentation band.
  final int? minAge;

  /// Durable mastery is needed while the child is younger than this many years; from it on, fresh is enough (English: 7). Null
  /// means fresh mastery is always enough.
  final int? durableBelowAge;

  /// The early set, or null for a gate that has none (Hebrew: a Hebrew-speaking child has the words). A gate with an early set takes
  /// the parent switch [lettersWithWordsSwitch].
  final EarlySet? early;

  /// The parent switch of the gate, by name (`oralOnly`, `lettersBefore5`) and how it acts.
  final String? switchName;
  final SwitchEffect? switchEffect;

  /// Routes (a Russian child's `new`, `heritage` or `reader`) for which the age condition does not apply.
  final Set<String> routeBypass;
}

/// What is known about one child when a gate is looked at.
class GateInput {
  const GateInput({
    required this.mastery,
    required this.ageBand,
    this.switchesOn = const <String>{},
    this.placedOpen = const <String>{},
    this.known = const <String>{},
    this.route,
    this.ageMonths,
  });

  /// The mastery of each skill (a skill that is missing has none).
  final Map<String, MasteryLevel> mastery;

  /// The child's age bracket (0 for 3 to 4, 1 for 5 to 6, 2 for 7 to 8): the age condition is read from this when the age in months is
  /// not known. Never the presentation band, which the parent may have changed.
  final int ageBand;

  /// The parent switches that are on, by name. `lettersWithWords` is in it when it is on for this child (the parent's choice, else the
  /// age's default, and never under 6;0).
  final Set<String> switchesOn;

  /// The gates placement marked open: the parent says the child knows letters or reads, and the placement confirmed it (level comes
  /// before age).
  final Set<String> placedOpen;

  /// The skills the child knows, taught or assumed by placement (`Engine.isMet`). Only the early set is read from it.
  final Set<String> known;
  final String? route;

  /// The child's age in months on the device (B-29), or null when no month and year of birth were given. When it is known a gate's
  /// minimum age is read from it, not from the bracket. It is worked out on the phone for this check and goes nowhere.
  final int? ageMonths;
}

/// Why a gate is closed.
enum GateReason { parentHolds, tooYoung, skillsMissing, noWordsYet }

class GateResult {
  const GateResult({
    required this.open,
    this.reasons = const <GateReason>[],
    this.missing = const <String>[],
  });

  final bool open;
  final List<GateReason> reasons;

  /// Skills that are still short of the mastery the gate needs (the parent view: "what is left").
  final List<String> missing;
}

/// The youngest age, in years, in each age bracket.
const List<int> bracketMinAge = <int>[3, 5, 7];

/// Whether the child is [years] or older: by the age in months when it is known ("not before 5" opens at 5;0), else by the youngest age
/// of the bracket.
bool ageAtLeast({int? months, required int ageBand, required int years}) =>
    months != null ? months >= years * 12 : bracketMinAge[ageBand.clamp(0, 2)] >= years;

bool _tooYoung(GateInput input, int minYears) =>
    !ageAtLeast(months: input.ageMonths, ageBand: input.ageBand, years: minYears);

/// The skills of `requires` and of the quotas that [enough] does not accept, in id order.
List<String> _missing(Set<String> requires, List<SkillQuota> quotas, bool Function(String) enough) {
  final List<String> missing = <String>[
    for (final String s in (requires.toList()..sort()))
      if (!enough(s)) s,
  ];
  for (final SkillQuota q in quotas) {
    if (q.skills.where(enough).length < q.count) {
      missing.addAll(<String>[
        for (final String s in (q.skills.toList()..sort()))
          if (!enough(s) && !missing.contains(s)) s,
      ]);
    }
  }
  return missing;
}

/// Whether [gate] is open for [input]. The order is: the parent's hold; the parent's override that opens, and placement above the gate
/// (level before age), which skip the age and the full list of skills but still ask the early set, if the gate has one; the age; then the
/// skills, the early set instead of the full list when "letters together with words" is on (and the child is 6 or more).
GateResult gateResult(CourseGate gate, GateInput input) {
  final bool switchOn = gate.switchName != null && input.switchesOn.contains(gate.switchName);
  if (switchOn && gate.switchEffect == SwitchEffect.closes) {
    return const GateResult(open: false, reasons: <GateReason>[GateReason.parentHolds]);
  }
  final EarlySet? early = gate.early;
  if ((switchOn && gate.switchEffect == SwitchEffect.opens) || input.placedOpen.contains(gate.id)) {
    if (early == null) return const GateResult(open: true);
    final List<String> missing = _missing(early.requires, early.requireAtLeast, input.known.contains);
    return missing.isEmpty
        ? const GateResult(open: true)
        : GateResult(open: false, reasons: const <GateReason>[GateReason.noWordsYet], missing: missing);
  }

  final List<GateReason> reasons = <GateReason>[];
  final bool ageApplies = gate.minAge != null && !gate.routeBypass.contains(input.route);
  if (ageApplies && _tooYoung(input, gate.minAge!)) reasons.add(GateReason.tooYoung);

  final bool together =
      early != null &&
      input.switchesOn.contains(lettersWithWordsSwitch) &&
      !_tooYoung(input, lettersWithWordsShownAge);
  final MasteryLevel needed = gate.durableBelowAge != null && _tooYoung(input, gate.durableBelowAge!)
      ? MasteryLevel.durable
      : MasteryLevel.fresh;
  bool enough(String skill) => (input.mastery[skill] ?? MasteryLevel.none).index >= needed.index;
  final List<String> missing = together
      ? _missing(early.requires, early.requireAtLeast, enough)
      : _missing(gate.requires, gate.requireAtLeast, enough);
  if (missing.isNotEmpty) reasons.add(GateReason.skillsMissing);
  return GateResult(open: reasons.isEmpty, reasons: reasons, missing: missing);
}

/// The skills that are held back from a child: those of every gate that is closed. A skill held by two gates stays held
/// while either is closed.
Set<String> heldSkills(Iterable<CourseGate> gates, GateInput input) => <String>{
  for (final CourseGate g in gates)
    if (!gateResult(g, input).open) ...g.holds,
};

/// The mastery of every skill the engine has seen, read from its state: fresh mastery once reached, durable after its
/// delayed check. (A skill due for a revisit has still reached fresh mastery.)
///
/// A roll-up has the lowest level among its groups, and none while any group has none (it means all its groups).
Map<String, MasteryLevel> masteryLevels(Engine engine) {
  final Map<String, MasteryLevel> out = <String, MasteryLevel>{
    for (final MapEntry<String, SkillState> e in engine.state.skills.entries)
      if (e.value.freshAt != null)
        e.key: e.value.durableAt != null ? MasteryLevel.durable : MasteryLevel.fresh,
  };
  for (final MapEntry<String, List<String>> r in engine.catalog.subSkills.entries) {
    final int lowest = r.value
        .map((String g) => (out[g] ?? MasteryLevel.none).index)
        .reduce((int a, int b) => a < b ? a : b);
    if (lowest > 0) out[r.key] = MasteryLevel.values[lowest];
  }
  return out;
}

/// The skills the child knows for the words floor of a gate: those the engine counts as met, taught (the unlock bar) or assumed by
/// placement. A roll-up is known when all its groups are.
Set<String> knownSkills(Engine engine) {
  final Set<String> out = <String>{
    for (final String id in engine.catalog.skills.keys)
      if (!engine.catalog.isRollUp(id) && engine.isMet(id)) id,
  };
  for (final MapEntry<String, List<String>> r in engine.catalog.subSkills.entries) {
    if (r.value.every(out.contains)) out.add(r.key);
  }
  return out;
}
