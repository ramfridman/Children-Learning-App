import 'dart:math' as math;

import 'graph.dart';
import 'mastery.dart';
import 'params.dart';
import 'retention.dart';
import 'rollup.dart';
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
    // Evidence never crosses courses, even when two packs use the same activity id.
    if (e.course != null && e.course != item.course) return;
    final bool probe = item.purpose == Purpose.probe;
    final int day = dayKey(e.at);
    // A word of a speaking skill's practice set was met, whatever becomes of the answer (frame section 3.3.8).
    if (!probe && !item.delight) _meetWords(item);
    // The probe this answer belongs to is decided on what was known before it (the answer itself changes the estimates).
    final GapSearch? open = state.search;
    final String? expectedProbe = (probe && open != null)
        ? (open.target ?? (open.probes >= params.probeMaxPerSearch ? null : _nextTarget(open)))
        : null;
    // A spoken answer counts only where the rules of speech say (see [_speechCounts]); if it counts for no skill it changes
    // nothing at all: not the session's record, not the statistics of the item, not a gap. That is decided first.
    final Set<String>? spoken = e.viaSpeech
        ? <String>{
            for (final String id in item.skills.keys)
              if (catalog.skills.containsKey(id) && _speechCounts(id, state.skills[id], e, probe)) id,
          }
        : null;
    if (spoken != null && spoken.isEmpty) return;
    state.lastEventAt = e.at;
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
    bool evidence = false;
    for (final MapEntry<String, double> w in item.skills.entries) {
      if (!catalog.skills.containsKey(w.key) || (spoken != null && !spoken.contains(w.key))) continue;
      if (_isPractice(w.key, item)) {
        _practise(w.key, item, e, probe);
      } else {
        evidence = true;
        _updateSkill(w.key, w.value, item, e, probe, day);
      }
    }
    // Practice is no evidence of anything: with the path in view a miss is motor control, not a misconception, so the tags, the
    // statistics of the way of explaining, the search for a gap and the repair of one never hear of it.
    if (!evidence) return;
    final int eff = _effectiveHint(item, e);
    _updateTags(item, e);
    if (!probe) {
      final RepStats r = state.repStats(graph.node(_known(item)).family, item.representation);
      r.tries++;
      if (e.result == Result.correct && eff <= 1) r.successes++;
    }
    _updateSearch(item, e, probe, expectedProbe);
    _updateGaps(item, e, probe, eff);
  }

  // ---- writing (rule E-1) ----

  /// Decided first, before any evidence (writing-mastery section 4.2): tracing, and every answer in a trace node, is practice. The
  /// other two classes are told apart by [_effectiveHint]: a copy is read as an answer with one more hint, a memory answer as given.
  bool _isPractice(String skillId, ItemMeta item) =>
      graph.node(skillId).writing == WritingRule.practised ||
      item.writingMode == WritingMode.trace ||
      item.practiceOnly;

  /// The hint level the rules read: what was shown, and for a copy one more (the model was in view).
  int _effectiveHint(ItemMeta item, AttemptEvent e) =>
      item.writingMode == WritingMode.copy ? math.min(e.hintLevel + 1, 3) : e.hintLevel;

  /// A practice answer: counted, and when it is a right trace with the start dot only (level 0 or 1) its letter is practised.
  void _practise(String id, ItemMeta item, AttemptEvent e, bool probe) {
    final SkillState s = skill(id);
    final bool first = !s.started;
    s.practiceCount++;
    if (first && e.sessionId != null) (state.newSkillsInSession[e.sessionId!] ??= <String>{}).add(id);
    if (e.result == Result.correct &&
        e.hintLevel <= 1 &&
        !probe &&
        item.startGuide &&
        item.variantGroup.isNotEmpty) {
      s.practisedGroups.add(item.variantGroup);
    }
  }

  void _meetWords(ItemMeta item) {
    if (item.variantGroup.isEmpty) return;
    for (final String id in item.skills.keys) {
      if (catalog.skills.containsKey(id) && graph.node(id).speaking) {
        (state.metWords[id] ??= <String>{}).add(item.variantGroup);
      }
    }
  }

  bool _practised(String id) {
    final Set<String> letters = catalog.practiceGroupsOf(id);
    final Set<String> done = state.skills[id]?.practisedGroups ?? const <String>{};
    return letters.isNotEmpty && letters.every(done.contains);
  }

  bool _practiceSetDone(String id) {
    final Set<String> words = catalog.variantGroupsOf(id);
    final Set<String> met = state.metWords[id] ?? const <String>{};
    return words.isNotEmpty && words.every(met.contains);
  }

  String _known(ItemMeta item) =>
      item.skills.keys.firstWhere(catalog.skills.containsKey, orElse: () => item.skills.keys.first);

  void _updateSkill(String id, double w, ItemMeta item, AttemptEvent e, bool probe, int day) {
    final SkillState s = skill(id);
    final bool first = !s.started;
    final bool correct = e.result == Result.correct;
    // A copy is read as an answer with one more hint (writing-mastery section 4.3); every other answer as it was given.
    final int eff = _effectiveHint(item, e);
    final bool copy = item.writingMode == WritingMode.copy;
    s.p = Bkt.update(
      s.p,
      correct: correct,
      weight: Bkt.weightOf(
        result: e.result,
        hintLevel: eff,
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

    // Reviews: the first answer of a skill on a day is a look at what the child remembers. A copy is not one: the model is in view.
    if (!probe && !copy && s.lastReviewDay != day) {
      final bool good = correct && eff <= 1;
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

    if (correct && eff == 0 && !probe) {
      s.successes++;
      if (e.viaSpeech) s.speechSuccesses++;
      s.successDays.add(day);
      s.successItems.add(item.id);
      if (item.variantGroup.isNotEmpty) s.successGroups.add(item.variantGroup);
      s.representationsPassed.add(item.representation);
      if (item.checkType != CheckType.practice) s.checksPassed.add(item.checkType);
      if (item.writingMode == WritingMode.memory) {
        s.memorySuccessDays.add(day);
        if (item.cue != null) s.memoryCues.add(item.cue!);
        if (item.variantGroup.isNotEmpty) s.memoryGroups.add(item.variantGroup);
      }
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

  /// Whether a spoken answer counts for skill [id] (docs/languages/frame.md section 5.1): only a success counts, only for a speaking
  /// skill, only without a hint and outside a probe (a heard word after help, or in a search for a gap, is not the evidence the
  /// cap is written for), and only while speech stays at most half of the skill's successes. A spoken answer that does not count
  /// changes nothing at all: not the estimate, not the number of answers, not a run, not a review, not a gap, not the statistics
  /// of a way of explaining. Every spoken answer that is applied counts toward the cap, because each one is a success without a
  /// hint (`speechSuccesses`).
  bool _speechCounts(String id, SkillState? s, AttemptEvent e, bool probe) {
    if (e.result != Result.correct || e.hintLevel != 0 || probe || !graph.node(id).speaking) return false;
    final int others = s == null ? 0 : s.successes - s.speechSuccesses;
    return (s?.speechSuccesses ?? 0) + 1 <= others;
  }

  void _checkFresh(String id, SkillState s, DateTime at) {
    if (s.freshAt != null || s.p < params.masteryBar) return;
    final bool core = graph.isCore(id);
    final SkillNode node = graph.node(id);
    if (node.writing == WritingRule.practised) return; // a trace node is practised, never mastered
    if (s.successes < (node.needSuccesses ?? (core ? params.freshSuccessesCore : params.freshSuccesses))) {
      return;
    }
    final int needDays = node.needDays ?? params.freshDays;
    if (s.successDays.length < needDays) return;
    final bool memoryWriting = node.writing == WritingRule.memory;
    if (memoryWriting) {
      // The cue condition replaces the representations (writing-mastery section 5): the sound and the name are the two ways of
      // knowing a letter, and the memory successes must come on two days.
      if (s.memorySuccessDays.length < math.max(2, needDays)) return;
      if (!s.memoryCues.containsAll(WritingCue.values)) return;
    } else {
      final int needReps =
          node.needRepresentations ?? (core ? params.freshRepresentationsCore : params.freshRepresentations);
      if (s.representationsPassed.length < needReps) return;
    }
    if (s.checksPassed.length < (node.needChecks ?? (core ? params.freshChecksCore : params.freshChecks))) {
      return;
    }
    // A set of words (or the letters of a group) is known when every one of them was answered right once, not when half of
    // them were answered right often (docs/languages/frame.md section 3.3.4).
    if (node.setCoverage && !catalog.variantGroupsOf(id).every(s.successGroups.contains)) return;
    if (memoryWriting && node.setCoverage && !catalog.memoryGroupsOf(id).every(s.memoryGroups.contains)) {
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
      // A trace node is never probed: how well a child traces says nothing about what the child knows (writing-mastery section 6.4).
      if (s.cleared.contains(c.key) ||
          s.failed.contains(c.key) ||
          c.key == cur ||
          demonstrated.contains(c.key) ||
          graph.node(c.key).writing == WritingRule.practised) {
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
      // unless a right answer alone would have passed (open tasks). A letter written freely is the exception: mirrors and look-alikes
      // are normal at five and six, and one stroke can stray, so a writing probe fails only on its second wrong answer.
      s.wrongRun++;
      final int needed = item.writingMode != null || probeRightsToPass(item.optionCount) != 1
          ? params.probeWrongsToFail
          : 1;
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

  void _updateGaps(ItemMeta item, AttemptEvent e, bool probe, int eff) {
    if (probe) return;
    for (final Gap g in state.gaps) {
      if (g.repaired || !item.skills.containsKey(g.skill)) continue;
      if (e.result == Result.correct && eff <= 1) {
        g.repairSuccesses++;
        if (g.repairSuccesses >= params.repairSuccesses) g.repairedAt = e.at;
      } else if (e.result == Result.incorrect) {
        g.repairSuccesses = 0;
      }
    }
  }

  // ---- questions the rest of the app asks ----

  /// True when every prerequisite of [id] has reached the unlock bar (or there are none). The facets of a letter bundle unlock
  /// as one: when the prerequisites of all of them have reached it. They never require each other. A prerequisite in
  /// [taughtWith] is taken as met: the skills that one lesson teaches together do not wait for each other (the path gate asks
  /// this way for the skills of a lesson).
  bool isUnlocked(String id, [Set<String> taughtWith = const <String>{}]) {
    final String? bundle = graph.node(id).bundle;
    final List<String> members = bundle == null ? <String>[id] : catalog.bundles[bundle]!;
    for (final String m in members) {
      for (final String p in graph.node(m).prerequisites.keys) {
        if (members.contains(p) || taughtWith.contains(p)) continue;
        if (!isMet(p)) return false;
      }
    }
    return true;
  }

  /// Whether the skill [id] counts as a met prerequisite, the one hook behind [isUnlocked]. A trace node (E-1) is met once
  /// every letter of it was traced with the start dot only, or when placement assumed it; a speaking skill, whose mastery depends on
  /// the microphone the parent chose, is met once its practice set is done (frame section 3.3.8). Neither can hold a child back.
  /// Any other skill is met at the unlock bar.
  bool isMet(String id) {
    final SkillNode node = graph.node(id);
    if (node.writing == WritingRule.practised) return _assumed.contains(id) || _practised(id);
    if ((state.skills[id]?.p ?? _prior(id)) >= params.unlockBar) return true;
    return node.speaking && _practiceSetDone(id);
  }

  /// The variant groups (words, or letters) of a set skill that have not been answered right without a hint yet; empty for a
  /// skill that is not a set. The session builder rotates its items through these until the set is covered.
  Set<String> uncoveredGroups(String id) {
    final SkillNode node = graph.node(id);
    // A trace node rotates its items through the letters not practised yet; a writing node through the ones with no memory success.
    if (node.writing == WritingRule.practised) {
      return catalog.practiceGroupsOf(id).difference(state.skills[id]?.practisedGroups ?? const <String>{});
    }
    if (!node.setCoverage) return const <String>{};
    if (node.writing == WritingRule.memory) {
      return catalog.memoryGroupsOf(id).difference(state.skills[id]?.memoryGroups ?? const <String>{});
    }
    final Set<String> done = state.skills[id]?.successGroups ?? const <String>{};
    return catalog.variantGroupsOf(id).difference(done);
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
    final List<String>? groups = catalog.subSkills[id];
    if (groups != null) return rollUpStatus(<SkillStatus>[for (final String g in groups) statusOf(g, now)]);
    final SkillState? s = state.skills[id];
    if (graph.node(id).writing == WritingRule.practised) {
      // Never mastered, never a gap: practised, or on the way to it.
      if (isMet(id)) return SkillStatus.practised;
      if (s == null || !s.started) return isUnlocked(id) ? SkillStatus.ready : SkillStatus.notStarted;
      return SkillStatus.learning;
    }
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
