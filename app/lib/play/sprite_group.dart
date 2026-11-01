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
      // Two rows of five; a group of more than ten (drawn with no frame) goes on with more rows.
      final int rows = math.max(2, (count / 5).ceil());
      return GroupLayout(
        <Offset>[for (int i = 0; i < count; i++) Offset(((i % 5) + 0.5) / 5, ((i ~/ 5) + 0.5) / rows)],
        0.2,
        1 / rows,
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

/// How much of its cell a picture fills at scale 1: on a ten-frame most of it (the frame's lines show between the pictures), in
/// any other arrangement a little less than all of it.
const double _frameFill = 0.78;
const double _cellFill = 0.85;

/// The place of each picture of a group inside a box of [box] (the same numbers [SpriteGroup] draws with, so that a hint can ring
/// a picture it did not draw itself). A picture is never larger than its cell, whatever [scale] asks (QA-38-3). With [framed]
/// false a ten-frame is not drawn: its pictures stand on the same grid with no board under them.
List<Rect> spriteRects(
  Size box,
  String arrangement,
  int count, {
  int seed = 0,
  double scale = 1,
  int lineSlots = 4,
  bool framed = true,
}) {
  final GroupLayout layout = groupLayout(arrangement, count, seed: seed, lineSlots: lineSlots);
  final List<Rect> frames = tenFrameRects(box, arrangement, count, framed: framed);
  if (frames.isNotEmpty) {
    // Square cells of the drawn frames; each picture fills most of its cell, so the lines of the frame show between them.
    final double cell = frames.first.width / 5;
    final double side = cell * _frameFill * math.min(scale, 1 / _frameFill);
    return <Rect>[
      for (int i = 0; i < count; i++)
        Rect.fromCenter(
          center: frames[i ~/ 10].topLeft + Offset(((i % 10 % 5) + 0.5) * cell, ((i % 10 ~/ 5) + 0.5) * cell),
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
  final double side =
      math.min(layout.cellWidth * w, layout.cellHeight * h) * _cellFill * math.min(scale, 1 / _cellFill);
  return <Rect>[
    for (final Offset p in layout.centers)
      Rect.fromLTWH(dx + p.dx * w - side / 2, dy + p.dy * h - side / 2, side, side),
  ];
}

/// Whether a group is drawn on a ten-frame: a `ten_frame`, and a `dice` of more than six (which falls back to one).
bool drawsTenFrame(String arrangement, int count) =>
    arrangement == 'ten_frame' || (arrangement == 'dice' && count > 6);

/// The ten-frames of a group inside a box of [box], left to right: each is two rows of five square cells. A group of more than ten
/// is a full frame and the rest (the same as the hint's `TenFrames`), as large as the box allows and centred in it. Empty when the
/// group is not drawn on a frame, or when [framed] is false. The empty cells are part of the picture: "five, and five more make
/// ten" is seen in the cells that are left.
List<Rect> tenFrameRects(Size box, String arrangement, int count, {bool framed = true}) {
  if (!framed || !drawsTenFrame(arrangement, count)) return const <Rect>[];
  final int frames = math.max(1, (count / 10).ceil());
  // A little room round the frames for their outline.
  final double w = box.width - 4;
  final double h = box.height - 4;
  if (w <= 0 || h <= 0) return const <Rect>[];
  // The frames are five cells wide, with a gap of 0.6 of a cell between two.
  final double across = 5.0 * frames + _frameGap * (frames - 1);
  final double cell = math.min(w / across, h / 2);
  final double left = (box.width - cell * across) / 2;
  final double top = (box.height - cell * 2) / 2;
  return <Rect>[
    for (int f = 0; f < frames; f++)
      Rect.fromLTWH(left + f * (5 + _frameGap) * cell, top, cell * 5, cell * 2),
  ];
}

const double _frameGap = 0.6;

/// [count] pictures of [svg] in the given arrangement. [scale] makes every picture bigger or smaller (the "crowded or
/// large objects" of a comparison, never past its cell); the group never changes its count.
///
/// A ten-frame is drawn with its board unless [framed] is false. Answers to be told apart are all drawn with no board (see
/// `answerGroupsFramed`): a board on one of them and not on another would tell the child which one is right (QA-38-1).
class SpriteGroup extends StatelessWidget {
  const SpriteGroup({
    super.key,
    required this.svg,
    required this.count,
    this.arrangement = 'line',
    this.seed = 0,
    this.scale = 1,
    this.lineSlots = 4,
    this.framed = true,
  });

  final String svg;
  final int count;
  final String arrangement;
  final int seed;
  final double scale;

  /// See [groupLayout].
  final int lineSlots;
  final bool framed;

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
        framed: framed,
      );
      return Stack(
        children: <Widget>[
          // Absolute places, so a pair of frames stands first-on-the-left whatever the direction around it.
          for (final (int i, Rect frame) in tenFrameRects(room, arrangement, count, framed: framed).indexed)
            Positioned.fromRect(
              key: Key('group-ten-frame${i == 0 ? '' : '-$i'}'),
              rect: frame,
              child: const CustomPaint(painter: _TenFramePainter()),
            ),
          for (final Rect r in places) Positioned.fromRect(rect: r, child: PackSvg(svg)),
        ],
      );
    },
  );
}

/// One ten-frame under a group: a white board of 2 by 5 cells with an ink rim and soft lines between its cells (the same look as
/// the ten-frames of the hints), so that the empty cells can be counted too.
class _TenFramePainter extends CustomPainter {
  const _TenFramePainter();

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
    canvas.drawLine(Offset(rim, cell), Offset(size.width - rim, cell), line);
    canvas.drawRRect(
      outer,
      Paint()
        ..color = TokenColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim,
    );
  }

  @override
  bool shouldRepaint(_TenFramePainter old) => false;
}
