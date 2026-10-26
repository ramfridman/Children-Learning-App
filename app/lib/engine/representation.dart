import 'dart:math' as math;

import 'engine.dart';
import 'state.dart';
import 'types.dart';

/// Chooses which way of explaining a skill to use next, by Thompson sampling over how well each way has
/// worked for this child in this family of skills. The random generator is passed in, so a fixed seed
/// always gives the same choices.
class RepresentationChooser {
  RepresentationChooser(this._rnd);

  final math.Random _rnd;

  /// What we believe before any evidence, as (successes, failures) per band A, B, C. Band A starts with things the
  /// child can move; later bands follow the order objects, pictures, symbols.
  static const List<Map<Representation, (double, double)>> priors = <Map<Representation, (double, double)>>[
    <Representation, (double, double)>{
      Representation.concrete: (2.0, 1.0),
      Representation.pictorial: (1.5, 1.0),
      Representation.story: (1.0, 1.0),
      Representation.embodied: (1.0, 1.0),
      Representation.symbolic: (0.5, 1.5),
    },
    <Representation, (double, double)>{
      Representation.concrete: (1.5, 1.0),
      Representation.pictorial: (1.5, 1.0),
      Representation.story: (1.0, 1.0),
      Representation.embodied: (1.0, 1.0),
      Representation.symbolic: (1.0, 1.0),
    },
    <Representation, (double, double)>{
      Representation.concrete: (1.0, 1.0),
      Representation.pictorial: (1.5, 1.0),
      Representation.story: (1.0, 1.0),
      Representation.embodied: (0.8, 1.0),
      Representation.symbolic: (1.5, 1.0),
    },
  ];

  /// One of [available], never [avoid] unless it is the only way. [band] is 0, 1 or 2.
  Representation choose({
    required Engine engine,
    required String skillId,
    required Set<Representation> available,
    Representation? avoid,
    int band = 0,
  }) {
    assert(available.isNotEmpty);
    final List<Representation> options = <Representation>[
      for (final Representation r in Representation.values)
        if (available.contains(r) && r != avoid) r,
    ];
    if (options.isEmpty) return available.first;
    final String family = engine.graph.node(skillId).family;
    Representation best = options.first;
    double bestDraw = -1;
    for (final Representation r in options) {
      final RepStats? st = engine.state.representations['$family|${r.name}'];
      final (double, double) prior = priors[band.clamp(0, 2)][r] ?? (1.0, 1.0);
      final double tries = (st?.tries ?? 0).toDouble();
      final double wins = (st?.successes ?? 0).toDouble();
      final double draw = _beta(prior.$1 + wins, prior.$2 + (tries - wins));
      if (draw > bestDraw) {
        bestDraw = draw;
        best = r;
      }
    }
    return best;
  }

  double _beta(double a, double b) {
    final double x = _gamma(a);
    final double y = _gamma(b);
    return x / (x + y);
  }

  // Marsaglia and Tsang's method.
  double _gamma(double shape) {
    if (shape < 1) {
      return _gamma(shape + 1) * math.pow(_rnd.nextDouble(), 1 / shape);
    }
    final double d = shape - 1 / 3;
    final double c = 1 / math.sqrt(9 * d);
    while (true) {
      double x;
      double v;
      do {
        x = _normal();
        v = 1 + c * x;
      } while (v <= 0);
      v = v * v * v;
      final double u = _rnd.nextDouble();
      if (u < 1 - 0.0331 * x * x * x * x) return d * v;
      if (math.log(u) < 0.5 * x * x + d * (1 - v + math.log(v))) return d * v;
    }
  }

  double _normal() {
    final double u1 = math.max(1e-12, _rnd.nextDouble());
    final double u2 = _rnd.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}
