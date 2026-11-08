import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

// The one cube of the base-ten blocks (docs/design/c1-blocks.md section 4, the owner's choice of 2026-11-07: rods of ten linked cubes,
// colourway "sea"). A loose one and a cube in a rod are the same drawing at the same size; a rod is ten of them touching, over a dark spine
// that shows at every join, so that a child who counts the cubes of a rod counts the same cubes as the loose ones. The drawing is here, the
// places of the blocks are `BaseTenLayout` (stage_pictures.dart), and the opening demonstration (block_demo.dart) moves these same cubes.

/// The colours of one cube: its body, its dark edge (the joins of a rod are drawn with it), the shine on top and the side face.
class CubeColours {
  const CubeColours({required this.body, required this.edge, required this.shine, required this.side});

  final Color body;
  final Color edge;
  final Color shine;
  final Color side;

  /// "Sea" (the owner's choice). The edge is `seaDeep` half-way to `ink`: 3.0 to 1 against the body, where `seaDeep` alone gives 1.85 to 1,
  /// so that every join of a rod can be seen.
  static const CubeColours sea = CubeColours(
    body: TokenColors.sea,
    edge: Color(0xFF1D485D),
    shine: Color(0xFF7FD3CF),
    side: Color(0xFF13827E),
  );

  /// The hint draws the whole picture in its sky, as it always did.
  static final CubeColours sky = CubeColours(
    body: TokenColors.sky,
    edge: TokenColors.skyDeep,
    shine: Color.lerp(TokenColors.sky, TokenColors.paper, 0.55)!,
    side: Color.lerp(TokenColors.sky, TokenColors.skyDeep, 0.5)!,
  );

  CubeColours withAlpha(double alpha) => CubeColours(
    body: body.withValues(alpha: alpha),
    edge: edge.withValues(alpha: alpha),
    shine: shine.withValues(alpha: alpha),
    side: side.withValues(alpha: alpha),
  );
}

/// The width of the dark edge and of every join: at least 1.2 points, 0.09 of a cube's side above 13; never more than 0.14 of the side, so
/// that the small cubes of a hint's card are not all edge.
double cubeEdgeWidth(double u) => math.min(math.max(1.2, 0.09 * u), 0.14 * u);

/// How far the side face runs down the right of a cube or a rod.
double cubeSideWidth(double u) => 0.16 * u;

RRect _rr(double x, double y, double w, double h, double radius) =>
    RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(radius));

Paint _fill(Color c) => Paint()..color = c;

void _body(Canvas canvas, double x, double y, double u, double width, CubeColours c) {
  final double sw = cubeEdgeWidth(u);
  final RRect body = _rr(x + sw / 2, y + sw / 2, width - sw, u - sw, 0.2 * u);
  canvas.drawRRect(body, _fill(c.body));
  canvas.drawRRect(
    body,
    Paint()
      ..color = c.edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawRRect(
    _rr(x + 0.2 * u, y + 0.17 * u, 0.42 * u, math.max(1.2, 0.13 * u), 0.06 * u),
    _fill(c.shine.withValues(alpha: c.shine.a * 0.8)),
  );
}

/// One loose cube in the square [cell] (its side is the unit): a side face, then the body with its dark edge and its shine.
void paintCube(Canvas canvas, Rect cell, CubeColours c) {
  final double u = cell.width;
  canvas.drawRRect(_rr(cell.left, cell.top, u, u, 0.2 * u), _fill(c.side));
  _body(canvas, cell.left, cell.top, u, u - cubeSideWidth(u), c);
}

/// A rod in [rod] (one unit wide, ten tall): ten cubes that touch, over a spine in the edge colour that shows through the rounded
/// corners at every join (a notch on both sides), and one side face down the whole right of it, which makes the ten one thing.
void paintRod(Canvas canvas, Rect rod, CubeColours c) {
  final double u = rod.width;
  final double sw = cubeEdgeWidth(u);
  final double side = cubeSideWidth(u);
  canvas.drawRRect(_rr(rod.left + 0.12 * u, rod.top + 0.1 * u, 0.76 * u, 9.8 * u, 0.1 * u), _fill(c.edge));
  canvas.drawRRect(
    _rr(rod.left + u - side - sw, rod.top + 0.15 * u, side + sw, 9.7 * u, 0.12 * u),
    _fill(c.side),
  );
  for (int k = 0; k < 10; k++) {
    _body(canvas, rod.left, rod.top + k * u, u, u - side, c);
  }
}

/// The glow of a lit rod (the one the question is about): a wide glow, a tint and a ring that is a shape, so the cue is not colour alone.
void paintRodGlow(Canvas canvas, Rect rod) {
  final double u = rod.width;
  canvas.drawRRect(
    RRect.fromRectAndRadius(rod.inflate(0.65 * u), Radius.circular(0.9 * u)),
    _fill(TokenColors.spark.withValues(alpha: 0.55)),
  );
  final RRect tint = RRect.fromRectAndRadius(rod.inflate(0.35 * u), Radius.circular(0.6 * u));
  canvas.drawRRect(tint, _fill(TokenColors.sparkTint));
  canvas.drawRRect(
    tint,
    Paint()
      ..color = TokenColors.sparkDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, 0.2 * u),
  );
}

/// The glow of one lit cube (the demonstration counts the cubes of ten): a ring of the same kind, round the cube.
void paintCubeGlow(Canvas canvas, Rect cell) {
  final double u = cell.width;
  canvas.drawRRect(
    RRect.fromRectAndRadius(cell.inflate(0.3 * u), Radius.circular(0.4 * u)),
    _fill(TokenColors.spark.withValues(alpha: 0.6)),
  );
}

/// A tall cross over [rod] (taken away): it stays inside the rod's own gaps (half a unit wide, so that four crossed rods never run into
/// one "XXXX"), an under-stroke of paper and a stroke of ink, with round caps.
void paintRodCross(Canvas canvas, Rect rod) {
  final double u = rod.width;
  final Offset c = rod.center;
  final Path cross = Path()
    ..moveTo(c.dx - 0.45 * u, c.dy - 1.3 * u)
    ..lineTo(c.dx + 0.45 * u, c.dy + 1.3 * u)
    ..moveTo(c.dx + 0.45 * u, c.dy - 1.3 * u)
    ..lineTo(c.dx - 0.45 * u, c.dy + 1.3 * u);
  Paint stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(cross, stroke(TokenColors.paper, math.max(4.2, 0.34 * u)));
  canvas.drawPath(cross, stroke(TokenColors.ink, math.max(2.4, 0.19 * u)));
}

/// An empty place a block will come to (a faint outline): a hint leaves the part still to be found as outlines.
void paintPlace(Canvas canvas, Rect cell, {double radius = 0.2}) {
  final double u = cell.width;
  canvas.drawRRect(
    RRect.fromRectAndRadius(cell, Radius.circular(radius * u)),
    Paint()
      ..color = TokenColors.skyDeep.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, u * 0.12),
  );
}
