import 'dart:math' as math;

import 'award.dart';

/// What the rules know about one skill: where it grows and when it reached lasting understanding (null if it has not).
/// Nothing else about a child's answers gets in here, so no speed, no time played and no number of tries can earn an
/// award (PLAN: no prize for speed or for playing longer). A test reads this file's text to keep it so.
class SkillFact {
  const SkillFact({required this.id, required this.domain, required this.durableAt});

  final String id;
  final String domain;
  final DateTime? durableAt;
}

/// A lesson the child finished, and when.
class FinishedLesson {
  const FinishedLesson({required this.lessonId, required this.at});

  final String lessonId;
  final DateTime at;
}

/// The good habits a medal celebrates (PLAN: habit medals). A moment is something the child did, never how fast or how long.
enum HabitKind {
  /// Said "I'm not sure" or asked to be shown.
  askedForHelp,

  /// Got it right after a mistake, on the same activity.
  triedAgain,
}

class HabitMoment {
  const HabitMoment({required this.kind, required this.at});

  final HabitKind kind;
  final DateTime at;
}

/// One habit medal. [habit] is null for a medal whose activities do not exist yet (explaining how you knew, fixing the
/// robot's bug, the weekly garden): it stays a locked silhouette until M9 has them.
class MedalDef {
  const MedalDef({required this.id, required this.habit, required this.needed});

  final String id;
  final HabitKind? habit;
  final int needed;
}

const List<MedalDef> medalDefs = <MedalDef>[
  MedalDef(id: 'brave-asker', habit: HabitKind.askedForHelp, needed: 5),
  MedalDef(id: 'try-again', habit: HabitKind.triedAgain, needed: 3),
  MedalDef(id: 'explainer', habit: null, needed: 3),
  MedalDef(id: 'bug-fixer', habit: null, needed: 5),
];

/// Island decorations come with the number of skills understood for good (M8, Q7).
const List<int> decorationSteps = <int>[10, 20, 30];

/// A land has trophies only when it has at least this many skills (M8, Q3): with fewer, bronze, silver and gold would
/// all arrive at once and mean nothing.
const int minSkillsForLandTrophy = 3;

/// How many skills of a land with [n] skills must reach lasting understanding for each tier (M8, Q2): bronze the first
/// two, silver half (rounded up, and never fewer than bronze), gold all of them.
int skillsNeeded(TrophyTier tier, int n) {
  final int bronze = math.min(2, n);
  return switch (tier) {
    TrophyTier.bronze => bronze,
    TrophyTier.silver => math.max(bronze, (n + 1) ~/ 2),
    TrophyTier.gold => n,
  };
}

/// Every award that is due, for stickers, golden stars and land trophies. Pure: the same facts give the same awards, so
/// a replay, a rebuild or a second phone always agrees. It only ever adds: the caller keeps what it gave before.
///
/// - A sticker for each finished lesson, numbered in the order the lesson was finished.
/// - A golden star for each skill that reached lasting understanding.
/// - A land trophy when enough skills of a land reached lasting understanding. Fresh mastery earns none.
/// - A habit medal when the child did the habit often enough, and an island decoration for 10, 20 and 30 skills understood
///   for good.
List<AwardDue> dueAwards({
  required List<SkillFact> skills,
  required List<FinishedLesson> lessons,
  List<HabitMoment> habits = const <HabitMoment>[],
  int minSkillsPerLand = minSkillsForLandTrophy,
}) {
  final List<AwardDue> out = <AwardDue>[];

  final List<FinishedLesson> ordered = List<FinishedLesson>.of(lessons)
    ..sort((FinishedLesson a, FinishedLesson b) => a.at.compareTo(b.at));
  final Map<String, int> seen = <String, int>{};
  for (final FinishedLesson l in ordered) {
    final int n = seen[l.lessonId] = (seen[l.lessonId] ?? 0) + 1;
    out.add(AwardDue(key: Awards.sticker(l.lessonId, n), kind: AwardKind.sticker, at: l.at));
  }

  for (final SkillFact s in skills) {
    final DateTime? at = s.durableAt;
    if (at != null) out.add(AwardDue(key: Awards.star(s.id), kind: AwardKind.star, at: at));
  }

  for (final TrophyLand land in TrophyLand.values) {
    final List<SkillFact> inLand = skills.where((SkillFact s) => s.domain == land.domain).toList();
    final int n = inLand.length;
    if (n < minSkillsPerLand) continue;
    final List<DateTime> lasting = <DateTime>[
      for (final SkillFact s in inLand)
        if (s.durableAt != null) s.durableAt!,
    ]..sort();
    for (final TrophyTier tier in TrophyTier.values) {
      final int need = skillsNeeded(tier, n);
      if (lasting.length >= need) {
        out.add(AwardDue(key: Awards.trophy(land, tier), kind: AwardKind.trophy, at: lasting[need - 1]));
      }
    }
  }

  for (final MedalDef m in medalDefs) {
    final HabitKind? kind = m.habit;
    if (kind == null) continue;
    final List<DateTime> moments = <DateTime>[
      for (final HabitMoment h in habits)
        if (h.kind == kind) h.at,
    ]..sort();
    if (moments.length >= m.needed) {
      out.add(AwardDue(key: Awards.medal(m.id), kind: AwardKind.medal, at: moments[m.needed - 1]));
    }
  }

  final List<DateTime> allLasting = <DateTime>[
    for (final SkillFact s in skills)
      if (s.durableAt != null) s.durableAt!,
  ]..sort();
  for (final int n in decorationSteps) {
    if (allLasting.length >= n) {
      out.add(AwardDue(key: Awards.decoration(n), kind: AwardKind.decoration, at: allLasting[n - 1]));
    }
  }
  return out;
}
