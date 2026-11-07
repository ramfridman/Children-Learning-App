import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/course_text.dart';
import '../design/tokens.g.dart';
import 'ls01_metrics.dart';

// A written sentence on the stage (docs/design/languages-l5-ls01.md sections 4.1, 7.8 and 7.9): a text stem of more than one word, or the
// sentence of a cloze. It wraps only at spaces, never inside a word, never with a hyphen; it is start-aligned in the course's direction;
// each word can carry the 6 point bar that walks under the words while they are read ("read it to me"); a `_` is the gap of a cloze, one
// unbreakable piece as wide as the widest option and 16 more. It is held to its room: when the system's text scale would make it taller than
// the stage it is drawn at the largest scale that fits, and never below its reading size.

/// The text split into its pieces: the words, and the gap where a `_` stood (with the punctuation that stuck to it).
List<({String before, bool gap, String after, String word})> sentencePieces(
  String text,
) => <({String before, bool gap, String after, String word})>[
  for (final String w in text.split(' '))
    if (w.isNotEmpty)
      if (w.contains('_'))
        (before: w.substring(0, w.indexOf('_')), gap: true, after: w.substring(w.indexOf('_') + 1), word: w)
      else
        (before: '', gap: false, after: '', word: w),
];

/// How a sentence lays out: its lines, how tall it stands and the widest unit that cannot be broken, at a text scale.
typedef SentenceMeasure = ({int lines, double height, double widest});

/// The units a sentence breaks between: each word, and the gap of a cloze. The Hebrew course keeps the gap together with the word after it
/// (it is read as one phrase), so that the gap lands in the middle of a line when it can. Each unit lists the indexes of [sentencePieces] it holds.
List<List<int>> sentenceUnits(String text, {required bool gapWithNext}) {
  final List<({String before, bool gap, String after, String word})> pieces = sentencePieces(text);
  final List<List<int>> units = <List<int>>[];
  for (int i = 0; i < pieces.length; i++) {
    if (gapWithNext && pieces[i].gap && i + 1 < pieces.length) {
      units.add(<int>[i, i + 1]);
      i++;
    } else {
      units.add(<int>[i]);
    }
  }
  return units;
}

/// Measures [text] in a column [column] wide at [scale] times its reading size, the way [Ls01Sentence] lays it out, so that the widget, the
/// choice of its scale and the fit check agree. [gapTextWidth] is the widest option (the gap is that wide and 16 more).
SentenceMeasure measureSentence(
  Ls01Metrics m,
  String text,
  FaceKind kind, {
  required double gapTextWidth,
  required double column,
  double scale = 1,
}) {
  final double size = m.size(kind);
  final double spacing = size * 0.3 * scale;
  double widthOf(String w) => m.textWidth(w, kind) * scale;
  double lineOf(String w) => size * scale * lineHeightFor(w, hebrew: m.hebrew);
  final List<({String before, bool gap, String after, String word})> pieces = sentencePieces(text);
  final List<double> pieceWidths = <double>[
    for (final ({String before, bool gap, String after, String word}) p in pieces)
      p.gap ? widthOf(p.before) + gapTextWidth * scale + 16 + widthOf(p.after) : widthOf(p.word),
  ];
  double line = 0;
  for (final ({String before, bool gap, String after, String word}) p in pieces) {
    if (!p.gap) {
      line = math.max(line, lineOf(p.word));
      continue;
    }
    line = math.max(line, size * scale * lineHeightFor('x', hebrew: m.hebrew) + 4);
    if (p.before.isNotEmpty) line = math.max(line, lineOf(p.before));
    if (p.after.isNotEmpty) line = math.max(line, lineOf(p.after));
  }
  final List<double> unitWidths = <double>[
    for (final List<int> u in sentenceUnits(text, gapWithNext: m.hebrew))
      u.fold<double>(0, (double sum, int i) => sum + (sum > 0 ? spacing : 0) + pieceWidths[i]),
  ];
  final int lines = Ls01Metrics.wrapLines(unitWidths, column, spacing);
  return (
    lines: lines,
    height: lines * line + (lines - 1) * size * 0.1 * scale,
    widest: unitWidths.fold<double>(0, math.max),
  );
}

/// The scale a sentence is drawn at: the system's text scale (never below 1: a text is not drawn smaller than its reading size), lowered in
/// steps of 0.05 while it does not fit its room, in the column and in height. At 1 it is the layout the fit check proved.
double fitSentenceScale(
  Ls01Metrics m,
  String text,
  FaceKind kind,
  TextScaler system, {
  required double gapTextWidth,
  required double column,
  required double height,
}) {
  final double size = m.size(kind);
  final double wanted = math.max(1, system.scale(size) / size);
  if (!height.isFinite || !column.isFinite) return wanted;
  for (double s = wanted; s > 1.0001; s -= 0.05) {
    final SentenceMeasure at = measureSentence(
      m,
      text,
      kind,
      gapTextWidth: gapTextWidth,
      column: column,
      scale: s,
    );
    if (at.widest <= column + 0.01 && at.height <= height + 0.01) return s;
  }
  return 1;
}

class Ls01Sentence extends StatelessWidget {
  const Ls01Sentence({
    super.key,
    required this.text,
    required this.metrics,
    required this.kind,
    required this.direction,
    this.litWord,
    this.gap,
    this.gapTextWidth = 0,
  });

  final String text;
  final Ls01Metrics metrics;

  /// `stem` for one word alone on the stage, `line` for a sentence.
  final FaceKind kind;
  final TextDirection direction;

  /// The word under which the bar of a reading stands now, as an index of [sentencePieces] (the gap counts as a word).
  final int? litWord;

  /// What stands in place of the `_` (a [GapBox]); null for a text with no gap. [gapTextWidth] is the widest option's width at the reading size.
  final Widget? gap;
  final double gapTextWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints room) {
      final double scale = fitSentenceScale(
        metrics,
        text,
        kind,
        MediaQuery.textScalerOf(context),
        gapTextWidth: gapTextWidth,
        column: room.maxWidth,
        height: room.maxHeight,
      );
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: _sentence(scale),
      );
    },
  );

  Widget _sentence(double scale) {
    final double size = metrics.size(kind);
    Widget word(String w) => CourseText(
      w,
      course: metrics.course,
      size: size,
      lineHeight: lineHeightFor(w, hebrew: metrics.hebrew),
    );
    final List<({String before, bool gap, String after, String word})> pieces = sentencePieces(text);
    final double spacing = size * 0.3 * scale;
    Widget piece(int i) {
      final ({String before, bool gap, String after, String word}) p = pieces[i];
      return IntrinsicWidth(
        key: Key('sentence-word-$i'),
        // The bar lies on the foot of the line's own box, under the letters: it takes no room, so a sentence is as tall with it as without.
        child: Stack(
          children: <Widget>[
            if (p.gap)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (p.before.isNotEmpty) word(p.before),
                  gap ?? const SizedBox.shrink(),
                  if (p.after.isNotEmpty) word(p.after),
                ],
              )
            else
              word(p.word),
            if (litWord == i) const Positioned(left: 0, right: 0, bottom: 0, child: _Bar()),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: direction,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: spacing,
        runSpacing: size * 0.1 * scale,
        children: <Widget>[
          for (final List<int> unit in sentenceUnits(text, gapWithNext: metrics.hebrew))
            if (unit.length == 1)
              piece(unit.first)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final int i in unit) ...<Widget>[
                    if (i != unit.first) SizedBox(width: spacing),
                    piece(i),
                  ],
                ],
              ),
        ],
      ),
    );
  }
}

/// The bar under a word that is being read: 6 points of `skyDeep`, at the foot of the word's box.
class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('word-bar'),
    height: 6,
    decoration: BoxDecoration(color: TokenColors.skyDeep, borderRadius: BorderRadius.circular(3)),
  );
}

/// The gap of a cloze: empty, a dashed box of `lilacDeep`; with a word in it, the same box solid; right, `sparkTint` with the check. It is as
/// wide as the widest option ([textWidth], at the reading size) and 16 more, and as tall as a line of text ([textHeight]) and 4 more, both
/// following the text scale the sentence is drawn at.
class GapBox extends StatelessWidget {
  const GapBox({
    super.key,
    required this.textWidth,
    required this.textHeight,
    this.child,
    this.right = false,
    this.lit = false,
  });

  final double textWidth;
  final double textHeight;

  /// The word in the gap, or null while it is empty.
  final Widget? child;
  final bool right;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      key: const Key('cloze-gap'),
      width: scaler.scale(textWidth) + 16,
      height: scaler.scale(textHeight) + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: DashedBoxPainter(
                dashed: child == null,
                fill: right ? TokenColors.sparkTint : null,
                color: right ? TokenColors.spark : TokenColors.lilacDeep,
              ),
              child: Center(child: child),
            ),
          ),
          if (lit)
            const Positioned(
              left: -6,
              right: -6,
              top: -6,
              bottom: -6,
              child: IgnorePointer(child: DecoratedBox(decoration: _litRing)),
            ),
          if (right)
            const Positioned(
              right: -6,
              top: -10,
              child: Icon(Icons.check_circle_rounded, size: 24, color: TokenColors.spark),
            ),
        ],
      ),
    );
  }

  static const BoxDecoration _litRing = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: Border.fromBorderSide(BorderSide(color: TokenColors.hintHalo, width: 4)),
  );
}

/// A rounded box drawn with a 3 point line: dashed while it is empty (the gap of a cloze, the place of an order still to fill), solid when
/// it holds something.
class DashedBoxPainter extends CustomPainter {
  DashedBoxPainter({required this.dashed, required this.color, this.fill, this.radius = 14});

  final bool dashed;
  final Color color;
  final Color? fill;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect box = RRect.fromRectAndRadius((Offset.zero & size).deflate(1.5), Radius.circular(radius));
    if (fill != null) canvas.drawRRect(box, Paint()..color = fill!);
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    if (!dashed) {
      canvas.drawRRect(box, line);
      return;
    }
    final Path path = Path()..addRRect(box);
    for (final metric in path.computeMetrics()) {
      double at = 0;
      while (at < metric.length) {
        canvas.drawPath(metric.extractPath(at, (at + 9).clamp(0, metric.length)), line);
        at += 15;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBoxPainter old) =>
      old.dashed != dashed || old.color != color || old.fill != fill || old.radius != radius;
}
