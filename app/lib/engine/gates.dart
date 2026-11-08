import 'engine.dart';
import 'state.dart';

// Course gates (docs/languages/frame.md section 3.3.6). A gate is a named condition on a set of skills that holds other skills
// back: the English oral gate keeps letters from a child who cannot yet understand enough English, the Russian letters gate
// keeps them from a new learner who has too few words. A gate holds skills back; the child never sees a lock. Pure: a gate and
// what is known about a child go in, open or closed and the reasons come out.

/// How much a skill is mastered, for a gate: fresh mastery is the first, durable mastery comes after a delayed check.
enum MasteryLevel { none, fresh, durable }

/// A group of skills of which at least [count] must be mastered (the Russian gate: "A-12 and three themes").
class SkillQuota {
  const SkillQuota({required this.skills, required this.count});

  final Set<String> skills;
  final int count;
}

/// Which way a parent switch acts on a gate: the English "oral only" keeps its gate closed, the Russian "letters before 5"
/// opens its gate whatever else is true.
enum SwitchEffect { closes, opens }

class CourseGate {
  const CourseGate({
    required this.id,
    required this.course,
    this.requires = const <String>{},
    this.requireAtLeast = const <SkillQuota>[],
    this.holds = const <String>{},
    this.minAge,
    this.neverUnderBand,
    this.durableBelowBand,
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

  /// The youngest age, in years, at which the gate opens by default (the Russian letters gate: 5).
  final int? minAge;

  /// The gate never opens while the presentation band is this one or younger (English: Band A, 0).
  final int? neverUnderBand;

  /// Durable mastery is needed while the presentation band is younger than this; from it on, fresh is enough (English: from
  /// Band C, 2). Null means fresh mastery is always enough.
  final int? durableBelowBand;

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
    required this.presentationBand,
    this.switchesOn = const <String>{},
    this.placedOpen = const <String>{},
    this.route,
    this.ageMonths,
  });

  /// The mastery of each skill (a skill that is missing has none).
  final Map<String, MasteryLevel> mastery;

  /// The child's age bracket (0 for 3 to 4, 1 for 5 to 6, 2 for 7 to 8): the age condition is read from this, not from a
  /// presentation band the parent may have changed.
  final int ageBand;
  final int presentationBand;

  /// The parent switches that are on, by name.
  final Set<String> switchesOn;

  /// The gates placement marked open ("a child placed above a gate has it marked open").
  final Set<String> placedOpen;
  final String? route;

  /// The child's age in months on the device (B-29), or null when no month and year of birth were given. When it is known a gate's
  /// minimum age is read from it, not from the bracket. It is worked out on the phone for this check and goes nowhere.
  final int? ageMonths;
}

/// Why a gate is closed.
enum GateReason { parentHolds, bandTooYoung, tooYoung, skillsMissing }

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

/// Whether the child is under [minYears]: by the age in months when it is known ("not before 5" opens at 5;0), else by the bracket.
bool _tooYoung(GateInput input, int minYears) {
  final int? months = input.ageMonths;
  return months != null ? months < minYears * 12 : bracketMinAge[input.ageBand.clamp(0, 2)] < minYears;
}

/// Whether [gate] is open for [input]. The order is: the parent's hold, a presentation band too young, the parent's override
/// that opens, placement above the gate, the age, then the skills.
GateResult gateResult(CourseGate gate, GateInput input) {
  final bool switchOn = gate.switchName != null && input.switchesOn.contains(gate.switchName);
  if (switchOn && gate.switchEffect == SwitchEffect.closes) {
    return const GateResult(open: false, reasons: <GateReason>[GateReason.parentHolds]);
  }
  if (gate.neverUnderBand != null && input.presentationBand <= gate.neverUnderBand!) {
    return const GateResult(open: false, reasons: <GateReason>[GateReason.bandTooYoung]);
  }
  if (switchOn && gate.switchEffect == SwitchEffect.opens) return const GateResult(open: true);
  if (input.placedOpen.contains(gate.id)) return const GateResult(open: true);

  final List<GateReason> reasons = <GateReason>[];
  final bool ageApplies = gate.minAge != null && !gate.routeBypass.contains(input.route);
  if (ageApplies && _tooYoung(input, gate.minAge!)) reasons.add(GateReason.tooYoung);

  final MasteryLevel needed = gate.durableBelowBand != null && input.presentationBand < gate.durableBelowBand!
      ? MasteryLevel.durable
      : MasteryLevel.fresh;
  bool enough(String skill) => (input.mastery[skill] ?? MasteryLevel.none).index >= needed.index;
  final List<String> missing = <String>[
    for (final String s in (gate.requires.toList()..sort()))
      if (!enough(s)) s,
  ];
  for (final SkillQuota q in gate.requireAtLeast) {
    if (q.skills.where(enough).length < q.count) {
      missing.addAll(<String>[
        for (final String s in (q.skills.toList()..sort()))
          if (!enough(s) && !missing.contains(s)) s,
      ]);
    }
  }
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
