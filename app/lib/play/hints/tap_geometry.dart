import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../child/activity_shell.dart';
import '../../content/models.dart';
import '../sprite_group.dart';

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

  /// True when the stage has a group (or the two groups) and also a numeral or a row: the groups stand on top and the numeral or the
  /// row under them, never over them (B-36: the two ten-frames and the teen they make). Any other stage keeps the whole room.
  bool get stacked => stackedOf(a);

  static bool stackedOf(TapAnswerActivity a) =>
      a.group != null && (a.stageNumeral != null || a.row.isNotEmpty);

  /// How much of the stage's height (above the options, if the options stand on it) the numeral or row of a [stacked] stage takes.
  /// A ten-frame on a phone is about 55 points tall in a 128 point stage: the groups keep the upper 58 percent, which is room for
  /// the frames on every board (the frames are as wide as the room allows), and the numeral under them gets the rest.
  static const double lowerShare = 0.42;

  /// The room the stage's group(s) and, if [stacked], the numeral or row have: from the top to the options (or the stage's bottom).
  double get _zoneH => _groupAboveOptions ? h * 0.5 : h;

  /// The space round the groups, and round each group, in points. A [stacked] stage spends less of its height on margins.
  static double groupInsetOf(TapAnswerActivity a) => stackedOf(a) ? 4 : 12;
  static double cellInsetOf(TapAnswerActivity a) => stackedOf(a) ? 2 : 6;

  /// The box the group (or the two groups) is drawn in.
  Rect get groupArea => Rect.fromLTWH(reserve, 0, w - reserve, stacked ? _zoneH * (1 - lowerShare) : _zoneH);

  /// The box under the groups of a [stacked] stage, for its numeral or its row. It follows the groups when a card takes the stage's
  /// end side.
  Rect get lowerArea => Rect.fromLTRB(reserve, groupArea.bottom, w, _zoneH);

  /// The places of the pictures of group [which] (0, or 1 for the second group of a comparison), the same as the stage draws them.
  /// With [count] the places of a group of that many (a ten-frame of ten, to see the cells that are still empty).
  List<Rect> groupObjects(int which, {int? count}) {
    final List<SpriteSet> sets = <SpriteSet>[a.group!, ?a.group2];
    final Rect inner = groupArea.deflate(groupInsetOf(a));
    final double cellW = inner.width / sets.length;
    final double pad = cellInsetOf(a);
    final Rect cell = Rect.fromLTWH(
      inner.left + which * cellW + pad,
      inner.top + pad,
      cellW - 2 * pad,
      inner.height - 2 * pad,
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
    final Rect inner = groupArea.deflate(groupInsetOf(a));
    final double cellW = inner.width / n;
    final double pad = cellInsetOf(a);
    return Rect.fromLTWH(
      inner.left + which * cellW + pad,
      inner.top + pad,
      cellW - 2 * pad,
      inner.height - 2 * pad,
    );
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
  /// hint stands their cubes, big enough to count. 0 for any other row, and for a row under groups (the groups are what the hint
  /// stands on there). The stage pads its row by the same.
  static double rowLiftOf(TapAnswerActivity a, double stageH) =>
      !stackedOf(a) && a.row.any((String r) => r.startsWith('op:')) ? (stageH * 0.26).roundToDouble() : 0;

  /// The space over and under the cells of the row: 10, and less in the narrow band under groups.
  static double rowPadOf(TapAnswerActivity a) => stackedOf(a) ? 4 : 10;

  /// The box the row is drawn in: the whole stage, or the band under the groups.
  Rect get _rowBox => stacked ? lowerArea : Offset.zero & size;

  /// The top of the drawn cells of the row (a cell is as tall as the row; a numeral in it may reach above [rowCells]' square).
  double get rowTop => _rowBox.top + rowPadOf(a) + 3 + rowLiftOf(a, h);

  /// The squares of the cells of the stage's row, left to right.
  List<Rect> rowCells() {
    final int n = a.row.length;
    final double lift = rowLiftOf(a, h);
    final Rect box = _rowBox;
    final double cellW = (box.width - 20) / n;
    final double side = math.min(cellW - 6, box.height - 2 * rowPadOf(a) - 6 - lift);
    return <Rect>[
      for (int i = 0; i < n; i++)
        Rect.fromCenter(
          center: Offset(box.left + 10 + (i + 0.5) * cellW, box.top + (box.height + lift) / 2),
          width: side,
          height: side,
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

  /// The size, in points, of the numeral the stage shows large: most of the stage's height when it stands alone, and most of the
  /// band under the groups when [stacked].
  double get stageNumeralFont => stacked ? lowerArea.height * 0.82 : h * 0.7;

  /// The place of the numeral that the stage shows large: in the middle of the stage, or under the groups when [stacked].
  Rect get stageNumeral {
    if (!stacked) return Rect.fromCenter(center: Offset(w / 2, h / 2), width: h * 0.55, height: h * 0.7);
    final Rect band = lowerArea;
    final double digits = '${a.stageNumeral}'.length * stageNumeralFont * 0.62;
    return Rect.fromCenter(
      center: band.center,
      width: math.min(band.width, digits),
      height: band.height * 0.92,
    );
  }

  /// The places of the options that stand on the stage itself (those that are not on tiles).
  List<Rect> stageOptions() {
    final int n = a.options.length;
    final double top = _groupAboveOptions ? h * 0.5 : 0;
    final double room = h - top;
    final double box = math.min(room * (_groupAboveOptions ? 0.9 : 0.86), w / (n + 0.5));
    final double gap = (w - box * n) / (n + 1);
    return <Rect>[
      for (int i = 0; i < n; i++) Rect.fromLTWH(gap + i * (box + gap), top + (room - box) / 2, box, box),
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

  /// The height of an answer tile (`AnswerTile`, every board); its clay lip and shadow reach 6 below it.
  static const double tileHeight = 96;

  /// The box the speech bubble may take on this board ([ActivitySpec.bubbleRoom]), in the stage's own points: a hint's picture
  /// that stands outside the stage stays out of it.
  Rect get bubbleRoom {
    final double inset = spec.stageIsCard ? 16 : 0;
    return spec.bubbleRoom.shift(Offset(-(spec.stage.left + inset), -(spec.stage.top + inset)));
  }

  /// True when the options are tiles below the stage.
  bool get tiles => a.optionsInTiles;

  /// The point on the top edge of option [i]'s tile (or, for an option on the stage, of its picture) where the hand's fingertip
  /// ends. For a tile this is below the stage: the hand reaches over its edge.
  Offset optionTip(int i) {
    if (!tiles) {
      final Rect r = stageOptions()[i];
      return Offset(r.center.dx, r.top + r.height * 0.18);
    }
    final int n = a.options.length;
    final bool sets = a.options.any((ChoiceOption o) => o.set != null);
    // Each tile takes its width and a 12 point tap margin on both sides (see `AnswerTile`).
    final double tileW = (sets ? math.min(170, spec.tilesWidth / n - 24) : 96) + 24;
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
