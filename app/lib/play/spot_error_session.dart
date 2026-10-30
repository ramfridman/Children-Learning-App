import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hint_widgets.dart';
import 'template_session.dart';

/// The spot-the-mistake template (T21): a friend made a row (a pattern, a count, a program, a sum) and one cell of it is wrong.
/// The child touches the mistake. A wrong touch is a gentle "not yet"; after three only the mistake is taken, and the help rings
/// it, at the end of the guide's walk along the row. The row is read from the left, whatever the language.
class SpotErrorSession extends TemplateSession {
  SpotErrorSession(super.controller, this.activity);

  final SpotErrorActivity activity;

  int? wrongCell;

  /// The cell the help has picked out: the mistake, at the end of the worked example and afterwards (never before).
  int? hintCell;

  /// Hint 1 and 2: the cell the light is on now (none when it has finished), the cells it has been to, and, for hint 2, how far
  /// the sky bar under the row has grown (it points the way along the row, and picks out no cell).
  int? lit;
  final Set<int> visited = <int>{};
  int? barTo;
  int _run = 0;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  Future<void> choose(int i) async {
    if (_busy || ring == AnswerState.correct) return;
    if (controller.guided && i != activity.wrong) {
      if (controller.answerShown) hintCell = activity.wrong;
      notify();
      return;
    }
    _busy = true;
    final bool right = i == activity.wrong;
    await controller.submitPlacement(
      right: right,
      tag: right ? '' : (activity.wrongTag ?? ''),
      response: '$i',
    );
    if (disposed) return;
    if (right) {
      ring = AnswerState.correct;
      hintCell = null;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    wrongCell = i;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      wrongCell = null;
      ring = AnswerState.idle;
      _busy = false;
      if (controller.answerShown) hintCell = activity.wrong;
      notify();
    });
  }

  @override
  void onReset() {
    wrongCell = null;
    hintCell = null;
    _clearWalk();
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintCell = null;
    _clearWalk();
    notify();
  }

  void _clearWalk() {
    _run++;
    lit = null;
    barTo = null;
    visited.clear();
  }

  @override
  void onHint() {
    if (_busy && !controller.guided) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.walkTheRow:
        _walk(to: activity.cells.length - 1, bar: false);
      case HintPicture.stepArcs:
        _walk(to: activity.cells.length - 1, bar: true);
      default:
        _walk(to: activity.wrong, bar: true, stopOnWrong: true);
    }
  }

  /// The light goes along the row from the left, one cell at a time, as far as [to]. With [stopOnWrong] (the worked example) it
  /// stops there and the cell is picked out: that is the last step, and then the child's turn comes back.
  void _walk({required int to, required bool bar, bool stopOnWrong = false}) {
    _clearWalk();
    hintCell = null;
    final int run = _run;
    const int step = 700;
    for (int i = 0; i <= to; i++) {
      later(Duration(milliseconds: step * i), () {
        if (run != _run) return;
        lit = i;
        visited.add(i);
        if (bar) barTo = i;
        notify();
      });
    }
    later(Duration(milliseconds: step * (to + 1)), () {
      if (run != _run) return;
      lit = null;
      if (stopOnWrong) {
        hintCell = activity.wrong;
        visited.clear();
      }
      notify();
      if (stopOnWrong) controller.demoDone();
    });
    notify();
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _RowStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;
}

class _RowStage extends StatelessWidget {
  const _RowStage(this.s, this.size);

  final SpotErrorSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final SpotErrorActivity a = s.activity;
    final double side = math.min(size.height - 16, (size.width - 16) / a.cells.length - 6);
    final double rowWidth = (side + 6) * a.cells.length;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('spot-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned.fill(
              child: Directionality(
                textDirection: TextDirection.ltr,
                // The cells come one by one from the left, so the child sees where the row starts.
                child: RowEntrance(
                  count: a.cells.length,
                  builder: (BuildContext context, Widget Function(int, Widget) cell) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[for (int i = 0; i < a.cells.length; i++) cell(i, _cell(a, i, side))],
                  ),
                ),
              ),
            ),
            // Hint 2: a sky bar under the row grows from the left as the light goes by. It points the way and picks out no cell.
            if (s.barTo != null)
              Positioned(
                left: (size.width - rowWidth) / 2 + 3,
                bottom: 2,
                child: AnimatedContainer(
                  key: const Key('spot-bar'),
                  duration: const Duration(milliseconds: 500),
                  width: (side + 6) * (s.barTo! + 1) - 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: TokenColors.hintHalo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(SpotErrorActivity a, int i, double side) {
    final Color? ring = s.wrongCell == i
        ? TokenColors.notYetRing
        : (s.ring == AnswerState.correct && i == a.wrong
              ? TokenColors.correctGlow
              : (s.hintCell == i || s.lit == i ? TokenColors.hintHalo : null));
    return GestureDetector(
      key: Key('cell-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => s.choose(i),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TokenColors.paper.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(TokenRadius.lg),
            border: Border.all(color: ring ?? TokenColors.hairline, width: ring == null ? 3 : 5),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: <Widget>[
              Center(child: _face(a, a.cells[i], side)),
              if (s.visited.contains(i) && s.hintCell != i)
                const Positioned(top: 4, right: 4, child: SeenDot(key: Key('seen-dot'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _face(SpotErrorActivity a, String cell, double side) {
    if (cell.startsWith('asset:')) {
      return Padding(padding: const EdgeInsets.all(5), child: PackSvg(a.assets.svg(cell)));
    }
    if (cell.startsWith('dir:')) {
      final IconData icon = switch (cell.substring(4)) {
        'up' => Icons.arrow_upward_rounded,
        'down' => Icons.arrow_downward_rounded,
        'left' => Icons.arrow_back_rounded,
        _ => Icons.arrow_forward_rounded,
      };
      return Icon(icon, size: side * 0.6, color: TokenColors.ink);
    }
    final String text = cell.startsWith('op:') ? cell.substring(3).replaceAll('-', '−') : cell.substring(2);
    return Text(text, style: AppText.fixed(size: side * 0.5, weight: 800, lineHeight: 1));
  }
}
