import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

// The small geometry of a stroke, shared by the tracing of the lands (T04) and by LS02: a finger path made dense, a path resampled to a
// fixed number of points, the distance from a point to a path. Everything is in the box of 100 by 100 units, y down. Pure functions.

/// A finger path with a point at least every two units, so that a fast stroke still covers the path.
List<Offset> denseStroke(List<Offset> pts) {
  final List<Offset> out = <Offset>[pts.first];
  for (int i = 1; i < pts.length; i++) {
    final Offset a = pts[i - 1];
    final Offset b = pts[i];
    final int n = math.max(1, ((b - a).distance / 2).ceil());
    for (int k = 1; k <= n; k++) {
      out.add(Offset.lerp(a, b, k / n)!);
    }
  }
  return out;
}

/// [count] points spread evenly along the polyline [pts].
List<Offset> resampleStroke(List<Offset> pts, int count) {
  final List<double> cum = <double>[0];
  for (int i = 1; i < pts.length; i++) {
    cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
  }
  final double total = cum.last;
  if (pts.length < 2 || total == 0) return List<Offset>.filled(count, pts.first);
  final List<Offset> out = <Offset>[];
  int seg = 1;
  for (int k = 0; k < count; k++) {
    final double d = total * k / (count - 1);
    while (seg < pts.length - 1 && cum[seg] < d) {
      seg++;
    }
    final double span = cum[seg] - cum[seg - 1];
    out.add(Offset.lerp(pts[seg - 1], pts[seg], span == 0 ? 0 : ((d - cum[seg - 1]) / span).clamp(0, 1))!);
  }
  return out;
}

/// The length of a polyline.
double strokeLength(List<Offset> pts) {
  double d = 0;
  for (int i = 1; i < pts.length; i++) {
    d += (pts[i] - pts[i - 1]).distance;
  }
  return d;
}

/// The distance from [p] to the polyline [path] (to its nearest segment, not only its nearest point).
double distanceToPath(Offset p, List<Offset> path) {
  double best = double.infinity;
  for (int i = 1; i < path.length; i++) {
    final Offset a = path[i - 1];
    final Offset ab = path[i] - a;
    final double len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final double t = len2 == 0 ? 0 : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0, 1);
    best = math.min(best, (p - (a + ab * t)).distance);
  }
  return path.length == 1 ? (p - path.first).distance : best;
}

/// The point [along] units from the start of the polyline (its end when it is shorter).
Offset pointAlong(List<Offset> pts, double along) {
  double walked = 0;
  for (int i = 1; i < pts.length; i++) {
    final double seg = (pts[i] - pts[i - 1]).distance;
    if (walked + seg >= along) {
      return Offset.lerp(pts[i - 1], pts[i], seg == 0 ? 0 : (along - walked) / seg)!;
    }
    walked += seg;
  }
  return pts.last;
}

/// What a finger path did against a path to follow (T04's check): it covers the path, stays near it, and begins at its start.
typedef PathVerdict = ({bool onPath, bool startsRight, bool startsAtEnd});

/// Reads a finger path [drawn] against [target], the path to follow, with the tolerance [tol] (box units). A path is on the path when the finger
/// covers at least 85% of it and at least 85% of the finger's points are near it; it begins right when it starts within 2.2 tolerances of the
/// start, and at the end when it starts there instead (the same path traced the other way).
PathVerdict pathVerdict(List<Offset> drawn, List<Offset> target, double tol) {
  final List<Offset> dense = denseStroke(drawn);
  final List<Offset> goal = resampleStroke(target, 32);
  int covered = 0;
  for (final Offset t in goal) {
    if (dense.any((Offset d) => (d - t).distance <= tol)) covered++;
  }
  int near = 0;
  for (final Offset d in dense) {
    if (goal.any((Offset t) => (d - t).distance <= tol * 1.6)) near++;
  }
  return (
    onPath: covered / goal.length >= 0.85 && near / dense.length >= 0.85,
    startsRight: (dense.first - goal.first).distance <= tol * 2.2,
    startsAtEnd: (dense.first - goal.last).distance <= tol * 2.2,
  );
}

/// The box round a polyline.
Rect strokeBounds(List<Offset> pts) {
  double left = pts.first.dx, top = pts.first.dy, right = left, bottom = top;
  for (final Offset p in pts) {
    left = math.min(left, p.dx);
    top = math.min(top, p.dy);
    right = math.max(right, p.dx);
    bottom = math.max(bottom, p.dy);
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// The angle between two directions, in degrees from 0 to 180 (180 when either has no length).
double turnBetween(Offset a, Offset b) {
  if (a.distance == 0 || b.distance == 0) return 180;
  final double d = (math.atan2(a.dy, a.dx) - math.atan2(b.dy, b.dx)).abs() * 180 / math.pi;
  return d > 180 ? 360 - d : d;
}

/// How many places a path turns by [degrees] or more within a short run (eight units either side of the place): a sharp corner (60
/// degrees) or a turn back on its own line (100 degrees, the n, the stem of an a). A run of such places is one. A smooth bowl of the
/// size of a letter never reaches 60 degrees over eight units, and a wobble of a shaking hand does not either.
int sharpTurns(List<Offset> pts, double degrees) {
  final double length = strokeLength(pts);
  if (length < 20) return 0;
  final int n = (length / 2).ceil() + 1;
  final List<Offset> p = resampleStroke(pts, n);
  final int w = math.max(2, (8 / (length / (n - 1))).round());
  int count = 0;
  int last = -1000;
  for (int i = w; i < n - w; i++) {
    if (turnBetween(p[i] - p[i - w], p[i + w] - p[i]) >= degrees) {
      if (i - last > w) count++;
      last = i;
    }
  }
  return count;
}

/// How many times a path crosses its own line at a real angle (55 to 125 degrees): the loops of a scribble. A path that goes back over
/// its line (the n) runs nearly alongside itself, and its wobble crosses at a shallow angle, which is no loop. Crossings next to each
/// other count once.
int selfCrossings(List<Offset> pts) {
  final double length = strokeLength(pts);
  if (length < 20) return 0;
  final List<Offset> p = resampleStroke(pts, math.min(80, (length / 3).ceil() + 1));
  int count = 0;
  int lastI = -100;
  for (int i = 0; i < p.length - 1; i++) {
    for (int j = i + 2; j < p.length - 1; j++) {
      if (_crossAtAngle(p[i], p[i + 1], p[j], p[j + 1])) {
        if (i - lastI > 3) count++;
        lastI = i;
      }
    }
  }
  return count;
}

bool _crossAtAngle(Offset a, Offset b, Offset c, Offset d) {
  double side(Offset p, Offset q, Offset r) => (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
  if (side(a, b, c) * side(a, b, d) >= 0 || side(c, d, a) * side(c, d, b) >= 0) return false;
  final double angle = turnBetween(b - a, d - c);
  return angle >= 55 && angle <= 125;
}
