import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

// The pieces of art that LS03, LS04 and LS05 draw in code (docs/design/l5-templates.md sections 3 to 5): the counter and its bowl, the
// three stamps of the Russian sound scheme with their shape marks, the stress sign, the signs of the Hebrew wheel, the slide knob. They are
// template art (final), not pictures of the pictures list, so they are shapes: a mark is never a font glyph.

/// A place on the board, in board points: [rect] drawn for a course that reads left to right, mirrored inside [zone] for one that reads right to
/// left (docs/design/l5-templates.md section 2.3).
class ZoneMap {
  const ZoneMap(this.zone, {required this.mirror});

  final Rect zone;
  final bool mirror;

  Rect at(Rect r) => mirror ? Rect.fromLTWH(zone.left + zone.right - r.right, r.top, r.width, r.height) : r;

  /// The x of a point (not a rectangle), mirrored the same way.
  double x(double v) => mirror ? zone.left + zone.right - v : v;
}

/// The three kinds of a sound in the Russian scheme: a vowel (red, a note), a hard consonant (blue, a square), a soft one (green, a smile).
enum SchemeKind {
  vowel('r', TokenColors.teachRed, TokenColors.teachRedLip),
  hard('b', TokenColors.teachBlue, TokenColors.teachBlueLip),
  soft('g', TokenColors.teachGreen, TokenColors.teachGreenLip);

  const SchemeKind(this.letter, this.fill, this.lip);

  /// The letter of the response code (`c=brb`).
  final String letter;
  final Color fill;
  final Color lip;

  static SchemeKind? ofLetter(String l) {
    for (final SchemeKind k in values) {
      if (k.letter == l) return k;
    }
    return null;
  }
}

/// The shape mark of a [SchemeKind] in a 100 by 100 box: a note, a square block, a smile. Colour is never the only cue.
class SchemeMark extends StatelessWidget {
  const SchemeMark(this.kind, {super.key, required this.size, this.color = Colors.white});

  final SchemeKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter(kind, color));
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.kind, this.color);

  final SchemeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 100;
    canvas.scale(k);
    final Paint fill = Paint()..color = color;
    switch (kind) {
      case SchemeKind.vowel:
        canvas.save();
        canvas.translate(40, 70);
        canvas.rotate(-22 * math.pi / 180);
        canvas.drawOval(const Rect.fromLTRB(-17, -13, 17, 13), fill);
        canvas.restore();
        canvas.drawRRect(RRect.fromLTRBR(51, 20, 60, 72, const Radius.circular(4)), fill);
        canvas.drawPath(
          Path()
            ..moveTo(56, 21)
            ..cubicTo(70, 24, 78, 34, 76, 48)
            ..cubicTo(72, 40, 66, 36, 58, 35)
            ..close(),
          fill,
        );
      case SchemeKind.hard:
        canvas.drawRRect(RRect.fromLTRBR(27, 27, 73, 73, const Radius.circular(7)), fill);
      case SchemeKind.soft:
        canvas.drawPath(
          Path()
            ..moveTo(24, 42)
            ..quadraticBezierTo(50, 80, 76, 42),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.kind != kind || old.color != color;
}

/// A coloured chip of the scheme (also a stamp): the colour, its clay lip and its white mark.
class SchemeChip extends StatelessWidget {
  const SchemeChip(this.kind, {super.key, required this.size, this.lifted = false, this.dim = false});

  final SchemeKind kind;
  final double size;
  final bool lifted;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dim ? 0.4 : 1,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kind.fill,
        border: Border.all(color: kind.lip, width: 4),
        boxShadow: <BoxShadow>[BoxShadow(color: kind.lip, offset: Offset(0, lifted ? 6 : 3))],
      ),
      child: Center(child: SchemeMark(kind, size: size * 0.62)),
    ),
  );
}

/// The plain counter of the count step: warm tan, not one of the scheme's three colours and not a feedback colour, so a tan one means "not
/// coloured yet".
class CounterDisc extends StatelessWidget {
  const CounterDisc({super.key, required this.size, this.lifted = false});

  final double size;
  final bool lifted;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: TokenColors.languagesToken,
      border: Border.all(color: TokenColors.languagesTokenLip, width: 4),
      boxShadow: <BoxShadow>[
        BoxShadow(color: TokenColors.languagesTokenLip, offset: Offset(0, lifted ? 6 : 4)),
      ],
    ),
    child: Center(
      child: Container(
        width: size * 0.6 - 8,
        height: size * 0.6 - 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 3),
        ),
      ),
    ),
  );
}

/// The bowl the counters come from: a shallow bowl with three of them and its rim in front. It never empties.
class BowlArt extends StatelessWidget {
  const BowlArt({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _BowlPainter());
}

class _BowlPainter extends CustomPainter {
  const _BowlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final Paint tan = Paint()..color = TokenColors.languagesToken;
    final Paint rim = Paint()
      ..color = TokenColors.languagesTokenLip
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final Paint ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(const Rect.fromLTRB(3, 34, 97, 78), Paint()..color = TokenColors.mist);
    canvas.drawOval(
      const Rect.fromLTRB(3, 34, 97, 78),
      Paint()
        ..color = TokenColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final Offset c in const <Offset>[Offset(34, 50), Offset(64, 50), Offset(49, 38)]) {
      canvas.drawCircle(c, 17, tan);
      canvas.drawCircle(c, 17, rim);
      canvas.drawCircle(c, 10, ring);
    }
    final Path front = Path()
      ..moveTo(3, 56)
      ..cubicTo(6, 90, 94, 90, 97, 56)
      ..cubicTo(90, 74, 10, 74, 3, 56)
      ..close();
    canvas.drawPath(front, Paint()..color = Colors.white);
    canvas.drawPath(
      front,
      Paint()
        ..color = TokenColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10, 70)
        ..cubicTo(30, 86, 70, 86, 90, 70),
      Paint()
        ..color = TokenColors.cardLip
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BowlPainter old) => false;
}

/// The stress sign of the Russian scheme: a slanted bar above a place.
class StressSign extends StatelessWidget {
  const StressSign({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(height * 0.7, height), painter: const _StressPainter());
}

class _StressPainter extends CustomPainter {
  const _StressPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    Offset(size.width * 0.15, size.height),
    Offset(size.width * 0.85, 0),
    Paint()
      ..color = TokenColors.ink
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(_StressPainter old) => false;
}

/// A vowel sign of the Hebrew wheel, drawn as a shape under a dashed box where a letter goes (a mark with no base is drawn differently by
/// different text engines, so no lone combining mark is ever set in a font). The empty string is "no sign": the dashed box alone.
class SignShape extends StatelessWidget {
  const SignShape(this.sign, {super.key, required this.size});

  final String sign;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double box = size * 0.40;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: size * 0.08),
        CustomPaint(size: Size.square(box), painter: _DashedBoxPainter()),
        SizedBox(height: math.max(2, size * 0.04)),
        if (sign.isNotEmpty) CustomPaint(size: Size(box * 1.25, box * 0.5), painter: _SignPainter(sign)),
      ],
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = TokenColors.inkSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final RRect r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    final Path path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), p);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => false;
}

class _SignPainter extends CustomPainter {
  const _SignPainter(this.sign);

  final String sign;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 16);
    final Paint ink = Paint()..color = TokenColors.ink;
    void bar(double x, double y, double w, double h, double r) =>
        canvas.drawRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)), ink);
    void dot(double x, double y, double r) => canvas.drawCircle(Offset(x, y), r, ink);
    switch (sign.runes.first) {
      case 0x05B8: // qamats: a small T
        bar(9, 1, 22, 5.5, 2.5);
        bar(17, 4, 6, 11, 2.5);
      case 0x05B7: // patah: a bar
        bar(9, 4, 22, 6, 3);
      case 0x05B4: // hiriq: a dot
        dot(20, 7, 4.5);
      case 0x05B0: // shva: two dots, one over the other
        dot(20, 3.5, 3.4);
        dot(20, 11.5, 3.4);
      case 0x05B5: // tsere: two dots side by side
        dot(14, 7, 3.6);
        dot(26, 7, 3.6);
      case 0x05B6: // segol: three dots
        dot(13, 3.5, 3.2);
        dot(27, 3.5, 3.2);
        dot(20, 11.5, 3.2);
      case 0x05B9: // holam: a dot above
        dot(20, 4, 3.8);
      case 0x05BB: // kubutz: three on a slant
        dot(12, 3, 3);
        dot(20, 7.5, 3);
        dot(28, 12, 3);
      default:
        bar(11, 5, 18, 5, 2.5);
    }
  }

  @override
  bool shouldRepaint(_SignPainter old) => old.sign != sign;
}

/// A chevron in the course's reading direction (the slide knob).
class ChevronMark extends StatelessWidget {
  const ChevronMark({super.key, required this.size, required this.towardsRight, this.color = Colors.white});

  final double size;
  final bool towardsRight;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ChevronPainter(towardsRight, color));
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.right, this.color);

  final bool right;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double s = right ? 1 : -1;
    final double cx = w / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx - s * w * 0.14, w * 0.2)
        ..lineTo(cx + s * w * 0.16, w * 0.5)
        ..lineTo(cx - s * w * 0.14, w * 0.8),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.right != right || old.color != color;
}

/// A reading arrow: an arrowhead at the end of a track (never flipped by the app's own direction).
class ArrowHead extends StatelessWidget {
  const ArrowHead({
    super.key,
    required this.size,
    required this.towardsRight,
    this.color = TokenColors.inkSoft,
  });

  final double size;
  final bool towardsRight;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ArrowHeadPainter(towardsRight, color));
}

class _ArrowHeadPainter extends CustomPainter {
  const _ArrowHeadPainter(this.right, this.color);

  final bool right;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path p = right
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(w, h / 2)
            ..lineTo(0, h)
            ..close())
        : (Path()
            ..moveTo(w, 0)
            ..lineTo(0, h / 2)
            ..lineTo(w, h)
            ..close());
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowHeadPainter old) => old.right != right || old.color != color;
}

/// A small light card of the hints (the "sky card" that lies over a stage): sky tint, a sky ring.
class SkyCard extends StatelessWidget {
  const SkyCard({super.key, required this.child, this.radius = 24});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TokenColors.skyTint,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: TokenColors.hintHalo, width: 4),
    ),
    child: child,
  );
}

/// The soft sky panel that stands under the stage of a template (the stage's own room).
class StagePanel extends StatelessWidget {
  const StagePanel({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(TokenRadius.lg),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[TokenColors.skyTint, Color(0xFFF3FAFE)],
      ),
    ),
    child: child,
  );
}

/// A dashed rounded rectangle (the "next" place of the rail, a sign bead's box): [color] at [width], dashes [dash] long with [gap] between.
class DashedRRect extends StatelessWidget {
  const DashedRRect({
    super.key,
    this.color = TokenColors.lilacDeep,
    this.width = 3,
    this.radius = 22,
    this.fill,
    this.dash = 9,
    this.gap = 7,
  });

  final Color color;
  final double width;
  final double radius;
  final Color? fill;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRectPainter(color, width, radius, fill, dash, gap),
    child: const SizedBox.expand(),
  );
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter(this.color, this.width, this.radius, this.fill, this.dash, this.gap);

  final Color color;
  final double width;
  final double radius;
  final Color? fill;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect r = RRect.fromRectAndRadius(
      Offset(width / 2, width / 2) & Size(size.width - width, size.height - width),
      Radius.circular(radius),
    );
    if (fill != null) canvas.drawRRect(r, Paint()..color = fill!);
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final metric in (Path()..addRRect(r)).computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), p);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.width != width || old.radius != radius || old.fill != fill;
}

/// A gentle wobble, once, when [on] turns true (a "not yet": 6 points, 360 ms). With reduce-motion it does not move.
class Wobble extends StatefulWidget {
  const Wobble({super.key, required this.on, required this.child, this.amplitude = 6});

  final bool on;
  final Widget child;
  final double amplitude;

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(Wobble old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on && !MediaQuery.disableAnimationsOf(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (BuildContext context, Widget? child) => Transform.translate(
      offset: Offset(math.sin(_c.value * math.pi * 3) * widget.amplitude * (1 - _c.value), 0),
      child: child,
    ),
  );
}
