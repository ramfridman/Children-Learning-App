import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/target_text.dart';
import '../design/token_types.dart';
import '../design/tokens.g.dart';
import '../engine/course.dart';

// The sizes of the text faces and tiles of LS01 (docs/design/languages-l5-ls01.md sections 3 and 4), in one place that the tiles, the
// sessions and the fit test all read, so that what the test measures is what the screen draws.

/// What a text face is. Each kind has a reading size per band, script and board, and a text is never drawn smaller than it.
enum FaceKind {
  /// One or two letters, no more (a tile, a bin sign): b, sh, ck, a unit like בָּ.
  letter,

  /// A word or a short phrase on a tile.
  word,

  /// A sentence on the stage (a stem of more than one word, a cloze).
  line,

  /// A stem of one word, unit or letter, alone on the stage.
  stem,

  /// A card already sorted, a pair already made: nothing is asked of it.
  kept,
}

/// A Hebrew pointed text keeps its line height (1.7); a single letter with no marks has no marks to keep apart and is set at 1.2.
double lineHeightFor(String text, {required bool hebrew}) {
  final bool marks = text.runes.any((int r) => (r >= 0x0300 && r <= 0x036F) || (r >= 0x05B0 && r <= 0x05C7));
  final int letters = text.runes
      .where((int r) => !(r >= 0x0300 && r <= 0x036F) && !(r >= 0x05B0 && r <= 0x05C7))
      .length;
  if (letters == 1 && !marks) return 1.2;
  return hebrew ? 1.7 : 1.3;
}

/// One row of equal tiles: how wide each is, the gap between them, and whether the row fits its zone.
class RowPlan {
  const RowPlan({
    required this.tileWidth,
    required this.tileHeight,
    required this.gap,
    required this.count,
    required this.zoneWidth,
    required this.widest,
    required this.textLimit,
    required this.pad,
  });

  /// The padding inside a word tile, on each side.
  final double pad;

  final double tileWidth;
  final double tileHeight;
  final double gap;
  final int count;
  final double zoneWidth;

  /// The widest text of the row, and the widest a text could be and still fit (a tile less its padding), both in points.
  final double widest;
  final double textLimit;

  /// The same row for [n] tiles (the tiles that are left when some have been used): the width of a tile stays.
  RowPlan withCount(int n) => RowPlan(
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    gap: gap,
    count: n,
    zoneWidth: zoneWidth,
    widest: widest,
    textLimit: zoneWidth / math.max(1, n) - gap - 2 * pad,
    pad: pad,
  );

  /// The space a tile takes in the row: its width and its gap (the hit areas of neighbours meet in the middle of the gap).
  double get cell => tileWidth + gap;

  double get total => count * cell;

  bool get fits => total <= zoneWidth + 0.01;

  /// The tile is the square of the band (a letter, a picture, a sound) and not wider.
  bool get square => (tileWidth - tileHeight).abs() < 0.5;
}

/// The numbers of LS01 for one band, one board and one course.
class Ls01Metrics {
  const Ls01Metrics({required this.band, required this.tablet, required this.course});

  /// The metrics of the activity's course on the board [spec] describes (a tablet shows the stage on a card).
  factory Ls01Metrics.of({required Band band, required ActivitySpec spec, required String course}) =>
      Ls01Metrics(band: band, tablet: spec.stageIsCard, course: course);

  final Band band;
  final bool tablet;
  final String course;

  bool get hebrew => !(course == Course.eng || course == Course.rus);

  /// The size [kind] is read at (docs/design/languages-l5-ls01.md section 3.2): never drawn below it.
  double size(FaceKind kind) => TokenReading.sizes[kind.name]![band]!.of(hebrew: hebrew, tablet: tablet);

  /// The height of a tile, and the side of a square one: 96 / 112 in Band A, 88 / 104 in Band B, 80 / 96 in Band C.
  double get tileHeight => tablet ? TokenTouch.band[band]!.answerTablet : TokenTouch.band[band]!.answerPhone;

  /// The gap between square tiles (24 on a phone, the band's on a tablet) and between wide ones (the band's own).
  double get squareGap => tablet ? TokenTouch.band[band]!.gapTablet : 24;
  double get wideGap => tablet ? TokenTouch.band[band]!.gapTablet : TokenTouch.band[band]!.gapPhone;

  /// The room above and below a tile that still counts as touching it.
  double get hitSlop => TokenTouch.band[band]!.hitSlop;

  /// The padding inside a word tile, on each side.
  double get wordPad => switch (band) {
    Band.a || Band.b => tablet ? 16 : 14,
    Band.c => tablet ? 14 : 12,
  };

  TextStyle styleFor(String text, FaceKind kind) {
    final bool bold = kind == FaceKind.letter;
    final double size = this.size(kind);
    return hebrew
        ? AppText.fixed(size: size, weight: bold ? 700 : 500, lineHeight: lineHeightFor(text, hebrew: true))
        : targetStyle(size: size, bold: bold, lineHeight: lineHeightFor(text, hebrew: false));
  }

  /// How wide [text] is at the reading size of [kind], on one line.
  double textWidth(String text, FaceKind kind) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: text, style: styleFor(text, kind)),
      textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
      locale: Locale(hebrew ? 'he' : (course == Course.rus ? 'ru' : 'en')),
      maxLines: 1,
    )..layout();
    final double w = p.width;
    p.dispose();
    return w;
  }

  /// The lines [text] takes in a column [width] wide at the reading size of [kind], broken at spaces only; and the widest word, which
  /// cannot be broken (a column narrower than it cuts the word).
  ({int lines, double widestWord}) lines(String text, FaceKind kind, double width) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: text, style: styleFor(text, kind)),
      textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
      locale: Locale(hebrew ? 'he' : (course == Course.rus ? 'ru' : 'en')),
    )..layout(maxWidth: width);
    final int n = p.computeLineMetrics().length;
    p.dispose();
    double widest = 0;
    for (final String w in text.split(' ')) {
      if (w.isNotEmpty) widest = math.max(widest, textWidth(w, kind));
    }
    return (lines: n, widestWord: widest);
  }

  /// How many lines a sentence takes in a column [column] wide when it is made of pieces that cannot be broken, [widths] points each, set
  /// [spacing] apart and broken between pieces only (the way `Ls01Sentence` wraps a stem or a cloze).
  static int wrapLines(List<double> widths, double column, double spacing) {
    int lines = 1;
    double used = 0;
    for (final double w in widths) {
      if (used > 0 && used + spacing + w > column + 0.01) {
        lines++;
        used = w;
      } else {
        used += (used > 0 ? spacing : 0) + w;
      }
    }
    return lines;
  }

  /// The row of equal tiles for [texts] ([kind] is `letter` or `word`) in a zone [zoneWidth] wide, with [extra] more points beside each
  /// tile (a speaker). One width for the row: the widest text and the padding, and at least the square of the band.
  RowPlan row(List<String> texts, FaceKind kind, double zoneWidth, {int? count}) {
    double widest = 0;
    for (final String t in texts) {
      widest = math.max(widest, textWidth(t, kind));
    }
    final double width = math.max(tileHeight, widest + 2 * wordPad);
    final bool square = (width - tileHeight).abs() < 0.5;
    final double gap = square ? squareGap : wideGap;
    final int n = count ?? texts.length;
    return RowPlan(
      tileWidth: width,
      tileHeight: tileHeight,
      gap: gap,
      count: n,
      zoneWidth: zoneWidth,
      widest: widest,
      textLimit: zoneWidth / math.max(1, n) - gap - 2 * wordPad,
      pad: wordPad,
    );
  }

  /// How many square tiles of the band fit a zone [zoneWidth] wide.
  int squaresIn(double zoneWidth) => (zoneWidth / (tileHeight + squareGap)).floor();
}
