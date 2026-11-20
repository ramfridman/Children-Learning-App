import 'dart:async';
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
import 'host_moves.dart';
import 'lesson_arc.dart' show ArcPart, ArcStep;
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
  /// The grid is drawn left to right and top to bottom, whatever the language. The bottom [strip] of the stage is not the grid's
  /// (the plan's steps stand there on a phone, see [stripOf]).
  static double cellSide(Size size, int cols, int rows, {double strip = 0}) =>
      math.min((size.width - 16) / cols, (size.height - strip - 12) / rows);

  static Offset cellCentre(Size size, int cols, int rows, (int, int) p, {double strip = 0}) {
    final double cell = cellSide(size, cols, rows, strip: strip);
    return Offset(
      (size.width - cell * cols) / 2 + (p.$1 + 0.5) * cell,
      (size.height - strip - cell * rows) / 2 + (p.$2 + 0.5) * cell,
    );
  }

  // ---- the phone's layout (B-38): a tall stage, and the arrows as a block of 2 by 2 beside it ----

  /// A tile of the pad with its tap margin (a tile is 58 and its margin 6 on each side).
  static const double _slot = 70;

  /// The steps of a plan are arrows of 28 (a tablet's 40) that are never scaled down, in a strip 44 high (56) with a start dot at its left end: a
  /// row that is full goes on in a second row under it, left to right too (docs/design/m11/min-sizes.md B2, R9).
  static double programIcon(ActivitySpec spec) => spec.stageIsCard ? 40 : 28;

  /// The least height of the strip with one row of steps; each further row adds an arrow and its gap of 4.
  static double stripHeightOf(ActivitySpec spec, int lines) =>
      lines * (programIcon(spec) + 4) - 4 + (spec.stageIsCard ? 16 : 16);

  /// How many rows the steps of [a] take in a strip [width] wide (less its margins, its start dot and the room round the steps), when the arrows are
  /// [gap] apart (4, or 0 where that keeps all of them in one row: the smallest phone's 8 steps).
  static int _linesAt(RobotPathActivity a, ActivitySpec spec, double width, double gap) {
    final double icon = programIcon(spec);
    final double room = width - 12 - 18;
    final int perRow = math.max(1, ((room + gap) / (icon + gap)).floor());
    return (a.maxSteps / perRow).ceil();
  }

  static double programGap(RobotPathActivity a, ActivitySpec spec, double width) =>
      _linesAt(a, spec, width, 4) > 1 && _linesAt(a, spec, width, 0) == 1 ? 0 : 4;

  static int programLines(RobotPathActivity a, ActivitySpec spec, double width) =>
      _linesAt(a, spec, width, programGap(a, spec, width));

  /// Whether the arrows stand as a block beside the stage (the phones: their stage is short, and a grid of four rows would have
  /// squares of 29 points). The tablets keep the row of arrows under the stage, where cells are large enough.
  static bool padBeside(ActivitySpec spec) => !spec.stageIsCard;

  /// The palette's tiles have a tap margin of 6 and the row starts `tileSlop` above the tiles' place, so the drawn tiles stand `tileSlop - 6` above it (see `ActivityFrame.tilesRise`).
  @override
  double tilesRise(ActivitySpec spec) => spec.tileSlop - 6;

  @override
  ActivitySpec layoutFor(ActivitySpec base) => _spec = laidOut(base);

  /// The board numbers of this template: on a phone the stage reaches down to the foot of the board, and the arrows (with the
  /// undo and go buttons of a plan, in a third column) stand to its end side, under the speech bubble. A board of four rows then
  /// has squares of at least 50 points on the phone and on the small phone. The tablets keep the board's own numbers.
  static ActivitySpec laidOut(ActivitySpec base) {
    if (!padBeside(base)) return base;
    final double top = base.bubbleTop + base.bubbleMaxHeight + 2;
    return base.withStageAndTiles(
      stage: Rect.fromLTRB(base.stage.left, base.stage.top, base.stage.right, top + 2 * _slot),
      tilesLeft: base.stage.right + 4,
      tilesTop: top + 12,
      tilesWidth: 3 * _slot,
    );
  }

  /// The size of the hint's hand on a phone: the tall stage would make it 96 high (see `hintScale`); at 72 the hand that presses
  /// the lower row of the block, which comes from below, still ends on the board.
  static const double _padHandScale = 1;

  /// The height at the foot of the stage that the plan's steps take: 0 where they stand over the arrows (the tablets) or the
  /// activity has no plan.
  static double stripOf(RobotPathActivity a, ActivitySpec spec) =>
      a.plan && padBeside(spec) ? stripHeightOf(spec, programLines(a, spec, spec.stage.width - 16)) : 0;

  double get _strip => _spec == null ? 0 : stripOf(activity, _spec!);

  /// The arrow tiles stand left, up, down, right in a row that is drawn left to right in every language; a plan has three more
  /// tiles after them (undo, 70 wide, and go, 94, with a gap of 10) and a row of its steps above.
  static const List<String> arrowOrder = <String>['left', 'up', 'down', 'right'];

  /// The height the steps of a plan have above the row of arrows on a tablet (one row of 40, or two).
  double _tabletStrip(ActivitySpec spec) =>
      stripHeightOf(spec, programLines(activity, spec, spec.tilesWidth)) + 8;

  /// The side of a control tile and its tap margin on a tablet (80 and 8, so that the arrows are not the phone's 58 on a card of 848: min-sizes C1), a
  /// phone's 58 and 6.
  double get _t => (_spec?.stageIsCard ?? false) ? 80 : 58;
  double get _ts => (_spec?.stageIsCard ?? false) ? 8 : 6;
  static double _tabletSlot(ActivitySpec spec) => spec.stageIsCard ? 96 : 70;

  /// The fingertip place on the top edge of the arrow tile [dir] (a tile is 58 and its tap margin 6). The block of 2 by 2 of a phone
  /// holds the arrows in the order of [arrowOrder], row by row. The row of a plan is taller
  /// (the go button has a lip) and its tiles stand 12 lower in it, under the row of the steps (34).
  Offset arrowTip(ActivitySpec spec, String dir) {
    if (padBeside(spec)) {
      final int i = arrowOrder.indexOf(dir);
      return spec.fromTiles(_padLeft + (i % 2 + 0.5) * _slot, i ~/ 2 * _slot + 6);
    }
    final double slot = _tabletSlot(spec);
    final double row = activity.plan ? 4 * slot + 10 + slot + slot + 24 : 4 * slot;
    final double x = (spec.tilesWidth - row) / 2 + (arrowOrder.indexOf(dir) + 0.5) * slot;
    return spec.fromTiles(x, (activity.plan ? _tabletStrip(spec) + 12 : 0) + 6);
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

  // ---- the host's part (a Show, the lead of a Together item) ----

  /// The host lays one arrow: in a plan the card goes in the row of steps, in direct control the robot moves one square.
  void _lay(String dir) {
    if (activity.plan) {
      program.add(dir);
      return;
    }
    final (int, int) next = _after(pos, dir);
    if (_inside(next)) pos = next;
  }

  /// The host's hand presses the arrow [dir] (the tile of the pad) and lays it.
  HostMove _arrowMove(String dir) {
    final ActivitySpec? spec = _spec;
    return HostMove(spec != null && _canDraw ? arrowTip(spec, dir) : null, () => _lay(dir), rest: 650);
  }

  @override
  void startHost() {
    final ArcStep? step = controller.step;
    if (step == null || hosting) return;
    if (activity.isShow) {
      unawaited(
        playShow(
          activity.show!,
          move: (ShowStep s, {required bool fast}) =>
              hostTour(_hint, <HostMove>[_arrowMove(s.arrow!)], fast: fast),
        ),
      );
    } else if (step.part == ArcPart.together && controller.leading && step.lead > 0) {
      unawaited(
        playLead(<Future<void> Function()>[
          for (final String d in activity.solution.take(step.lead))
            () => hostTour(_hint, <HostMove>[_arrowMove(d)]),
        ]),
      );
    }
  }

  /// A touch on a reminder skips what the host still has to do: its arrows are laid, and the child's step is left.
  @override
  void onScreenTouch() {
    if (!activity.isShow) return;
    skipHost(() {
      _hint.clear();
      for (final ShowStep s in activity.show!.hostSteps) {
        _lay(s.arrow!);
      }
    });
  }

  /// A Show, and the child lays an arrow: the one the host left ends the Show (a plan is run first, so that the child sees where it leads); any other
  /// is "let's look again". Nothing is written.
  Future<void> _showArrow(String dir) async {
    final String want = activity.show!.childStep.arrow!;
    if (dir != want) {
      _busy = true;
      hintStep = want;
      lookAgain(activity);
      notify();
      later(TemplateSession.notYetPause, () {
        hintStep = null;
        _busy = false;
        notify();
      });
      return;
    }
    _busy = true;
    _lay(dir);
    notify();
    if (activity.plan) {
      // The plan runs on its own: the robot walks the cards, one square for each.
      running = true;
      pos = activity.robotAt;
      notify();
      final List<String> steps = List<String>.of(program);
      for (int i = 0; i < steps.length; i++) {
        await pause(Duration(milliseconds: stillHost ? 300 : 450));
        final (int, int) next = _after(pos, steps[i]);
        if (_inside(next)) pos = next;
        notify();
      }
      await pause(const Duration(milliseconds: 450));
      running = false;
    }
    ring = AnswerState.correct;
    notify();
    finishShow();
  }

  Future<void> arrow(String dir) async {
    if (_busy || hosting || running || ring == AnswerState.correct) return;
    if (activity.isShow) {
      await _showArrow(dir);
      return;
    }
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
    if (_busy || hosting || activity.isShow || running || program.isEmpty) return;
    program.removeLast();
    // The undo button stays lit until what is left of the plan is the start of the way (hint 2 lit it, see [_firstStep]).
    if (hintStep == 'undo' && _planOnWay != null) hintStep = null;
    notify();
  }

  /// Plan mode: the robot walks the program, one square at a time.
  Future<void> go() async {
    if (_busy || hosting || activity.isShow || running || program.isEmpty) return;
    if (ring == AnswerState.correct) return;
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
    later(praise, controller.next);
  }

  /// One numbered footprint on each of [squares], the first of them numbered [first] (the number of that step of the way).
  List<HintMark> _footprints(List<(int, int)> squares, {int first = 1}) {
    final double side = cellSide(_size, activity.cols, activity.rows, strip: _strip);
    return <HintMark>[
      for (int j = 0; j < squares.length; j++)
        BadgeMark(
          cellCentre(_size, activity.cols, activity.rows, squares[j], strip: _strip) +
              Offset(side * 0.26, side * 0.26),
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
            for (int i = 0; i < way.length; i++)
              HandStop(
                arrowTip(spec, way[i]),
                step,
                marks: footprints(i),
                // From below, so that its body never hides the speech bubble (over the block of arrows), nor the robot and the flag
                // (over the stage, above the tablets' row).
                from: HandFrom.below,
              ),
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
    // The arrows the host laid in the lead of a Together item stay laid.
    if (controller.step?.part == ArcPart.together && !controller.leading) {
      activity.solution.take(controller.step!.lead).forEach(_lay);
    }
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
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) =>
      _hint.hands(size, spec, scale: padBeside(spec) ? _padHandScale : null);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => padBeside(spec) ? _pad() : _arrowRow(spec),
  );

  /// The steps of a plan, the first at the left after a start dot, and an arrow never mirrors, in every language. Each step is a square of the
  /// arrow's size; a row that is full goes on in a second row under it (see [programLines]).
  Widget _programRow(ActivitySpec spec, double width) {
    final double icon = programIcon(spec);
    final double gap = programGap(activity, spec, width);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        // The strip is this padded box: 44 high with one row of steps (56 on a tablet), as min-sizes.md B2 asks.
        key: const Key('robot-program'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: (icon - 10) / 2, right: 8),
              child: const SizedBox(
                key: Key('robot-start'),
                width: 10,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: TokenColors.ink, shape: BoxShape.circle),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: gap,
                runSpacing: 4,
                children: <Widget>[
                  for (final String d in program)
                    SizedBox(
                      width: icon,
                      height: icon,
                      child: Icon(_icon(d), size: icon, color: TokenColors.ink),
                    ),
                  for (int i = program.length; i < activity.maxSteps; i++)
                    // An empty place is a ring of 20 (28 on a tablet), not an arrow: min-sizes.md B2.
                    SizedBox(
                      width: icon,
                      height: icon,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: TokenColors.hairline, width: 3),
                          ),
                          child: SizedBox.square(dimension: icon * 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnswerTile _arrowTile(String d) => AnswerTile(
    key: Key('arrow-$d'),
    semanticLabel: d,
    size: _t,
    slop: _ts,
    state: hintStep == d ? AnswerState.selected : AnswerState.idle,
    onPressed: () => arrow(d),
    child: Icon(_icon(d), size: _t > 60 ? 44 : 34, color: TokenColors.ink),
  );

  AnswerTile get _undoTile => AnswerTile(
    key: const Key('robot-undo'),
    semanticLabel: 'undo',
    size: _t,
    slop: _ts,
    state: hintStep == 'undo' ? AnswerState.selected : AnswerState.idle,
    onPressed: undo,
    child: Icon(Icons.backspace_outlined, size: _t > 60 ? 44 : 32, color: TokenColors.ink),
  );

  Widget get _goButton => Padding(
    padding: EdgeInsets.all(_ts),
    child: PlayPebble(key: const Key('robot-go'), semanticLabel: 'go', size: _t, onPressed: go),
  );

  /// The same button in a slot of the pad: 58 with a tap margin of 6, as the arrows.
  Widget get _goInPad =>
      PlayPebble(key: const Key('robot-go'), semanticLabel: 'go', size: 58, slop: 6, onPressed: go);

  /// Where the block of arrows starts in the tiles' box: a plan has undo and go in a third column, and the block of a direct
  /// activity stands in the middle of the box.
  double get _padLeft => activity.plan ? 0 : _slot / 2;

  /// The phone's controls (see [padBeside]): the arrows as a block of 2 by 2, in the order of [arrowOrder] row by row, and for a
  /// plan the undo and go buttons in a column beside it. Drawn left to right: an arrow that points left stands on the left.
  Widget _pad() => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      height: 2 * _slot,
      child: Stack(
        children: <Widget>[
          for (final (int i, String d) in arrowOrder.indexed)
            Positioned(left: _padLeft + i % 2 * _slot, top: i ~/ 2 * _slot, child: _arrowTile(d)),
          if (activity.plan) ...<Widget>[
            Positioned(left: 2 * _slot, top: 0, child: _undoTile),
            Positioned(left: 2 * _slot, top: _slot, child: _goInPad),
          ],
        ],
      ),
    ),
  );

  /// The tablets' controls: a row under the stage, with the steps of a plan above it. The controls are drawn left to right: an arrow
  /// that points left stands on the left, in every language.
  Widget _arrowRow(ActivitySpec spec) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (activity.plan) SizedBox(height: _tabletStrip(spec), child: _programRow(spec, spec.tilesWidth)),
      Directionality(
        textDirection: TextDirection.ltr,
        // (Scaled down only on a board narrower than the grown card, where the row of arrows, undo and go does not fit.)
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final String d in arrowOrder) _arrowTile(d),
              if (activity.plan) ...<Widget>[const SizedBox(width: 10), _undoTile, _goButton],
            ],
          ),
        ),
      ),
    ],
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
    final double strip = s._strip;
    final double cell = RobotPathSession.cellSide(size, a.cols, a.rows, strip: strip);
    final double left = (size.width - cell * a.cols) / 2;
    final double top = (size.height - strip - cell * a.rows) / 2;
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
            // On a phone the steps of a plan stand under the grid, in the stage.
            if (strip > 0)
              Positioned(
                left: 8,
                right: 8,
                bottom: 4,
                height: strip,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TokenColors.paper.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(math.min(strip / 2, 22)),
                  ),
                  child: s._programRow(s._spec!, s._spec!.stage.width - 16),
                ),
              ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }
}
