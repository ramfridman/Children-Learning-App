import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart';
import 'lesson_arc.dart' show ArcPart, ArcStep;
import 'response_code.dart';
import 'show_solids.dart';
import 'show_stage.dart';
import 'stroke_geometry.dart';
import 'template_session.dart';

/// The tracing template (T04): a numeral or a shape is shown as a dotted path, and the child follows it with a finger. Each stroke
/// is read from its start: a stroke is right when the finger covers the path (most of its length), stays near it, and begins at
/// the start. The same path traced from the other end carries the direction misconception (a numeral drawn the wrong way round).
///
/// Everything is in a 100 by 100 box. With `guide: start` only the starting dot and the first direction are drawn; after three
/// mistakes the whole path is shown and a dot walks along it.
///
/// The host's part (M11 Stage 2): a path is drawn side by side, corner to corner (a circle in quarters, `traceSides`). In a Show the host draws
/// every side but the last with its pointer, each staying lit, and the child traces the rest (a wrong stroke is only "let's look again", and nothing
/// is written); in a Together item the host draws its first sides ([ArcStep.lead]) and the child traces the rest.
class TraceSession extends TemplateSession {
  TraceSession(super.controller, this.activity);

  final TraceActivity activity;

  /// The sides of each stroke, and how many of them the host has drawn; the child's strokes are what is left ([childStrokes]).
  late final List<List<List<Offset>>> _sides = <List<List<Offset>>>[
    for (final List<Offset> stroke in activity.strokes) traceSides(stroke),
  ];
  int _hosted = 0;
  late List<List<Offset>> childStrokes = activity.strokes;
  Size _size = Size.zero;
  ActivitySpec? _spec;

  bool get _canDraw => _spec != null && !_size.isEmpty;

  /// How many sides the host has drawn, and the strokes the child still has to trace: the rest of the stroke the host stopped in, then the strokes
  /// after it. A stroke the host drew whole is the host's.
  void _setHosted(int n) {
    _hosted = n;
    final List<List<Offset>> out = <List<Offset>>[];
    int left = n;
    for (final List<List<Offset>> sides in _sides) {
      if (left >= sides.length) {
        left -= sides.length;
        continue;
      }
      final List<Offset> rest = <Offset>[];
      for (final List<Offset> side in sides.skip(left)) {
        rest.addAll(rest.isEmpty ? side : side.skip(1));
      }
      out.add(rest);
      left = 0;
    }
    childStrokes = n == 0 ? activity.strokes : out;
  }

  /// The square the path is drawn in, in the stage's own points: inside the border, centred.
  Rect get _box {
    final double side = math.min(_size.width, _size.height) - 6;
    final double inner = side - 2 * _border;
    return Rect.fromLTWH(
      (_size.width - side) / 2 + _border,
      (_size.height - side) / 2 + _border,
      inner,
      inner,
    );
  }

  /// The host draws side [n] (counted from 1) with its pointer, and it stays lit: its own colour, white with the room's deep edge.
  Future<void> _hostSide(int n, {required bool fast}) async {
    final List<Offset> side = <List<Offset>>[for (final List<List<Offset>> s in _sides) ...s][n - 1];
    final Rect box = _box;
    final List<Offset> path = <Offset>[for (final Offset p in side) box.topLeft + p / 100 * box.width];
    final ShowStyle? style = showStyle;
    if (style != null && _canDraw && !fast) {
      showMarks.scale = hintScale(_size);
      await ShowDirector(
        this,
        style,
        showMarks,
      ).drawPath(path, ms: style.slow ? 900 : 600, around: box.center);
      await pause(const Duration(milliseconds: 250));
    } else {
      showMarks.lit.add(path);
      await pause(Duration(milliseconds: fast ? 200 : 700));
    }
    _setHosted(n);
    notify();
  }

  @override
  void startHost() {
    final ArcStep? step = controller.step;
    if (step == null || hosting) return;
    if (activity.isShow) {
      unawaited(
        playShow(
          activity.show!,
          move: (ShowStep s, {required bool fast}) => _hostSide(s.segment!, fast: fast),
        ),
      );
    } else if (step.part == ArcPart.together && controller.leading && step.lead > 0) {
      unawaited(
        playLead(<Future<void> Function()>[
          for (int n = 1; n <= step.lead; n++) () => _hostSide(n, fast: false),
        ]),
      );
    }
  }

  /// A touch on a reminder skips what the host still has to do: its sides are lit at once, and the child's stroke is left.
  @override
  void onScreenTouch() {
    if (!activity.isShow) return;
    skipHost(() {
      showMarks.clearMarks();
      final Rect box = _box;
      final List<List<Offset>> all = <List<Offset>>[for (final List<List<Offset>> s in _sides) ...s];
      final int upto = activity.show!.hostSteps.last.segment!;
      showMarks.lit.clear();
      for (final List<Offset> side in all.take(upto)) {
        showMarks.lit.add(<Offset>[for (final Offset p in side) box.topLeft + p / 100 * box.width]);
      }
      _setHosted(upto);
    });
  }

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
    if (_busy || hosting || ring == AnswerState.correct) return;
    current = <Offset>[p];
    notify();
  }

  void extend(Offset p) {
    if (_busy || hosting || current.isEmpty) return;
    current.add(p);
    notify();
  }

  Future<void> end() async {
    if (_busy || hosting || current.length < 2 || ring == AnswerState.correct) {
      current = <Offset>[];
      notify();
      return;
    }
    final PathVerdict v = pathVerdict(current, childStrokes[strokeIndex], activity.tolerance);
    final bool onPath = v.onPath;
    final bool startsRight = v.startsRight;
    final bool startsAtEnd = v.startsAtEnd;
    final bool right = onPath && startsRight;
    if (right) {
      finished.add(List<Offset>.of(current));
      current = <Offset>[];
      _stopDemo();
      if (finished.length == childStrokes.length) {
        _busy = true;
        if (activity.isShow) {
          // The child traced the last side of the Show: the host's key line is said again as the praise, and nothing is written.
          controller.completePractice();
        } else {
          await controller.submitPlacement(right: true, response: ResponseCode.traced);
        }
        if (disposed) return;
        ring = AnswerState.correct;
        notify();
        later(praise, controller.next);
      } else {
        notify();
      }
      return;
    }
    if (activity.isShow) {
      // The wrong stroke of a Show: nothing is written and nothing is counted; the host says "let's look again" and the child may try again.
      current = <Offset>[];
      controller.speak(activity.feedback.forIncorrect(null));
      notify();
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
    final int first = math.min(strokeIndex, childStrokes.length - 1);
    final int last = allStrokes ? childStrokes.length - 1 : first;
    for (int k = first; k <= last; k++) {
      final List<Offset> path = resampleStroke(childStrokes[k], 24);
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
    // The sides the host drew in the lead of a Together item stay drawn, and a Show's keep their place; any other tracing starts from nothing.
    final ArcStep? step = controller.step;
    _setHosted(
      activity.isShow
          ? _hosted
          : (step?.part == ArcPart.together && !controller.leading ? math.min(step!.lead, _hosted) : 0),
    );
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
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _stage(size));
  }

  Widget _stage(Size size) {
    final double side = math.min(size.width, size.height) - 6;
    // The finger is read and the path is drawn inside the border, on the same square.
    final double inner = side - 2 * _border;
    Offset toBox(Offset local) => local / inner * 100;
    return Semantics(
      container: true,
      label: activity.altText,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
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
          ),
          if (showStyle != null)
            Positioned.fill(
              child: ShowLayer(marks: showMarks, style: showStyle!),
            ),
        ],
      ),
    );
  }

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
    final Paint dot = Paint()..color = TokenColors.ink.withValues(alpha: 0.4);
    for (final (int i, List<Offset> stroke) in s.childStrokes.indexed) {
      final bool done = i < s.finished.length;
      if (s.guideShown && !done) {
        for (final Offset p in resampleStroke(stroke, math.max(6, (strokeLength(stroke) / 5).round()))) {
          canvas.drawCircle(px(p), 2.3 * k, dot);
        }
      }
      if (i == s.strokeIndex) {
        // the starting dot, and (when only the start is shown) the first direction
        canvas.drawCircle(px(stroke.first), 4.5 * k, Paint()..color = TokenColors.correctGlow);
        if (!s.guideShown) {
          final List<Offset> lead = resampleStroke(stroke, 12).take(4).toList();
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

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
