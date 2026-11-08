import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../child/activity_shell.dart';
import '../../content/models.dart';
import '../../content/row_width.dart';
import '../../design/course_text.dart';
import '../number_entry.dart' show KeypadLayout;
import '../sprite_group.dart';
import '../size_scale.dart';
import '../stage_picture.dart';
import '../stage_pictures.dart';

/// Where the things of a `tap_answer` stage and of its answer tiles are, in the stage's own points ((0, 0) is the stage's top left
/// corner). The stage draws its group, row and numeral with the same numbers (see `tap_answer_session.dart`), so a hint can light
/// a thing it did not draw itself, and the hand's fingertip can end on the top edge of an answer tile.
class TapGeometry {
  const TapGeometry(this.a, this.size, this.spec, {this.reserve = 0, this.dir = TextDirection.rtl});

  final TapAnswerActivity a;

  /// The stage's size, the screen's layout numbers (where the tiles are), and the direction the row of tiles runs in.
  final Size size;
  final ActivitySpec spec;
  final TextDirection dir;

  /// How much of the stage's end side (the left) a card takes; the group then stands in the rest.
  final double reserve;

  TapGeometry withReserve(double r) => TapGeometry(a, size, spec, reserve: r, dir: dir);

  double get w => size.width;
  double get h => size.height;

  // ---- the stage's own things ----

  /// True when the group stands above the stage's own options (the options are on the stage, not on tiles).
  bool get _groupAboveOptions => a.group != null && !a.optionsInTiles;

  /// True when the stage shows pictures and a row of numbers together (a number sentence over its two ten-frames): the pictures take the
  /// top of the stage and the row the bottom, so that the row is never drawn over a picture.
  static bool groupAndRow(TapAnswerActivity a) =>
      (a.group != null || stagePictureOf(a) != null) &&
      (a.row.isNotEmpty || a.numberAnswer != null) &&
      a.optionsInTiles;

  /// The kind of the stage picture a session draws (`base_ten` or `hundred_chart`, see `stage_pictures.dart`), or null when the
  /// activity has none, or one of a kind that no session draws yet.
  static String? stagePictureOf(TapAnswerActivity a) => a.drawnPictureKind;

  /// The share of the stage's height the pictures take when a row stands under them (see [groupAndRow]).
  static const double pictureShare = 0.6;

  /// The room kept round the pictures of a group and round each picture's cell: a stage that holds a row under them has little height
  /// to spare, so it takes less.
  /// A picture of blocks keeps a margin of 6 on the stage (docs/design/c1-blocks.md section 5.1) and its cells touch the margin.
  static double groupInsetOf(TapAnswerActivity a) => stagePictureOf(a) == 'base_ten'
      ? BaseTenLayout.stageMargin
      : (groupAndRow(a) || stagePictureOf(a) != null ? 4 : 12);
  static double cellInsetOf(TapAnswerActivity a) =>
      stagePictureOf(a) == 'base_ten' ? 0 : (groupAndRow(a) || stagePictureOf(a) != null ? 2 : 6);

  /// The box the group (or the two groups) is drawn in.
  Rect get groupArea => Rect.fromLTWH(
    reserve,
    0,
    w - reserve,
    groupAndRow(a) ? h * pictureShare : (_groupAboveOptions ? h * 0.5 : h),
  );

  /// The places of the pictures of group [which] (0, or 1 for the second group of a comparison), the same as the stage draws them.
  /// With [count] the places of a group of that many (a ten-frame of ten, to see the cells that are still empty).
  List<Rect> groupObjects(int which, {int? count}) {
    final List<SpriteSet> sets = <SpriteSet>[a.group!, ?a.group2];
    final ({double outer, double inner}) pad = groupPadOf(a, size);
    final Rect inner = groupArea.deflate(pad.outer);
    final double cellW = inner.width / sets.length;
    final Rect cell = Rect.fromLTWH(
      inner.left + which * cellW + pad.inner,
      inner.top + pad.inner,
      cellW - 2 * pad.inner,
      inner.height - 2 * pad.inner,
    );
    final SpriteSet g = sets[which];
    return <Rect>[
      for (final Rect r in spriteRects(
        cell.size,
        g.arrangement,
        count ?? g.count,
        seed: g.seed,
        scale: g.scale,
        lineSlots: lineSlotsOf(a, g, size),
      ))
        r.shift(cell.topLeft),
    ];
  }

  /// How many places a `line` of [g] has room for (see [groupLayout]). A clock face or a shade of a colour alone on the stage is one
  /// thing to read, not a group to compare: it takes the whole room, so that its hands and its shade can be seen on a phone.
  static int lineSlotsOf(TapAnswerActivity a, SpriteSet g, Size stage) =>
      a.group2 == null &&
          g.count == 1 &&
          (g.sprite.startsWith('asset:clock_') ||
              g.sprite.startsWith('asset:shade_') ||
              loneThingOf(a, stage))
      ? 1
      : 4;

  /// A single thing alone on a phone's stage to be found among the tiles under it (the apple of "where is another apple?", the plate
  /// of a pair): it takes the room the stage has, so that it is at least as large as the pictures on the tiles (76), which on the
  /// small phone's stage of 104 it is not with the room round a group (18 on each side). A tablet's stage has the room.
  static bool loneThingOf(TapAnswerActivity a, Size stage) =>
      a.group != null && a.group2 == null && a.group!.count == 1 && a.optionsInTiles && stage.width <= 500;

  /// The room round the groups of [a] in a stage of [stage]: round the box of all of them, and round each one (4 and 2 for a lone thing;
  /// otherwise [groupInsetOf] and [cellInsetOf]: 12 and 6 for a group).
  static ({double outer, double inner}) groupPadOf(TapAnswerActivity a, Size stage) =>
      loneThingOf(a, stage) ? (outer: 4, inner: 2) : (outer: groupInsetOf(a), inner: cellInsetOf(a));

  /// The whole box of group [which], for a group with no pictures (a count of 0) that still has a place.
  Rect groupCell(int which) {
    final int n = a.group2 == null ? 1 : 2;
    final ({double outer, double inner}) pad = groupPadOf(a, size);
    final Rect inner = groupArea.deflate(pad.outer);
    final double cellW = inner.width / n;
    return Rect.fromLTWH(
      inner.left + which * cellW + pad.inner,
      inner.top + pad.inner,
      cellW - 2 * pad.inner,
      inner.height - 2 * pad.inner,
    );
  }

  /// The layout of the blocks of the stage picture, in the picture's own box (add [pictureArea]'s top left for the stage's points), or
  /// null when the activity has no picture of blocks.
  BaseTenLayout? get blocks => stagePictureOf(a) == 'base_ten' && a.picture2 == null
      ? BaseTenLayout.forBox(
          BaseTen.fromScene(a.picture!),
          pictureArea.size,
          standing: true,
          maxUnit: BaseTenLayout.unitCap(tablet: spec.stageIsCard),
        )
      : null;

  /// The boxes the pictures of blocks of the stage are drawn in, in the coordinates of [area] (the room the stage gives the picture: its
  /// width less a hint's card, and its height or the share of it a row leaves): one box, or two for a comparison, 16 apart, each inside the
  /// stage's margin. The stage draws them, and a hint stands on the same places.
  static List<Rect> blockCells(TapAnswerActivity a, Size area) {
    const double gap = BaseTenLayout.pairGap;
    final double inset = groupInsetOf(a);
    final double w = area.width - 2 * inset, h = area.height - 2 * inset;
    if (a.picture2 == null) return <Rect>[Rect.fromLTWH(inset, inset, w, h)];
    final double cell = (w - gap) / 2;
    return <Rect>[for (int i = 0; i < 2; i++) Rect.fromLTWH(inset + i * (cell + gap), inset, cell, h)];
  }

  /// The height of the room of the stage's picture: the whole stage, or the share a row under it leaves.
  static double pictureHeightOf(TapAnswerActivity a, double stageH) =>
      groupAndRow(a) ? stageH * pictureShare : stageH;

  /// The layout of the chart of the stage picture, in the same way, or null when there is none.
  ChartLayout? get chart => stagePictureOf(a) == 'hundred_chart'
      ? ChartLayout.forBox(ChartSpec.fromScene(a.picture!), pictureArea.size)
      : null;

  /// The box the stage picture (blocks or chart) is drawn in: the group's room, inside the same margin.
  Rect get pictureArea => groupArea.deflate(groupInsetOf(a));

  /// A group's pictures in reading order: row by row from the top, each row from the left.
  List<Rect> inReadingOrder(List<Rect> rects) {
    if (rects.isEmpty) return rects;
    final double band = rects.first.height * 0.7;
    final List<Rect> sorted = List<Rect>.of(rects)
      ..sort((Rect p, Rect q) {
        final int row = (p.center.dy / band).round().compareTo((q.center.dy / band).round());
        return row != 0 ? row : p.center.dx.compareTo(q.center.dx);
      });
    return sorted;
  }

  /// How far a number sentence (a row with a sign in it) stands lower than the stage's top: the room over the numbers where the
  /// hint stands their cubes, big enough to count. 0 for any other row. The stage pads its row by the same.
  /// A row that stands under pictures (see [groupAndRow]) has no such room: its cubes are the pictures above it.
  static double rowLiftOf(TapAnswerActivity a, double stageH) =>
      !groupAndRow(a) && a.row.any((String r) => r.startsWith('op:')) ? (stageH * 0.26).roundToDouble() : 0;

  /// The band of the stage the row has, from its top and its height: the whole stage, or what the pictures above it leave. The row is
  /// padded by [rowPadOf] above and below inside it.
  static ({double top, double height}) rowBandOf(TapAnswerActivity a, double stageH) => groupAndRow(a)
      ? (top: stageH * pictureShare, height: stageH * (1 - pictureShare))
      : (top: 0, height: stageH);

  static double rowPadOf(TapAnswerActivity a) => groupAndRow(a) ? 2 : 10;

  /// The top of the drawn cells of the row (a cell is as tall as the row; a numeral in it may reach above [rowCells]' square).
  double get rowTop => rowBandOf(a, h).top + 3 + rowInsetOf(a, size) + rowLiftOf(a, h);

  /// The room kept free at each end of a row that has numbers or signs in it, so that it never touches the stage's rounded edge.
  static const double rowEdge = 16;

  /// How the row of [a] is laid out on a stage of [stage]: the width of each cell, left to right, and the size of the numbers and
  /// signs. A row with a number or a sign in it is laid out by what its cells hold (`rowCellEm`): every number and sign is one size,
  /// the biggest at which the whole row fits between the two [rowEdge]s (never above the height of the row), and the row is centred.
  /// A row of pictures only has cells of one width, filling the stage but for 10 points at each end.
  static ({List<double> widths, double textSize}) rowLayoutOf(TapAnswerActivity a, Size stage) {
    final int n = a.row.length;
    final bool text = a.row.any((String r) => r.startsWith('n:') || r.startsWith('op:'));
    if (!text) return (widths: List<double>.filled(n, (stage.width - 20) / n), textSize: 0);
    final double height =
        rowBandOf(a, stage.height).height - 2 * rowPadOf(a) - rowLiftOf(a, stage.height) - 6;
    final double size = math.min(height, (stage.width - 2 * rowEdge) / rowEm(a.row));
    return (widths: <double>[for (final String r in a.row) size * rowCellEm(r)], textSize: size);
  }

  /// Where the typed number is shown when the item has a number answer and no row to hold it: a cell in the middle of the stage, or in the
  /// band under the pictures.
  Rect get entryCell {
    final double top = groupAndRow(a) ? h * pictureShare : 0;
    final double band = h - top;
    final double cellH = math.min(band - 12, 72);
    return Rect.fromCenter(
      center: Offset(w / 2, top + band / 2),
      width: math.min(w * 0.6, cellH * 2.6),
      height: cellH,
    );
  }

  /// The cell that holds the typed number: the row's gap, or [entryCell] when there is no row.
  Rect get answerCell {
    if (a.row.isEmpty) return entryCell;
    final int gap = a.row.indexOf('?');
    return gap < 0 ? entryCell : rowCells()[gap];
  }

  /// Whether the row of [a] is laid out by [rowLayoutOf]: a row with a number or a sign in it (a number sentence, whose cells are as
  /// wide as what they hold), and any row that stands under pictures (see [groupAndRow]). Such a row keeps its one line; every other
  /// row of pictures is laid out by [rowLinesOf] and [rowSideOf].
  static bool usesRowLayout(TapAnswerActivity a) =>
      groupAndRow(a) || a.row.any((String r) => r.startsWith('n:') || r.startsWith('op:'));

  /// How many lines the row of [a] stands in on a stage of [stage]. A row of seven cells or more whose cell would be smaller than
  /// the token `stagePictureMin` in one line stands in two (the 9 of LOG-B-01 on a phone). A size item of five cells or more with
  /// round pictures (a row of balls) stands in two when one line would draw them under [_sizeCell] (a tile's picture is 84 at most, so a tablet's row never needs two lines; the stage then takes the room
  /// under it, see `TapAnswerSession.layoutFor`), so that the smallest ball can be seen at a glance. Any other row of six or fewer
  /// keeps its one line, as its hints and its gap are laid for it.
  static int rowLinesOf(TapAnswerActivity a, Size stage) {
    if (usesRowLayout(a)) return 1;
    final int n = a.row.length;
    final SizeLook? look = sizeLookOfTap(a);
    if (look != null) {
      if (look.tall || n < 5) return 1;
      return math.min(((stage.width - 20) / n) * sizeBleed, tilePictureSideOf(stage)) >= _sizeCell(stage)
          ? 1
          : 2;
    }
    if (n < 7) return 1;
    final double one = math.min((stage.width - 20) / n - 6, stage.height - 26 - rowLiftOf(a, stage.height));
    return one >= minPictureOf(stage) ? 1 : 2;
  }

  /// The smallest box a size item's pictures are drawn in on a stage of [stage] (so that its big picture is about 56 points on a
  /// phone and its small one about 20): rows that cannot give it are cut into lines.
  static double _sizeCell(Size stage) => 72;

  /// The room over and under the row's cells: [rowPadOf] for a row laid out by [rowLayoutOf]; any other 10, and 4 where two lines, or tall pictures (towers), have to fit in the stage's height.
  static double rowInsetOf(TapAnswerActivity a, Size stage) =>
      usesRowLayout(a) ? rowPadOf(a) : (rowLinesOf(a, stage) == 1 && !rowIsTall(a) ? 10 : 4);

  /// Whether the row of [a] draws tall pictures (the towers of a size item): its cells are then as tall as the stage leaves them.
  static bool rowIsTall(TapAnswerActivity a) => sizeLookOfTap(a)?.tall ?? false;

  /// The room a row of [a] leaves at the stage's two ends and round each cell, in a stage of [stage]: 10 and 3, and 4 and 1 for a row
  /// of six or fewer unlike pictures whose cell would be under the token `stagePictureMin` with those (the 6 of a pattern on a small
  /// phone: 36 points a picture, and 42 with this).
  static ({double edge, double pad}) rowRoomOf(TapAnswerActivity a, Size stage) {
    const ({double edge, double pad}) usual = (edge: 10, pad: 3);
    const ({double edge, double pad}) tight = (edge: 4, pad: 1);
    if (a.row.length >= 7 || sizeLookOfTap(a) != null) return usual;
    final double least = minPictureOf(stage);
    final int n = a.row.length;
    double side(({double edge, double pad}) r) => (stage.width - 2 * r.edge) / n - 2 * r.pad;
    return side(usual) < least && side(tight) >= least ? tight : usual;
  }

  /// The side of a square cell of the row of [a] in a stage of [stage]: the cells of a line share the stage's width (see [rowRoomOf]
  /// for what is left at the ends and round each cell), and the lines share its height; no cell is taller than the stage leaves.
  static double rowSideOf(TapAnswerActivity a, Size stage) {
    final int lines = rowLinesOf(a, stage);
    final double lift = rowLiftOf(a, stage.height);
    final int per = (a.row.length / lines).ceil();
    final ({double edge, double pad}) room = rowRoomOf(a, stage);
    return math.min(
      (stage.width - 2 * room.edge) / per - 2 * room.pad,
      (stage.height - 2 * rowInsetOf(a, stage) - lift) / lines - 6,
    );
  }

  /// The box that an item that compares sizes draws each of its pictures in, the same in the row and on the answer tiles (see
  /// `size_scale.dart`), or null for any other item. A round picture has the row's cell, or a tile's picture if that is smaller. A
  /// tall one (a tower) has the height that the stage's row leaves, or a tall tile's picture holds, and its own shape.
  static Size? sameBoxOf(TapAnswerActivity a, Size stage) {
    final SizeLook? look = sizeLookOfTap(a);
    if (look == null) return null;
    if (!look.tall) {
      final double side = math.min((rowSideOf(a, stage) + 6) * sizeBleed, tilePictureSideOf(stage));
      return Size(side, side);
    }
    final int lines = rowLinesOf(a, stage);
    final int per = (a.row.length / lines).ceil();
    final double cellW = (stage.width - 20) / per - 6;
    final double cellH = (stage.height - 2 * rowInsetOf(a, stage) - rowLiftOf(a, stage.height)) / lines - 6;
    final double height = math.min(math.min(cellH, cellW / look.aspect), tallTilePictureHeightOf(stage));
    return Size(height * look.aspect, height);
  }

  /// The cells of the stage's row (squares, or the boxes of tall pictures), left to right and line by line from the top.
  List<Rect> rowCells() {
    if (usesRowLayout(a)) return _layoutRowCells();
    final int n = a.row.length;
    final int lines = rowLinesOf(a, size);
    final int per = (n / lines).ceil();
    final double lift = rowLiftOf(a, h);
    final double edge = rowRoomOf(a, size).edge;
    final double cellW = (w - 2 * edge) / per;
    final double side = rowSideOf(a, size);
    final Size box = rowIsTall(a) ? sameBoxOf(a, size)! : Size(side, side);
    final double inset = rowInsetOf(a, size);
    final double pitch = (h - 2 * inset - lift) / lines;
    return <Rect>[
      for (int i = 0; i < n; i++)
        Rect.fromCenter(
          center: Offset(edge + (i % per + 0.5) * cellW, inset + lift + pitch * (i ~/ per + 0.5)),
          width: box.width,
          height: box.height,
        ),
    ];
  }

  /// The squares of the cells of a row laid out by [rowLayoutOf], left to right (the same places the stage draws them in).
  List<Rect> _layoutRowCells() {
    final double lift = rowLiftOf(a, h);
    final ({double top, double height}) band = rowBandOf(a, h);
    final List<double> widths = rowLayoutOf(a, size).widths;
    double left = (w - widths.fold<double>(0, (double sum, double x) => sum + x)) / 2;
    final List<Rect> cells = <Rect>[];
    for (final double cellW in widths) {
      final double side = math.min(cellW - 6, band.height - 2 * rowPadOf(a) - 6 - lift);
      cells.add(
        Rect.fromCenter(
          center: Offset(left + cellW / 2, band.top + (band.height + lift) / 2),
          width: side,
          height: side,
        ),
      );
      left += cellW;
    }
    return cells;
  }

  /// The cells of the columns of the stage's chart, each column from the bottom up, the same as the stage draws them (columns
  /// of equal squares on one line, spread evenly).
  List<List<Rect>> chartColumns() {
    const double left = 16, top = 8, right = 16, bottom = 10, floor = 3;
    final double boxW = w - left - right;
    final double boxH = h - top - bottom;
    final int most = a.chart.fold(1, (int m, ({String sprite, int count}) c) => math.max(m, c.count));
    final double cell = math.min((boxH - 6) / most, boxW / a.chart.length - 14);
    final double gap = (boxW - cell * a.chart.length) / (a.chart.length + 1);
    final double base = h - bottom - floor;
    return <List<Rect>>[
      for (int i = 0; i < a.chart.length; i++)
        <Rect>[
          for (int j = 0; j < a.chart[i].count; j++)
            Rect.fromLTWH(left + gap * (i + 1) + cell * i, base - cell * (j + 1), cell, cell),
        ],
    ];
  }

  /// The place of the numeral that the stage shows large.
  Rect get stageNumeral => Rect.fromCenter(center: Offset(w / 2, h / 2), width: h * 0.55, height: h * 0.7);

  /// True when the pictures on the stage run from the right: the activity is of a course that reads right to left (Hebrew). The
  /// lands keep the order they always had, first picture on the left.
  bool get stageFromRight => courseRowDirection(a.course) == TextDirection.rtl;

  /// The places of the options that stand on the stage itself (those that are not on tiles), in the order of the options.
  List<Rect> stageOptions() {
    final int n = a.options.length;
    final double top = _groupAboveOptions ? h * 0.5 : 0;
    final double room = h - top;
    final double box = math.min(room * (_groupAboveOptions ? 0.9 : 0.86), w / (n + 0.5));
    final double gap = (w - box * n) / (n + 1);
    return <Rect>[
      for (int i = 0; i < n; i++)
        Rect.fromLTWH(gap + (stageFromRight ? n - 1 - i : i) * (box + gap), top + (room - box) / 2, box, box),
    ];
  }

  /// The middle of the stage, a [width] by [height] box, for a picture that stands alone (a sample, a path).
  Rect centre(double width, double height) =>
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: width, height: height);

  /// The card at the stage's end side (the left): up to 90 by 120, inside the stage.
  Rect get endCard {
    final double cw = math.min(90, w * 0.27);
    return Rect.fromLTWH(6, (h - math.min(120, h - 8)) / 2, cw, math.min(120, h - 8));
  }

  // ---- the answers ----

  /// True when the options are tiles below the stage.
  bool get tiles => a.optionsInTiles;

  /// The size of the stage's own room on [spec]'s board: a tablet's stage is a card, and its picture is 16 in from the card's edge.
  static Size stageSizeOf(ActivitySpec spec) =>
      spec.stageIsCard ? Size(spec.stage.width - 32, spec.stage.height - 32) : spec.stage.size;

  /// The width of one answer tile of [a] on [spec]'s board: a square 96 points for a numeral, a letter, a sound or a picture; as
  /// wide as the row allows for a set of things (170 at most) and for words (220 at most).
  static double tileWidthOf(TapAnswerActivity a, ActivitySpec spec) {
    final double room = spec.tilesWidth / a.options.length - 2 * spec.tileSlop;
    if (a.options.any((ChoiceOption o) => o.set != null)) return math.min(170, room);
    if (a.options.any((ChoiceOption o) => o.picture != null)) return math.min(260, room);
    if (a.options.any((ChoiceOption o) => o.text != null) && !a.letterFace) return math.min(220, room);
    // A size item's tiles are as large as its pictures need (see `size_scale.dart`).
    return comparesSizes(a) ? tileSideOf(stageSizeOf(spec)) : spec.tileSize;
  }

  /// Whether an option of [a] is blocks on its tile (`answer.options[].picture`).
  static bool hasBlockTiles(TapAnswerActivity a) =>
      a.optionsInTiles && a.options.any((ChoiceOption o) => o.picture != null);

  /// The box the blocks of one option are drawn in: the tile less its border and the 5 points of margin round the blocks (the blocks stand
  /// on the bottom of the tile, see `BaseTenPicture.standing`).
  static Size blockBoxOf(TapAnswerActivity a, ActivitySpec spec) =>
      Size(tileWidthOf(a, spec) - 2 * BaseTenLayout.tileEdge, spec.tileHeight - 2 * BaseTenLayout.tileEdge);

  /// The side of one cube in every option of [a] that is blocks: the one size that fits the widest and tallest of them, so that a
  /// cube is as big in a rod option as in an option of cubes only (a child compares the pictures). Null when no option is blocks.
  static double? blockUnitOf(TapAnswerActivity a, ActivitySpec spec) {
    final Size box = blockBoxOf(a, spec);
    return BaseTenLayout.commonUnit(<(BaseTen, Size)>[
      for (final ChoiceOption o in a.options)
        if (o.picture != null) (BaseTen.fromScene(o.picture!), box),
    ], maxUnit: BaseTenLayout.unitCap(tablet: spec.stageIsCard));
  }

  /// The point on the top edge of option [i]'s tile (or, for an option on the stage, of its picture) where the hand's fingertip
  /// ends. For a tile this is below the stage: the hand reaches over its edge.
  Offset optionTip(int i) {
    if (!tiles) {
      final Rect r = stageOptions()[i];
      return Offset(r.center.dx, r.top + r.height * 0.18);
    }
    final int n = a.options.length;
    // Each tile takes its width and its tap margin on both sides (see `AnswerTile`): 12 points, or the look's.
    final double tileW = tileWidthOf(a, spec) + 2 * spec.tileSlop;
    final double fromStart = (spec.tilesWidth - n * tileW) / 2 + (i + 0.5) * tileW;
    final double cx = dir == TextDirection.rtl
        ? spec.tilesLeft + spec.tilesWidth - fromStart
        : spec.tilesLeft + fromStart;
    final double inset = spec.stageIsCard ? 16 : 0;
    return Offset(cx - (spec.stage.left + inset), spec.tilesTop - (spec.stage.top + inset));
  }

  /// The point on the top edge of key [name] of the keypad (see `KeypadLayout`), in the stage's points: where the fingertip ends when the
  /// answer is typed.
  Offset keyTip(String name) {
    final Offset board = KeypadLayout.of(spec).tip(name);
    final double inset = spec.stageIsCard ? 16 : 0;
    return board - Offset(spec.stage.left + inset, spec.stage.top + inset);
  }

  /// The right edge of the keypad, in the stage's points.
  double get keypadRight => KeypadLayout.of(spec).right - (spec.stage.left + (spec.stageIsCard ? 16 : 0));

  /// A place for a small sample picture above option [i], where it can hover before the hand arrives.
  Offset sampleAbove(int i) => optionTip(i) - Offset(0, tiles ? 12 : 0);

  /// The index of the right option.
  int get correctIndex => a.options.indexWhere((ChoiceOption o) => o.id == a.correctId);
}
