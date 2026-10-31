import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/tokens.g.dart';
import '../template_session.dart' show PackSvg;
import 'hint_marks.dart';

// P10, the seesaw of heavy and light (B-40, TA-11 MATH-A-04): a playground seesaw drawn in code, with the two things of the question
// on its ends. Drawn after photographs of playground seesaws (Wikimedia Commons, Category:Seesaws: "Seesaw-aa.jpg", a row of
// plank seesaws on a centre bar, one end resting on the ground, a hoop handle in front of each seat and a rubber pad under each
// end; "Altalena.jpg", the line drawing of a plank on a triangular fulcrum) and the Wikipedia article "Seesaw" (a long narrow board
// on a single pivot at its middle; one end goes up as the other goes down). An original drawing: a wooden plank with a light top
// edge and grain, a teal A-frame stand, a round pivot cap (the same cap as the pan balance), a hoop handle and a rubber pad near
// each end, and two small wooden blocks that hold it level. No text inside the picture.

/// The places of the seesaw on a stage of [size]: drawn for the phone's stage (330 by 128) and grown evenly with a bigger one, its
/// stand on the stage's floor. The plank is long enough that the two things stand well apart, and tips only as far as its low end's
/// pad resting on the ground (about 15 degrees), so that the thing on the high end stays inside the stage.
class SeesawBox {
  SeesawBox(this.size)
    : u = math.min(size.width / 330, size.height / 128),
      cx = size.width / 2,
      ground = size.height - 3 * math.min(size.width / 330, size.height / 128);

  final Size size;

  /// One point of the phone's drawing on this stage.
  final double u;
  final double cx;

  /// Where the stand and the blocks stand.
  final double ground;

  /// The middle of the plank (its pivot), and half the plank's length, its thickness.
  double get pivotY => ground - 36 * u;
  Offset get pivot => Offset(cx, pivotY);
  double get half => 118 * u;
  double get thick => 10 * u;

  /// The rubber pad under each end: its middle's distance from the pivot, its width and height.
  double get padX => 106 * u;
  double get padW => 18 * u;
  double get padH => 5 * u;

  /// Where a thing sits (its middle's distance from the pivot) and the box it is drawn in, its foot on the plank.
  double get thingX => 84 * u;
  double get thingW => 58 * u;
  double get thingH => 50 * u;

  /// The hoop handle in front of each seat: its middle's distance from the pivot.
  double get handleX => 44 * u;

  /// How far the plank turns when an end rests on the ground: its pad's foot touches the floor.
  double get tilt {
    final double a = padX;
    final double b = thick / 2 + padH;
    final double r = math.sqrt(a * a + b * b);
    return math.asin(((ground - pivotY) / r).clamp(-1.0, 1.0)) - math.atan2(b, a);
  }

  /// The wooden block under the left (or right) end of the level plank, from the floor up to its pad.
  Rect prop({required bool left}) {
    final double x = left ? cx - padX : cx + padX;
    return Rect.fromLTRB(x - 13 * u, pivotY + thick / 2 + padH, x + 13 * u, ground);
  }
}

/// The seesaw of a [SeesawMark], filling its box. Keyed `hint-seesaw`; the plank's painter is keyed `hint-seesaw-plank`.
class SeesawPicture extends StatelessWidget {
  const SeesawPicture({super.key, required this.mark});

  final SeesawMark mark;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final SeesawBox b = SeesawBox(c.biggest);
        // With "reduce motion" the plank does not turn: a new lean is a new picture that fades in already tipped.
        final Widget plank = still
            ? KeyedSubtree(
                key: ValueKey<int>(mark.down),
                child: _FadeIn(child: _plank(b, mark.down.toDouble())),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(end: mark.down.toDouble()),
                duration: const Duration(milliseconds: 1600),
                curve: Curves.easeInOutCubic,
                builder: (BuildContext context, double t, Widget? _) => _plank(b, t),
              );
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            key: const Key('hint-seesaw'),
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(child: CustomPaint(painter: _StandPainter(b))),
              _prop(b, left: true, shown: mark.propLeft, still: still),
              _prop(b, left: false, shown: mark.propRight, still: still),
              Positioned.fill(child: plank),
              Positioned.fill(child: CustomPaint(painter: _CapPainter(b))),
            ],
          ),
        );
      },
    );
  }

  /// The plank, the two things on it, turned by [t] times the full tilt (1: the right end down).
  Widget _plank(SeesawBox b, double t) {
    final double angle = t * b.tilt;
    Widget thing(String svg, double aspect, bool left) {
      final double w = math.min(b.thingW, b.thingH * aspect);
      final double h = w / aspect;
      final double x = left ? b.cx - b.thingX : b.cx + b.thingX;
      return Positioned(
        left: x - w / 2,
        top: b.pivotY - b.thick / 2 - h + 0.5 * b.u,
        width: w,
        height: h,
        child: PackSvg(svg, fit: BoxFit.fill),
      );
    }

    return Transform.rotate(
      angle: angle,
      origin: b.pivot - Offset(b.size.width / 2, b.size.height / 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(key: const Key('hint-seesaw-plank'), painter: SeesawPlankPainter(b, t)),
          ),
          thing(mark.left, mark.leftAspect, true),
          thing(mark.right, mark.rightAspect, false),
        ],
      ),
    );
  }

  /// A wooden block under one end. When it is taken away it slides out (away from the stand) and fades; with "reduce motion" it is
  /// simply gone.
  Widget _prop(SeesawBox b, {required bool left, required bool shown, required bool still}) {
    final Duration d = still ? Duration.zero : const Duration(milliseconds: 450);
    return Positioned.fromRect(
      key: Key(left ? 'seesaw-prop-left' : 'seesaw-prop-right'),
      rect: b.prop(left: left),
      child: AnimatedSlide(
        offset: shown ? Offset.zero : Offset(left ? -0.9 : 0.9, 0),
        duration: d,
        curve: Curves.easeIn,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: d,
          child: CustomPaint(painter: _BlockPainter(b.u)),
        ),
      ),
    );
  }
}

/// A short fade in (200 ms) the first time it is built: the still picture of a tipped plank.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 200),
    child: child,
    builder: (BuildContext c, double t, Widget? child) => Opacity(opacity: t, child: child),
  );
}

/// The shadow on the grass and the A-frame stand: a teal triangle with a rounded top, a light edge on its left, a darker right side
/// and a foot bar on the ground.
class _StandPainter extends CustomPainter {
  _StandPainter(this.b);

  final SeesawBox b;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = b.u;
    final double cx = b.cx;
    final double g = b.ground;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, g - 1 * u), width: 240 * u, height: 7 * u),
      Paint()..color = TokenColors.worldShadow,
    );
    final double top = b.pivotY;
    final double baseHalf = 25 * u;
    final Path frame = Path()
      ..moveTo(cx - baseHalf, g - 3 * u)
      ..lineTo(cx - 5 * u, top + 3 * u)
      ..quadraticBezierTo(cx, top - 2 * u, cx + 5 * u, top + 3 * u)
      ..lineTo(cx + baseHalf, g - 3 * u)
      ..close();
    canvas.drawPath(frame, Paint()..color = TokenColors.sea);
    // The right side in shade, the left edge in light.
    final Path shade = Path()
      ..moveTo(cx + 1 * u, top + 2 * u)
      ..quadraticBezierTo(cx + 3 * u, top, cx + 5 * u, top + 3 * u)
      ..lineTo(cx + baseHalf, g - 3 * u)
      ..lineTo(cx + 9 * u, g - 3 * u)
      ..close();
    canvas.drawPath(shade, Paint()..color = TokenColors.seaDeep.withValues(alpha: 0.55));
    canvas.drawLine(
      Offset(cx - baseHalf + 5 * u, g - 6 * u),
      Offset(cx - 5 * u, top + 8 * u),
      Paint()
        ..color = TokenColors.seaTint.withValues(alpha: 0.8)
        ..strokeWidth = 2 * u
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      frame,
      Paint()
        ..color = TokenColors.seaDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * u
        ..strokeJoin = StrokeJoin.round,
    );
    // The foot bar on the ground.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - baseHalf - 6 * u, g - 4.5 * u, cx + baseHalf + 6 * u, g),
        Radius.circular(2.25 * u),
      ),
      Paint()..color = TokenColors.seaDeep,
    );
  }

  @override
  bool shouldRepaint(_StandPainter old) => old.b.size != b.size;
}

/// The round pivot cap and its pin, over the middle of the plank: it does not turn.
class _CapPainter extends CustomPainter {
  _CapPainter(this.b);

  final SeesawBox b;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = b.u;
    canvas.drawCircle(b.pivot, 7 * u, Paint()..color = TokenColors.spark);
    canvas.drawCircle(
      b.pivot,
      7 * u,
      Paint()
        ..color = TokenColors.sparkDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * u,
    );
    canvas.drawCircle(b.pivot, 2.2 * u, Paint()..color = TokenColors.ink);
  }

  @override
  bool shouldRepaint(_CapPainter old) => old.b.size != b.size;
}

/// The plank, drawn level (the widget turns it): the board with a light top edge, grain and darker ends, a rubber pad under each
/// end, and a hoop handle standing on it in front of each seat. [t] is how far it is tipped (from -1 to 1), kept for the tests.
class SeesawPlankPainter extends CustomPainter {
  SeesawPlankPainter(this.b, this.t);

  final SeesawBox b;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = b.u;
    final double cx = b.cx;
    final double y = b.pivotY;
    final double half = b.half;
    final double th = b.thick;
    // The rubber pads under the ends.
    for (final double s in <double>[-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + s * b.padX, y + th / 2 + b.padH / 2 - 0.5 * u),
            width: b.padW,
            height: b.padH + 1 * u,
          ),
          Radius.circular(2 * u),
        ),
        Paint()..color = TokenColors.inkSoft,
      );
    }
    // The hoop handles: a bent tube standing on the plank, its two feet bolted on.
    for (final double s in <double>[-1, 1]) {
      final double hx = cx + s * b.handleX;
      final Path hoop = Path()
        ..moveTo(hx - 7 * u, y - th / 2)
        ..lineTo(hx - 7 * u, y - th / 2 - 9 * u)
        ..quadraticBezierTo(hx - 7 * u, y - th / 2 - 15 * u, hx, y - th / 2 - 15 * u)
        ..quadraticBezierTo(hx + 7 * u, y - th / 2 - 15 * u, hx + 7 * u, y - th / 2 - 9 * u)
        ..lineTo(hx + 7 * u, y - th / 2);
      canvas.drawPath(
        hoop,
        Paint()
          ..color = TokenColors.seaDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.4 * u
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        hoop,
        Paint()
          ..color = TokenColors.sea
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * u
          ..strokeCap = StrokeCap.round,
      );
    }
    // The board.
    final RRect board = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - half, y - th / 2, cx + half, y + th / 2),
      Radius.circular(3 * u),
    );
    canvas.drawRRect(board, Paint()..color = TokenColors.worldWood);
    canvas.save();
    canvas.clipRRect(board);
    // A darker band at each end (the seat's end grain) and a light top edge.
    for (final double s in <double>[-1, 1]) {
      final double x = cx + s * half;
      canvas.drawRect(
        Rect.fromLTRB(math.min(x, x - s * 6 * u), y - th / 2, math.max(x, x - s * 6 * u), y + th / 2),
        Paint()..color = TokenColors.teachBrown.withValues(alpha: 0.35),
      );
    }
    canvas.drawRect(
      Rect.fromLTRB(cx - half, y - th / 2, cx + half, y - th / 2 + 2.4 * u),
      Paint()..color = TokenColors.worldWoodLight,
    );
    final Paint grain = Paint()
      ..color = TokenColors.teachBrown.withValues(alpha: 0.4)
      ..strokeWidth = 0.9 * u
      ..strokeCap = StrokeCap.round;
    for (final (double from, double to, double dy) in <(double, double, double)>[
      (-104, -62, 1.2),
      (-40, -12, 2.4),
      (16, 58, 1.0),
      (74, 108, 2.6),
    ]) {
      canvas.drawLine(Offset(cx + from * u, y + dy * u), Offset(cx + to * u, y + dy * u), grain);
    }
    canvas.restore();
    canvas.drawRRect(
      board,
      Paint()
        ..color = TokenColors.teachBrownLip
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * u,
    );
    // The bolts of the handles' feet.
    for (final double s in <double>[-1, 1]) {
      for (final double f in <double>[-7, 7]) {
        canvas.drawCircle(
          Offset(cx + s * b.handleX + f * u, y + 0.6 * u),
          1.1 * u,
          Paint()..color = TokenColors.teachBrownLip,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SeesawPlankPainter old) => old.t != t || old.b.size != b.size;
}

/// A small wooden block: a light face with a darker side, grain and a soft shadow on the grass.
class _BlockPainter extends CustomPainter {
  _BlockPainter(this.u);

  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r.center.dx, r.bottom - 0.5 * u), width: r.width + 6 * u, height: 4 * u),
      Paint()..color = TokenColors.worldShadow,
    );
    final RRect face = RRect.fromRectAndRadius(r.deflate(0.6 * u), Radius.circular(2.5 * u));
    canvas.drawRRect(face, Paint()..color = TokenColors.worldWoodLight);
    canvas.save();
    canvas.clipRRect(face);
    canvas.drawRect(
      Rect.fromLTRB(r.right - 6 * u, r.top, r.right, r.bottom),
      Paint()..color = TokenColors.worldWood.withValues(alpha: 0.7),
    );
    canvas.drawRect(
      Rect.fromLTRB(r.left, r.top, r.right, r.top + 3 * u),
      Paint()..color = TokenColors.paper.withValues(alpha: 0.35),
    );
    final Paint grain = Paint()
      ..color = TokenColors.teachBrown.withValues(alpha: 0.35)
      ..strokeWidth = 0.9 * u
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(r.left + 5 * u, r.top + 8 * u)
        ..quadraticBezierTo(r.center.dx - 2 * u, r.top + 11 * u, r.right - 9 * u, r.top + 9 * u),
      grain,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left + 4 * u, r.bottom - 7 * u)
        ..quadraticBezierTo(r.center.dx, r.bottom - 10 * u, r.right - 8 * u, r.bottom - 6 * u),
      grain,
    );
    canvas.restore();
    canvas.drawRRect(
      face,
      Paint()
        ..color = TokenColors.teachBrown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * u,
    );
  }

  @override
  bool shouldRepaint(_BlockPainter old) => old.u != u;
}
