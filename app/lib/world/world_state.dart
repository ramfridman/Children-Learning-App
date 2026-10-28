import 'dart:convert';

import '../engine/engine.dart';
import '../engine/state.dart';
import '../engine/types.dart';
import '../parent/progress.dart' show SkillInfo;
import '../rewards/award.dart';

/// Which drawing a skill owns (assets/world/objects.json): its own, else its domain's, else the fallback plant.
class WorldCatalog {
  const WorldCatalog({required this.skills, required this.domains, required this.fallback});

  factory WorldCatalog.parse(String source) {
    final Map<String, Object?> m = jsonDecode(source) as Map<String, Object?>;
    Map<String, String> strings(Object? o) => <String, String>{
      for (final MapEntry<String, Object?> e
          in (o as Map<String, Object?>? ?? const <String, Object?>{}).entries)
        e.key: e.value! as String,
    };
    return WorldCatalog(
      skills: strings(m['skills']),
      domains: strings(m['domains']),
      fallback: m['fallback']! as String,
    );
  }

  final Map<String, String> skills;
  final Map<String, String> domains;
  final String fallback;

  String objectFor(String skillId, String domain) => skills[skillId] ?? domains[domain] ?? fallback;

  /// The same catalog, where the installed pack names a skill's object (pack 0.3.0), that name wins.
  WorldCatalog withPack(Map<String, String> packObjects) =>
      WorldCatalog(skills: <String, String>{...skills, ...packObjects}, domains: domains, fallback: fallback);
}

/// How far an object has grown. Nothing is ever padlocked and nothing ever goes back: a skill that needs a revisit keeps
/// its colour and its star, and shows a bell flag instead.
enum GrowthStage {
  /// A pencil sketch: the child is still practising (or has not started).
  sketch,

  /// In full colour: fresh mastery.
  colour,

  /// In full colour with fruit and a golden star: lasting understanding.
  fruit,
}

class WorldObject {
  const WorldObject({
    required this.skillId,
    required this.title,
    required this.objectId,
    required this.stage,
    required this.bell,
    this.line,
  });

  final String skillId;

  /// One line for the child of what they can do, with niqqud, when the pack has one (pack 0.3.0).
  final String? line;

  /// What the child can do, for a parent or a screen reader.
  final String title;
  final String objectId;
  final GrowthStage stage;

  /// A check is due: the object calls for help with a bell flag, and tapping it opens a short revisit mission.
  final bool bell;

  bool get star => stage == GrowthStage.fruit;
}

/// Every land's objects, from what the engine concluded and what the child has been given. Pure.
///
/// A golden star is shown if the engine says the skill reached lasting understanding **or** the child has the star award
/// (so a replay that no longer finds it cannot take it off the map).
Map<TrophyLand, List<WorldObject>> buildWorld({
  required Engine engine,
  required Map<String, SkillInfo> skills,
  required Set<String> starredSkills,
  required WorldCatalog catalog,
  required DateTime now,
  Map<String, String> lines = const <String, String>{},
}) {
  final Set<String> due = engine.dueChecks(now).toSet();
  final Map<TrophyLand, List<WorldObject>> out = <TrophyLand, List<WorldObject>>{};
  final List<String> ids = skills.keys.toList()..sort();
  for (final String id in ids) {
    final SkillInfo info = skills[id]!;
    final TrophyLand? land = TrophyLand.ofDomain(info.domain);
    if (land == null) continue;
    final SkillState? s = engine.state.skills[id];
    final bool lasting = (s?.durableAt != null) || starredSkills.contains(id);
    final bool fresh = s?.freshAt != null;
    (out[land] ??= <WorldObject>[]).add(
      WorldObject(
        skillId: id,
        title: info.title,
        objectId: catalog.objectFor(id, info.domain),
        stage: lasting
            ? GrowthStage.fruit
            : fresh
            ? GrowthStage.colour
            : GrowthStage.sketch,
        bell: due.contains(id),
        line: lines[id],
      ),
    );
  }
  return out;
}

/// The items of a revisit mission for one skill: three to five, each a different way of asking, the ones the child has
/// not met since reaching mastery first, and another way of explaining than the one last used when the last check was
/// failed. Deterministic. Empty if the skill has no item to ask.
List<String> missionItemIds(Engine engine, String skillId, {int max = 5}) {
  final SkillState? s = engine.state.skills[skillId];
  final List<ItemMeta> candidates = <ItemMeta>[
    for (final ItemMeta i in engine.catalog.itemsFor(skillId))
      if (i.purpose != Purpose.probe) i,
  ];
  if (candidates.isEmpty) return const <String>[];
  final Representation? avoid = (s?.needsRevisit ?? false) ? s?.lastRepresentation : null;
  double score(ItemMeta i) {
    double v = 0;
    if (s != null && s.itemsAtFresh.contains(i.id)) v += 2; // met when mastery was reached: less of a check
    if (avoid != null && i.representation == avoid) v += 1;
    if (i.variantGroup.isNotEmpty && i.variantGroup == s?.lastVariantGroup) v += 1;
    return v + i.difficulty * 0.1;
  }

  candidates.sort((ItemMeta a, ItemMeta b) {
    final int c = score(a).compareTo(score(b));
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  final List<ItemMeta> picked = <ItemMeta>[];
  final Set<String> groups = <String>{};
  for (final ItemMeta i in candidates) {
    if (picked.length >= max) break;
    if (i.variantGroup.isNotEmpty && !groups.add(i.variantGroup)) continue;
    picked.add(i);
  }
  // A skill with only one or two ways of asking still gets a few items: the rest are filled with its other items.
  for (final ItemMeta i in candidates) {
    if (picked.length >= 3) break;
    if (!picked.contains(i)) picked.add(i);
  }
  return <String>[for (final ItemMeta i in picked) i.id];
}
