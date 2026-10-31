import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../child/play_button.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/pointer_plans.dart';
import 'hints/hint_player.dart';
import 'hints/tile_points.dart';
import 'lesson_controller.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The robot-path template (T07). A robot stands on a small grid and the flag is somewhere else. In `direct` mode every arrow
/// moves the robot at once (the first steps of controlling something). In `plan` mode the child builds a row of steps and then
/// presses go: the robot walks them, and if it does not end on the flag, that is a "not yet", with M-CS-OFF1 when it stopped one
/// square short or went one square past. The program stays, so the child can change a step and run it again.
///
/// Directions are the screen's own, and never mirror: up is up, right is right, in every language.
class RobotPathSession extends TemplateSession {
  RobotPathSession(super.controller, this.activity) : pos = activity.robotAt;

  final RobotPathActivity activity;

  /// Where the robot is now, as (column, row) from the top left.
  (int, int) pos;

  /// The planned steps (plan mode), and whether they are being walked now.
  final List<String> program = <String>[];
  bool running = false;

  /// The arrow that the help points at, and the squares of the way that the help shows.
  String? hintStep;
  final Set<(int, int)> trail = <(int, int)>{};

  /// Hint 1 lights the robot and the flag; hint 2 shows a ghost of the robot one step on (null when there is none).
  bool spotlight = false;
  (int, int)? ghost;

  /// The robot just tried to leave the grid.
  bool bumped = false;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// The pointing hand and the numbered footprints of the worked example (B-40), and the stage's and the board's sizes they use.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec? _spec;

  bool get _canDraw => _spec != null && !_size.isEmpty;

  /// The side of a square of the grid in a stage of [size], and the middle of the square [p] ((column, row) from the top left).
  /// The grid is drawn left to right and top to bottom, whatever the language.
  static double cellSide(Size size, int cols, int rows) =>
      math.min((size.width - 16) / cols, (size.height - 12) / rows);

  static Offset cellCentre(Size size, int cols, int rows, (int, int) p) {
    final double cell = cellSide(size, cols, rows);
    return Offset(
      (size.width - cell * cols) / 2 + (p.$1 + 0.5) * cell,
      (size.height - cell * rows) / 2 + (p.$2 + 0.5) * cell,
    );
  }

  /// The arrow tiles stand left, up, down, right in a row that is drawn left to right in every language; a plan has three more
  /// tiles after them (undo, 70 wide, and go, 94, with a gap of 10) and a row of its steps above.
  static const List<String> arrowOrder = <String>['left', 'up', 'down', 'right'];

  /// The fingertip place on the top edge of the arrow tile [dir] (a tile is 58 and its tap margin 6). The row of a plan is taller
  /// (the go button has a lip) and its tiles stand 12 lower in it, under the row of the steps (34).
  Offset arrowTip(ActivitySpec spec, String dir) {
    final double row = (activity.plan ? 4 * 70 + 10 + 70 + 94 : 4 * 70).toDouble();
    final double x = (spec.tilesWidth - row) / 2 + (arrowOrder.indexOf(dir) + 0.5) * 70;
    return spec.fromTiles(x, (activity.plan ? 34 + 12 : 0) + 6);
  }

  static (int, int) _after((int, int) p, String d) => switch (d) {
    'up' => (p.$1, p.$2 - 1),
    'down' => (p.$1, p.$2 + 1),
    'left' => (p.$1 - 1, p.$2),
    _ => (p.$1 + 1, p.$2),
  };

  bool _inside((int, int) p) => p.$1 >= 0 && p.$1 < activity.cols && p.$2 >= 0 && p.$2 < activity.rows;

  /// The next step of the help: in plan mode the step after the ones planned, in direct mode the next step from where the
  /// robot stands (along the line first, then across).
  String? get _nextOfHelp {
    if (activity.plan) {
      return program.length < activity.solution.length ? activity.solution[program.length] : null;
    }
    final (int, int) g = activity.goalAt;
    if (pos.$1 != g.$1) return pos.$1 < g.$1 ? 'right' : 'left';
    if (pos.$2 != g.$2) return pos.$2 < g.$2 ? 'down' : 'up';
    return null;
  }

  Future<void> arrow(String dir) async {
    if (_busy || running || ring == AnswerState.correct) return;
    if (controller.guided && dir != _nextOfHelp) {
      if (controller.answerShown) hintStep = _nextOfHelp;
      notify();
      return;
    }
    hintStep = null;
    ghost = null;
    spotlight = false;
    _hint.clear();
    if (activity.plan) {
      if (program.length < activity.maxSteps) program.add(dir);
      notify();
      return;
    }
    final (int, int) next = _after(pos, dir);
    if (!_inside(next)) {
      bumped = true;
      notify();
      later(const Duration(milliseconds: 350), () {
        bumped = false;
        notify();
      });
      return;
    }
    pos = next;
    notify();
    if (pos == activity.goalAt) await _won();
  }

  void undo() {
    if (_busy || running || program.isEmpty) return;
    program.removeLast();
    // The undo button stays lit until what is left of the plan is the start of the way (hint 2 lit it, see [_firstStep]).
    if (hintStep == 'undo' && _planOnWay != null) hintStep = null;
    notify();
  }

  /// Plan mode: the robot walks the program, one square at a time.
  Future<void> go() async {
    if (_busy || running || program.isEmpty || ring == AnswerState.correct) return;
    running = true;
    pos = activity.robotAt;
    hintStep = null;
    notify();
    final List<String> steps = List<String>.of(program);
    for (int i = 0; i < steps.length; i++) {
      later(Duration(milliseconds: 450 * (i + 1)), () {
        final (int, int) next = _after(pos, steps[i]);
        if (_inside(next)) pos = next;
        notify();
      });
    }
    later(Duration(milliseconds: 450 * (steps.length + 1)), _finishRun);
  }

  Future<void> _finishRun() async {
    if (pos == activity.goalAt) {
      running = false;
      await _won();
      return;
    }
    _busy = true;
    final int away = (pos.$1 - activity.goalAt.$1).abs() + (pos.$2 - activity.goalAt.$2).abs();
    // One square short or one square past is the off-by-one of counting the start square.
    final String tag = away == 1 ? (activity.wrongTag ?? '') : '';
    await controller.submitPlacement(right: false, tag: tag, response: ResponseCode.program(program));
    if (disposed) return;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      ring = AnswerState.idle;
      running = false;
      _busy = false;
      pos = activity.robotAt;
      if (controller.guided) {
        program.clear();
        if (controller.answerShown) hintStep = _nextOfHelp;
      }
      notify();
    });
  }

  Future<void> _won() async {
    _busy = true;
    final Outcome o = await controller.submitPlacement(
      right: true,
      response: activity.plan ? ResponseCode.program(program) : ResponseCode.reached,
    );
    if (disposed || !o.correct) return;
    ring = AnswerState.correct;
    notify();
    later(TemplateSession.praisePause, controller.next);
  }

  /// One numbered footprint on each of [squares], the first of them numbered [first] (the number of that step of the way).
  List<HintMark> _footprints(List<(int, int)> squares, {int first = 1}) {
    final double side = cellSide(_size, activity.cols, activity.rows);
    return <HintMark>[
      for (int j = 0; j < squares.length; j++)
        BadgeMark(
          cellCentre(_size, activity.cols, activity.rows, squares[j]) + Offset(side * 0.26, side * 0.26),
          first + j,
        ),
    ];
  }

  /// Where a robot that walks [steps] from the start ends: a step off the grid is not taken, as when the robot runs.
  (int, int) _endOf(List<String> steps) {
    (int, int) at = activity.robotAt;
    for (final String d in steps) {
      final (int, int) next = _after(at, d);
      if (_inside(next)) at = next;
    }
    return at;
  }

  /// How many steps the child's plan has when they are all the first steps of the stored way, or null when one of them is not.
  int? get _planOnWay {
    final List<String> way = activity.solution;
    if (program.length > way.length) return null;
    for (int i = 0; i < program.length; i++) {
      if (program[i] != way[i]) return null;
    }
    return program.length;
  }

  /// The first leg of the stored way from step [from]: its arrows up to the first turn, and never more than half the steps of the
  /// way (rounded down, at least one).
  List<String> _legFrom(int from) {
    final List<String> way = activity.solution;
    if (from >= way.length) return const <String>[];
    final int most = math.max(1, way.length ~/ 2);
    int end = from + 1;
    while (end < way.length && end - from < most && way[end] == way[from]) {
      end++;
    }
    return way.sublist(from, end);
  }

  /// Hint 2: the arrow to press is lit, and a ghost robot stands where the step (or the leg) leads, with the footprints of it.
  ///
  /// In direct mode it is the next step from where the robot stands (footprint 1). In plan mode it starts from the end of the plan,
  /// and the footprints carry on from its count. The skill CS-B-01 shows a whole leg of the way; every other plan shows one step.
  /// A plan that is not the way's beginning lights the undo button instead, and draws nothing else.
  void _firstStep() {
    _hint.clear();
    ghost = null;
    // A plan with a step that is not the way's: the footprints would be numbered from the start, but the next step pressed would be
    // added after the wrong ones. So the undo button is lit first, and nothing else is drawn, until the plan is the way's beginning.
    if (activity.plan && _planOnWay == null) {
      hintStep = 'undo';
      return;
    }
    final List<String> leg;
    final (int, int) from;
    final int first;
    if (!activity.plan) {
      final String? next = _nextOfHelp;
      leg = <String>[?next];
      from = pos;
      first = 1;
    } else if (activity.skillId == 'CS-B-01') {
      leg = _legFrom(program.length);
      from = _endOf(program);
      first = program.length + 1;
    } else {
      final String? next = _nextOfHelp;
      leg = <String>[?next];
      from = _endOf(program);
      first = program.length + 1;
    }
    hintStep = leg.isEmpty ? null : leg.first;
    final List<(int, int)> squares = <(int, int)>[];
    (int, int) at = from;
    for (final String d in leg) {
      at = _after(at, d);
      squares.add(at);
    }
    ghost = squares.isEmpty || !squares.every(_inside) ? null : squares.last;
    if (ghost == null || !_canDraw) return;
    _hint.play(HintPlan(const <HintFrame>[], rest: _footprints(squares, first: first)));
  }

  /// The worked example: the pointing hand presses each arrow of the way, the robot takes the step and leaves a numbered footprint,
  /// and at the flag the robot goes back to the start. Then it is the child's turn.
  void _workedExample() {
    if (running) return;
    running = true;
    pos = activity.robotAt;
    program.clear();
    trail.clear();
    notify();
    final List<String> way = activity.solution;
    const int step = 600;
    const int tail = 1200;
    final ActivitySpec? spec = _spec;
    if (spec != null && _canDraw) {
      // The square after each step, in the order of the steps: the footprints.
      final List<(int, int)> squares = <(int, int)>[];
      (int, int) at = activity.robotAt;
      for (final String d in way) {
        at = _after(at, d);
        squares.add(at);
      }
      List<HintMark> footprints(int n) => _footprints(squares.sublist(0, n));
      _hint.play(
        handTourPlan(
          <HandStop>[
            for (int i = 0; i < way.length; i++) HandStop(arrowTip(spec, way[i]), step, marks: footprints(i)),
          ],
          after: footprints(way.length),
          tailMs: step + tail,
        ),
      );
    }
    for (int i = 0; i < way.length; i++) {
      later(Duration(milliseconds: step * (i + 1)), () {
        pos = _after(pos, way[i]);
        trail.add(pos);
        notify();
      });
    }
    later(Duration(milliseconds: step * (way.length + 1) + tail), () {
      pos = activity.robotAt;
      trail.clear();
      running = false;
      // The last step of the worked example: the arrow the child is to press first is lit. Then it is the child's turn.
      hintStep = _nextOfHelp;
      notify();
      controller.demoDone();
    });
  }

  @override
  void onReset() {
    _hint.clear();
    pos = activity.robotAt;
    program.clear();
    trail.clear();
    hintStep = null;
    spotlight = false;
    ghost = null;
    running = false;
    bumped = false;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    _hint.clear();
    hintStep = null;
    spotlight = false;
    ghost = null;
    notify();
  }

  @override
  void onHint() {
    if (running || ring == AnswerState.correct) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.robotAndGoal:
        // Hint 1: where the robot stands and where the flag is, nothing more.
        hintStep = null;
        ghost = null;
        spotlight = true;
        _hint.clear();
      case HintPicture.firstArrow:
        spotlight = false;
        _firstStep();
      default:
        spotlight = false;
        ghost = null;
        _hint.clear();
        _workedExample();
        return;
    }
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => _RobotStage(this, size),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (activity.plan)
          // The steps are drawn left to right, the first at the left, and an arrow never mirrors, in every language.
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 34,
              child: Row(
                key: const Key('robot-program'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final String d in program)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(_icon(d), size: 28, color: TokenColors.ink),
                    ),
                  for (int i = program.length; i < activity.maxSteps; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.circle_outlined, size: 22, color: TokenColors.hairline),
                    ),
                ],
              ),
            ),
          ),
        // The controls are drawn left to right: an arrow that points left stands on the left, in every language.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final String d in const <String>['left', 'up', 'down', 'right'])
                AnswerTile(
                  key: Key('arrow-$d'),
                  semanticLabel: d,
                  size: 58,
                  slop: 6,
                  state: hintStep == d ? AnswerState.selected : AnswerState.idle,
                  onPressed: () => arrow(d),
                  child: Icon(_icon(d), size: 34, color: TokenColors.ink),
                ),
              if (activity.plan) ...<Widget>[
                const SizedBox(width: 10),
                AnswerTile(
                  key: const Key('robot-undo'),
                  semanticLabel: 'undo',
                  size: 58,
                  slop: 6,
                  state: hintStep == 'undo' ? AnswerState.selected : AnswerState.idle,
                  onPressed: undo,
                  child: const Icon(Icons.backspace_outlined, size: 28, color: TokenColors.ink),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: PlayPebble(key: const Key('robot-go'), semanticLabel: 'go', size: 58, onPressed: go),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  static IconData _icon(String d) => switch (d) {
    'up' => Icons.arrow_upward_rounded,
    'down' => Icons.arrow_downward_rounded,
    'left' => Icons.arrow_back_rounded,
    _ => Icons.arrow_forward_rounded,
  };
}

class _RobotStage extends StatelessWidget {
  const _RobotStage(this.s, this.size);

  final RobotPathSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final RobotPathActivity a = s.activity;
    final double cell = math.min((size.width - 16) / a.cols, (size.height - 12) / a.rows);
    final double left = (size.width - cell * a.cols) / 2;
    final double top = (size.height - cell * a.rows) / 2;
    Offset at((int, int) p) => Offset(left + p.$1 * cell, top + p.$2 * cell);
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('robot-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            // The grid is drawn left to right and top to bottom, whatever the language.
            for (int r = 0; r < a.rows; r++)
              for (int c = 0; c < a.cols; c++)
                Positioned(
                  left: at((c, r)).dx + 2,
                  top: at((c, r)).dy + 2,
                  width: cell - 4,
                  height: cell - 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: s.trail.contains((c, r))
                          ? TokenColors.hintHalo.withValues(alpha: 0.5)
                          : TokenColors.paper.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: s.spotlight && ((c, r) == s.pos || (c, r) == a.goalAt)
                          ? Border.all(color: TokenColors.hintHalo, width: 4)
                          : Border.all(color: TokenColors.hairline, width: 2),
                    ),
                  ),
                ),
            Positioned(
              left: at(a.goalAt).dx + 4,
              top: at(a.goalAt).dy + 4,
              width: cell - 8,
              height: cell - 8,
              child: PackSvg(a.assets.svg(a.goalSprite), key: const Key('robot-goal')),
            ),
            if (s.ghost != null)
              Positioned(
                left: at(s.ghost!).dx + 3,
                top: at(s.ghost!).dy + 3,
                width: cell - 6,
                height: cell - 6,
                child: Opacity(
                  key: const Key('robot-ghost'),
                  opacity: 0.4,
                  child: PackSvg(a.assets.svg(a.robotSprite)),
                ),
              ),
            AnimatedPositioned(
              key: const Key('robot'),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: at(s.pos).dx + 3 + (s.bumped ? 4 : 0),
              top: at(s.pos).dy + 3,
              width: cell - 6,
              height: cell - 6,
              child: PackSvg(a.assets.svg(a.robotSprite)),
            ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }
}
