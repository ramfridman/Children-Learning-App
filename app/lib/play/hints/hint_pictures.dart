import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../design/app_text.dart';
import '../../design/tokens.g.dart';
import '../hint_hand.dart';
import '../hint_widgets.dart';
import '../template_session.dart';
import 'hint_marks.dart';

// The shared hint pictures of B-40 (design spec sections 1 to 3): a sky glow means "look here", a sky card means "another way",
// the sky hand means "watch me". Every picture is sky (`hintHalo`, `skyTint`, `skyDeep`), never red, takes no touch, comes to rest,
// and has a still version for "reduce motion" (it appears with a 200 ms fade, in the same order).
//
// Keys for the tests: `hint-p1` (spotlight), `hint-p2` (a lit ring), `hint-p5` (pair lines), `hint-p6` (number path), `hint-p9`
// (a sample: swatch or ghost outline), `hint-p12` (the pointing hand), and `seen-dot` for a small dot that stays.

/// How much bigger than a phone's stage (128 high) the hint pictures are: 1 on a phone, a little less on the small phone (never
/// under 0.85, so the minimum sizes of the spec hold) and at most 1.4 on a tablet.
double hintScale(Size stage) => (stage.height / 128).clamp(0.85, 1.4).toDouble();

/// Draws [marks] over a stage of [size]. It sits above the stage, takes no touch, and may draw beyond the stage's edge (the hand's
/// fingertip ends on the top edge of an answer tile).
class HintOverlay extends StatelessWidget {
  const HintOverlay({super.key, required this.marks, required this.size});

  final List<HintMark> marks;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final double k = hintScale(size);
    final List<Widget> veils = <Widget>[];
    final List<Widget> body = <Widget>[];
    final List<Widget> hands = <Widget>[];
    for (final (int i, HintMark m) in marks.indexed) {
      final Widget w = _draw(context, m, i, k);
      (m is VeilMark ? veils : (m is HandMark ? hands : body)).add(w);
    }
    return IgnorePointer(
      child: SizedBox.fromSize(
        size: size,
        child: Stack(clipBehavior: Clip.none, children: <Widget>[...veils, ...body, ...hands]),
      ),
    );
  }

  Widget _draw(BuildContext context, HintMark m, int i, double k) {
    final Key key = ValueKey<int>(i);
    switch (m) {
      case VeilMark():
        return Positioned.fill(
          key: key,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TokenRadius.lg),
            child: Appear(
              child: CustomPaint(key: const Key('hint-p1'), painter: _VeilPainter(m.holes, k)),
            ),
          ),
        );
      case RingMark():
        final double side = math.max(m.rect.width, m.rect.height) + 12 * k;
        final Rect r = m.round
            ? Rect.fromCenter(center: m.rect.center, width: side, height: side)
            : m.rect.inflate(6 * k);
        return Positioned.fromRect(
          key: key,
          rect: r,
          child: Appear(
            scaleFrom: 0.8,
            child: SkyRing(key: const Key('hint-p2'), round: m.round, radius: 14 * k, scale: k),
          ),
        );
      case SeenMark():
        return Positioned(
          key: key,
          left: m.rect.right - 7 * k,
          top: m.rect.top - 1 * k,
          child: SeenDot(key: const Key('seen-dot'), radius: 4 * k),
        );
      case BadgeMark():
        return m.big ? _bigBadge(key, m, k) : _badge(key, m, k);
      case PairsMark():
        return Positioned.fill(
          key: key,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('hint-p5'),
                  painter: _DottedPainter(m.lines, k, curved: false),
                ),
              ),
              for (final Rect r in m.unpaired)
                Positioned.fromRect(
                  rect: Rect.fromCenter(
                    center: r.center,
                    width: math.max(r.width, r.height) + 12 * k,
                    height: math.max(r.width, r.height) + 12 * k,
                  ),
                  child: SkyRing(scale: k),
                ),
            ],
          ),
        );
      case PathMark():
        return Positioned.fromRect(
          key: key,
          rect: m.rect,
          child: Appear(
            child: NumberPath(mark: m, scale: k),
          ),
        );
      case SwatchMark():
        return _glide(
          key,
          m.rect,
          Appear(
            scaleFrom: 0.85,
            child: HintSwatch(key: const Key('hint-p9'), colour: m.colour),
          ),
        );
      case GhostMark():
        return _glide(
          key,
          m.rect,
          Appear(
            child: GhostOutline(key: const Key('hint-p9'), kind: m.kind, turn: m.turn, scale: k),
          ),
        );
      case CopyMark():
        return _glide(
          key,
          m.rect,
          Appear(
            child: Opacity(
              opacity: m.opacity,
              child: Transform.rotate(angle: m.turns * 2 * math.pi, child: PackSvg(m.svg)),
            ),
          ),
        );
      case CardMark():
        return Positioned.fromRect(
          key: key,
          rect: m.rect,
          child: Appear(
            scaleFrom: 0.9,
            child: Container(
              key: const Key('hint-card'),
              decoration: BoxDecoration(
                color: TokenColors.skyTint,
                borderRadius: BorderRadius.circular(18 * k),
                border: Border.all(color: TokenColors.hintHalo, width: 3),
              ),
              padding: EdgeInsets.all(6 * k),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: m.child),
                ),
              ),
            ),
          ),
        );
      case ArcMark():
        return Positioned.fill(
          key: key,
          child: CustomPaint(
            key: const Key('hint-arc'),
            painter: _DottedPainter(<(Offset, Offset)>[(m.from, m.to)], k, curved: true),
          ),
        );
      case LineMark():
        return Positioned.fill(
          key: key,
          child: CustomPaint(
            key: const Key('hint-line'),
            painter: _DottedPainter(<(Offset, Offset)>[(m.from, m.to)], k, curved: false),
          ),
        );
      case BracketMark():
        return Positioned.fill(
          key: key,
          child: Appear(
            child: CustomPaint(key: const Key('hint-bracket'), painter: _BracketPainter(m.left, m.right, k)),
          ),
        );
      case BlockMark():
        return Positioned.fromRect(
          key: key,
          rect: m.rect,
          child: Appear(
            child: DecoratedBox(
              key: const Key('hint-block'),
              decoration: BoxDecoration(
                color: TokenColors.skyTint,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: TokenColors.skyDeep, width: 2),
              ),
            ),
          ),
        );
      case HandMark():
        return _hand(context, key, m, k);
    }
  }

  /// A sample that glides from one place to the next in 450 ms (it is simply there with "reduce motion").
  Widget _glide(Key key, Rect rect, Widget child) => _Glide(key: key, rect: rect, child: child);

  Widget _badge(Key key, BadgeMark m, double k) {
    final double r = 11 * k;
    return Positioned(
      key: key,
      left: m.at.dx - r,
      top: m.at.dy - r,
      width: 2 * r,
      height: 2 * r,
      child: Appear(
        scaleFrom: 0.7,
        child: Container(
          key: const Key('hint-badge'),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TokenColors.paper,
            shape: BoxShape.circle,
            border: Border.all(color: TokenColors.skyDeep, width: 2.5),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${m.n}', style: AppText.fixed(size: 14 * k, weight: 800, lineHeight: 1)),
          ),
        ),
      ),
    );
  }

  Widget _bigBadge(Key key, BadgeMark m, double k) {
    final double side = 64 * k;
    return Positioned(
      key: key,
      left: m.at.dx - side / 2,
      top: m.at.dy - side / 2,
      width: side,
      height: side,
      child: Appear(
        scaleFrom: 0.7,
        child: Container(
          key: const Key('hint-count-card'),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TokenColors.paper,
            borderRadius: BorderRadius.circular(18 * k),
            border: Border.all(color: TokenColors.hintHalo, width: 3),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${m.n}', style: AppText.fixed(size: 44 * k, weight: 800, lineHeight: 1)),
          ),
        ),
      ),
    );
  }

  /// The pointing hand: its fingertip on [HandMark.tip]. It travels in 450 ms (it just appears there with "reduce motion").
  Widget _hand(BuildContext context, Key key, HandMark m, double k) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final double h = (72 * k).clamp(40, 96).toDouble();
    final Offset tip = PointingHand.tipAt(h);
    return Positioned.fill(
      key: key,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (m.press)
            Positioned(
              key: ValueKey<String>('ripple-${m.tip.dx.round()}-${m.tip.dy.round()}'),
              left: m.tip.dx - 17 * k,
              top: m.tip.dy - 17 * k,
              width: 34 * k,
              height: 34 * k,
              child: _Ripple(still: still, scale: k),
            ),
          AnimatedPositioned(
            key: const ValueKey<String>('hand'),
            duration: still ? Duration.zero : const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            left: m.tip.dx - tip.dx,
            top: m.tip.dy - tip.dy,
            child: Appear(
              child: SizedBox(
                key: const Key('hint-p12'),
                child: PointingHand(height: h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A picture that moves to its new [rect] in 450 ms, easing, when a later step puts it somewhere else. It must sit directly in the
/// overlay's stack (it is a positioned child).
class _Glide extends StatelessWidget {
  const _Glide({super.key, required this.rect, required this.child});

  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedPositioned.fromRect(
    rect: rect,
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
    curve: Curves.easeInOut,
    child: child,
  );
}

/// A sky ring: 4 wide with a soft 10 wide halo at 35% around it (design spec 2.3). Nothing inside the ring is tinted, so what it
/// lights keeps its colours. [round] makes a circle, otherwise a rounded square of corner [radius].
class SkyRing extends StatelessWidget {
  const SkyRing({super.key, this.round = true, this.radius = 14, this.scale = 1});

  final bool round;
  final double radius;
  final double scale;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SkyRingPainter(round, radius, scale));
}

class _SkyRingPainter extends CustomPainter {
  _SkyRingPainter(this.round, this.radius, this.k);

  final bool round;
  final double radius;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = (Offset.zero & size).deflate(2 * k);
    final RRect ring = RRect.fromRectAndRadius(
      box,
      Radius.circular(round ? math.min(box.width, box.height) / 2 : radius),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * k
        ..color = TokenColors.hintHalo.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * k
        ..color = TokenColors.hintHalo,
    );
  }

  @override
  bool shouldRepaint(_SkyRingPainter old) => old.round != round || old.radius != radius || old.k != k;
}

/// A short fade in (250 ms; 200 ms with "reduce motion"), the first time it is built; [scaleFrom] makes it grow to full size at the
/// same time, but only where motion is allowed.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.child, this.scaleFrom});

  final Widget child;
  final double? scaleFrom;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: still ? 200 : 250),
      curve: Curves.easeOut,
      child: child,
      builder: (BuildContext c, double t, Widget? child) => Opacity(
        opacity: t,
        child: scaleFrom == null || still
            ? child
            : Transform.scale(scale: scaleFrom! + (1 - scaleFrom!) * t, child: child),
      ),
    );
  }
}

/// The sky ripple of a press: a ring that grows from 10 to 17 and fades in 400 ms (a still ring with "reduce motion").
class _Ripple extends StatelessWidget {
  const _Ripple({required this.still, required this.scale});

  final bool still;
  final double scale;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: still ? Duration.zero : const Duration(milliseconds: 400),
    builder: (BuildContext c, double t, Widget? child) =>
        CustomPaint(painter: _RipplePainter(still ? 0.6 : t, scale)),
  );
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t, this.scale);

  final double t;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = (10 + 7 * t) * scale;
    canvas.drawCircle(
      size.center(Offset.zero),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = TokenColors.hintHalo.withValues(alpha: 1 - t),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.scale != scale;
}

/// P1: `cream` at half over the stage with a clear, ringed hole 8 beyond each target.
class _VeilPainter extends CustomPainter {
  _VeilPainter(this.holes, this.k);

  final List<Rect> holes;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    Path veil = Path()..addRect(Offset.zero & size);
    final List<RRect> rings = <RRect>[
      for (final Rect h in holes)
        RRect.fromRectAndRadius(h.inflate(8 * k), Radius.circular(math.min(h.width, h.height) / 2 + 8 * k)),
    ];
    for (final RRect r in rings) {
      veil = Path.combine(ui.PathOperation.difference, veil, Path()..addRRect(r));
    }
    canvas.drawPath(veil, Paint()..color = TokenColors.cream.withValues(alpha: 0.5));
    for (final RRect r in rings) {
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * k
          ..color = TokenColors.hintHalo.withValues(alpha: 0.35),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * k
          ..color = TokenColors.hintHalo,
      );
    }
  }

  @override
  bool shouldRepaint(_VeilPainter old) => old.holes != holes || old.k != k;
}

/// P5 and the small links: dotted `skyDeep` lines (3 wide, round caps, 1 on and 6 off); [curved] draws each as a hop arc.
class _DottedPainter extends CustomPainter {
  _DottedPainter(this.lines, this.k, {required this.curved});

  final List<(Offset, Offset)> lines;
  final double k;
  final bool curved;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round
      ..color = TokenColors.skyDeep;
    for (final (Offset a, Offset b) in lines) {
      final Path p = Path()..moveTo(a.dx, a.dy);
      if (curved) {
        final Offset mid = (a + b) / 2;
        p.quadraticBezierTo(mid.dx, math.min(a.dy, b.dy) - 18 * k, b.dx, b.dy);
      } else {
        p.lineTo(b.dx, b.dy);
      }
      for (final ui.PathMetric m in p.computeMetrics()) {
        for (double d = 0; d < m.length; d += 7 * k) {
          canvas.drawPath(m.extractPath(d, d + 0.1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DottedPainter old) => old.lines != lines || old.k != k;
}

/// P7: an open bracket, `skyDeep` 3 wide: the two tips point up to the things above it.
class _BracketPainter extends CustomPainter {
  _BracketPainter(this.left, this.right, this.k);

  final Offset left;
  final Offset right;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final double tick = 7 * k;
    canvas.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(left.dx, left.dy + tick)
        ..lineTo(right.dx, right.dy + tick)
        ..lineTo(right.dx, right.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = TokenColors.skyDeep,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.left != left || old.right != right || old.k != k;
}

/// P6: a strip of equal squares with numerals, 1 at the left (never mirrored), a little taller at 5 and 10. The square [PathMark.gap]
/// is empty; the squares after [PathMark.upTo] are not drawn yet.
class NumberPath extends StatelessWidget {
  const NumberPath({super.key, required this.mark, required this.scale});

  final PathMark mark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final int shown = mark.upTo ?? mark.count;
    return Directionality(
      textDirection: mark.reverse ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        key: const Key('hint-p6'),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int n = 1; n <= mark.count; n++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 1 * scale),
                child: n > shown ? const SizedBox() : _square(n),
              ),
            ),
        ],
      ),
    );
  }

  Widget _square(int n) {
    final bool gap = mark.gap == n;
    final bool ring = mark.ring == n;
    final double tall = (n == 5 || n == 10) ? 6 * scale : 0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          key: Key('path-square-$n'),
          height: mark.rect.height - 6 * scale + tall,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: gap ? TokenColors.skyTint : TokenColors.paper,
            borderRadius: BorderRadius.circular(4 * scale),
            border: Border.all(
              color: ring || gap ? TokenColors.skyDeep : TokenColors.ink,
              width: ring || gap ? 3 : 1.5,
            ),
          ),
          child: gap
              ? null
              : Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$n', style: AppText.fixed(size: 15 * scale, weight: 800, lineHeight: 1)),
                ),
        ),
        if (mark.marker == n)
          Positioned(
            top: -10 * scale,
            child: SeenDot(key: const Key('path-marker'), radius: 6 * scale),
          ),
      ],
    );
  }
}

/// P9: a round paint dab of a colour with its helper symbol (red a heart, orange a sun, yellow a star, green a leaf, blue a drop,
/// purple grapes, pink a flower, brown a nut, black a moon, white a cloud, grey a stone), so that colour never stands alone.
class HintSwatch extends StatelessWidget {
  const HintSwatch({super.key, required this.colour});

  final String colour;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SwatchPainter(colour));
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.colour);

  final String colour;

  @override
  void paint(Canvas canvas, Size size) {
    final Color paint = hintColours[colour] ?? TokenColors.skyDeep;
    final Color lip = HSLColor.fromColor(paint)
        .withLightness((HSLColor.fromColor(paint).lightness * 0.72).clamp(0, 1).toDouble())
        .toColor();
    final double r = math.min(size.width, size.height) / 2 - 4;
    final Offset c = size.center(Offset.zero) - const Offset(0, 2);
    canvas.drawCircle(
      c + const Offset(0, 4),
      r,
      Paint()..color = colour == 'white' ? TokenColors.cardLip : lip,
    );
    canvas.drawCircle(c, r, Paint()..color = paint);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = colour == 'white' ? TokenColors.cardLip : Colors.white.withValues(alpha: 0.7),
    );
    final Color ink = colour == 'white' ? TokenColors.skyDeep : Colors.white;
    final Paint fill = Paint()..color = ink;
    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = colour == 'white' ? TokenColors.skyDeep : lip;
    _symbol(canvas, c, r * 0.55, fill, edge, paint);
  }

  void _symbol(Canvas canvas, Offset c, double s, Paint fill, Paint edge, Color body) {
    void both(Path p) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, edge);
    }

    switch (colour) {
      case 'red': // a heart
        both(
          Path()
            ..moveTo(c.dx, c.dy + s * 0.95)
            ..cubicTo(c.dx - s * 1.7, c.dy - s * 0.1, c.dx - s * 0.95, c.dy - s * 1.2, c.dx, c.dy - s * 0.35)
            ..cubicTo(c.dx + s * 0.95, c.dy - s * 1.2, c.dx + s * 1.7, c.dy - s * 0.1, c.dx, c.dy + s * 0.95)
            ..close(),
        );
      case 'orange': // a sun
        canvas.drawCircle(c, s * 0.5, fill);
        canvas.drawCircle(c, s * 0.5, edge);
        for (int i = 0; i < 8; i++) {
          final double a = i * math.pi / 4;
          canvas.drawLine(
            c + Offset(math.cos(a), math.sin(a)) * (s * 0.75),
            c + Offset(math.cos(a), math.sin(a)) * (s * 1.05),
            Paint()
              ..color = fill.color
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'yellow': // a star
        final Path star = Path();
        for (int i = 0; i < 10; i++) {
          final double a = -math.pi / 2 + i * math.pi / 5;
          final double rr = i.isEven ? s * 1.1 : s * 0.48;
          final Offset p = c + Offset(math.cos(a), math.sin(a)) * rr;
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        both(star..close());
      case 'green': // a leaf
        both(
          Path()
            ..moveTo(c.dx - s * 0.9, c.dy + s * 0.9)
            ..quadraticBezierTo(c.dx - s * 1.0, c.dy - s * 0.9, c.dx + s * 0.9, c.dy - s * 0.9)
            ..quadraticBezierTo(c.dx + s * 1.0, c.dy + s * 0.9, c.dx - s * 0.9, c.dy + s * 0.9)
            ..close(),
        );
      case 'blue': // a drop
        both(
          Path()
            ..moveTo(c.dx, c.dy - s * 1.1)
            ..cubicTo(c.dx + s * 0.3, c.dy - s * 0.5, c.dx + s * 0.85, c.dy, c.dx + s * 0.85, c.dy + s * 0.4)
            ..arcToPoint(Offset(c.dx - s * 0.85, c.dy + s * 0.4), radius: Radius.circular(s * 0.85))
            ..cubicTo(c.dx - s * 0.85, c.dy, c.dx - s * 0.3, c.dy - s * 0.5, c.dx, c.dy - s * 1.1)
            ..close(),
        );
      case 'purple': // grapes
        for (final Offset o in <Offset>[
          Offset(-s * 0.5, -s * 0.35),
          Offset(s * 0.5, -s * 0.35),
          Offset(0, s * 0.35),
          Offset(0, -s * 0.95),
        ]) {
          canvas.drawCircle(c + o, s * 0.42, fill);
          canvas.drawCircle(c + o, s * 0.42, edge);
        }
      case 'pink': // a flower
        for (int i = 0; i < 5; i++) {
          final double a = -math.pi / 2 + i * 2 * math.pi / 5;
          final Offset p = c + Offset(math.cos(a), math.sin(a)) * (s * 0.62);
          canvas.drawCircle(p, s * 0.42, fill);
          canvas.drawCircle(p, s * 0.42, edge);
        }
        canvas.drawCircle(c, s * 0.3, Paint()..color = body);
      case 'brown': // a nut
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-0.4);
        final Rect o = Rect.fromCenter(center: Offset.zero, width: s * 1.3, height: s * 1.8);
        canvas.drawOval(o, fill);
        canvas.drawOval(o, edge);
        canvas.drawLine(Offset(0, -s * 0.9), Offset(0, s * 0.9), edge);
        canvas.restore();
      case 'black': // a moon
        both(
          Path.combine(
            ui.PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.95)),
            Path()..addOval(Rect.fromCircle(center: c + Offset(s * 0.55, -s * 0.3), radius: s * 0.82)),
          ),
        );
      case 'white': // a cloud
        both(
          Path.combine(
            ui.PathOperation.union,
            Path.combine(
              ui.PathOperation.union,
              Path()..addOval(Rect.fromCircle(center: c + Offset(-s * 0.5, s * 0.1), radius: s * 0.5)),
              Path()..addOval(Rect.fromCircle(center: c + Offset(s * 0.1, -s * 0.25), radius: s * 0.62)),
            ),
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTRB(c.dx - s * 0.95, c.dy + s * 0.1, c.dx + s * 1.0, c.dy + s * 0.62),
                Radius.circular(s * 0.26),
              ),
            ),
          ),
        );
      default: // grey: a stone
        final Rect o = Rect.fromCenter(center: c, width: s * 1.9, height: s * 1.3);
        canvas.drawOval(o, fill);
        canvas.drawOval(o, edge);
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.colour != colour;
}

/// P9: the dashed outline of a shape (or of a straight or a curved line): `skyDeep`, 3 wide, round caps. [turn] lets it turn a
/// quarter once (1.5 s) and then stay; with "reduce motion" it does not turn.
class GhostOutline extends StatelessWidget {
  const GhostOutline({super.key, required this.kind, this.turn = false, this.scale = 1});

  final GhostKind kind;
  final bool turn;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final Widget outline = CustomPaint(painter: _GhostPainter(kind, scale));
    if (!turn || MediaQuery.disableAnimationsOf(context)) return outline;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 0.25),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      child: outline,
      builder: (BuildContext c, double t, Widget? child) =>
          Transform.rotate(angle: t * 2 * math.pi, child: child),
    );
  }
}

class _GhostPainter extends CustomPainter {
  _GhostPainter(this.kind, this.k);

  final GhostKind kind;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height) - 6 * k;
    final Offset c = size.center(Offset.zero);
    final Path shape = switch (kind) {
      GhostKind.circle => Path()..addOval(Rect.fromCenter(center: c, width: side, height: side)),
      GhostKind.square =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: side * 0.86, height: side * 0.86),
            Radius.circular(side * 0.06),
          ),
        ),
      GhostKind.rect =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: math.min(size.width - 6 * k, side * 1.5), height: side * 0.6),
            Radius.circular(side * 0.05),
          ),
        ),
      GhostKind.triangle =>
        Path()
          ..moveTo(c.dx, c.dy - side * 0.46)
          ..lineTo(c.dx + side * 0.5, c.dy + side * 0.4)
          ..lineTo(c.dx - side * 0.5, c.dy + side * 0.4)
          ..close(),
      GhostKind.straight =>
        Path()
          ..moveTo(c.dx - size.width * 0.42, c.dy)
          ..lineTo(c.dx + size.width * 0.42, c.dy),
      GhostKind.curved =>
        Path()
          ..moveTo(c.dx - size.width * 0.42, c.dy + side * 0.15)
          ..cubicTo(
            c.dx - size.width * 0.2,
            c.dy - side * 0.5,
            c.dx + size.width * 0.05,
            c.dy + side * 0.5,
            c.dx + size.width * 0.42,
            c.dy - side * 0.15,
          ),
    };
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round
      ..color = TokenColors.skyDeep;
    for (final ui.PathMetric m in shape.computeMetrics()) {
      for (double d = 0; d < m.length; d += 12 * k) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6 * k, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GhostPainter old) => old.kind != kind || old.k != k;
}
