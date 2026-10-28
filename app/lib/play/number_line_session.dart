import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'template_session.dart';

/// The number-line template (T09). The line always runs from the small number on the left to the large number on the right,
/// in every language. In `place` mode the child touches the tick where the marker belongs; in `jump` mode the marker stands on a
/// number and hops, and the child touches the tick where it lands. A touch is the answer: no confirm button.
///
/// A touch on the mirror of the right tick (the line read from the right) is written with its own misconception, M-NL-DIR.
/// After three wrong touches only the right tick is taken, and the guide hops the marker along the way.
class NumberLineSession extends TemplateSession {
  NumberLineSession(super.controller, this.activity) : markerAt = activity.start;

  final NumberLineActivity activity;

  /// The number the marker stands on, or null (not on the line yet).
  int? markerAt;

  /// The ticks that the help has lit, and the tick that just said "not yet".
  final Set<int> trail = <int>{};
  int? wrongTick;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;
  bool demoRunning = false;
  int _demo = 0; // a new touch or a new help ends the one that is running

  int get tickCount => activity.to - activity.from + 1;

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
    trail.clear();
  }

  void _showWay() {
    _stopWay();
    final int id = _demo;
    demoRunning = true;
    final int from = activity.start ?? activity.from;
    final List<int> way = activity.jump ? _landings() : _countUp(from, activity.target);
    markerAt = activity.start;
    notify();
    final int gap = way.length > 8 ? 250 : 500;
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
    });
  }

  List<int> _landings() {
    int at = activity.start ?? activity.from;
    return <int>[for (final int h in activity.hops) at += h];
  }

  List<int> _countUp(int from, int to) => <int>[for (int i = from; i <= to; i++) i];

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
    _showWay();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _LineStage(this, size));

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
                    AnimatedPositioned(
                      key: const Key('line-marker'),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      left: (s.markerAt == null ? _x(a.from) - marker * 1.5 : _x(s.markerAt!)) - marker / 2,
                      top: lineY - marker - 10,
                      width: marker,
                      height: marker,
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
