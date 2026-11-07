import 'engine.dart';
import 'params.dart';
import 'state.dart';
import 'types.dart';

// The check visit of a language course (docs/languages/band-a-build.md section 7.4, rules C-1 to C-6): a short visit of one skill on a
// later day, which gives the skill the evidence a lesson cannot (a check, a second day, a word or a way of showing not yet met). To the
// child it is a visit, like a revisit, and never a test. Pure: the engine's state goes in, item ids come out; nothing here reads a clock.

/// How many items a check visit holds at most by presentation band (frame section 3.1): 3 to 5 under Band A, up to 8 and 12 above.
int checkVisitMax(int band) => switch (band) {
  0 => 5,
  1 => 8,
  _ => 12,
};

const int _checkVisitMin = 3;

/// C-1: whether [skillId] is ready for a check visit on the day [today] (`Engine.dayKey`). [taught]: every lesson of the course path that
/// teaches it was finished at least once or placed (the caller reads the lessons; the engine knows none).
///
/// Ready: started (or taken as known by placement and not verified yet), not fresh, not a trace node (which is practised, never mastered),
/// taught, and nothing of it answered today, so the check is a retrieval after a delay and not an echo of the lesson.
bool checkVisitReady(Engine engine, String skillId, {required bool taught, required int today}) {
  if (!taught || !engine.catalog.skills.containsKey(skillId) || engine.catalog.isRollUp(skillId)) {
    return false;
  }
  if (engine.graph.node(skillId).writing == WritingRule.practised) return false;
  final SkillState? s = engine.state.skills[skillId];
  if (s?.freshAt != null) return false;
  if (!(s?.started ?? false) && !engine.isAssumed(skillId)) return false;
  final DateTime? last = s?.lastAttemptAt;
  return last == null || Engine.dayKey(last) != today;
}

/// The items of the check visit of [skillId], in the order they are played (C-3), or empty when the skill has nothing to ask.
///
/// 1. a warm-up: an easy learn item already answered right (the likeliest success), after a failed check one in another way of showing;
/// 2. the checks: one for each check type the skill still lacks (a balanced pair is one, served as its two items), preferring a word not
///    asked in the last visit and a way of showing not passed yet; after a failed check, another item of the failed type;
/// 3. a learn item for each word of the set not yet answered right without a hint, while there is room;
/// 4. a learn item in a way of showing the skill has not passed yet, if the steps above brought none;
/// 5. when the skill lacks only days, successes or the estimate: one check of a type it has passed, and learn items to fill the visit;
/// 6. an ending on a success: a last easy item when the visit would end on a check.
///
/// [inLessonChecks] are the checks that belong to a lesson (a question about the story just heard): never served here. [max] is
/// [checkVisitMax] of the child's band.
List<String> checkVisitItemIds(
  Engine engine,
  String skillId, {
  Set<String> inLessonChecks = const <String>{},
  int max = 5,
}) {
  if (!engine.catalog.skills.containsKey(skillId)) return const <String>[];
  final SkillState? s = engine.state.skills[skillId];
  final SkillNode node = engine.graph.node(skillId);
  final bool core = engine.graph.isCore(skillId);
  final EngineParams p = engine.params;
  final CheckTrail? trail = s?.trail;
  final Set<String> rightItems = s?.successItems ?? const <String>{};
  final Set<String> lastVisit = trail?.lastVisitItems ?? const <String>{};
  final Set<Representation> passedWays = s?.representationsPassed ?? const <Representation>{};
  final Set<CheckType> passedChecks = s?.checksPassed ?? const <CheckType>{};

  final List<ItemMeta> pool = <ItemMeta>[
    for (final ItemMeta i in engine.catalog.itemsFor(skillId))
      if (!i.delight &&
          i.purpose != Purpose.probe &&
          !(i.purpose == Purpose.check && inLessonChecks.contains(i.id)))
        i,
  ]..sort(_easiestFirst);
  final List<ItemMeta> learn = <ItemMeta>[
    for (final ItemMeta i in pool)
      if (i.purpose == Purpose.learn) i,
  ];
  final List<ItemMeta> checks = <ItemMeta>[
    for (final ItemMeta i in pool)
      if (i.purpose == Purpose.check && i.checkType != CheckType.practice) i,
  ];
  if (learn.isEmpty && checks.isEmpty) return const <String>[];

  final List<ItemMeta> picked = <ItemMeta>[];
  bool take(ItemMeta? i) {
    if (i == null || picked.contains(i) || picked.length >= max) return false;
    picked.add(i);
    return true;
  }

  // A check with its partner in a balanced pair: both or neither.
  bool takeCheck(ItemMeta i) {
    final ItemMeta? partner = i.pairWith == null ? null : engine.catalog.items[i.pairWith];
    if (picked.length + (partner == null ? 1 : 2) > max) return false;
    take(i);
    take(partner);
    return true;
  }

  final Set<String> failedItems = trail?.failedItems ?? const <String>{};
  double askedBefore(ItemMeta i) =>
      (lastVisit.contains(i.id) ? 2 : 0) +
      (failedItems.contains(i.id) ? 3 : 0) +
      (passedWays.contains(i.representation) ? 1 : 0) +
      i.difficulty * 0.1;

  // 1. The warm-up.
  final Representation? failedWay = (trail?.failedTypes.isNotEmpty ?? false)
      ? trail!.failedRepresentation
      : null;
  final ItemMeta? warmUp =
      learn.where((ItemMeta i) => rightItems.contains(i.id) && i.representation != failedWay).firstOrNull ??
      learn.where((ItemMeta i) => i.representation != failedWay).firstOrNull ??
      learn.firstOrNull;
  take(warmUp);

  // 2. The checks the skill still lacks: the failed types first, then the others in the order of the enum.
  final int needChecks = node.needChecks ?? (core ? p.freshChecksCore : p.freshChecks);
  final List<CheckType> lacking = <CheckType>{
    for (final CheckType t in <CheckType>[...?trail?.failedTypes, ...CheckType.values])
      if (!passedChecks.contains(t) && checks.any((ItemMeta i) => i.checkType == t)) t,
  }.toList();
  final int missing = needChecks - passedChecks.length;
  for (final CheckType t in lacking.take(missing < 0 ? 0 : missing)) {
    final List<ItemMeta> ofType = <ItemMeta>[
      for (final ItemMeta i in checks)
        if (i.checkType == t) i,
    ]..sort((ItemMeta a, ItemMeta b) => askedBefore(a).compareTo(askedBefore(b)));
    for (final ItemMeta i in ofType) {
      if (takeCheck(i)) break;
    }
  }

  // 3. The words of the set not yet answered right without a hint.
  final Set<String> covered = <String>{for (final ItemMeta i in picked) i.variantGroup};
  for (final String group in (engine.uncoveredGroups(skillId).toList()..sort())) {
    if (covered.contains(group)) continue;
    final ItemMeta? forWord = learn.where((ItemMeta i) => i.variantGroup == group).firstOrNull;
    if (take(forWord)) covered.add(group);
  }

  // 4. A way of showing the skill has not passed yet.
  final int needWays =
      node.needRepresentations ?? (core ? p.freshRepresentationsCore : p.freshRepresentations);
  final Set<Representation> ways = <Representation>{
    ...passedWays,
    for (final ItemMeta i in picked) i.representation,
  };
  if (passedWays.length < needWays && ways.length < needWays) {
    take(learn.where((ItemMeta i) => !ways.contains(i.representation)).firstOrNull);
  }

  // 5. A skill that lacks only days, successes or the estimate: a check of a type it has passed, then learn items.
  if (!picked.any((ItemMeta i) => i.purpose == Purpose.check)) {
    // A type the skill has passed, if the skill has an item of one; any check otherwise.
    final List<ItemMeta> passedType = <ItemMeta>[
      for (final ItemMeta i in checks)
        if (passedChecks.contains(i.checkType)) i,
    ];
    final List<ItemMeta> again = (passedType.isEmpty ? checks.toList() : passedType)
      ..sort((ItemMeta a, ItemMeta b) => askedBefore(a).compareTo(askedBefore(b)));
    for (final ItemMeta i in again) {
      if (takeCheck(i)) break;
    }
  }
  final List<ItemMeta> rest = learn.toList()
    ..sort((ItemMeta a, ItemMeta b) {
      final int byVisit = (lastVisit.contains(a.id) ? 1 : 0).compareTo(lastVisit.contains(b.id) ? 1 : 0);
      if (byVisit != 0) return byVisit;
      final int byRight = (rightItems.contains(a.id) ? 1 : 0).compareTo(rightItems.contains(b.id) ? 1 : 0);
      return byRight != 0 ? byRight : _easiestFirst(a, b);
    });
  final bool onlyDays = missing <= 0;
  for (final ItemMeta i in rest) {
    if (picked.length >= (onlyDays ? max : _checkVisitMin)) break;
    take(i);
  }

  // 6. An ending on a success.
  if (picked.isNotEmpty && picked.last.purpose == Purpose.check) {
    take(
      learn.where((ItemMeta i) => rightItems.contains(i.id) && !picked.contains(i)).firstOrNull ??
          learn.where((ItemMeta i) => !picked.contains(i)).firstOrNull,
    );
  }
  return <String>[for (final ItemMeta i in picked) i.id];
}

int _easiestFirst(ItemMeta a, ItemMeta b) {
  final int c = a.difficulty.compareTo(b.difficulty);
  return c != 0 ? c : a.id.compareTo(b.id);
}
