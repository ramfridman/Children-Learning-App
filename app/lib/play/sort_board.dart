import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/tokens.g.dart';
import 'ink_fit.dart';
import 'sprite_group.dart';
import 'template_session.dart' show PackSvg;

/// The four boards of the sort (docs/design/m11/min-sizes.md section 3): a phone and the smallest phone put the bins on two or three **shelves**
/// stacked on the stage; a tablet puts them side by side on its wide card.
enum SortKind {
  phone,
  phoneSE,
  tabletL,
  tabletP;

  static SortKind of(ActivitySpec spec) => spec.stageIsCard
      ? (spec.boardHeight < 1000 ? tabletL : tabletP)
      : (spec.boardHeight > 380 ? phone : phoneSE);

  bool get tablet => this == tabletL || this == tabletP;
}

/// What a bin's sample picture is: one picture, a few of them in a line, or sticks that count the sides of a shape (a tally). [fit] is the picture cut
/// to its ink, so that its box can be as big as it needs for the ink to be seen; null for a tally and for the samples of a size rule (a big and a
/// small ball: the small one is small on purpose, and cutting it to its ink would draw it as big as the big one).
typedef BinMark = ({int count, bool tally, InkFit? fit});

/// Where everything of a sort board stands, in the stage's own points: the bins (shelves on a phone, bins on a tablet), the sign of each (its
/// sample picture and its label), the well where the cards that were sorted lie, and the slots of the cards in it.
///
/// A card is drawn at one size on a board and never smaller: the well shows the newest cards that fit and piles the earlier ones under the
/// first with a count badge (min-sizes.md R5). The strip's cards (a pattern of animals, 2.5 wide for 1 high) are 190 by 76 on a phone,
/// 170 by 68 on the smallest, 300 by 120 on a tablet's landscape and 280 by 112 on its portrait; a square picture is 48, 44 and 64. The label
/// is 18 points (24 on a tablet), weight 500, line height 1.7, grown with the text size where its box lets it ([SortBoard.scaleFor]).
/// The language's way: the first bin is at the top (phones) or at the right (tablets) and a sign stands at the start side, which is the right.
class SortBoard {
  SortBoard({
    required this.kind,
    required this.stage,
    required this.labels,
    required this.marks,
    required this.wide,
    this.share = false,
    this.bigMark = false,
    this.itemFits = const <InkFit>[],
    this.scale = 1,
  });

  final SortKind kind;
  final Size stage;
  final List<String> labels;
  final List<BinMark> marks;

  /// The cards are wide pictures (a pattern strip).
  final bool wide;

  /// A share: the bins are plates, the cards are small and the count on a plate shows (min-sizes.md 3.4).
  final bool share;

  /// The samples are of a size rule (a big and a small ball): the small one's ink is a third of its box, so the box is as large as the room lets it be.
  final bool bigMark;

  /// The pictures of the cards that are sorted (square ones), cut to their ink: the card of the board is as big as the flattest, tallest or thinnest of them
  /// needs for its ink to be seen (empty: the card is a square).
  final List<InkFit> itemFits;

  /// The size the labels are drawn at, as a multiple of their own size.
  final double scale;

  static const double border = 3;
  static const double itemGap = 8;
  static const double pileStep = 6;

  /// The room the edges of a pile take above and to the end side of its card (two edges).
  static const double pileRoom = 12;
  static const double stripAspect = 2.5;

  /// The ink a picture in a bin is drawn to have (the floor is 40, and a measure is good to a point): a little over it.
  static const double inkTarget = 42;

  bool get tablet => kind.tablet;
  bool get small => kind == SortKind.phoneSE;
  int get n => labels.length;
  double get font => tablet ? 24 : 18;
  double get line => font * scale * 1.7;
  double get inset => small ? 6 : 8;
  double get gap => tablet || n <= 2 ? 12 : 4;
  double get pad => small ? 6 : 8;

  /// The side of a bin's sample picture.
  double get markSide =>
      tablet ? (wide ? 56 : (bigMark ? 96 : 72)) : (n == 2 ? (bigMark ? (small ? 60 : 64) : 44) : 41.5);

  /// Three or more shelves on a phone are 76 high: the label stands beside the sample (as high as the shelf), not under it.
  bool get sideLabel =>
      !tablet &&
      !wide &&
      n >= 3 &&
      marks.every((BinMark m) => m.count <= 1 || m.tally) &&
      _single.every((double w) => w <= 84);

  /// The least a picture of a bin's sample takes when it is a few of them in a line: the item of a bin is 48 (44 on the smallest phone, 64 on a tablet).
  double get itemFloor => tablet ? 64 : (small ? 44 : 48);

  /// The room for a label of its natural lines (at most two) under (or beside) the sign's mark, whatever the mark's size: what a mark may grow into.
  int get _labelLines {
    int lines = 1;
    final double room = (tablet ? _binW / 2 : _colMax) - 12;
    for (final double w in _single) {
      lines = math.max(lines, (w / math.max(1, room)).ceil());
    }
    return math.min(lines, 2);
  }

  /// The tallest a sample's box may be: a phone's shelf less its label and the room round them; a tablet's header is a little taller than the mark's side.
  double get _markMaxH => tablet
      ? markSide + 24
      : math.max(markSide, _binH - 2 * border - 8 - (sideLabel ? 0 : _labelLines * line));

  /// The tallest of the sample boxes (what a shelf's sign or a bin's header has to hold).
  late final double _markH = <double>[for (int i = 0; i < n; i++) markSize(i).height]
      .fold(markSide, math.max);

  static TextStyle labelStyle(double font) => AppText.fixed(size: font, weight: 500);

  late final double _binW = tablet ? (stage.width - 2 * inset - gap * (n - 1)) / n : stage.width - 2 * inset;
  late final double _binH = tablet
      ? stage.height - 2 * inset
      : (stage.height - 2 * inset - gap * (n - 1)) / n;

  /// The bins, the first at the top (phone) or at the right (tablet).
  late final List<Rect> bins = <Rect>[
    for (int i = 0; i < n; i++)
      tablet
          ? Rect.fromLTWH(stage.width - inset - (i + 1) * _binW - i * gap, inset, _binW, _binH)
          : Rect.fromLTWH(inset, inset + i * (_binH + gap), _binW, _binH),
  ];

  // ---- the label ----

  late final List<double> _single = <double>[for (final String l in labels) _width(l, null).width];

  ({double width, int lines}) _width(String label, double? room) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: label, style: labelStyle(font)),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.linear(scale),
    )..layout(maxWidth: room ?? double.infinity);
    final ({double width, int lines}) r = (width: p.width, lines: p.computeLineMetrics().length);
    p.dispose();
    return r;
  }

  /// The most lines a label of a phone's shelf may take: what the shelf leaves under the mark.
  int get _linesMax =>
      tablet ? 2 : math.max(1, ((_binH - 2 * border - (sideLabel ? 0 : _markH) - 4) / line).floor());

  // ---- the card ----

  late final double _headerBase = tablet ? math.max(_markH, _linesIn() * line) + 12 : 0;

  int _linesIn() {
    int lines = 1;
    for (int i = 0; i < n; i++) {
      lines = math.max(lines, _width(labels[i], _tabletLabelRoom(i)).lines);
    }
    return math.min(lines, 2);
  }

  double _tabletLabelRoom(int i) => _binW - 2 * pad - markSize(i).width - 24;

  /// The height of the header row of a tablet's bin (its sign), 0 on a phone.
  double get headerH => _headerBase;

  late final Size card = _card();

  Size _card() {
    if (!wide) {
      // A share's plates show their cards at the item's floor too (a plate's count is what the badge says, and the cards are what a child touches).
      final double side = itemFloor;
      if (itemFits.isEmpty) return Size.square(side);
      // The card is as big as the flattest, tallest or thinnest picture of the sort needs (the shelf's well less its pile's room), and never under the floor.
      final Rect room = well(0);
      final double maxW = math.max(side, room.width - pileRoom);
      final double maxH = math.max(side, room.height - pileRoom);
      double w = side, h = side;
      for (final InkFit f in itemFits) {
        final Size b = f.boxFor(side, target: inkTarget, maxW: maxW, maxH: maxH);
        w = math.max(w, b.width);
        h = math.max(h, b.height);
      }
      return Size(w, h);
    }
    double h = tablet ? (kind == SortKind.tabletL ? 120 : 112) : (small ? 68 : 76);
    if (tablet) {
      h = math.min(h, (_binW - 2 * pad - pileRoom) / stripAspect);
      h = math.min(h, _binH - 2 * border - _headerBase - pad - pileRoom);
    } else {
      h = math.min(h, _binH - 2 * border - 8);
    }
    return Size(h * stripAspect, h);
  }

  // ---- the sign ----

  double get _colMin => small ? 60 : 72;
  late final double _colMax = math.max(
    _colMin,
    wide
        ? math.min(120.0, _binW - pad - border - (card.width + pileRoom))
        : math.max((sideLabel ? 0.62 : 0.45) * _binW, _lineOfSamples),
  );

  /// The sign column that a line of the most pictures a sample shows at the item's floor needs (at most 0.62 of the shelf).
  double get _lineOfSamples {
    int most = 0;
    for (final BinMark m in marks) {
      if (!m.tally && m.count > 1) most = math.max(most, m.count);
    }
    return math.min(0.62 * _binW, most * itemFloor / groupCellFill + 12 + 12);
  }

  /// The box of bin [i]'s sample picture: [markSide] square, or wider for a few pictures or a tally.
  Size markSize(int i) {
    final BinMark m = marks[i];
    // Beside a label of up to 84 points a sample may take what is left of the sign column.
    final double cap = (tablet ? _binW / 2 : _colMax) - 12 - (sideLabel ? 84 + 12 : 0);
    final InkFit? fit = m.fit;
    if (m.count <= 1) {
      return fit == null
          ? Size.square(markSide)
          : fit.boxFor(markSide, target: inkTarget, maxW: math.max(markSide, cap), maxH: _markMaxH);
    }
    if (m.tally) {
      final double s = tablet ? 12 : 9;
      return Size(math.min(cap, m.count * s + (m.count - 1) * 0.7 * s), markSide);
    }
    // A few pictures in a line: each picture (a group's picture fills a part of its cell) is a box of the item's floor at least, as many as the sign's room
    // allows at that size.
    double cell = math.max(markSide, itemFloor / groupCellFill);
    // On a shelf of 76 (three or more) a box that big and a label do not both fit: the pictures keep the sign's size, and are under the item's floor.
    if (!tablet && n >= 3) cell = markSide;
    if (fit != null && !(!tablet && n >= 3)) {
      // A narrow or a flat picture needs a bigger square for its ink to be seen.
      final Size need = fit.boxFor(itemFloor, target: inkTarget, maxW: 120, maxH: 120);
      cell = math.max(cell, math.max(need.width, need.height) / groupCellFill);
    }
    final double w = math.min(cap, m.count * cell);
    return Size(w, math.min(cell, w / m.count));
  }

  /// The width of a phone's sign column (the start side of a shelf): the widest of its marks and labels, between the least and what the card leaves.
  late final double signW = _signW();

  double _signW() {
    if (tablet) return 0;
    double need = _colMin;
    for (int i = 0; i < n; i++) {
      need = sideLabel
          ? math.max(need, markSize(i).width + _single[i] + 24)
          : math.max(need, math.max(markSize(i).width, math.min(_single[i], _colMax - 12)) + 12);
    }
    return math.min(_colMax, need);
  }

  /// The lines bin [i]'s label takes in its room.
  int linesOf(int i) => _width(labels[i], _labelRoom(i)).lines.clamp(1, _linesMax);

  /// The width bin [i]'s label has: a tablet's header less the mark, a shelf's sign column (less the mark where the label stands beside it).
  double _labelRoom(int i) =>
      tablet ? _tabletLabelRoom(i) : (sideLabel ? signW - markSize(i).width - 18 : signW - 12);

  /// True when every label fits its room in the lines the box has: otherwise the label is drawn smaller (see [scaleFor]).
  bool get fits {
    for (int i = 0; i < n; i++) {
      if (_width(labels[i], _labelRoom(i)).lines > _linesMax) return false;
    }
    return true;
  }

  /// The largest scale of the labels, up to the system's text size (at most [maxScale]), at which all of them fit; never under 1.
  static double scaleFor({
    required SortKind kind,
    required Size stage,
    required List<String> labels,
    required List<BinMark> marks,
    required bool wide,
    required double wanted,
    bool bigMark = false,
  }) {
    final double top = wanted.clamp(1.0, 1.3);
    for (double s = top; s > 1; s -= 0.05) {
      if (SortBoard(
        kind: kind,
        stage: stage,
        labels: labels,
        marks: marks,
        wide: wide,
        bigMark: bigMark,
        scale: s,
      ).fits) {
        return s;
      }
    }
    return 1;
  }

  /// The rectangle of a phone's sign column, or a tablet's header row, of bin [i].
  Rect sign(int i) {
    final Rect b = bins[i];
    return tablet
        ? Rect.fromLTRB(b.left + pad, b.top + border, b.right - pad, b.top + border + headerH)
        : Rect.fromLTRB(b.right - border - signW, b.top + border, b.right - border, b.bottom - border);
  }

  /// The box of bin [i]'s sample picture.
  Rect markRect(int i) {
    final Rect s = sign(i);
    final Size m = markSize(i);
    if (tablet) return Rect.fromLTWH(s.right - m.width, s.top + (s.height - m.height) / 2, m.width, m.height);
    if (sideLabel) {
      return Rect.fromLTWH(s.right - 6 - m.width, s.top + (s.height - m.height) / 2, m.width, m.height);
    }
    final double content = m.height + 4 + linesOf(i) * line;
    final double top = s.top + math.max(0, (s.height - content) / 2);
    return Rect.fromLTWH(s.center.dx - m.width / 2, top, m.width, m.height);
  }

  /// The box of bin [i]'s label.
  Rect labelRect(int i) {
    final Rect s = sign(i);
    final Rect m = markRect(i);
    if (tablet) return Rect.fromLTRB(s.left, s.top, m.left - 12, s.bottom);
    if (sideLabel) {
      final double h = linesOf(i) * line;
      return Rect.fromLTRB(s.left + 6, s.top + (s.height - h) / 2, m.left - 6, s.top + (s.height + h) / 2);
    }
    return Rect.fromLTWH(s.left + 6, m.bottom + 4, s.width - 12, linesOf(i) * line);
  }

  /// The middle of bin [i]'s sample picture.
  Offset sampleCentre(int i) => markRect(i).center;

  // ---- the well ----

  /// Where the cards lie in bin [i]: the rest of a shelf beside its sign, or a bin under its header.
  Rect well(int i) {
    final Rect b = bins[i];
    return tablet
        ? Rect.fromLTRB(b.left + pad, b.top + border + headerH, b.right - pad, b.bottom - border - pad)
        : Rect.fromLTRB(b.left + pad, b.top + border, b.right - border - signW, b.bottom - border);
  }

  late final int perRow = math.max(
    1,
    ((well(0).width - pileRoom + itemGap) / (card.width + itemGap)).floor(),
  );
  late final int rows = math.max(
    1,
    ((well(0).height - pileRoom + itemGap) / (card.height + itemGap)).floor(),
  );

  /// How many cards a bin shows at full size; the cards before them lie piled under the first.
  int get capacity => perRow * rows;

  /// The slot [k] (0 is the oldest of those shown) of bin [i]: from the start side, row by row, the block centred in the well.
  Rect slot(int i, int k) {
    final Rect w = well(i);
    final int r = k ~/ perRow;
    final int c = k % perRow;
    final double blockW = perRow * card.width + (perRow - 1) * itemGap;
    final double blockH = rows * card.height + (rows - 1) * itemGap;
    final double left = w.center.dx - blockW / 2 + (perRow - 1 - c) * (card.width + itemGap);
    final double top = w.top + (w.height - blockH) / 2 + pileRoom / 2 + r * (card.height + itemGap);
    return Rect.fromLTWH(left, top, card.width, card.height);
  }

  /// Where the hand puts a card into bin [i]: the middle of its well.
  Offset dropPlace(int i) => well(i).center;
}

/// The inside of a bin or a shelf (its sign and its well); the border, the ring and the touch are the session's.
class SortBinBody extends StatelessWidget {
  const SortBinBody({
    super.key,
    required this.board,
    required this.index,
    required this.binId,
    required this.mark,
    required this.cards,
  });

  final SortBoard board;
  final int index;
  final String binId;

  /// The sample picture of the bin's rule, drawn in [SortBoard.markRect].
  final Widget mark;

  /// The cards that lie in the bin, the oldest first: an id and its picture.
  final List<({String id, String svg})> cards;

  @override
  Widget build(BuildContext context) {
    final Rect origin = board.bins[index];
    Rect local(Rect r) => r.shift(-origin.topLeft);
    final int shown = math.min(cards.length, board.capacity);
    final int piled = cards.length - shown;
    final List<({String id, String svg})> visible = cards.sublist(cards.length - shown);
    final Rect first = local(board.slot(index, 0));
    final double edge = board.tablet ? 40 : (board.small ? 30 : 32);
    final bool count = piled > 0 || (board.share && cards.length > 1);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        Positioned.fromRect(rect: local(board.markRect(index)), child: mark),
        Positioned.fromRect(
          rect: local(board.labelRect(index)),
          child: Align(
            alignment: board.tablet
                ? AlignmentDirectional.centerStart
                : (board.sideLabel ? Alignment.center : Alignment.topCenter),
            child: Text(
              board.labels[index],
              key: Key('bin-label-$binId'),
              maxLines: board.linesOf(index),
              overflow: TextOverflow.ellipsis,
              textAlign: board.tablet ? TextAlign.start : TextAlign.center,
              textScaler: TextScaler.linear(board.scale),
              style: SortBoard.labelStyle(board.font),
            ),
          ),
        ),
        if (piled > 0)
          for (int e = math.min(2, piled); e >= 1; e--)
            Positioned.fromRect(
              key: e == 1 ? Key('bin-pile-$binId') : null,
              rect: first.shift(Offset(-SortBoard.pileStep * e, -SortBoard.pileStep * e)),
              child: Opacity(
                opacity: e == 1 ? 0.82 : 0.64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(TokenRadius.sm),
                    border: Border.all(color: TokenColors.ink, width: 2.5),
                  ),
                ),
              ),
            ),
        for (final (int k, ({String id, String svg}) c) in visible.indexed)
          Positioned.fromRect(
            rect: local(board.slot(index, k)),
            child: PackSvg(c.svg, key: Key('bin-card-${c.id}')),
          ),
        if (count)
          Positioned(
            left: first.left - SortBoard.pileStep * math.min(2, piled) - 2,
            top: first.top - SortBoard.pileStep * math.min(2, piled) - 2,
            child: CountBadge(key: Key('bin-count-$binId'), count: cards.length, side: edge),
          ),
      ],
    );
  }
}

/// The number of cards in a pile or on a plate: a white numeral, weight 800, on an ink circle, never mirrored.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.side});

  final int count;
  final double side;

  @override
  Widget build(BuildContext context) => Container(
    width: side,
    height: side,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: TokenColors.ink, shape: BoxShape.circle),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        '$count',
        style: AppText.fixed(
          size: side >= 40 ? 24 : 20,
          weight: 800,
          lineHeight: 1.1,
          color: TokenColors.paper,
        ),
        textScaler: TextScaler.noScaling,
      ),
    ),
  );
}

/// A tally of [count] sticks standing side by side: the wood of `stick_long` (an ink edge, a grain line, a light end), each [stickWidth] wide (9
/// on a phone, 12 on a tablet), as tall as the box is, with a gap of 0.7 of a stick's width.
class SortTally extends CustomPainter {
  const SortTally(this.count, this.stickWidth);

  final int count;
  final double stickWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = stickWidth;
    for (int i = 0; i < count; i++) {
      final double x = i * 1.7 * w;
      final RRect stick = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, w, size.height),
        Radius.circular(w * 0.4),
      );
      canvas
        ..drawRRect(stick, Paint()..color = const Color(0xFFC98F52))
        ..drawLine(
          Offset(x + w * 0.3, size.height * 0.15),
          Offset(x + w * 0.3, size.height * 0.85),
          Paint()
            ..color = const Color(0xFF9E6A35)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        )
        ..drawRRect(
          stick,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = TokenColors.ink,
        )
        ..drawOval(Rect.fromLTWH(x + 1, 1, w - 2, w * 0.55), Paint()..color = const Color(0xFFF2D7A6));
    }
  }

  @override
  bool shouldRepaint(covariant SortTally old) => old.count != count || old.stickWidth != stickWidth;
}

/// The sample picture of a bin in its box: one picture, a few of them in a line, or a tally of sticks.
Widget sortMark({
  required SortBoard board,
  required int index,
  required String svg,
  required bool tally,
  required double share,
}) {
  final BinMark m = board.marks[index];
  final Size box = board.markSize(index);
  if (m.count <= 1) {
    // A picture cut to its ink fills a box of its own shape; a size rule's sample is a square of its share of the room.
    final InkFit? fit = m.fit;
    return Center(
      child: fit == null
          ? SizedBox.square(key: const Key('bin-sample'), dimension: box.width * share, child: PackSvg(svg))
          : SizedBox.fromSize(key: const Key('bin-sample'), size: box, child: PackSvg(fit.svg)),
    );
  }
  if (tally) {
    return Center(
      child: CustomPaint(
        key: const Key('bin-tally'),
        size: box,
        painter: SortTally(m.count, board.tablet ? 12 : 9),
      ),
    );
  }
  return Center(
    child: SizedBox.fromSize(
      size: box,
      child: SpriteGroup(svg: m.fit?.svg ?? svg, count: m.count, arrangement: 'line', lineSlots: m.count),
    ),
  );
}

/// What the tray under (or beside) the stage looks like (docs/design/m11/min-sizes.md 3.2 to 3.4): on a phone a **deck**, one card on top as a
/// wide answer tile with the waiting cards as two edges under it, so that the child sorts one card at a time and a strip's animals are 25 points;
/// on a tablet all the cards: a grid of wide tiles for strips, a row (two rows from six) of the look's tile for square pictures.
class SortTray {
  SortTray._({
    required this.deck,
    required this.tile,
    required this.card,
    required this.spacing,
    required this.runSpacing,
  });

  /// The tray of [count] cards on [kind]'s board; [width] is the width of the tiles' box (the spec's `tilesWidth`), [look] the look's tile.
  factory SortTray.of({
    required SortKind kind,
    required bool wide,
    required int count,
    required double width,
    required double look,
  }) {
    if (!kind.tablet) {
      if (wide) {
        final double w = kind == SortKind.phoneSE ? 196 : 184;
        // The look's tile is the least an answer tile is (96 for the youngest); the deck's own is 88 (86 on the smallest phone) where that is more.
        final double h = math.max(look, kind == SortKind.phoneSE ? 86 : 88);
        return SortTray._(
          deck: true,
          tile: Size(w, h),
          card: Size(w - 8, (w - 8) / SortBoard.stripAspect),
          spacing: 0,
          runSpacing: 0,
        );
      }
      return SortTray._(
        deck: true,
        tile: Size.square(look),
        card: Size.square(look - 12),
        spacing: 0,
        runSpacing: 0,
      );
    }
    if (wide) {
      final bool land = kind == SortKind.tabletL;
      final int columns = count <= 4 ? 2 : 3;
      final double spacing = (columns == 2 ? 24 : 16) - 8;
      final double h = land ? 112 : 128;
      final double w = math.min(land ? 300.0 : 340.0, (width - (columns - 1) * spacing) / columns - 8);
      double cw = math.min(land ? 250.0 : 300.0, w - 12);
      cw = math.min(cw, (h - 8) * SortBoard.stripAspect);
      return SortTray._(
        deck: false,
        tile: Size(w, h),
        card: Size(cw, cw / SortBoard.stripAspect),
        spacing: spacing,
        runSpacing: 8,
      );
    }
    // The look's tile at any count: where the cards do not fit one row they stand in two, and the card above is as tall as that leaves (see `layoutFor`).
    return SortTray._(
      deck: false,
      tile: Size.square(look),
      card: Size.square(look - 12),
      spacing: 4,
      runSpacing: 4,
    );
  }

  final bool deck;

  /// The tile's size, and the card (the picture) inside it.
  final Size tile;
  final Size card;

  /// The room between tiles' tap margins, along a row and between rows (the tiles' own margins of 4 come on top).
  final double spacing;
  final double runSpacing;

  /// What the edges of a deck add under its top card.
  static const double deckEdges = 12;

  /// The height of the tiles' box with its tap margin (a deck adds its edges).
  double boxHeight(int count, double width) => deck
      ? tile.height + 8 + deckEdges
      : rowsFor(count, width) * (tile.height + 8) + (rowsFor(count, width) - 1) * runSpacing;

  int perRow(double width) => math.max(1, ((width + spacing) / (tile.width + 8 + spacing)).floor());
  int rowsFor(int count, double width) => deck ? 1 : (count / perRow(width)).ceil();

  /// Where tile [i] of [count] stands: the middle of its top edge, from the tiles' box's left edge and top (the tap margin 4 under the top).
  /// The first tile is at the right, as the language's rows are.
  Offset tip(int count, int i, double width) {
    if (deck) return Offset(width / 2, 4);
    final int per = perRow(width);
    final int r = i ~/ per;
    final int c = i % per;
    final int inRow = math.min(per, count - r * per);
    final double slot = tile.width + 8;
    final double rowW = inRow * slot + (inRow - 1) * spacing;
    final double start = (width - rowW) / 2;
    return Offset(width - start - (c + 0.5) * slot - c * spacing, 4 + r * (tile.height + 8 + runSpacing));
  }
}
