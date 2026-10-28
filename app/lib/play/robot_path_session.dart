import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../child/play_button.dart';
import '../design/tokens.g.dart';
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

  /// The robot just tried to leave the grid.
  bool bumped = false;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

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
      hintStep = _nextOfHelp;
      notify();
      return;
    }
    hintStep = null;
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
        hintStep = _nextOfHelp;
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

  /// The robot walks the way that the guide knows, and goes back to the start.
  void _workedExample() {
    if (running) return;
    running = true;
    pos = activity.robotAt;
    program.clear();
    trail.clear();
    notify();
    final List<String> way = activity.solution;
    for (int i = 0; i < way.length; i++) {
      later(Duration(milliseconds: 600 * (i + 1)), () {
        pos = _after(pos, way[i]);
        trail.add(pos);
        notify();
      });
    }
    later(Duration(milliseconds: 600 * (way.length + 1) + 1200), () {
      pos = activity.robotAt;
      trail.clear();
      running = false;
      notify();
    });
  }

  @override
  void onReset() {
    pos = activity.robotAt;
    program.clear();
    trail.clear();
    hintStep = null;
    running = false;
    bumped = false;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintStep = null;
    notify();
  }

  @override
  void onHint() {
    if (running || ring == AnswerState.correct) return;
    if (controller.hintAction == HintAction.workedExample) {
      _workedExample();
      return;
    }
    hintStep = _nextOfHelp;
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _RobotStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (activity.plan)
          SizedBox(
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
                      border: Border.all(color: TokenColors.hairline, width: 2),
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
            AnimatedPositioned(
              key: const Key('robot'),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: at(s.pos).dx + 3 + (s.bumped ? 4 : 0),
              top: at(s.pos).dy + 3,
              width: cell - 6,
              height: cell - 6,
              child: PackSvg(a.assets.svg(a.robotSprite)),
            ),
          ],
        ),
      ),
    );
  }
}
