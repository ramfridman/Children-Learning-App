import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/engine.dart';
import '../parent/progress.dart' show SkillInfo;
import '../rewards/award.dart';
import '../strings/he.dart';
import '../world/world_state.dart';
import 'providers.dart';
import 'reward_providers.dart';
import 'state.dart';

final FutureProvider<WorldCatalog> worldCatalogProvider = FutureProvider<WorldCatalog>(
  (Ref ref) async =>
      WorldCatalog.parse(await rootBundle.loadString('assets/world/objects.json', cache: false)),
);

/// What the map shows of one child's world, and the engine it was worked out with (a bell flag's mission is made from it).
class WorldView {
  const WorldView({required this.lands, required this.engine, required this.now});

  final Map<TrophyLand, List<WorldObject>> lands;
  final Engine engine;
  final DateTime now;

  /// The short revisit lesson for one skill, or null if it has no item to ask.
  Lesson? missionFor(String skillId) {
    final List<String> items = missionItemIds(engine, skillId);
    if (items.isEmpty) return null;
    return Lesson.mission(
      // A lesson id is lower case, as `sync-push` takes it (every answer carries it).
      id: 'mission-${skillId.toLowerCase()}',
      itemIds: items,
      skillIds: <String>[skillId],
      celebration: Spoken(vo: 'vo:core.celebrate.well', caption: He.celebrateWell.text),
    );
  }
}

/// One child's world: each skill's object, how far it has grown, and whether it calls for help. Rebuilt whenever the
/// child's awards change (a lesson ended, a sync brought something).
final FutureProviderFamily<WorldView, String> worldProvider = FutureProvider.family<WorldView, String>((
  Ref ref,
  String childId,
) async {
  final AppDatabase db = await ref.watch(databaseProvider.future);
  final PackContent content = await ref.watch(contentProvider.future);
  final WorldCatalog catalog = (await ref.watch(worldCatalogProvider.future)).withPack(<String, String>{
    for (final SkillDoc s in content.skills.values)
      if (s.worldObject != null) s.id: s.worldObject!,
  });
  final List<Reward> given = await ref.watch(rewardsProvider(childId).future);
  final DateTime now = DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true);
  final Engine engine = Engine(catalog: engineCatalog(content))
    ..replay((await db.attemptsOf(childId)).map(eventOf).toList()..sort((a, b) => a.at.compareTo(b.at)));
  return WorldView(
    engine: engine,
    now: now,
    lands: buildWorld(
      engine: engine,
      skills: <String, SkillInfo>{
        for (final SkillDoc s in content.skills.values) s.id: SkillInfo(title: s.title, domain: s.domain),
      },
      starredSkills: <String>{
        for (final Reward r in given)
          if (Awards.starOf(r.awardKey) != null) Awards.starOf(r.awardKey)!,
      },
      catalog: catalog,
      now: now,
      lines: <String, String>{
        for (final SkillDoc s in content.skills.values)
          if (s.childLine != null) s.id: s.childLine!,
      },
    ),
  );
});
