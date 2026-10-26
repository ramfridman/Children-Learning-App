import 'dart:math' as math;

import 'engine.dart';
import 'params.dart';
import 'session_builder.dart';
import 'state.dart';
import 'types.dart';

String _simId(int i) => 'SM-${String.fromCharCode(65 + i ~/ 10)}-${(i % 10).toString().padLeft(2, '0')}';

/// An invented skill graph with items, for trying the engine on thousands of cases. Skills are numbered in
/// a valid order; each needs up to three earlier ones. Each skill has four practice items in different
/// representations (the first, a three-option item, can show the skill's misconception tag), two probe items,
/// one open item that checks the reverse, and an open probe (nothing to guess).
class SimWorld {
  SimWorld._(this.catalog, this.order);

  factory SimWorld.random(
    math.Random rnd, {
    int skills = 20,
    int maxPrerequisites = 3,
    bool delight = false,
  }) {
    final List<SkillNode> nodes = <SkillNode>[];
    final List<ItemMeta> items = <ItemMeta>[];
    final List<TagInfo> tags = <TagInfo>[];
    final List<String> order = <String>[];
    for (int i = 0; i < skills; i++) {
      final String id = _simId(i);
      final Map<String, double> pre = <String, double>{};
      if (i > 0) {
        final int wanted = math.min(i, rnd.nextInt(maxPrerequisites) + (rnd.nextDouble() < 0.7 ? 1 : 0));
        // Prefer recent skills so that the graph has depth.
        int tries = 0;
        while (pre.length < wanted && tries++ < 50) {
          final int back = 1 + (rnd.nextDouble() * rnd.nextDouble() * math.min(i, 8)).floor();
          pre[_simId(i - back)] = 0.4 + rnd.nextDouble() * 0.6;
        }
      }
      order.add(id);
      nodes.add(
        SkillNode(
          id: id,
          prerequisites: pre,
          representations: <Representation>{
            Representation.concrete,
            Representation.pictorial,
            Representation.story,
            Representation.symbolic,
          },
          tags: <String>{'M-$id'},
        ),
      );
      String strongest = id;
      double w = -1;
      pre.forEach((String k, double v) {
        if (v > w) {
          w = v;
          strongest = k;
        }
      });
      tags.add(TagInfo(id: 'M-$id', skills: <String>[strongest]));
      final Map<String, double> sk = <String, double>{id: 1};
      const List<Representation> reps = <Representation>[
        Representation.concrete,
        Representation.pictorial,
        Representation.story,
        Representation.symbolic,
      ];
      for (int k = 0; k < 4; k++) {
        items.add(
          ItemMeta(
            id: '$id.${k + 1}',
            skills: sk,
            representation: reps[k],
            variantGroup: '$id-g${k + 1}',
            difficulty: 0.25 + 0.15 * k,
            optionCount: 3,
            tags: k == 0 ? <String>{'M-$id'} : const <String>{},
          ),
        );
      }
      items.add(
        ItemMeta(
          id: '$id.o',
          skills: sk,
          representation: Representation.symbolic,
          checkType: CheckType.reverse,
          variantGroup: '$id-o',
          difficulty: 0.7,
        ),
      );
      for (int k = 1; k <= 2; k++) {
        items.add(
          ItemMeta(
            id: '$id.p$k',
            skills: sk,
            purpose: Purpose.probe,
            representation: reps[k - 1],
            variantGroup: '$id-p',
            difficulty: 0.3,
            optionCount: 3,
            tags: <String>{'M-$id'},
          ),
        );
      }
      // An open probe (give, drag, trace): nothing to guess, so one right answer settles it.
      items.add(
        ItemMeta(
          id: '$id.p3',
          skills: sk,
          purpose: Purpose.probe,
          representation: Representation.symbolic,
          variantGroup: '$id-p',
          difficulty: 0.35,
          tags: <String>{'M-$id'},
        ),
      );
      if (delight && i % 5 == 0) {
        items.add(
          ItemMeta(
            id: '$id.fun',
            skills: sk,
            delight: true,
            representation: Representation.embodied,
            optionCount: 0,
          ),
        );
      }
    }
    return SimWorld._(Catalog(skills: nodes, items: items, tags: tags), order);
  }

  final Catalog catalog;

  /// Skill ids from the first to the last in a valid order.
  final List<String> order;
}

/// An invented child. It knows some skills and not others; it slips now and then, guesses when it does not know,
/// and when it is wrong in an item that can show a misconception it often chooses that wrong answer.
class SimChild {
  SimChild({
    required this.catalog,
    required Set<String> known,
    required this.random,
    this.slip = 0.05,
    this.pTag = 0.7,
    this.pUnsure = 0.08,
    this.pLearn = 0.2,
  }) : known = Set<String>.of(known);

  final Catalog catalog;
  final Set<String> known;
  final math.Random random;
  final double slip;
  final double pTag;
  final double pUnsure;

  /// Chance of picking a skill up from one attempt when all its prerequisites are known.
  final double pLearn;

  (Result, String) answer(ItemMeta item) {
    final String skill = item.primarySkill;
    final bool knows = known.contains(skill);
    if (knows) {
      return random.nextDouble() < slip ? (Result.incorrect, _tag(item)) : (Result.correct, '');
    }
    final bool prerequisitesKnown = catalog.skills[skill]!.prerequisites.keys.every(known.contains);
    if (prerequisitesKnown && random.nextDouble() < pLearn) known.add(skill);
    final double guess = item.optionCount >= 2 ? 1.0 / item.optionCount : 0.02;
    if (random.nextDouble() < pUnsure) return (Result.unsure, '');
    if (random.nextDouble() < guess) return (Result.correct, '');
    return (Result.incorrect, _tag(item));
  }

  String _tag(ItemMeta item) {
    if (item.tags.isEmpty || random.nextDouble() > pTag) return '';
    return item.tags.first;
  }
}

/// What one gap trial found.
class GapTrial {
  const GapTrial({
    required this.planted,
    required this.found,
    required this.probes,
    required this.items,
    required this.triggered,
    this.known = const <String>{},
  });

  final Set<String> planted;

  /// The skills the child really knows.
  final Set<String> known;

  /// The gap record the engine made, or null.
  final Gap? found;
  final int probes;

  /// Items the child answered from the first to the end of the search.
  final int items;

  /// Whether the child's failures started a search at all.
  final bool triggered;

  bool get exact => found != null && planted.contains(found!.skill);
  bool get within3 => exact && found!.probes <= 3;
}

/// Plays one invented child with planted gaps against the real engine and session builder.
///
/// The child has practised [coverage] of the skills it knows (so the engine has seen it succeed there), then
/// fails a skill that depends on a planted gap. Returns what the engine concluded.
GapTrial runGapTrial({
  required SimWorld world,
  required math.Random random,
  int gaps = 1,
  double coverage = 0.5,
  EngineParams params = const EngineParams(),
  double tagAccuracy = 1.0,
}) {
  final Catalog catalog = world.catalog;
  final Engine engine = Engine(catalog: catalog, params: params);
  final List<String> order = world.order;

  // Pick the planted gaps: skills that something depends on, none below another. The child fails a skill
  // that is one to three levels above a planted gap (the depth the diagnostic walk covers).
  final Set<String> planted = <String>{};
  final Map<String, Set<String>> below = <String, Set<String>>{
    for (final String id in order) id: engine.graph.ancestors(id),
  };
  final List<String> withDependants = <String>[
    for (final String id in order)
      if (engine.graph.dependantsOf(id).isNotEmpty) id,
  ];
  if (withDependants.isEmpty) {
    return const GapTrial(planted: <String>{}, found: null, probes: 0, items: 0, triggered: false);
  }
  int guard = 0;
  while (planted.length < gaps && guard++ < 30) {
    final String g = withDependants[random.nextInt(withDependants.length)];
    if (planted.any((String p) => below[p]!.contains(g) || below[g]!.contains(p))) continue;
    planted.add(g);
  }
  final String firstGap = planted.first;
  // Distance from a skill down to the gap, by the shortest path.
  int distance(String from, String to) {
    int best = 1 << 20;
    void walk(String s, int d) {
      if (s == to) {
        if (d < best) best = d;
        return;
      }
      for (final String p in engine.graph.node(s).prerequisites.keys) {
        walk(p, d + 1);
      }
    }

    walk(from, 0);
    return best;
  }

  final List<String> origins = <String>[
    for (final String id in order)
      if (below[id]!.contains(firstGap) && distance(id, firstGap) <= 3) id,
  ];
  if (origins.isEmpty) return GapTrial(planted: planted, found: null, probes: 0, items: 0, triggered: false);
  final String origin = origins[random.nextInt(origins.length)];

  // The child knows a skill when neither it nor anything below it is planted.
  final Set<String> known = <String>{
    for (final String id in order)
      if (!planted.contains(id) && !below[id]!.any(planted.contains)) id,
  };
  final SimChild child = SimChild(catalog: catalog, known: known, random: random, pLearn: 0);

  // What the engine knew before today. Skills below the child's level were assumed (0.85). On a share of all
  // skills ([coverage]) there is real history: where the child knows the skill it did well (0.97), where it
  // does not it did badly (0.35), which is what makes the weakest prerequisite stand out.
  engine.assume(order);
  for (final String s in order) {
    if (random.nextDouble() > coverage) continue;
    final SkillState st = engine.skill(s);
    st.n = 3;
    if (known.contains(s)) {
      st.p = 0.97;
      st.nCorrect = 3;
      st.successes = 3;
    } else {
      st.p = 0.35;
      st.nCorrect = 1;
    }
  }
  DateTime at = DateTime.utc(2026, 11, 1, 9);
  int id = 0;
  at = at.add(const Duration(days: 1));

  // The child works on the origin and fails; the builder then probes.
  final SessionBuilder builder = SessionBuilder(engine: engine, random: random);
  final List<Served> served = <Served>[];
  final List<ItemMeta> originItems = <ItemMeta>[
    for (final ItemMeta i in catalog.itemsFor(origin))
      if (i.purpose != Purpose.probe) i,
  ];
  int steps = 0;
  int answered = 0;
  bool triggered = false;
  while (steps++ < 40) {
    ItemMeta item;
    if (engine.state.search != null) {
      triggered = true;
      final Pick pick = builder.next(SessionContext(sessionId: 2, band: 0, now: at, served: served));
      if (pick is! ServeItem) break;
      item = pick.item;
    } else if (triggered) {
      break;
    } else {
      item = originItems[answered % originItems.length];
    }
    final (Result r, String tag) = child.answer(item);
    answered++;
    engine.apply(AttemptEvent(id: ++id, at: at, activityId: item.id, result: r, tag: tag, sessionId: 2));
    served.add(Served(item, triggered ? Phase.repair : Phase.focus, r));
    at = at.add(const Duration(seconds: 40));
    if (engine.state.search == null && triggered) break;
  }
  final Gap? found = engine.state.gaps.isEmpty ? null : engine.state.gaps.first;
  return GapTrial(
    planted: planted,
    found: found,
    probes: found?.probes ?? 0,
    items: answered,
    triggered: triggered,
    known: known,
  );
}

/// The result of many gap trials.
class GapReport {
  GapReport(this.label, this.trials);

  final String label;
  final List<GapTrial> trials;

  int get total => trials.length;
  int get triggered => trials.where((GapTrial t) => t.triggered).length;
  int exactWithin(int n) => trials.where((GapTrial t) => t.exact && t.found!.probes <= n).length;
  int get exact => trials.where((GapTrial t) => t.exact).length;
  int get wrong => trials.where((GapTrial t) => t.found != null && !t.exact).length;

  /// Wrong gaps that name a skill the child really knows (a probe failed by a slip).
  int get wrongKnown =>
      trials.where((GapTrial t) => t.found != null && !t.exact && t.known.contains(t.found!.skill)).length;

  /// Wrong gaps that name a skill the child really lacks, between the planted gap and the failing skill.
  int get wrongIntermediate =>
      trials.where((GapTrial t) => t.found != null && !t.exact && !t.known.contains(t.found!.skill)).length;

  int get none => trials.where((GapTrial t) => t.found == null).length;
  double get meanProbes {
    final List<GapTrial> f = trials.where((GapTrial t) => t.found != null).toList();
    return f.isEmpty ? 0 : f.fold<int>(0, (int a, GapTrial t) => a + t.found!.probes) / f.length;
  }

  double get meanItems =>
      trials.isEmpty ? 0 : trials.fold<int>(0, (int a, GapTrial t) => a + t.items) / trials.length;

  /// Share of trials in which the planted gap was found with at most three probes.
  double get rateWithin3 => total == 0 ? 0 : exactWithin(3) / total;

  @override
  String toString() =>
      '${label.padRight(34)} n=$total  within1=${_pct(exactWithin(1))} within2=${_pct(exactWithin(2))} within3=${_pct(exactWithin(3))}  wrong=${_pct(wrong)} (slip ${_pct(wrongKnown)}, between ${_pct(wrongIntermediate)}) none=${_pct(none)}  probes=${meanProbes.toStringAsFixed(2)} items=${meanItems.toStringAsFixed(1)}';

  String _pct(int n) => '${(100 * n / math.max(1, total)).toStringAsFixed(1)}%'.padLeft(6);
}

GapReport gapReport({
  required String label,
  required int children,
  required int seed,
  int gaps = 1,
  double coverage = 0.5,
  int skillsMin = 6,
  int skillsMax = 40,
  EngineParams params = const EngineParams(),
}) {
  final math.Random rnd = math.Random(seed);
  final List<GapTrial> trials = <GapTrial>[];
  while (trials.length < children) {
    final SimWorld w = SimWorld.random(rnd, skills: skillsMin + rnd.nextInt(skillsMax - skillsMin + 1));
    final GapTrial t = runGapTrial(world: w, random: rnd, gaps: gaps, coverage: coverage, params: params);
    if (t.planted.isEmpty) continue;
    trials.add(t);
  }
  return GapReport(label, trials);
}

/// Children who know everything but slip twice in a row on one skill: the engine must not invent a gap.
GapReport falseGapReport({
  required int children,
  required int seed,
  EngineParams params = const EngineParams(),
}) {
  final math.Random rnd = math.Random(seed);
  final List<GapTrial> trials = <GapTrial>[];
  while (trials.length < children) {
    final SimWorld w = SimWorld.random(rnd, skills: 6 + rnd.nextInt(35));
    final Engine engine = Engine(catalog: w.catalog, params: params);
    final List<String> withPre = <String>[
      for (final String id in w.order)
        if (w.catalog.skills[id]!.prerequisites.isNotEmpty) id,
    ];
    if (withPre.isEmpty) continue;
    final String origin = withPre[rnd.nextInt(withPre.length)];
    final SimChild child = SimChild(catalog: w.catalog, known: w.order.toSet(), random: rnd);
    DateTime at = DateTime.utc(2026, 11, 1, 9);
    int id = 0;
    for (final String s in w.order) {
      if (rnd.nextDouble() > 0.5) continue;
      final List<ItemMeta> pool = <ItemMeta>[
        for (final ItemMeta i in w.catalog.itemsFor(s))
          if (i.purpose != Purpose.probe) i,
      ];
      for (int k = 0; k < 3; k++) {
        final ItemMeta item = pool[rnd.nextInt(pool.length)];
        final (Result r, String tag) = child.answer(item);
        engine.apply(AttemptEvent(id: ++id, at: at, activityId: item.id, result: r, tag: tag, sessionId: 1));
        at = at.add(const Duration(minutes: 1));
      }
    }
    final SessionBuilder builder = SessionBuilder(engine: engine, random: rnd);
    final List<Served> served = <Served>[];
    final List<ItemMeta> items = <ItemMeta>[
      for (final ItemMeta i in w.catalog.itemsFor(origin))
        if (i.purpose != Purpose.probe) i,
    ];
    // Two slips in a row, as luck would have it; then the child answers as it knows.
    for (int k = 0; k < 2; k++) {
      engine.apply(
        AttemptEvent(id: ++id, at: at, activityId: items[k].id, result: Result.incorrect, sessionId: 2),
      );
      at = at.add(const Duration(seconds: 40));
    }
    int steps = 0;
    while (engine.state.search != null && steps++ < 20) {
      final Pick pick = builder.next(SessionContext(sessionId: 2, band: 0, now: at, served: served));
      if (pick is! ServeItem) break;
      final (Result r, String tag) = child.answer(pick.item);
      engine.apply(
        AttemptEvent(id: ++id, at: at, activityId: pick.item.id, result: r, tag: tag, sessionId: 2),
      );
      served.add(Served(pick.item, Phase.repair, r));
      at = at.add(const Duration(seconds: 40));
    }
    final Gap? gap = engine.state.gaps.isEmpty ? null : engine.state.gaps.first;
    trials.add(
      GapTrial(
        planted: const <String>{},
        found: gap,
        probes: gap?.probes ?? 0,
        items: steps,
        triggered: true,
      ),
    );
  }
  return GapReport('no gap (two slips)', trials);
}

int _eventId = 1000000;

/// What one played session looked like.
class SessionRun {
  SessionRun(this.served, this.endReason, this.end);

  final List<Served> served;
  final String endReason;
  final DateTime end;

  int count(Phase p) => served.where((Served s) => s.phase == p).length;
}

/// Plays one whole session of an invented child against the builder, as the app would: pick, answer, tell the
/// engine, repeat until the builder ends it.
SessionRun playSession({
  required Engine engine,
  required SessionBuilder builder,
  required SimChild child,
  required int band,
  required int sessionId,
  required DateTime start,
  bool limitReached = false,
  int maxItems = 80,
}) {
  final List<Served> served = <Served>[];
  DateTime at = start;
  String reason = 'guard';
  for (int i = 0; i < maxItems; i++) {
    final Pick pick = builder.next(
      SessionContext(sessionId: sessionId, band: band, now: at, served: served, limitReached: limitReached),
    );
    if (pick is EndSession) {
      reason = pick.reason;
      break;
    }
    final ServeItem s = pick as ServeItem;
    final (Result r, String tag) = child.answer(s.item);
    engine.apply(
      AttemptEvent(id: ++_eventId, at: at, activityId: s.item.id, result: r, tag: tag, sessionId: sessionId),
    );
    served.add(Served(s.item, s.phase, r));
    at = at.add(Duration(seconds: engine.params.secondsPerItem[band]));
  }
  return SessionRun(served, reason, at);
}
