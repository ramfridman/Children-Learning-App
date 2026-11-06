// The release gate of a language's say-it (docs/languages/frame.md section 5.1, docs/milestones/L3.md section 4). Pure Dart.
//
// The test set is the course's say-it words and their foils, read by adults and, supervised by the owner, by children. Only counts
// are kept. What must pass: at most 1 in 20 of the readings that should not be confident (a foil said, nothing said) comes out
// confident, and most of the correct readings do. If it fails, that language's say-it ships in echo mode until a better model passes.
import 'dart:math' as math;

/// How a set of readings came out.
class GateCounts {
  const GateCounts({
    this.correctReadings = 0,
    this.correctConfident = 0,
    this.negativeReadings = 0,
    this.negativeConfident = 0,
  });

  /// The word to be said was said.
  final int correctReadings;
  final int correctConfident;

  /// A foil was said, or nothing (silence, noise, a sibling, the guide's own voice): no reading of these may be confident.
  final int negativeReadings;
  final int negativeConfident;

  GateCounts operator +(GateCounts o) => GateCounts(
    correctReadings: correctReadings + o.correctReadings,
    correctConfident: correctConfident + o.correctConfident,
    negativeReadings: negativeReadings + o.negativeReadings,
    negativeConfident: negativeConfident + o.negativeConfident,
  );
}

enum GateVerdict {
  /// The language's say-it may use the microphone.
  pass,

  /// The language's say-it ships in echo mode.
  fail,

  /// Too few readings to say either: the gate is not passed.
  notEnough,
}

class GateRules {
  const GateRules({
    this.maxFalseConfident = 0.05,
    this.stricterFalseConfident = 0.03,
    this.minNegatives = 60,
    this.minCorrect = 20,
    this.minRecall = 0.5,
  });

  /// "At most 1 in 20" (frame 5.1, approved).
  final double maxFalseConfident;

  /// The 97% bar the research proposed for the owner to confirm (M5's bar); reported, not gated.
  final double stricterFalseConfident;

  /// With none confident in n negative readings the 95% upper bound is about 3 / n (the rule of three): 60 readings are needed to
  /// show "at most 5%", 100 for "at most 3%".
  final int minNegatives;
  final int minCorrect;

  /// "Most correct readings come out confident": more than this.
  final double minRecall;
}

class GateResult {
  const GateResult(
    this.verdict, {
    required this.recall,
    required this.falseConfident,
    required this.upperBound,
    required this.meetsStricterBar,
    required this.reasons,
  });

  final GateVerdict verdict;

  /// The share of correct readings that were confident, and of negative readings that were; NaN when there are none.
  final double recall;
  final double falseConfident;

  /// The 95% upper bound of the false-confident rate (the rule of three when none was confident, else a normal bound).
  final double upperBound;

  /// The upper bound is within the stricter 3% bar.
  final bool meetsStricterBar;
  final List<String> reasons;
}

/// Decides one language (or one age band of it) from its counts.
GateResult releaseGate(GateCounts c, {GateRules rules = const GateRules()}) {
  final double recall = c.correctReadings == 0 ? double.nan : c.correctConfident / c.correctReadings;
  final double fc = c.negativeReadings == 0 ? double.nan : c.negativeConfident / c.negativeReadings;
  final double bound = c.negativeReadings == 0
      ? 1
      : c.negativeConfident == 0
      ? 3 / c.negativeReadings
      : math.min(1, fc + 1.96 * math.sqrt(fc * (1 - fc) / c.negativeReadings));
  final List<String> reasons = <String>[];
  GateVerdict verdict = GateVerdict.pass;

  // Too many confident foils fails at once, however few readings there are.
  if (c.negativeReadings > 0 && fc > rules.maxFalseConfident && c.negativeConfident >= 2) {
    verdict = GateVerdict.fail;
    reasons.add('${c.negativeConfident} of ${c.negativeReadings} readings that should not be confident were');
  } else if (c.negativeReadings < rules.minNegatives) {
    verdict = GateVerdict.notEnough;
    reasons.add(
      '${c.negativeReadings} readings that should not be confident; ${rules.minNegatives} are needed',
    );
  } else if (bound > rules.maxFalseConfident) {
    verdict = GateVerdict.notEnough;
    reasons.add(
      'the 95% upper bound of the false-confident rate is above ${(rules.maxFalseConfident * 100).round()}%',
    );
  }
  if (verdict != GateVerdict.fail) {
    if (c.correctReadings < rules.minCorrect) {
      if (verdict == GateVerdict.pass) verdict = GateVerdict.notEnough;
      reasons.add('${c.correctReadings} correct readings; ${rules.minCorrect} are needed');
    } else if (recall <= rules.minRecall) {
      verdict = GateVerdict.fail;
      reasons.add('only ${(recall * 100).toStringAsFixed(0)}% of the correct readings were confident');
    }
  }
  return GateResult(
    verdict,
    recall: recall,
    falseConfident: fc,
    upperBound: bound,
    meetsStricterBar: c.negativeReadings > 0 && bound <= rules.stricterFalseConfident,
    reasons: reasons,
  );
}

/// The age bands of a language that must each be read before the language can pass (A 3 to 4, B 5 to 6, C 7 to 8).
const List<String> requiredBands = <String>['A', 'B', 'C'];

/// All the age bands of a language. Adults (band `adult`) are read too and may fail it, but only children can pass it: the language
/// passes when each of A, B and C has been read and passes; a band with too few readings keeps it from passing, and one that fails
/// fails it.
GateVerdict languageVerdict(Map<String, GateCounts> byBand, {GateRules rules = const GateRules()}) {
  GateVerdict worst = GateVerdict.pass;
  for (final String b in requiredBands) {
    if (!byBand.containsKey(b)) worst = GateVerdict.notEnough;
  }
  for (final GateCounts c in byBand.values) {
    final GateVerdict v = releaseGate(c, rules: rules).verdict;
    if (v == GateVerdict.fail) return GateVerdict.fail;
    if (v == GateVerdict.notEnough) worst = GateVerdict.notEnough;
  }
  return worst;
}
