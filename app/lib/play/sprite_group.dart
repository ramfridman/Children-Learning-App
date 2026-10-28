import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'template_session.dart';

/// Where the pictures of a counted group sit, in the unit square (0 to 1 in both directions), and the room each one
/// has. The same placement is used by every template that shows "some of a thing" (the sets of a comparison, the
/// flash of a ten-frame), so what the child sees is the same everywhere.
class GroupLayout {
  const GroupLayout(this.centers, this.cellWidth, this.cellHeight);

  final List<Offset> centers;
  final double cellWidth;
  final double cellHeight;
}

/// The ways to arrange a group: in a `line`, `scatter`ed on a loose grid, as the pips of a `dice`, or in a `ten_frame`
/// (two rows of five, filled row by row). A group of 0 is empty.
const List<String> groupArrangements = <String>['line', 'scatter', 'dice', 'ten_frame'];

GroupLayout groupLayout(String arrangement, int count, {int seed = 0}) {
  if (count <= 0) return const GroupLayout(<Offset>[], 1, 1);
  switch (arrangement) {
    case 'dice':
      if (count <= 6) return GroupLayout(_dice(count), 0.3, 0.3);
      return groupLayout('ten_frame', count, seed: seed);
    case 'ten_frame':
      return GroupLayout(
        <Offset>[for (int i = 0; i < count; i++) Offset(((i % 5) + 0.5) / 5, ((i ~/ 5) + 0.5) / 2)],
        0.2,
        0.5,
      );
    case 'scatter':
      const int cols = 5;
      const int rows = 3;
      final List<int> cells = <int>[for (int i = 0; i < cols * rows; i++) i]..shuffle(math.Random(seed));
      final math.Random jitter = math.Random(seed + 7);
      return GroupLayout(
        <Offset>[
          for (final int c in cells.take(math.min(count, cols * rows)))
            Offset(
              ((c % cols) + 0.5 + (jitter.nextDouble() - 0.5) * 0.3) / cols,
              ((c ~/ cols) + 0.5 + (jitter.nextDouble() - 0.5) * 0.3) / rows,
            ),
        ],
        1 / cols,
        1 / rows,
      );
    default:
      return GroupLayout(
        <Offset>[for (int i = 0; i < count; i++) Offset((i + 0.5) / count, 0.5)],
        1 / count,
        1,
      );
  }
}

List<Offset> _dice(int n) {
  const double a = 0.2;
  const double b = 0.5;
  const double c = 0.8;
  return switch (n) {
    1 => const <Offset>[Offset(b, b)],
    2 => const <Offset>[Offset(a, a), Offset(c, c)],
    3 => const <Offset>[Offset(a, a), Offset(b, b), Offset(c, c)],
    4 => const <Offset>[Offset(a, a), Offset(c, a), Offset(a, c), Offset(c, c)],
    5 => const <Offset>[Offset(a, a), Offset(c, a), Offset(b, b), Offset(a, c), Offset(c, c)],
    _ => const <Offset>[Offset(a, a), Offset(a, b), Offset(a, c), Offset(c, a), Offset(c, b), Offset(c, c)],
  };
}

/// [count] pictures of [svg] in the given arrangement. [scale] makes every picture bigger or smaller (the "crowded or
/// large objects" of a comparison); the group never changes its count.
class SpriteGroup extends StatelessWidget {
  const SpriteGroup({
    super.key,
    required this.svg,
    required this.count,
    this.arrangement = 'line',
    this.seed = 0,
    this.scale = 1,
  });

  final String svg;
  final int count;
  final String arrangement;
  final int seed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final GroupLayout layout = groupLayout(arrangement, count, seed: seed);
    return LayoutBuilder(
      builder: (BuildContext c, BoxConstraints box) {
        double w = box.maxWidth.isFinite ? box.maxWidth : 200;
        double h = box.maxHeight.isFinite ? box.maxHeight : 100;
        // The pips of a dice sit in a square, however wide the room is.
        final bool square = arrangement == 'dice' && count <= 6;
        final double dx = square ? (w - math.min(w, h)) / 2 : 0;
        final double dy = square ? (h - math.min(w, h)) / 2 : 0;
        if (square) {
          w = h = math.min(w, h);
        }
        final double side = math.min(layout.cellWidth * w, layout.cellHeight * h) * 0.85 * scale;
        return Stack(
          children: <Widget>[
            for (final Offset p in layout.centers)
              Positioned(
                left: dx + p.dx * w - side / 2,
                top: dy + p.dy * h - side / 2,
                width: side,
                height: side,
                child: PackSvg(svg),
              ),
          ],
        );
      },
    );
  }
}
