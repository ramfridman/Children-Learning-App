import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The tracing template (T04): a numeral or a shape is shown as a dotted path, and the child follows it with a finger. Each stroke
/// is read from its start: a stroke is right when the finger covers the path (most of its length), stays near it, and begins at
/// the start. The same path traced from the other end carries the direction misconception (a numeral drawn the wrong way round).
///
/// Everything is in a 100 by 100 box. With `guide: start` only the starting dot and the first direction are drawn; after three
/// mistakes the whole path is shown and a dot walks along it.
class TraceSession extends TemplateSession {
  TraceSession(super.controller, this.activity);

  final TraceActivity activity;

  /// The strokes the child has finished (right), and the one in progress, in box units.
  final List<List<Offset>> finished = <List<Offset>>[];
  List<Offset> current = <Offset>[];
  AnswerState ring = AnswerState.idle;
  bool _busy = false;
  bool showWay = false;
  Offset? demo;
  int _demoId = 0;

  bool get guideShown => activity.fullGuide || showWay || controller.guided;

  int get strokeIndex => finished.length;

  void begin(Offset p) {
    if (_busy || ring == AnswerState.correct) return;
    current = <Offset>[p];
    notify();
  }

  void extend(Offset p) {
    if (_busy || current.isEmpty) return;
    current.add(p);
    notify();
  }

  Future<void> end() async {
    if (_busy || current.length < 2 || ring == AnswerState.correct) {
      current = <Offset>[];
      notify();
      return;
    }
    final List<Offset> drawn = _dense(current);
    final List<Offset> target = _resample(activity.strokes[strokeIndex], 32);
    final double tol = activity.tolerance;
    int covered = 0;
    for (final Offset t in target) {
      if (drawn.any((Offset d) => (d - t).distance <= tol)) covered++;
    }
    int near = 0;
    for (final Offset d in drawn) {
      if (target.any((Offset t) => (d - t).distance <= tol * 1.6)) near++;
    }
    final bool onPath = covered / target.length >= 0.85 && near / drawn.length >= 0.85;
    final bool startsRight = (drawn.first - target.first).distance <= tol * 2.2;
    final bool startsAtEnd = (drawn.first - target.last).distance <= tol * 2.2;
    final bool right = onPath && startsRight;
    if (right) {
      finished.add(List<Offset>.of(current));
      current = <Offset>[];
      _stopDemo();
      if (finished.length == activity.strokes.length) {
        _busy = true;
        await controller.submitPlacement(right: true, response: ResponseCode.traced);
        if (disposed) return;
        ring = AnswerState.correct;
        notify();
        later(TemplateSession.praisePause, controller.next);
      } else {
        notify();
      }
      return;
    }
    if (controller.guided) {
      // The help is at its top: a wrong stroke is not counted again; the way is shown once more instead.
      current = <Offset>[];
      _walk();
      return;
    }
    final String tag = (onPath && !startsRight && startsAtEnd && activity.directionTag != null)
        ? activity.directionTag!
        : (activity.wrongTag ?? '');
    _busy = true;
    await controller.submitPlacement(
      right: false,
      tag: tag,
      response: onPath ? ResponseCode.tracedBackwards : ResponseCode.tracedOff,
    );
    if (disposed) return;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      finished.clear();
      current = <Offset>[];
      ring = AnswerState.idle;
      _busy = false;
      if (controller.guided) _walk();
      notify();
    });
  }

  /// A finger path with a point at least every two units, so that a fast stroke still covers the path.
  static List<Offset> _dense(List<Offset> pts) {
    final List<Offset> out = <Offset>[pts.first];
    for (int i = 1; i < pts.length; i++) {
      final Offset a = pts[i - 1];
      final Offset b = pts[i];
      final int n = math.max(1, ((b - a).distance / 2).ceil());
      for (int k = 1; k <= n; k++) {
        out.add(Offset.lerp(a, b, k / n)!);
      }
    }
    return out;
  }

  /// [count] points spread evenly along the polyline.
  static List<Offset> _resample(List<Offset> pts, int count) {
    final List<double> cum = <double>[0];
    for (int i = 1; i < pts.length; i++) {
      cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
    }
    final double total = cum.last;
    final List<Offset> out = <Offset>[];
    int seg = 1;
    for (int k = 0; k < count; k++) {
      final double d = total * k / (count - 1);
      while (seg < pts.length - 1 && cum[seg] < d) {
        seg++;
      }
      final double span = cum[seg] - cum[seg - 1];
      out.add(Offset.lerp(pts[seg - 1], pts[seg], span == 0 ? 0 : ((d - cum[seg - 1]) / span).clamp(0, 1))!);
    }
    return out;
  }

  void _stopDemo() {
    _demoId++;
    demo = null;
    _handDemo = false;
  }

  /// True while the worked example (level 3) walks: the pointing hand goes with the dot.
  bool _handDemo = false;

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final Offset? dot = demo;
      if (dot == null || !_handDemo) return const SizedBox();
      // The dot is in the box's own 0 to 100; the box is the square at the middle of the stage, inside its border.
      final double side = math.min(size.width, size.height) - 6;
      final double inner = side - 2 * _border;
      final Offset origin = Offset((size.width - side) / 2 + _border, (size.height - side) / 2 + _border);
      return HintOverlay(
        marks: <HintMark>[HandMark(origin + dot / 100 * inner, snap: true)],
        size: size,
        clearOf: handClearOf(spec),
        layer: HintLayer.hands,
      );
    },
  );

  /// A dot walks along the stroke that is next, as far as [fraction] of it, [msPerPoint] for each of its points. With [guide] the
  /// whole path is drawn as well; with [rest] of the strokes it goes on to the strokes after that one (the worked example).
  void _walk({double fraction = 1, int msPerPoint = 70, bool guide = true, bool allStrokes = false}) {
    _stopDemo();
    _handDemo = allStrokes;
    final int id = _demoId;
    if (guide) showWay = true;
    int at = 0;
    final int first = math.min(strokeIndex, activity.strokes.length - 1);
    final int last = allStrokes ? activity.strokes.length - 1 : first;
    for (int k = first; k <= last; k++) {
      final List<Offset> path = _resample(activity.strokes[k], 24);
      final int shown = math.max(2, (path.length * fraction).round());
      for (int i = 0; i < shown; i++) {
        later(Duration(milliseconds: msPerPoint * (++at)), () {
          if (_demoId != id) return;
          demo = path[i];
          notify();
        });
      }
      at += 6; // a short rest between strokes
    }
    later(Duration(milliseconds: msPerPoint * (at + 8)), () {
      if (_demoId != id) return;
      demo = null;
      notify();
      if (allStrokes) controller.demoDone();
    });
    notify();
  }

  @override
  void onReset() {
    finished.clear();
    current = <Offset>[];
    ring = AnswerState.idle;
    _busy = false;
    showWay = false;
    _stopDemo();
    notify();
  }

  @override
  void onReplay() {}

  @override
  void onHint() {
    if (_busy) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.firstStroke:
        // Hint 1: where to start and which way, the first part of the stroke only.
        _walk(fraction: 0.3, guide: false);
      case HintPicture.wholeStroke:
        // Hint 2: the whole stroke, slower, with the path drawn.
        _walk(msPerPoint: 110);
      default:
        // The worked example: every stroke of the numeral or shape in turn, with the path drawn. Then it is the child's turn.
        _walk(allStrokes: true);
    }
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final double side = math.min(size.width, size.height) - 6;
      // The finger is read and the path is drawn inside the border, on the same square.
      final double inner = side - 2 * _border;
      Offset toBox(Offset local) => local / inner * 100;
      return Semantics(
        container: true,
        label: activity.altText,
        child: Center(
          child: Container(
            key: const Key('trace-stage'),
            width: side,
            height: side,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(TokenRadius.lg),
              border: Border.all(
                color: ring == AnswerState.correct
                    ? TokenColors.correctGlow
                    : (ring == AnswerState.notYet ? TokenColors.notYetRing : TokenColors.hairline),
                width: _border,
              ),
            ),
            child: GestureDetector(
              key: const Key('trace-touch'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (DragStartDetails d) => begin(toBox(d.localPosition)),
              onPanUpdate: (DragUpdateDetails d) => extend(toBox(d.localPosition)),
              onPanEnd: (DragEndDetails d) => end(),
              child: CustomPaint(painter: _TracePainter(this), size: Size(inner, inner)),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;

  static const double _border = 4;
}

class _TracePainter extends CustomPainter {
  _TracePainter(this.s) : super(repaint: s);

  final TraceSession s;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 100;
    Offset px(Offset p) => p * k;
    final TraceActivity a = s.activity;
    final Paint dot = Paint()..color = TokenColors.ink.withValues(alpha: 0.4);
    for (final (int i, List<Offset> stroke) in a.strokes.indexed) {
      final bool done = i < s.finished.length;
      if (s.guideShown && !done) {
        for (final Offset p in TraceSession._resample(stroke, math.max(6, (_length(stroke) / 5).round()))) {
          canvas.drawCircle(px(p), 2.3 * k, dot);
        }
      }
      if (i == s.strokeIndex) {
        // the starting dot, and (when only the start is shown) the first direction
        canvas.drawCircle(px(stroke.first), 4.5 * k, Paint()..color = TokenColors.correctGlow);
        if (!s.guideShown) {
          final List<Offset> lead = TraceSession._resample(stroke, 12).take(4).toList();
          for (final Offset p in lead.skip(1)) {
            canvas.drawCircle(px(p), 2.3 * k, dot);
          }
        }
      }
    }
    void line(List<Offset> pts, Color colour) {
      final Paint paint = Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Path path = Path()..moveTo(px(pts.first).dx, px(pts.first).dy);
      for (final Offset p in pts.skip(1)) {
        path.lineTo(px(p).dx, px(p).dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final List<Offset> f in s.finished) {
      line(f, TokenColors.correctGlow);
    }
    if (s.current.length > 1) {
      line(s.current, s.ring == AnswerState.notYet ? TokenColors.notYetRing : TokenColors.ink);
    }
    if (s.demo != null) canvas.drawCircle(px(s.demo!), 5 * k, Paint()..color = TokenColors.hintHalo);
  }

  static double _length(List<Offset> pts) {
    double d = 0;
    for (int i = 1; i < pts.length; i++) {
      d += (pts[i] - pts[i - 1]).distance;
    }
    return d;
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
