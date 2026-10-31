import 'package:flutter/widgets.dart';

// What a hint draws on the stage, as plain data (B-40 part 2). A template (or a family of `tap_answer`) decides what to draw and
// where; `HintOverlay` (hint_pictures.dart) draws it. Everything is in the stage's own points: (0, 0) is the stage's top left
// corner, and the numbers are the same on every device (the overlay scales sizes, not places).
//
// A mark is one of the shared pictures of the design spec (docs/design/b40-visual-hints.md, section 3):
// P1 [VeilMark], P2 [RingMark] with [SeenMark], P5 [PairsMark], P6 [PathMark], P9 [SwatchMark] and [GhostMark],
// P12 [HandMark]; the rest ([CardMark], [CopyMark], [BadgeMark], [ArcMark], [LineMark]) are the small parts they are made of.

sealed class HintMark {
  const HintMark();
}

/// P1 (spotlight): the stage fades to half, and each of [holes] stays clear inside a sky ring.
final class VeilMark extends HintMark {
  const VeilMark(this.holes);

  final List<Rect> holes;
}

/// P2 (light each): one thing is lit with a sky ring. A round ring for an object, a rounded square for a cell.
final class RingMark extends HintMark {
  const RingMark(this.rect, {this.round = true});

  final Rect rect;
  final bool round;
}

/// P2: a small sky dot at the top end corner of a thing that has been looked at; it stays when the ring has moved on.
final class SeenMark extends HintMark {
  const SeenMark(this.rect);

  final Rect rect;
}

/// A number badge (paper, a sky ring): [n] things counted so far. [big] is the count card of the end of a count.
final class BadgeMark extends HintMark {
  const BadgeMark(this.at, this.n, {this.big = false});

  final Offset at;
  final int n;
  final bool big;
}

/// P5 (pair lines): dotted lines between partners; the things in [unpaired] get a sky ring.
final class PairsMark extends HintMark {
  const PairsMark({required this.lines, this.unpaired = const <Rect>[]});

  final List<(Offset, Offset)> lines;
  final List<Rect> unpaired;
}

/// P6 (number path): equal squares with numerals, the first at the left (never mirrored): [from], [from] + [step], and so on.
/// [gap] is the number of a square drawn empty, [ring] one with a sky ring, [marker] the one the helper's marker stands on, [upTo]
/// how many squares are drawn so far (the rest are not there yet). A step of 2 or 10 is a path of skip counting.
final class PathMark extends HintMark {
  const PathMark({
    required this.rect,
    required this.count,
    this.gap,
    this.ring,
    this.marker,
    this.upTo,
    this.from = 1,
    this.step = 1,
  });

  final Rect rect;
  final int count;
  final int? gap;
  final int? ring;
  final int? marker;
  final int? upTo;
  final int from;
  final int step;

  /// The number written in the [i]th square (from 1).
  int numberAt(int i) => from + (i - 1) * step;
}

/// P9 (sample): a paint dab of a colour with its helper symbol. [colour] is one of the names in [hintColours].
final class SwatchMark extends HintMark {
  const SwatchMark(this.rect, this.colour);

  final Rect rect;
  final String colour;
}

/// The outlines a [GhostMark] can draw: flat shapes, a line, and the outline of a solid as it is drawn on paper.
enum GhostKind { circle, square, rect, triangle, straight, curved, cylinder, cone, box, pyramid }

/// P9 (sample): a dashed outline of a shape (or a line); [turn] lets it turn once to show that a shape stays itself.
final class GhostMark extends HintMark {
  const GhostMark(this.rect, this.kind, {this.turn = false});

  final Rect rect;
  final GhostKind kind;
  final bool turn;
}

/// A picture of the question drawn again where the hint needs it (a group in a row, the picture in a gap, a sample). [turns] is a
/// rotation in turns; [opacity] makes it a ghost.
final class CopyMark extends HintMark {
  const CopyMark(this.rect, this.svg, {this.opacity = 1, this.turns = 0, this.backed = false});

  final Rect rect;
  final String svg;
  final double opacity;
  final double turns;

  /// The picture stands on a paper fill the size of [rect], over whatever the stage has there (the "?" of an empty place).
  final bool backed;
}

/// The sky card of a second picture: radius 18, `skyTint`, a `hintHalo` ring 3 wide, with [child] inside. A [tight] card has half
/// the padding, for a strip that lies over a thing (dots under a numeral).
final class CardMark extends HintMark {
  const CardMark(this.rect, this.child, {this.tight = false});

  final Rect rect;
  final Widget child;
  final bool tight;
}

/// A hop of the number path, as a dotted arc.
final class ArcMark extends HintMark {
  const ArcMark(this.from, this.to);

  final Offset from;
  final Offset to;
}

/// A dotted sky line: a link from a thing to its picture, a start line, a floor. [faint] makes it thin and light: a connector that
/// only says "this belongs to that", beside the lines that carry the hint itself.
final class LineMark extends HintMark {
  const LineMark(this.from, this.to, {this.faint = false});

  final Offset from;
  final Offset to;
  final bool faint;
}

/// A sky arrow from [from] to [to] with its head at [to]: a push, a direction the helper's things move in.
final class ArrowMark extends HintMark {
  const ArrowMark(this.from, this.to);

  final Offset from;
  final Offset to;
}

/// A mark that is drawn on an answer tile, not on the stage: the session draws it in its row of tiles, because a tile (and what is
/// on it) paints above the stage and the speech bubble, and the stage's overlay does not. [tile] is the tile's place in the row
/// (0 is the first option).
sealed class TileMark extends HintMark {
  const TileMark(this.tile);

  final int tile;
}

/// A place badge over the top edge of a tile: [n] is its place in the queue (the same badge as the stage's [BadgeMark]).
final class TileBadgeMark extends TileMark {
  const TileBadgeMark(super.tile, this.n);

  final int n;
}

/// A small start flag standing on the first end of a tile (the end the row starts at).
final class TileFlagMark extends TileMark {
  const TileFlagMark(super.tile);
}

/// A small start flag that stands on [base] (the foot of its pole): where a line, a queue or a row begins.
final class FlagMark extends HintMark {
  const FlagMark(this.base);

  final Offset base;
}

/// P7 (core bracket): an open bracket under the span from [left] to [right] (the ends are at the bracket's top, the tips point up).
final class BracketMark extends HintMark {
  const BracketMark(this.left, this.right);

  final Offset left;
  final Offset right;
}

/// A small cube of a stick or a tower (a unit to count along a length): `skyTint` with a `skyDeep` edge. An [empty] one is only its
/// outline: a place that is not filled.
final class BlockMark extends HintMark {
  const BlockMark(this.rect, {this.empty = false});

  final Rect rect;
  final bool empty;
}

/// A place for a coin on the shop's counter (one shekel): a dashed circle, or, when [filled], gold: the shekel is paid.
final class PlaceMark extends HintMark {
  const PlaceMark(this.rect, {this.filled = false});

  final Rect rect;
  final bool filled;
}

/// The outline of a shape as a path of corners: the first [upTo] sides are drawn in sky (all of them when null), a start dot sits on
/// the first corner and a dot on each corner reached. [closed] is false for a line that does not come back to its start.
final class OutlineMark extends HintMark {
  const OutlineMark(this.points, {this.closed = true, this.upTo, this.dots = true, this.faint = false});

  final List<Offset> points;
  final bool closed;
  final int? upTo;
  final bool dots;

  /// Only a thin dotted outline: the shape is there, none of its sides is lit.
  final bool faint;
}

/// P10 (the seesaw of heavy and light): a playground seesaw standing on the floor of [rect] (the whole stage), [left] on its left
/// end and [right] on its right end (pack pictures cut to their ink, [leftAspect] and [rightAspect] their width over height). [down]
/// is the end that rests on the ground: -1 the left, 1 the right, 0 neither (the plank is level). [propLeft] and [propRight] are the
/// wooden blocks under each end that hold the plank level until the hand takes them away. A new [down] tips the plank slowly;
/// with "reduce motion" the tipped plank fades in.
final class SeesawMark extends HintMark {
  const SeesawMark(
    this.rect, {
    required this.left,
    required this.right,
    this.leftAspect = 1,
    this.rightAspect = 1,
    this.down = 0,
    this.propLeft = true,
    this.propRight = true,
  });

  final Rect rect;
  final String left;
  final String right;
  final double leftAspect;
  final double rightAspect;
  final int down;
  final bool propLeft;
  final bool propRight;
}

/// Where the body of a pointing hand lies: [guide] is the hand's own way, from the guide's side above the fingertip (it never
/// reaches the speech bubble, see `HintOverlay`); [below] turns the hand half round so that its body lies under the fingertip, for
/// a target whose surroundings above it (the shop's total, a bin's label) have to stay in view.
enum HandFrom { guide, below }

/// P12 (the pointing hand): the fingertip is on [tip]. [press] makes a sky ripple at the tip (the "tok"). [snap] puts the hand where
/// it is told at once, with no glide: the hand of a trace follows a walking dot a few points at a time. [from] is where the hand's
/// body lies.
final class HandMark extends HintMark {
  const HandMark(this.tip, {this.press = false, this.snap = false, this.from = HandFrom.guide});

  final Offset tip;
  final bool press;
  final bool snap;
  final HandFrom from;
}

/// One step of a hint: what is on the stage for [hold]. [litOption] is the answer tile (by its place in the row) that has a sky
/// glow during this step, used where the stage has nothing of the question to light and every option is lit in turn. [reserve] is
/// how much of the stage's end side (the left) a card takes, so that the stage's own picture moves into the rest.
class HintFrame {
  const HintFrame(
    this.marks, {
    this.hold = const Duration(milliseconds: 950),
    this.litOption,
    this.reserve = 0,
  });

  final List<HintMark> marks;
  final Duration hold;
  final int? litOption;
  final double reserve;
}

/// A whole hint: the [frames] one after the other, then what stays on the stage ([rest], with [restReserve]). [endsDemo] is true
/// for the worked example, whose last step hands the answer its halo.
class HintPlan {
  const HintPlan(this.frames, {this.rest = const <HintMark>[], this.restReserve = 0, this.endsDemo = false});

  final List<HintFrame> frames;
  final List<HintMark> rest;
  final double restReserve;
  final bool endsDemo;

  Duration get length => frames.fold(Duration.zero, (Duration d, HintFrame f) => d + f.hold);
}

/// The names of the colours of the teaching set, and their paint.
const Map<String, Color> hintColours = <String, Color>{
  'red': Color(0xFFE5484D),
  'orange': Color(0xFFFF9F43),
  'yellow': Color(0xFFFFD84D),
  'green': Color(0xFF4CAF50),
  'blue': Color(0xFF2F7FE0),
  'purple': Color(0xFF9B6BDF),
  'pink': Color(0xFFF48FB1),
  'brown': Color(0xFF8A5A2B),
  'black': Color(0xFF2B2540),
  'white': Color(0xFFFFFFFF),
  'grey': Color(0xFF9AA0B4),
};
