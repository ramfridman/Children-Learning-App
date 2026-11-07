import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/app_text.dart';
import '../design/board.dart' show BoardClass;
import '../design/target_text.dart';
import '../design/token_types.dart' show Band;
import '../engine/course.dart';
import 'ls01_metrics.dart' show lineHeightFor;

// Where the slide of LS04 stands (docs/design/l5-templates.md section 5): the word at the slide size on a page, a mark under each part threaded on a track,
// and the knob at its rest. The parts' boxes come from the shaped text (`TextPainter.getBoxesForSelection` for each part), never from equal shares, so a
// mark is under the letters it belongs to whatever the font does. All in board points.

/// The size the word is slid at: a text face of its own, never below the band's stem size (a tablet's tall stage takes a bigger word).
double slideSizeOf(BoardClass board, Band band, {required bool hebrew}) {
  final bool tablet = board == BoardClass.tabletLandscape || board == BoardClass.tabletPortrait;
  final bool c = band == Band.c;
  if (tablet) return hebrew ? (c ? 64 : 80) : (c ? 80 : 96);
  if (board == BoardClass.phoneSE) return hebrew ? (c ? 42 : 44) : (c ? 48 : 52);
  return hebrew ? (c ? 44 : 46) : (c ? 52 : 56);
}

/// The slide knob: 56 points (72 on a tablet), the Band B control floor.
double knobSizeOf(BoardClass board) =>
    board == BoardClass.tabletLandscape || board == BoardClass.tabletPortrait ? 72 : 56;

/// The text style of the word: the teaching font for English and Russian, Heebo at the nikud line height for Hebrew.
TextStyle slideStyle(String course, double size, String text) => course == Course.heb
    ? AppText.fixed(size: size, weight: 500, lineHeight: lineHeightFor(text, hebrew: true))
    : targetStyle(size: size, lineHeight: lineHeightFor(text, hebrew: false));

class SlideGeometry {
  SlideGeometry._({
    required this.page,
    required this.painter,
    required this.origin,
    required this.spans,
    required this.trackY,
    required this.xs,
    required this.xe,
    required this.knob,
    required this.rtl,
    required this.size,
  });

  /// The geometry of [word] on [page] (the stage's inner room, in board points) for a course that reads [rtl] or not.
  factory SlideGeometry.of({
    required Rect page,
    required String course,
    required BlendWord word,
    required BoardClass board,
    required Band band,
  }) {
    final bool rtl = course == Course.heb;
    final double size = slideSizeOf(board, band, hebrew: rtl);
    final double knob = knobSizeOf(board);
    final TextPainter tp = TextPainter(
      text: TextSpan(text: word.text, style: slideStyle(course, size, word.text)),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      locale: Locale(rtl ? 'he' : (course == Course.rus ? 'ru' : 'en')),
    )..layout();
    // The vertical budget: the line, two points, the knob; centred on the page.
    final double block = tp.height + 2 + knob;
    final double top = page.top + math.max(0, (page.height - block) / 2);
    final Offset origin = Offset(page.center.dx - tp.width / 2, top);
    final List<Rect> spans = <Rect>[];
    int at = 0;
    for (final BlendPart p in word.parts) {
      final int next = at + p.text.length;
      final List<TextBox> boxes = tp.getBoxesForSelection(TextSelection(baseOffset: at, extentOffset: next));
      Rect r = boxes.isEmpty ? Rect.zero : boxes.first.toRect();
      for (final TextBox b in boxes.skip(1)) {
        r = r.expandToInclude(b.toRect());
      }
      spans.add(r.shift(origin));
      at = next;
    }
    final double trackY = top + tp.height + 2 + knob / 2;
    final double start = rtl ? origin.dx + tp.width + 0.75 * knob : origin.dx - 0.75 * knob;
    final double end = rtl ? origin.dx : origin.dx + tp.width;
    return SlideGeometry._(
      page: page,
      painter: tp,
      origin: origin,
      spans: spans,
      trackY: trackY,
      xs: start,
      xe: end,
      knob: knob,
      rtl: rtl,
      size: size,
    );
  }

  final Rect page;
  final TextPainter painter;
  final Offset origin;

  /// The box of each part, on the board.
  final List<Rect> spans;
  final double trackY;

  /// The knob's centre at rest, and where the word ends: the knob travels between them, in the reading direction.
  final double xs;
  final double xe;
  final double knob;
  final bool rtl;
  final double size;

  double get length => (xe - xs).abs();

  /// The direction of the slide along x: right for English and Russian, left for Hebrew.
  double get sign => rtl ? -1 : 1;

  /// The knob's x at progress [t] (0 at rest, 1 at the end of the word).
  double xAt(double t) => xs + sign * t.clamp(0, 1) * length;

  /// The progress of a knob whose centre is at [x].
  double tAt(double x) => (((x - xs) * sign) / length).clamp(0, 1);

  /// The part the knob's centre is in, or null before the word starts.
  int? partAt(double x) {
    for (int i = 0; i < spans.length; i++) {
      final double a = rtl ? spans[i].right : spans[i].left;
      final double b = rtl ? spans[i].left : spans[i].right;
      final double from = math.min(a, b);
      final double to = math.max(a, b);
      if (x >= from - 0.01 && x <= to + 0.01) return i;
    }
    return null;
  }

  /// The progress that puts the knob at the middle of part [i].
  double tOfPart(int i) => tAt(spans[i].center.dx);

  /// The mark of part [i] (a dot for a letter, a bar for a digraph or a unit): its centre on the track.
  Offset markAt(int i) => Offset(spans[i].center.dx, trackY);

  /// The track's end past the word, where the arrowhead stands.
  double get arrowX => xe + sign * (knob * 0.35);
}
