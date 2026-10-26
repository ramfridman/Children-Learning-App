import 'dart:math' as math;

import 'params.dart';

/// Memory of one skill, in the FSRS style: a stability S (days until the chance of remembering falls to
/// 90%) and a difficulty D (1 easy to 10 hard). The weights are the published open-source defaults for FSRS 4.5;
/// they are starting values, to be refitted on our own data.
class MemoryState {
  const MemoryState({
    required this.stability,
    required this.difficulty,
    required this.lastReview,
    this.reviews = 0,
  });

  final double stability;
  final double difficulty;
  final DateTime lastReview;
  final int reviews;
}

abstract final class Retention {
  // FSRS-4.5 defaults for the parts of the model used here.
  static const double _w4 = 5.1618; // initial difficulty
  static const double _w6 = 0.8975; // difficulty change per grade
  static const double _w7 = 0.031; // mean reversion
  static const double _w8 = 1.6474;
  static const double _w9 = 0.1367;
  static const double _w10 = 1.0461;
  static const double _w11 = 2.2756;
  static const double _w12 = 0.0773;
  static const double _w13 = 0.3102;
  static const double _w14 = 0.2972;

  /// The chance of remembering after [days], for stability [s]: 0.9 at `days == s`.
  static double retrievability(double days, double s) => math.pow(1 + (19 / 81) * days / s, -0.5).toDouble();

  /// Days until the chance of remembering falls to [target], clamped to the parameters' gaps.
  static double intervalDays(double s, double target, EngineParams params) {
    final double t = s * (81 / 19) * (math.pow(target, -2) - 1);
    return t.clamp(params.minGapDays.toDouble(), params.maxGapDays.toDouble());
  }

  /// The first memory of a skill, made on its first review.
  static MemoryState first({required DateTime at, required double initialStability, required bool good}) {
    final double d = (_w4 - ((good ? 3 : 1) - 3) * 1.2298).clamp(1.0, 10.0);
    return MemoryState(stability: initialStability, difficulty: d, lastReview: at, reviews: 1);
  }

  /// The memory after a review at [at]: a success raises stability (more when the chance of remembering
  /// had fallen), a failure lowers it. Reviews less than half a day apart change nothing (same sitting).
  static MemoryState review(MemoryState m, {required DateTime at, required bool good}) {
    final double days = at.difference(m.lastReview).inMinutes / 1440.0;
    if (days < 0.5) return m;
    final double r = retrievability(days, m.stability);
    final double dNext = (m.difficulty - _w6 * ((good ? 3 : 1) - 3));
    final double dRevert = (_w7 * _w4 + (1 - _w7) * dNext).clamp(1.0, 10.0);
    final double s;
    if (good) {
      s =
          m.stability *
          (1 + math.exp(_w8) * (11 - dRevert) * math.pow(m.stability, -_w9) * (math.exp(_w10 * (1 - r)) - 1));
    } else {
      s = math.min(
        m.stability,
        _w11 * math.pow(dRevert, -_w12) * (math.pow(m.stability + 1, _w13) - 1) * math.exp(_w14 * (1 - r)),
      );
    }
    return MemoryState(
      stability: math.max(0.1, s),
      difficulty: dRevert,
      lastReview: at,
      reviews: m.reviews + 1,
    );
  }
}
