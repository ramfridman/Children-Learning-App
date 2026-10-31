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

/// The outline of the picture [svg], or null for one that has no corners (a circle, a solid).
SpriteOutline? outlineOf(String svg) {
  final RegExpMatch? poly = RegExp(r'<(polygon|polyline)\b[^>]*\bpoints="([^"]*)"').firstMatch(svg);
  if (poly != null) {
    final List<double> n = <double>[
      for (final RegExpMatch m in RegExp(r'-?\d+\.?\d*').allMatches(poly[2]!)) double.parse(m[0]!),
    ];
    return SpriteOutline(<Offset>[
      for (int i = 0; i + 1 < n.length; i += 2) Offset(n[i] / 100, n[i + 1] / 100),
    ], closed: poly[1] == 'polygon');
  }
  final RegExpMatch? rect = RegExp(r'<rect\b([^>]*)>').firstMatch(svg);
  if (rect != null) {
    double v(String name) =>
        double.tryParse(RegExp('\\b$name="(-?[\\d.]+)"').firstMatch(rect[1]!)?[1] ?? '') ?? 0;
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
  // The one curved shape of the pack: a quadratic curve from one corner to another and a straight side back (M x y Q cx cy x y Z).
  final RegExpMatch? curve = RegExp(
    r'<path\b[^>]*\bd="M\s*(-?[\d.]+)[\s,]+(-?[\d.]+)\s*Q\s*(-?[\d.]+)[\s,]+(-?[\d.]+)[\s,]+(-?[\d.]+)[\s,]+(-?[\d.]+)',
  ).firstMatch(svg);
  if (curve != null) {
    final List<double> c = <double>[for (int i = 1; i <= 6; i++) double.parse(curve[i]!) / 100];
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
  return null;
}
