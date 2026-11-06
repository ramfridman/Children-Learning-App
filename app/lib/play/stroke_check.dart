import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../content/strokes.dart';
import 'stroke_geometry.dart';

// The free-stroke check of LS02 (docs/milestones/L5.md section 5.2): copy and memory are read at the end of each stroke, never during it.
// A child's stroke is compared with the model strokes of the letter that are not matched yet, in any order (stroke order is not scored,
// Q2): it must start near where the model starts, go the way the model goes, stay on the model's path and stop near its end, on the guide
// lines (the numbers are in the 100 by 100 box, so a letter on the wrong lines is seen). A dot is a tap near its point, and a short mark is
// read by its start and its direction only.
//
// An error it can name is returned with its kind (start, direction, lines, mirror, partner); anything else is "unnamed": a retry that
// writes no tag and no evidence. The child's points live only in the session and are never kept.

/// Every tolerance of the check, named so that the qa-engineer can tune each on adult and child-like samples. Box units (100 by 100).
abstract final class StrokeTolerance {
  /// How far from the model's start a stroke may begin.
  static const double startRadius = 18;

  /// How far from the model's end a stroke may stop: a hook or a tail that is left out or turned the wrong way is the difference between
  /// j and its mirror, or Cyrillic sha and shcha.
  static const double endRadius = 24;

  /// How much better (in score: start distance, path distance and half the end distance) a look-alike or a mirror image must fit than the
  /// letter itself to be named instead of it: a rounded ם is no ס.
  static const double margin = 3;

  /// How far from a dot's point a tap may fall.
  static const double dotRadius = 16;

  /// The most a stroke's early course (see [LetterChecker.measure]) may turn from the model's, in degrees.
  static const double firstMoveDegrees = 65;

  /// How far from the model's path the child's path may stray (its points' mean distance), and how much of the model's path it must cover.
  static const double band = 12;
  static const double coverage = 0.8;

  /// The looser band that only decides which error to name: a stroke that is this near the model's path but did not match is a
  /// start or a direction error, not just a scribble.
  static const double looseBand = 18;
  static const double looseCoverage = 0.6;

  /// How much longer than the model a stroke may be: a hand that wobbles or goes over its line a little is still writing the letter, a
  /// scribble that covers the whole box is not.
  static const double longestRatio = 2.5;

  /// A short mark's length against the model's.
  static const double shortFraction = 0.4;

  /// A path shorter than this is a tap.
  static const double tapUnits = 6;

  /// A stroke whose mirror image lies this near (mean distance) is its own mirror (o, the stem of i, a bar): written mirrored it is the same
  /// stroke, so there is no mirror error to name. An s or an a is nearly its own mirror: it is read by its start and its direction.
  static const double symmetricBelow = 3;

  /// A stroke whose mirror image lies this near another stroke of the letter (the two sticks of Cyrillic Tse, the two arms of A) is no sign of a
  /// mirrored hand either: the other stroke is what was written.
  static const double pairedBelow = 10;

  /// After the shape is moved onto the model's bounding box, how near it must be to count as "the right shape on the wrong lines".
  static const double shapeBand = 9;
}

/// What the check made of one stroke.
enum StrokeFault {
  /// Begun far from the model's start (or at its other end).
  start,

  /// Begun right but going the other way (a round part turned the wrong way round).
  direction,

  /// The right shape, off the guide lines (too small, too big, too high or too low).
  lines,

  /// The letter's mirror image.
  mirror,

  /// A look-alike form the author listed.
  partner,
}

class StrokeVerdict {
  const StrokeVerdict.matched(this.index) : fault = null, partner = null;
  const StrokeVerdict.fault(StrokeFault this.fault, {this.partner}) : index = null;
  const StrokeVerdict.unnamed() : index = null, fault = null, partner = null;

  /// The model stroke this stroke is (the stroke is right), or null.
  final int? index;

  /// The error it names, or null when it is right or when it is a miss that cannot be named.
  final StrokeFault? fault;

  /// For [StrokeFault.partner]: the form id of the look-alike that was written.
  final String? partner;

  bool get right => index != null;
  bool get named => fault != null;
}

/// Reads the strokes of one letter box, one at a time. Make one for a letter, give it each finished stroke, and ask when it is whole.
class LetterChecker {
  LetterChecker(this.form, {this.partners = const <StrokeForm>[]})
    : done = List<bool>.filled(form.strokes.length, false);

  final StrokeForm form;

  /// The look-alike forms a miss is also read against.
  final List<StrokeForm> partners;

  /// Which model strokes have been matched.
  final List<bool> done;

  bool get complete => done.every((bool d) => d);

  int get matched => done.where((bool d) => d).length;

  void reset() => done.fillRange(0, done.length, false);

  /// The first model stroke not matched yet, in the order it is written (where the start dot goes), or null when the letter is whole.
  int? get next {
    for (int i = 0; i < done.length; i++) {
      if (!done[i]) return i;
    }
    return null;
  }

  /// Reads one finished stroke [drawn] (box units).
  StrokeVerdict check(List<Offset> drawn) {
    if (drawn.isEmpty) return const StrokeVerdict.unnamed();
    final List<Offset> dp = denseStroke(drawn);
    final double length = strokeLength(dp);
    if (length < StrokeTolerance.tapUnits) {
      final int? dot = _dotAt(dp.first);
      if (dot == null) return const StrokeVerdict.unnamed();
      done[dot] = true;
      return StrokeVerdict.matched(dot);
    }
    // The nearest model stroke that fits, and how well.
    int? best;
    double bestScore = double.infinity;
    for (int i = 0; i < done.length; i++) {
      final StrokeModel m = form.strokes[i];
      if (done[i] || m.kind == StrokeKind.dot) continue;
      final double? score = _matchScore(dp, length, m.points, m.kind, retrace: m.retrace);
      if (score != null && score < bestScore) {
        best = i;
        bestScore = score;
      }
    }
    // A look-alike form, or the mirror image of a stroke, that fits better than the letter itself by a margin is what was written.
    final ({String form, double score})? alike = _bestPartner(dp, length);
    if (alike != null && alike.score + StrokeTolerance.margin < bestScore) {
      return StrokeVerdict.fault(StrokeFault.partner, partner: alike.form);
    }
    final double? flipped = _bestMirror(dp, length);
    if (flipped != null && flipped + StrokeTolerance.margin < bestScore) {
      return const StrokeVerdict.fault(StrokeFault.mirror);
    }
    if (best != null) {
      done[best] = true;
      return StrokeVerdict.matched(best);
    }
    return _name(dp, length);
  }

  /// Reads one finished stroke [drawn] as a trace: the stroke that is next in the order it is written, followed along its dotted path
  /// (T04's check, [pathVerdict]) with the tolerance [tol]. A dot and a short mark are read as ever. A path that is right but begun at the
  /// stroke's other end is a start error; any other miss is a retry with no name.
  StrokeVerdict traceCheck(List<Offset> drawn, double tol) {
    final int? i = next;
    if (i == null || drawn.isEmpty) return const StrokeVerdict.unnamed();
    final StrokeModel m = form.strokes[i];
    if (m.kind != StrokeKind.line) return check(drawn);
    if (strokeLength(denseStroke(drawn)) < StrokeTolerance.tapUnits) return const StrokeVerdict.unnamed();
    final PathVerdict v = pathVerdict(drawn, m.points, tol);
    if (v.onPath && v.startsRight) {
      done[i] = true;
      return StrokeVerdict.matched(i);
    }
    if (v.onPath && v.startsAtEnd) return const StrokeVerdict.fault(StrokeFault.start);
    return const StrokeVerdict.unnamed();
  }

  int? _dotAt(Offset p) {
    int? best;
    double bestDist = StrokeTolerance.dotRadius;
    for (int i = 0; i < done.length; i++) {
      final StrokeModel m = form.strokes[i];
      if (done[i] || m.kind != StrokeKind.dot) continue;
      final double d = (p - m.start).distance;
      if (d <= bestDist) {
        best = i;
        bestDist = d;
      }
    }
    return best;
  }

  /// The look-alike form whose stroke fits [dp] best, with the score.
  ({String form, double score})? _bestPartner(List<Offset> dp, double length) {
    ({String form, double score})? best;
    for (final StrokeForm p in partners) {
      for (final StrokeModel m in p.strokes) {
        if (m.kind == StrokeKind.dot) continue;
        final double? score = _matchScore(dp, length, m.points, m.kind, retrace: m.retrace);
        if (score != null && (best == null || score < best.score)) best = (form: p.id, score: score);
      }
    }
    return best;
  }

  /// How well [dp] is the mirror image of a stroke of the letter that is not its own mirror image, or null.
  double? _bestMirror(List<Offset> dp, double length) {
    double? best;
    for (int i = 0; i < done.length; i++) {
      final StrokeModel m = form.strokes[i];
      if (done[i] || m.kind == StrokeKind.dot || _mirrorIsAStroke(form, i)) continue;
      final double? score = _matchScore(dp, length, _mirrored(m.points), m.kind, retrace: m.retrace);
      if (score != null && (best == null || score < best)) best = score;
    }
    return best;
  }

  /// The mirror image of stroke [i] of [form] is the stroke itself or another stroke of the letter: written mirrored it is no error that
  /// the mirror could name.
  static bool _mirrorIsAStroke(StrokeForm form, int i) {
    final List<Offset> flipped = _mirrored(form.strokes[i].points);
    for (int k = 0; k < form.strokes.length; k++) {
      final StrokeModel o = form.strokes[k];
      if (o.kind == StrokeKind.dot) continue;
      final double limit = k == i ? StrokeTolerance.symmetricBelow : StrokeTolerance.pairedBelow;
      if (_meanDistance(flipped, o.points) < limit) return true;
    }
    return false;
  }

  /// A letter every stroke of which is its own mirror image or the mirror image of another (o, i, t, A, H, X, Cyrillic Tse): written mirrored it is the
  /// same letter, and no mirror error can be named for it.
  static bool mirrorsOntoItself(StrokeForm form) {
    for (int i = 0; i < form.strokes.length; i++) {
      if (form.strokes[i].kind != StrokeKind.dot && !_mirrorIsAStroke(form, i)) return false;
    }
    return true;
  }

  /// The four numbers a stroke is judged by, against a model path: how far it starts from the model's start, how far its early course turns
  /// from the model's (degrees), how far its path strays on average, and how much of the model's path it covers. For the qa-engineer, who
  /// tunes [StrokeTolerance] on samples.
  static ({double start, double turn, double mean, double covered}) measure(
    List<Offset> drawn,
    List<Offset> model,
  ) {
    final List<Offset> dp = denseStroke(drawn);
    return (
      start: (dp.first - model.first).distance,
      turn: _firstMoveTurn(dp, model),
      mean: _meanDistance(dp, model),
      covered: _covered(dp, model),
    );
  }

  // ---- matching ----

  /// How well the drawn path [dp] is the model path [model] (a smaller number is better), or null when it is not: it starts near its
  /// start, goes the same way, stays on its path, covers it and stops near its end (a short mark: starts near and goes the same way only).
  static double? _matchScore(
    List<Offset> dp,
    double length,
    List<Offset> model,
    StrokeKind kind, {
    bool retrace = false,
  }) {
    final double startDist = (dp.first - model.first).distance;
    if (startDist > StrokeTolerance.startRadius) return null;
    if (kind == StrokeKind.short) {
      final double modelLength = strokeLength(model);
      final double angle = _turn(dp.last - dp.first, model.last - model.first);
      if (angle > StrokeTolerance.firstMoveDegrees) return null;
      if (length < modelLength * StrokeTolerance.shortFraction || length > math.max(modelLength * 3, 30)) {
        return null;
      }
      return startDist;
    }
    // A stroke that goes back over its own line (n, m, h, r, a, d) has no one early course to compare: its start, its band, its coverage and
    // its end decide, and the "wrong way" of it is begun at its other end.
    if (!retrace && _firstMoveTurn(dp, model) > StrokeTolerance.firstMoveDegrees) return null;
    if (length > strokeLength(model) * StrokeTolerance.longestRatio) return null;
    final double mean = _meanDistance(dp, model);
    if (mean > StrokeTolerance.band || _covered(dp, model) < StrokeTolerance.coverage) return null;
    final double endDist = (dp.last - model.last).distance;
    if (endDist > StrokeTolerance.endRadius) return null;
    return startDist + mean + endDist / 2;
  }

  static double _meanDistance(List<Offset> dp, List<Offset> model) {
    final List<Offset> sample = resampleStroke(dp, 32);
    double sum = 0;
    for (final Offset p in sample) {
      sum += distanceToPath(p, model);
    }
    return sum / sample.length;
  }

  /// The share of the model's path that lies within [band] of the drawn path.
  static double _covered(List<Offset> dp, List<Offset> model, [double band = StrokeTolerance.band]) {
    final List<Offset> sample = resampleStroke(model, 32);
    final int near = sample.where((Offset q) => distanceToPath(q, dp) <= band).length;
    return near / sample.length;
  }

  /// How far the early course of the drawn path turns from the model's, in degrees. The course is the chord from a fifth to three fifths of
  /// the way along the path: it says which way the stroke goes (a circle round the right way or the wrong one, a stem down or up) without
  /// being thrown by where a finger lands and the little wander before it settles on the line, which is what the first few units of a stroke
  /// are on a child's hand.
  static double _firstMoveTurn(List<Offset> dp, List<Offset> model) => _turn(_course(dp), _course(model));

  static Offset _course(List<Offset> pts) {
    final double length = strokeLength(pts);
    if (length < 12) return pts.last - pts.first;
    return pointAlong(pts, length * 0.6) - pointAlong(pts, length * 0.2);
  }

  static double _turn(Offset a, Offset b) {
    if (a.distance == 0 || b.distance == 0) return 180;
    final double d = (math.atan2(a.dy, a.dx) - math.atan2(b.dy, b.dx)).abs() * 180 / math.pi;
    return d > 180 ? 360 - d : d;
  }

  // ---- naming a miss ----

  /// Names what is wrong with a stroke that fits no stroke of the letter, its mirror image or a look-alike: the nearest model stroke that
  /// is not matched yet, and whether the stroke was begun far from its start or at its other end, begun right and going the wrong way
  /// round, or the right shape on the wrong lines.
  StrokeVerdict _name(List<Offset> dp, double length) {
    StrokeFault? fault;
    double bestScore = double.infinity;
    for (int i = 0; i < done.length; i++) {
      final StrokeModel m = form.strokes[i];
      // A scribble that covers the box is no stroke of this letter, whatever its shape: it is named nothing.
      if (done[i] ||
          m.kind != StrokeKind.line ||
          length > strokeLength(m.points) * StrokeTolerance.longestRatio) {
        continue;
      }
      final double mean = _meanDistance(dp, m.points);
      if (mean <= StrokeTolerance.looseBand &&
          _covered(dp, m.points, StrokeTolerance.looseBand) >= StrokeTolerance.looseCoverage) {
        // On the path but not a match: begun far from its start (or at its other end), or begun right and going the wrong way.
        final bool startsHere = (dp.first - m.start).distance <= StrokeTolerance.startRadius;
        if (mean < bestScore) {
          bestScore = mean;
          fault = startsHere ? StrokeFault.direction : StrokeFault.start;
        }
        continue;
      }
      // The right shape in the wrong place or size: moved onto the model's box it fits.
      final List<Offset> fitted = _onto(dp, m.points);
      final double shape = _meanDistance(fitted, m.points);
      if (shape <= StrokeTolerance.shapeBand &&
          _covered(fitted, m.points, StrokeTolerance.shapeBand) >= StrokeTolerance.coverage &&
          _turn(fitted.last - fitted.first, m.end - m.start) <= 90 &&
          shape + 20 < bestScore) {
        bestScore = shape + 20;
        fault = StrokeFault.lines;
      } else if (_meanDistance(fitted.reversed.toList(), m.points) <= StrokeTolerance.shapeBand &&
          shape + 40 < bestScore) {
        bestScore = shape + 40;
        fault = StrokeFault.start;
      }
    }
    return fault == null ? const StrokeVerdict.unnamed() : StrokeVerdict.fault(fault);
  }

  /// [pts] reflected about the middle of the box (the letters are centred on it).
  static List<Offset> _mirrored(List<Offset> pts) => <Offset>[
    for (final Offset p in pts) Offset(100 - p.dx, p.dy),
  ];

  /// [pts] moved and stretched onto the bounding box of [model].
  static List<Offset> _onto(List<Offset> pts, List<Offset> model) {
    ({double l, double t, double r, double b}) box(List<Offset> l) {
      double left = double.infinity,
          top = double.infinity,
          right = -double.infinity,
          bottom = -double.infinity;
      for (final Offset p in l) {
        left = math.min(left, p.dx);
        top = math.min(top, p.dy);
        right = math.max(right, p.dx);
        bottom = math.max(bottom, p.dy);
      }
      return (l: left, t: top, r: right, b: bottom);
    }

    final ({double l, double t, double r, double b}) a = box(pts);
    final ({double l, double t, double r, double b}) m = box(model);
    final double aw = a.r - a.l, ah = a.b - a.t, mw = m.r - m.l, mh = m.b - m.t;
    return <Offset>[
      for (final Offset p in pts)
        Offset(
          aw < 4 ? (m.l + m.r) / 2 : m.l + (p.dx - a.l) / aw * mw,
          ah < 4 ? (m.t + m.b) / 2 : m.t + (p.dy - a.t) / ah * mh,
        ),
    ];
  }
}
