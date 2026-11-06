import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import '../content/strokes.dart';
import 'stroke_geometry.dart';

// The free-stroke check of LS02 (docs/milestones/L5.md section 5.2): copy and memory are read at the end of each stroke, never during it.
// A child's stroke is compared with the model strokes of the letter that are not matched yet, in any order (stroke order is not scored,
// Q2): it must start near where the model starts, go the way the model goes, stay on the model's path and stop near its end, on the guide
// lines (the numbers are in the 100 by 100 box, so a letter on the wrong lines is seen). A dot is a tap near its point, and a short mark is
// read by its start and its direction only.
//
// A letter has its model and a few other builds that are right (a ball and a stick for a, QA-L52-1): each stroke is read against every build
// that is still possible, a build that the stroke does not fit is dropped, and the letter is whole when one build is whole. After the last
// stroke the whole drawing is read once more against every form of the script ([LetterChecker.otherLetter], QA-L52-4): the stem of a t
// completes an l, so what the child goes on to write decides which letter it was.
//
// An error it can name is returned with its kind (start, direction, lines, mirror, partner); anything else is "unnamed": a retry that
// writes no tag and no evidence. A stroke that is no scribble, is most of a model stroke and fits no build is the only stroke that is named.
// The child's points live only in the session and are never kept.

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
  static const double longestRatio = 2.0;

  /// A stroke longer than this against the model's, or with more loops or corners than the model, is a scribble: it is named nothing.
  static const double scribbleRatio = 1.6;
  static const int scribbleCrossings = 2;
  static const int scribbleCorners = 2;

  /// A short mark's length against the model's, from and to.
  static const double shortFraction = 0.4;
  static const double shortRatio = 2;

  /// A path shorter than this is a tap.
  static const double tapUnits = 6;

  /// On an axis where the model is at least [extentMin] units across, a stroke must reach this share of it: a straight line down the
  /// middle is no s and no resh, whatever its start and end (QA-L52-3).
  /// A child's hand wanders a few units, so [extentSlack] is taken off what is asked.
  static const double extentShare = 0.5;
  static const double extentMin = 15;
  static const double extentSlack = 3;

  /// A turn of this many degrees within a short run is a corner; a turn back on the line is a reversal (the n, the stem of the a).
  static const double cornerDegrees = 60;
  static const double reversalDegrees = 100;

  /// A start or direction error is named only for a stroke that is of the model stroke's length (from this share to that): a shorter one
  /// is a part of a build the check does not know (the stem of a b), a longer one is more than one stroke of the model written in one,
  /// and both are a retry with no name.
  static const double partialShare = 0.7;
  static const double wholeShare = 1.25;

  /// A model whose end is this near its start is a ring (o, samekh, the bowl of the Cyrillic a): it may be begun anywhere on the ring, and
  /// goes round the same way.
  static const double closedBelow = 12;

  /// A ring is drawn closed: the gap between where it began and where it stopped is at most this share of its size (a c's is over 0.6), or
  /// the model's own gap and a third of the size, whichever is more (the bowl of the Cyrillic a is left a little open).
  static const double ringGapShare = 0.45;

  /// A stroke whose mirror image lies this near (mean distance) is its own mirror (o, the stem of i, a bar): written mirrored it is the same
  /// stroke, so there is no mirror error to name. An s or an a is nearly its own mirror: it is read by its start and its direction.
  static const double symmetricBelow = 3;

  /// A stroke whose mirror image lies this near another stroke of the letter (the two sticks of Cyrillic Tse, the two arms of A) is no sign of a
  /// mirrored hand either: the other stroke is what was written.
  static const double pairedBelow = 10;

  /// After the shape is moved onto the model's bounding box, how near it must be to count as "the right shape on the wrong lines".
  static const double shapeBand = 9;

  /// The whole drawing is taken for another letter when that letter fits it better than the target by this much per stroke.
  static const double wholeMargin = 12;
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

/// A way to write the letter (its model or another right build) and how far a child's strokes have gone along it.
class _Build {
  _Build(this.strokes) : done = List<bool>.filled(strokes.length, false);

  final List<StrokeModel> strokes;
  final List<bool> done;

  /// False once a stroke was written that this build does not have: the child is writing the letter another way.
  bool alive = true;

  bool get complete => done.every((bool d) => d);
}

/// The stroke of a build that a drawn stroke is, and how well.
typedef _Hit = ({int index, double score});

/// Reads the strokes of one letter box, one at a time. Make one for a letter, give it each finished stroke, and ask when it is whole.
class LetterChecker {
  LetterChecker(this.form, {this.partners = const <StrokeForm>[]})
    : _builds = <_Build>[for (final List<StrokeModel> b in form.builds) _Build(b)];

  final StrokeForm form;

  /// The look-alike forms a miss is also read against.
  final List<StrokeForm> partners;

  /// The model and the other right builds of the letter, with the strokes each has been given.
  final List<_Build> _builds;

  /// The build the child is on: the first that every stroke so far has fitted (the model, until a stroke fits only another build).
  _Build get _active => _builds.firstWhere((_Build b) => b.alive);

  /// The strokes of the build the child is on, and which of them are matched.
  List<StrokeModel> get strokes => _active.strokes;
  List<bool> get done => _active.done;

  bool get complete => _builds.any((_Build b) => b.alive && b.complete);

  int get matched => done.where((bool d) => d).length;

  void reset() {
    for (final _Build b in _builds) {
      b.alive = true;
      b.done.fillRange(0, b.done.length, false);
    }
  }

  /// The first stroke of the build not matched yet, in the order it is written (where the start dot goes), or null when the letter is whole.
  int? get next {
    final List<bool> d = done;
    for (int i = 0; i < d.length; i++) {
      if (!d[i]) return i;
    }
    return null;
  }

  /// Reads one finished stroke [drawn] (box units).
  StrokeVerdict check(List<Offset> drawn) {
    if (drawn.isEmpty) return const StrokeVerdict.unnamed();
    final List<Offset> dp = denseStroke(drawn);
    final double length = strokeLength(dp);
    if (length < StrokeTolerance.tapUnits) {
      final List<_Hit?> dots = <_Hit?>[for (final _Build b in _builds) b.alive ? _dotAt(b, dp.first) : null];
      if (dots.every((_Hit? h) => h == null)) return const StrokeVerdict.unnamed();
      return StrokeVerdict.matched(_commit(dots));
    }
    // The nearest model stroke that fits in each build that is still possible, and how well.
    final List<_Hit?> hits = <_Hit?>[
      for (final _Build b in _builds) b.alive ? _strokeAt(b, dp, length) : null,
    ];
    double bestScore = double.infinity;
    for (final _Hit? h in hits) {
      if (h != null && h.score < bestScore) bestScore = h.score;
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
    if (bestScore.isFinite) return StrokeVerdict.matched(_commit(hits));
    return _name(dp, length);
  }

  /// Gives the stroke to the builds it fits and drops the others; returns the index of the stroke in the build the child is on.
  int _commit(List<_Hit?> hits) {
    for (final (int b, _Build build) in _builds.indexed) {
      if (!build.alive) continue;
      final _Hit? h = hits[b];
      if (h == null) {
        build.alive = false;
      } else {
        build.done[h.index] = true;
      }
    }
    return hits[_builds.indexOf(_active)]!.index;
  }

  /// Reads one finished stroke [drawn] as a trace: the stroke that is next in the order it is written, followed along its dotted path
  /// (T04's check, [pathVerdict]) with the tolerance [tol]. A dot and a short mark are read as ever. A path that is right but begun at the
  /// stroke's other end is a start error; any other miss is a retry with no name. A trace follows the build the child is on.
  StrokeVerdict traceCheck(List<Offset> drawn, double tol) {
    final int? i = next;
    if (i == null || drawn.isEmpty) return const StrokeVerdict.unnamed();
    final _Build on = _active;
    for (final _Build b in _builds) {
      b.alive = identical(b, on);
    }
    final StrokeModel m = on.strokes[i];
    if (m.kind != StrokeKind.line) return check(drawn);
    if (strokeLength(denseStroke(drawn)) < StrokeTolerance.tapUnits) return const StrokeVerdict.unnamed();
    final PathVerdict v = pathVerdict(drawn, m.points, tol);
    if (v.onPath && v.startsRight) {
      on.done[i] = true;
      return StrokeVerdict.matched(i);
    }
    if (v.onPath && v.startsAtEnd) return const StrokeVerdict.fault(StrokeFault.start);
    return const StrokeVerdict.unnamed();
  }

  _Hit? _dotAt(_Build b, Offset p) {
    _Hit? best;
    for (int i = 0; i < b.strokes.length; i++) {
      final StrokeModel m = b.strokes[i];
      if (b.done[i] || m.kind != StrokeKind.dot) continue;
      final double d = (p - m.start).distance;
      if (d <= StrokeTolerance.dotRadius && (best == null || d < best.score)) best = (index: i, score: d);
    }
    return best;
  }

  _Hit? _strokeAt(_Build b, List<Offset> dp, double length) {
    _Hit? best;
    for (int i = 0; i < b.strokes.length; i++) {
      final StrokeModel m = b.strokes[i];
      if (b.done[i] || m.kind == StrokeKind.dot) continue;
      final double? score = _matchScore(dp, length, m.points, m.kind, retrace: m.retrace);
      if (score != null && (best == null || score < best.score)) best = (index: i, score: score);
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
    for (final _Build b in _builds) {
      if (!b.alive) continue;
      for (int i = 0; i < b.strokes.length; i++) {
        final StrokeModel m = b.strokes[i];
        if (b.done[i] || m.kind == StrokeKind.dot || _mirrorIsAStroke(b.strokes, i)) continue;
        final double? score = _matchScore(dp, length, _mirrored(m.points), m.kind, retrace: m.retrace);
        if (score != null && (best == null || score < best)) best = score;
      }
    }
    return best;
  }

  /// The mirror image of stroke [i] is the stroke itself or another stroke of the letter: written mirrored it is no error that
  /// the mirror could name.
  static bool _mirrorIsAStroke(List<StrokeModel> strokes, int i) {
    final List<Offset> flipped = _mirrored(strokes[i].points);
    for (int k = 0; k < strokes.length; k++) {
      final StrokeModel o = strokes[k];
      if (o.kind == StrokeKind.dot) continue;
      final double limit = k == i ? StrokeTolerance.symmetricBelow : StrokeTolerance.pairedBelow;
      if (_meanDistance(flipped, o.points) < limit) return true;
    }
    // A stroke too narrow to show a hand (a stem, with or without a small flag) has no mirror image to name, wherever it stands.
    return strokeBounds(strokes[i].points).width < StrokeTolerance.extentMin;
  }

  /// A letter every stroke of which is its own mirror image or the mirror image of another (o, i, t, A, H, X, Cyrillic Tse): written mirrored it is the
  /// same letter, and no mirror error can be named for it.
  static bool mirrorsOntoItself(StrokeForm form) {
    for (int i = 0; i < form.strokes.length; i++) {
      if (form.strokes[i].kind != StrokeKind.dot && !_mirrorIsAStroke(form.strokes, i)) return false;
    }
    return true;
  }

  // ---- the whole drawing ----

  /// After the letter is whole and the child has stopped writing: the form of [forms] that the strokes [drawn] (every stroke the child
  /// made in this box, the ones that were taken and the ones that were not) write better than the target does, or null when the target is
  /// what they write. The stem of a t completes an l, the first stroke of a bet completes a resh, a c fits an a: so the whole is read, once,
  /// against every form and every build (QA-L52-4). A drawing that no other form reads whole, or that the target reads as well, is the target.
  StrokeForm? otherLetter(Iterable<StrokeForm> forms, List<List<Offset>> drawn) {
    if (drawn.isEmpty || drawn.length > 6) return null;
    final List<List<Offset>> dense = <List<Offset>>[for (final List<Offset> s in drawn) denseStroke(s)];
    StrokeForm? best;
    double bestFit = double.infinity;
    for (final StrokeForm f in forms) {
      if (f.id == form.id) continue;
      final double? fit = _wholeFit(f, dense);
      if (fit != null && fit < bestFit) {
        best = f;
        bestFit = fit;
      }
    }
    if (best == null) return null;
    final double? own = _wholeFit(form, dense);
    return own == null || bestFit + StrokeTolerance.wholeMargin < own ? best : null;
  }

  /// The mean score per stroke of the best build of [f] that the strokes [dense] read exactly (each stroke is one stroke of the build,
  /// and every stroke of the build is written), or null when no build does.
  static double? _wholeFit(StrokeForm f, List<List<Offset>> dense) {
    double? best;
    for (final List<StrokeModel> build in f.builds) {
      if (build.length != dense.length) continue;
      final double? fit = _assign(<List<double?>>[
        for (final List<Offset> dp in dense) <double?>[for (final StrokeModel m in build) _costOf(dp, m)],
      ]);
      if (fit != null && (best == null || fit < best)) best = fit;
    }
    return best;
  }

  static double? _costOf(List<Offset> dp, StrokeModel m) {
    final double length = strokeLength(dp);
    if (length < StrokeTolerance.tapUnits) {
      if (m.kind != StrokeKind.dot) return null;
      final double d = (dp.first - m.start).distance;
      return d <= StrokeTolerance.dotRadius ? d : null;
    }
    return m.kind == StrokeKind.dot ? null : _matchScore(dp, length, m.points, m.kind, retrace: m.retrace);
  }

  /// The cheapest way to give every stroke (a row of [cost]) a stroke of the build of its own (a column), as a mean per stroke, or null.
  static double? _assign(List<List<double?>> cost) {
    final int n = cost.length;
    final List<double> best = List<double>.filled(1 << n, double.infinity)..[0] = 0;
    for (int mask = 0; mask < (1 << n) - 1; mask++) {
      if (best[mask].isInfinite) continue;
      int row = 0; // the strokes given a place so far are the first `row` rows
      for (int bits = mask; bits > 0; bits &= bits - 1) {
        row++;
      }
      for (int col = 0; col < n; col++) {
        final double? c = cost[row][col];
        if (mask & (1 << col) != 0 || c == null) continue;
        best[mask | (1 << col)] = math.min(best[mask | (1 << col)], best[mask] + c);
      }
    }
    final double all = best[(1 << n) - 1];
    return all.isInfinite ? null : all / n;
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
  /// start, goes the same way, is of the model's size and shape, stays on its path, covers it and stops near its end (a short mark: starts
  /// near and goes the same way only).
  static double? _matchScore(
    List<Offset> dp,
    double length,
    List<Offset> model,
    StrokeKind kind, {
    bool retrace = false,
  }) {
    final bool ring = kind != StrokeKind.short && _isRing(model);
    final double startDist = ring ? distanceToPath(dp.first, model) : (dp.first - model.first).distance;
    if (startDist > StrokeTolerance.startRadius) return null;
    if (kind == StrokeKind.short) {
      final double modelLength = strokeLength(model);
      final double angle = _turn(dp.last - dp.first, model.last - model.first);
      if (angle > StrokeTolerance.firstMoveDegrees) return null;
      if (length < modelLength * StrokeTolerance.shortFraction ||
          length > math.max(modelLength * StrokeTolerance.shortRatio, 30)) {
        return null;
      }
      return startDist;
    }
    // A stroke that goes back over its own line (n, m, h, r, a, d) has no one early course to compare: its start, its band, its coverage and
    // its end decide, and the "wrong way" of it is begun at its other end.
    // A ring may be begun anywhere on it, so only the way round is compared; and it is closed: a c is no o.
    if (ring) {
      final Rect box = strokeBounds(dp);
      final double size = math.max(box.width, box.height);
      final double gap = (model.last - model.first).distance;
      if (_goesRound(dp) != _goesRound(model) ||
          (dp.last - dp.first).distance > math.max(size * StrokeTolerance.ringGapShare, gap + size * 0.35)) {
        return null;
      }
    } else if (!retrace && _firstMoveTurn(dp, model) > StrokeTolerance.firstMoveDegrees) {
      return null;
    }
    if (!_shapeFits(dp, model, retrace)) return null;
    final double mean = _meanDistance(dp, model);
    if (mean > StrokeTolerance.band || _covered(dp, model) < StrokeTolerance.coverage) return null;
    final double endDist = ring ? distanceToPath(dp.last, model) : (dp.last - model.last).distance;
    if (endDist > StrokeTolerance.endRadius) return null;
    return startDist + mean + endDist / 2;
  }

  /// The model comes back to where it began (and is long enough to be a ring, not a tick).
  static bool _isRing(List<Offset> model) =>
      (model.last - model.first).distance < StrokeTolerance.closedBelow && strokeLength(model) > 40;

  /// The way a ring goes round: 1 for clockwise on the screen (y down), -1 for counter-clockwise (the sign of its net turning).
  static int _goesRound(List<Offset> pts) {
    final List<Offset> p = resampleStroke(pts, 24);
    double turning = 0;
    for (int i = 2; i < p.length; i++) {
      final Offset a = p[i - 1] - p[i - 2];
      final Offset b = p[i] - p[i - 1];
      turning += a.dx * b.dy - a.dy * b.dx;
    }
    return turning >= 0 ? 1 : -1;
  }

  /// The stroke is as wide and as tall as the model, turns back on its line where the model does (a c is no a), and is no scribble.
  static bool _shapeFits(List<Offset> dp, List<Offset> model, bool retrace) {
    final Rect d = strokeBounds(dp);
    final Rect m = strokeBounds(model);
    bool reaches(double drawn, double modelled) =>
        modelled < StrokeTolerance.extentMin ||
        drawn >= modelled * StrokeTolerance.extentShare - StrokeTolerance.extentSlack;
    return reaches(d.width, m.width) &&
        reaches(d.height, m.height) &&
        (!retrace || sharpTurns(dp, StrokeTolerance.reversalDegrees) > 0) &&
        !_scribbly(dp, model, StrokeTolerance.longestRatio);
  }

  /// More loops or corners than the model has, or longer than [ratio] times the model: a scribble, or a spiral, is no letter.
  static bool _scribbly(List<Offset> dp, List<Offset> model, double ratio) =>
      strokeLength(dp) > strokeLength(model) * ratio ||
      selfCrossings(dp) > selfCrossings(model) + StrokeTolerance.scribbleCrossings ||
      sharpTurns(dp, StrokeTolerance.cornerDegrees) >
          sharpTurns(model, StrokeTolerance.cornerDegrees) + StrokeTolerance.scribbleCorners;

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

  static double _turn(Offset a, Offset b) => turnBetween(a, b);

  // ---- naming a miss ----

  /// Names what is wrong with a stroke that fits no stroke of the letter, its mirror image or a look-alike: the nearest model stroke that
  /// is not matched yet, and whether the stroke was begun far from its start or at its other end, begun right and going the wrong way
  /// round, or the right shape on the wrong lines. Only a stroke that is letter-like is named: not a scribble, and not a part of a
  /// stroke (the stem of a b is a piece of a build the model does not have), so a build that is not known is a retry with no name.
  StrokeVerdict _name(List<Offset> dp, double length) {
    StrokeFault? fault;
    double bestScore = double.infinity;
    final _Build on = _active;
    for (int i = 0; i < on.strokes.length; i++) {
      final StrokeModel m = on.strokes[i];
      if (on.done[i] || m.kind != StrokeKind.line) continue;
      // Only a stroke shaped like this model stroke is named (turning back where it turns back, no scribble, as wide and as tall once it is
      // moved onto the model's box): a c is no wrongly-begun a, and a scribble is no stroke of any letter. Anything else is a retry with no name.
      if (_scribbly(dp, m.points, StrokeTolerance.scribbleRatio)) continue;
      final double share = length / strokeLength(m.points);
      final double mean = _meanDistance(dp, m.points);
      if (share >= StrokeTolerance.partialShare &&
          share <= StrokeTolerance.wholeShare &&
          mean <= StrokeTolerance.looseBand &&
          _covered(dp, m.points, StrokeTolerance.looseBand) >= StrokeTolerance.looseCoverage &&
          _shapeFits(dp, m.points, m.retrace)) {
        // On the path but not a match: a ring that goes round the other way, a stroke begun right and ending at its end that went a different
        // way, or the stroke traced from its other end. A stroke that began or ended anywhere else is a build the check does not know.
        final StrokeFault? named = _onPathFault(dp, m.points);
        if (named != null && mean < bestScore) {
          bestScore = mean;
          fault = named;
        }
        continue;
      }
      // The right shape in the wrong place or size: moved onto the model's box it fits.
      final List<Offset> fitted = _onto(dp, m.points);
      final double shape = _meanDistance(fitted, m.points);
      final double fittedShare = strokeLength(fitted) / strokeLength(m.points);
      if (fittedShare < StrokeTolerance.partialShare ||
          fittedShare > StrokeTolerance.wholeShare ||
          !_shapeFits(fitted, m.points, m.retrace)) {
        continue;
      }
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

  /// The error of a stroke that lies on the model's path but did not match, or null when it is none the check can name.
  static StrokeFault? _onPathFault(List<Offset> dp, List<Offset> model) {
    if (_isRing(model)) return _goesRound(dp) == _goesRound(model) ? null : StrokeFault.direction;
    final bool startsHere = (dp.first - model.first).distance <= StrokeTolerance.startRadius;
    final bool endsHere = (dp.last - model.last).distance <= StrokeTolerance.endRadius;
    if (startsHere && endsHere) return StrokeFault.direction;
    final bool backwards =
        (dp.first - model.last).distance <= StrokeTolerance.startRadius &&
        (dp.last - model.first).distance <= StrokeTolerance.endRadius;
    return backwards ? StrokeFault.start : null;
  }

  /// [pts] reflected about the middle of the box (the letters are centred on it).
  static List<Offset> _mirrored(List<Offset> pts) => <Offset>[
    for (final Offset p in pts) Offset(100 - p.dx, p.dy),
  ];

  /// [pts] moved and stretched onto the bounding box of [model].
  static List<Offset> _onto(List<Offset> pts, List<Offset> model) {
    final Rect a = strokeBounds(pts);
    final Rect m = strokeBounds(model);
    return <Offset>[
      for (final Offset p in pts)
        Offset(
          a.width < 4 ? m.center.dx : m.left + (p.dx - a.left) / a.width * m.width,
          a.height < 4 ? m.center.dy : m.top + (p.dy - a.top) / a.height * m.height,
        ),
    ];
  }
}
