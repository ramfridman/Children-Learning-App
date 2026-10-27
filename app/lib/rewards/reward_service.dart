import 'package:drift/drift.dart' show Value;

import '../content/engine_adapter.dart';
import '../data/app_database.dart';
import '../engine/engine.dart';
import '../engine/types.dart';
import 'award.dart';
import 'reward_rules.dart';

/// Works out what a child has earned and keeps it (M8). The rules are pure (`dueAwards`); this class reads the child's
/// history, asks the rules, and writes only what is missing. It never removes anything: whatever a replay, a rebuild or a
/// late event from another phone concludes, an award once given stays.
class RewardService {
  RewardService({required this.db, required this.catalog, required this.domains, required this.nowMs});

  final AppDatabase db;

  /// The skills as the engine reads them, and the domain each belongs to (which land it grows in).
  final Catalog catalog;
  final Map<String, String> domains;
  final int Function() nowMs;

  DateTime get _now => DateTime.fromMillisecondsSinceEpoch(nowMs(), isUtc: true);

  static String seededKey(String childId) => 'rewards_seeded:$childId';

  /// What the child's history says is due now. Writes nothing (the dev page and the tests look at this).
  Future<List<AwardDue>> due(String childId) async {
    final List<AttemptEvent> events = (await db.attemptsOf(childId)).map(eventOf).toList()
      ..sort((AttemptEvent a, AttemptEvent b) => a.at.compareTo(b.at));
    final Engine engine = Engine(catalog: catalog)..replay(events);
    final List<SkillFact> skills = <SkillFact>[
      for (final MapEntry<String, String> s in domains.entries)
        SkillFact(id: s.key, domain: s.value, durableAt: engine.state.skills[s.key]?.durableAt),
    ];
    final List<FinishedLesson> lessons = <FinishedLesson>[
      for (final Session s in await db.sessionsOf(childId))
        if (s.endReason == 'finished' && s.plan.startsWith('lesson:'))
          FinishedLesson(
            lessonId: s.plan.substring('lesson:'.length),
            at: (s.endedAt ?? s.startedAt).toUtc(),
          ),
    ];
    return dueAwards(skills: skills, lessons: lessons);
  }

  /// Gives the child whatever is due and was not given yet, and returns the rows given just now.
  ///
  /// The first time for a child (a child with history from before rewards existed, or one a second phone has just
  /// pulled) everything already earned is given quietly, so that only the single highest trophy is presented (M8, Q8).
  /// After that stickers wait to be revealed and trophies wait for their ceremony; golden stars show on the map and need
  /// no ceremony.
  Future<List<Reward>> evaluate(String childId) async {
    final List<AwardDue> due = await this.due(childId);
    final Set<String> have = await db.awardKeys(childId);
    final List<AwardDue> missing = due.where((AwardDue a) => !have.contains(a.key)).toList();
    final bool firstTime = await db.setting(seededKey(childId)) == null;
    final String? presented = firstTime ? _highestTrophy(missing) : null;
    final DateTime now = _now;
    final Set<String> given = <String>{};
    for (final AwardDue a in missing) {
      final bool showLater = switch (a.kind) {
        AwardKind.star => false,
        AwardKind.sticker || AwardKind.trophy => !firstTime || a.key == presented,
        _ => false,
      };
      final bool added = await db.addReward(
        RewardsCompanion.insert(
          profileId: childId,
          awardKey: a.key,
          kind: a.kind.name,
          at: a.at,
          seenAt: Value<DateTime?>(showLater ? null : now),
        ),
      );
      if (added) given.add(a.key);
    }
    if (firstTime) await db.putSetting(seededKey(childId), 'yes');
    return <Reward>[
      for (final Reward r in await db.rewardsOf(childId))
        if (given.contains(r.awardKey)) r,
    ];
  }

  /// The one trophy worth a ceremony among several: the highest tier, and of those the one earned last.
  static String? _highestTrophy(List<AwardDue> due) => pickCeremony(<({String key, DateTime at})>[
    for (final AwardDue a in due)
      if (a.kind == AwardKind.trophy) (key: a.key, at: a.at),
  ]);

  /// Of several trophies that unlocked together, the key of the one to present: the highest tier, then the latest.
  static String? pickCeremony(List<({String key, DateTime at})> trophies) {
    String? best;
    int bestTier = -1;
    DateTime? bestAt;
    for (final ({String key, DateTime at}) t in trophies) {
      final int tier = Awards.trophyOf(t.key)?.tier.index ?? -1;
      if (tier > bestTier || (tier == bestTier && bestAt != null && t.at.isAfter(bestAt))) {
        best = t.key;
        bestTier = tier;
        bestAt = t.at;
      }
    }
    return best;
  }
}
