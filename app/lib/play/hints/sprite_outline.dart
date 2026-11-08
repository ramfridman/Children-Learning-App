import 'dart:ui';

// The corners of the flat shapes of the pack, read from their pictures (B-40, Band B). A hint that lights the sides of a shape, or
// lays out the sides of the options next to each other, needs where the corners are; the pictures of the shapes are plain
// polygons, rectangles and one curved shape, drawn in a 100 by 100 box.

/// A shape's corners in parts of its box (0 to 1 each way), and whether its last side comes back to the first corner.
class SpriteOutline {
  const SpriteOutline(this.points, {required this.closed});

  final List<Offset> points;
  final bool closed;

  /// The number of sides: one for each pair of neighbours (and the one that closes it).
  int get sides => closed ? points.length : points.length - 1;

  /// The length of side [i] in parts of the box.
  double sideLength(int i) => (points[(i + 1) % points.length] - points[i]).distance;

  /// The corners of this outline when the shape's picture fills [box].
  List<Offset> inBox(Rect box) => <Offset>[
    for (final Offset p in points) Offset(box.left + p.dx * box.width, box.top + p.dy * box.height),
  ];
}

/// A picture longer than this is not read at all (the pack pictures are a few KB), so a hostile one cannot make a reader slow.
const int maxReadableSvgChars = 64 * 1024;

/// The longest run of attributes read inside one tag; the longest tag of a pack picture is about 4.3 KB.
const int maxSvgTagChars = 8192;

/// The tags of [svg] named in [names] (a regular-expression alternative such as `rect|circle`), each with the text of its
/// attributes. A tag with no `>` before the next `<`, or with more than [maxSvgTagChars] of attributes, is skipped, and each
/// character is looked at a few times at most, however the picture is cut.
Iterable<(String, String)> svgTags(String svg, String names) sync* {
  int gt = -1;
  for (final RegExpMatch m in RegExp('<($names)\\b').allMatches(svg)) {
    if (gt < m.end) gt = svg.indexOf('>', m.end);
    if (gt < 0) return;
    final int lt = svg.indexOf('<', m.end);
    if ((lt >= 0 && lt < gt) || gt - m.end > maxSvgTagChars) continue;
    yield (m[1]!, svg.substring(m.end, gt));
  }
}

/// The outline of the picture [svg], or null for one that has no corners (a circle, a solid, a picture too long to read). Kept
/// once for each picture.
SpriteOutline? outlineOf(String svg) {
  if (svg.length > maxReadableSvgChars) return null;
  if (_outlines.containsKey(svg)) return _outlines[svg];
  return _outlines[svg] = _readOutline(svg);
}

final Map<String, SpriteOutline?> _outlines = <String, SpriteOutline?>{};

SpriteOutline? _readOutline(String svg) {
  for (final (String name, String at) in svgTags(svg, 'polygon|polyline')) {
    final RegExpMatch? points = RegExp(r'\bpoints="([^"]*)"').firstMatch(at);
    if (points == null) continue;
    final List<double> n = <double>[
      for (final RegExpMatch m in RegExp(r'-?\d+\.?\d*').allMatches(points[1]!)) ?double.tryParse(m[0]!),
    ];
    return SpriteOutline(<Offset>[
      for (int i = 0; i + 1 < n.length; i += 2) Offset(n[i] / 100, n[i + 1] / 100),
    ], closed: name == 'polygon');
  }
  for (final (String _, String at) in svgTags(svg, 'rect')) {
    double v(String name) => double.tryParse(RegExp('\\b$name="(-?[\\d.]+)"').firstMatch(at)?[1] ?? '') ?? 0;
    final double x = v('x') / 100;
    final double y = v('y') / 100;
    final double w = v('width') / 100;
    final double h = v('height') / 100;
    return SpriteOutline(<Offset>[
      Offset(x, y),
      Offset(x + w, y),
      Offset(x + w, y + h),
      Offset(x, y + h),
    ], closed: true);
  }
  // The pictures of the pack draw each shape as a path: the first `<path>` is the outline (the clip, the fill and the stroke repeat it).
  final (String, String)? first = svgTags(svg, 'path').firstOrNull;
  final String? d = first == null ? null : RegExp(r'\bd="([^"]*)"').firstMatch(first.$2)?[1];
  if (d == null) return null;
  return _readCurve(d) ?? _readStraightPath(d);
}

/// The one curved shape of the pack: a quadratic curve from one corner to another and a straight side back (M x y Q cx cy x y Z).
SpriteOutline? _readCurve(String d) {
  final RegExpMatch? curve = RegExp(
    r'^M\s*(-?[\d.]+)[\s,]+(-?[\d.]+)\s*Q\s*(-?[\d.]+)[\s,]+(-?[\d.]+)[\s,]+(-?[\d.]+)[\s,]+(-?[\d.]+)',
  ).firstMatch(d);
  if (curve == null) return null;
  final List<double?> read = <double?>[for (int i = 1; i <= 6; i++) double.tryParse(curve[i]!)];
  if (read.contains(null)) return null;
  final List<double> c = <double>[for (final double? v in read) v! / 100];
  const int steps = 10;
  return SpriteOutline(<Offset>[
    for (int i = 0; i <= steps; i++)
      () {
        final double t = i / steps;
        final double u = 1 - t;
        return Offset(
          u * u * c[0] + 2 * u * t * c[2] + t * t * c[4],
          u * u * c[1] + 2 * u * t * c[3] + t * t * c[5],
        );
      }(),
  ], closed: true);
}

/// A path of straight sides and rounded corners (absolute `M L H V C Z`, one subpath) as its corners; a rounded corner is where
/// the two straight sides it joins would meet. Any other command (an arc, a relative move, two curves in a row) gives null.
SpriteOutline? _readStraightPath(String d) {
  final List<Offset> corners = <Offset>[];
  Offset at = Offset.zero;
  bool closed = false;
  bool afterCurve = false;
  String? command;
  final List<double> args = <double>[];

  // Takes [need] numbers off [args] for each use of the command; false when the path is not of this kind.
  bool run() {
    final String? c = command;
    if (c == null) return true;
    final int need = switch (c) {
      'M' || 'L' => 2,
      'H' || 'V' => 1,
      'C' => 6,
      'Z' => 0,
      _ => -1,
    };
    if (need < 0 || (need == 0 ? args.isNotEmpty : args.isEmpty || args.length % need != 0)) return false;
    if (closed || (c == 'M' && corners.isNotEmpty) || (c != 'M' && corners.isEmpty)) return false;
    if (c == 'Z') {
      closed = true;
      return true;
    }
    for (int i = 0; i < args.length; i += need) {
      final Offset from = at;
      switch (c) {
        case 'M' || 'L':
          at = Offset(args[i], args[i + 1]);
          corners.add(at);
          afterCurve = false;
        case 'H':
          at = Offset(args[i], from.dy);
          corners.add(at);
          afterCurve = false;
        case 'V':
          at = Offset(from.dx, args[i]);
          corners.add(at);
          afterCurve = false;
        case 'C':
          // The curve starts at the last corner; that corner moves to where the sides before and after the curve meet.
          if (afterCurve) return false;
          final Offset end = Offset(args[i + 4], args[i + 5]);
          final Offset? meet = _meet(
            from,
            Offset(args[i], args[i + 1]),
            end,
            Offset(args[i + 2], args[i + 3]),
          );
          if (meet == null) return false;
          corners[corners.length - 1] = meet;
          at = end;
          afterCurve = true;
      }
    }
    args.clear();
    return true;
  }

  for (final RegExpMatch m in RegExp(r'([A-Za-z])|(-?(?:\d+\.?\d*|\.\d+))').allMatches(d)) {
    if (m[1] != null) {
      if (!run()) return null;
      command = m[1]!;
    } else {
      final double? v = double.tryParse(m[2]!);
      if (v == null) return null;
      args.add(v);
    }
  }
  if (!run()) return null;
  if (closed && corners.length > 1 && corners.last == corners.first) corners.removeLast();
  if (corners.length < (closed ? 3 : 2)) return null;
  return SpriteOutline(<Offset>[for (final Offset p in corners) p / 100], closed: closed);
}

/// Where the line from [p] through [p1] meets the line from [q] through [q1]; null when they run side by side.
Offset? _meet(Offset p, Offset p1, Offset q, Offset q1) {
  final Offset a = p1 - p;
  final Offset b = q1 - q;
  final double cross = a.dx * b.dy - a.dy * b.dx;
  if (cross.abs() < 1e-9) return null;
  final Offset pq = q - p;
  final double t = (pq.dx * b.dy - pq.dy * b.dx) / cross;
  return p + a * t;
}
