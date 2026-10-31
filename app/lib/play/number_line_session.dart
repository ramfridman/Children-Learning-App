import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hint_widgets.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'template_session.dart';

/// The number-line template (T09). The line always runs from the small number on the left to the large number on the right,
/// in every language. In `place` mode the child touches the tick where the marker belongs; in `jump` mode the marker stands on a
/// number and hops, and the child touches the tick where it lands. A touch is the answer: no confirm button.
///
/// A touch on the mirror of the right tick (the line read from the right) is written with its own misconception, M-NL-DIR.
/// After three wrong touches only the right tick is taken: the guide first hops the marker along the whole way, one unit at a time
/// with a dotted arc and a number for each hop, the pointing hand going with it, and the tick it lands on stays lit. The first two
/// helps light the start and hop one unit (one arc, the number 1), and never the tick the marker is to land on. The line and its
/// numbers run left to right; a hop back is an arc that goes to the left, along the same line.
class NumberLineSession extends TemplateSession {
  NumberLineSession(super.controller, this.activity) : markerAt = activity.start;

  final NumberLineActivity activity;

  /// The number the marker stands on, or null (not on the line yet).
  int? markerAt;

  /// The ticks that the help has lit, and the tick that just said "not yet".
  final Set<int> trail = <int>{};

  /// How many dots the hop size pill shows (hint 1 of a jump), and how many of them have been used up (hint 2 hops once).
  int hopDots = 0;
  int hopDotsUsed = 0;
  int? wrongTick;

  /// The arcs, the numbers and the pointing hand of the hints, in the stage's own points (see [HintPlayer]).
  late final HintPlayer _hint = HintPlayer(this);
  AnswerState ring = AnswerState.idle;
  bool _busy = false;
  bool demoRunning = false;
  int _demo = 0; // a new touch or a new help ends the one that is running

  int get tickCount => activity.to - activity.from + 1;

  // The places of the stage (the same numbers `_LineStage` draws with), for the hints' marks.
  static const double _pad = 22;

  double _tickX(Size size, int n) =>
      _pad + (n - activity.from) / (activity.to - activity.from) * (size.width - 2 * _pad);

  double _lineY(Size size) => size.height * 0.66;

  /// The top of the tick of [n]: where the fingertip touches it and where a hop starts and ends.
  Offset _tickTop(Size size, int n) => Offset(_tickX(size, n), _lineY(size) - 12);

  /// A hop of one unit from [a] to [b] as a dotted arc, and the number of the hop (1, 2, 3) over its middle.
  List<HintMark> _hop(Size size, int a, int b, int number) => <HintMark>[
    ArcMark(_tickTop(size, a), _tickTop(size, b)),
    BadgeMark(Offset((_tickX(size, a) + _tickX(size, b)) / 2, _lineY(size) - 12 - 9 - 14), number),
  ];

  Size _size = Size.zero;

  /// The tick (a number) nearest to a touch at [dx] on a line [width] points wide, with [pad] points of margin.
  int tickAt(double dx, double width, double pad) {
    final double share = ((dx - pad) / math.max(1, width - 2 * pad)).clamp(0.0, 1.0);
    return activity.from + (share * (activity.to - activity.from)).round();
  }

  Future<void> choose(int n) async {
    if (_busy || ring == AnswerState.correct) return;
    _stopWay();
    if (controller.guided && n != activity.target) {
      _showWay();
      return;
    }
    hopDots = 0;
    _busy = true;
    markerAt = n;
    trail.clear();
    notify();
    final bool right = n == activity.target;
    String tag = '';
    if (!right) {
      final bool mirror = n == activity.from + activity.to - activity.target;
      tag = (mirror && activity.mirrorTag != null) ? activity.mirrorTag! : (activity.wrongTag ?? '');
    }
    await controller.submitPlacement(right: right, tag: tag, response: '$n');
    if (disposed) return;
    if (right) {
      ring = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    wrongTick = n;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      wrongTick = null;
      ring = AnswerState.idle;
      markerAt = activity.start;
      _busy = false;
      if (controller.guided) _showWay();
      notify();
    });
  }

  /// The help counts up the way: from where the marker stands (or from the start of the line) to the right tick.
  void _stopWay() {
    _demo++;
    demoRunning = false;
    _hint.clear();
    trail.clear();
    hopDots = 0;
    hopDotsUsed = 0;
  }

  /// Hint 1: the start of the line is lit, with the landmarks (0, 5, 10) of a line that is put on by touch, or the size of the hop
  /// as a pill of dots in a jump. The tick the marker is to land on is never lit.
  void _lightStart() {
    _stopWay();
    if (activity.jump) {
      trail.add(activity.start ?? activity.from);
      hopDots = activity.hops.isEmpty ? 0 : activity.hops.first.abs();
    } else {
      trail.add(activity.from);
      for (int n = activity.from; n <= activity.to; n++) {
        if (n % 5 == 0 && n != activity.target) trail.add(n);
      }
    }
    trail.remove(activity.target);
    notify();
  }

  /// Hint 2: the guide hops the marker one unit from the start (counting back when the line is walked back) and stops. A hop that
  /// would land on the tick of the answer is not taken: the marker only stands on the start.
  void _hopOnce() {
    _stopWay();
    final int from = activity.start ?? activity.from;
    final int dir = activity.jump && activity.hops.isNotEmpty && activity.hops.first < 0 ? -1 : 1;
    final int one = from + dir;
    markerAt = from;
    trail.add(from);
    if (activity.jump && activity.hops.isNotEmpty) {
      hopDots = activity.hops.first.abs();
      hopDotsUsed = one == activity.target ? 0 : 1;
    }
    notify();
    if (one == activity.target || one < activity.from || one > activity.to) return;
    final int id = _demo;
    // The marker hops after 700 ms, and the arc and its number 1 stay where it landed.
    _hint.play(
      HintPlan(<HintFrame>[
        const HintFrame(<HintMark>[], hold: Duration(milliseconds: 700)),
      ], rest: _hop(_size, from, one, 1)),
    );
    later(const Duration(milliseconds: 700), () {
      if (_demo != id) return;
      markerAt = one;
      trail.add(one);
      notify();
    });
  }

  /// The worked example: the marker hops along the way one unit at a time (a hop of three is three hops), each with its arc and its
  /// number, the pointing hand going with it to each tick. A line that is put on by touch has no arcs (its hops would be too
  /// close), only the number of the tick the marker is on. The tick it ends on is lit and the hand rests on it.
  void _showWay() {
    _stopWay();
    final int id = _demo;
    demoRunning = true;
    final int from = activity.start ?? activity.from;
    final List<int> way = _unitWay(from, activity.jump ? _landings().last : activity.target);
    markerAt = activity.start;
    notify();
    final int gap = way.length > 12 ? 380 : 500;
    // The running number stands up and to the left of the marker: the hand comes from the upper right and would hide it right
    // above the tick, and right above there is no room under the stage's top edge.
    final double k = (_size.height / 128).clamp(0.85, 1.4).toDouble();
    final double room = math.max(15 * k, _lineY(_size) - math.min(_size.height * 0.5, 52) - 16 * k);
    List<HintMark> counted(int upTo) => <HintMark>[
      if (activity.jump)
        for (int i = 0; i < upTo; i++) ..._hop(_size, i == 0 ? from : way[i - 1], way[i], i + 1)
      else if (upTo > 0)
        BadgeMark(Offset(_tickX(_size, way[upTo - 1]) - 30 * k, room), upTo),
    ];
    _hint.play(
      handTourPlan(<HandStop>[
        HandStop(_tickTop(_size, from), gap),
        for (int i = 0; i < way.length; i++) HandStop(_tickTop(_size, way[i]), gap, marks: counted(i + 1)),
        HandStop(_tickTop(_size, way.last), 1200, marks: counted(way.length)),
      ]),
    );
    for (int i = 0; i < way.length; i++) {
      later(Duration(milliseconds: gap * (i + 1)), () {
        if (_demo != id) return;
        trail.add(way[i]);
        markerAt = way[i];
        notify();
      });
    }
    later(Duration(milliseconds: gap * (way.length + 1) + 1200), () {
      if (_demo != id) return;
      demoRunning = false;
      markerAt = activity.start;
      notify();
      controller.demoDone();
    });
  }

  List<int> _landings() {
    int at = activity.start ?? activity.from;
    return <int>[for (final int h in activity.hops) at += h];
  }

  /// Every number from [from] to [to], one unit at a time (counting back when [to] is the smaller), without [from] itself.
  List<int> _unitWay(int from, int to) => <int>[
    for (int n = from; n != to; n += to > from ? 1 : -1) n + (to > from ? 1 : -1),
  ];

  @override
  void onReset() {
    markerAt = activity.start;
    _stopWay();
    wrongTick = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {}

  @override
  void onHint() {
    if (_busy && !controller.guided) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.startAndLandmarks:
        _lightStart();
      case HintPicture.firstHop:
        _hopOnce();
      default:
        _showWay();
    }
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _LineStage(this, size)),
        _hint.body(size),
      ],
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;
}

class _LineStage extends StatelessWidget {
  const _LineStage(this.s, this.size);

  final NumberLineSession s;
  final Size size;

  static const double _pad = 22;

  double _x(int n) {
    final NumberLineActivity a = s.activity;
    return _pad + (n - a.from) / (a.to - a.from) * (size.width - 2 * _pad);
  }

  @override
  Widget build(BuildContext context) {
    final NumberLineActivity a = s.activity;
    final double lineY = size.height * 0.66;
    final double marker = math.min(size.height * 0.5, 52);
    // Before it stands on a number (place mode) the marker waits in the top left corner, on the stage and clearly off the
    // line (QA-6), a little smaller; it hops onto the tick the child touches.
    final bool waiting = s.markerAt == null;
    final double side = waiting ? marker * 0.8 : marker;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            key: const Key('line-stage'),
            children: <Widget>[
              if (a.background != null)
                Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('line-touch'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (TapUpDetails d) => s.choose(s.tickAt(d.localPosition.dx, size.width, _pad)),
                ),
              ),
              IgnorePointer(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: _pad - 4,
                      width: size.width - 2 * _pad + 8,
                      top: lineY - 3,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TokenColors.ink,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    for (int n = a.from; n <= a.to; n++) _tick(a, n, lineY),
                    if (s.hopDots > 0)
                      Positioned(
                        right: 8,
                        top: 6,
                        child: HintCard(
                          key: const Key('hop-pill'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (int i = 0; i < s.hopDots; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Container(
                                    key: i < s.hopDotsUsed ? const Key('hop-dot-used') : const Key('hop-dot'),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < s.hopDotsUsed ? null : TokenColors.skyDeep,
                                      border: Border.all(color: TokenColors.skyDeep, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      key: const Key('line-marker'),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      left: waiting ? 4 : _x(s.markerAt!) - marker / 2,
                      top: waiting ? 4 : lineY - marker - 10,
                      width: side,
                      height: side,
                      child: PackSvg(a.assets.svg(a.markerSprite)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tick(NumberLineActivity a, int n, double lineY) {
    final bool lit = s.trail.contains(n);
    final bool wrong = s.wrongTick == n;
    final bool right = s.ring == AnswerState.correct && n == a.target;
    final Color colour = wrong
        ? TokenColors.notYetRing
        : (right ? TokenColors.correctGlow : (lit ? TokenColors.hintHalo : TokenColors.ink));
    return Positioned(
      left: _x(n) - 14,
      top: lineY - 12,
      width: 28,
      height: 64,
      child: Column(
        children: <Widget>[
          Container(
            width: lit || wrong || right ? 8 : 4,
            height: lit || wrong || right ? 24 : 18,
            decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(3)),
          ),
          if (a.labels.contains(n))
            Text(
              '$n',
              style: AppText.fixed(size: 17, weight: 800, lineHeight: 1.1),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
