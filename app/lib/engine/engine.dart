import 'dart:math' as math;

import 'graph.dart';
import 'mastery.dart';
import 'params.dart';
import 'retention.dart';
import 'state.dart';
import 'types.dart';

/// The learning engine of one child: it reads answers one by one and keeps what they mean. The state is
/// always the result of replaying the attempts, in order, through [apply]; nothing here reads a clock, a
/// database or a random number (the time of each answer comes with it).
class Engine {
  Engine({required this.catalog, this.params = const EngineParams()}) : graph = SkillGraph(catalog);

  final Catalog catalog;
  final SkillGraph graph;
  final EngineParams params;
  EngineState state = EngineState();
  final Set<String> _assumed = <String>{};

  static int dayKey(DateTime t) => t.toUtc().millisecondsSinceEpoch ~/ 86400000;

  /// Skills below the child's placement: taken as probably known (0.85) until shown otherwise.
  void assume(Iterable<String> skillIds) {
    for (final String id in skillIds) {
      if (!catalog.skills.containsKey(id)) continue;
      _assumed.add(id);
      final SkillState? s = state.skills[id];
      if (s != null && !s.started) {
        s.p = params.priorAssumed;
        s.assumed = true;
      }
    }
  }

  /// Starts over and replays [events] in the order they happened.
  EngineState replay(Iterable<AttemptEvent> events) {
    state = EngineState();
    final List<AttemptEvent> sorted = events.toList()
      ..sort((AttemptEvent a, AttemptEvent b) {
        final int c = a.at.compareTo(b.at);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    for (final AttemptEvent e in sorted) {
      apply(e);
    }
    return state;
  }

  SkillState skill(String id) =>
      state.skills[id] ??= SkillState(_assumed.contains(id) ? params.priorAssumed : params.priorNew)
        ..assumed = _assumed.contains(id);

  // ---- reading one answer ----

  void apply(AttemptEvent e) {
    final ItemMeta? item = catalog.items[e.activityId];
    if (item == null) return;
    state.lastEventAt = e.at;
    final bool probe = item.purpose == Purpose.probe;
    final int day = dayKey(e.at);
    // The probe this answer belongs to is decided on what was known before it (the answer itself changes the estimates).
    final GapSearch? open = state.search;
    final String? expectedProbe = (probe && open != null)
        ? (open.target ?? (open.probes >= params.probeMaxPerSearch ? null : _nextTarget(open)))
        : null;
    final int? sid = e.sessionId;
    if (sid != null) {
      (state.sessions[sid] ??= <SessionAnswer>[]).add(
        SessionAnswer(
          activityId: item.id,
          skillId: item.primarySkill,
          result: e.result,
          hintLevel: e.hintLevel,
        ),
      );
    }
    // Free play makes no demands: it is neither evidence of knowing nor of not knowing.
    if (item.delight) return;
    for (final MapEntry<String, double> w in item.skills.entries) {
      if (catalog.skills.containsKey(w.key)) _updateSkill(w.key, w.value, item, e, probe, day);
    }
    _updateTags(item, e);
    if (!probe) {
      final RepStats r = state.repStats(graph.node(_known(item)).family, item.representation);
      r.tries++;
      if (e.result == Result.correct && e.hintLevel <= 1) r.successes++;
    }
    _updateSearch(item, e, probe, expectedProbe);
    _updateGaps(item, e, probe);
  }

  String _known(ItemMeta item) =>
      item.skills.keys.firstWhere(catalog.skills.containsKey, orElse: () => item.skills.keys.first);

  void _updateSkill(String id, double w, ItemMeta item, AttemptEvent e, bool probe, int day) {
    final SkillState s = skill(id);
    final bool first = !s.started;
    final bool correct = e.result == Result.correct;
    s.p = Bkt.update(
      s.p,
      correct: correct,
      weight: Bkt.weightOf(
        result: e.result,
        hintLevel: e.hintLevel,
        skillWeight: w,
        optionCount: item.optionCount,
        params: params,
      ),
      optionCount: item.optionCount,
      params: params,
    );
    s.n++;
    if (correct) s.nCorrect++;
    if (e.result == Result.unsure) s.nUnsure++;
    if (first && e.sessionId != null) (state.newSkillsInSession[e.sessionId!] ??= <String>{}).add(id);

    // Reviews: the first answer of a skill on a day is a look at what the child remembers.
    if (!probe && s.lastReviewDay != day) {
      final bool good = correct && e.hintLevel <= 1;
      final SkillNode node = graph.node(id);
      s.memory = s.memory == null
          ? Retention.first(at: e.at, initialStability: node.initialStabilityDays, good: good)
          : Retention.review(s.memory!, at: e.at, good: good);
      s.lastReviewDay = day;
      final DateTime? fresh = s.freshAt;
      if (fresh != null) {
        if (good) {
          s.needsRevisit = false;
          final int days = e.at.difference(fresh).inHours ~/ 24;
          if (s.durableAt == null && days >= params.durableDays && !s.itemsAtFresh.contains(item.id)) {
            s.durableAt = e.at;
          }
        } else if (e.result == Result.incorrect) {
          s.needsRevisit = true;
        }
      }
    }

    if (correct && e.hintLevel == 0 && !probe) {
      s.successes++;
      s.successDays.add(day);
      s.successItems.add(item.id);
      s.representationsPassed.add(item.representation);
      if (item.checkType != CheckType.practice) s.checksPassed.add(item.checkType);
    }
    if (!probe) {
      if (correct) {
        s.failRun = 0;
        s.unsureRun = 0;
        s.runTags.clear();
      } else if (e.result == Result.incorrect) {
        s.failRun++;
        if (e.tag.isNotEmpty) s.runTags.add(e.tag);
      } else {
        s.unsureRun++;
      }
    }
    s.lastHintLevel = e.hintLevel;
    s.lastItem = item.id;
    s.lastVariantGroup = item.variantGroup;
    s.lastRepresentation = item.representation;
    if (e.result == Result.incorrect) s.lastFailedRepresentation = item.representation;
    s.lastAttemptAt = e.at;
    _checkFresh(id, s, e.at);
  }

  void _checkFresh(String id, SkillState s, DateTime at) {
    if (s.freshAt != null || s.p < params.masteryBar) return;
    final bool core = graph.isCore(id);
    final SkillNode node = graph.node(id);
    if (s.successes < (node.needSuccesses ?? (core ? params.freshSuccessesCore : params.freshSuccesses))) {
      return;
    }
    if (s.successDays.length < (node.needDays ?? params.freshDays)) return;
    final int needReps =
        node.needRepresentations ?? (core ? params.freshRepresentationsCore : params.freshRepresentations);
    if (s.representationsPassed.length < needReps) return;
    if (s.checksPassed.length < (node.needChecks ?? (core ? params.freshChecksCore : params.freshChecks))) {
      return;
    }
    s.freshAt = at;
    s.itemsAtFresh = Set<String>.of(s.successItems);
  }

  void _updateTags(ItemMeta item, AttemptEvent e) {
    if (e.tag.isNotEmpty && e.result == Result.incorrect) {
      final TagState t = state.tags[e.tag] ??= TagState();
      if (t.status == TagStatus.resolved) {
        t.status = TagStatus.suspected;
        t.score = 0;
        t.items.clear();
      }
      t.score = params.evidenceDecay * t.score + 1.0;
      t.items.add(item.id);
      t.cleanRuns = 0;
      t.lastSeen = e.at;
      if (t.score >= params.activeScore && t.items.length >= params.activeItems) t.status = TagStatus.active;
    }
    if (e.result != Result.correct) return;
    for (final String tag in item.tags) {
      final TagState? t = state.tags[tag];
      if (t == null) continue;
      t.score *= params.evidenceDecay;
      final bool diagnostic = item.purpose == Purpose.probe || item.contradicts == tag;
      if (diagnostic) {
        t.cleanRuns++;
        if (t.cleanRuns >= params.resolveAfter && t.status != TagStatus.resolved) {
          t.status = TagStatus.resolved;
        }
      }
    }
  }

  // ---- the search for a gap ----

  void _updateSearch(ItemMeta item, AttemptEvent e, bool probe, String? expectedProbe) {
    final GapSearch? s = state.search;
    if (probe) {
      if (s != null) _probeAnswered(s, item, e, expectedProbe);
      return;
    }
    if (s != null || e.result == Result.correct) return;
    final String id = _known(item);
    if (!catalog.skills.containsKey(id)) return;
    final SkillState st = skill(id);
    if (graph.node(id).prerequisites.isEmpty) return;
    if (state.gaps.any((Gap g) => !g.repaired && (g.origin == id || g.skill == id))) return;
    final bool tagActive = state.tags.entries.any(
      (MapEntry<String, TagState> t) =>
          t.value.status == TagStatus.active &&
          ((catalog.tags[t.key]?.skills.contains(id) ?? false) || graph.node(id).tags.contains(t.key)),
    );
    final bool steppedBack = st.n >= params.stepBackAfter && st.p < params.stepBackBelow;
    if (st.failRun >= params.failTrigger ||
        st.unsureRun >= params.unsureTrigger ||
        tagActive ||
        steppedBack) {
      final Set<String> below = graph.ancestors(id);
      final List<String> trace = <String>[];
      for (final String tag in <String>[...st.runTags.reversed, if (e.tag.isNotEmpty) e.tag]) {
        for (final String sk in catalog.tags[tag]?.skills ?? const <String>[]) {
          if (below.contains(sk) && !trace.contains(sk)) trace.add(sk);
        }
      }
      final GapSearch started = GapSearch(origin: id, startedAt: e.at, traceSkills: trace);
      state.search = started;
      _advance(started, e.at);
    }
  }

  /// The skill the child should be probed on next, or null when no search is open or it needs no more probes.
  String? nextProbe() {
    final GapSearch? s = state.search;
    if (s == null) return null;
    if (s.target != null) return s.target;
    if (s.probes >= params.probeMaxPerSearch || s.path.length - 1 >= params.probeMaxDepth) return null;
    return _nextTarget(s);
  }

  /// True when the probe of the search's current target has had its first item right and needs a second.
  bool get probeNeedsConfirmation => (state.search?.correctRun ?? 0) + (state.search?.wrongRun ?? 0) > 0;

  /// How many right answers a probe needs: enough that guessing alone would pass it less than
  /// `probeGuessPassMax` of the time (one for an open task, three or four for three choices).
  int probeRightsToPass(int optionCount) {
    if (optionCount < 2) return 1;
    final double g = 1.0 / optionCount;
    return (math.log(params.probeGuessPassMax) / math.log(g)).ceil().clamp(1, params.probeRightsCap);
  }

  String? _nextTarget(GapSearch s) {
    final String cur = s.path.last;
    // Everything the child has shown it can do, and everything below that, needs no probe.
    final Set<String> demonstrated = <String>{};
    state.skills.forEach((String id, SkillState st) {
      if (st.p >= params.skipProbeAbove &&
          st.nCorrect >= 2 &&
          st.successes >= 1 &&
          catalog.skills.containsKey(id)) {
        demonstrated
          ..add(id)
          ..addAll(graph.ancestors(id));
      }
    });
    // The skills a probe may name: below the current one, up to `probeReach` levels down, each with the
    // strength of the chain of prerequisites that leads to it.
    final Map<String, double> reach = <String, double>{};
    void walk(String id, double w, int d) {
      if (d >= params.probeReach) return;
      graph.node(id).prerequisites.forEach((String p, double wt) {
        final double nw = w * wt;
        if (nw > (reach[p] ?? 0)) reach[p] = nw;
        walk(p, nw, d + 1);
      });
    }

    walk(cur, 1.0, 0);
    final Set<String> below = graph.ancestors(cur);
    for (final String t in s.traceSkills) {
      if (below.contains(t)) reach.putIfAbsent(t, () => 0.5);
    }
    // Score every candidate: how weak it looks, along how strong a chain of prerequisites.
    final Map<String, double> scores = <String, double>{};
    for (final MapEntry<String, double> c in reach.entries) {
      if (s.cleared.contains(c.key) ||
          s.failed.contains(c.key) ||
          c.key == cur ||
          demonstrated.contains(c.key)) {
        continue;
      }
      final SkillState? st = state.skills[c.key];
      double score = (0.5 + 0.5 * c.value) * (1 - (st?.p ?? _prior(c.key)));
      final int ti = s.traceSkills.indexOf(c.key);
      if (ti >= 0) score += 5 - ti * 0.1;
      if (st != null && st.freshAt != null && st.memory != null) {
        final double r = Retention.retrievability(
          (state.lastEventAt ?? st.memory!.lastReview).difference(st.memory!.lastReview).inMinutes / 1440.0,
          st.memory!.stability,
        );
        if (r < params.revisitBelow) score += 0.3;
      }
      scores[c.key] = score;
    }
    if (scores.isEmpty) return null;
    final double top = scores.values.reduce(math.max);
    // Among the nearly-as-suspicious, probe the one that settles most: a pass clears everything below it.
    String? best;
    int bestReach = -1;
    for (final MapEntry<String, double> c in scores.entries) {
      if (c.value < top * params.probeNearTop) continue;
      final int clears = graph.ancestors(c.key).where(scores.containsKey).length;
      if (bestReach < 0 ||
          clears < bestReach ||
          (clears == bestReach && best != null && c.key.compareTo(best) < 0)) {
        best = c.key;
        bestReach = clears;
      }
    }
    return best;
  }

  double _prior(String id) => _assumed.contains(id) ? params.priorAssumed : params.priorNew;

  void _probeAnswered(GapSearch s, ItemMeta item, AttemptEvent e, String? expected) {
    if (expected == null || item.primarySkill != expected) return;
    s.target = expected;
    if (e.result == Result.correct) {
      s.correctRun++;
      if (s.correctRun < probeRightsToPass(item.optionCount)) return;
      _probeDone(s, passed: true, at: e.at, sessionId: e.sessionId);
    } else {
      // A wrong answer in an item that is easy to guess is a slip as often as not: two are needed to fail,
      // unless a right answer alone would have passed (open tasks).
      s.wrongRun++;
      final int needed = probeRightsToPass(item.optionCount) == 1 ? 1 : params.probeWrongsToFail;
      if (s.wrongRun < needed) return;
      _probeDone(s, passed: false, at: e.at, sessionId: e.sessionId);
    }
  }

  void _probeDone(GapSearch s, {required bool passed, required DateTime at, int? sessionId}) {
    final String target = s.target!;
    s.probes++;
    if (sessionId != null) state.probesInSession[sessionId] = (state.probesInSession[sessionId] ?? 0) + 1;
    s.target = null;
    s.correctRun = 0;
    s.wrongRun = 0;
    if (passed) {
      s.cleared.add(target);
      if (params.passClearsPrerequisites) s.cleared.addAll(graph.ancestors(target));
    } else {
      s.failed.add(target);
      if (!s.path.contains(target)) s.path.add(target);
    }
    _advance(s, at);
  }

  /// Goes on with the search if there is something left to probe within the budget; otherwise ends it.
  void _advance(GapSearch s, DateTime at) {
    final bool budgetLeft = s.probes < params.probeMaxPerSearch && s.path.length - 1 < params.probeMaxDepth;
    final String? next = budgetLeft ? _nextTarget(s) : null;
    if (next != null) return;
    // The search ends here.
    final SkillState origin = skill(s.origin);
    if (s.failed.isNotEmpty) {
      state.gaps.add(
        Gap(
          origin: s.origin,
          skill: s.path.last,
          foundAt: at,
          probes: s.probes,
          via: budgetLeft ? 'walk' : 'budget',
        ),
      );
    } else {
      // Nothing below is missing (or the probes ran out with every one passed): the child simply is still
      // learning this skill, or slipped. No gap is recorded, and the skill goes on as normal practice.
      state.closedSearches.add(s.origin);
    }
    origin.failRun = 0;
    origin.unsureRun = 0;
    origin.runTags.clear();
    state.search = null;
  }

  void _updateGaps(ItemMeta item, AttemptEvent e, bool probe) {
    if (probe) return;
    for (final Gap g in state.gaps) {
      if (g.repaired || !item.skills.containsKey(g.skill)) continue;
      if (e.result == Result.correct && e.hintLevel <= 1) {
        g.repairSuccesses++;
        if (g.repairSuccesses >= params.repairSuccesses) g.repairedAt = e.at;
      } else if (e.result == Result.incorrect) {
        g.repairSuccesses = 0;
      }
    }
  }

  // ---- questions the rest of the app asks ----

  /// True when every prerequisite of [id] has reached the unlock bar (or there are none).
  bool isUnlocked(String id) {
    for (final String p in graph.node(id).prerequisites.keys) {
      if ((state.skills[p]?.p ?? _prior(p)) < params.unlockBar) return false;
    }
    return true;
  }

  double retrievability(String id, DateTime now) {
    final MemoryState? m = state.skills[id]?.memory;
    if (m == null) return 1;
    return Retention.retrievability(now.difference(m.lastReview).inMinutes / 1440.0, m.stability);
  }

  /// When the next check of a skill with fresh mastery falls due, or null.
  DateTime? nextCheckAt(String id) {
    final SkillState? s = state.skills[id];
    final MemoryState? m = s?.memory;
    if (s == null || m == null || s.freshAt == null) return null;
    final double target = graph.node(id).targetRetention ?? params.targetRetention;
    final double days = Retention.intervalDays(m.stability, target, params);
    return m.lastReview.add(Duration(minutes: (days * 1440).round()));
  }

  /// Skills with fresh mastery whose check is due now (earliest first), plus skills that need a revisit.
  List<String> dueChecks(DateTime now) {
    final List<MapEntry<String, DateTime>> due = <MapEntry<String, DateTime>>[];
    for (final String id in state.skills.keys) {
      final SkillState s = state.skills[id]!;
      if (s.freshAt == null) continue;
      final DateTime? at = nextCheckAt(id);
      if (s.needsRevisit || (at != null && !now.isBefore(at))) {
        due.add(MapEntry<String, DateTime>(id, at ?? now));
      }
    }
    due.sort((MapEntry<String, DateTime> a, MapEntry<String, DateTime> b) => a.value.compareTo(b.value));
    return <String>[for (final MapEntry<String, DateTime> d in due) d.key];
  }

  SkillStatus statusOf(String id, DateTime now) {
    final SkillState? s = state.skills[id];
    if (state.gaps.any((Gap g) => !g.repaired && g.skill == id)) return SkillStatus.gap;
    if (s == null || !s.started) return isUnlocked(id) ? SkillStatus.ready : SkillStatus.notStarted;
    if (s.freshAt != null) {
      if (s.needsRevisit || retrievability(id, now) < params.revisitBelow) return SkillStatus.needsRevisit;
      return s.durableAt != null ? SkillStatus.durableMastery : SkillStatus.freshMastery;
    }
    return SkillStatus.learning;
  }

  /// The representation to move away from for [id]: after two wrong answers in a row, or a worked example.
  Representation? avoidRepresentation(String id) {
    final SkillState? s = state.skills[id];
    if (s == null) return null;
    if (s.failRun >= params.switchAfterErrors || s.lastHintLevel >= 3) return s.lastRepresentation;
    return null;
  }

  /// The child is stuck in this session: several wrong answers in a row on one skill, or worked examples in a row.
  bool isStuck(int sessionId) {
    final List<SessionAnswer> a = state.sessions[sessionId] ?? const <SessionAnswer>[];
    if (a.length >= params.stuckErrors) {
      final List<SessionAnswer> last = a.sublist(a.length - params.stuckErrors);
      if (last.every((SessionAnswer x) => x.result == Result.incorrect && x.skillId == last.first.skillId)) {
        return true;
      }
    }
    if (a.length >= params.stuckWorkedExamples) {
      final List<SessionAnswer> last = a.sublist(a.length - params.stuckWorkedExamples);
      if (last.every((SessionAnswer x) => x.hintLevel >= 3)) return true;
    }
    return false;
  }
}
