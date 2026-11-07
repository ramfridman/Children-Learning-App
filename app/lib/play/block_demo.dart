import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/tokens.g.dart';
import 'block_art.dart';

// The demonstration that a rod is ten cubes (docs/design/c1-blocks.md section 6, the owner's choice of 2026-11-07). Ten loose cubes stand in
// the 2 by 5 frame; they are counted 1 to 10, each lighting as its number comes; they glide into one column and snap together (the gaps close,
// a ring of light); the rod stands with a "10" beside it, and the line "ten cubes are one rod" is said; then the picture goes and the first item
// begins. A lesson with blocks opens with it for a child's first three such lessons, then with the short version (the glide and the snap); the
// eye ("show me") of an item with rods plays it too.
//
// Nothing here is timed for the child: it is a thing to watch, it never waits for an answer and any touch of the item ends it. With "reduce
// motion" the cubes light 1 to 10 in place and the picture fades to the rod. No sound file is made here; the click of the snap is the voice
// director's, later: `onSnap` is where it will go.

/// The line said at the snap when the lesson says none of its own (an eye on an item of a lesson without the demonstration).
const String blockDemoLine = 'vo:demo.ten_is_rod';

enum BlockDemoKind {
  /// Counted, glides, snaps, the line (about nine seconds).
  full,

  /// Only the glide and the snap (two seconds).
  short,
}

/// Everything the demonstration draws at one moment. Places are in units of a cube's side, from the middle of the ground: [cubes] are the
/// ten cubes' left edge and bottom, in the order they are counted.
class BlockDemoFrame {
  const BlockDemoFrame({
    required this.cubes,
    this.cubeAlpha = 1,
    this.lit,
    this.numeral,
    this.rodAlpha = 0,
    this.ringAlpha = 0,
    this.tileAlpha = 0,
    this.slide = 0,
    this.fade = 1,
  });

  final List<Offset> cubes;

  /// How much of the ten loose cubes shows (they give way to the rod).
  final double cubeAlpha;

  /// The cube that is lit now, and the number being counted.
  final int? lit;
  final int? numeral;

  /// How much of the rod shows, the ring of light round it, and the tile with the 10 beside it.
  final double rodAlpha;
  final double ringAlpha;
  final double tileAlpha;

  /// How far the picture has slid to the start side, in units, and how much of it is left (the item begins).
  final double slide;
  final double fade;
}

/// The timeline of the demonstration: when each thing happens, and what is on show at a time.
class BlockDemoScript {
  const BlockDemoScript(this.kind, {this.reduced = false});

  final BlockDemoKind kind;

  /// "Reduce motion": no gliding; the cubes light in place and the picture fades to the rod.
  final bool reduced;

  // Milliseconds. The counting: each cube 0.5 s, from 0.6 s. The glide: 0.5 s a cube, 40 ms apart. The gaps close in 120 ms, the ring lasts
  // 400 ms, the tile stays a while, the picture goes in 0.4 s.
  static const int appear = 600,
      perCube = 500,
      glide = 500,
      stagger = 40,
      closing = 120,
      ring = 400,
      going = 400;
  static const int _count = appear + 10 * perCube;
  static const int _gap = 200;
  static const double _columnGap = 0.15;

  bool get counts => kind == BlockDemoKind.full;

  int get _glideAt => counts ? _count + _gap : 0;
  int get _glideEnd => _glideAt + 9 * stagger + glide;
  int get _closeAt => _glideEnd + 40;
  int get _fadeStart => _closeAt + closing + ring + (counts ? 1000 : 180);

  /// When the picture is whole and the voice may say its line (the snap, or the fade to the rod).
  Duration get snap => Duration(milliseconds: reduced ? _count + _gap : _closeAt);

  /// How long the demonstration lasts.
  Duration get length => Duration(milliseconds: reduced ? _reducedFade + going : _fadeStart + going);

  int get _reducedFade => counts ? _count + _gap + 300 + 800 : 500;

  static const List<Offset> _frame = <Offset>[
    Offset(-1.15, 0),
    Offset(-1.15, 1.3),
    Offset(-1.15, 2.6),
    Offset(-1.15, 3.9),
    Offset(-1.15, 5.2),
    Offset(0.15, 0),
    Offset(0.15, 1.3),
    Offset(0.15, 2.6),
    Offset(0.15, 3.9),
    Offset(0.15, 5.2),
  ];

  /// Where cube [i] is in the frame of ones, and in the column it glides into with [gap] between the cubes.
  static Offset inFrame(int i) => _frame[i];
  static Offset inColumn(int i, double gap) => Offset(-0.5, i * (1 + gap));

  BlockDemoFrame at(Duration time) {
    final int t = time.inMilliseconds;
    final double fade = _fadeOf(t);
    if (reduced) return _reduced(t, fade);
    final List<Offset> cubes = <Offset>[];
    for (int i = 0; i < 10; i++) {
      final double p = Curves.easeOutCubic.transform(((t - _glideAt - i * stagger) / glide).clamp(0.0, 1.0));
      final double gap = _columnGap * (1 - ((t - _closeAt) / closing).clamp(0.0, 1.0));
      cubes.add(Offset.lerp(inFrame(i), inColumn(i, gap), p)!);
    }
    final double whole = ((t - _closeAt) / closing).clamp(0.0, 1.0);
    final int? lit = counts && t >= appear && t < _count ? (t - appear) ~/ perCube : null;
    final double ringT = ((t - _closeAt - closing) / ring);
    return BlockDemoFrame(
      cubes: cubes,
      cubeAlpha: math.min(counts ? ((t) / appear).clamp(0.0, 1.0) : 1.0, 1 - whole),
      lit: lit,
      numeral: lit == null ? null : lit + 1,
      rodAlpha: whole,
      ringAlpha: ringT >= 0 && ringT <= 1 ? 1 - ringT : 0,
      tileAlpha: counts ? ((t - _closeAt - closing) / 300).clamp(0.0, 1.0) : 0,
      slide: (1 - fade) * 1.5,
      fade: fade,
    );
  }

  BlockDemoFrame _reduced(int t, double fade) {
    final List<Offset> cubes = <Offset>[for (int i = 0; i < 10; i++) inFrame(i)];
    final int start = counts ? _count + _gap : 0;
    final double mix = ((t - start) / 300).clamp(0.0, 1.0);
    final int? lit = counts && t >= appear && t < _count ? (t - appear) ~/ perCube : null;
    return BlockDemoFrame(
      cubes: cubes,
      cubeAlpha: math.min(counts ? (t / appear).clamp(0.0, 1.0) : 1.0, 1 - mix),
      lit: lit,
      numeral: lit == null ? null : lit + 1,
      rodAlpha: mix,
      tileAlpha: counts ? mix : 0,
      fade: fade,
    );
  }

  double _fadeOf(int t) {
    final int start = reduced ? _reducedFade : _fadeStart;
    return (1 - ((t - start) / going)).clamp(0.0, 1.0);
  }
}

/// The demonstration, drawn in the room it is given (the stage), on [background] (the item's own scene). It calls [onSnap] when the ten are one
/// rod, and [onDone] when it has faded. With [reduce] (the system's "reduce motion") the cubes do not glide.
class BlockDemo extends StatefulWidget {
  const BlockDemo({
    super.key,
    required this.kind,
    required this.maxUnit,
    required this.onDone,
    this.onSnap,
    this.background,
    this.reduce = false,
  });

  final BlockDemoKind kind;

  /// The biggest cube (22 on a phone, 28 on a tablet).
  final double maxUnit;
  final VoidCallback onDone;
  final VoidCallback? onSnap;
  final Widget? background;
  final bool reduce;

  /// The side of a cube at which the demonstration fits a room of [room]: ten cubes in a column with the small gaps they glide with, and a margin.
  static double unitFor(Size room, double maxUnit) =>
      math.min(maxUnit, math.min((room.height - 12) / 11.4, (room.width - 12) / 9));

  @override
  State<BlockDemo> createState() => _BlockDemoState();
}

class _BlockDemoState extends State<BlockDemo> with SingleTickerProviderStateMixin {
  late final BlockDemoScript _script;
  late final AnimationController _clock;
  bool _snapped = false;

  @override
  void initState() {
    super.initState();
    _script = BlockDemoScript(widget.kind, reduced: widget.reduce);
    // With the system's "reduce motion" a controller runs 20 times faster unless it is told to keep its time: the demonstration's own reduced form
    // (the cubes light in place, the picture fades to the rod) has its own length and keeps it (QA-C1c-2).
    _clock = AnimationController(
      vsync: this,
      duration: _script.length,
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_tick);
    _clock.forward().whenComplete(_finish);
  }

  void _tick() {
    if (!_snapped && _clock.value * _script.length.inMilliseconds >= _script.snap.inMilliseconds) {
      _snapped = true;
      widget.onSnap?.call();
    }
  }

  void _finish() {
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final double u = BlockDemo.unitFor(box.biggest, widget.maxUnit);
      return AnimatedBuilder(
        animation: _clock,
        builder: (BuildContext context, Widget? _) {
          final BlockDemoFrame f = _script.at(_script.length * _clock.value);
          return Opacity(
            opacity: f.fade,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ?widget.background,
                CustomPaint(painter: BlockDemoPainter(f, u)),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Draws one [BlockDemoFrame] at a cube of [u] points (a test draws the frames of the timeline one by one).
class BlockDemoPainter extends CustomPainter {
  BlockDemoPainter(this.f, this.u);

  final BlockDemoFrame f;
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final double midX = size.width / 2 - f.slide * u * 2;
    final double floor = size.height - 6 - 0.15 * u;
    Rect cell(Offset p) => Rect.fromLTWH(midX + p.dx * u, floor - p.dy * u - u, u, u);
    if (f.ringAlpha > 0) {
      final Rect rod = cell(BlockDemoScript.inColumn(9, 0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rod.left, rod.top, rod.right, floor).inflate(0.6 * u),
          Radius.circular(0.9 * u),
        ),
        Paint()..color = TokenColors.paper.withValues(alpha: 0.75 * f.ringAlpha),
      );
    }
    if (f.cubeAlpha > 0) {
      canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: f.cubeAlpha));
      for (int i = 0; i < f.cubes.length; i++) {
        final Rect c = cell(f.cubes[i]);
        if (f.lit == i) paintCubeGlow(canvas, c);
        paintCube(canvas, c, CubeColours.sea);
      }
      canvas.restore();
    }
    if (f.rodAlpha > 0) {
      final Rect rod = Rect.fromLTWH(midX - 0.5 * u, floor - 10 * u, u, 10 * u);
      canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: f.rodAlpha));
      paintRod(canvas, rod, CubeColours.sea);
      canvas.restore();
    }
    if (f.numeral != null) _text(canvas, '${f.numeral}', Offset(midX + 3.6 * u, floor - 6.4 * u), 2.6 * u, 1);
    if (f.tileAlpha > 0) {
      final double side = math.min(72, 5.2 * u);
      final Rect tile = Rect.fromLTWH(midX + 1.6 * u, floor - 5 * u - side / 2, side, side);
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, const Radius.circular(20)),
        Paint()..color = TokenColors.paper.withValues(alpha: f.tileAlpha),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, const Radius.circular(20)),
        Paint()
          ..color = TokenColors.hairline.withValues(alpha: f.tileAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      _text(canvas, '10', tile.center, side * 0.6, f.tileAlpha);
    }
  }

  void _text(Canvas canvas, String text, Offset center, double size, double alpha) {
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: text,
        style: AppText.fixed(
          size: size,
          weight: 800,
          lineHeight: 1,
        ).copyWith(color: TokenColors.ink.withValues(alpha: alpha)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, center - Offset(p.width / 2, p.height / 2));
    p.dispose();
  }

  @override
  bool shouldRepaint(BlockDemoPainter old) => old.f != f || old.u != u;
}
