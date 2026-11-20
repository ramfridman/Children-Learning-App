import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'hints/tap_plans.dart' show inkBoxOf, inkedSvg;

/// A pack picture cut to its ink, and the box it needs for the ink to be seen (docs/design/m11/min-sizes.md R1, R5).
///
/// Most pack pictures stand in a wide margin of their own drawing box: a block lies flat in the middle of a square, a tower is a thin stick, a
/// ball fills 72 hundredths. A box of 48 then shows 20 or 30 points of picture. The picture is drawn **cut to its ink** (see [inkedSvg]), so
/// that it fills the box; and a box for a flat or a tall picture is as long as the picture needs, not a square: the ink a child sees is the
/// side of the square of the same area as the picture, and never less than half its longest side (a thin line has no area).
class InkFit {
  const InkFit._(this.svg, this.aspect, this.inkW, this.inkH);

  /// The picture cut to its ink.
  final String svg;

  /// Width over height of the cut picture's drawing box.
  final double aspect;

  /// How much of the cut picture's box the ink covers (0 to 1 each way): what is left of it is the room for the stroke.
  final double inkW;
  final double inkH;

  /// The cut picture of [svg], read once.
  factory InkFit.of(String svg) => _fits.putIfAbsent(svg, () {
    final String cut = inkedSvg(svg).$1;
    final RegExpMatch? vb = RegExp(r'viewBox="\s*[-\d.]+[\s,]+[-\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)')
        .firstMatch(cut);
    final double w = double.tryParse(vb?[1] ?? '') ?? 1;
    final double h = double.tryParse(vb?[2] ?? '') ?? 1;
    final Rect ink = inkBoxOf(cut);
    return InkFit._(cut, h > 0 && w > 0 ? w / h : 1, ink.width, ink.height);
  });

  static final Map<String, InkFit> _fits = <String, InkFit>{};

  /// The ink of the picture when it is drawn with [drawn] as its width and height: as the minimum-size test reads it.
  double inkOf(double drawnW, double drawnH) {
    final double w = inkW * drawnW;
    final double h = inkH * drawnH;
    return math.max(math.sqrt(w * h), 0.5 * math.max(w, h));
  }

  /// The box (at least [side] each way) in which the picture, drawn as large as the box lets it be, has [target] ink: a square where [side] is enough,
  /// longer along the picture's long side where it is not, never past [maxW] by [maxH]. The picture is drawn contained in the box.
  Size boxFor(double side, {required double target, required double maxW, required double maxH}) {
    double longest = side;
    Size drawn(double l) => aspect >= 1 ? Size(l, l / aspect) : Size(l * aspect, l);
    for (; longest < 400; longest += 2) {
      final Size d = drawn(longest);
      if (inkOf(d.width, d.height) >= target || d.width >= maxW || d.height >= maxH) break;
    }
    final Size d = drawn(longest);
    return Size(math.min(maxW, math.max(side, d.width)), math.min(maxH, math.max(side, d.height)));
  }
}
