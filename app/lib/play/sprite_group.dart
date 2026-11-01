import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.g.dart';
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
///
/// A `line` has room for at least [lineSlots] pictures, so that groups of different sizes shown together have pictures of the
/// same size: by default four, and the largest group's count where every group of a screen is drawn in one row of its own.
const List<String> groupArrangements = <String>['line', 'scatter', 'dice', 'ten_frame'];

GroupLayout groupLayout(String arrangement, int count, {int seed = 0, int lineSlots = 4}) {
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
        // A group of one or two is not drawn larger than a group of four: sizes must compare fairly.
        <Offset>[
          for (int i = 0; i < count; i++)
            Offset(0.5 + (i - (count - 1) / 2) / math.max(count, lineSlots), 0.5),
        ],
        1 / math.max(count, lineSlots),
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

/// The place of each picture of a group inside a box of [box] (the same numbers [SpriteGroup] draws with, so that a hint can ring
/// a picture it did not draw itself).
List<Rect> spriteRects(
  Size box,
  String arrangement,
  int count, {
  int seed = 0,
  double scale = 1,
  int lineSlots = 4,
}) {
  final GroupLayout layout = groupLayout(arrangement, count, seed: seed, lineSlots: lineSlots);
  final Rect? frame = tenFrameRect(box, arrangement, count);
  if (frame != null) {
    // Square cells of the drawn frame; each picture fills most of its cell, so the frame's lines show between them.
    final double cell = frame.width / 5;
    final double side = cell * 0.78 * scale;
    return <Rect>[
      for (int i = 0; i < count; i++)
        Rect.fromCenter(
          center: frame.topLeft + Offset(((i % 5) + 0.5) * cell, ((i ~/ 5) + 0.5) * cell),
          width: side,
          height: side,
        ),
    ];
  }
  double w = box.width;
  double h = box.height;
  // The pips of a dice sit in a square, however wide the room is.
  final bool square = arrangement == 'dice' && count <= 6;
  final double dx = square ? (w - math.min(w, h)) / 2 : 0;
  final double dy = square ? (h - math.min(w, h)) / 2 : 0;
  if (square) {
    w = h = math.min(w, h);
  }
  final double side = math.min(layout.cellWidth * w, layout.cellHeight * h) * 0.85 * scale;
  return <Rect>[
    for (final Offset p in layout.centers)
      Rect.fromLTWH(dx + p.dx * w - side / 2, dy + p.dy * h - side / 2, side, side),
  ];
}

/// Whether a group is drawn on a ten-frame: a `ten_frame`, and a `dice` of more than six (which falls back to one).
bool drawsTenFrame(String arrangement, int count) =>
    arrangement == 'ten_frame' || (arrangement == 'dice' && count > 6);

/// The ten-frame of a group inside a box of [box]: two rows of five square cells (more rows only for a group of more than ten),
/// as large as the box allows and centred in it; null when the group is not drawn on a frame. The empty cells are part of the
/// picture: "five, and five more make ten" is seen in the cells that are left.
Rect? tenFrameRect(Size box, String arrangement, int count) {
  if (!drawsTenFrame(arrangement, count)) return null;
  final int rows = math.max(2, (count / 5).ceil());
  // A little room round the frame for its outline.
  final double w = box.width - 4;
  final double h = box.height - 4;
  if (w <= 0 || h <= 0) return null;
  final double cell = math.min(w / 5, h / rows);
  return Rect.fromLTWH((box.width - cell * 5) / 2, (box.height - cell * rows) / 2, cell * 5, cell * rows);
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
    this.lineSlots = 4,
  });

  final String svg;
  final int count;
  final String arrangement;
  final int seed;
  final double scale;

  /// See [groupLayout].
  final int lineSlots;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext c, BoxConstraints box) {
      final Size room = Size(
        box.maxWidth.isFinite ? box.maxWidth : 200,
        box.maxHeight.isFinite ? box.maxHeight : 100,
      );
      final List<Rect> places = spriteRects(
        room,
        arrangement,
        count,
        seed: seed,
        scale: scale,
        lineSlots: lineSlots,
      );
      final Rect? frame = tenFrameRect(room, arrangement, count);
      return Stack(
        children: <Widget>[
          if (frame != null)
            Positioned.fromRect(
              key: const Key('group-ten-frame'),
              rect: frame,
              child: CustomPaint(painter: _TenFramePainter(rows: (frame.height / (frame.width / 5)).round())),
            ),
          for (final Rect r in places) Positioned.fromRect(rect: r, child: PackSvg(svg)),
        ],
      );
    },
  );
}

/// The ten-frame under a group: a white board with an ink rim and soft lines between its cells (the same look as the ten-frames
/// of the hints), so that the empty cells can be counted too.
class _TenFramePainter extends CustomPainter {
  const _TenFramePainter({required this.rows});

  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 5;
    final double rim = (cell * 0.07).clamp(2.0, 3.5);
    final Rect board = Offset.zero & size;
    final RRect outer = RRect.fromRectAndRadius(board.deflate(rim / 2), Radius.circular(cell * 0.12));
    canvas.drawRRect(outer, Paint()..color = TokenColors.paper.withValues(alpha: 0.94));
    final Paint line = Paint()
      ..color = TokenColors.ink.withValues(alpha: 0.28)
      ..strokeWidth = (rim * 0.6).clamp(1.5, 2.0);
    for (int c = 1; c < 5; c++) {
      canvas.drawLine(Offset(c * cell, rim), Offset(c * cell, size.height - rim), line);
    }
    for (int r = 1; r < rows; r++) {
      canvas.drawLine(Offset(rim, r * cell), Offset(size.width - rim, r * cell), line);
    }
    canvas.drawRRect(
      outer,
      Paint()
        ..color = TokenColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim,
    );
  }

  @override
  bool shouldRepaint(_TenFramePainter old) => old.rows != rows;
}
