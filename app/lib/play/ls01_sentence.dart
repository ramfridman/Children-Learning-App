import 'package:flutter/material.dart';

import '../design/course_text.dart';
import '../design/tokens.g.dart';
import 'ls01_metrics.dart';

// A written sentence on the stage (docs/design/languages-l5-ls01.md sections 4.1, 7.8 and 7.9): a text stem of more than one word, or the
// sentence of a cloze. It wraps only at spaces, never inside a word, never with a hyphen; it is start-aligned in the course's direction;
// each word can carry the 6 point bar that walks under the words while they are read ("read it to me"); a `_` is the gap of a cloze, one
// unbreakable piece as wide as the widest option and 16 more.

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

class Ls01Sentence extends StatelessWidget {
  const Ls01Sentence({
    super.key,
    required this.text,
    required this.metrics,
    required this.kind,
    required this.direction,
    this.litWord,
    this.gap,
  });

  final String text;
  final Ls01Metrics metrics;

  /// `stem` for one word alone on the stage, `line` for a sentence.
  final FaceKind kind;
  final TextDirection direction;

  /// The word under which the bar of a reading stands now, as an index of [sentencePieces] (the gap counts as a word).
  final int? litWord;

  /// What stands in place of the `_` (a [GapBox]); null for a text with no gap.
  final Widget? gap;

  @override
  Widget build(BuildContext context) {
    final double size = metrics.size(kind);
    Widget word(String w) => CourseText(
      w,
      course: metrics.course,
      size: size,
      lineHeight: lineHeightFor(w, hebrew: metrics.hebrew),
    );
    final List<({String before, bool gap, String after, String word})> pieces = sentencePieces(text);
    return Directionality(
      textDirection: direction,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: size * 0.3,
        runSpacing: size * 0.1,
        children: <Widget>[
          for (final (int i, ({String before, bool gap, String after, String word}) p) in pieces.indexed)
            IntrinsicWidth(
              key: Key('sentence-word-$i'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  _Bar(on: litWord == i),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The bar under a word that is being read: 6 points of `skyDeep` while it is read, the same room empty before and after, so that
/// nothing moves when it appears.
class _Bar extends StatelessWidget {
  const _Bar({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    key: on ? const Key('word-bar') : null,
    height: 6,
    margin: const EdgeInsets.only(top: 2),
    decoration: BoxDecoration(color: on ? TokenColors.skyDeep : null, borderRadius: BorderRadius.circular(3)),
  );
}

/// The gap of a cloze: empty, a dashed box of `lilacDeep`; with a word in it, the same box solid; right, `sparkTint` with the check.
class GapBox extends StatelessWidget {
  const GapBox({
    super.key,
    required this.width,
    required this.height,
    this.child,
    this.right = false,
    this.lit = false,
  });

  final double width;
  final double height;

  /// The word in the gap, or null while it is empty.
  final Widget? child;
  final bool right;
  final bool lit;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('cloze-gap'),
    width: width,
    height: height,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: _GapPainter(
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

  static const BoxDecoration _litRing = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: Border.fromBorderSide(BorderSide(color: TokenColors.hintHalo, width: 4)),
  );
}

class _GapPainter extends CustomPainter {
  _GapPainter({required this.dashed, required this.color, this.fill});

  final bool dashed;
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect box = RRect.fromRectAndRadius((Offset.zero & size).deflate(1.5), const Radius.circular(14));
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
  bool shouldRepaint(_GapPainter old) => old.dashed != dashed || old.color != color || old.fill != fill;
}
