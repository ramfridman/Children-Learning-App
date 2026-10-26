import 'dart:math' as math;

import 'engine.dart';
import 'params.dart';
import 'representation.dart';
import 'state.dart';
import 'types.dart';

enum Phase { warmUp, repair, focus, revisit, delight, easyEnd }

/// An item the session served, and how it went (null until answered).
class Served {
  Served(this.item, this.phase, [this.result]);

  final ItemMeta item;
  final Phase phase;
  Result? result;
}

/// What the builder is told about the session so far.
class SessionContext {
  SessionContext({
    required this.sessionId,
    required this.band,
    required this.now,
    required this.served,
    this.limitReached = false,
    this.chosenDomain,
  });

  final int sessionId;

  /// 0, 1 or 2 for Bands A, B and C.
  final int band;
  final DateTime now;
  final List<Served> served;

  /// The parent's time limit is up: the session ends after the item in progress.
  final bool limitReached;

  /// The first letters of skill ids (`NUM`) the child chose to play; the builder honours it for the focus.
  final String? chosenDomain;
}

sealed class Pick {
  const Pick();
}

/// Play this item next, for this reason.
class ServeItem extends Pick {
  const ServeItem(this.item, this.phase, this.reason);

  final ItemMeta item;
  final Phase phase;
  final String reason;
}

/// The session is over: the wind-down celebration comes now.
class EndSession extends Pick {
  const EndSession(this.reason);

  final String reason;
}

/// Chooses the next item of a session by the plan of PLAN.md: a warm-up, repair of gaps, one or two skills
/// in focus, revisit checks due by memory, delight, and a calm end on a success.
class SessionBuilder {
  SessionBuilder({required this.engine, required math.Random random})
    : _chooser = RepresentationChooser(random),
      _rnd = random;

  final Engine engine;
  final RepresentationChooser _chooser;
  final math.Random _rnd;

  EngineParams get params => engine.params;
  Catalog get catalog => engine.catalog;

  /// How many items a session of this band holds.
  int totalItems(int band) =>
      math.max(4, (params.sessionMinutes[band] * 60 / params.secondsPerItem[band]).round());

  Pick next(SessionContext c) {
    final int total = totalItems(c.band);
    final Served? last = c.served.isEmpty ? null : c.served.last;

    // The end: after the planned number of items, or when the parent's time is up; always on a success.
    if (c.served.length >= total || c.limitReached) {
      final bool ended = last?.phase == Phase.easyEnd;
      if (ended || (last?.result == Result.correct && last!.phase != Phase.repair)) {
        return const EndSession('the session is over');
      }
      final ItemMeta? easy = _easyEnd(c);
      if (easy == null) return const EndSession('the session is over (no easy item to end on)');
      return ServeItem(easy, Phase.easyEnd, 'end on a success');
    }

    // A search for a gap has its probes next (a few per session, never as a test, within the repair share; a
    // probe that has begun is finished).
    final int warmQuota = c.band == 2 ? 2 : 1;
    final int repairMax = (total * params.repairShareMax).floor();
    final String? probeSkill = c.served.length < warmQuota ? null : engine.nextProbe();
    if (probeSkill != null &&
        (engine.state.probesInSession[c.sessionId] ?? 0) < params.probeMaxPerSession &&
        (_count(c, Phase.repair) < repairMax || engine.probeNeedsConfirmation)) {
      final ItemMeta? probe = probeItem(probeSkill, c.served.map((Served s) => s.item.id).toSet());
      if (probe != null) return ServeItem(probe, Phase.repair, 'probe $probeSkill');
    }

    // Stuck: leave the skill, give an easy win elsewhere.
    if (c.served.length >= warmQuota && engine.isStuck(c.sessionId)) {
      final String stuckOn = engine.state.sessions[c.sessionId]!.last.skillId;
      final ItemMeta? easy = _easiestWin(c, exceptSkill: stuckOn);
      if (easy != null) return ServeItem(easy, Phase.focus, 'stuck on $stuckOn: an easy win elsewhere');
    }

    final Phase? phase = _phase(c, total);
    if (phase == null) return const EndSession('nothing left to serve');
    final ServeItem? pick = _serve(phase, c);
    if (pick != null) return pick;
    // The chosen phase had nothing; try the others in order.
    for (final Phase p in <Phase>[Phase.focus, Phase.revisit, Phase.repair, Phase.delight, Phase.warmUp]) {
      if (p == phase) continue;
      final ServeItem? alt = _serve(p, c);
      if (alt != null) return alt;
    }
    return const EndSession('nothing left to serve');
  }

  // ---- which phase is next ----

  int _count(SessionContext c, Phase p) => c.served.where((Served s) => s.phase == p).length;

  bool _hasDelight() => catalog.items.values.any((ItemMeta i) => i.delight);

  Phase? _phase(SessionContext c, int total) {
    if (c.served.isEmpty) return Phase.warmUp;
    final int warmQuota = c.band == 2 ? 2 : 1;
    if (_count(c, Phase.warmUp) < warmQuota && c.served.length < warmQuota) return Phase.warmUp;

    final double revisitShare = const <double>[0.175, 0.225, 0.275][c.band];
    final int repairMax = (total * params.repairShareMax).floor();
    final int revisitQuota = (total * revisitShare).round();
    final int delightQuota = _hasDelight() ? (total * 0.2).round() : 0;
    final int warmUsed = _count(c, Phase.warmUp);
    final int focusQuota = math.max(1, total - warmUsed - revisitQuota - delightQuota - repairMax);

    final bool repairNeeded = engine.state.openGaps.isNotEmpty || engine.state.activeTags.isNotEmpty;
    final bool revisitDue = engine.dueChecks(c.now).isNotEmpty;

    // How far each phase is from its share, as a fraction; the most behind goes next. Repair is a cap,
    // not a quota: it takes at most its share, and only when there is something to repair.
    final Map<Phase, double> need = <Phase, double>{};
    if (repairNeeded && _count(c, Phase.repair) < repairMax) {
      need[Phase.repair] = 1 - _count(c, Phase.repair) / math.max(1, repairMax);
    }
    if (revisitDue && _count(c, Phase.revisit) < revisitQuota) {
      need[Phase.revisit] = 1 - _count(c, Phase.revisit) / math.max(1, revisitQuota);
    }
    if (delightQuota > 0 && _count(c, Phase.delight) < delightQuota) {
      need[Phase.delight] = 1 - _count(c, Phase.delight) / math.max(1, delightQuota);
    }
    need[Phase.focus] = math.max(0.0, 1 - _count(c, Phase.focus) / focusQuota) + 0.05;
    // A repair that is wanted goes early but not twice in a row.
    if (c.served.last.phase == Phase.repair) need.remove(Phase.repair);
    Phase best = Phase.focus;
    double bestNeed = -1;
    for (final MapEntry<Phase, double> e in need.entries) {
      if (e.value > bestNeed) {
        best = e.key;
        bestNeed = e.value;
      }
    }
    return best;
  }

  // ---- serving one phase ----

  ServeItem? _serve(Phase phase, SessionContext c) {
    final Set<String> used = <String>{for (final Served s in c.served) s.item.id};
    switch (phase) {
      case Phase.warmUp:
        final ItemMeta? i = _easiestWin(c);
        return i == null ? null : ServeItem(i, Phase.warmUp, 'an easy start');
      case Phase.repair:
        return _repair(c, used);
      case Phase.revisit:
        return _revisit(c, used);
      case Phase.delight:
        final List<ItemMeta> d = <ItemMeta>[
          for (final ItemMeta i in catalog.items.values)
            if (i.delight && !used.contains(i.id)) i,
        ];
        return d.isEmpty
            ? null
            : ServeItem(d[_rnd.nextInt(d.length)], Phase.delight, 'something free to play');
      case Phase.focus:
        return _focus(c, used);
      case Phase.easyEnd:
        return null;
    }
  }

  ServeItem? _repair(SessionContext c, Set<String> used) {
    // 1. A gap that is open: items for the missing skill, in another representation than the one that failed.
    for (final Gap g in engine.state.openGaps) {
      final ItemMeta? i = _itemFor(
        g.skill,
        c,
        used,
        avoid: engine.avoidRepresentation(g.skill) ?? engine.state.skills[g.skill]?.lastFailedRepresentation,
      );
      if (i != null) return ServeItem(i, Phase.repair, 'repair ${g.skill}');
    }
    // 2. An item built to expose a misconception that was repaired (or is active).
    for (final String tag in engine.state.activeTags) {
      for (final ItemMeta i in catalog.items.values) {
        if (i.contradicts == tag && !used.contains(i.id)) return ServeItem(i, Phase.repair, 'expose $tag');
      }
      for (final String id in catalog.tags[tag]?.repairActivities ?? const <String>[]) {
        final ItemMeta? i = catalog.items[id];
        if (i != null && !used.contains(i.id)) return ServeItem(i, Phase.repair, 'repair activity of $tag');
      }
    }
    return null;
  }

  ServeItem? _revisit(SessionContext c, Set<String> used) {
    for (final String id in engine.dueChecks(c.now)) {
      final SkillState s = engine.state.skills[id]!;
      // A different item of the variant group than the one last used; another representation after a failure.
      final ItemMeta? i = _itemFor(
        id,
        c,
        used,
        avoid: s.needsRevisit ? s.lastRepresentation : null,
        differentVariantFrom: s.lastVariantGroup,
        preferNotIn: s.itemsAtFresh,
      );
      if (i != null) return ServeItem(i, Phase.revisit, 'check $id');
    }
    return null;
  }

  ServeItem? _focus(SessionContext c, Set<String> used) {
    final Set<String> focusSkills = <String>{
      for (final Served s in c.served)
        if (s.phase == Phase.focus) s.item.primarySkill,
    };
    final Set<String> newInSession = engine.state.newSkillsInSession[c.sessionId] ?? const <String>{};
    // A skill gets a few items and then the next takes over, so that about two are in focus in a session.
    final int perSkill = math.max(params.focusItemsPerSkill, (totalItems(c.band) * 0.275).ceil());
    final Map<String, int> doneToday = <String, int>{};
    for (final Served s in c.served) {
      if (s.phase == Phase.focus) doneToday[s.item.primarySkill] = (doneToday[s.item.primarySkill] ?? 0) + 1;
    }
    final List<String> candidates = <String>[];
    for (final String id in catalog.skills.keys) {
      final SkillStatus st = engine.statusOf(id, c.now);
      if (st != SkillStatus.ready && st != SkillStatus.learning) continue;
      if (engine.state.openGaps.any((Gap g) => g.skill == id && !g.repaired) && st != SkillStatus.learning) {
        continue;
      }
      if (!(engine.state.skills[id]?.started ?? false) &&
          newInSession.length >= params.maxNewSkillsPerSession) {
        continue;
      }
      // Enough of this one for today: a skill gets a few items, then the next takes over.
      if ((doneToday[id] ?? 0) >= perSkill) continue;
      candidates.add(id);
    }
    if (candidates.isEmpty) {
      // Everything is saturated: go on with the weakest of the skills in focus rather than stop.
      for (final String id in doneToday.keys) {
        final SkillStatus st = engine.statusOf(id, c.now);
        if (st == SkillStatus.ready || st == SkillStatus.learning) candidates.add(id);
      }
    }
    if (candidates.isEmpty) return null;
    // Keep to one or two skills at a time: the ones already in focus, then the weakest started one, then the
    // easiest new one; the child's chosen domain comes first.
    candidates.sort((String a, String b) {
      int rank(String id) {
        int r = 0;
        if (c.chosenDomain != null && id.startsWith(c.chosenDomain!)) r -= 100;
        if (focusSkills.contains(id)) {
          r -= 50;
        } else if (focusSkills.length >= 2) {
          r += 50;
        }
        final SkillState? s = engine.state.skills[id];
        r += (s?.started ?? false) ? 0 : 10;
        r += engine.graph.depth(id);
        return r;
      }

      final int d = rank(a) - rank(b);
      if (d != 0) return d;
      final double pa = engine.state.skills[a]?.p ?? 0.2;
      final double pb = engine.state.skills[b]?.p ?? 0.2;
      final int byP = pa.compareTo(pb);
      return byP != 0 ? byP : a.compareTo(b);
    });
    for (final String id in candidates) {
      final ItemMeta? i = _itemFor(id, c, used, avoid: engine.avoidRepresentation(id), notSameAsLastOf: id);
      if (i != null) return ServeItem(i, Phase.focus, 'learn $id');
    }
    return null;
  }

  // ---- choosing an item for a skill ----

  /// The item for [skillId] whose chance of success is nearest the middle of the target band, in a
  /// representation chosen by the bandit (never [avoid]); not already used in this session unless nothing else is left.
  ItemMeta? _itemFor(
    String skillId,
    SessionContext c,
    Set<String> used, {
    Representation? avoid,
    String? differentVariantFrom,
    Set<String> preferNotIn = const <String>{},
    String? notSameAsLastOf,
  }) {
    List<ItemMeta> pool = <ItemMeta>[
      for (final ItemMeta i in catalog.itemsFor(skillId))
        if (i.purpose != Purpose.probe && !i.delight) i,
    ];
    if (pool.isEmpty) return null;
    final String? lastItem = notSameAsLastOf == null ? null : engine.state.skills[notSameAsLastOf]?.lastItem;
    List<ItemMeta> fresh = pool.where((ItemMeta i) => !used.contains(i.id) && i.id != lastItem).toList();
    if (fresh.isEmpty) fresh = pool.where((ItemMeta i) => i.id != lastItem).toList();
    if (fresh.isEmpty) fresh = pool;
    pool = fresh;
    if (differentVariantFrom != null) {
      final List<ItemMeta> other = pool
          .where((ItemMeta i) => i.variantGroup != differentVariantFrom)
          .toList();
      if (other.isNotEmpty) pool = other;
    }
    if (preferNotIn.isNotEmpty) {
      final List<ItemMeta> unseen = pool.where((ItemMeta i) => !preferNotIn.contains(i.id)).toList();
      if (unseen.isNotEmpty) pool = unseen;
    }
    final Set<Representation> reps = <Representation>{for (final ItemMeta i in pool) i.representation};
    final Representation rep = _chooser.choose(
      engine: engine,
      skillId: skillId,
      available: reps,
      avoid: avoid,
      band: c.band,
    );
    final List<ItemMeta> inRep = pool.where((ItemMeta i) => i.representation == rep).toList();
    return _nearestToTarget(inRep.isEmpty ? pool : inRep, skillId, c.band);
  }

  /// Elo-style choice: the item whose predicted chance of success is closest to the middle of the target band.
  ItemMeta _nearestToTarget(List<ItemMeta> pool, String skillId, int band) {
    final List<double> t = band == 0 ? params.targetBandA : params.targetBandBC;
    final double center = (t[0] + t[1]) / 2;
    final double p = engine.state.skills[skillId]?.p ?? params.priorNew;
    ItemMeta best = pool.first;
    double bestGap = double.infinity;
    for (final ItemMeta i in pool) {
      final double g = i.optionCount >= 2 ? 1.0 / i.optionCount : params.pGuessOpen;
      final double ps = g + (1 - g) / (1 + math.exp(-6 * (p - i.difficulty)));
      final double gap = (ps - center).abs();
      if (gap < bestGap - 1e-9 || (gap < bestGap + 1e-9 && i.id.compareTo(best.id) < 0)) {
        best = i;
        bestGap = gap;
      }
    }
    return best;
  }

  /// A probe item for [skillId]: a different one from what this session has served (so a confirming item
  /// is another item), the easiest first.
  ItemMeta? probeItem(String skillId, Set<String> used) {
    // Open items first (a right answer cannot be a guess, so one settles it), then the rest, in a fixed order.
    final List<ItemMeta> probes =
        <ItemMeta>[
          for (final ItemMeta i in catalog.itemsFor(skillId))
            if (i.purpose == Purpose.probe) i,
        ]..sort((ItemMeta a, ItemMeta b) {
          final int guessable = (a.optionCount == 0 ? 0 : 1).compareTo(b.optionCount == 0 ? 0 : 1);
          return guessable != 0 ? guessable : a.id.compareTo(b.id);
        });
    if (probes.isEmpty) return null;
    final List<ItemMeta> unused = probes.where((ItemMeta i) => !used.contains(i.id)).toList();
    return (unused.isEmpty ? probes : unused).first;
  }

  /// The easiest item in a skill the child is surest of (for the warm-up and the end).
  ItemMeta? _easiestWin(SessionContext c, {String? exceptSkill}) {
    final Set<String> used = <String>{for (final Served s in c.served) s.item.id};
    String? bestSkill;
    double bestP = -1;
    for (final MapEntry<String, SkillState> e in engine.state.skills.entries) {
      if (e.key == exceptSkill || !e.value.started) continue;
      if (engine.state.openGaps.any((Gap g) => g.skill == e.key)) continue;
      if (e.value.p > bestP) {
        bestP = e.value.p;
        bestSkill = e.key;
      }
    }
    if (bestSkill == null) {
      // A brand-new child: the easiest item of the shallowest skill.
      final List<String> roots =
          catalog.skills.keys.where((String id) => id != exceptSkill && engine.isUnlocked(id)).toList()
            ..sort((String a, String b) => engine.graph.depth(a).compareTo(engine.graph.depth(b)));
      for (final String id in roots) {
        final List<ItemMeta> pool = <ItemMeta>[
          for (final ItemMeta i in catalog.itemsFor(id))
            if (i.purpose != Purpose.probe && !i.delight && !used.contains(i.id)) i,
        ]..sort((ItemMeta a, ItemMeta b) => a.difficulty.compareTo(b.difficulty));
        if (pool.isNotEmpty) return pool.first;
      }
      return null;
    }
    final List<ItemMeta> pool = <ItemMeta>[
      for (final ItemMeta i in catalog.itemsFor(bestSkill))
        if (i.purpose != Purpose.probe && !i.delight) i,
    ]..sort((ItemMeta a, ItemMeta b) => a.difficulty.compareTo(b.difficulty));
    if (pool.isEmpty) return null;
    final ItemMeta? unused = pool.cast<ItemMeta?>().firstWhere(
      (ItemMeta? i) => !used.contains(i!.id),
      orElse: () => null,
    );
    return unused ?? pool.first;
  }

  /// The last item of a session: an easy one from a skill the child knows well (estimate 0.85 or more).
  ItemMeta? _easyEnd(SessionContext c) {
    final ItemMeta? i = _easiestWin(c);
    if (i == null) return null;
    final double p = engine.state.skills[i.primarySkill]?.p ?? 0;
    return p >= params.endOnSuccessAbove ? i : null;
  }
}
