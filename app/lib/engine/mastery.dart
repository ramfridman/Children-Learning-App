import 'params.dart';
import 'types.dart';

/// Bayesian knowledge tracing with soft evidence: how likely the child knows a skill after one answer.
abstract final class Bkt {
  /// The chance of a lucky guess in an item with [optionCount] choices (0 means an open task).
  static double guess(int optionCount, EngineParams params) =>
      optionCount >= 2 ? 1.0 / optionCount : params.pGuessOpen;

  /// The knowledge estimate after one answer. [weight] says how much of a full answer this one is
  /// (the hint credit, the skill's weight in the item, the two-option cap, "not sure" at 0.3); a weight
  /// of 0 changes nothing.
  static double update(
    double p, {
    required bool correct,
    required double weight,
    required int optionCount,
    required EngineParams params,
  }) {
    if (weight <= 0) return p;
    final double g = guess(optionCount, params);
    final double s = params.pSlip;
    final double posterior = correct
        ? (p * (1 - s)) / (p * (1 - s) + (1 - p) * g)
        : (p * s) / (p * s + (1 - p) * (1 - g));
    final double learned = posterior + (1 - posterior) * params.pTransit;
    final double blended = p + weight.clamp(0.0, 1.0) * (learned - p);
    return blended.clamp(0.001, 0.999);
  }

  /// The weight of one answer for one skill.
  static double weightOf({
    required Result result,
    required int hintLevel,
    required double skillWeight,
    required int optionCount,
    required EngineParams params,
  }) {
    switch (result) {
      case Result.correct:
        final double cap = optionCount == 2 ? params.twoOptionCap : 1.0;
        return params.credit(hintLevel) * skillWeight * cap;
      case Result.incorrect:
        return skillWeight;
      case Result.unsure:
        return params.unsureWeight * skillWeight;
    }
  }
}
