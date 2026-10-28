import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'template_session.dart';

/// The spot-the-mistake template (T21): a friend made a row (a pattern, a count, a program, a sum) and one cell of it is wrong.
/// The child touches the mistake. A wrong touch is a gentle "not yet"; after three only the mistake is taken, and the help rings
/// it. The row is read from the left, whatever the language.
class SpotErrorSession extends TemplateSession {
  SpotErrorSession(super.controller, this.activity);

  final SpotErrorActivity activity;

  int? wrongCell;
  int? hintCell;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  Future<void> choose(int i) async {
    if (_busy || ring == AnswerState.correct) return;
    if (controller.guided && i != activity.wrong) {
      hintCell = activity.wrong;
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
      if (controller.guided) hintCell = activity.wrong;
      notify();
    });
  }

  @override
  void onReset() {
    wrongCell = null;
    hintCell = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintCell = null;
    notify();
  }

  @override
  void onHint() {
    if (_busy && !controller.guided) return;
    // The help rings the mistake from the second help on; the first only invites looking again.
    if (controller.hintLevel >= 2 || controller.guided) hintCell = activity.wrong;
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[for (int i = 0; i < a.cells.length; i++) _cell(a, i, side)],
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
              : (s.hintCell == i ? TokenColors.hintHalo : null));
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
          child: _face(a, a.cells[i], side),
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
