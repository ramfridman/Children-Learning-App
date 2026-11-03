import 'state.dart';

/// The status of a roll-up skill from the statuses of its groups (docs/languages/frame.md section 3.3.2). A roll-up has no
/// estimate of its own: it is fresh when all its groups are fresh, durable when all are durable, and as a prerequisite it
/// means all groups. [groups] must hold one status for every group of the roll-up, not only the ones the child has begun.
SkillStatus rollUpStatus(List<SkillStatus> groups) {
  if (groups.isEmpty) return SkillStatus.notStarted;
  if (groups.every((SkillStatus s) => s == SkillStatus.durableMastery)) return SkillStatus.durableMastery;
  const Set<SkillStatus> reached = <SkillStatus>{
    SkillStatus.freshMastery,
    SkillStatus.durableMastery,
    SkillStatus.needsRevisit,
  };
  if (groups.every(reached.contains)) {
    return groups.contains(SkillStatus.needsRevisit) ? SkillStatus.needsRevisit : SkillStatus.freshMastery;
  }
  const Set<SkillStatus> begun = <SkillStatus>{
    SkillStatus.learning,
    SkillStatus.freshMastery,
    SkillStatus.durableMastery,
    SkillStatus.needsRevisit,
    SkillStatus.gap,
  };
  if (groups.any(begun.contains)) return SkillStatus.learning;
  return groups.contains(SkillStatus.ready) ? SkillStatus.ready : SkillStatus.notStarted;
}
