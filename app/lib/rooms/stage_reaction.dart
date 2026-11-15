import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/tokens.g.dart';
import 'room_spec.dart';

/// The room's landmark, which is where the stage reacts when an activity is solved (docs/design/m11-rooms.md section 5.1): 220 ms after the
/// check badge, a short motion of at most 900 ms, and then an end state that stays until the item leaves. It fills the box it is given (the
/// landmark's own place on the board, `LandmarkSlot`), which nothing else covers or is covered by, and draws the landmark at rest too.
///
/// It is driven by [solved] alone: never before the answer is right, never on a wrong one, and it is not counted or kept anywhere: when the
/// next item starts, [solved] is false again and the landmark is plain. With "reduce motion" on, only the end state appears (a fade of
/// 120 ms, nothing moves).
class StageReaction extends StatefulWidget {
  const StageReaction({super.key, required this.room, required this.solved});

  final RoomSpec room;
  final bool solved;

  /// The wait after the check badge pops, and how long the motion lasts at most.
  static const Duration after = Duration(milliseconds: 220);
  static const Duration motion = Duration(milliseconds: 900);
  static const Duration fade = Duration(milliseconds: 120);

  @override
  State<StageReaction> createState() => _StageReactionState();
}

class _StageReactionState extends State<StageReaction> with SingleTickerProviderStateMixin {
  static const Duration _full = Duration(milliseconds: 1120);

  late final AnimationController _c = AnimationController(vsync: this, duration: _full);
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    if (widget.solved) _c.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void didUpdateWidget(StageReaction old) {
    super.didUpdateWidget(old);
    if (widget.solved == old.solved) return;
    if (widget.solved) {
      _c.duration = _reduced ? StageReaction.fade : _full;
      _c.forward(from: 0);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// How far the motion is (0 to 1) at the controller's value; null while the reaction waits for the check badge.
  double? _progress() {
    if (_reduced) return 1;
    final double ms = _c.value * _full.inMilliseconds;
    if (ms < StageReaction.after.inMilliseconds) return null;
    return ((ms - StageReaction.after.inMilliseconds) / StageReaction.motion.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          final double? m = widget.solved ? _progress() : null;
          if (m == null) return _landmark(const <Widget>[]);
          // With "reduce motion" the landmark stays as it is and only its end state fades in.
          if (_reduced) {
            return _landmark(<Widget>[
              Opacity(
                opacity: _c.value,
                child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: _parts(m)),
              ),
            ]);
          }
          final Widget picture = _landmark(_parts(m));
          final double lift = math.sin(math.pi * m);
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: <Widget>[
              if (m < 1)
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            TokenColors.sparkTint.withValues(alpha: 0.9 * lift),
                            TokenColors.sparkTint.withValues(alpha: 0),
                          ],
                          stops: const <double>[0.2, 0.68],
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.scale(scale: 1 + 0.15 * lift, alignment: Alignment.bottomCenter, child: picture),
            ],
          );
        },
      ),
    ),
  );

  Widget _landmark(List<Widget> parts) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.expand,
    children: <Widget>[_svg(widget.room.art('landmark')), ...parts],
  );

  static Widget _svg(String asset) => SvgPicture.asset(asset, fit: BoxFit.fill, excludeFromSemantics: true);

  Widget _overlay() => _svg(widget.room.art('reacted'));

  /// What is drawn over the landmark at [m] of the motion, in the room's own way: the end state is the room's `reacted` picture.
  List<Widget> _parts(double m) {
    Widget fadeIn(double from, double to) => Opacity(
      opacity: Curves.easeOut.transform(((m - from) / (to - from)).clamp(0.0, 1.0)),
      child: _overlay(),
    );
    Widget moving(_Motion kind) => CustomPaint(painter: _MotionPainter(kind, m));
    switch (widget.room.id) {
      case RoomId.numbers:
        // Four hops up the four steps (150 ms each), then the top step fills with gold (300 ms).
        return <Widget>[if (m < _hopsEnd) moving(_Motion.dotHops), fadeIn(_hopsEnd, 1)];
      case RoomId.colors:
        // A drop falls into the pool (300 ms), two rings grow and fade (600 ms), one faint ring stays.
        return <Widget>[moving(_Motion.dropAndRipples), fadeIn(0.7, 1)];
      case RoomId.shapes:
        // A small fir grows from the ground (0 to 1.1 to 1).
        return <Widget>[
          Transform.scale(
            scale: Curves.easeOutBack.transform(m),
            alignment: const Alignment(-0.66, 0.84),
            child: _overlay(),
          ),
        ];
      case RoomId.logic:
        // The door's circle, square and triangle light in turn (200 ms each), then the arch glows (300 ms).
        final double rows = (m / _slotsEnd).clamp(0.0, 1.0);
        final int lit = (rows * 3).ceil();
        return <Widget>[
          if (lit > 0 && m < 1) ClipRect(clipper: _SlotsClipper(lit), child: _overlay()),
          fadeIn(_slotsEnd, 1),
        ];
      case RoomId.cs:
        // The crate is lifted on the hook's line (500 ms), set on the quay (200 ms) and squashes a little.
        final double up = m < _liftEnd
            ? Curves.easeOut.transform(m / _liftEnd)
            : 1 - Curves.easeIn.transform(((m - _liftEnd) / _setEnd).clamp(0.0, 1.0));
        final double settle = ((m - _liftEnd - _setEnd) / (1 - _liftEnd - _setEnd)).clamp(0.0, 1.0);
        final double squash = math.sin(math.pi * settle);
        return <Widget>[
          Opacity(
            opacity: (m * 10).clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: Offset(0, -0.17 * up),
              child: Transform(
                alignment: const Alignment(-0.1, 0.8),
                transform: Matrix4.diagonal3Values(1 + 0.08 * squash, 1 - 0.08 * squash, 1),
                child: _overlay(),
              ),
            ),
          ),
        ];
      case RoomId.math:
        // A gold coin arcs into the jar (500 ms); the jar bounces with the landmark.
        return <Widget>[if (m < _coinEnd) moving(_Motion.coin), fadeIn(_coinEnd, 1)];
      case RoomId.eng || RoomId.heb || RoomId.rus:
        // The window's glass warms and a sun rises in it, from the bottom up (600 ms).
        final double rise = Curves.easeOut.transform((m / 0.67).clamp(0.0, 1.0));
        return <Widget>[
          Opacity(
            opacity: rise,
            child: ClipRect(clipper: _RiseClipper(rise), child: _overlay()),
          ),
        ];
    }
  }

  static const double _hopsEnd = 600 / 900;
  static const double _slotsEnd = 600 / 900;
  static const double _liftEnd = 500 / 900;
  static const double _setEnd = 200 / 900;
  static const double _coinEnd = 500 / 900;
}

/// The three logic slots of the door, in the landmark's 200 unit box: each lights down to its own bottom edge.
class _SlotsClipper extends CustomClipper<Rect> {
  const _SlotsClipper(this.lit);

  final int lit;

  static const List<double> _bottoms = <double>[77, 105, 133];

  @override
  Rect getClip(Size size) {
    final double k = size.width / 200;
    return Rect.fromLTRB(80 * k, 44 * k, 120 * k, _bottoms[lit.clamp(1, 3) - 1] * k);
  }

  @override
  bool shouldReclip(_SlotsClipper old) => old.lit != lit;
}

/// Reveals a picture from its bottom edge upward.
class _RiseClipper extends CustomClipper<Rect> {
  const _RiseClipper(this.share);

  final double share;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, size.height * (1 - share), size.width * 2, size.height * 2);

  @override
  bool shouldReclip(_RiseClipper old) => old.share != share;
}

enum _Motion { dotHops, dropAndRipples, coin }

/// The moving bit of a reaction, drawn in the landmark's 200 by 200 units.
class _MotionPainter extends CustomPainter {
  const _MotionPainter(this.kind, this.m);

  final _Motion kind;
  final double m;

  /// The coral dot's places on the four steps, from the lowest to the top one (the last is where the end state has it).
  static const List<Offset> _steps = <Offset>[
    Offset(170, 138),
    Offset(136, 104),
    Offset(102, 70),
    Offset(68, 36),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);
    switch (kind) {
      case _Motion.dotHops:
        _dot(canvas);
      case _Motion.dropAndRipples:
        _drop(canvas);
      case _Motion.coin:
        _coin(canvas);
    }
  }

  void _dot(Canvas canvas) {
    final double p = (m / (600 / 900)).clamp(0.0, 1.0) * 4;
    final int seg = math.min(3, p.floor());
    final double u = p - seg;
    final Offset from = seg == 0 ? _steps[0] + const Offset(34, -44) : _steps[seg - 1];
    final Offset to = _steps[seg];
    final Offset at =
        Offset.lerp(from, to, Curves.easeInOut.transform(u))! + Offset(0, -18 * math.sin(math.pi * u));
    canvas.drawCircle(at, 9, Paint()..color = TokenColors.domainNumbersFill);
    canvas.drawCircle(
      at,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = TokenColors.ink,
    );
  }

  void _drop(Canvas canvas) {
    const Offset pool = Offset(100, 165);
    final double fall = (m / 0.333).clamp(0.0, 1.0);
    if (fall < 1) {
      final Offset at = Offset(100, 112 + 43 * Curves.easeIn.transform(fall));
      canvas.drawCircle(at, 3.6, Paint()..color = TokenColors.paper);
      canvas.drawCircle(
        at,
        3.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = TokenColors.sketch,
      );
      return;
    }
    final double q = ((m - 0.333) / 0.667).clamp(0.0, 1.0);
    for (final double delay in const <double>[0, 0.25]) {
      final double r = ((q - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (r <= 0 || r >= 1) continue;
      final double rx = 6 + 26 * r;
      canvas.drawOval(
        Rect.fromCenter(center: pool, width: rx * 2, height: rx * 2 * 8.5 / 32),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = TokenColors.ink.withValues(alpha: 0.35 * (1 - r)),
      );
    }
  }

  void _coin(Canvas canvas) {
    final double u = Curves.easeIn.transform((m / (500 / 900)).clamp(0.0, 1.0));
    const Offset a = Offset(30, 60);
    const Offset control = Offset(90, 10);
    const Offset b = Offset(144, 108);
    final Offset at = a * ((1 - u) * (1 - u)) + control * (2 * (1 - u) * u) + b * (u * u);
    canvas.drawOval(
      Rect.fromCenter(center: at + const Offset(0, 1.8), width: 24, height: 10),
      Paint()..color = TokenColors.sparkDeep,
    );
    canvas.drawOval(Rect.fromCenter(center: at, width: 24, height: 10), Paint()..color = TokenColors.spark);
  }

  @override
  bool shouldRepaint(_MotionPainter old) => old.m != m || old.kind != kind;
}
