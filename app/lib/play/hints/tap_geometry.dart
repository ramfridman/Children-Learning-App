import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../child/activity_shell.dart';
import '../../content/models.dart';
import '../../design/course_text.dart';
import '../sprite_group.dart';
import '../size_scale.dart';
import '../stage_picture.dart';

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

  /// The box the group (or the two groups) is drawn in.
  Rect get groupArea => Rect.fromLTWH(reserve, 0, w - reserve, _groupAboveOptions ? h * 0.5 : h);

  /// The places of the pictures of group [which] (0, or 1 for the second group of a comparison), the same as the stage draws them.
  /// With [count] the places of a group of that many (a ten-frame of ten, to see the cells that are still empty).
  List<Rect> groupObjects(int which, {int? count}) {
    final List<SpriteSet> sets = <SpriteSet>[a.group!, ?a.group2];
    final Rect inner = groupArea.deflate(12);
    final double cellW = inner.width / sets.length;
    final Rect cell = Rect.fromLTWH(
      inner.left + which * cellW + 6,
      inner.top + 6,
      cellW - 12,
      inner.height - 12,
    );
    final SpriteSet g = sets[which];
    return <Rect>[
      for (final Rect r in spriteRects(
        cell.size,
        g.arrangement,
        count ?? g.count,
        seed: g.seed,
        scale: g.scale,
        lineSlots: lineSlotsOf(a, g),
      ))
        r.shift(cell.topLeft),
    ];
  }

  /// How many places a `line` of [g] has room for (see [groupLayout]). A clock face or a shade of a colour alone on the stage is one
  /// thing to read, not a group to compare: it takes the whole room, so that its hands and its shade can be seen on a phone.
  static int lineSlotsOf(TapAnswerActivity a, SpriteSet g) =>
      a.group2 == null &&
          g.count == 1 &&
          (g.sprite.startsWith('asset:clock_') || g.sprite.startsWith('asset:shade_'))
      ? 1
      : 4;

  /// The whole box of group [which], for a group with no pictures (a count of 0) that still has a place.
  Rect groupCell(int which) {
    final int n = a.group2 == null ? 1 : 2;
    final Rect inner = groupArea.deflate(12);
    final double cellW = inner.width / n;
    return Rect.fromLTWH(inner.left + which * cellW + 6, inner.top + 6, cellW - 12, inner.height - 12);
  }

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
  static double rowLiftOf(TapAnswerActivity a, double stageH) =>
      a.row.any((String r) => r.startsWith('op:')) ? (stageH * 0.26).roundToDouble() : 0;

  /// The top of the drawn cells of the row (a cell is as tall as the row; a numeral in it may reach above [rowCells]' square).
  double get rowTop => rowInsetOf(a, size) + 3 + rowLiftOf(a, h);

  /// How many lines the row of [a] stands in on a stage of [stage]. A row of seven cells or more whose cell would be smaller than
  /// the token `stagePictureMin` in one line stands in two (the 9 of LOG-B-01 on a phone). A size item of five cells or more with
  /// round pictures (a row of balls) stands in two when one line would draw them under [_sizeCell] (a tile's picture is 84 at most, so a tablet's row never needs two lines; the stage then takes the room
  /// under it, see `TapAnswerSession.layoutFor`), so that the smallest ball can be seen at a glance. Any other row of six or fewer
  /// keeps its one line, as its hints and its gap are laid for it.
  static int rowLinesOf(TapAnswerActivity a, Size stage) {
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

  /// The room over and under the row's cells: 10, and 4 where two lines, or tall pictures (towers), have to fit in the stage's height.
  static double rowInsetOf(TapAnswerActivity a, Size stage) =>
      rowLinesOf(a, stage) == 1 && !rowIsTall(a) ? 10 : 4;

  /// Whether the row of [a] draws tall pictures (the towers of a size item): its cells are then as tall as the stage leaves them.
  static bool rowIsTall(TapAnswerActivity a) => sizeLookOfTap(a)?.tall ?? false;

  /// The side of a square cell of the row of [a] in a stage of [stage]: the cells of a line share the stage's width (10 in on each
  /// side, 3 round each cell), and the lines share its height; no cell is taller than the stage leaves.
  static double rowSideOf(TapAnswerActivity a, Size stage) {
    final int lines = rowLinesOf(a, stage);
    final double lift = rowLiftOf(a, stage.height);
    final int per = (a.row.length / lines).ceil();
    return math.min(
      (stage.width - 20) / per - 6,
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
    final int n = a.row.length;
    final int lines = rowLinesOf(a, size);
    final int per = (n / lines).ceil();
    final double lift = rowLiftOf(a, h);
    final double cellW = (w - 20) / per;
    final double side = rowSideOf(a, size);
    final Size box = rowIsTall(a) ? sameBoxOf(a, size)! : Size(side, side);
    final double inset = rowInsetOf(a, size);
    final double pitch = (h - 2 * inset - lift) / lines;
    return <Rect>[
      for (int i = 0; i < n; i++)
        Rect.fromCenter(
          center: Offset(10 + (i % per + 0.5) * cellW, inset + lift + pitch * (i ~/ per + 0.5)),
          width: box.width,
          height: box.height,
        ),
    ];
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
    final double room = spec.tilesWidth / a.options.length - 24;
    if (a.options.any((ChoiceOption o) => o.set != null)) return math.min(170, room);
    if (a.options.any((ChoiceOption o) => o.text != null) && !a.letterFace) return math.min(220, room);
    // A size item's tiles are as large as its pictures need (see `size_scale.dart`).
    return comparesSizes(a) ? tileSideOf(stageSizeOf(spec)) : 96;
  }

  /// The point on the top edge of option [i]'s tile (or, for an option on the stage, of its picture) where the hand's fingertip
  /// ends. For a tile this is below the stage: the hand reaches over its edge.
  Offset optionTip(int i) {
    if (!tiles) {
      final Rect r = stageOptions()[i];
      return Offset(r.center.dx, r.top + r.height * 0.18);
    }
    final int n = a.options.length;
    // Each tile takes its width and a 12 point tap margin on both sides (see `AnswerTile`).
    final double tileW = tileWidthOf(a, spec) + 24;
    final double fromStart = (spec.tilesWidth - n * tileW) / 2 + (i + 0.5) * tileW;
    final double cx = dir == TextDirection.rtl
        ? spec.tilesLeft + spec.tilesWidth - fromStart
        : spec.tilesLeft + fromStart;
    final double inset = spec.stageIsCard ? 16 : 0;
    return Offset(cx - (spec.stage.left + inset), spec.tilesTop - (spec.stage.top + inset));
  }

  /// A place for a small sample picture above option [i], where it can hover before the hand arrives.
  Offset sampleAbove(int i) => optionTip(i) - Offset(0, tiles ? 12 : 0);

  /// The index of the right option.
  int get correctIndex => a.options.indexWhere((ChoiceOption o) => o.id == a.correctId);
}
