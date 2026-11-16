import '../content/models.dart';
import '../engine/engine.dart';
import '../engine/presentation.dart';
import '../engine/state.dart';

// The lesson arc of a land in a room (M11 Stage 2, docs/milestones/M11-stage2.md sections 2, 5 and 7.4): Recall, Show, Together, Alone, Use. This file
// decides, from what the engine knows about the child, WHICH screens a visit serves and in which order. It knows no widget, no clock and no
// database: the lesson screen gives it the child's standing in each skill, the look stage and the lesson's parts, and the lesson controller plays
// what it returns. Level decides what is served and how (a Show for a skill the child is new to, none for one already mastered); age decides only
// how much (the caps of the look stage).

/// The part of a lesson a screen belongs to.
enum ArcPart { recall, show, together, alone, use }

/// Whether and how a Show plays: not at all, in full (the child is new to the skill: a first meeting), or as a reminder (a shorter run with the
/// key line only, which a touch skips).
enum ShowKind { none, full, reminder }

/// How many screens each part may serve at a look stage (section 2.5; the greeting and the celebration are not counted).
class ArcCaps {
  const ArcCaps({
    required this.screens,
    required this.alone,
    required this.recall,
    required this.use,
    this.scored,
  });

  /// The most screens a visit serves in all.
  final int screens;

  /// How many Alone items a visit serves when a Show and a Together item come first; a mastered skill, with no Show and no Together, takes their
  /// places up to [screens].
  final int alone;

  /// Whether the lesson may open with an item of an earlier skill, and end with an item in a new setting.
  final int recall;
  final int use;

  /// The most scored items (recall, alone and use): 7 for the oldest, where a lesson used to serve up to twelve. Null: only [screens] limits.
  final int? scored;

  /// The caps of the look stage at [index] (0 to 3 for P1 to P4: B-29, P1 to 3;5, P2 3;6 to 4;11, P3 5;0 to 6;5, P4 6;6 and up), from the tables of
  /// `engine/presentation.dart`. The look is named there and by the screen, never here.
  factory ArcCaps.ofStage(int index) => ArcCaps(
    screens: arcScreensByStage[index],
    alone: arcAloneByStage[index],
    recall: arcRecallByStage[index],
    use: arcUseByStage[index],
    scored: arcScoredByStage[index],
  );
}

/// Where the child stands in one skill when the visit begins, as far as the Show and the fade rule care.
class SkillStanding {
  const SkillStanding({
    this.status = SkillStatus.notStarted,
    this.p = 0,
    this.struggled = false,
    this.daysSincePractice,
  });

  /// What the engine knows of [skill] at [now]: its status, the estimate that the child knows it, whether the last visit ended with a worked
  /// example or two mistakes in a row, and how long ago it was last practised. A skill the engine has not started is new.
  factory SkillStanding.of(Engine engine, String skill, DateTime now) {
    if (!engine.catalog.skills.containsKey(skill)) return const SkillStanding();
    final SkillState? s = engine.state.skills[skill];
    final bool started = s != null && s.started;
    return SkillStanding(
      status: engine.statusOf(skill, now),
      p: started ? s.p : 0,
      struggled: started && (s.failRun >= engine.params.switchAfterErrors || s.lastHintLevel >= 3),
      daysSincePractice: started && s.lastAttemptAt != null ? now.difference(s.lastAttemptAt!).inDays : null,
    );
  }

  final SkillStatus status;
  final double p;
  final bool struggled;
  final int? daysSincePractice;

  /// Mastered: the child is not held on hands-on items, and a Show would only get in the way (expertise reversal).
  bool get mastered => status == SkillStatus.freshMastery || status == SkillStatus.durableMastery;

  /// The child has never met the skill: the whole of the first visit is a first meeting.
  bool get isNew =>
      status == SkillStatus.notStarted || status == SkillStatus.ready || status == SkillStatus.gap;

  /// Which Show, if any, this child gets (section 2.3): the child's level decides, the child's age never does.
  ShowKind get showKind {
    if (isNew) return ShowKind.full;
    if (mastered || status == SkillStatus.practised) return ShowKind.none;
    if (status == SkillStatus.needsRevisit) return ShowKind.reminder;
    final bool stale = (daysSincePractice ?? 0) >= 14;
    return p < 0.6 || struggled || stale ? ShowKind.reminder : ShowKind.none;
  }
}

/// The rung of an item by what it shows (section 5): objects moved and the body are 0, pictures and stories 1, symbols 2.
int rungOf(Activity a) => switch (a.representation) {
  'concrete' || 'embodied' => 0,
  'pictorial' || 'story' => 1,
  _ => 2,
};

/// One screen of a visit.
class ArcStep {
  const ArcStep({
    required this.activity,
    required this.part,
    this.show = ShowKind.none,
    this.lead = 0,
    this.line,
    this.firstMeeting = false,
  });

  final Activity activity;
  final ArcPart part;

  /// A Show: in full or as a reminder.
  final ShowKind show;

  /// Together: how many steps the host does first (0: it only says its line), and that line. The first Alone step after the host taught has the
  /// line the host says as the companion takes over; it leads nothing.
  final int lead;
  final Spoken? line;

  /// Together: the full Show of this item's skill plays in this visit, so a right answer shows that the child copied the host, and the item
  /// writes no evidence at all (section 2.2). On a later visit it is an answer given at hint level 2.
  final bool firstMeeting;

  ArcStep withActivity(Activity a) =>
      ArcStep(activity: a, part: part, show: show, lead: lead, line: line, firstMeeting: firstMeeting);
}

/// How the fade rule is going for one skill in this visit (section 5). The wanted rung is the table's for the child's level, moved down by
/// one after a tagged mistake or a worked example and back up after two right answers in a row at hint level 1 or less.
class _Fade {
  _Fade(SkillStanding s)
    : _sequence = s.mastered
          ? const <int>[2, 1]
          : s.p < 0.4 || s.isNew
          ? const <int>[0, 0, 1]
          : s.p < 0.7
          ? const <int>[0, 1, 2, 1, 2]
          : const <int>[1, 2],
      cap = s.p < 0.4 && !s.mastered || s.isNew ? 1 : 2,
      lowIsBetter = !s.mastered && s.p < 0.7;

  final List<int> _sequence;

  /// The highest rung served (a child new to a skill is not given symbols in the first visit).
  final int cap;

  /// A missing rung is replaced by the nearest more concrete one while the child is still learning (p under 0.7), else by the nearest more
  /// symbolic one (section 5, rule 3).
  final bool lowIsBetter;
  int served = 0;
  int _adjust = 0;
  int _rightRun = 0;

  /// The rung to serve next.
  int get wanted =>
      ((served < _sequence.length ? _sequence[served] : _cycle(served)) + _adjust).clamp(0, cap);

  /// After the table is used up it goes on in its last two rungs (1, 2, 1, 2 ...), or stays on its last.
  int _cycle(int k) {
    if (_sequence.length < 2) return _sequence.last;
    final int a = _sequence[_sequence.length - 2];
    final int b = _sequence.last;
    return (k - _sequence.length).isEven ? a : b;
  }

  /// The order in which rungs are tried to fill [wanted].
  List<int> get preference {
    final int w = wanted;
    final List<int> down = <int>[for (int r = w - 1; r >= 0; r--) r];
    final List<int> up = <int>[for (int r = w + 1; r <= 2; r++) r];
    return <int>[
      w,
      if (lowIsBetter) ...<int>[...down, ...up] else ...<int>[...up, ...down],
    ];
  }

  void answered({required bool slipped, required bool clean}) {
    served++;
    if (slipped) {
      _adjust = (_adjust - 1).clamp(-2, 0);
      _rightRun = 0;
    } else if (clean) {
      _rightRun++;
      if (_rightRun >= 2) _adjust = 0;
    } else {
      _rightRun = 0;
    }
  }
}

/// The screens of one visit of a lesson in parts, and the way they are chosen while the child works (the fade rule moves the later Alone
/// items after a mistake or a worked example).
class ArcPlan {
  ArcPlan._(this.steps, this._pool, this._fade, this._standing, this._preferChecks);

  /// The screens in order. The Alone steps after the one just answered may be given another item by [answered].
  final List<ArcStep> steps;
  final Map<String, List<Activity>> _pool;
  final Map<String, _Fade> _fade;
  final Map<String, SkillStanding> _standing;
  final Set<String> _preferChecks;

  /// Plans a visit of [parts] within [caps] (the look's). [standing] gives the child's standing in a skill (a skill it does not know is
  /// new); [started] says whether the child has begun a skill (for the one item of recall). A Show that is not in the pack, or an Alone pool
  /// of no item, makes no plan: the lesson is then played from its flat list, as it was before the arc.
  static ArcPlan? build({
    required PackContent content,
    required LessonParts parts,
    required List<String> skills,
    required ArcCaps caps,
    required SkillStanding Function(String skill) standing,
    required bool Function(String skill) started,
  }) {
    final Activity? firstShow = content.activities[parts.show];
    if (firstShow == null || !firstShow.isShow) return null;
    final Activity? secondShow = parts.secondShow == null ? null : content.activities[parts.secondShow];

    // --- which Shows play: the first skill's, and a reminder before the first item of the second skill ---
    final ShowKind kind1 = standing(firstShow.skillId).showKind;
    ShowKind kind2 = secondShow == null ? ShowKind.none : standing(secondShow.skillId).showKind;
    // A lesson of two new skills gets one full Show (the first new skill's); any other skill that needs one gets a reminder.
    if (kind1 == ShowKind.full && kind2 == ShowKind.full) kind2 = ShowKind.reminder;
    // The second skill's Show plays at the start when the first skill needs none: it is then the lesson's one Show.
    final bool secondFirst = kind1 == ShowKind.none && kind2 != ShowKind.none;

    // --- the pool, by skill ---
    final Map<String, List<Activity>> pool = <String, List<Activity>>{};
    for (final String id in parts.alone) {
      final Activity? a = content.activities[id];
      if (a != null && !a.isShow) pool.putIfAbsent(a.skillId, () => <Activity>[]).add(a);
    }
    final List<String> order = <String>[
      for (final String s in skills)
        if (pool.containsKey(s)) s,
      for (final String s in pool.keys)
        if (!skills.contains(s)) s,
    ];

    // --- Together: an item is played with the host when the Show of its skill plays ---
    final List<ArcStep> together = <ArcStep>[];
    for (final TogetherItem t in parts.together) {
      final Activity? a = content.activities[t.id];
      if (a == null) continue;
      final ShowKind k = a.skillId == firstShow.skillId
          ? kind1
          : a.skillId == secondShow?.skillId
          ? kind2
          : standing(a.skillId).showKind;
      if (k == ShowKind.none) continue;
      together.add(
        ArcStep(
          activity: a,
          part: ArcPart.together,
          lead: t.lead,
          line: t.line,
          firstMeeting: k == ShowKind.full,
        ),
      );
      break; // one Together item at the most: the host leads once
    }

    // --- recall and use ---
    Activity? recall;
    if (caps.recall > 0) {
      for (final String id in parts.recall) {
        final Activity? a = content.activities[id];
        if (a != null && started(a.skillId)) {
          recall = a;
          break;
        }
      }
    }
    final Activity? use = caps.use > 0 && parts.use.isNotEmpty ? content.activities[parts.use.first] : null;

    // --- how many Alone items fit ---
    final bool anyShow = kind1 != ShowKind.none || kind2 != ShowKind.none;
    final int shows = (kind1 != ShowKind.none ? 1 : 0) + (kind2 != ShowKind.none ? 1 : 0);
    final int aloneWanted = caps.alone + (anyShow ? 0 : 2);
    final int poolSize = pool.values.fold(0, (int n, List<Activity> l) => n + l.length);
    int alone = aloneWanted < poolSize ? aloneWanted : poolSize;
    bool useIt = use != null;
    bool recallIt = recall != null;
    int total() => (recallIt ? 1 : 0) + shows + together.length + alone + (useIt ? 1 : 0);
    int scored() => (recallIt ? 1 : 0) + alone + (useIt ? 1 : 0);
    bool tooMany() => total() > caps.screens || (caps.scored != null && scored() > caps.scored!);
    // Past the caps: the Alone items go down to two first, then the Use item and the recall item go, then Alone goes down to one.
    while (tooMany() && alone > 2) {
      alone--;
    }
    if (tooMany() && useIt) useIt = false;
    while (tooMany() && alone > 2) {
      alone--;
    }
    if (tooMany() && recallIt) recallIt = false;
    while (tooMany() && alone > 1) {
      alone--;
    }

    // --- the Alone items, by the fade rule ---
    final Map<String, SkillStanding> standings = <String, SkillStanding>{
      for (final String s in order) s: standing(s),
    };
    final Map<String, _Fade> fade = <String, _Fade>{for (final String s in order) s: _Fade(standings[s]!)};
    final Set<String> checks = <String>{
      for (final MapEntry<String, SkillStanding> e in standings.entries)
        if (e.value.mastered) e.key,
    };
    final ArcPlan plan = ArcPlan._(<ArcStep>[], pool, fade, standings, checks);
    final List<Activity> picked = <Activity>[];
    for (int k = 0; k < alone; k++) {
      // The skills take turns, the first first; a skill with nothing left lets the next one have the place.
      for (int j = 0; j < order.length; j++) {
        final Activity? a = plan._pick(order[(k + j) % order.length], picked);
        if (a != null) {
          picked.add(a);
          break;
        }
      }
    }
    if (picked.isEmpty) return null;

    // --- the screens in order ---
    final ArcStep show1 = ArcStep(activity: firstShow, part: ArcPart.show, show: kind1);
    final List<ArcStep> steps = <ArcStep>[
      if (recallIt) ArcStep(activity: recall!, part: ArcPart.recall),
      if (kind1 != ShowKind.none) show1,
      if (secondFirst) ArcStep(activity: secondShow!, part: ArcPart.show, show: kind2),
      ...together,
    ];
    bool secondPlaced = secondFirst || kind2 == ShowKind.none;
    // The host hands over to the companion as Alone begins, when the host taught first.
    Spoken? handover = anyShow || together.isNotEmpty ? parts.handover : null;
    for (final Activity a in picked) {
      if (!secondPlaced && a.skillId == secondShow!.skillId) {
        steps.add(ArcStep(activity: secondShow, part: ArcPart.show, show: kind2));
        secondPlaced = true;
      }
      steps.add(ArcStep(activity: a, part: ArcPart.alone, line: handover));
      handover = null;
    }
    if (useIt) steps.add(ArcStep(activity: use!, part: ArcPart.use));
    plan.steps.addAll(steps);
    return plan;
  }

  /// The next item of [skill]'s pool that the fade rule wants, not yet [taken] in this visit (null when the pool has none left).
  Activity? _pick(String skill, List<Activity> taken) {
    final List<Activity> left = <Activity>[
      for (final Activity a in _pool[skill] ?? const <Activity>[])
        if (!taken.contains(a)) a,
    ];
    if (left.isEmpty) return null;
    final _Fade f = _fade[skill]!;
    for (final int rung in f.preference) {
      final List<Activity> here = <Activity>[
        for (final Activity a in left)
          if (rungOf(a) == rung) a,
      ];
      if (here.isEmpty) continue;
      // A mastered skill is asked by checks of understanding first: a transfer, a reverse, an explain-back.
      if (_preferChecks.contains(skill)) {
        final Activity? check = here.where((Activity a) => a.checkType != 'practice').firstOrNull;
        if (check != null) return check;
      }
      return here.first;
    }
    return left.first;
  }

  /// The child answered the Alone item at [index] (an Alone step; anything else changes nothing): [slipped] a mistake with a tag, or a worked
  /// example; [clean] right with no more than hint 1. The later Alone steps may take other items (one rung lower after a slip, one up again
  /// after two clean answers). Returns the indexes of the steps that changed.
  List<int> answered(int index, {required bool slipped, required bool clean}) {
    final ArcStep step = steps[index];
    if (step.part != ArcPart.alone) return const <int>[];
    final String skill = step.activity.skillId;
    _fade[skill]?.answered(slipped: slipped, clean: clean);
    final List<Activity> taken = <Activity>[
      for (int i = 0; i <= index; i++)
        if (steps[i].part == ArcPart.alone) steps[i].activity,
    ];
    final List<int> changed = <int>[];
    for (int i = index + 1; i < steps.length; i++) {
      if (steps[i].part != ArcPart.alone) continue;
      final Activity? a = _pick(steps[i].activity.skillId, taken);
      if (a != null && a != steps[i].activity) {
        steps[i] = steps[i].withActivity(a);
        changed.add(i);
      }
      taken.add(steps[i].activity);
    }
    return changed;
  }

  /// How the plan sees a skill (for tests and the developer page).
  SkillStanding? standingOf(String skill) => _standing[skill];
}
