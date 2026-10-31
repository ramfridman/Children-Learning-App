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

  /// The box the group (or the two groups) is drawn in.
  Rect get groupArea => Rect.fromLTWH(reserve, 0, w - reserve, _groupAboveOptions ? h * 0.5 : h);

  /// The places of the pictures of group [which] (0, or 1 for the second group of a comparison), the same as the stage draws them.
  List<Rect> groupObjects(int which) {
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
      for (final Rect r in spriteRects(cell.size, g.arrangement, g.count, seed: g.seed, scale: g.scale))
        r.shift(cell.topLeft),
    ];
  }

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

  /// The squares of the cells of the stage's row, left to right.
  List<Rect> rowCells() {
    final int n = a.row.length;
    final double cellW = (w - 20) / n;
    final double side = math.min(cellW - 6, h - 26);
    return <Rect>[
      for (int i = 0; i < n; i++)
        Rect.fromCenter(center: Offset(10 + (i + 0.5) * cellW, h / 2), width: side, height: side),
    ];
  }

  /// The place of the numeral that the stage shows large.
  Rect get stageNumeral => Rect.fromCenter(center: Offset(w / 2, h / 2), width: h * 0.55, height: h * 0.7);

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
