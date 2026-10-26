// The tunable numbers of the learning engine. Every one is a starting value from docs/curriculum.md
// section 10 or docs/tech.md section 7; none has been tested on a child yet. The class reads and writes
// JSON so that a content pack can carry a tuned copy later; until then the defaults ship in code.
//
// The engine imports nothing but `dart:` libraries and other engine files (a test enforces it).

class EngineParams {
  const EngineParams({
    this.priorNew = 0.2,
    this.priorAssumed = 0.85,
    this.pTransit = 0.15,
    this.pSlip = 0.08,
    this.pGuessOpen = 0.02,
    this.creditByHint = const <double>[1.0, 0.8, 0.5, 0.0],
    this.unsureWeight = 0.3,
    this.twoOptionCap = 0.5,
    this.unlockBar = 0.8,
    this.masteryBar = 0.95,
    this.freshSuccesses = 4,
    this.freshSuccessesCore = 6,
    this.freshDays = 2,
    this.freshRepresentations = 1,
    this.freshRepresentationsCore = 2,
    this.freshChecks = 1,
    this.freshChecksCore = 2,
    this.durableDays = 7,
    this.revisitBelow = 0.7,
    this.targetRetention = 0.9,
    this.minGapDays = 1,
    this.maxGapDays = 90,
    this.evidenceDecay = 0.8,
    this.activeScore = 1.5,
    this.activeItems = 2,
    this.resolveAfter = 3,
    this.failTrigger = 2,
    this.unsureTrigger = 3,
    this.probeMaxDepth = 3,
    this.probeMaxPerSearch = 3,
    this.probeMaxPerSession = 3,
    this.skipProbeAbove = 0.95,
    this.repairSuccesses = 2,
    this.stepBackBelow = 0.4,
    this.stepBackAfter = 5,
    this.stuckErrors = 3,
    this.stuckWorkedExamples = 2,
    this.switchAfterErrors = 2,
    this.maxNewSkillsPerSession = 2,
    this.targetBandA = const <double>[0.80, 0.90],
    this.targetBandBC = const <double>[0.75, 0.85],
    this.endOnSuccessAbove = 0.85,
    this.repairShareMax = 0.25,
    this.secondsPerItem = const <int>[35, 45, 50],
    this.sessionMinutes = const <int>[8, 12, 15],
  });

  factory EngineParams.fromJson(Map<String, Object?> j) {
    const EngineParams d = EngineParams();
    double n(String k, double fallback) => (j[k] as num?)?.toDouble() ?? fallback;
    int i(String k, int fallback) => (j[k] as num?)?.toInt() ?? fallback;
    List<double> l(String k, List<double> fallback) =>
        (j[k] as List<Object?>?)?.map((Object? e) => (e! as num).toDouble()).toList() ?? fallback;
    List<int> li(String k, List<int> fallback) =>
        (j[k] as List<Object?>?)?.map((Object? e) => (e! as num).toInt()).toList() ?? fallback;
    return EngineParams(
      priorNew: n('priorNew', d.priorNew),
      priorAssumed: n('priorAssumed', d.priorAssumed),
      pTransit: n('pTransit', d.pTransit),
      pSlip: n('pSlip', d.pSlip),
      pGuessOpen: n('pGuessOpen', d.pGuessOpen),
      creditByHint: l('creditByHint', d.creditByHint),
      unsureWeight: n('unsureWeight', d.unsureWeight),
      twoOptionCap: n('twoOptionCap', d.twoOptionCap),
      unlockBar: n('unlockBar', d.unlockBar),
      masteryBar: n('masteryBar', d.masteryBar),
      freshSuccesses: i('freshSuccesses', d.freshSuccesses),
      freshSuccessesCore: i('freshSuccessesCore', d.freshSuccessesCore),
      freshDays: i('freshDays', d.freshDays),
      freshRepresentations: i('freshRepresentations', d.freshRepresentations),
      freshRepresentationsCore: i('freshRepresentationsCore', d.freshRepresentationsCore),
      freshChecks: i('freshChecks', d.freshChecks),
      freshChecksCore: i('freshChecksCore', d.freshChecksCore),
      durableDays: i('durableDays', d.durableDays),
      revisitBelow: n('revisitBelow', d.revisitBelow),
      targetRetention: n('targetRetention', d.targetRetention),
      minGapDays: i('minGapDays', d.minGapDays),
      maxGapDays: i('maxGapDays', d.maxGapDays),
      evidenceDecay: n('evidenceDecay', d.evidenceDecay),
      activeScore: n('activeScore', d.activeScore),
      activeItems: i('activeItems', d.activeItems),
      resolveAfter: i('resolveAfter', d.resolveAfter),
      failTrigger: i('failTrigger', d.failTrigger),
      unsureTrigger: i('unsureTrigger', d.unsureTrigger),
      probeMaxDepth: i('probeMaxDepth', d.probeMaxDepth),
      probeMaxPerSearch: i('probeMaxPerSearch', d.probeMaxPerSearch),
      probeMaxPerSession: i('probeMaxPerSession', d.probeMaxPerSession),
      skipProbeAbove: n('skipProbeAbove', d.skipProbeAbove),
      repairSuccesses: i('repairSuccesses', d.repairSuccesses),
      stepBackBelow: n('stepBackBelow', d.stepBackBelow),
      stepBackAfter: i('stepBackAfter', d.stepBackAfter),
      stuckErrors: i('stuckErrors', d.stuckErrors),
      stuckWorkedExamples: i('stuckWorkedExamples', d.stuckWorkedExamples),
      switchAfterErrors: i('switchAfterErrors', d.switchAfterErrors),
      maxNewSkillsPerSession: i('maxNewSkillsPerSession', d.maxNewSkillsPerSession),
      targetBandA: l('targetBandA', d.targetBandA),
      targetBandBC: l('targetBandBC', d.targetBandBC),
      endOnSuccessAbove: n('endOnSuccessAbove', d.endOnSuccessAbove),
      repairShareMax: n('repairShareMax', d.repairShareMax),
      secondsPerItem: li('secondsPerItem', d.secondsPerItem),
      sessionMinutes: li('sessionMinutes', d.sessionMinutes),
    );
  }

  /// Knowledge before any evidence: a new skill, or one assumed from a placement below the child's level.
  final double priorNew;
  final double priorAssumed;

  /// Chance of learning the skill from one attempt (BKT), of a slip, and of a lucky guess in an open task.
  final double pTransit;
  final double pSlip;
  final double pGuessOpen;

  /// Credit for a right answer by hint level shown: none, 1, 2, 3 (a worked example).
  final List<double> creditByHint;

  /// "I'm not sure" counts as this much of a wrong answer, and never as misconception evidence.
  final double unsureWeight;

  /// Right answers in two-option items count for at most this share of the success evidence.
  final double twoOptionCap;

  /// A skill unlocks when all prerequisites reach this; mastery needs the second bar.
  final double unlockBar;
  final double masteryBar;
  final int freshSuccesses;
  final int freshSuccessesCore;
  final int freshDays;
  final int freshRepresentations;
  final int freshRepresentationsCore;
  final int freshChecks;
  final int freshChecksCore;
  final int durableDays;
  final double revisitBelow;

  /// Memory: when the chance of remembering falls to this, a check is due (between the two gaps, in days).
  final double targetRetention;
  final int minGapDays;
  final int maxGapDays;

  /// Misconceptions: `score = decay * score + strength`; active at the score and the number of different items.
  final double evidenceDecay;
  final double activeScore;
  final int activeItems;
  final int resolveAfter;

  /// A gap search starts after this many wrong answers in a row on a skill, or this many "not sure".
  final int failTrigger;
  final int unsureTrigger;
  final int probeMaxDepth;
  final int probeMaxPerSearch;
  final int probeMaxPerSession;

  /// A prerequisite the child has just shown at this estimate needs no probe.
  final double skipProbeAbove;
  final int repairSuccesses;
  final double stepBackBelow;
  final int stepBackAfter;
  final int stuckErrors;
  final int stuckWorkedExamples;
  final int switchAfterErrors;
  final int maxNewSkillsPerSession;

  /// The success rate the items are chosen for: Band A, and Bands B and C (low, high).
  final List<double> targetBandA;
  final List<double> targetBandBC;
  final double endOnSuccessAbove;
  final double repairShareMax;

  /// Per band A, B, C: seconds an item takes and the length of a session in minutes.
  final List<int> secondsPerItem;
  final List<int> sessionMinutes;

  double credit(int hintLevel) => creditByHint[hintLevel.clamp(0, creditByHint.length - 1)];

  Map<String, Object?> toJson() => <String, Object?>{
    'priorNew': priorNew,
    'priorAssumed': priorAssumed,
    'pTransit': pTransit,
    'pSlip': pSlip,
    'pGuessOpen': pGuessOpen,
    'creditByHint': creditByHint,
    'unsureWeight': unsureWeight,
    'twoOptionCap': twoOptionCap,
    'unlockBar': unlockBar,
    'masteryBar': masteryBar,
    'freshSuccesses': freshSuccesses,
    'freshSuccessesCore': freshSuccessesCore,
    'freshDays': freshDays,
    'freshRepresentations': freshRepresentations,
    'freshRepresentationsCore': freshRepresentationsCore,
    'freshChecks': freshChecks,
    'freshChecksCore': freshChecksCore,
    'durableDays': durableDays,
    'revisitBelow': revisitBelow,
    'targetRetention': targetRetention,
    'minGapDays': minGapDays,
    'maxGapDays': maxGapDays,
    'evidenceDecay': evidenceDecay,
    'activeScore': activeScore,
    'activeItems': activeItems,
    'resolveAfter': resolveAfter,
    'failTrigger': failTrigger,
    'unsureTrigger': unsureTrigger,
    'probeMaxDepth': probeMaxDepth,
    'probeMaxPerSearch': probeMaxPerSearch,
    'probeMaxPerSession': probeMaxPerSession,
    'skipProbeAbove': skipProbeAbove,
    'repairSuccesses': repairSuccesses,
    'stepBackBelow': stepBackBelow,
    'stepBackAfter': stepBackAfter,
    'stuckErrors': stuckErrors,
    'stuckWorkedExamples': stuckWorkedExamples,
    'switchAfterErrors': switchAfterErrors,
    'maxNewSkillsPerSession': maxNewSkillsPerSession,
    'targetBandA': targetBandA,
    'targetBandBC': targetBandBC,
    'endOnSuccessAbove': endOnSuccessAbove,
    'repairShareMax': repairShareMax,
    'secondsPerItem': secondsPerItem,
    'sessionMinutes': sessionMinutes,
  };
}
