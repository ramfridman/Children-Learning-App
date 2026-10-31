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

/// P6 (number path): equal squares with numerals, 1 at the left (never mirrored; [reverse] puts 1 at the right, only where the
/// row of tiles below runs that way). [gap] is a square drawn empty, [ring] a square with a sky ring, [marker] the square the
/// helper's marker stands on, [upTo] how many squares are drawn so far (the rest are not there yet).
final class PathMark extends HintMark {
  const PathMark({
    required this.rect,
    required this.count,
    this.gap,
    this.ring,
    this.marker,
    this.upTo,
    this.reverse = false,
  });

  final Rect rect;
  final int count;
  final int? gap;
  final int? ring;
  final int? marker;
  final int? upTo;
  final bool reverse;
}

/// P9 (sample): a paint dab of a colour with its helper symbol. [colour] is one of the names in [hintColours].
final class SwatchMark extends HintMark {
  const SwatchMark(this.rect, this.colour);

  final Rect rect;
  final String colour;
}

/// The outlines a [GhostMark] can draw.
enum GhostKind { circle, square, rect, triangle, straight, curved }

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
  const CopyMark(this.rect, this.svg, {this.opacity = 1, this.turns = 0});

  final Rect rect;
  final String svg;
  final double opacity;
  final double turns;
}

/// The sky card of a second picture: radius 18, `skyTint`, a `hintHalo` ring 3 wide, with [child] inside.
final class CardMark extends HintMark {
  const CardMark(this.rect, this.child);

  final Rect rect;
  final Widget child;
}

/// A hop of the number path, as a dotted arc.
final class ArcMark extends HintMark {
  const ArcMark(this.from, this.to);

  final Offset from;
  final Offset to;
}

/// A dotted sky line: a link from a thing to its picture, a start line, a floor.
final class LineMark extends HintMark {
  const LineMark(this.from, this.to);

  final Offset from;
  final Offset to;
}

/// P7 (core bracket): an open bracket under the span from [left] to [right] (the ends are at the bracket's top, the tips point up).
final class BracketMark extends HintMark {
  const BracketMark(this.left, this.right);

  final Offset left;
  final Offset right;
}

/// A small cube of a stick or a tower (a unit to count along a length): `skyTint` with a `skyDeep` edge.
final class BlockMark extends HintMark {
  const BlockMark(this.rect);

  final Rect rect;
}

/// P12 (the pointing hand): the fingertip is on [tip]. [press] makes a sky ripple at the tip (the "tok").
final class HandMark extends HintMark {
  const HandMark(this.tip, {this.press = false});

  final Offset tip;
  final bool press;
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
